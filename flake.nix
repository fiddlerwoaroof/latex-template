{
  inputs = {
    nixpkgs = {
      type = "github";
      owner = "nixos";
      repo = "nixpkgs";
      rev = "5b4c18bac5159221b55eb1e85e7259e1e9e49b00";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    flake-utils,
    nixpkgs,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};

      texpkgs = pkgs.texlive.combine {
        inherit
          (pkgs.texlive)
          alegreya
          booklet
          booktabs
          csquotes
          currfile
          etoolbox
          float
          fontspec
          forloop
          geometry
          hyperref
          hyphen-latin
          hyphen-spanish
          intcalc
          latexmk
          luahbtex
          lualibs
          luatex
          luatexbase
          memoir
          microtype
          mparhack
          paracol
          pdflscape
          pdfpages
          pgf
          polyglossia
          ragged2e
          scheme-basic
          sourcecodepro
          textcase
          xpatch
          xstring
          ;
      };

      writeZsh = pkgs.writers.makeScriptWriter {interpreter = "${pkgs.zsh}/bin/zsh";};
      # tt = it: builtins.trace it it;

      ## To use custom font files, make `fc_config/fonts` directory and
      ## upload fonts there, then uncome this and references to it below
      #
      fonts = pkgs.stdenv.mkDerivation {
        name = "font-data";
        version = "0.0.0";
        buildInputs = [
          texpkgs
        ];
        src = ./fc_config;
        FONTCONFIG_PATH = ./fc_config;
        OSFONTDIR = ./fc_config/fonts;
        buildPhase = ''
          export TEXMFHOME="$out"
          export TEXMFVAR="$TEXMFHOME/texmf-var/"
          export FONTCONFIG_PATH="${./fc_config}"
          mkdir -p "$out"
          export OSFONTDIR="${./fc_config/fonts}"
          echo FONTCONFIG_PATH is $FONTCONFIG_PATH
          cp -R ./ "$out"
          luaotfload-tool -u -f
        '';
      };
    in {
      packages = {
        inherit fonts;
        default = pkgs.stdenv.mkDerivation {
          name = "main-pdf";
          version = "0.0.0";
          buildInputs = [
            texpkgs
            fonts
          ];
          src = ./src;
          buildPhase = ''
            export TEXMFHOME="$(mktemp -d)"
            export TEXMFVAR="$TEXMFHOME/texmf-var/"
            export FONTCONFIG_PATH="${fonts}"
            export OSFONTDIR="${fonts}/fonts"
            cp -R ${fonts}/texmf-var/ "$TEXMFVAR"
            chmod -R +w "$TEXMFVAR"
            echo FONTCONFIG_PATH is $FONTCONFIG_PATH
            luaotfload-tool  --find='Code2001'
            mkdir -p "$out"
            mkdir -p "$TEXMFVAR"
            make all
          '';
        };
        previews = let
          doc = self.packages.${system}.default;
        in
          pkgs.stdenv.mkDerivation {
            name = "main-pdf";
            version = "0.0.0";
            buildInputs = [
              doc
              #fonts
              pkgs.envsubst
              pkgs.ghostscript
              pkgs.imagemagick
              texpkgs
            ];
            src = ./src;
            buildPhase = ''
              cp "${doc}/main.pdf" .
	            gs -sDEVICE=png16m -o thumb'%02d'.png -r144 main.pdf
	            convert -background '#000' +smush 5 'thumb02.png' 'thumb03.png' combined1.png
	            convert -background '#000' +smush 5 'thumb04.png' 'thumb05.png' combined2.png
	            convert -background '#000' +smush 5 'thumb06.png' 'thumb07.png' combined3.png
            '';
            installPhase = ''
              mkdir -p "$out"
              cp thumb*.png combined*.png "$out"
            '';
          };
      };
      devShells.default = pkgs.mkShell {
        buildInputs = [
          texpkgs
          pkgs.pandoc
          pkgs.poppler_utils
          pkgs.ghostscript
          pkgs.psutils
          pkgs.imagemagick
        ];
      };
      apps.luaotftool = {
        type = "app";
        buildInputs = [texpkgs fonts];
        program = toString (writeZsh "otftool-wrap" ''
          export FONTCONFIG_PATH="${fonts}"
          export OSFONTDIR="${fonts}/fonts"

          ${texpkgs}/bin/luaotfload-tool "$@"
        '');
      };
    });
}
