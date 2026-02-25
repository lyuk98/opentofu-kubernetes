{
  pkgs ? import <nixpkgs> { },
  ...
}:
{
  # The default development environment
  default = pkgs.mkShellNoCC {
    nativeBuildInputs = with pkgs; [
      graphviz # for converting DOT files
      opentofu
      python3
    ];
  };
}
