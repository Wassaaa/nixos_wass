#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3
"""
Noctalia GUI Settings to Nix Template Sync Script
Run this after configuring your bar in the GUI to sync changes to the Nix config.
"""

import json
import os
import sys
from pathlib import Path
from datetime import datetime

class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    NC = '\033[0m'

def print_header():
    print(f"{Colors.BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.NC}")
    print(f"{Colors.BLUE}   Noctalia GUI Settings to Nix Template Sync{Colors.NC}")
    print(f"{Colors.BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{Colors.NC}\n")

def json_to_nix(obj, indent=0):
    """Convert JSON to Nix attribute set format"""
    spaces = "  " * indent

    if isinstance(obj, dict):
        if not obj:
            return "{}"
        lines = ["{"]
        for key, value in obj.items():
            if "-" in key or key in ["location", "timeout"]:
                nix_key = f'"{key}"'
            else:
                nix_key = key
            lines.append(f"{spaces}  {nix_key} = {json_to_nix(value, indent + 1)};")
        lines.append(f"{spaces}}}")
        return "\n".join(lines)
    elif isinstance(obj, list):
        if not obj:
            return "[ ]"
        if all(isinstance(item, dict) for item in obj):
            lines = ["["]
            for item in obj:
                item_str = json_to_nix(item, indent + 1)
                lines.append(f"{spaces}  {item_str}")
            lines.append(f"{spaces}]")
            return "\n".join(lines)
        else:
            return "[ " + " ".join(json_to_nix(item, indent) for item in obj) + " ]"
    elif isinstance(obj, bool):
        return "true" if obj else "false"
    elif isinstance(obj, (int, float)):
        return str(obj)
    elif isinstance(obj, str):
        return f'"{obj}"'
    else:
        return str(obj)

def main():
    print_header()

    script_dir = Path(__file__).parent
    nix_file = script_dir / "default.nix"
    settings_file = Path.home() / ".config" / "noctalia" / "settings.json"
    backup_dir = script_dir / "backups"

    if not settings_file.exists():
        print(f"{Colors.RED}Error: Settings file not found at {settings_file}{Colors.NC}")
        print("Make sure you have configured Noctalia through the GUI first.")
        return 1

    if settings_file.is_symlink():
        print(f"{Colors.YELLOW}Warning: Settings file is a symlink (read-only){Colors.NC}")
        print("You need to rebuild first to get the writable config.")
        return 1

    backup_dir.mkdir(exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_file = backup_dir / f"default.nix.{timestamp}"

    if nix_file.exists():
        backup_file.write_text(nix_file.read_text())
        print(f"{Colors.GREEN}✓{Colors.NC} Backed up current config to: {backup_file}")

    try:
        with open(settings_file) as f:
            settings = json.load(f)
    except json.JSONDecodeError as e:
        print(f"{Colors.RED}Error: Invalid JSON in settings file: {e}{Colors.NC}")
        return 1

    print(f"{Colors.BLUE}Current GUI Settings Preview:{Colors.NC}")
    preview = json.dumps(settings, indent=2)
    print(preview[:400] + "...\n" if len(preview) > 400 else preview + "\n")

    nix_settings = json_to_nix(settings, indent=3)

    nix_template = '''{{
  config,
  lib,
  pkgs,
  inputs,
  host,
  ...
}}:
let
  variables = import ../../../hosts/${{host}}/variables.nix;
  barChoice = variables.barChoice or "waybar";
  enableNoctalia = barChoice == "noctalia";
in
{{
  imports = lib.optionals enableNoctalia [
    inputs.noctalia.homeModules.default
  ];

  config = lib.mkIf enableNoctalia {{
    programs.waybar.enable = lib.mkForce false;
    home.packages = [ inputs.noctalia.packages.${{pkgs.system}}.default ];

    home.file.".config/noctalia/settings.json.template" = {{
      text = builtins.toJSON {settings};
    }};

    home.activation.noctaliaSettingsInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      SETTINGS_FILE="$HOME/.config/noctalia/settings.json"
      TEMPLATE_FILE="$HOME/.config/noctalia/settings.json.template"

      if [ ! -f "$SETTINGS_FILE" ] || [ -L "$SETTINGS_FILE" ]; then
        $DRY_RUN_CMD rm -f "$SETTINGS_FILE"
        $DRY_RUN_CMD cp "$TEMPLATE_FILE" "$SETTINGS_FILE"
        $DRY_RUN_CMD chmod 644 "$SETTINGS_FILE"
      fi
    '';

    home.activation.noctaliaWarning = lib.hm.dag.entryAfter [ "noctaliaSettingsInit" ] ''
      $DRY_RUN_CMD echo ""
      $DRY_RUN_CMD echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      $DRY_RUN_CMD echo "🌙 Noctalia Shell is ENABLED"
      $DRY_RUN_CMD echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      $DRY_RUN_CMD echo ""
      $DRY_RUN_CMD echo "⚠️  Waybar has been automatically disabled"
      $DRY_RUN_CMD echo ""
      $DRY_RUN_CMD echo "📝 Configuration: ~/.config/noctalia/settings.json (GUI-editable)"
      $DRY_RUN_CMD echo "🎨 Settings synced from GUI (use ./sync-from-gui.py to update)"
      $DRY_RUN_CMD echo "✏️  All GUI changes persist across reboots"
      $DRY_RUN_CMD echo ""
      $DRY_RUN_CMD echo "💡 To update Nix template from GUI changes:"
      $DRY_RUN_CMD echo "   cd modules/home/noctalia-shell && ./sync-from-gui.py"
      $DRY_RUN_CMD echo ""
      $DRY_RUN_CMD echo "📚 Docs: https://docs.noctalia.dev"
      $DRY_RUN_CMD echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      $DRY_RUN_CMD echo ""
    '';
  }};
}}
'''

    nix_content = nix_template.format(settings=nix_settings)
    nix_file.write_text(nix_content)

    print(f"{Colors.GREEN}✓{Colors.NC} Nix template updated with your GUI settings!")
    print(f"{Colors.GREEN}✓{Colors.NC} Changes saved to: {nix_file}\n")
    print(f"{Colors.YELLOW}Next steps:{Colors.NC}")
    print("  1. Review: git diff modules/home/noctalia-shell/default.nix")
    print("  2. Test: dcli build")
    print("  3. Apply: dcli rebuild")
    print("  4. Commit changes\n")
    print(f"{Colors.BLUE}💡 Tip:{Colors.NC} Your GUI settings are already working.")
    print("    This updates the template for fresh installs or resets.\n")

    return 0

if __name__ == "__main__":
    sys.exit(main())
