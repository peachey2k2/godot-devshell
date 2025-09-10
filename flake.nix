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

      # set up the version and and specify if it's mono
      version = "4.5-rc1";
      is_mono = true;

      
      _mono = if is_mono then "_mono" else "";
      godot-stable = pkgs.fetchurl {
        url = "https://github.com/godotengine/godot-builds/releases/download/${version}/Godot_v${version}${_mono}_linux_x86_64.zip";
        hash = "sha256-VncVcJptJMntaf3HgTRa9ELCMgptczZOph2kJ9o7RBo=";
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
        version = "4.5-rc1";

        src = godot-stable;
        nativeBuildInputs = with pkgs; [unzip autoPatchelfHook];
        buildInputs = buildInputs;

        dontAutoPatchelf = false;

        unpackPhase = ''
          mkdir source
          unzip $src -d source
        '';

        installPhase = ''
          mkdir -p $out/bin
          ls source
          cp source/Godot_v${version}${_mono}_linux_x86_64/Godot_v${version}${_mono}_linux.x86_64 $out/bin/godot
          ${if is_mono then /* sh */ ''
            cp -r source/Godot_v${version}${_mono}_linux_x86_64/GodotSharp $out/bin/GodotSharp
          '' else ""}
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
