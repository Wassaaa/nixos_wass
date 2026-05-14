{
  config,
  pkgs,
  lib,
  ...
}:

{
  # --- FIX 1: Fix Docker Desktop WSL Integration (The 'whoami' error) ---
  wsl.extraBin = with pkgs; [
    { src = "${coreutils}/bin/whoami"; }
    { src = "${coreutils}/bin/uname"; }
    { src = "${coreutils}/bin/dirname"; }
    { src = "${coreutils}/bin/readlink"; }
  ];

  # 1. Make sure required tools are installed
  environment.systemPackages = with pkgs; [
    docker
    docker-compose
    jq
  ];

  # --- FIX 2: Fix Docker Mounts (Your existing script) ---
  # 2. Define the Systemd Service
  systemd.services.docker-mount-fix = {
    description = "Fix Docker Desktop mounts on WSL start";
    wantedBy = [ "multi-user.target" ];

    # We remove the dependency on docker.socket because Docker Desktop manages that externally
    # We only wait for the network to be up generally
    after = [ "network.target" ];

    serviceConfig = {
      Type = "oneshot";
      # IMPORTANT: Change 'nixos' to your actual username (run 'whoami')
      User = "wsl";
      Group = "users";
      # If the script fails, don't consider the boot failed
      RemainAfterExit = true;
    };

    script = ''
      # 1. Setup Path
      export PATH=${
        lib.makeBinPath [
          pkgs.docker
          pkgs.docker-compose
          pkgs.jq
        ]
      }:$PATH

      echo "Starting Docker Fixer..."

      # 2. Wait for Docker Desktop to connect the socket
      # Since we don't have a systemd unit to wait for, we just poll the command
      retries=0
      while ! docker info > /dev/null 2>&1; do
        sleep 2
        retries=$((retries+1))
        if [ $retries -gt 30 ]; then
            echo "Timed out waiting for Docker Desktop."
            exit 1
        fi
      done

      echo "Docker is online! Waiting 5s for volume mounts to stabilize..."
      sleep 5

      # 3. Restart Stacks
      # Use the 'docker compose' plugin syntax
      echo "Restarting containers..."

      # We find all running compose projects and restart them
      projects=$(docker compose ls --format=json | jq -r '.[].ConfigFiles')

      if [ -z "$projects" ]; then
          echo "No active Docker Compose projects found to restart."
      else
          for config in $projects; do
            echo "Restarting stack defined in: $config"
            docker compose -f "$config" restart || echo "Failed to restart $config"
          done
      fi

      echo "Done!"
    '';
  };
}
