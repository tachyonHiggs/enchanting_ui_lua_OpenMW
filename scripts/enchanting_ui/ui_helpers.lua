local UI = require('openmw.ui')
local auxUi = require("openmw_aux.ui")
local async = require('openmw.async')
local Util = require('openmw.util')
local v2 = Util.vector2
local I = require('openmw.interfaces')
local core = require('openmw.core')
local types = require('openmw.types')

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

local function create_enchantable_item(id, icon, type, name, enchant_pts)
    print("create_effect_item")

    local icon_element = {
        name = "icon",
        type = UI.TYPE.Image,
        template = I.MWUI.templates.borders,
        props = {
            resource = UI.texture({
                path = icon
            }),
            alpha = 1,
            size = v2(50,50),
        },
    }

    local type_text
    if type == types.Weapon then
        type_text = "Weapon"
    elseif type == types.Armor then
        type_text = "Armor"
    else
        type_text = "Clothing"
    end

    local type_element = {
        name = "type",
        type = UI.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = type_text,
            textSize = 20,
            size = v2(80,20),
            autoSize = false
        },
    }

    local text_element = {
        name = "name",
        type = UI.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = name,
            textSize = 20,
            size = v2(200,20),
            autoSize = false
        },
    }

    local enchant_points_element = {
        name = "enchant_points",
        type = UI.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = tostring(enchant_pts),
            textSize = 20,
            size = v2(50,20),
            autoSize = false
        },
    }

    return 
    {
        name = id,
        type = UI.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = UI.ALIGNMENT.Start,
            align = UI.ALIGNMENT.Start,
        },
        content = UI.content {
            icon_element,
            templates.padding(20, 20),
            text_element,
            templates.padding(20, 20),
            type_element,
            templates.padding(20, 20),
            enchant_points_element,
        },
        events = {
            mouseClick = async:callback(function()
                if on_item_clicked then
                    on_item_clicked(id, icon, enchant_pts, type_text)
                end
            end)
        }
    }
end

function helper.make_enchantable_items_list()
    local valid_items = {}

    local items = enchanter.get_enchantable_inventory_items()
    for __, item in pairs(items) do
        table.insert(valid_items, create_enchantable_item(item[1], item[2], item[3], item[4], item[5]))
    end

    return valid_items or {}
end


-- SOULS

local function create_soul(id, value, icon, name, soul_name)
    local icon_element = {
        name = "icon",
        type = UI.TYPE.Image,
        template = I.MWUI.templates.borders,
        props = {
            resource = UI.texture({
                path = icon
            }),
            alpha = 1,
            size = v2(50,50),
        },
    }
    local name = {
        name = "name",
        type = UI.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = name,
            textSize = 20,
            size = v2(150,20),
            autoSize = false
        },
    }

    local soul_value = {
        name = "value",
        type = UI.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = tostring(value),
            textSize = 20,
            size = v2(80,20),
            autoSize = false
        },
    }

    local soul_name = {
        name = "soul_name",
        type = UI.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = soul_name,
            textSize = 20,
            size = v2(200,20),
            autoSize = false
        },
    }

    return {
        name = id,
        type = UI.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = UI.ALIGNMENT.Start,
            align = UI.ALIGNMENT.Start,
            size = v2(600, 20)
        },
        content = UI.content {
            icon_element,
            templates.padding(20, 20),
            name,
            templates.padding(20, 20),
            soul_value,
            templates.padding(20, 20),
            soul_name,
        },
        events = {
            mouseClick = async:callback(function()
                if on_soul_clicked then
                    print(icon)
                    on_soul_clicked(id, value, icon)
                end
            end)
        }
    }
end

function helper.make_souls_list()
    local valid_items = {}

    local items = enchanter.get_inventory_souls()
    for __, item in pairs(items) do
        table.insert(valid_items, create_soul(item[1], item[2], item[3], item[4], item[5]))
    end

    return valid_items or {}
end

-- MAGIC EFFECTS



return helper