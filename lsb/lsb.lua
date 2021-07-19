_addon.name = 'LSB Helpers'
_addon.author = 'zach2good'
_addon.version = '1.0.0.0'
_addon.command = 'lsb'

require('luau')
local texts = require('texts')

local defaultSettings = {}
defaultSettings.display = {}
defaultSettings.display.pos = {}
defaultSettings.display.pos.x = 500
defaultSettings.display.pos.y = 100

defaultSettings.display.bg = {}
defaultSettings.display.bg.alpha = 200
defaultSettings.display.bg.red = 0
defaultSettings.display.bg.green = 0
defaultSettings.display.bg.blue = 0

defaultSettings.display.text = {}
defaultSettings.display.text.size = 12
defaultSettings.display.text.font = 'Courier New'
defaultSettings.display.text.fonts = {}
defaultSettings.display.text.alpha = 255
defaultSettings.display.text.red = 255
defaultSettings.display.text.green = 255
defaultSettings.display.text.blue = 255

--------------------------------------------------------
-- Utils
--------------------------------------------------------
function string.fromhex(str)
    if str == nil then return "" end
    return (str:gsub('..', function (cc)
        return string.char(tonumber(cc, 16))
    end))
end

function string.tohex(str)
    if str == nil then return "" end
    return (str:gsub('.', function (c)
        return string.format('%02X ', string.byte(c))
    end))
end

local function getTableKeys(tab)
    local keyset = {}
    for k,v in pairs(tab) do
        keyset[#keyset + 1] = k
    end
    return keyset
end

local dumpTableToString
dumpTableToString = function(table, depth)
    if table == nil then table = {} end
    if depth == nil then depth = 0 end

    local outputString = ""
    for _, key in ipairs(getTableKeys(table)) do
        local value = table[key]
        if type(value) == "table" then
            local keyStr = tostring(key)
            local indent = ""
            for i = 1, depth do indent = indent .. "    " end
            outputString = outputString .. indent .. keyStr .. " : {\n"
            outputString = outputString .. dumpTableToString(value, depth + 1)
            outputString = outputString .. indent .. "}\n"
        else
            local keyStr = tostring(key)
            local valueStr = tostring(value)
            local indent = ""
            for i = 1, depth do indent = indent .. "    " end
            outputString = outputString .. indent .. keyStr .. " : " .. valueStr .. "\n"
        end
    end
    return outputString
end

--------------------------------------------------------
-- Globals
--------------------------------------------------------
local targInfo = texts.new(default_settings.display, default_settings)
targInfo:pos(200, 200)

--------------------------------------------------------
-- Functions
--------------------------------------------------------
local function update()
    -- Target
    local player = windower.ffxi.get_player()
    local targIndex = player['target_index']
    if targIndex then
        local targ = windower.ffxi.get_mob_by_index(targIndex)
        targInfo:text("TARGET:\n" .. dumpTableToString(targ))
        targInfo:show()
    else
        targInfo:hide()
    end
end

--------------------------------------------------------
-- Windower Hooks
--------------------------------------------------------
windower.register_event('load', function()
    update:loop(0.2)
end)
