-- Zed "One Dark", with colors taken from zed/assets/themes/one/one.json.
-- Zed colors with an alpha channel are blended onto the editor background.

vim.cmd("highlight clear")
vim.g.colors_name = "zed-onedark"
vim.o.background = "dark"

local function blend(fg, alpha, bg)
  bg = bg or "#282c33"
  local function ch(hex, i) return tonumber(hex:sub(i, i + 1), 16) end
  local out = "#"
  for _, i in ipairs({ 2, 4, 6 }) do
    out = out .. string.format("%02x", math.floor(ch(fg, i) * alpha + ch(bg, i) * (1 - alpha) + 0.5))
  end
  return out
end

local c = {
  bg = "#282c33",            -- editor.background
  surface = "#2f343e",       -- panel / elevated_surface.background
  chrome = "#3b414d",        -- status_bar.background
  element = "#2e343e",       -- element.background
  hover = "#363c46",         -- element.hover
  selected = "#454a56",      -- element.selected
  border = "#464b57",
  border_variant = "#363c46",
  border_focused = "#47679e",
  fg = "#acb2be",            -- editor.foreground
  text = "#dce0e5",
  muted = "#a9afbc",
  placeholder = "#878a98",
  line_nr = "#4e5a5f",
  line_nr_active = "#d0d4da",
  accent = "#74ade8",

  error = "#d07277",
  warning = "#dec184",
  info = "#74ade8",
  hint = "#788ca6",
  success = "#a1c181",

  vc_added = "#27a657",
  vc_modified = "#d3b020",
  vc_deleted = "#e06c76",

  -- syntax
  keyword = "#b477cf",
  func = "#73ade9",
  string = "#a1c181",
  comment = "#5d636f",
  comment_doc = "#878e98",
  type = "#6eb4bf",
  number = "#bf956a",
  constant = "#dfc184",
  variable = "#acb2be",
  property = "#d07277",
  bracket = "#b2b9c6",
  namespace = "#dce0e5",
  predictive = "#5a6a87",
  punct_special = "#b1574b",
}

local hl = {
  -- editor UI
  Normal = { fg = c.fg, bg = c.bg },
  NormalNC = { link = "Normal" },
  NormalFloat = { fg = c.text, bg = c.surface },
  FloatBorder = { fg = c.border, bg = c.surface },
  FloatTitle = { fg = c.text, bg = c.surface, bold = true },
  Cursor = { fg = c.bg, bg = c.accent },
  lCursor = { link = "Cursor" },
  CursorIM = { link = "Cursor" },
  TermCursor = { link = "Cursor" },
  CursorLine = { bg = blend(c.surface, 0xbf / 255) },
  CursorColumn = { link = "CursorLine" },
  ColorColumn = { bg = blend("#c8ccd4", 0x0d / 255) },
  LineNr = { fg = c.line_nr },
  CursorLineNr = { fg = c.line_nr_active },
  SignColumn = { bg = c.bg },
  FoldColumn = { fg = c.line_nr, bg = c.bg },
  Folded = { fg = c.muted, bg = c.surface },
  Visual = { bg = blend(c.accent, 0x3d / 255) },
  VisualNOS = { link = "Visual" },
  Search = { bg = blend(c.accent, 0x66 / 255) },
  CurSearch = { bg = blend("#e8af74", 0x66 / 255) },
  IncSearch = { link = "CurSearch" },
  Substitute = { link = "CurSearch" },
  MatchParen = { bg = c.selected, bold = true },
  NonText = { fg = c.line_nr },
  Whitespace = { fg = c.line_nr },
  SpecialKey = { fg = c.line_nr },
  EndOfBuffer = { fg = c.bg },
  Conceal = { fg = c.placeholder },
  Directory = { fg = c.accent },
  Title = { fg = c.property, bold = true },
  ErrorMsg = { fg = c.error },
  WarningMsg = { fg = c.warning },
  MoreMsg = { fg = c.success },
  ModeMsg = { fg = c.text },
  Question = { fg = c.accent },
  QuickFixLine = { bg = c.selected },
  WinSeparator = { fg = c.border },
  VertSplit = { link = "WinSeparator" },
  StatusLine = { fg = c.text, bg = c.chrome },
  StatusLineNC = { fg = c.placeholder, bg = c.element },
  WinBar = { fg = c.text, bg = c.bg },
  WinBarNC = { fg = c.placeholder, bg = c.bg },
  TabLine = { fg = c.placeholder, bg = c.surface },
  TabLineSel = { fg = c.text, bg = c.bg },
  TabLineFill = { bg = c.surface },
  Pmenu = { fg = c.text, bg = c.surface },
  PmenuSel = { bg = c.selected },
  PmenuKind = { fg = c.type, bg = c.surface },
  PmenuKindSel = { fg = c.type, bg = c.selected },
  PmenuExtra = { fg = c.placeholder, bg = c.surface },
  PmenuExtraSel = { fg = c.placeholder, bg = c.selected },
  PmenuSbar = { bg = c.surface },
  PmenuThumb = { bg = c.selected },
  WildMenu = { link = "PmenuSel" },
  SpellBad = { sp = c.error, undercurl = true },
  SpellCap = { sp = c.warning, undercurl = true },
  SpellLocal = { sp = c.info, undercurl = true },
  SpellRare = { sp = c.hint, undercurl = true },

  -- diff / version control
  DiffAdd = { bg = blend(c.success, 0x1a / 255) },
  DiffChange = { bg = blend(c.warning, 0x1a / 255) },
  DiffDelete = { fg = c.error, bg = blend(c.error, 0x1a / 255) },
  DiffText = { bg = blend(c.warning, 0x33 / 255) },
  Added = { fg = c.vc_added },
  Changed = { fg = c.vc_modified },
  Removed = { fg = c.vc_deleted },
  diffAdded = { link = "Added" },
  diffChanged = { link = "Changed" },
  diffRemoved = { link = "Removed" },
  MiniDiffSignAdd = { fg = c.vc_added },
  MiniDiffSignChange = { fg = c.vc_modified },
  MiniDiffSignDelete = { fg = c.vc_deleted },

  -- diagnostics
  DiagnosticError = { fg = c.error },
  DiagnosticWarn = { fg = c.warning },
  DiagnosticInfo = { fg = c.info },
  DiagnosticHint = { fg = c.hint },
  DiagnosticOk = { fg = c.success },
  DiagnosticVirtualTextError = { fg = c.error, bg = blend(c.error, 0x1a / 255) },
  DiagnosticVirtualTextWarn = { fg = c.warning, bg = blend(c.warning, 0x1a / 255) },
  DiagnosticVirtualTextInfo = { fg = c.info, bg = blend(c.info, 0x1a / 255) },
  DiagnosticVirtualTextHint = { fg = c.hint, bg = blend("#5a6f89", 0x1a / 255) },
  DiagnosticUnderlineError = { sp = c.error, undercurl = true },
  DiagnosticUnderlineWarn = { sp = c.warning, undercurl = true },
  DiagnosticUnderlineInfo = { sp = c.info, undercurl = true },
  DiagnosticUnderlineHint = { sp = c.hint, undercurl = true },
  DiagnosticUnnecessary = { fg = c.placeholder },
  DiagnosticDeprecated = { strikethrough = true },

  -- LSP
  LspReferenceText = { bg = blend(c.accent, 0x1a / 255) },
  LspReferenceRead = { bg = blend(c.accent, 0x1a / 255) },
  LspReferenceWrite = { bg = blend("#555a63", 0x66 / 255) },
  LspInlayHint = { fg = c.hint, bg = blend("#5a6f89", 0x1a / 255) },
  LspSignatureActiveParameter = { fg = c.accent, bold = true },
  LspCodeLens = { fg = c.comment },

  -- legacy syntax groups
  Comment = { fg = c.comment },
  Constant = { fg = c.constant },
  String = { fg = c.string },
  Character = { fg = c.string },
  Number = { fg = c.number },
  Boolean = { fg = c.number },
  Float = { fg = c.number },
  Identifier = { fg = c.variable },
  Function = { fg = c.func },
  Statement = { fg = c.keyword },
  Conditional = { fg = c.keyword },
  Repeat = { fg = c.keyword },
  Label = { fg = c.accent },
  Operator = { fg = c.type },
  Keyword = { fg = c.keyword },
  Exception = { fg = c.keyword },
  PreProc = { fg = c.keyword },
  Include = { fg = c.keyword },
  Define = { fg = c.keyword },
  Macro = { fg = c.func },
  PreCondit = { fg = c.keyword },
  Type = { fg = c.type },
  StorageClass = { fg = c.keyword },
  Structure = { fg = c.type },
  Typedef = { fg = c.type },
  Special = { fg = c.number },
  SpecialChar = { fg = c.comment_doc },
  Tag = { fg = c.accent },
  Delimiter = { fg = c.bracket },
  SpecialComment = { fg = c.comment_doc },
  Debug = { fg = c.property },
  Underlined = { underline = true },
  Ignore = { fg = c.comment },
  Error = { fg = c.error },
  Todo = { fg = c.bg, bg = c.warning, bold = true },

  -- treesitter captures, mapped to the Zed capture that Zed would use
  ["@variable"] = { fg = c.variable },
  ["@variable.builtin"] = { fg = c.number },      -- variable.special
  ["@variable.parameter"] = { fg = c.property },
  ["@variable.member"] = { fg = c.property },     -- property
  ["@property"] = { fg = c.property },
  ["@constant"] = { fg = c.constant },
  ["@constant.builtin"] = { fg = c.constant },
  ["@constant.macro"] = { fg = c.constant },
  ["@module"] = { fg = c.namespace },             -- namespace
  ["@module.builtin"] = { fg = c.namespace },
  ["@label"] = { fg = c.accent },
  ["@string"] = { fg = c.string },
  ["@string.documentation"] = { fg = c.string },
  ["@string.escape"] = { fg = c.comment_doc },
  ["@string.regexp"] = { fg = c.number },
  ["@string.special"] = { fg = c.number },
  ["@string.special.symbol"] = { fg = c.number },
  ["@string.special.url"] = { fg = c.type },      -- link_uri
  ["@character"] = { fg = c.string },
  ["@character.special"] = { fg = c.number },
  ["@boolean"] = { fg = c.number },
  ["@number"] = { fg = c.number },
  ["@number.float"] = { fg = c.number },
  ["@type"] = { fg = c.type },
  ["@type.builtin"] = { fg = c.type },
  ["@type.definition"] = { fg = c.type },
  ["@attribute"] = { fg = c.accent },
  ["@attribute.builtin"] = { fg = c.accent },
  ["@function"] = { fg = c.func },
  ["@function.builtin"] = { fg = c.func },
  ["@function.call"] = { fg = c.func },
  ["@function.macro"] = { fg = c.func },
  ["@function.method"] = { fg = c.func },
  ["@function.method.call"] = { fg = c.func },
  ["@constructor"] = { fg = c.func },
  ["@operator"] = { fg = c.type },
  ["@keyword"] = { fg = c.keyword },
  ["@keyword.directive"] = { fg = c.keyword },    -- preproc
  ["@punctuation"] = { fg = c.variable },
  ["@punctuation.bracket"] = { fg = c.bracket },
  ["@punctuation.delimiter"] = { fg = c.bracket },
  ["@punctuation.special"] = { fg = c.punct_special },
  ["@comment"] = { fg = c.comment },
  ["@comment.documentation"] = { fg = c.comment_doc },
  ["@comment.error"] = { fg = c.error, bold = true },
  ["@comment.warning"] = { fg = c.warning, bold = true },
  ["@comment.todo"] = { fg = c.info, bold = true },
  ["@comment.note"] = { fg = c.hint, bold = true },
  ["@markup.heading"] = { fg = c.property },      -- title
  ["@markup.strong"] = { fg = c.number, bold = true },
  ["@markup.italic"] = { fg = c.accent, italic = true },
  ["@markup.strikethrough"] = { strikethrough = true },
  ["@markup.underline"] = { underline = true },
  ["@markup.raw"] = { fg = c.string },            -- text.literal
  ["@markup.quote"] = { fg = c.comment_doc, italic = true },
  ["@markup.link"] = { fg = c.func },
  ["@markup.link.label"] = { fg = c.func, italic = true },
  ["@markup.link.url"] = { fg = c.type, underline = true },
  ["@markup.list"] = { fg = c.property },         -- punctuation.list_marker
  ["@markup.list.checked"] = { fg = c.success },
  ["@markup.list.unchecked"] = { fg = c.muted },
  ["@diff.plus"] = { fg = "#98c379" },
  ["@diff.minus"] = { fg = "#e06c75" },
  ["@diff.delta"] = { fg = c.warning },
  ["@tag"] = { fg = c.accent },
  ["@tag.builtin"] = { fg = c.accent },
  ["@tag.attribute"] = { fg = c.accent },
  ["@tag.delimiter"] = { fg = c.bracket },

  -- LSP semantic tokens: keep the Zed (treesitter) look
  ["@lsp.type.namespace"] = { link = "@module" },
  ["@lsp.type.enumMember"] = { fg = c.func },     -- variant
  ["@lsp.type.enum"] = { fg = c.type },
  ["@lsp.type.macro"] = { link = "@function.macro" },
  ["@lsp.type.selfKeyword"] = { link = "@variable.builtin" },
  ["@lsp.type.lifetime"] = { link = "@label" },
  ["@lsp.type.comment"] = {},
  ["@lsp.mod.mutable"] = {},

  -- helix-style mode indicator in the statusline
  StatusModeNormal = { fg = c.bg, bg = c.accent, bold = true },
  StatusModeInsert = { fg = c.bg, bg = c.success, bold = true },
  StatusModeSelect = { fg = c.bg, bg = c.keyword, bold = true },
  StatusLineMuted = { fg = c.muted, bg = c.chrome },

  -- multicursor.nvim
  MultiCursorCursor = { fg = c.bg, bg = c.accent },
  MultiCursorVisual = { link = "Visual" },
  MultiCursorSign = { fg = c.accent, bg = c.bg },
  MultiCursorMatchPreview = { link = "Search" },
  MultiCursorDisabledCursor = { fg = c.bg, bg = c.placeholder },
  MultiCursorDisabledVisual = { bg = c.selected },
  MultiCursorDisabledSign = { fg = c.placeholder, bg = c.bg },

  -- mini.nvim
  MiniPickMatchCurrent = { bg = c.selected },
  MiniPickMatchRanges = { fg = c.accent, bold = true },
  MiniPickPrompt = { fg = c.text, bg = c.surface },
  MiniPickBorderText = { fg = c.text, bg = c.surface },
  MiniClueTitle = { fg = c.text, bg = c.surface, bold = true },
  MiniClueDescGroup = { fg = c.keyword, bg = c.surface },
  MiniClueNextKey = { fg = c.accent, bg = c.surface },
  MiniClueDescSingle = { fg = c.text, bg = c.surface },
  MiniClueSeparator = { fg = c.border, bg = c.surface },
}

for group, spec in pairs(hl) do
  vim.api.nvim_set_hl(0, group, spec)
end

local ansi = {
  "#282c34", "#e06c75", "#98c379", "#e5c07b", "#61afef", "#c678dd", "#56b6c2", "#abb2bf",
  "#636d83", "#ea858b", "#aad581", "#ffd885", "#85c1ff", "#d398eb", "#6ed5de", "#fafafa",
}
for i, color in ipairs(ansi) do
  vim.g["terminal_color_" .. (i - 1)] = color
end
