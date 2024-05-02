{
  outputs = { self }: let
    system = with builtins; head (match "^### (.*)/.*" (readFile ./README.md));
  in {
    packages.x86_64-linux.default = self;
  };
}
