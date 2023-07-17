{
  inputs."master".url = "github:nixos/nixpkgs/master";
  inputs."nixpkgs-unstable".url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs."nixos-unstable".url = "github:nixos/nixpkgs/nixos-unstable";
  inputs."nixos-22.11".url = "github:nixos/nixpkgs/nixos-22.11";

  outputs = { self, ... }@inputs: let
    forAllSystems = with inputs.nixpkgs-unstable.lib; genAttrs platforms.unix;
    forAllChannels = drv: builtins.listToAttrs (map (ch: { name = ch; value = drv ch; }) (builtins.attrNames inputs));
  in {
    packages = forAllSystems (system-host:
      forAllSystems (system: forAllChannels (channel: let
        pkgs = inputs.nixpkgs-unstable.legacyPackages.${system-host};
        lock = with builtins; fromJSON (readFile ./flake.lock);
      in pkgs.stdenv.mkDerivation rec {
        pname = "nix-index-db-src-${system}-${channel}";
        version = builtins.substring 2 6 inputs.${channel}.lastModifiedDate
          + "." + inputs.${channel}.shortRev;
        src = self;
        nativeBuildInputs = [
          pkgs.nix-index
          pkgs.cacert
          passthru.README
        ];
        dontUnpack = true;
        dontPatch = true;
        dontConfigure = true;
        buildPhase = ''
          mkdir -p $out/nix-index-db
          HOME=$TMP nix-index --db $out/nix-index-db --system ${system} \
            --nixpkgs https://github.com/NixOS/nixpkgs/tarball/${inputs.${channel}.rev}
        '';
        installPhase = ''
          install -Dm444 -t $out $src/template/flake.nix $src/template/flake.lock \
            ${passthru.README}/README.md
        '';
        passthru.README = import ./template/README.nix {
          inherit (pkgs) writeTextDir;
          inherit (inputs.${channel}) rev shortRev lastModifiedDate;
          inherit system channel version;
        };
      })
    ) // forAllChannels (channel:
      self.packages.${system-host}.${system-host}.${channel}
    ));
  };
}
