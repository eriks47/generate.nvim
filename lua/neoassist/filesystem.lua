local M = {}

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

  header_extension = '%' .. header_extension
  local source_path = string.gsub(header_name, header_extension, source_extension)

  return source_path
end

return M
