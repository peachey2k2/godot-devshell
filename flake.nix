{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};

      # set up the version and and specify if it's mono here
      version = "3.4.2-stable";
      is_mono = false;
      
      major-ver = pkgs.lib.strings.toInt (builtins.substring 0 1 version);

      my-godot = pkgs.fetchurl {
        url = if major-ver == 4 then
          "https://github.com/godotengine/godot-builds/releases/download/${version}/Godot_v${version}${if is_mono then "_mono" else ""}_linux${if is_mono then "_" else "."}x86_64.zip"
        else
          "https://github.com/godotengine/godot-builds/releases/download/${version}/Godot_v${version}${if is_mono then "_mono_x11_64" else "_x11.64"}.zip";

        # you'll need to replace this :)
        hash = "sha256-Ll+iK6cIXmJlW4pXV6LPCrG7IhzkNd2y3NMJOVOGJt0=";
      };
      

      buildInputs = with pkgs; [
        alsa-lib
        dbus
        fontconfig
        libGL
        libpulseaudio
        libxkbcommon
        makeWrapper
        mesa
        patchelf
        speechd
        udev
        vulkan-loader
        xorg.libX11
        xorg.libXcursor
        xorg.libXext
        xorg.libXfixes
        xorg.libXi
        xorg.libXinerama
        xorg.libXrandr
        xorg.libXrender
      ] ++ lib.optional is_mono pkgs.dotnetCorePackages.sdk_8_0-source ;

      godot-unwrapped = pkgs.stdenv.mkDerivation {
        pname = "godot";
        version = version;

        src = my-godot;
        nativeBuildInputs = with pkgs; [unzip autoPatchelfHook];
        buildInputs = buildInputs;

        dontAutoPatchelf = false;

        unpackPhase = ''
          mkdir source
          unzip $src -d source
        '';

        installPhase = ''
          mkdir -p $out/bin
          ${
            if major-ver == 4 then
              if is_mono then /* sh */ ''
                cp source/Godot_v${version}_mono_linux_x86_64/Godot_v${version}${if is_mono then "_mono" else ""}_linux.x86_64 $out/bin/godot
                cp -r source/Godot_v${version}_mono_linux_x86_64/GodotSharp $out/bin/GodotSharp
              '' else /* sh */ ''
                cp source/Godot_v${version}_linux.x86_64 $out/bin/godot
              ''
            else /* sh */ ''
              cp source/Godot_v${version}_${if is_mono then "mono_x11_64" else "x11.64"} $out/bin/godot
            ''
          }
        '';
      };

      godot-bin = pkgs.buildFHSEnv {
        name = "godot";
        targetPkgs = pkgs: buildInputs ++ [godot-unwrapped];
        runScript = "godot";
      };
    in {
      devShell = pkgs.mkShell {
        buildInputs = [godot-bin];
      };
    });
}
