{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      packages.${system} = {
        cursor = pkgs.appimageTools.wrapType2 rec {
          name = "cursor";
          pname = "cursor";
          version = "0.45.15";
          src = pkgs.fetchurl {
            url = "https://downloader.cursor.sh/linux/appImage/x64";
            hash = "sha256-5MGWJi8TP+13jZf6YMMUU5uYY/3OBTFxtGpirvgj8ZI=";
          };

          extraInstallCommands =
            let
              contents = pkgs.appimageTools.extract { inherit pname version src; };
            in
            ''
              install -m 444 -D ${contents}/${pname}.desktop -t $out/share/applications
              substituteInPlace $out/share/applications/${pname}.desktop \
                --replace 'Exec=AppRun' 'Exec=${pname}'
              cp -r ${contents}/usr/share/icons $out/share

              # Ensure the binary exists and create a symlink if it doesn't already exist
              if [ -e ${contents}/AppRun ]; then
                install -m 755 -D ${contents}/AppRun $out/bin/${pname}-${version}
                if [ ! -L $out/bin/${pname} ]; then
                  ln -s $out/bin/${pname}-${version} $out/bin/${pname}
                fi
              else
                echo "Error: Binary not found in extracted AppImage contents."
                exit 1
              fi
            '';

          extraBuildInputs = with pkgs; [
            unzip
            autoPatchelfHook
            asar
            wrapGAppsHook
          ];

          meta = with pkgs.lib; {
            description = "AI code editor";
            homepage = "https://cursor.com";
            platforms = [ "x86_64-linux" ];
            mainProgram = "cursor";
          };
        };
      };

      defaultPackage.${system} = self.packages.${system}.cursor;
    };
}
