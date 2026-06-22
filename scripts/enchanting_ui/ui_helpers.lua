local UI = require('openmw.ui')
local auxUi = require("openmw_aux.ui")
local async = require('openmw.async')
local Util = require('openmw.util')
local v2 = Util.vector2
local I = require('openmw.interfaces')

local templates = require("scripts.enchanting_ui.templates")
local enchanter = require("scripts.enchanting_ui.enchanter")

local helper = {}

local on_item_clicked = nil
local on_soul_clicked = nil
function helper.set_on_item_clicked(callback)
    on_item_clicked = callback
end
function helper.set_on_soul_clicked(callback)
    on_soul_clicked = callback
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

local function create_magic_effect_item(id, name, onMouseClick)
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
            mouseClick = async:callback(onMouseClick)
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
        table.insert(items, create_magic_effect_item(id, name, function() end)) -- TODO: on click fnc
    end

    return items or {} -- return the list or just an empty one
end

return helper