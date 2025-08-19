{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    zig.url = "github:mitchellh/zig-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, ... } @ inputs: flake-utils.lib.eachDefaultSystem(system: let
    pkgs = import nixpkgs { inherit system overlays; };
    zig-version = "0.14.1";
    overlays = [(prev: _: (let inherit (prev) system; in {
      zig = inputs.zig.packages.${system}.${zig-version};
    }))];
  in {
    devShells.default = pkgs.mkShell {
      buildInputs = with pkgs; [ pkg-config zig zls ];
      nativeBuildInputs = with pkgs; [ gtk3 vte ];
    };
  });
}
