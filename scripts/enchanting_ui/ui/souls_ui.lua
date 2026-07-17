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


local souls_ui = {}


local function on_soul_clicked(id, object, value, icon)

    enchanter.soul.id = id
    enchanter.soul.object = object
    enchanter.soul.icon = icon
    enchanter.soul.charge = value
    elements.stats_charge:set_text(tostring(enchanter.enchantment.effective_cost).. "/".. tostring(enchanter.soul.charge ))
    
    print("click on soul: ", id)
    print("at icon: ", icon)
    print("with a soul value of: ", value)
    elements.soul_input:set_image(icon)
    elements.enable_ui(elements.root)

    auxUi.deepDestroy(elements.souls_root)
    elements.souls_root:update()

end

function souls_ui.show_soul_list()

    print("CREATING SOUL UI")
    elements.disable_ui(elements.root)

    elements.souls_root = UI.create{
        name = "souls_list",
        layer = "Windows",
        template = I.MWUI.templates.boxSolid,
        props = {
            relativeSize = v2(1, 1),
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
        },
        content = UI.content {
            souls_ui.souls_list:create()
        }
    }

    elements.souls_root:update()
end

local function create_soul(id, object, value, icon, name, soul_name)
    local icon_element = {
        name = "icon",
        type = UI.TYPE.Image,
        template = I.MWUI.templates.borders,
        props = {
            resource = UI.texture({
                path = icon
            }),
            alpha = 1,
            size = v2(elements.souls_list_sizes[1],50),
        },
    }
    local name_element = {
        name = "name",
        type = UI.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = name,
            textSize = elements.text_size,
            size = v2(elements.souls_list_sizes[2],elements.text_size),
            autoSize = false
        },
    }

    local soul_value = {
        name = "value",
        type = UI.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = tostring(value),
            textSize = elements.text_size,
            size = v2(elements.souls_list_sizes[3],elements.text_size),
            autoSize = false
        },
    }

    local soul_name_element = {
        name = "soul_name",
        type = UI.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = soul_name,
            textSize = elements.text_size,
            size = v2(elements.souls_list_sizes[4],elements.text_size),
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
            size = v2(elements.souls_list_sizes[5], elements.text_size),
            autoSize = false
        },
    }

    return {
        name = id,
        type = UI.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = UI.ALIGNMENT.Center,
            align = UI.ALIGNMENT.Start,
            size = v2(600, elements.text_size)
        },
        userData = {
            -- Used for list sorting!
            icon, name, value, soul_name, object.count
        },
        content = UI.content {
            icon_element,
            templates.padding(elements.padding_size, elements.padding_size),
            name_element,
            templates.padding(elements.padding_size, elements.padding_size),
            soul_value,
            templates.padding(elements.padding_size, elements.padding_size),
            soul_name_element,
            templates.padding(elements.padding_size, elements.padding_size),
            count_element,
        },
        events = {
            mouseClick = async:callback(function()
                on_soul_clicked(id, object, value, icon)
            end)
        }
    }
end

function souls_ui.make_souls_list()
    print("make_souls_list")
    local valid_items = {}

    local items = enchanter.get_inventory_souls()
    for __, item in pairs(items) do
        table.insert(valid_items, create_soul(item[1], item[2], item[3], item[4], item[5], item[6]))
    end

    return valid_items or {}
end

function souls_ui.update()
    if elements.souls_root.layout then
        elements.souls_root:update()
    end
end

souls_ui.souls_list = templates.list.new("Souls", v2(elements.root_size[1], elements.root_size[2]), souls_ui.update, souls_ui.make_souls_list, {column_names=elements.souls_list_column_names, column_widths=elements.souls_list_sizes, enable_column_sortings=elements.souls_list_sorting})
elements.souls_list = souls_ui.souls_list

elements.soul_input = templates.text_image.new("Soul", v2(75,75), 10, souls_ui.show_soul_list)

return souls_ui