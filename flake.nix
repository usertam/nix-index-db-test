{
  inputs."master".url = "github:nixos/nixpkgs/master";
  inputs."nixpkgs-unstable".url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs."nixos-unstable".url = "github:nixos/nixpkgs/nixos-unstable";
  inputs."nixos-24.05".url = "github:nixos/nixpkgs/nixos-24.05";

  outputs = { self, ... }@inputs: let
    inherit (inputs.nixpkgs-unstable.lib) genAttrs platforms;
    forAllSystems = genAttrs platforms.unix;
    forAllChannels = genAttrs (builtins.attrNames inputs);
  in {
    packages = forAllSystems (system-host:
      forAllSystems (system: forAllChannels (channel: let
        pkgs = inputs.nixpkgs-unstable.legacyPackages.${system-host};
        lock = with builtins; fromJSON (readFile ./flake.lock);
        flake = inputs.${channel};
      in pkgs.stdenv.mkDerivation (final: {
        pname = "nix-index-db-src-${system}-${channel}";
        version = builtins.substring 2 6 flake.lastModifiedDate + "." + flake.shortRev;
        src = self;
        nativeBuildInputs = with pkgs; [
          nix-index
          cacert
        ];
        buildPhase = ''
          mkdir -p $out/nix-index-db
          HOME=$TMP nix-index --db $out/nix-index-db --system ${system} \
            --nixpkgs https://github.com/NixOS/nixpkgs/tarball/${flake.rev}
        '';
        installPhase = ''
          cat <<'EOF' > $out/flake.nix
          {
            outputs.packages.${system}.default = self;
          }
          EOF

          cat <<'EOF' > $out/flake.lock
          {
            "nodes": {
              "root": {}
            },
            "root": "root",
            "version": 7
          }
          EOF

          cat <<'EOF' > $out/README.md
          # nix-index-db
          ### ${system}/${channel} @ ${final.version}
          - Nixpkgs: `${channel}`@[`${flake.shortRev}`](https://github.com/NixOS/nixpkgs/commit/${flake.rev})
          - Platform: `${system}`
          - Timestamp: `${flake.lastModifiedDate}`
          EOF
        '';
      }))
    ) // forAllChannels (channel:
      self.packages.${system-host}.${system-host}.${channel}
    ));
  };
}
