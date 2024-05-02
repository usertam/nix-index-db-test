{
  outputs = { self }: let
    system = with builtins; head (match "^### (.*)/.*" (readFile ./README.md));
  in {
    packages.aarch64-darwin.default = self;
  };
}
