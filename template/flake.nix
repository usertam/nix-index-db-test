{
  outputs = { self }: with builtins; let
    meta = match "^.*# (.+) / (.+) @ ([a-z0-9.]+).*$" (readFile ./README.md);
    system = elemAt meta 0;
    channel = elemAt meta 1;
    version = elemAt meta 2;
  in {
    packages.${system}.default = derivation rec {
      inherit system version;
      pname = "nix-index-db-${system}-${channel}";
      name = "${pname}-${version}";
      builder = "${self}/toybox";
      args = [
        "install" "-D" "${self}/nix-index-db"
        "${placeholder "out"}/files"
      ];
    };
  };
}
