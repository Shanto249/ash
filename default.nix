{ pkgs ? import <nixpkgs> {} }:

let
  pythonWithPackages = pkgs.python3.withPackages (ps: with ps; [
    requests
    configparser
  ]);
in
pkgs.stdenv.mkDerivation {
  pname = "n-command";
  version = "0.1.0";
  src = ./.;

  buildInputs = [
    pythonWithPackages
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp ./n.py $out/bin/n
    chmod +x $out/bin/n
    # Fix the shebang
    substituteInPlace $out/bin/n \
      --replace "#!/usr/bin/env python3" "#!${pythonWithPackages}/bin/python3"
  '';

  meta = with pkgs.lib; {
    description = "Natural language command generator using Ollama with configuration menu";
    homepage = "https://github.com/user/n-command";
    license = licenses.mit;
    platforms = platforms.all;
  };
} 