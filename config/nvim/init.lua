-- Neovim with helix keymaps (lua/helix.lua) and Zed's One Dark theme
-- (colors/zed-onedark.lua). Plugins are managed by lazy.nvim.

local helix = require("helix")
helix.setup()

-- options, matching my helix config where helix has an equivalent
local o = vim.opt
o.termguicolors = true
o.number = true
o.cursorline = true
o.signcolumn = "yes"
o.scrolloff = 5
o.mouse = "a"
o.ignorecase = true
o.smartcase = true
o.undofile = true
o.splitright = true
o.splitbelow = true
o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.updatetime = 300
o.timeoutlen = 1000
o.showmode = false
o.completeopt = { "menuone", "noinsert" }
o.shortmess:append("c")
o.listchars = { tab = "→ ", space = "·", nbsp = "⍽", trail = "·", eol = "⏎" }
o.guicursor = "n:block,i-ci-ve:ver25,v:hor20,r-cr-o:hor20"
o.statusline = "%{%v:lua.require'helix'.mode()%}%* %f %m%r%= %{%v:lua.StatusDiagnostics()%}"
  .. "%#StatusLineMuted#%{&fenc} %{&ff}  %l:%c  %{&ft} "

-- helix: A-w / A-q toggle whitespace rendering
vim.keymap.set("n", "<M-w>", "<Cmd>set list<CR>", { desc = "Show whitespace" })
vim.keymap.set("n", "<M-q>", "<Cmd>set nolist<CR>", { desc = "Hide whitespace" })

function _G.StatusDiagnostics()
  local out = {}
  for _, s in ipairs({ { "ERROR", "Error", "●" }, { "WARN", "Warn", "●" } }) do
    local n = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity[s[1]] })
    if n > 0 then table.insert(out, ("%%#Diagnostic%s#%s %d"):format(s[2], s[3], n)) end
  end
  return #out > 0 and table.concat(out, " ") .. "%* " or ""
end

vim.cmd.colorscheme("zed-onedark")

-- plugins
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    "nvim-treesitter/nvim-treesitter",
    -- the master branch supports nvim 0.10 (Debian 13) and builds parsers
    -- without the tree-sitter CLI
    branch = "master",
    build = ":TSUpdate",
    -- only the queries are used, by mini.ai
    dependencies = { { "nvim-treesitter/nvim-treesitter-textobjects", branch = "master" } },
    main = "nvim-treesitter.configs",
    opts = {
      ensure_installed = { "bash", "c", "cpp", "json", "lua", "markdown", "markdown_inline",
        "python", "rust", "toml", "vim", "vimdoc", "yaml", "query" },
      highlight = { enable = true },
      indent = { enable = true },
    },
  },
  {
    "nvim-mini/mini.nvim",
    config = function()
      require("mini.icons").setup()
      require("mini.extra").setup()
      require("mini.pick").setup({
        mappings = {
          -- helix picker keys
          move_down = "<C-n>",
          move_up = "<C-p>",
          choose_in_split = "<C-s>",
          choose_in_vsplit = "<C-v>",
          scroll_down = "<C-d>",
          scroll_up = "<C-u>",
        },
      })
      vim.ui.select = require("mini.pick").ui_select

      local ai = require("mini.ai")
      local ts = ai.gen_spec.treesitter
      ai.setup({
        -- selected through mi/ma in lua/helix.lua
        mappings = { around = "", inside = "", around_next = "", inside_next = "",
          around_last = "", inside_last = "", goto_left = "", goto_right = "" },
        n_lines = 500,
        custom_textobjects = {
          f = ts({ a = "@function.outer", i = "@function.inner" }),
          t = ts({ a = "@class.outer", i = "@class.inner" }),
          c = ts({ a = "@comment.outer", i = "@comment.inner" }),
          T = ts({ a = "@test.outer", i = "@test.inner" }),
          -- closest pair of brackets or quotes
          m = { { "%b()", "%b[]", "%b{}", "%b<>", '%b""', "%b''", "%b``" }, "^.().*().$" },
        },
      })

      require("mini.surround").setup({
        mappings = { add = "ms", delete = "md", replace = "mr", find = "", find_left = "",
          highlight = "", update_n_lines = "", suffix_last = "", suffix_next = "" },
        search_method = "cover_or_next",
        -- helix does not add spaces for opening brackets
        custom_surroundings = {
          ["("] = { input = { "%b()", "^.().*().$" }, output = { left = "(", right = ")" } },
          ["["] = { input = { "%b[]", "^.().*().$" }, output = { left = "[", right = "]" } },
          ["{"] = { input = { "%b{}", "^.().*().$" }, output = { left = "{", right = "}" } },
          ["<"] = { input = { "%b<>", "^.().*().$" }, output = { left = "<", right = ">" } },
        },
      })
      require("mini.comment").setup({
        mappings = { comment = "", comment_line = "<C-c>", comment_visual = "<C-c>", textobject = "" },
      })
      require("mini.pairs").setup()
      require("mini.diff").setup({
        view = { style = "sign", signs = { add = "▍", change = "▍", delete = "▁" } },
        mappings = { apply = "", reset = "", textobject = "",
          goto_first = "[G", goto_prev = "[g", goto_next = "]g", goto_last = "]G" },
      })
      require("mini.completion").setup()

      -- helix-like key hint popups
      local clue = require("mini.clue")
      clue.setup({
        triggers = {
          { mode = "n", keys = "<Leader>" }, { mode = "x", keys = "<Leader>" },
          { mode = "n", keys = "g" }, { mode = "x", keys = "g" },
          { mode = "n", keys = "m" }, { mode = "x", keys = "m" },
          { mode = "n", keys = "z" }, { mode = "x", keys = "z" },
          { mode = "n", keys = "[" }, { mode = "n", keys = "]" },
          { mode = "n", keys = "<C-w>" },
          { mode = "n", keys = '"' }, { mode = "x", keys = '"' },
        },
        clues = {
          { mode = "n", keys = "<Leader>w", desc = "+window" },
          clue.gen_clues.windows(),
          clue.gen_clues.registers(),
          clue.gen_clues.z(),
        },
        window = { delay = 300, config = { width = "auto" } },
      })
    end,
  },
  {
    "jake-stewart/multicursor.nvim",
    branch = "1.0",
    config = helix.setup_multicursor,
  },
}, {
  install = { colorscheme = { "zed-onedark" } },
  change_detection = { notify = false },
})

-- insert mode completion keys, like helix
vim.keymap.set("i", "<Tab>", function() return vim.fn.pumvisible() == 1 and "<C-n>" or "<Tab>" end,
  { expr = true })
vim.keymap.set("i", "<S-Tab>", function() return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>" end,
  { expr = true })
vim.keymap.set("i", "<C-x>", function() MiniCompletion.complete_twostage() end,
  { desc = "Complete" })

-- LSP: servers are started if installed
vim.diagnostic.config({ virtual_text = true, severity_sort = true, float = { border = "rounded" } })

local servers = {
  { name = "rust-analyzer", cmd = { "rust-analyzer" }, filetypes = { "rust" },
    root = { "Cargo.toml", ".git" },
    settings = { ["rust-analyzer"] = { check = { command = "clippy" } } } },
  { name = "ruff", cmd = { "ruff", "server" }, filetypes = { "python" },
    root = { "pyproject.toml", "ruff.toml", ".ruff.toml", "setup.py", ".git" } },
  { name = "pyright", cmd = { "pyright-langserver", "--stdio" }, filetypes = { "python" },
    root = { "pyproject.toml", "pyrightconfig.json", "setup.py", ".git" },
    settings = { python = { analysis = { autoSearchPaths = true, useLibraryCodeForTypes = true } } } },
  { name = "pylsp", cmd = { "pylsp" }, filetypes = { "python" }, unless = "pyright-langserver",
    root = { "pyproject.toml", "setup.py", ".git" } },
  { name = "clangd", cmd = { "clangd" }, filetypes = { "c", "cpp" },
    root = { "compile_commands.json", ".clangd", ".git" } },
  { name = "lua-language-server", cmd = { "lua-language-server" }, filetypes = { "lua" },
    root = { ".luarc.json", ".git" },
    settings = { Lua = { workspace = { library = vim.api.nvim_get_runtime_file("", true) } } } },
  { name = "bash-language-server", cmd = { "bash-language-server", "start" },
    filetypes = { "sh", "bash" }, root = { ".git" } },
}

local lsp_group = vim.api.nvim_create_augroup("lsp_start", {})
for _, server in ipairs(servers) do
  vim.api.nvim_create_autocmd("FileType", {
    group = lsp_group,
    pattern = server.filetypes,
    callback = function(args)
      if vim.fn.executable(server.cmd[1]) == 0 then return end
      if server.unless and vim.fn.executable(server.unless) == 1 then return end
      vim.lsp.start({
        name = server.name,
        cmd = server.cmd,
        root_dir = vim.fs.root(args.buf, server.root) or vim.fn.getcwd(),
        settings = server.settings,
      })
    end,
  })
end

vim.api.nvim_create_autocmd("LspAttach", {
  group = lsp_group,
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client.name == "ruff" then client.server_capabilities.hoverProvider = false end
    local method = "textDocument/inlayHint"
    local inlay = vim.fn.has("nvim-0.11") == 1 and client:supports_method(method)
      or client.supports_method(method)
    if inlay then
      vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
    end
  end,
})

-- clear the references highlighted by <Space>h when moving
vim.api.nvim_create_autocmd("CursorMoved", { callback = function() vim.lsp.buf.clear_references() end })

-- helix: python is formatted on save (auto-format = true)
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.py",
  callback = function(args)
    if #vim.lsp.get_clients({ bufnr = args.buf, name = "ruff" }) > 0 then
      vim.lsp.buf.format({ bufnr = args.buf, name = "ruff" })
    end
  end,
})
