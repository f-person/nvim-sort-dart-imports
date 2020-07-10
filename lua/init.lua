local project_name

-- returns output of a command
function os.capture(cmd)
    local handle = assert(io.popen(cmd, 'r'))
    local output = assert(handle:read('*a'))
    handle:close()

    output = string.gsub(
                 string.gsub(string.gsub(output, '^%s+', ''), '%s+$', ''),
                 '[\n\r]+', ' ')
    return output
end

local function file_exists(filepath)
    local f = io.open(filepath, "rb")
    if f then f:close() end
    return f ~= nil
end

-- reads all lines of a file, returns an empty table if the file does not exist
local function read_lines(filepath)
    if not file_exists(filepath) then return {} end
    local lines = {}
    for line in io.lines(filepath) do lines[#lines + 1] = line end
    return lines
end

local function isblank(str)
    return not str or #str == 0 or str:match("^%s+$") ~= nil
end

local function find_project_name()
    -- find pubspec.yaml
    local pubspecpath = os.capture("find . -name 'pubspec.yaml'")
    if not (pubspecpath and #pubspecpath > 0) then return end

    local lines = read_lines(pubspecpath)
    for _, line in pairs(lines) do
        if line:match("^name") then
            project_name = line:gsub("name:", "") -- remove key
            project_name = project_name:gsub("%s+", "") -- trim
            break
        end
    end
end

-- returns imports, startline, endline
local function read_imports()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local startline
    local endline

    local imports = {}
    for linenumber, line in ipairs(lines) do
        line = line:gsub("^%s+", "")
        islast = linenumber == #lines

        if line:match("^import") or line:match("^export") or line:match("^part") then
            table.insert(imports, line)

            if startline == nil then startline = linenumber end
            if islast then
                endline = linenumber
                break
            end
        elseif islast or
            (not isblank(line) and not line:match("^library") and
                not line:match("^//")) then

            if startline ~= nil then
                if linenumber > 0 and isblank(lines[linenumber]) and not islast then
                    endline = linenumber - 2
                else
                    endline = linenumber - 1
                end
            end
            break
        end
    end

    return imports, startline, endline
end

-- returns 2 tables: raw imports, sorted imports
local function get_imports(values)
    if not values or #values == 0 then return '' end

    local dart_imports = {}
    local package_imports = {}
    local package_local_imports = {}
    local relative_imports = {}
    local part_statements = {}
    local exports = {}

    for _, value in pairs(values) do
        if value:match("^export") then
            table.insert(exports, value)
        elseif value:match("^part") then
            table.insert(part_statements, value)
        elseif value:match("dart:") then
            table.insert(dart_imports, value)
        elseif project_name ~= nil and value:match("package:" .. project_name) then
            table.insert(package_local_imports, value)
        elseif value:match("package:") then
            table.insert(package_imports, value)
        else
            table.insert(relative_imports, value)
        end
    end

    local imports = {}

    local function add_imports(values)
        table.sort(values)
        for i, value in ipairs(values) do
            table.insert(imports, value)

            local islast = i == #values
            if islast then table.insert(imports, "") end
        end
    end

    add_imports(dart_imports)
    add_imports(package_imports)
    add_imports(package_local_imports)
    add_imports(relative_imports)
    add_imports(exports)
    add_imports(part_statements)

    return values, imports
end

function sort_dart_imports()
    if project_name == nil then find_project_name() end

    local imports, startline, endline = read_imports()
    if imports == nil or #imports == 0 then return end
    local raw_imports, sorted_imports = get_imports(imports)
    if sorted_imports[#sorted_imports - 1] == "" then
        sorted_imports[#sorted_imports - 1] = nil
    end

    -- check whether or not imports are already sorted
    if table.concat(raw_imports) ~= table.concat(sorted_imports) then
        -- replace old imports with organized ones 
        vim.api.nvim_buf_set_lines(0, startline - 1, endline, false,
                                   sorted_imports)
    end

end
