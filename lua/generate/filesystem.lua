local M = {}

local api = vim.api
local ts = vim.treesitter
local uv = vim.loop

local exension_index = {
  ['.hpp'] = '.cpp',
  ['.h'] = '.cpp',
  ['.hh'] = '.cc',
  ['.hxx'] = '.cxx',
  ['.h++'] = '.c++',
  ['.H'] = '.C',
}

function M.header_to_source(header_name)
  local source_extension = ''
  local header_extension = ''
  for w in string.gmatch(header_name, '%.%w+') do
    source_extension = exension_index[w]
    header_extension = w
  end

  if source_extension == '' or header_extension == '' then
    api.nvim_err_writeln('Error: Cannot determine the extension of ' .. header_name)
  end

  header_extension = '%' .. header_extension
  local source_path = string.gsub(header_name, header_extension, source_extension)

  return source_path
end

function M.open_file_in_buffer(path)
  api.nvim_command('e ' .. path)
  local bufnr = api.nvim_get_current_buf()
  local parser = ts.get_parser()
  local root = parser:parse()[1]:root()

  return root, bufnr
end

function M.append_to_file(path, content)
  local fd = uv.fs_open(path, 'a', 438)
  uv.fs_write(fd, content .. '\n\n', 0)
  uv.fs_close(fd)
end

return M
