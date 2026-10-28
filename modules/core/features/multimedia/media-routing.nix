{ pkgs, config, ... }:
{
  assertions = [
    {
      assertion = config.services.pipewire.enable;
      message = "Media routing requires PipeWire audio to be enabled.";
    }
  ];

  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 exclusive_caps=1 card_label="OBS Virtual Camera"
  '';

  services.pipewire.extraConfig.pipewire."91-virtual-audio" = {
    "context.objects" = [
      {
        factory = "adapter";
        args = {
          "factory.name" = "support.null-audio-sink";
          "node.name" = "microphone-proxy";
          "node.description" = "Microphone Proxy";
          "media.class" = "Audio/Source/Virtual";
          "audio.position" = [ "MONO" ];
          "priority.session" = 1;
        };
      }
      {
        factory = "adapter";
        args = {
          "factory.name" = "support.null-audio-sink";
          "node.name" = "obs-track-1";
          "node.description" = "OBS Track 1";
          "media.class" = "Audio/Sink";
          "audio.position" = [ "FL" "FR" ];
          "priority.session" = 1;
        };
      }
      {
        factory = "adapter";
        args = {
          "factory.name" = "support.null-audio-sink";
          "node.name" = "obs-track-2";
          "node.description" = "OBS Track 2";
          "media.class" = "Audio/Sink";
          "audio.position" = [ "FL" "FR" ];
          "priority.session" = 1;
        };
      }
    ];
  };

  environment.systemPackages = with pkgs; [
    obs-studio
    qpwgraph
  ];
}