-- Neovim Configuration
-- Minimal, fast, functional

-- Leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Options
local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true

opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true

opt.wrap = false
opt.scrolloff = 8
opt.sidescrolloff = 8

opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

opt.splitright = true
opt.splitbelow = true

opt.termguicolors = true
opt.background = "dark"

opt.undofile = true
opt.swapfile = false
opt.backup = false

opt.updatetime = 250
opt.timeoutlen = 300

opt.clipboard = "unnamedplus"
opt.mouse = "a"

opt.showmode = false
opt.laststatus = 3

-- Keymaps
local map = vim.keymap.set

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Window navigation
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- Buffer navigation
map("n", "<S-h>", "<cmd>bprevious<CR>")
map("n", "<S-l>", "<cmd>bnext<CR>")
map("n", "<leader>bd", "<cmd>bdelete<CR>")

-- Move lines
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")

-- Keep cursor centered
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Better paste
map("x", "<leader>p", '"_dP')

-- Quick save/quit
map("n", "<leader>w", "<cmd>w<CR>")
map("n", "<leader>q", "<cmd>q<CR>")

-- File explorer
map("n", "<leader>e", "<cmd>Explore<CR>")

-- Split management
map("n", "<leader>sv", "<cmd>vsplit<CR>")
map("n", "<leader>sh", "<cmd>split<CR>")

-- Quickfix
map("n", "<leader>co", "<cmd>copen<CR>")
map("n", "<leader>cc", "<cmd>cclose<CR>")
map("n", "]q", "<cmd>cnext<CR>")
map("n", "[q", "<cmd>cprev<CR>")

-- Diagnostic
map("n", "[d", vim.diagnostic.goto_prev)
map("n", "]d", vim.diagnostic.goto_next)
map("n", "<leader>d", vim.diagnostic.open_float)

-- Terminal
map("n", "<leader>tt", "<cmd>terminal<CR>")
map("t", "<Esc><Esc>", "<C-\\><C-n>")

-- Colorscheme (built-in, no plugins needed)
vim.cmd.colorscheme("habamax")

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function()
        vim.highlight.on_yank({ timeout = 200 })
    end,
})

-- Remove trailing whitespace on save
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*",
    callback = function()
        local save = vim.fn.winsaveview()
        vim.cmd([[%s/\s\+$//e]])
        vim.fn.winrestview(save)
    end,
})

-- Return to last edit position
vim.api.nvim_create_autocmd("BufReadPost", {
    callback = function()
        local mark = vim.api.nvim_buf_get_mark(0, '"')
        local lcount = vim.api.nvim_buf_line_count(0)
        if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})
