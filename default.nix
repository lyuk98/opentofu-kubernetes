{
  pkgs ? import <nixpkgs> { },
  ...
}:
{
  # The default development environment
  default = pkgs.mkShellNoCC {
    nativeBuildInputs = with pkgs; [
      opentofu
      python3
    ];
  };
}
