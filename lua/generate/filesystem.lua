local M = {}

local api = vim.api
local ts = vim.treesitter
local uv = vim.loop
local fs = vim.fs

local exension_index = {
  ['.hpp'] = '.cpp',
  ['.h'] = '.cpp',
  ['.hh'] = '.cc',
  ['.hxx'] = '.cxx',
  ['.h++'] = '.c++',
  ['.H'] = '.C',
}

local source_dir_names = { 'source', 'src' }
local include_dir_names = { 'include', 'inc' }

-- Logically is something like 'cd ..'
local function remove_basename(filepath)
  local first = nil
  for i = #filepath, 1, -1 do
    if string.sub(filepath, i, i) == '/' then
      first = i
      break
    end
  end

  -- Need to substract one to remove forward slash
  return string.sub(filepath, 1, first - 1), string.sub(filepath, first)
end

-- Returns: string (modified or unmodified source_path)
local function attempt_to_change_to_source_dir(source_path)
  -- Remove last directory
  -- Scan it
  -- Decide whether it has source directory
  --     If yes, replace path part with the directory name
  --     Else return source_path

  local directory_above, filename = remove_basename(source_path)
  directory_above = remove_basename(directory_above)

  local file = uv.fs_scandir(directory_above)
  local name, type = uv.fs_scandir_next(file)
  while name ~= nil do
    for i = 1, #source_dir_names do
      if source_dir_names[i] == name and type == 'directory' then
        return directory_above .. '/' .. name .. filename
      end
    end
    name, type = uv.fs_scandir_next(file)
  end

  return source_path
end

-- Returns: string or nil
function M.header_to_source(header_name)
  local source_extension = ''
  local header_extension = ''
  for w in string.gmatch(header_name, '%.%w+') do
    source_extension = exension_index[w]
    header_extension = w
  end

  if source_extension == '' or header_extension == '' then
    return nil
  end

  header_extension = '%' .. header_extension
  local source_path = string.gsub(header_name, header_extension, source_extension)

  -- If a project has separate directories for source files and
  -- header files, placing the source file in the header directory
  -- will be incorrect. Thus if we can detect that the header is
  -- in an "include" directory we can attempt to find the "source"
  -- directory.
  local directory = remove_basename(source_path)
  directory = fs.basename(directory)
  for i = 1, #include_dir_names do
    if string.lower(directory) == include_dir_names[i] then
      source_path = attempt_to_change_to_source_dir(source_path)
    end
  end

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
