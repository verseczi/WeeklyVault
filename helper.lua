function RGBtoHex(colour)
    local r = colour[1] or 0
    local g = colour[2] or 0
    local b = colour[3] or 0
    -- Accept both normalized (0..1) and 0..255 color values
    if r <= 1 and g <= 1 and b <= 1 then
        r = math.floor(r * 255 + 0.5)
        g = math.floor(g * 255 + 0.5)
        b = math.floor(b * 255 + 0.5)
    else
        r = math.floor(r + 0.5)
        g = math.floor(g + 0.5)
        b = math.floor(b + 0.5)
    end
    r = math.max(0, math.min(255, r))
    g = math.max(0, math.min(255, g))
    b = math.max(0, math.min(255, b))
    return string.format("ff%02x%02x%02x", r, g, b)
end

function ColorByCompleted(level, completed, UnTimedRunColor, TimedRunColor)
    local failColor = RGBtoHex(UnTimedRunColor)
    local passColor = RGBtoHex(TimedRunColor)

    local colorOutput = "|c" .. (completed and passColor or failColor) .. "+" .. level .. "|r"
    return colorOutput
end

-- WeakAuras2's functions, copied here to avoid dependency on the whole library
function ComposeSorts(...)
    -- accepts vararg of sort funcs
    -- returns new sort func that combines the functions passed in
    -- order of functions passed in determines their priority in new sort
    -- returns nil if all functions return nil,
    -- so that it can be composed or inverted without trouble
    local sorts = {}
    for i = 1, select("#", ...) do
        local sortFunc = select(i, ...)
        if type(sortFunc) == "function" then
            tinsert(sorts, sortFunc)
        end
    end
    return function(a, b)
        for _, sortFunc in ipairs(sorts) do
            local result = sortFunc(a, b)
            if result ~= nil then
                return result
            end
        end
        return nil
    end
end

function SortDescending(path)
    return InvertSort(SortAscending(path))
end

function InvertSort(sortFunc)
    -- takes a comparator and returns the "inverse"
    -- i.e. when sortFunc returns true/false, inverseSortFunc returns false/true
    -- nils are preserved to ensure that inverseSortFunc composes well
    if type(sortFunc) ~= "function" then
        error("InvertSort requires a function to invert.")
    else
        return function(...)
            local result = sortFunc(...)
            if result == nil then return nil end
            return not result
        end
    end
end

function SortNilLast(a, b)
    -- sorts nil values to the end
    -- only returns nil if both values are non-nil
    -- Useful as a high priority sorter in a composition,
    -- to ensure that children with missing data
    -- don't ever sit in the middle of a row
    -- and interrupt the sorting algorithm
    if a == nil and b == nil then
        -- guarantee stability in the nil region
        return false
    elseif a == nil then
        return false
    elseif b == nil then
        return true
    else
        return nil
    end
end

SortNilFirst = InvertSort(SortNilLast)

function SortGreaterLast(a, b)
    -- sorts values in ascending order
    -- values of disparate types are sorted according to the value of type(value)
    -- which is a bit weird but at least guarantees a stable sort
    -- can only sort comparable values (i.e. numbers and strings)
    -- no support currently for tables with __lt metamethods
    if a == b then
        return nil
    end
    if type(a) ~= type(b) then
        return type(a) > type(b)
    end
    if type(a) == "number" then
        if abs(b - a) < 0.001 then
            return nil
        else
            return a < b
        end
    elseif type(a) == "string" then
        return a < b
    else
        return nil
    end
end

SortGreaterFirst = InvertSort(SortGreaterLast)

function SortRegionData(path, sortFunc)
    -- takes an array-like table, and a function that takes 2 values and returns true/false/nil
    -- creates function that accesses the value indicated by path, and compares using sortFunc
    if type(path) ~= "table" then
        path = {}
    end
    if type(sortFunc) ~= "function" then
        -- if sortFunc not provided, compare by default as "<"
        sortFunc = SortGreaterLast
    end
    return function(a, b)
        local aValue, bValue = a, b
        for _, key in ipairs(path) do
            if type(aValue) ~= "table" then return nil end
            if type(bValue) ~= "table" then return nil end
            aValue, bValue = aValue[key], bValue[key]
        end
        return sortFunc(aValue, bValue)
    end
end

function SortAscending(path)
    return SortRegionData(path, ComposeSorts(SortNilFirst, SortGreaterLast))
end
