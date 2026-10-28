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
    "context.modules" = [
      {
        name = "libpipewire-module-loopback";
        args = {
          "node.description" = "Microphone Proxy";
          "capture.props" = {
            "node.name" = "capture.microphone-proxy";
            "audio.position" = [ "MONO" ];
            "node.passive" = true;
          };
          "playback.props" = {
            "node.name" = "microphone-proxy";
            "media.class" = "Audio/Source";
            "audio.position" = [ "MONO" ];
            "filter.smart" = true;
            "filter.smart.name" = "microphone-proxy";
          };
        };
      }
      {
        name = "libpipewire-module-loopback";
        args = {
          "node.description" = "Main Audio";
          "capture.props" = {
            "node.name" = "main-audio";
            "media.class" = "Audio/Sink";
            "audio.position" = [ "FL" "FR" ];
            "filter.smart" = true;
            "filter.smart.name" = "main-audio";
          };
          "playback.props" = {
            "node.name" = "playback.main-audio";
            "audio.position" = [ "FL" "FR" ];
            "node.passive" = true;
          };
        };
      }
    ];

    "context.objects" = [
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