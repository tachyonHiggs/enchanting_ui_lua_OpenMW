local UI = require('openmw.ui')
local I = require('openmw.interfaces')
local Util = require('openmw.util')
local v2 = Util.vector2
local auxUi = require("openmw_aux.ui")
local ambient = require('openmw.ambient')
local async = require('openmw.async')
local core = require('openmw.core')
local storage = require('openmw.storage')

local templates = require("scripts.enchanting_ui.templates")
local enchanter = require("scripts.enchanting_ui.enchanter")
local elements = require("scripts.enchanting_ui.ui.elements")
local effect_ui = require("scripts.enchanting_ui.ui.effect_ui")


local add_effect_ui = {}

add_effect_ui.on_magic_effect_clicked = function(id)

    print("On magic effect clicked: ", id)
    
    ambient.playSound('menu click')
    if #enchanter.effects_with_params >= 8 then
        print("Max effects added, returning!")
        UI.showMessage("Max number of effects reached")
        return
    end

    enchanter.reset_effect_to_add()
    enchanter.effect_to_add.id = id
    enchanter.effect_to_modify = false

    print("CREATING MAGIC EFFECT ADD UI")

    local props = {
        relativeSize = v2(1, 1),
        relativePosition = v2(0.5, 0.5),
        anchor = v2(0.5, 0.5),
        visible = true,
    }
    local effect_ui_add = effect_ui.new(enchanter.effect_to_modify, enchanter.effect_to_add)
    elements.effects_root = templates.window.new("effects_window", UI.TYPE.Container, I.MWUI.templates.boxSolid, props, {effect_ui_add:create()})
    elements.effects_root:create()
    elements.add_effects_root:destroy()
end

local function create_magic_effect_item(id, name)
    -- TODO: add more like magic school info
    local record = core.magic.effects.records[id]
    local icon = record.icon
    local school = record.school

    local icon_element = {
        name = "icon",
        type = UI.TYPE.Image,
        template = I.MWUI.templates.borders,
        props = {
            resource = UI.texture({
                path = icon
            }),
            alpha = 1,
            size = v2(elements.add_effects_list_sizes[1],elements.add_effects_list_sizes[1]),
        },
    }

    local name_element = {
        name = id,
        type = UI.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = name,
            textSize = elements.text_size,
            autoSize = false,
            size = v2(elements.add_effects_list_sizes[2], elements.text_size)
        },
    }

    local school_element = {
        name = "school",
        type = UI.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = school:sub(1, 1):upper() .. school:sub(2),
            textSize = elements.text_size,
            autoSize = false,
            size = v2(elements.add_effects_list_sizes[3], elements.text_size)
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
            index = 1,
            info = {icon, name, school}
        },
        content = UI.content {
            icon_element,
            templates.padding(elements.padding_size, elements.padding_size),
            name_element,
            templates.padding(elements.padding_size, elements.padding_size),
            school_element,
        },
        events = {
            mouseClick = async:callback(function()
                add_effect_ui.on_magic_effect_clicked(id)
            end)
        },
    }

end

function add_effect_ui.make_magic_effects_list()
    local known_magic_effects = enchanter.get_known_magic_effects()
    if known_magic_effects == nil then
        print("!! ERROR magic_effects_list is NIL")
        return
    end
    local items = {}

    for id, name in pairs(known_magic_effects) do
        table.insert(items, create_magic_effect_item(id, name))
    end

    return items or {} -- return the list or just an empty one
end

function add_effect_ui.show_add_effect_list()
    print("add_effect_ui.show_add_effect_list")

    ambient.playSound('menu click')

    -- Create list
    local column_sorting_names = {column_names=elements.add_effects_list_column_names, column_widths=elements.add_effects_list_sizes, enable_column_sortings=elements.add_effects_list_sorting}
    elements.magic_effects_list = templates.list.new("Magic Effects", v2(elements.add_effects_size[1], elements.add_effects_size[2]), add_effect_ui.update, add_effect_ui.make_magic_effects_list, column_sorting_names, nil, true)
    
    -- Change and update UI
    elements.root:hide()
    local props = {
        relativeSize = v2(1, 1),
        relativePosition = v2(0.5, 0.5),
        anchor = v2(0.5, 0.5),
        visible = true,
    }
    elements.add_effects_root = templates.window.new("magic_effects_window", UI.TYPE.Container, I.MWUI.templates.boxSolid, props, {elements.magic_effects_list:create()})
    elements.add_effects_root:create()
end

function add_effect_ui.update()
    if elements.add_effects_root.created then
        elements.add_effects_root:update()
        elements.magic_effects_list:set_input_text()
    end
end

return add_effect_ui