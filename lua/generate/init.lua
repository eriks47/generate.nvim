if vim.g.loaded_generate ~= nil then
  return
end
vim.g.loaded_generate = true

local M = {}

local api = vim.api
local ts = vim.treesitter
local uv = vim.loop
local fs = require('generate.filesystem')

api.nvim_create_user_command('Generate', function(params)
  local header = require('generate.header')
  local source = require('generate.source')

  local path = api.nvim_buf_get_name(0)
  local parser = ts.get_parser()
  local root = parser:parse()[1]:root()

  local arg = params.fargs[1]
  if arg == 'implementations' then
    local namespaces = header.get_declarations(root)
    -- asynchronously get the implementations file (*.cpp) path
    local util = require 'lspconfig.util'
    local bufnr = vim.api.nvim_get_current_buf()
    bufnr = util.validate_bufnr(bufnr)
    local clangd_client = util.get_active_client_by_name(bufnr, 'clangd')
    local hparams = { uri = vim.uri_from_fname(path) }
    if clangd_client then
      clangd_client.request('textDocument/switchSourceHeader', hparams, function(err, result)
        local filepath = nil
        -- async here
        if err or (not result) then
          print('query clangd cpp file faild, err is ', tostring(err))
          filepath = fs.header_to_source(path)
        end
        -- get cpp file
        if result then
          filepath = vim.uri_to_fname(result)
        end
        source.insert_header(path, filepath)
        source.implement_methods(namespaces)
      end, bufnr)
    else
      -- no lsp avaliable 
      source.insert_header(path, fs.header_to_source(path))
      source.implement_methods(namespaces)
    end
  end
end, {
  bang = false,
  bar = false,
  nargs = 1,
  addr = 'other',
  complete = function()
    return { 'implementations' }
  end,
})

M.setup = require('generate.config').setup

return M
