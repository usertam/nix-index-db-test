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
          passthru.toybox
          passthru.readme
        ];
        dontUnpack = true;
        dontPatch = true;
        dontConfigure = true;
        buildPhase = ''
          HOME=$TMP nix-index --db $TMP --system ${system} \
            --nixpkgs https://github.com/NixOS/nixpkgs/tarball/${inputs.${channel}.rev}
          install -Dm444 $TMP/files $out/nix-index-db
        '';
        installPhase = ''
          install -Dm555 -t $out ${passthru.toybox}/bin/toybox
          install -Dm444 -t $out $src/template/flake.nix $src/template/flake.lock \
            ${passthru.readme}/README.md
        '';
        passthru.toybox =
          if system == system-host then pkgs.pkgsStatic.toybox
          else pkgs.pkgsCross.${
            if system == "aarch64-linux" then "aarch64-multiplatform"
            else if system == "i686-linux" then "gnu32"
            else system
          }.pkgsStatic.toybox;
        passthru.readme = import ./template/README.nix {
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
