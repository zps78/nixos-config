# ../../modules/services/paperless.nix
#
# Paperless-ngx, native - successor of the container on the Unraid karma.
# SQLite + the module's own Redis; OCR in English and Portuguese. Logins
# are Paperless's own users (moved over from karma with the importer).
#
#   web UI   http://<host>:28981   (interfaces + Tailscale only)
#   consume  <consumptionDir>      (scanner drop folder; SMB comes later)
#   export   <dataDir>/export      (nightly full export - portable backup,
#                                   readable without Paperless)
#
# Moving data in (same Paperless version on both sides!):
#   karma:  docker exec <container> document_exporter ../export
#   here:   sudo paperless-manage document_importer /path/to/export
{ config, lib, ... }:

let
  cfg = config.myServices.paperless;
  port = 28981;
in
{
  options.myServices.paperless = {
    enable = lib.mkEnableOption "Paperless-ngx document archive";

    interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Open the web UI only on these interfaces (tailscale0 is trusted fleet-wide anyway).";
    };
  };

  config = lib.mkIf cfg.enable {
    services.paperless = {
      enable = true;
      address = "0.0.0.0";               # the firewall decides who gets in
      inherit port;
      settings = {
        # karma's container settings (2026-11-23)
        # (also selects the tesseract language packs - the container's
        # PAPERLESS_OCR_LANGUAGES install list isn't needed here)
        PAPERLESS_OCR_LANGUAGE = "eng+por";
        PAPERLESS_FILENAME_FORMAT = "{created}-{correspondent}-{title}";
        PAPERLESS_TIME_ZONE = "Europe/Lisbon";
        PAPERLESS_CONSUMER_POLLING = 0;    # inotify; set when the drop folder is on SMB
      };
      # Nightly full export to <dataDir>/export: a second, plain-file copy of
      # everything (documents + metadata), inside the snapshotted dataset.
      exporter.enable = true;
    };

    networking.firewall.interfaces = lib.genAttrs cfg.interfaces (_: {
      allowedTCPPorts = [ port ];
    });
  };
}
