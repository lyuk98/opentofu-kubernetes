{
  pkgs ? import <nixpkgs> { },
  ...
}:
{
  # The default development environment
  default = pkgs.mkShellNoCC {
    nativeBuildInputs = with pkgs; [
      cacert # for fetching from Git over HTTPS
      git
      opentofu
      python3
    ];
  };
}
