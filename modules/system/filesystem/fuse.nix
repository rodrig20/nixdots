# Allows --allow-other on FUSE mounts (writes user_allow_other to
# /etc/fuse.conf); without it fusermount rejects the flag.
{ config, pkgs, lib, ... }:

{
  options.systemSettings.fuse.allowOther = lib.mkEnableOption "user_allow_other in /etc/fuse.conf (--allow-other on FUSE mounts)";

  config = lib.mkIf config.systemSettings.fuse.allowOther {
    programs.fuse.userAllowOther = true;
  };
}
