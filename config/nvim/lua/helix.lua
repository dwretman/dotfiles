-- Helix-style keymaps.
--
-- Helix is selection-first: motions select text and actions work on the
-- selection. This module emulates that with visual mode:
--  * normal mode is helix normal mode with a one character selection,
--  * w/b/e, f/t, x, %, mi/ma, Alt-o, ... select text by entering visual mode,
--  * in visual mode, motions collapse the selection and move like in helix
--    normal mode, unless select mode was entered with `v`, where they extend
--    the selection.
-- Multiple selections (C, s, S, &, ...) use multicursor.nvim, which replays
-- the typed keys at every cursor.

local M = {}

-- true in helix select (extend) mode
M.extend = false

local map = vim.keymap.set
local api = vim.api

local function visual()
  return vim.fn.mode():find("^[vV\22]") ~= nil
end

-- leave visual mode, keeping the cursor at the selection head
local function esc()
  if visual() then vim.cmd("normal! \27") end
end

local function count()
  return vim.v.count > 0 and tostring(vim.v.count) or ""
end

-- feed keys before any already typed keys; noremap unless `remap`
local function feed(keys, remap)
  api.nvim_feedkeys(vim.keycode(keys), remap and "mi" or "ni", false)
end

local function cursor()
  return api.nvim_win_get_cursor(0)
end

local function line(row)
  return api.nvim_buf_get_lines(0, row - 1, row, true)[1]
end

-- select from `anchor` to `head` ({row, col} as nvim_win_get_cursor uses)
local function select(anchor, head)
  esc()
  api.nvim_win_set_cursor(0, anchor)
  vim.cmd("normal! v")
  api.nvim_win_set_cursor(0, head)
end

-- move the cursor one character forward or backward, across lines
local function step(forward)
  return vim.fn.searchpos([[\v(.|^$)]], forward and "W" or "bW")[1] ~= 0
end

-- in visual mode: extend with `keys` in select mode, else collapse and move
local function xmove(lhs, keys, desc)
  map("x", lhs, function()
    local c = count()
    if not M.extend then esc() end
    feed(c .. (keys or lhs))
  end, { desc = desc })
end

-- map in normal mode and, collapsing any selection first, in visual mode
local function nxmap(lhs, rhs, desc)
  map("n", lhs, rhs, { desc = desc })
  if type(rhs) == "function" then
    map("x", lhs, function() esc(); rhs() end, { desc = desc })
  else
    map("x", lhs, "<Esc>" .. rhs, { desc = desc })
  end
end

local function set_extend(on)
  M.extend = on
  vim.cmd.redrawstatus()
end

-- multicursor.nvim replays a typed key's mapping at every cursor. Mappings
-- that change shared state decide once per typed key, and the replays reuse
-- that decision.
local typed_keys, decided_at, decision = 0, -1, nil
vim.on_key(function(_, typed)
  if typed and typed ~= "" then typed_keys = typed_keys + 1 end
end, api.nvim_create_namespace("helix_typed_keys"))

local function decide(f)
  if decided_at ~= typed_keys then
    decided_at, decision = typed_keys, f()
  end
  return decision
end

---------------------------------------------------------------------------
-- word motions: select the word, like helix w/b/e/W/B/E

local function word(motion)
  local forward = motion:lower() ~= "b"
  local n = vim.v.count1
  local from_selection = visual()
  esc()
  local start, target = cursor(), cursor()
  for i = 1, n do
    -- a repeated motion selects the next word, not the rest of this one
    if (from_selection or i > 1) and not step(forward) then break end
    start = cursor()
    vim.cmd("normal! " .. motion)
    target = cursor()
    if motion:lower() == "w" then
      if target[1] > start[1] then
        -- stop at the end of the line
        target = { start[1], math.max(#line(start[1]) - 1, 0) }
      elseif target[2] > start[2] then
        -- select up to the next word, not including it
        step(false)
        target = cursor()
      end
    end
    api.nvim_win_set_cursor(0, target)
  end
  select(start, target)
end

---------------------------------------------------------------------------
-- treesitter selection: helix Alt-o, Alt-i, Alt-n, Alt-p

local sel_history = {}

-- current selection as a treesitter range (0-based, end exclusive)
local function selection_range()
  local a, b = vim.fn.getpos("v"), vim.fn.getpos(".")
  if not visual() then a = b end
  local s, e = a, b
  if a[2] > b[2] or (a[2] == b[2] and a[3] > b[3]) then s, e = b, a end
  local sr, sc, er, ec = s[2] - 1, s[3] - 1, e[2] - 1, e[3] - 1
  local last = line(e[2])
  if vim.fn.mode() == "V" then
    sc, ec = 0, #last
  elseif ec < #last then
    ec = ec + vim.str_utf_end(last, ec + 1) + 1
  end
  return { sr, sc, er, ec }
end

local function select_range(r)
  local sr, sc, er, ec = r[1], r[2], r[3], r[4]
  if ec == 0 and er > sr then
    er = er - 1
    ec = math.max(#line(er + 1) - 1, 0)
  else
    ec = math.max(ec - 1, 0)
  end
  select({ sr + 1, sc }, { er + 1, ec })
end

local function node_at_selection()
  local ok, parser = pcall(vim.treesitter.get_parser)
  if not ok or not parser then return end
  parser:parse()
  local r = selection_range()
  return parser:named_node_for_range(r, { ignore_injections = false }), r
end

local function same_range(node, r)
  local sr, sc, er, ec = node:range()
  return sr == r[1] and sc == r[2] and er == r[3] and ec == r[4]
end

function M.expand_selection()
  local node, r = node_at_selection()
  while node and same_range(node, r) do node = node:parent() end
  if not node then return end
  if not visual() then sel_history = {} end
  table.insert(sel_history, r)
  select_range({ node:range() })
end

function M.shrink_selection()
  local r = table.remove(sel_history)
  if r then
    select_range(r)
    return
  end
  local node = node_at_selection()
  local child = node and node:named_child(0)
  if child then select_range({ child:range() }) end
end

function M.select_sibling(next)
  local node, r = node_at_selection()
  -- select the sibling of the selected node, or of its closest ancestor
  while node do
    if not same_range(node, r) then
      local s, e = node:range()
      local ns, ne = r[1], r[3]
      if not (s <= ns and e >= ne) then break end
    end
    local sib = next and node:next_named_sibling() or node:prev_named_sibling()
    if sib then
      sel_history = {}
      select_range({ sib:range() })
      return
    end
    node = node:parent()
  end
end

---------------------------------------------------------------------------
-- text objects (helix match mode mi/ma), using mini.ai for most of them

local native_objects = { w = true, W = true, p = true, s = true }

local function textobject(ai)
  return function()
    local id = vim.fn.getcharstr()
    if native_objects[id] then
      esc()
      vim.cmd("normal! v" .. ai .. id)
    else
      require("mini.ai").select_textobject(ai, id)
    end
  end
end

---------------------------------------------------------------------------
-- statusline mode, like helix NOR/INS/SEL

function M.mode()
  local m = vim.fn.mode()
  if m:find("^[iR]") then return "%#StatusModeInsert# INS " end
  if visual() and M.extend then return "%#StatusModeSelect# SEL " end
  return "%#StatusModeNormal# NOR "
end

---------------------------------------------------------------------------

function M.setup()
  vim.g.mapleader = " "
  -- matchit maps % (helix: select all); mm is bracket matching in helix
  vim.g.loaded_matchit = 1

  api.nvim_create_autocmd("ModeChanged", {
    group = api.nvim_create_augroup("helix_extend", {}),
    callback = function()
      if not vim.v.event.new_mode:find("^[vV\22]") then M.extend = false end
    end,
  })

  -- remove nvim defaults that clash with helix keys or delay them
  for _, m in ipairs({
    { "n", "gcc" }, { "o", "gc" }, { "n", "grn" }, { "n", "grr" }, { "n", "gri" },
    { "n", "grt" }, { "x", "grn" }, { "n", "gra" }, { "x", "gra" }, { "n", "gO" },
    { "x", "an" }, { "x", "in" },
  }) do
    pcall(vim.keymap.del, m[1], m[2])
  end

  -- movement: in visual mode collapse the selection, or extend in select mode
  for _, k in ipairs({ "h", "j", "k", "l", "<Left>", "<Right>", "<Up>", "<Down>", "G" }) do
    xmove(k)
  end

  for _, k in ipairs({ "w", "b", "e", "W", "B", "E" }) do
    local desc = "Select " .. k .. " motion"
    map("n", k, function() word(k) end, { desc = desc })
    map("x", k, function()
      if M.extend then feed(count() .. k) else word(k) end
    end, { desc = desc })
  end

  for _, k in ipairs({ "f", "t", "F", "T" }) do
    map("n", k, function() feed("v" .. count() .. k) end, { desc = "Select to char" })
    map("x", k, function()
      local c = count()
      if M.extend then
        feed(c .. k)
      else
        esc()
        feed("v" .. c .. k)
      end
    end, { desc = "Select to char" })
  end
  map("n", "<M-.>", function() feed("v" .. count() .. ";") end, { desc = "Repeat last f/t" })
  map("x", "<M-.>", function()
    local c = count()
    if M.extend then feed(c .. ";") else esc(); feed("v" .. c .. ";") end
  end, { desc = "Repeat last f/t" })

  -- select mode
  map("n", "v", function() set_extend(true); feed(count() .. "v") end, { desc = "Select mode" })
  map("x", "v", function()
    set_extend(decide(function() return not M.extend end))
  end, { desc = "Toggle select mode" })
  map("x", "<Esc>", function()
    if decide(function() return M.extend end) then set_extend(false) else esc() end
  end, { desc = "Exit select mode / collapse" })
  map("n", "<Esc>", "<Cmd>nohlsearch<CR><Esc>")

  -- selection manipulation
  map("n", "x", "V", { desc = "Select line" })
  map("x", "x", function() return vim.fn.mode() == "V" and "j" or "V" end,
    { expr = true, desc = "Extend line selection" })
  map("n", "X", "V", { desc = "Select line" })
  map("x", "X", function() return vim.fn.mode() == "V" and "" or "V" end,
    { expr = true, desc = "Extend selection to line bounds" })
  map("n", "%", "ggVG", { desc = "Select all" })
  map("x", "%", "<Esc>ggVG", { desc = "Select all" })
  map("n", ";", "<Nop>")
  map("x", ";", "<Esc>", { desc = "Collapse selection" })
  map("n", ",", "<Nop>")
  map("x", ",", "<Esc>", { desc = "Keep primary selection" })
  map("x", "<M-;>", "o", { desc = "Flip selection" })
  map("x", "<M-:>", function()
    local a, b = vim.fn.getpos("v"), vim.fn.getpos(".")
    return (b[2] < a[2] or (b[2] == a[2] and b[3] < a[3])) and "o" or ""
  end, { expr = true, desc = "Ensure selection forward" })

  map({ "n", "x" }, "<M-o>", M.expand_selection, { desc = "Expand selection" })
  map({ "n", "x" }, "<M-Up>", M.expand_selection, { desc = "Expand selection" })
  map({ "n", "x" }, "<M-i>", M.shrink_selection, { desc = "Shrink selection" })
  map({ "n", "x" }, "<M-Down>", M.shrink_selection, { desc = "Shrink selection" })
  map({ "n", "x" }, "<M-n>", function() M.select_sibling(true) end, { desc = "Select next sibling" })
  map({ "n", "x" }, "<M-Right>", function() M.select_sibling(true) end, { desc = "Select next sibling" })
  map({ "n", "x" }, "<M-p>", function() M.select_sibling(false) end, { desc = "Select previous sibling" })
  map({ "n", "x" }, "<M-Left>", function() M.select_sibling(false) end, { desc = "Select previous sibling" })

  -- changes
  map("n", "d", "x", { desc = "Delete selection" })
  map("n", "<M-d>", '"_x', { desc = "Delete selection without yanking" })
  map("x", "<M-d>", '"_d', { desc = "Delete selection without yanking" })
  map("n", "c", "s", { desc = "Change selection" })
  map("n", "<M-c>", '"_s', { desc = "Change selection without yanking" })
  map("x", "<M-c>", '"_c', { desc = "Change selection without yanking" })
  map("n", "y", "yl", { desc = "Yank selection" })
  map("x", "y", "ygv", { desc = "Yank selection" })
  map("x", "p", "<Esc>`>p", { desc = "Paste after selection" })
  map("x", "P", "<Esc>`<P", { desc = "Paste before selection" })
  map("n", "R", "vP", { desc = "Replace with yanked" })
  map("x", "R", "P", { desc = "Replace with yanked" })
  map("x", "i", "<Esc>`<i", { desc = "Insert before selection" })
  map("x", "a", "<Esc>`>a", { desc = "Append after selection" })
  map("x", "I", "<Esc>I", { desc = "Insert at line start" })
  map("x", "A", "<Esc>A", { desc = "Append at line end" })
  map("x", "o", "<Esc>`>o", { desc = "Open line below" })
  map("x", "O", "<Esc>`<O", { desc = "Open line above" })
  map("n", "u", "u", { desc = "Undo" })
  map("x", "u", "<Esc>u", { desc = "Undo" })
  map("n", "U", "<C-r>", { desc = "Redo" })
  map("x", "U", "<Esc><C-r>", { desc = "Redo" })
  map("n", "<M-u>", "g-", { desc = "Earlier" })
  map("n", "<M-U>", "g+", { desc = "Later" })
  map("n", "`", "gul", { desc = "Lowercase" })
  map("x", "`", "u", { desc = "Lowercase" })
  map("n", "<M-`>", "gUl", { desc = "Uppercase" })
  map("x", "<M-`>", "U", { desc = "Uppercase" })
  map("n", ">", ">>", { desc = "Indent" })
  map("n", "<", "<<", { desc = "Unindent" })
  map("x", ">", ">gv", { desc = "Indent" })
  map("x", "<", "<gv", { desc = "Unindent" })
  map("n", "Q", function() return vim.fn.reg_recording() == "" and "qq" or "q" end,
    { expr = true, desc = "Record macro" })
  map("n", "q", "@q", { desc = "Replay macro" })
  map({ "n", "x" }, "<C-s>", "m'", { desc = "Save to jumplist" })

  -- search selects the match
  map("n", "n", "ngn", { desc = "Select next match" })
  map("n", "N", "Ngn", { desc = "Select previous match" })
  map("x", "n", function() return M.extend and "n" or "<Esc>ngn" end, { expr = true, desc = "Select next match" })
  map("x", "N", function() return M.extend and "N" or "<Esc>`<Ngn" end, { expr = true, desc = "Select previous match" })

  -- goto mode
  map("n", "gg", function() feed(count() .. "gg") end, { desc = "Goto line / file start" })
  xmove("gg", "gg", "Goto line / file start")
  map("n", "ge", "G", { desc = "Goto last line" })
  xmove("ge", "G", "Goto last line")
  map("n", "gh", "0", { desc = "Goto line start" })
  xmove("gh", "0", "Goto line start")
  map("n", "gl", "$", { desc = "Goto line end" })
  xmove("gl", "g_", "Goto line end")
  map("n", "gs", "^", { desc = "Goto first non-whitespace" })
  xmove("gs", "^", "Goto first non-whitespace")
  map("n", "gt", "H", { desc = "Goto window top" })
  xmove("gt", "H", "Goto window top")
  map("n", "gc", "M", { desc = "Goto window center" })
  xmove("gc", "M", "Goto window center")
  map("n", "gb", "L", { desc = "Goto window bottom" })
  xmove("gb", "L", "Goto window bottom")
  nxmap("ga", "<C-^>", "Goto last accessed file")
  nxmap("gn", "<Cmd>bnext<CR>", "Goto next buffer")
  nxmap("gp", "<Cmd>bprevious<CR>", "Goto previous buffer")
  nxmap("g.", "`.", "Goto last modification")
  nxmap("gd", vim.lsp.buf.definition, "Goto definition")
  nxmap("gD", vim.lsp.buf.declaration, "Goto declaration")
  nxmap("gy", vim.lsp.buf.type_definition, "Goto type definition")
  nxmap("gi", vim.lsp.buf.implementation, "Goto implementation")
  nxmap("gr", function() require("mini.extra").pickers.lsp({ scope = "references" }) end,
    "Goto references")

  -- match mode
  map("n", "mm", "%", { desc = "Goto matching bracket" })
  xmove("mm", "%", "Goto matching bracket")
  map({ "n", "x" }, "mi", textobject("i"), { desc = "Select inside textobject" })
  map({ "n", "x" }, "ma", textobject("a"), { desc = "Select around textobject" })
  -- mini.surround maps ms in visual mode and md/mr in normal mode
  map("n", "ms", function() vim.cmd("normal! v"); feed("ms", true) end, { desc = "Surround add" })
  map("x", "md", function() esc(); feed("md", true) end, { desc = "Surround delete" })
  map("x", "mr", function() esc(); feed("mr", true) end, { desc = "Surround replace" })

  -- unimpaired
  for key, id in pairs({ f = "f", t = "t", a = "a", c = "c", T = "T" }) do
    local function move(search_method)
      return function()
        require("mini.ai").move_cursor("left", "a", id, { search_method = search_method })
      end
    end
    nxmap("]" .. key, move("next"), "Goto next " .. id .. " textobject")
    nxmap("[" .. key, move("prev"), "Goto previous " .. id .. " textobject")
  end
  map("n", "]p", "}", { desc = "Next paragraph" })
  map("n", "[p", "{", { desc = "Previous paragraph" })
  map("n", "]<Space>", "<Cmd>call append(line('.'), repeat([''], v:count1))<CR>",
    { desc = "Add newline below" })
  map("n", "[<Space>", "<Cmd>call append(line('.') - 1, repeat([''], v:count1))<CR>",
    { desc = "Add newline above" })

  -- comments (mini.comment maps <C-c>)
  map({ "n", "x" }, "<Leader>c", "<C-c>", { remap = true, desc = "Toggle comment" })

  -- space mode
  local function pick(name, opts)
    return function()
      local pickers = vim.tbl_extend("force", require("mini.pick").builtin, require("mini.extra").pickers)
      pickers[name](opts and opts())
    end
  end
  local function root()
    return vim.fs.root(0, ".git") or vim.fn.getcwd()
  end
  local function files(cwd)
    return function()
      require("mini.pick").builtin.cli({
        command = { "rg", "--files", "--hidden", "--glob", "!.git" },
      }, {
        source = {
          name = "Files",
          cwd = cwd(),
          show = function(buf, items, query)
            require("mini.pick").default_show(buf, items, query, { show_icons = true })
          end,
        },
      })
    end
  end
  nxmap("<Leader>f", files(root), "File picker")
  nxmap("<Leader>F", files(vim.fn.getcwd), "File picker at cwd")
  nxmap("<Leader>b", pick("buffers"), "Buffer picker")
  nxmap("<Leader>j", pick("list", function() return { scope = "jump" } end), "Jumplist picker")
  nxmap("<Leader>s", pick("lsp", function() return { scope = "document_symbol" } end), "Symbol picker")
  nxmap("<Leader>S", pick("lsp", function() return { scope = "workspace_symbol" } end), "Workspace symbol picker")
  nxmap("<Leader>d", pick("diagnostic", function() return { scope = "current" } end), "Diagnostic picker")
  nxmap("<Leader>D", pick("diagnostic", function() return { scope = "all" } end), "Workspace diagnostic picker")
  nxmap("<Leader>g", pick("git_files", function() return { scope = "modified" } end), "Changed file picker")
  nxmap("<Leader>/", pick("grep_live"), "Global search")
  nxmap("<Leader>'", pick("resume"), "Last picker")
  nxmap("<Leader>?", pick("keymaps"), "Command palette")
  nxmap("<Leader>e", pick("explorer", function() return { cwd = root() } end), "File explorer")
  nxmap("<Leader>E", pick("explorer", function() return { cwd = vim.fn.expand("%:p:h") } end),
    "File explorer at buffer dir")
  nxmap("<Leader>k", vim.lsp.buf.hover, "Hover")
  nxmap("<Leader>r", vim.lsp.buf.rename, "Rename symbol")
  nxmap("<Leader>h", vim.lsp.buf.document_highlight, "Highlight references")
  map({ "n", "x" }, "<Leader>a", vim.lsp.buf.code_action, { desc = "Code action" })
  map({ "n", "x" }, "<Leader>w", "<C-w>", { desc = "Window" })
  map("n", "<Leader>y", '"+yl', { desc = "Yank to clipboard" })
  map("x", "<Leader>y", '"+ygv', { desc = "Yank to clipboard" })
  map("n", "<Leader>Y", '"+yl', { desc = "Yank main selection to clipboard" })
  map("x", "<Leader>Y", '"+ygv', { desc = "Yank main selection to clipboard" })
  map("n", "<Leader>p", '"+p', { desc = "Paste clipboard after" })
  map("x", "<Leader>p", '<Esc>`>"+p', { desc = "Paste clipboard after" })
  map("n", "<Leader>P", '"+P', { desc = "Paste clipboard before" })
  map("x", "<Leader>P", '<Esc>`<"+P', { desc = "Paste clipboard before" })
  map("n", "<Leader>R", 'v"+P', { desc = "Replace with clipboard" })
  map("x", "<Leader>R", '"+P', { desc = "Replace with clipboard" })

  -- insert mode
  map("i", "<C-k>", "<C-o>D", { desc = "Delete to line end" })
  map("i", "<C-d>", "<Del>", { desc = "Delete next char" })
  map("i", "<M-d>", "<C-o>dw", { desc = "Delete next word" })
  map("i", "<C-s>", "<C-g>u", { desc = "Commit undo checkpoint" })

  -- helix typable commands
  local function cabbrev(lhs, rhs)
    map("ca", lhs, function()
      return (vim.fn.getcmdtype() == ":" and vim.fn.getcmdline() == lhs) and rhs or lhs
    end, { expr = true })
  end
  cabbrev("o", "edit")
  cabbrev("open", "edit")
  cabbrev("bc", "bdelete")
  cabbrev("bclose", "bdelete")
  cabbrev("rl", "edit!")
  cabbrev("reload", "edit!")
  cabbrev("hs", "split")
  cabbrev("fmt", "lua vim.lsp.buf.format()")
  cabbrev("format", "lua vim.lsp.buf.format()")
end

-- multiple selections, called when multicursor.nvim is loaded
function M.setup_multicursor()
  local mc = require("multicursor-nvim")
  mc.setup()

  map({ "n", "x" }, "C", function() mc.lineAddCursor(1) end, { desc = "Copy selection to next line" })
  map({ "n", "x" }, "<M-C>", function() mc.lineAddCursor(-1) end,
    { desc = "Copy selection to previous line" })
  map("x", "s", mc.matchCursors, { desc = "Select regex matches in selections" })
  map("x", "S", mc.splitCursors, { desc = "Split selections on regex" })
  map("x", "<M-s>", function()
    mc.action(function(ctx)
      ctx:forEachCursor(function(cursor) cursor:splitVisualLines() end)
    end)
  end, { desc = "Split selections on newlines" })
  map("n", "s", "<Nop>")
  map("n", "S", "<Nop>")
  map({ "n", "x" }, "&", mc.alignCursors, { desc = "Align selections" })

  -- only while there are multiple cursors
  mc.addKeymapLayer(function(set)
    set({ "n", "x" }, ",", mc.clearCursors, { desc = "Keep primary selection" })
    set({ "n", "x" }, "<M-,>", mc.deleteCursor, { desc = "Remove primary selection" })
    set({ "n", "x" }, ")", function() mc.nextCursor(true) end, { desc = "Next selection" })
    set({ "n", "x" }, "(", function() mc.prevCursor(true) end, { desc = "Previous selection" })
    set("x", "<M-)>", function() mc.transposeCursors(1) end, { desc = "Rotate selection contents" })
    set("x", "<M-(>", function() mc.transposeCursors(-1) end, { desc = "Rotate selection contents backward" })
    set("n", "<Esc>", mc.clearCursors, { desc = "Clear selections" })
  end)
end

return M
