{ pkgs, config, ... }:

{
  # Install socat for Chrome remote debugging bridge
  home.packages = with pkgs; [
    socat
  ];

  # Create dummy browser script (prevents Antigravity from spawning Chrome)
  home.file.".local/bin/dummy-browser.sh" = {
    text = ''
      #!/usr/bin/env bash
      echo "DevTools listening on ws://127.0.0.1:9222/devtools/browser/fake-uuid"
      sleep 365d
    '';
    executable = true;
  };

  # Test Chrome connection
  home.file.".local/bin/chrome-bridge-test" = {
    text = ''
      #!/usr/bin/env bash
      echo "[INFO] Testing Chrome connection..."
      if curl -s http://localhost:9222/json/version | head -3; then
          echo ""
          echo "[SUCCESS] Chrome debug port is accessible!"
      else
          echo ""
          echo "[ERROR] Cannot connect to Chrome"
          echo ""
          echo "Make sure Chrome is running on Windows (PowerShell):"
          echo "  & \"C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe\" --remote-debugging-port=9223 --user-data-dir=\"C:\\chrome-profile\""
      fi
    '';
    executable = true;
  };

  # Setup guide
  home.file.".local/bin/chrome-bridge-setup" = {
    text = ''
      #!/usr/bin/env bash
      WIN_IP=$(ip route show | grep -i default | awk '{ print $3}')

      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "ANTIGRAVITY CHROME BRIDGE - Setup Guide"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      echo "ARCHITECTURE:"
      echo "  Antigravity → dummy-browser.sh → socat → Python proxy → Chrome"
      echo "  (WSL)                          (systemd)  (Windows)      (9223)"
      echo ""
      echo "━━━ ANTIGRAVITY SETTINGS ━━━"
      echo ""
      echo "  Browser Binary Path: ${config.home.homeDirectory}/.local/bin/dummy-browser.sh"
      echo "  Browser CDP Port: 9222"
      echo ""
      echo "━━━ WINDOWS SETUP (One-Time) ━━━"
      echo ""
      echo "1. Copy Python proxy:"
      echo "   Copy ~/.local/share/antigravity/chrome-proxy.py to Windows"
      echo "   Example: C:\\Users\\<USERNAME>\\chrome-proxy.py"
      echo ""
      echo "2. Firewall (PowerShell Admin):"
      echo "   New-NetFirewallRule -DisplayName \"Chrome Debug\" -Direction Inbound -LocalPort 9222 -Protocol TCP -Action Allow -Profile Any"
      echo ""
      echo "━━━ DAILY WORKFLOW ━━━"
      echo ""
      echo "Terminal 1 (Windows) - Python Proxy:"
      echo "   python C:\\Users\\<USERNAME>\\chrome-proxy.py"
      echo ""
      echo "Terminal 2 (Windows) - Chrome:"
      echo "   & \"C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe\" --remote-debugging-port=9223 --user-data-dir=\"C:\\chrome-profile\""
      echo ""
      echo "WSL: Bridge runs automatically (systemd service)"
      echo ""
      echo "━━━ SERVICE MANAGEMENT ━━━"
      echo ""
      echo "  systemctl --user status chrome-bridge    # Check status"
      echo "  systemctl --user restart chrome-bridge   # Restart"
      echo "  journalctl --user -u chrome-bridge -n 20 # View logs"
      echo "  chrome-bridge-test                       # Test connection"
      echo ""
    '';
    executable = true;
  };

  # Systemd user service for Chrome bridge
  systemd.user.services.chrome-bridge = {
    Unit = {
      Description = "Antigravity Chrome Remote Debugging Bridge";
      After = [ "network-online.target" ];
    };

    Service = {
      Type = "simple";

      # Dynamically detect WSL gateway IP and start socat tunnel
      ExecStart = pkgs.writeShellScript "chrome-bridge-service" ''
        WIN_IP=$(${pkgs.iproute2}/bin/ip route show | ${pkgs.gnugrep}/bin/grep -i default | ${pkgs.gawk}/bin/awk '{ print $3}')

        if [ -z "$WIN_IP" ]; then
          echo "[ERROR] Could not detect WSL gateway IP"
          exit 1
        fi

        echo "[INFO] Chrome bridge started: localhost:9222 -> $WIN_IP:9222"
        exec ${pkgs.socat}/bin/socat TCP-LISTEN:9222,fork,reuseaddr TCP:$WIN_IP:9222
      '';

      Restart = "always";
      RestartSec = "5s";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
