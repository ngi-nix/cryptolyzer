{
  description = "(insert short project description here)";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-22.05";

  # Upstream source tree(s).

  inputs.cryptoparser-src = {
    url = github:/c0r0n3r/cryptoparser;
    flake = false;
  };

  inputs.cryptolyzer-src = {
    url = github:/c0r0n3r/cryptolyzer;
    flake = false;
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let

      # System types to support.
      supportedSystems = [ "x86_64-linux" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });

    in

    {

      # A Nixpkgs overlay.
      overlay = final: prev: {

        cryptolyzer = with final; python3.pkgs.buildPythonPackage rec {

          name = "cryptolyzer";

          src = inputs.cryptolyzer-src;

          buildInputs = with python3Packages; [ 
                          python-dateutil 
                          requests
                          six
                          urllib3
                          attrs
                          certvalidator
                          cryptoparser ];

          pythonImportsCheck = [ "cryptolyzer" ];                          
          
          doCheck = false;

          meta = with lib; {
            homepage = "https://github.com/c0r0n3r/cryptolyzer";
            description = "CryptoLyzer is a fast and flexible server cryptographic settings analyzer library for Python";
            license = licenses.mpl20;
          };
        
        };

        cryptoparser = with final; python3.pkgs.buildPythonPackage rec {

          pname = "cryptoparser";
          
          version = "";
          
          src = inputs.cryptoparser-src;
          
          buildInputs =  with python3Packages; [
            asn1crypto
            attrs
            python-dateutil
            six
          ];
          
          pythonImportsCheck = [ "cryptoparser" ];
          
          doCheck = true;
          
          meta = with lib; {
            description = " A cryptographic protocol parser";
            homepage = https://github.com/c0r0n3r/cryptoparser;
            license = licenses.mpl20;
          };

        };
      };

      # Provide some binary packages for selected system types.
      packages = forAllSystems (system:
        {
          inherit (nixpkgsFor.${system}) cryptolyzer;
        });

      # The default package for 'nix build'. This makes sense if the
      # flake provides only one package or there is a clear "main"
      # package.
      defaultPackage = forAllSystems (system: self.packages.${system}.cryptolyzer);

    };
}
