{ pkgs, lib, ... }:
{
  globals = {
    mapleader = " ";
    maplocalleader = " ";
  };
  clipboard.register = "unnamed,unnamedplus";
  opts = {
    number = true;
    mouse = "a";
    cursorline = true;
    undofile = true;
    winwidth = 80;
  };
  colorschemes.onedark.enable = true;
  plugins = {
    colorizer = {
      enable = true;
      settings = {
        filetypes = {
          __unkeyed-1 = "*";
          __unkeyed-2 = "!vim";
          css = {
            rgb_fn = true;
          };
          html = {
            names = false;
          };
        };
        user_commands = [
          "ColorizerToggle"
          "ColorizerReloadAllBuffers"
        ];

      };
    };
    which-key.enable = true;
    bufferline.enable = true;
    markview.enable = true;
    dashboard.enable = true;
    dashboard.settings = {
      config = {
        footer = [ "The only winning move is not to play" ];
        header = [
          "███    ██ ██    ██ ██ ███    ███"
          "████   ██ ██    ██ ██ ████  ████"
          "██ ██  ██ ██    ██ ██ ██ ████ ██"
          "██  ██ ██  ██  ██  ██ ██  ██  ██"
          "██   ████   ████   ██ ██      ██"
        ];
        mru = {
          limit = 20;
        };
        project = {
          enable = false;
        };
        week_header = {
          enable = false;
        };
      };
      theme = "hyper";
    };
    undotree.enable = true;
    # Grep
    telescope = {
      enable = true;
      extensions = {
        file-browser.enable = true;
        fzf-native.enable = true;
        live-grep-args.enable = true;
        ui-select.enable = true;
        undo.enable = true;
        media-files.enable = true;
        #Nix fuzzy search
        manix.enable = true;
      };
      keymaps = {

        "<Leader>fg" = {
          action = "live_grep";
          options.desc = "Find w grep";
        };

        "<Leader>ff" = {
          action = "find_files";
          options.desc = "Find files";
        };
        "<Leader>fn" = {
          action = "manix";
          options.desc = "Find in nix doc";
        };
      };
    };
    # Filebrowser
    nvim-tree.enable = true;
    web-devicons.enable = true; # Warning wants this explicitly
    # Language Higlighting etc.
    treesitter = {
      enable = true;
      grammarPackages = pkgs.vimPlugins.nvim-treesitter.allGrammars;
      nixvimInjections = true;

      settings = {
        #    highlight.enable = true;
        # Install missing Parsers
        auto_install = true;
        # Mark Code Blocks
        incremental_selection.enable = true;
        # Indent Code
        indent.enable = true;
      };
    };

    # Show Head of current function on top
    treesitter-context = {
      enable = true;
    };
    #  # QoL for code, showing definitions, current scope, renaming, etc...
    treesitter-refactor = {
      enable = true;
      highlightCurrentScope.enable = true;
      highlightDefinitions.enable = true;
      navigation.enable = true;
      # Rename with "grr"
      smartRename.enable = true;
    };

    # Floating definitions, etc.:
    treesitter-textobjects = {
      enable = true;
      lspInterop.enable = true;
      move.enable = true;
    };

    ts-comments.enable = true;

    # Language Server:
    lsp = {
      enable = true;
      inlayHints = true;
      servers = {
        # prismals.enable = true;
        # prismals.package = pkgs.nodePackages."@prisma/language-server"; Seems broken as of 25.05
        volar.enable = true;
        cssls.enable = true;
        tailwindcss.enable = true;
        ts_ls = {
          enable = true;
          settings = {
            init_options = {
              plugins = [
                {
                  name = "@vue/typescript-plugin";
                  location = "${pkgs.vue-language-server}/lib/node_modules/@vue/language-server";
                  languages = [
                    "javascript"
                    "typescript"
                    "vue"
                  ];
                }
              ];
            };
            filetypes = [
              "javascript"
              "typescript"
              "vue"
            ];
          };
        };
        eslint.enable = true;
        bashls.enable = true;
        postgres_lsp.enable = true;
        lemminx.enable = true;
        jsonls.enable = true;
        yamlls.enable = true;
        html.enable = true;
        nixd = {
          enable = true;
          filetypes = [ "nix" ];
          settings =
            let
              flake = ''(builtins.getFlake "/etc/nixos/flake")""'';
            in
            {
              nixpkgs = {
                expr = "import ${flake}.inputs.nixpkgs { }";
              };
              formatting = {
                command = [ "${lib.getExe pkgs.nixfmt-rfc-style}" ];
              };
            };

        };
      };
    };

    lspsaga = {
      enable = true;
      diagnostic.extendRelatedInformation = true;
    };
    lsp-signature.enable = true;
    lsp-status.enable = true;
    lspkind.enable = true;

    # Autocompletion
    cmp = {
      enable = true;
      autoEnableSources = true;
      settings = {
        sources = [
          { name = "nvim_lsp"; }
          { name = "path"; }
          {
            name = "buffer";
            entry_filter = ''
              	function(entry, ctx)
                  return require("cmp").lsp.CompletionItemKind.Text ~= entry:get_kind();
                end'';
          }
          { name = "luasnip"; }
          { name = "nvim_lsp_document_symbol"; }
          { name = "nvim_lsp_signature_help"; }

        ];
        experimental = {
          ghost_text = true;
        };
        mapping = {
          "<C-j>" = "cmp.mapping.select_next_item()";
          "<C-k>" = "cmp.mapping.select_prev_item()";

          "<Tab>" = ''
            cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_next_item()
              elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
              else
                fallback()
              end
            end, { "i", "s" })
          '';

          "<C-Space>" = "cmp.mapping.complete()";
          "<CR>" = "cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })"; # Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.

        };
      };
    };
    cmp-nvim-lsp = {
      enable = true;
    }; # lsp
    cmp-buffer = {
      enable = true;
    };
    cmp-path = {
      enable = true;
    }; # file system paths
    cmp-cmdline = {
      enable = true;
    }; # autocomplete for cmdline
    cmp-nvim-lsp-document-symbol = {
      enable = true;
    }; # docs
    cmp-nvim-lsp-signature-help = {
      enable = true;
    }; # function signatures

    cmp_luasnip = {
      enable = true;
    }; # snippets
    luasnip = {
      enable = true;
      settings.enable_autosnippets = true;
    };
    cmp-zsh = {
      enable = true;
    };

    gitsigns = {
      enable = true;
      settings = {
        current_line_blame = true;
        current_line_blame_opts = {
          ignore_whitespace = true;
        };
      };
    };
  };

  keymaps = [
    {
      key = "<Space>";
      action = "<Nop>";
      options.desc = "Disable space in normal mode";
      mode = "n";
    }
    {
      key = "<F1>";
      action = "<Nop>";
      options.desc = "Disable Helpfile";
    }

    {
      key = "<c-n>";
      action = "<cmd>NvimTreeToggle<CR>";
      options.desc = "Toggle File browser";
    }
    {
      key = "<Leader>F";
      action = "<cmd>lua vim.lsp.buf.format()<CR>";
      options.desc = "Format Code";
    }
    {
      key = "<Leader>fs";
      action = "<cmd>Lspsaga finder<CR>";
      options.desc = "Find symbol";
    }
    {
      key = "<c-t>";
      action = "<cmd>Lspsaga term_toggle<CR>";
      options.desc = "Open Terminal";
    }
    {
      key = "<F2>";
      action = "<cmd>lua vim.lsp.buf.rename()<CR>";
      options.desc = "Rename Symbol";
    }
    {
      key = "<Leader>id";
      action = "<cmd>lua vim.api.nvim_put({io.popen('uuidgen'):read():sub(1, -2)}, 'c', true, true)<CR>";
      options.desc = "Insert UUID";
    }
    {
      key = "<Leader>ca";
      action = "<cmd>lua vim.lsp.buf.code_action()<CR>";
      options.desc = "Apply Code Action";
    }
    {
      key = "<Leader>e";
      action = "<cmd>lua vim.diagnostic.open_float()<CR>";
      options.desc = "Open full error/warning";
    }
  ];
}
