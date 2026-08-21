{
  description = "App Windows — Plasma 6 applet showing the windows of the currently active application";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      # Single source of truth: the plugin id and version come from metadata.json,
      # so they can't drift from what Plasma actually reads. The install directory
      # name MUST equal KPlugin.Id or plasmashell won't find the applet.
      meta' = (builtins.fromJSON (builtins.readFile ./metadata.json)).KPlugin;
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      package =
        pkgs:
        pkgs.stdenvNoCC.mkDerivation {
          pname = "plasma-appwindows";
          version = meta'.Version;

          # `self` is this flake's source, so there is no rev/hash to keep in sync.
          src = self;

          # Pure QML: nothing to compile, just place the KPackage where Plasma looks.
          dontBuild = true;

          installPhase = ''
            runHook preInstall
            dir=$out/share/plasma/plasmoids/${meta'.Id}
            install -Dm444 metadata.json -t $dir
            cp -r contents $dir/
            runHook postInstall
          '';

          meta = {
            description = meta'.Description;
            homepage = "https://github.com/xapienz/plasma-appwindows";
            license = pkgs.lib.licenses.gpl2Plus;
            platforms = systems;
          };
        };
    in
    {
      packages = forAllSystems (pkgs: rec {
        plasma-appwindows = package pkgs;
        default = plasma-appwindows;
      });

      # For consumers who prefer an overlay to a direct package reference.
      overlays.default = final: _prev: { plasma-appwindows = package final; };
    };
}
