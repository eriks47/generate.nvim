local ts = vim.treesitter
local ts_util = require('generate.treesitter')

local M = {}

local class_query = ts.query.parse_query(
  'cpp',
  [[
    ((class_specifier) @class)

    ((namespace_definition) @namespace)
]]
)

function M.get_declarations(root)
  -- The first thing we need is to find all classes and
  -- namespaces so that we know "where to look" for functions
  -- and methods that we have to implement
  local namespaces = {}
  for _, node, _ in class_query:iter_captures(root, 0) do
    namespaces[node] = {}
  end

  -- After we have all roots for classes and namespaces we need
  -- to find their names; this is necessary because an implementation
  -- must contain the relevant namespace name (e.g. Window::Create())
  for k, v in pairs(namespaces) do
    local identifier = ts_util.first_child_with_type('type_identifier', k)
    if identifier == nil then
      identifier = ts_util.first_child_with_type('namespace_identifier', k)
    end
    if identifier == nil then
      identifier = ts_util.first_child_with_type('identifier', k)
    end
    local text = ts.get_node_text(identifier, 0, {})
    v['name'] = text
  end

  for k, v in pairs(namespaces) do
    v['declarations'] = {}
    local fields = ts_util.first_child_with_type('field_declaration_list', k)
    if fields == nil then
      fields = ts_util.first_child_with_type('declaration_list', k)
      if fields == nil then
        error('Failed to find fields')
      end
    end
    for node in fields:iter_children() do
      if ts_util.is_function_declaration(node) then
        table.insert(v['declarations'], node)
      end
    end
  end

  return namespaces
end

return M
