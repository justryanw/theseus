{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, rust-overlay }:
    let
      overlays = [
        (import rust-overlay)
        (self: super: {
          rustToolchain = super.rust-bin.stable.latest.default;
        })
      ];

      allSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      forAllSystems = f: nixpkgs.lib.genAttrs allSystems (system: f {
        pkgs = import nixpkgs { inherit overlays system; };
      });
    in
    {
      packages = forAllSystems
        ({ pkgs }:
          let
            repo = pkgs.fetchFromGitHub {
              owner = "modrinth";
              repo = "theseus";
              rev = "84d731b6700a873691eb1300a8d15619fa39922e";
              sha256 = "sha256-nIL1+J5JVvC9BBdSNIfpIjsV82uBcU1IIHrwPZn3BJ4=";
            };

            front-end = pkgs.buildNpmPackage {
              name = "theseus_gui";

              buildInputs = (with pkgs; [
                nodejs
              ]);

              src = "${repo}/theseus_gui";
              npmDepsHash = "sha256-auHag5J1R/4Ta59VfTE3KNtrnojldyB9hlIwX8dZPtA=";

              npmBuild = "npm run build";

              postPatch = ''
                cp ${./package-lock.json} ./package-lock.json
              '';

              installPhase = ''
                mkdir $out
                cp -r dist $out
              '';
            };
          in
          {
            default = pkgs.rustPlatform.buildRustPackage {
              src = "${repo}";

              name = "theseus_gui";

              cargoLock = {
                lockFile = "${repo}/Cargo.lock";
                outputHashes = {
                  "tauri-plugin-single-instance-0.0.0" = "sha256-GkWRIVhiPGds5ocht1K0eetfeDCvyX4wRr1JheO7aik=";
                };
              };

              cargoBuildFlags = "--bin theseus_gui";

              nativeBuildInputs = (with pkgs; [
                pkg-config
              ]);

              buildInputs = (with pkgs; [
                openssl
                libsoup
                gtk4
                atkmm
                webkitgtk
                nodejs
              ]);

              postPatch = ''
                mkdir -p ./theseus_gui/dist
                cp -R ${front-end}/dist/. ./theseus_gui/dist/.
              '';
            };
          });
    };
}
