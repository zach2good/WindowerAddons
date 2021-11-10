_addon.name = 'attackdelay'
_addon.author = 'zach2good'
_addon.version = '0.1'
_addon.commands = {'attackdelay'}

local packets = require('packets')
local texts = require('texts')

local default_settings = {}
default_settings.display = {}
default_settings.display.pos = {}
default_settings.display.pos.x = 500
default_settings.display.pos.y = 100

default_settings.display.bg = {}
default_settings.display.bg.alpha = 200
default_settings.display.bg.red = 0
default_settings.display.bg.green = 0
default_settings.display.bg.blue = 0

default_settings.display.text = {}
default_settings.display.text.size = 12
default_settings.display.text.font = 'Courier New'
default_settings.display.text.fonts = {}
default_settings.display.text.alpha = 255
default_settings.display.text.red = 255
default_settings.display.text.green = 255
default_settings.display.text.blue = 255

local NUMBER_OF_ATTACKS = 50
local attack_lookup = {}
local hud = texts.new(default_settings.display, default_settings)

hud:pos(400, 100)

-- https://ffxiclopedia.fandom.com/wiki/Delay
-- Melee Delay
-- Every 60 delay for a melee weapon is equal to 1 real time second, and it is determined by the weapon used (except for Hand to Hand).
-- -> Time in seconds * 60 = Melee Delay

function display()
    -- Build string
    local hud_string = "Attack Delay\n"
    hud_string = hud_string .. "=============================="
    for idx, entry in pairs(attack_lookup) do
        local id = idx
        local name = entry["name"]
        local time = entry["average_time"]
        local num_samples = #entry["times"]
        hud_string = hud_string .. string.format("\n%s(%d): time = %.3fs / delay = %d (n = %d)", name, id, time, time * 60, num_samples)
    end

    -- Show string
    hud:text(hud_string)
    hud:show()
end

windower.register_event('incoming chunk', function(id, data)
    local player = windower.ffxi.get_player()
    local player_mob = windower.ffxi.get_mob_by_id(player.id)

    if id == 0x028 then
        local action_message = packets.parse('incoming', data)
        if action_message["Category"] == 1 then -- Melee
            local attacker_id = action_message["Actor"]
            local attacker_name = windower.ffxi.get_mob_by_id(attacker_id).name

            local target_id = action_message["Target 1 ID"]
            local target_name = windower.ffxi.get_mob_by_id(target_id).name

            if player.id == target_id then
                -- attacker has attacked player
                local time_now = os.clock() -- Time in seconds, with ms accuracy
                local attacker_entry = attack_lookup[attacker_id]

                -- Create list for attacker
                if attacker_entry == nil then
                    attack_lookup[attacker_id] = {}
                    attack_lookup[attacker_id]["attacks"] = {}
                    attack_lookup[attacker_id]["times"] = {}
                    attack_lookup[attacker_id]["name"] = attacker_name
                end

                -- Insert new entry
                local new_entry = {}
                new_entry["name"] = attacker_name
                new_entry["time"] = time_now
                table.insert(attack_lookup[attacker_id]["attacks"], new_entry)

                -- If less than 2 entries to compare, bail out
                local attacks_length = #attack_lookup[attacker_id]["attacks"]
                if attacks_length < 2 then
                    return
                end

                -- Compare
                local last_attack_entry = attacker_entry["attacks"][attacks_length - 1]
                local time_between_attacks = new_entry["time"] - last_attack_entry["time"]

                -- Figure out average
                table.insert(attack_lookup[attacker_id]["times"], time_between_attacks)
                local times_length = #attack_lookup[attacker_id]["times"]
                if times_length > NUMBER_OF_ATTACKS then
                    table.remove(attack_lookup[attacker_id]["times"], 1)
                    times_length = #attack_lookup[attacker_id]["times"]
                end

                -- Sum
                local average_time = 0
                for idx = 1, times_length do
                    average_time = average_time + attack_lookup[attacker_id]["times"][idx]
                end

                -- Average
                average_time = average_time / times_length
                attack_lookup[attacker_id]["average_time"] = average_time

                -- Display
                display()
            end
        end
    end
end)
