# nvim-nix

A standalone [nixvim](https://github.com/nix-community/nixvim) neovim that
always starts in a kitty window configured with the InconsolataGo Nerd Font,
so the glyphs in the statusline, the file tree and the git signs are never at
the mercy of whatever terminal happens to be in front of it.

## Commands

| command        | what it does                                                      |
| -------------- | ----------------------------------------------------------------- |
| `nvim`         | opens a kitty window with the guaranteed font and runs neovim in it |
| `nvim-nokitty` | the plain neovim binary, in the terminal you are already in         |

Both come from the same package, so installing it gives you both.

## When `nvim` does not open a window

The launcher falls back to the current terminal when a new window would break
the caller instead of helping it:

- there is no graphical session, so neither `WAYLAND_DISPLAY` nor `DISPLAY` is set
- stdin or stdout is not a terminal, so the call is part of a pipe or a redirect
- `NVIM_KITTY` is set, which means you are already inside a window the launcher opened
- the call is `--headless`, `--version` or `--help`, and only wants to print something
- `NVIM_NO_KITTY` is set, the explicit opt out
- there is no kitty on the path, which only happens if the launcher is installed without it
- kitty itself failed to start, in which case the launcher says so and runs neovim anyway

The exit code is always neovim's own, so `EDITOR=nvim` and `git commit` keep
working. Note that they do open a window, which is the point of the setup. Use
`nvim-nokitty` if you want an editor that stays in the terminal.

## How the font is guaranteed

- The launcher points `FONTCONFIG_FILE` at a fontconfig built from the store,
  containing the Nerd Font and a color emoji font. Nothing has to be installed
  on the host for this to work.
- System fonts still come in through `/etc/fonts/conf.d`, which NixOS fills
  from `fonts.packages`, so they stay available as a fallback for glyphs the
  Nerd Font does not carry.
- `kitty/nvim.conf` is loaded with `kitty --config`, so `~/.config/kitty/kitty.conf`
  is never read for these windows and cannot override the font.
- The family named in `kitty/nvim.conf` is verified at build time against the
  font package. A typo fails the build instead of producing boxes at runtime.

`kitty/nvim.conf` is the place to change the font, its size or the colors.

## Keep the flake in step with your system

kitty draws with OpenGL, and on NixOS an OpenGL program has to come from the
same nixpkgs generation as the driver under `/run/opengl-driver`. A kitty built
from an older nixpkgs cannot load a newer Mesa. It then finds no EGL platform
at all and crashes on startup.

So the `nixpkgs` and `nixvim` inputs here track a NixOS release on purpose, and
that release should be the one the machine runs. The symptom of a drift is
`nvim` falling back to the terminal with an EGL error on stderr. The fix is to
point both inputs at the release from `nixos-version` and run `nix flake update`.

## Install

As a NixOS module, which also installs kitty from the system's own nixpkgs and
puts the font into `fonts.packages` for the rest of the system:

```nix
{
  inputs.nvim-nix.url = "github:Korny666/nvim-nix";

  # in your configuration
  imports = [ inputs.nvim-nix.nixosModules.default ];
}
```

Or straight from the flake:

```sh
nix run github:Korny666/nvim-nix
```

## Outputs

| output            | contents                                                       |
| ----------------- | -------------------------------------------------------------- |
| `default`         | same as `nix-nvim-kitty`                                        |
| `nix-nvim-kitty`  | the launcher plus `nvim-nokitty`                                |
| `nix-nvim`        | the bare nixvim neovim                                          |
| `nix-nvim-offline` | the bare neovim in a bubblewrap sandbox without network access |
| `fonts`           | the Nerd Font package                                           |

`nix flake check` runs the font family check on its own.
