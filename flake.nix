{
  description = "Standalone neovim";

  inputs = {
    nixvim = {
      url = "github:nix-community/nixvim/nixos-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixvim,
    }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      vimconfig = import ./nix-nvim-config.nix;

      # Kitty reads this at runtime and the font check reads it at build time.
      kittyConf = ./kitty/nvim.conf;

      # Everything that is built per system, in one place, so that packages
      # and checks share the very same derivations.
      buildFor =
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            # hrsh7th/cmp-nvim-lsp-document-symbol ships without a license
            # file, so the generated plugin list in nixpkgs marks it unfree.
            # The config uses it as a completion source, so allow exactly that
            # one package instead of opening the gate for everything. Uses the
            # lib of the input rather than pkgs.lib, which is not built yet.
            config.allowUnfreePredicate =
              pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "cmp-nvim-lsp-document-symbol" ];
          };
          lib = pkgs.lib;

          nerdFont = pkgs.nerd-fonts.inconsolata-go;
          emojiFont = pkgs.noto-fonts-color-emoji;

          nix-nvim = nixvim.legacyPackages.${system}.makeNixvimWithModule {
            inherit pkgs;
            module = vimconfig;
          };
          nvimBin = lib.getExe nix-nvim;

          # A fontconfig that does not care what the host has installed: the
          # Nerd Font and the emoji font come straight from the store. System
          # fonts still arrive through /etc/fonts/conf.d, which NixOS fills
          # from fonts.packages, so they remain available as a fallback for
          # glyphs the Nerd Font does not carry.
          fontsConf = pkgs.makeFontsConf {
            fontDirectories = [
              nerdFont
              emojiFont
            ];
          };

          # Fails the build when kitty/nvim.conf names a font family that the
          # packaged Nerd Font does not actually provide.
          fontCheck =
            pkgs.runCommand "nvim-kitty-font-check"
              {
                nativeBuildInputs = [ pkgs.fontconfig.bin ];
              }
              ''
                family=$(sed -n 's/^font_family[[:space:]]\{1,\}//p' ${kittyConf} \
                  | head -n 1 | sed 's/[[:space:]]*$//')
                if [ -z "$family" ]; then
                  echo "nvim-nix: kitty/nvim.conf sets no font_family" >&2
                  exit 1
                fi

                available=$(find ${nerdFont} -type f \( -name '*.ttf' -o -name '*.otf' \) \
                  -exec fc-scan --format '%{family}\n' {} + \
                  | tr ',' '\n' \
                  | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
                  | sort -u)

                if ! printf '%s\n' "$available" | grep -qxF "$family"; then
                  echo "nvim-nix: kitty/nvim.conf asks for the font family '$family'," >&2
                  echo "nvim-nix: but ${nerdFont} only provides:" >&2
                  printf '%s\n' "$available" | sed 's/^/  /' >&2
                  exit 1
                fi

                echo "$family" > $out
              '';

          # Runs inside the kitty window. Records neovim's exit code so that
          # the launcher can hand it back to whoever called nvim.
          innerRunner = pkgs.writeShellScript "nvim-kitty-inner" ''
            rc_file="$1"
            shift
            "${nvimBin}" "$@"
            printf '%s' "$?" > "$rc_file"
          '';

          launcher = pkgs.writeShellApplication {
            name = "nvim";
            runtimeInputs = [
              pkgs.kitty
              pkgs.coreutils
            ];
            text = ''
              # nvim always goes through a kitty window configured with the
              # Nerd Font, which is what makes the glyphs guaranteed. The
              # exceptions below are the cases where a new window would break
              # the caller instead of helping it.

              nvim_bin="${nvimBin}"

              inline() {
                exec "$nvim_bin" "$@"
              }

              # Explicit opt out.
              if [ -n "''${NVIM_NO_KITTY:-}" ]; then
                inline "$@"
              fi

              # Already inside a window this launcher opened.
              if [ -n "''${NVIM_KITTY:-}" ]; then
                inline "$@"
              fi

              # No graphical session at all, a tty or a plain ssh login.
              if [ -z "''${WAYLAND_DISPLAY:-}" ] && [ -z "''${DISPLAY:-}" ]; then
                inline "$@"
              fi

              # Piped or redirected, where a separate window would swallow the
              # stream.
              if [ ! -t 0 ] || [ ! -t 1 ]; then
                inline "$@"
              fi

              # Calls that are meant to print something and exit, not to edit.
              for arg in "$@"; do
                case "$arg" in
                  --) break ;;
                  --headless | --version | -v | --help | -h) inline "$@" ;;
                esac
              done

              # kitty ships with this package, so this only bites when the
              # launcher is installed without it.
              if ! command -v kitty > /dev/null 2>&1; then
                echo "nvim: no kitty on PATH, using the current terminal instead" >&2
                inline "$@"
              fi

              rc_file=$(mktemp)
              trap 'rm -f "$rc_file"' EXIT

              kitty_rc=0
              NVIM_KITTY=1 FONTCONFIG_FILE=${fontsConf} \
                kitty \
                --config ${kittyConf} \
                --class nvim-kitty \
                --directory "$PWD" \
                --start-as maximized \
                ${innerRunner} "$rc_file" "$@" || kitty_rc=$?

              # A written exit code proves that neovim ran, so it is the one
              # the caller wants, not kitty's.
              if [ -s "$rc_file" ]; then
                nvim_rc=$(cat "$rc_file")
                case "$nvim_rc" in
                  *[!0-9]*) exit 1 ;;
                  *) exit "$nvim_rc" ;;
                esac
              fi

              # Nothing was written, so neovim never started and kitty itself
              # failed. Fall back to the current terminal rather than leaving
              # the caller with nothing. The exec below skips the trap, so the
              # temporary file goes now.
              rm -f "$rc_file"
              echo "nvim: kitty exited with $kitty_rc before neovim started, using the current terminal instead" >&2
              inline "$@"
            '';
          };

          nix-nvim-kitty =
            pkgs.runCommand "nvim-kitty"
              {
                meta = {
                  description = "Neovim in a kitty window with a guaranteed Nerd Font";
                  mainProgram = "nvim";
                };
              }
              ''
                mkdir -p $out/bin
                ln -s ${lib.getExe launcher} $out/bin/nvim
                ln -s ${nvimBin} $out/bin/nvim-nokitty
                # Building this package runs the font check.
                test -e ${fontCheck}
              '';

          nix-nvim-offline = pkgs.writeShellApplication {
            name = "nvim";
            runtimeInputs = [
              pkgs.bubblewrap
              nix-nvim
              pkgs.bash
            ];
            text = ''
              bwrap --dev-bind / / --unshare-net ${nvimBin} "$@"
            '';
          };
        in
        {
          inherit
            nix-nvim
            nix-nvim-kitty
            nix-nvim-offline
            fontCheck
            ;
          fonts = nerdFont;
        };

      perSystem = forAllSystems buildFor;
    in
    {
      nixosModules.default =
        { pkgs, lib, ... }:
        let
          sys = pkgs.stdenv.hostPlatform.system;
        in
        {
          environment.systemPackages = [
            (self.packages.${sys}.default or (throw "nvim-nix: unsupported system ${sys}"))
            # kitty from the system's own nixpkgs, so there is always one on
            # hand that matches the graphics driver.
            pkgs.kitty
          ];
          # Only so the rest of the system can use the font as well. The
          # launcher does not rely on it, it carries its own fontconfig.
          fonts.packages = [ pkgs.nerd-fonts.inconsolata-go ];
        };

      packages = forAllSystems (
        system:
        {
          inherit (perSystem.${system})
            nix-nvim
            nix-nvim-kitty
            nix-nvim-offline
            fonts
            ;
          default = perSystem.${system}.nix-nvim-kitty;
        }
      );

      checks = forAllSystems (system: {
        font-family = perSystem.${system}.fontCheck;
      });
    };
}
