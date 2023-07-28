local config = {}

local function first_non_nil(...)
    local n = select("#", ...)
    for i = 1, n do
        local value = select(i, ...)
        if value ~= nil then
            return value
        end
    end
end

local default = {
    add_header_include = true
}

function config.setup(options)
    if options == nil then
        options = {}
    end

    vim.g.generate_add_header_include =
      first_non_nil(options.add_header_include, default.add_header_include)
end

return config
