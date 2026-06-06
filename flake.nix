{
  description = "slick";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    zig-overlay.url = "github:mitchellh/zig-overlay";
    zig-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      zig-overlay,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ zig-overlay.overlays.default ];
        };
        commonBuildInputs = with pkgs; [
          zig

          # X11 libraries required by raylib
          libx11
          libxcursor
          libxext
          libxfixes
          libxi
          libxinerama
          libxrandr
          libxrender

          # OpenGL libraries
          libGL
          libGLU
          mesa

          # Window management
          glfw

          # Additional libraries
          pkg-config

          # Audio libraries (raylib supports audio)
          alsa-lib
          pulseaudio
        ];

      in
      {
        devShells = {
          default = pkgs.mkShell {
            buildInputs = commonBuildInputs;

          shellHook = ''
            export PKG_CONFIG_PATH="${pkgs.lib.makeSearchPathOutput "dev" "lib/pkgconfig" [
              pkgs.libx11
              pkgs.libxcursor
              pkgs.libxext
              pkgs.libxfixes
              pkgs.libxi
              pkgs.libxinerama
              pkgs.libxrandr
              pkgs.libxrender
              pkgs.libGL
              pkgs.libGLU
              pkgs.mesa
              pkgs.glfw
              pkgs.alsa-lib
              pkgs.pulseaudio
            ]}:$PKG_CONFIG_PATH"
          '';
          };

          lsp = pkgs.mkShell {
            buildInputs =
              with pkgs;
              [
                zls
              ]
              ++ commonBuildInputs;
          };
        };
      }
    );
}
