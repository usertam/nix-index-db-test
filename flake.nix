{
  inputs."master".url = "github:nixos/nixpkgs/master";
  inputs."nixpkgs-unstable".url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs."nixos-unstable".url = "github:nixos/nixpkgs/nixos-unstable";
  inputs."nixos-22.11".url = "github:nixos/nixpkgs/nixos-22.11";

  outputs = { self, ... }@inputs: let
    inherit (inputs.nixpkgs-unstable.lib) genAttrs platforms;
    forAllSystems = genAttrs platforms.unix;
    forAllChannels = genAttrs (builtins.attrNames inputs);
  in {
    packages = forAllSystems (system-host:
      forAllSystems (system: forAllChannels (channel: let
        pkgs = inputs.nixpkgs-unstable.legacyPackages.${system-host};
        lock = with builtins; fromJSON (readFile ./flake.lock);
        date = inputs.${channel}.lastModifiedDate;
        commit = inputs.${channel}.rev;
        abbrev = inputs.${channel}.shortRev;
      in pkgs.stdenv.mkDerivation (finalAttrs: {
        pname = "nix-index-db-src-${system}-${channel}";
        version = builtins.substring 2 6 date + "." + abbrev;
        src = self;
        nativeBuildInputs = [
          pkgs.nix-index
          pkgs.cacert
        ];
        dontUnpack = true;
        dontPatch = true;
        dontConfigure = true;
        buildPhase = ''
          mkdir -p $out/nix-index-db
          HOME=$TMP nix-index --db $out/nix-index-db --system ${system} \
            --nixpkgs https://github.com/NixOS/nixpkgs/tarball/${commit}
        '';
        installPhase = ''
          cat <<EOF > $out/flake.nix
          {
            outputs = { self }: let
              system = with builtins; head (match "^### (.*)/.*" (readFile ./README.md));
            in {
              packages.''${system}.default = self;
            };
          }
          EOF

          cat <<EOF > $out/flake.lock
          {
            "nodes": {
              "root": {}
            },
            "root": "root",
            "version": 7
          }
          EOF

          cat <<EOF > $out/README.md
          # nix-index-db
          ### ${system}/${channel} @ ${finalAttrs.version}
          - Nixpkgs: `${channel}`@[`${abbrev}`](https://github.com/NixOS/nixpkgs/commit/${commit})
          - Platform: `${system}`
          - Date: `${date}`
          EOF
        '';
      }))
    ) // forAllChannels (channel:
      self.packages.${system-host}.${system-host}.${channel}
    ));
  };
}
