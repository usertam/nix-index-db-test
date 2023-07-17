{
  outputs = { self }: let
    system = with builtins; elemAt (match
      "^.*Platform: `([a-z0-9-]+)`.*$"
      (readFile ./README.md)) 0;
  in {
    packages.${system}.default = ./.;
  };
}
