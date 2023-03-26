if vim.g.loaded_neoassist ~= nil then
  return
end
vim.g.loaded_neoassist = true

local api = vim.api
local ts = vim.treesitter
local uv = vim.loop

api.nvim_create_user_command('Neoassist', function(params)
  local header = require('neoassist.header')
  local source = require('neoassist.source')

  local path = api.nvim_buf_get_name(0)
  local parser = ts.get_parser()
  local root = parser:parse()[1]:root()

  local arg = params.fargs[1]
  if arg == 'createImplementation' then
    local namespaces = header.get_declarations(root)
    source.insert_header(path)
    source.implement_methods(namespaces)
  end
end, {
  bang = false,
  bar = false,
  nargs = 1,
  addr = 'other',
  complete = function()
    return { 'createImplementation' }
  end,
})
