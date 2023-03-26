local M = {}

function M.children_with_type(type, parent)
  local found = {}

  for child in parent:iter_children() do
    local child_type = child:type()

    if child_type == type then
      table.insert(found, child)
    end
  end

  return found
end

-- @return bool
function M.is_function_declaration(node)
  local type = node:type()
  if type == 'function_definition' then
    return false
  end

  local declrators = M.children_with_type('function_declarator', node)
  if #declrators ~= 0 then
    return true
  end

  local declarations = M.children_with_type('declaration', node)
  if #declarations ~= 0 then
    return true
  end

  return false
end

-- @returns <node> or nil
function M.first_child_with_type(type, parent)
  for child in parent:iter_children() do
    local child_type = child:type()

    if child_type == type then
      return child
    end
  end

  return nil
end

function M.declarator_identifier(declarator)
  local interesting_names = {
    'field_identifier',
    'identifier',
    'destructor_name',
    'operator_name',
  }

  for i = 1, #interesting_names do
    local name = interesting_names[i]
    local identifier = M.first_child_with_type(name, declarator)
    if identifier ~= nil then
      return identifier
    end
  end

  return nil
end

return M
