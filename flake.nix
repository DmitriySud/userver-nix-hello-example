{
  description = "hello-service — a minimal userver HTTP service (core only)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";

    # Declare userver-src here, so userver-nix can follow it 
    # and we can use --override-input userver-src /home/...
    # while building hello-service in this repo
    userver-src = {
      url = "github:userver-framework/userver/v3.0";
      flake = false;
    };

    userver-nix = {
      url = "github:DmitriySud/userver-nix/master";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.userver-src.follows = "userver-src";
    };
  };

  outputs = { self, nixpkgs, flake-utils, userver-src, userver-nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Build userver with just the core feature, as this service only uses
        # userver::core. mkUserver is exposed per-system by the wrapper.
        userver = userver-nix.lib.${system}.mkUserver {
          features = { core = true; };
        };

        # Use the clang stdenv as requested.
        clangStdenv = pkgs.clangStdenv;

        hello-service = clangStdenv.mkDerivation {
          pname = "hello-service";
          version = "0.1.0";
          src = ./.;

          nativeBuildInputs = with pkgs; [ cmake ninja pkg-config python3 ];

          buildInputs = [
            userver
            pkgs.gbenchmark
          ];

          # Point find_package(userver ...) at the wrapper's installed package.
          cmakeFlags = [
            "-Duserver_DIR=${userver}/lib/cmake/userver"
            "-DCMAKE_BUILD_TYPE=Release"
            "-DUSERVER_FEATURE_TESTSUITE=OFF"
          ];

          meta = with pkgs.lib; {
            description = "Minimal userver HTTP service that says hello";
            license = licenses.asl20;
            platforms = platforms.linux;
            mainProgram = "hello_service";
          };
        };
      in {
        packages = {
          default = hello-service;
          hello-service = hello-service;
        };

        apps.default = {
          type = "app";
          # Run with the bundled static config.
          program = "${pkgs.writeShellScript "run-hello-service" ''
            exec ${hello-service}/bin/hello_service \
              -c ${hello-service}/share/hello_service/static_config.yaml
          ''}";
        };

        devShells.default = clangStdenv.mkDerivation {
          name = "hello-service-dev";
          nativeBuildInputs = with pkgs; [
            cmake ninja pkg-config
            clang-tools   # clangd / clang-format
            gdb
          ];
          buildInputs = [ userver pkgs.fmt ];
          shellHook = ''
            export userver_DIR="${userver}/lib/cmake/userver"
            echo "hello-service dev shell (clang). userver_DIR set."
            echo "Configure: cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug"
          '';
        };
      });
}
