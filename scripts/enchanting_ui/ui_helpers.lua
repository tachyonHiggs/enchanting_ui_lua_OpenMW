local UI = require('openmw.ui')
local auxUi = require("openmw_aux.ui")
local async = require('openmw.async')
local Util = require('openmw.util')
local v2 = Util.vector2
local I = require('openmw.interfaces')
local core = require('openmw.core')

local templates = require("scripts.enchanting_ui.templates")
local enchanter = require("scripts.enchanting_ui.enchanter")

local helper = {}

local on_item_clicked = nil
local on_soul_clicked = nil
local on_magic_effect_clicked = nil
local on_effect_clicked = nil

function helper.set_on_item_clicked(callback)
    on_item_clicked = callback
end
function helper.set_on_soul_clicked(callback)
    on_soul_clicked = callback
end
function helper.set_on_magic_effect_clicked(callback)
    on_magic_effect_clicked = callback
end
function helper.set_on_effect_clicked(callback)
    on_effect_clicked = callback
end


-- ITEMS

local function create_enchantable_item(id, icon)
    return {
        name = id,
        type = UI.TYPE.Image,
        -- template = I.MWUI.templates.boxSolid,
        props = {
            resource = UI.texture({
                path = icon,
            }),
            alpha = 1,
            size = v2(50,50),
        },
        events = {
            mouseClick = async:callback(function()
                if on_item_clicked then
                    on_item_clicked(id, icon)
                end
            end),
            -- mouseDoubleClick = async:callback(function()
            --     on_item_clicked(id)
            -- end)
        }
    }
end

function helper.make_enchantable_items_list()
    local valid_items = {}

    local items = enchanter.get_enchantable_inventory_items()
    for __, item in pairs(items) do
        table.insert(valid_items, create_enchantable_item(item[1], item[2]))
    end

    return valid_items or {}
end


-- SOULS

local function create_soul(id, value, icon)
    return {
        name = id,
        type = UI.TYPE.Image,
        -- template = I.MWUI.templates.boxSolid,
        props = {
            resource = UI.texture({
                path = icon,
            }),
            alpha = 1,
            size = v2(50,50),
        },
        events = {
            mouseClick = async:callback(function()
                if on_soul_clicked then
                    on_soul_clicked(id, value, icon)
                end
            end),
            -- mouseDoubleClick = async:callback(function()
            --     on_item_clicked(id)
            -- end)
        }
    }
end

function helper.make_souls_list()
    local valid_items = {}

    local items = enchanter.get_inventory_souls()
    for __, item in pairs(items) do
        table.insert(valid_items, create_soul(item[1], item[2], item[3]))
    end

    return valid_items or {}
end

-- MAGIC EFFECTS

local function create_magic_effect_item(id, name)
    return 
    {
        name = id,
        type = UI.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = name,
            textSize = 20,
        },
        events = {
            mouseClick = async:callback(function()
                if on_magic_effect_clicked then
                    on_magic_effect_clicked(id)
                end
            end)
        }
    }
end

function helper.make_magic_effects_list()
    local known_magic_effects = enchanter.get_known_magic_effects()
    if known_magic_effects == nil then
        print("!! ERROR magic_effects_list is NIL")
        return
    end
    local items = {}

    for id, name in pairs(known_magic_effects) do
        table.insert(items, create_magic_effect_item(id, name)) -- TODO: on click fnc
    end

    return items or {} -- return the list or just an empty one
end

-- EFFECTS

function helper.create_effect_item(effect, on_effect_clicked)
    print("create_effect_item")

    local icon_element = {
        name = "icon",
        type = UI.TYPE.Image,
        template = I.MWUI.templates.borders,
        props = {
            resource = UI.texture({
                path = core.magic.effects.records[effect.id].icon
            }),
            alpha = 1,
            size = v2(20,20),
        },
    }

    local parts = { effect.effect.name }

    if effect.magnitudeMax > 0 then
        table.insert(parts, ("%d to %d"):format(effect.magnitudeMin, effect.magnitudeMax))
    end

    if effect.duration > 0 then
        table.insert(parts, ("for %d sec"):format(effect.duration))
    end

    if effect.area > 0 then
        table.insert(parts, ("in %d ft"):format(effect.area))
    end

    if effect.range == core.magic.RANGE.Self then
        table.insert(parts, "on Self")
    elseif effect.range == core.magic.RANGE.Target then
        table.insert(parts, "on Target")
    else 
        table.insert(parts, "on Touch")
    end

    local text = table.concat(parts, " ")
    print(effect.range)
    
    local text_element = {
        name = effect.id,
        type = UI.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = text,
            textSize = 20,
        },
    }

    return 
    {
        name = effect.effect.name.."_effect_item",
        type = UI.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = UI.ALIGNMENT.Start,
            align = UI.ALIGNMENT.Start,
        },
        content = UI.content {
            icon_element,
            text_element,
        },
        events = {
            mouseClick = async:callback(function()
                if on_effect_clicked then
                    on_effect_clicked(effect.id)
                end
            end)
        }
    }
end

return helper