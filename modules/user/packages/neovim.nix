# Neovim: telescope + treesitter + LSP (nil, lua), Stylix themed.
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.neovim;
in
{
  options.userSettings.programs.neovim.enable = lib.mkEnableOption "neovim editor";

  config = lib.mkIf cfg.enable {
    programs.neovim = {
      enable = true;

      defaultEditor = false;

      plugins = with pkgs.vimPlugins; [
        plenary-nvim
        telescope-nvim
        nvim-lspconfig
        (nvim-treesitter.withPlugins (p: [
          p.bash
          p.json
          p.lua
          p.markdown
          p.markdown_inline
          p.nix
          p.python
          p.rust
          p.toml
          p.vim
          p.vimdoc
          p.yaml
        ]))
      ];

      # Language servers + finder backend + nix formatter on nvim's PATH.
      extraPackages = with pkgs; [
        nil
        lua-language-server
        alejandra
        fd
      ];

      initLua = ''
        -- Leader first (before any plugin/keymap setup).
        vim.g.mapleader = " "
        vim.g.maplocalleader = " "

        -- Options.
        local o = vim.opt
        o.number = true
        o.relativenumber = true
        o.signcolumn = "yes"
        o.cursorline = true
        o.scrolloff = 8
        o.sidescrolloff = 8
        o.wrap = false
        o.tabstop = 2
        o.shiftwidth = 2
        o.expandtab = true
        o.smartindent = true
        o.ignorecase = true
        o.smartcase = true
        o.hlsearch = true
        o.incsearch = true
        o.undofile = true
        o.swapfile = false
        o.backup = false
        o.updatetime = 250
        o.timeoutlen = 400
        o.completeopt = { "menu", "menuone", "noselect" }
        o.termguicolors = true
        o.clipboard = "unnamedplus" -- wl-clipboard: yank goes to Wayland clipboard
        o.splitright = true
        o.splitbelow = true

        -- Highlight on yank.
        vim.api.nvim_create_autocmd("TextYankPost", {
          desc = "Highlight on yank",
          group = vim.api.nvim_create_augroup("yank-highlight", { clear = true }),
          callback = function() vim.hl.on_yank() end,
        })

        -- Clear search highlight with <Esc><Esc>.
        vim.keymap.set("n", "<Esc><Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

        -- Telescope.
        local telescope = require("telescope")
        telescope.setup({
          defaults = {
            layout_strategy = "horizontal",
            layout_config = { prompt_position = "top" },
            sorting_strategy = "ascending",
          },
        })
        local builtin = require("telescope.builtin")
        vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
        vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep (ripgrep)" })
        vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Open buffers" })
        vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
        vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "Diagnostics list" })

        -- Treesitter (grammars come from Nix, no :TSInstall needed).
        -- Works with both the legacy configs module and the 1.x rewrite.
        local ok_ts, ts_configs = pcall(require, "nvim-treesitter.configs")
        if ok_ts and ts_configs.setup then
          ts_configs.setup({
            highlight = { enable = true },
            indent = { enable = true },
          })
        else
          vim.api.nvim_create_autocmd("FileType", {
            desc = "Start treesitter highlighting",
            group = vim.api.nvim_create_augroup("treesitter-start", { clear = true }),
            callback = function() pcall(vim.treesitter.start) end,
          })
        end

        -- LSP: buffer-local maps once a server attaches.
        vim.api.nvim_create_autocmd("LspAttach", {
          desc = "LSP keymaps",
          group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
          callback = function(ev)
            local map = function(keys, fn, desc)
              vim.keymap.set("n", keys, fn, { buffer = ev.buf, desc = "LSP: " .. desc })
            end
            map("gd", vim.lsp.buf.definition, "Go to definition")
            map("gr", vim.lsp.buf.references, "References")
            map("gI", vim.lsp.buf.implementation, "Implementation")
            map("K", vim.lsp.buf.hover, "Hover")
            map("<leader>rn", vim.lsp.buf.rename, "Rename")
            map("<leader>ca", vim.lsp.buf.code_action, "Code action")
            map("<leader>f", function() vim.lsp.buf.format({ async = true }) end, "Format")
            map("[d", vim.diagnostic.goto_prev, "Previous diagnostic")
            map("]d", vim.diagnostic.goto_next, "Next diagnostic")
            map("<leader>e", vim.diagnostic.open_float, "Diagnostic float")
          end,
        })

        -- Servers (binaries come from Nix via extraPackages).
        vim.lsp.config("nil_ls", {
          cmd = { "nil" },
          filetypes = { "nix" },
          settings = { ["nil"] = { formatting = { command = { "alejandra" } } } },
        })
        vim.lsp.enable("nil_ls")
        vim.lsp.config("lua_ls", {
          cmd = { "lua-language-server" },
          filetypes = { "lua" },
        })
        vim.lsp.enable("lua_ls");

        -- Diagnostics look.
        vim.diagnostic.config({ virtual_text = true, underline = true });
      '';
    };
  };
}
