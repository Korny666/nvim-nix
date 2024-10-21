{ nix2nvimrc, ... }:
let
  inherit (nix2nvimrc) toLuaFn luaExpr;
in
{
  configs.global = {
    after = [ "leader" ];
    opts = {
      hidden = true;
      termguicolors = true;
      winwidth = 80;
      incsearch = true;
      hlsearch = true;
      ignorecase = true;
      smartcase = true;
      magic = true;
      showmatch = true;
      undofile = true;
      undodir = luaExpr "vim.env.HOME .. '/.cache/nvim/undo'";
      visualbell = true;
      cursorline = true;
      cursorlineopt = "number";
      tabstop = 2;
      softtabstop = 2;
      smarttab = true;
      expandtab = true;
      shiftwidth = 2;
      relativenumber = false;
      copyindent = true;
      preserveindent = true;
      number = true;
      foldmethod = "indent";
      foldlevelstart = 99;
      linebreak = true;
      scrolloff = 2;
      sidescrolloff = 3;
      listchars = "tab:▸ ,trail:␣,nbsp:~,extends:…";
      list = true;
      mouse = "nv";
      signcolumn = "yes";
      splitbelow = true;
      splitright = true;
      updatetime = 300;
      formatoptions = luaExpr "vim.o.formatoptions .. 'n'";
      background = "dark";
      completeopt = "menu,menuone,noselect";
      clipboard = "unnamed,unnamedplus";
    };
    keymaps = map (nix2nvimrc.toKeymap { silent = true; }) [
      # windows
      [ "" "<C-h>" "<C-w>h" { } ]
      [ "" "<C-j>" "<C-w>j" { } ]
      [ "" "<C-k>" "<C-w>k" { } ]
      [ "" "<C-l>" "<C-w>l" { } ]
      [ "n" "<Leader>cd" "<Cmd>lcd %:p:h<CR>" { desc = "Change working directory"; } ]
      # undo breaks
      [ "i" "," ",<c-g>u" { } ]
      [ "i" "." ".<c-g>u" { } ]
      [ "i" "!" "!<c-g>u" { } ]
      [ "i" "?" "?<c-g>u" { } ]
      [ "i" ":" ":<c-g>u" { } ]
      # search
      [ "n" "<cr>" ":noh<cr>" { } ]
      [ "n" "n" "nzz" { } ]
      [ "n" "N" "Nzz" { } ]
      # yank
      [ [ "n" "v" ] "<Leader>y" "\"+y" { } ]
      [ "n" "<Leader>Y" "gg\"+yG" { } ]
      [ [ "n" "v" ] "<Leader>d" "\"_d" { desc = "Delete to /dev/null"; } ]
      [ "n" "Y" "y$" { } ]
      # indent
      [ "v" "<" "<gv" { desc = "Indent left"; } ]
      [ "v" ">" ">gv" { desc = "Indent right"; } ]
      # terminal
      [ "t" "<Esc>" "<C-\\><C-n>" { desc = "Close terminal"; } ]
      # ---
      [ "n" "gx" "<Cmd>call jobstart(['xdg-open', expand('<cfile>')])<CR>" { desc = "Open file"; } ]
      # https://stackoverflow.com/a/26504944
      [ "n" "<Leader>h" "<Cmd>let &hls=(&hls == 1 ? 0 : 1)<CR>" { desc = "Toggle highlight search"; } ]
      # diagnostics
      [ "n" "<Leader>e" (luaExpr "vim.diagnostic.open_float") { } ]
      [ "n" "[d" (luaExpr "vim.diagnostic.goto_prev") { } ]
      [ "n" "]d" (luaExpr "vim.diagnostic.goto_next") { } ]
      [ "n" "<Leader>q" (luaExpr "vim.diagnostic.setloclist") { } ]
      # spell
      [ "n" "<Leader>se" "<Cmd>setlocal spell spelllang=en_us<CR>" { desc = "Spell English"; } ]
      [ "n" "<Leader>sd" "<Cmd>setlocal spell spelllang=de_de<CR>" { desc = "Spell German"; } ]
      # rename global
      [ "n" "<F2>" ":%s#\\<<C-r><C-w>\\>#<C-r><C-w>#g<Left><Left>" { desc = "Spell German"; silent = false; } ]
      [ [ "n" "v" ] "<Leader>fs" "<Cmd>Telescope grep_string<CR>" { } ]
      [ "n" "<Leader><Leader><Tab>" (luaExpr "require'telescope.builtin'.resume") { desc = "Resume telescope"; } ]
      [ "n" "<Leader><Tab>" (luaExpr "function() require'telescope.builtin'.buffers({sort_mru=true, sort_lastused=true}) end") { desc = "Find buffers (sorted)"; } ]
    ];
    vim = [ ./global.vim ];
  };
}
