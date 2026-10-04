# mpv video/audio player (Wayland + VA-API, uosc UI, MPRIS for Noctalia bar).
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.mpv;
in
{
  options.userSettings.programs.mpv.enable = lib.mkEnableOption "mpv media player";

  config = lib.mkIf cfg.enable {
    programs.mpv = {
      enable = true;

      scripts = with pkgs.mpvScripts; [
        uosc
        thumbfast
        mpris
      ];

      # uosc replaces the built-in OSC: slim, themeable (Stylix fills colors),
      # with thumbnails via thumbfast.
      scriptOpts = {
        uosc = {
          timeline_style = "bar";
          timeline_size = 4;
          controls = "menu,gap,subtitles,audio,video,fullscreen,speed,shuffle,loop-playlist,loop-file,gap,prev,play-pause,next,gap,volume";
          volume_controls = "mute";
          top_bar_controls = "title,buy,close";
          window_border = "no";
          autoload = true;
          autoload_playlist = true;
        };
        thumbfast = {
          max_height = 200;
          max_width = 320;
          network = "yes";
        };
      };

      config = {
        # --- Video output: Wayland-native, high quality, Intel VA-API ---
        vo = "gpu-next";
        gpu-context = "wayland";
        hwdec = "vaapi";
        hwdec-codecs = "all";
        profile = "high-quality";
        scale = "ewa_lanczossharp";
        cscale = "ewa_lanczossharp";
        deband = true;
        dither-depth = "auto";

        # --- Window: let Hyprland own borders/rounding ---
        osc = "no";
        osd-bar = "no";
        border = "no";
        keep-open = "yes";
        force-window = "immediate";
        autofit-larger = "80%x80%";
        screenshot-directory = "~/Pictures/Screenshots";
        screenshot-template = "mpv-%F-%P";

        # --- Audio ---
        volume-max = 130;
        audio-channels = "auto-safe";

        # --- Subs: PT preferred, styled, readable on dark theme ---
        sub-auto = "fuzzy";
        slang = "pt-PT,pt,en";
        alang = "pt-PT,pt,en";
        sub-font-size = 44;
        sub-border-size = 2;
        sub-shadow-offset = 1;
        sub-blur = 0.2;

        # --- Behaviour: resume, playlist, cache, streaming ---
        save-position-on-quit = true;
        resume-playback-check-mtime = true;
        loop-playlist = "no";
        playlist-start = 0;
        prefetch-playlist = true;
        demuxer-max-bytes = "512MiB";
        demuxer-max-back-bytes = "256MiB";
        cache-secs = 30;
        ytdl-format = "bestvideo+bestaudio/best";
      };

      bindings = {
        # Core (also clickable via uosc)
        "SPACE" = "cycle pause";
        "q" = "quit";
        "Q" = "quit-watch-later";
        "f" = "cycle fullscreen";
        "m" = "cycle mute";
        "o" = "show-progress";

        # YouTube-style seeking
        "j" = "seek -10";
        "l" = "seek 10";
        "k" = "cycle pause";
        "LEFT" = "seek -5";
        "RIGHT" = "seek 5";
        "UP" = "add volume 5";
        "DOWN" = "add volume -5";
        "," = "frame-step";
        "." = "frame-back-step";
        "BS" = "set speed 1.0";

        # Playlist / chapters
        ">" = "playlist-next";
        "<" = "playlist-prev";
        "n" = "playlist-next";
        "p" = "playlist-prev";
        "H" = "cycle shuffle";
        "r" = "cycle values loop-file \"inf\" \"no\"";
        "PgUp" = "add chapter 1";
        "PgDwn" = "add chapter -1";

        # Tracks
        "v" = "cycle sub";
        "a" = "cycle audio";
        "A" = "cycle video";
        "T" = "cycle ontop";

        # Screenshots (go to ~/Pictures/Screenshots)
        "s" = "screenshot video";
        "S" = "screenshot subtitles";
        "Ctrl+s" = "screenshot window";
      };
    };

    # yt-dlp: mpv plays URLs directly (mpv <url>). playerctl: MPRIS control
    # so the Noctalia bar media widget + XF86 keys keep working.
    home.packages = with pkgs; [
      yt-dlp
      playerctl
    ];
  };
}
