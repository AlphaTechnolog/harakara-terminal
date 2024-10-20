{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    
    zig = {
      url = "github:mitchellh/zig-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "";
      };
    };
  };

  outputs = { self, nixpkgs, flake-utils, zig }: flake-utils.lib.eachDefaultSystem(system: let
    pkgs = import nixpkgs {inherit system;};
    zig-dev = zig.packages.${system}."0.13.0";
  in {
    packages = let
      makeBuild = optimize: pkgs.callPackage ./nix/package.nix {
        inherit (pkgs) zig_0_13;
        inherit optimize;
      };
    in {
      default = self.packages.${system}.harakara-terminal-release;
      harakara-terminal-debug = makeBuild "Debug";
      harakara-terminal-release = makeBuild "ReleaseFast";
    };

    devShells.default = pkgs.mkShell (let
      inherit (pkgs) lib;
    in {
      LD_LIBRARY_PATH = lib.makeLibraryPath (with pkgs; [
        gtk3
        glib
        vte
      ]);

      nativeBuildInputs = with pkgs; [
        gtk3
        glib
        pkg-config
        vte
      ];

      buildInputs = [
        zig-dev
        self.packages.${system}.harakara-terminal-debug
      ];
    });
  });
}
