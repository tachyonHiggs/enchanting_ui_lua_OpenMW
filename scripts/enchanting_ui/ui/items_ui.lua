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

    enchanter.reset_enchantment()
    enchanter.reset_item()

    elements.effects:clear()

    enchanter.item.id = id
    enchanter.item.object = object
    enchanter.item.icon = icon
    enchanter.item.type = type_text
    enchanter.item.enchantment_capacity = enchant_pts

    print("click on item: ", id)
    print("Icon: ", icon)
    print("Type: ", type_text)
    print("enchant_pts: ", string.format("%.1f", enchant_pts))
    elements.item_input:set_image(icon)
    
    elements.cast_type_btn:set_text(enchanter.toggle_cast_type())

    elements.stats_enchantment:set_text(tostring(enchanter.enchantment.base_cost).."/"..string.format("%.1f", enchant_pts))
    elements.stats_charge:set_text(tostring(enchanter.enchantment.effective_cost) .. "/" .. tostring(enchanter.soul.charge))

    elements.enable_ui(elements.root)
    elements.root:update()

    auxUi.deepDestroy(elements.items_root)
    elements.items_root:update()
end

local function create_enchantable_item(id, object, icon, type, name, enchant_pts)
    print("create_enchantable_item")

    local icon_element = {
        name = "icon",
        type = UI.TYPE.Image,
        template = I.MWUI.templates.borders,
        props = {
            resource = UI.texture({
                path = icon
            }),
            alpha = 1,
            size = v2(elements.items_list_sizes[1],50),
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

    local text_element = {
        name = "name",
        type = UI.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = name,
            textSize = elements.text_size,
            size = v2(elements.items_list_sizes[2],elements.text_size),
            autoSize = false
        },
    }

    local enchant_points_element = {
        name = "enchant_points",
        type = UI.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = string.format("%.1f", enchant_pts),
            textSize = elements.text_size,
            size = v2(elements.items_list_sizes[3],elements.text_size),
            autoSize = false
        },
    }

    local type_element = {
        name = "type",
        type = UI.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = type_text,
            textSize = elements.text_size,
            size = v2(elements.items_list_sizes[4],elements.text_size),
            autoSize = false
        },
    }

    local count_element = {
        name = "count",
        type = UI.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = tostring(object.count),
            textSize = elements.text_size,
            size = v2(elements.items_list_sizes[5],elements.text_size),
            autoSize = false
        },
    }

    return 
    {
        name = id,
        type = UI.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = UI.ALIGNMENT.Center,
            align = UI.ALIGNMENT.Start,
        },
        userData = {
            -- Used for list sorting!
            icon, name, enchant_pts, type_text, object.count
        },
        content = UI.content {
            icon_element,
            templates.padding(elements.padding_size, elements.padding_size),
            text_element,
            templates.padding(elements.padding_size, elements.padding_size),
            enchant_points_element,
            templates.padding(elements.padding_size, elements.padding_size),
            type_element,
            templates.padding(elements.padding_size, elements.padding_size),
            count_element
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
    elements.disable_ui(elements.root)
    elements.items_root = UI.create{
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
    elements.items_root:update()
end

function items_ui.update()
    if elements.items_root.layout then
        elements.items_root:update()
    end
end

elements.items_list = templates.list.new("Items", v2(elements.root_size[1], elements.root_size[2]), items_ui.update, items_ui.make_enchantable_items_list, {column_names=elements.items_list_column_names, column_widths=elements.items_list_sizes, enable_column_sortings=elements.items_list_sorting})

elements.item_input = templates.text_image.new("Item", v2(75,75), 10, items_ui.show_item_list)

return items_ui