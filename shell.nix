{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
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
} 