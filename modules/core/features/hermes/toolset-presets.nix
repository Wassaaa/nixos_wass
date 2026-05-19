# Shared Hermes gateway toolset presets.
#
# Add or edit preset sections here, then rebuild. The main WSL helper
# (`hermes-wsl`) and fleet helper (`hermes-fleet`) both consume this file.
{
  # Toolsets managed by presets. Applying a preset first disables every toolset
  # in this list for the Discord platform, then enables the chosen preset.
  all = [
    "web"
    "browser"
    "terminal"
    "file"
    "code_execution"
    "vision"
    "video"
    "image_gen"
    "video_gen"
    "x_search"
    "moa"
    "tts"
    "skills"
    "todo"
    "memory"
    "session_search"
    "clarify"
    "delegation"
    "cronjob"
    "messaging"
    "homeassistant"
    "spotify"
    "discord"
    "discord_admin"
    "yuanbao"
    "computer_use"
  ];

  presets = {
    full = [
      "web"
      "browser"
      "terminal"
      "file"
      "code_execution"
      "vision"
      "video"
      "image_gen"
      "video_gen"
      "tts"
      "skills"
      "todo"
      "memory"
      "session_search"
      "clarify"
      "delegation"
      "cronjob"
      "messaging"
      "computer_use"
    ];

    code = [
      "web"
      "browser"
      "terminal"
      "file"
      "code_execution"
      "vision"
      "skills"
      "todo"
      "memory"
      "session_search"
      "clarify"
      "delegation"
      "cronjob"
    ];
  };
}
