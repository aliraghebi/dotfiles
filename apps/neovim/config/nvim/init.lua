-- Basic options
vim.opt.encoding = "utf-8"
vim.opt.backspace = "eol,start,indent"
vim.opt.autoindent = true
vim.opt.smarttab = true
vim.opt.fileformats = "unix,dos"
vim.opt.timeout = true
vim.opt.timeoutlen = 1000
vim.opt.ttimeoutlen = 100
vim.opt.laststatus = 2
vim.opt.statusline = "%f %=L:%l/%L %c (%p%%)"
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false
vim.opt.ruler = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.autoread = true
vim.opt.list = true
vim.opt.listchars = { tab = "  ", trail = "·" }
vim.opt.modeline = true
vim.opt.modelines = 5
vim.opt.foldmethod = "marker"
vim.opt.hlsearch = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.termguicolors = true
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 50
vim.opt.clipboard = "unnamedplus"

-- Leader key
vim.g.mapleader = " "

-- Keymaps
vim.keymap.set("n", "<C-w>n", ":tabnext<CR>")
vim.keymap.set("n", "<C-w>p", ":tabprevious<CR>")
vim.keymap.set("n", "<C-w>c", ":tabnew<CR>")

-- Filetype-specific indentation
vim.api.nvim_create_augroup("format", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = "format",
  pattern = { "php" },
  callback = function() vim.opt_local.tabstop = 4; vim.opt_local.softtabstop = 4; vim.opt_local.shiftwidth = 4 end,
})
vim.api.nvim_create_autocmd("FileType", {
  group = "format",
  pattern = { "cpp" },
  callback = function() vim.opt_local.tabstop = 4; vim.opt_local.softtabstop = 4; vim.opt_local.shiftwidth = 4; vim.opt_local.expandtab = true end,
})
vim.api.nvim_create_autocmd("FileType", {
  group = "format",
  pattern = { "json", "html", "javascript", "vue.javascript", "docker-compose" },
  callback = function() vim.opt_local.tabstop = 2; vim.opt_local.softtabstop = 2; vim.opt_local.shiftwidth = 2; vim.opt_local.expandtab = true end,
})
vim.api.nvim_create_autocmd("FileType", {
  group = "format",
  pattern = "gitcommit",
  callback = function() vim.opt_local.spell = true; vim.opt_local.textwidth = 72 end,
})
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = "format",
  pattern = "*.vue",
  callback = function() vim.opt_local.filetype = "vue.javascript" end,
})
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = "format",
  pattern = ".babelrc",
  callback = function() vim.opt_local.filetype = "json" end,
})

vim.api.nvim_create_user_command("Spellcheck", "setlocal spell spelllang=en_us", {})

-- lazy.nvim bootstrap
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    opts = { style = "night" },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight-night")
    end,
  },
})

-- Neovide
if vim.g.neovide then
  vim.o.guifont = "JetBrainsMono Nerd Font:h14"
  vim.g.neovide_padding_top = 8
  vim.g.neovide_padding_bottom = 8
  vim.g.neovide_padding_left = 8
  vim.g.neovide_padding_right = 8
  vim.g.neovide_cursor_animation_length = 0.05
  vim.g.neovide_scroll_animation_length = 0.3
end