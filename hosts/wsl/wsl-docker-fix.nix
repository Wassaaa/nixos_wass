{
  pkgs,
  lib,
  ...
}:

let
  # Define the "Fixer Script" as a package
  dockerFixScript = pkgs.writeShellScript "docker-fix.sh" ''
    # 1. Add necessary tools to the path
    export PATH=$PATH:${
      lib.makeBinPath [
        pkgs.docker
        pkgs.docker-compose
        pkgs.jq
      ]
    }

    # Log output for debugging
    exec 1>/tmp/docker-fix.log 2>&1
    echo "Starting Docker Fixer..."

    # 2. Wait for Docker Socket to be active
    # We loop until 'docker info' succeeds
    while ! docker info > /dev/null 2>&1; do
      echo "Waiting for Docker Daemon..."
      sleep 2
    done

    echo "Docker is up! Waiting 5s for mounts to settle..."
    sleep 5

    # 3. Restart all active stacks
    # We use 'docker compose ls' to find running projects and restart them
    # This forces them to re-mount the volumes correctly
    for config in $(docker compose ls --format=json | jq -r '.[].ConfigFiles'); do
      echo "Restarting stack: $config"
      docker compose -f "$config" restart
    done

    echo "Done!"
  '';
in
{
  # Ensure these tools are installed system-wide
  environment.systemPackages = with pkgs; [
    docker
    docker-compose
    jq
  ];

  # Configure /etc/wsl.conf to run the script on boot
  # We use 'su -l' to run it as YOUR user, not root
  wsl.wslConf.boot.command = "su -l wsl -c '${dockerFixScript}'";
}
