{
  description = "n-command - Natural language to shell command converter";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "n-command";
          version = "0.1.0";
          src = ./.;

          buildInputs = with pkgs; [
            (python3.withPackages (ps: with ps; [
              requests
              configparser
            ]))
          ];

          installPhase = ''
            mkdir -p $out/bin
            cp ./n.py $out/bin/n
            chmod +x $out/bin/n
          '';

          meta = with pkgs.lib; {
            description = "Natural language command generator using Ollama with configuration menu";
            homepage = "https://github.com/user/n-command";
            license = licenses.mit;
            platforms = platforms.all;
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            python3
            python3Packages.requests
            python3Packages.pip
            python3Packages.virtualenv
          ];

          shellHook = ''
            # Create and activate a virtualenv if it doesn't exist
            if [ ! -d "venv" ]; then
              virtualenv venv
            fi
            source venv/bin/activate
            
            # Install required packages in the virtualenv
            pip install requests
            
            # Notify user that the environment is ready
            echo "Development environment activated. Run 'python n.py your command' to test."
          '';
        };
      }
    );
} 