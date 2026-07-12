local UI = require('openmw.ui')
local I = require('openmw.interfaces')
local Util = require('openmw.util')
local v2 = Util.vector2
local auxUi = require("openmw_aux.ui")
local ambient = require('openmw.ambient')
local self = require('openmw.self')
local async = require('openmw.async')
local core = require('openmw.core')
local types = require('openmw.types')

local templates = require("scripts.enchanting_ui.templates")
local enchanter = require("scripts.enchanting_ui.enchanter")
local elements = require("scripts.enchanting_ui.ui.elements")


local items_ui = {}


local function on_item_clicked(id, object, icon, enchant_pts, type_text)

    enchanter.item.id = id
    enchanter.item.object = object
    enchanter.item.icon = icon
    enchanter.item.type = type_text
    enchanter.item.enchantment_capacity = enchant_pts
    print("click on item: ", id)
    print("Icon: ", icon)
    print("Type: ", type_text)
    print("enchant_pts: ", tostring(enchant_pts))
    elements.item_input:set_image(icon)
    
    elements.stats_enchantment:set_text(tostring(enchanter.enchantment.cost).."/"..tostring(enchanter.item.enchantment_capacity))

    -- TODo: this is just toggle cast type function
    enchanter.enchantment.type = 0
    enchanter.soul.charge = 0
    enchanter.enchantment.cost = 0
    enchanter.effects_with_params = {}
    enchanter.enchantment.isAutocalc = 0

    elements.effects:clear()
    
    elements.cast_type_btn.content[2].props.text = enchanter.toggle_cast_type()
    -- ENd todo

    enable_ui(elements.root)

    auxUi.deepDestroy(items_ui.ui)
    items_ui.ui:update()
end

local function create_enchantable_item(id, object, icon, type, name, enchant_pts)
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
    elseif type == types.Clothing then
        type_text = "Clothing"
    else 
        type_text = "Book"
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
                on_item_clicked(id, object, icon, enchant_pts, type_text)
            end)
        }
    }
end

function items_ui.make_enchantable_items_list()
    print("make_enchantable_items_list")
    local valid_items = {}

    local items = enchanter.get_enchantable_inventory_items()
    for __, item in pairs(items) do
        table.insert(valid_items, create_enchantable_item(item[1], item[2], item[3], item[4], item[5], item[6]))
    end

    return valid_items or {}
end

function items_ui.show_item_list()
    disable_ui(elements.root)
    items_ui.ui = UI.create{
        name = "item_list",
        layer = "Windows",
        template = I.MWUI.templates.boxSolid,
        props = {
            relativeSize = v2(1, 1),
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
        },
        content = UI.content {
            elements.items_list:create()
        }
    }
end

elements.items_list = templates.list.new("Items", v2(600, 500), items_ui.make_enchantable_items_list)

elements.item_input = templates.text_image.new("Item", v2(75,75), 10, items_ui.show_item_list)

return items_ui