local api = vim.api
local uv = vim.loop
local ts = vim.treesitter
local fn = vim.fn

local ts_util = require('lua.neoassist.treesitter')
local fs = require('lua.neoassist.filesystem')

local M = {
  header_bufnr = -1,
  source_bufnr = -1,
}

local declaration_query = ts.parse_query(
  'cpp',
  [[
    ((function_definition) @method)

    ((template_declaration) @template)
]]
)

local default_param_query = ts.parse_query(
  'cpp',
  [[
    ((optional_parameter_declaration) @parameter)
]]
)

local brace_pattern = '\n{\n\n}\n\n'

local function is_include_present(root, bufnr, include)
  local includes = ts_util.children_with_type('preproc_include', root)
  for i = 1, #includes do
    local text = ts.get_node_text(includes[i], bufnr, {})
    if text == include .. '\n' then
      return true
    end
  end

  return false
end

local function declaration_to_implementation(declaration, namespace, bufnr)
  local prefix = namespace .. '::'
  local text = ts.get_node_text(declaration, bufnr, {})

  -- Remove keywords that shouldn't be present in method implementations
  local keywords = { 'virtual', 'override', 'final', 'static', 'explicit', 'friend' }
  for k = 1, #keywords do
    local pattern = keywords[k] .. '%s*'
    text = string.gsub(text, pattern, '')
  end

  -- Add prefix (i.e. ClassName::)
  local declarator = ts_util.first_child_with_type('function_declarator', declaration)
  if declarator == nil then
    local child = ts_util.first_child_with_type('declaration', declaration)
    declarator = ts_util.first_child_with_type('function_declarator', child)
  end
  local identifier = ts_util.declarator_identifier(declarator)
  local function_name = ts.get_node_text(identifier, bufnr, {})
  function_name = string.gsub(function_name, '%W', '%%%1')
  text = string.gsub(text, function_name, prefix .. function_name)

  -- Remove semicolon
  text = string.sub(text, 1, -2)

  -- Remove default value
  for _, node, _ in default_param_query:iter_captures(declaration, M.header_bufnr) do
    local dirty = ts.get_node_text(node, M.header_bufnr, {})
    local clean = string.gsub(dirty, '%s*=.*', '')
    dirty = string.gsub(dirty, '%W', '%%%1')
    text = string.gsub(text, dirty, clean)
  end

  return text
end

local function get_implemenations(root)
  local strings = {}

  for _, node, _ in declaration_query:iter_captures(root, 0) do
    local text = ts.get_node_text(node, 0, {})
    text = string.gsub(text, '%s+{.*', '')
    table.insert(strings, text)
  end

  return strings
end

local function open_source_buffer(source_path)
  api.nvim_command('e ' .. source_path)
  local bufnr = api.nvim_get_current_buf()
  local parser = ts.get_parser()
  local root = parser:parse()[1]:root()

  return root, bufnr
end

function M.implement_methods(namespaces)
  local path = api.nvim_buf_get_name(0)
  local root, _ = open_source_buffer(path)

  local strings = {}
  local existing_implemenations = get_implemenations(root, M.source_bufnr)
  print(namespaces)
  for _, v in pairs(namespaces) do
    local name = v['name']
    for i = 1, #v['declarations'] do
      local declaration = v['declarations'][i]
      local implementation = declaration_to_implementation(declaration, name, M.header_bufnr)
      if not vim.tbl_contains(existing_implemenations, implementation) then
        table.insert(strings, implementation .. brace_pattern)
      end
    end
  end

  local fd = uv.fs_open(path, 'a', 438)
  uv.fs_write(fd, strings, 0)
  uv.fs_close(fd)
end

function M.insert_header(header_path)
  local source_path = fs.header_to_source(header_path)
  local name = fn.fnamemodify(header_path, ':t')
  local header_text = '#include "' .. name .. '"'

  local header_bufnr = api.nvim_get_current_buf()
  M.header_bufnr = header_bufnr
  local root, source_bufnr = open_source_buffer(source_path)
  M.source_bufnr = source_bufnr

  if not is_include_present(root, M.source_bufnr, header_text) then
    local fd = uv.fs_open(source_path, 'a', 438)
    uv.fs_write(fd, header_text .. '\n\n', 0)
    uv.fs_close(fd)
  end
end

return M
