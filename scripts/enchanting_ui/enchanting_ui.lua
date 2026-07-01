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

local ui_helpers = require("scripts.enchanting_ui.ui_helpers")

-- TODO: tooltips hovering

--
local enchanting_ui = {}
local header = {element = {}}
local footer = {element = {}}
local main_content = {element = {}}

enchanting_ui.create_ui = function() 

    print("create_ui")

    enchanter.reset()

    enchanting_ui.root = UI.create{
        name = "root",
        layer = "Windows",
        type = UI.TYPE.Widget,
        template = nil,
        props = {
            size = v2(600, 500),
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
        },
        content = UI.content { 
            templates.make_border(v2(600, 500)),
            {
                name = "root_padding",
                template = I.MWUI.templates.padding,
                props = {
                    anchor = v2(0.5, 0.5),
                    relativePosition = v2(0.5, 0.5),
                },
                content = UI.content { 
                    {
                        name = "flex_V1",
                        type = UI.TYPE.Flex,
                        props = {
                            horizontal = false,
                            arrange = UI.ALIGNMENT.Start,
                            align = UI.ALIGNMENT.Start,
                        },
                        content = UI.content {
                            header.element,
                            main_content.element,
                            footer.element,
                        }
                    }
                }
           }
        }
    }
    
    print("Created UI")
end

-- header

-- header input list fncs
enchanting_ui.soul_list = templates.list.new("Souls", v2(600, 500), ui_helpers.make_souls_list)
enchanting_ui.items_list = templates.list.new("Items", v2(600, 500), ui_helpers.make_enchantable_items_list)

local function on_item_clicked(id, icon, enchant_pts, type_text)

    enchanter.item.id = id
    enchanter.item.icon = icon
    enchanter.item.type = type_text
    enchanter.item.enchantment_capacity = enchant_pts
    print("click on item: ", id)
    print("Icon: ", icon)
    print("enchant_pts: ", tostring(enchant_pts))
    enchanting_ui.item_input.content[3].props.resource = UI.texture({
        path = icon
    })
    enchanting_ui.stats_enchantment:set_text("0/"..tostring(enchant_pts))
    enchanting_ui.root:update()

    auxUi.deepDestroy(enchanting_ui.item_list)
    enchanting_ui.item_list:update()

end

local function show_item_list()

    ui_helpers.set_on_item_clicked(on_item_clicked)
    print("CREATING ITEM UI")

    enchanting_ui.item_list = UI.create{
        name = "item_list",
        layer = "Windows",
        template = I.MWUI.templates.boxSolid,
        props = {
            relativeSize = v2(1, 1),
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
        },
        content = UI.content {
            enchanting_ui.items_list:create()
        }
    }
end

local function on_soul_clicked(id, value, icon)

    enchanter.soul.id = id
    enchanter.soul.icon = icon
    enchanter.enchantment.charge = value
    enchanting_ui.stats_charge:set_text(tostring(value))
    
    print("click on soul: ", id)
    print("at icon: ", icon)
    print("with a soul value of: ", value)
    enchanting_ui.soul_input.content[3].props.resource = UI.texture({
        path = icon
    })
    enchanting_ui.root:update()

    auxUi.deepDestroy(enchanting_ui.soul_list)
    enchanting_ui.soul_list:update()

end

local function show_soul_list()

    ui_helpers.set_on_soul_clicked(on_soul_clicked)
    print("CREATING SOUL UI")

    enchanting_ui.soul_list = UI.create{
        name = "souls_list",
        layer = "Windows",
        template = I.MWUI.templates.boxSolid,
        props = {
            relativeSize = v2(1, 1),
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
        },
        content = UI.content {
            enchanting_ui.soul_list:create()
        }
    }
end

enchanting_ui.name_input = templates.text_input("Name", 200, function(text) enchanter.name = text end)
enchanting_ui.item_input = templates.text_image("Item", v2(75,75), 10, show_item_list, nil, nil)
enchanting_ui.soul_input = templates.text_image("Soul", v2(75,75), 10, show_soul_list, nil, nil)

local function inputs()
    print("inputs")

                    
    return {
        name = "inputs_flex",
        type = UI.TYPE.Flex,
        props = {
            horizontal = false,
            arrange = UI.ALIGNMENT.Start,
            align = UI.ALIGNMENT.Start,
            size = v2(300,50),
            -- gap = 10,
        },
        content = UI.content {
            enchanting_ui.name_input,
            templates.padding(10, 0),
            {
                name = "item_soul_flex",
                type = UI.TYPE.Flex,
                props = {
                    horizontal = true,
                    arrange = UI.ALIGNMENT.Start,
                    align = UI.ALIGNMENT.Start,
                },
                content = UI.content {
                    enchanting_ui.item_input,
                    templates.padding(10, 0),
                    enchanting_ui.soul_input,
                },
                templates.padding(10, 0),
            }
        }
    }
end

enchanting_ui.stats_enchantment = templates.text_output.new("Enchantment:", 200, 10, "0/0", UI.ALIGNMENT.End)
enchanting_ui.stats_cast_cost = templates.text_output.new("Cast Cost:", 200, 10, "0", UI.ALIGNMENT.End)
enchanting_ui.stats_charge = templates.text_output.new("Charge:", 200, 10, "0", UI.ALIGNMENT.End)
enchanting_ui.stats_chance = templates.text_output.new("Chance:", 200, 10, "0", UI.ALIGNMENT.End)

local function stats()
    return{
        name = "stats_flex",
        type = UI.TYPE.Flex,
        props = {
            horizontal = false,
            arrange = UI.ALIGNMENT.Start,
            align = UI.ALIGNMENT.Start,
            -- gap = 10,
        },
        content = UI.content {
            enchanting_ui.stats_enchantment:create(),
            enchanting_ui.stats_cast_cost:create(),
            enchanting_ui.stats_charge:create(),
            enchanting_ui.stats_chance:create()
        }
    }
end

header.element = {
    name = "header",
    template = I.MWUI.templates.padding,
    content = UI.content { {
        name = "header_flex",
        type = UI.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = UI.ALIGNMENT.Start,
            align = UI.ALIGNMENT.Start,
            -- gap = 20,
        },
        content = UI.content {
            templates.padding(20, 0),
            inputs(),
            stats(),
            templates.padding(20, 0),
        }
    } }
}
-- End header

-- main_content

-- enchanting_ui attribute
-- enchanting_ui skill
enchanting_ui.magnitude = templates.slider.new("Magnitude", 100, 1, 1, 1, function(value) enchanter.effect_to_add.magnitudeMin = value enchanting_ui.magic_effect_add:update() end)
enchanting_ui.magnitude_max = templates.slider.new("         ", 100, 1, 1, 1, function(value) enchanter.effect_to_add.magnitudeMax = value enchanting_ui.magic_effect_add:update() end)
enchanting_ui.duration = templates.slider.new("Duration", 1440, 1, 1, 1, function(value) enchanter.effect_to_add.duration = value enchanting_ui.magic_effect_add:update() end)
enchanting_ui.area = templates.slider.new("Area", 50, 0, 0, 1, function(value) enchanter.effect_to_add.area = value enchanting_ui.magic_effect_add:update() end)

local function toggle_range_type()
    print("toggle_range_type")
    local text = ""

    local function set_visible(control, visible)
        if visible then
            control:show()
        else
            control:hide()
        end
    end

    -- Find next valid range for magic id
    local range = enchanter.effect_to_add.range
    while true do
        range = ((range+1) % 3) -- 0-2)
        
        if core.magic.effects.records[enchanter.effect_to_add.id].onSelf and range == core.magic.RANGE.Self then
            text = "Self"
            break
        end
        if core.magic.effects.records[enchanter.effect_to_add.id].onTarget and range == core.magic.RANGE.Target then
            text = "Target"
            break
        end
        if core.magic.effects.records[enchanter.effect_to_add.id].onTouch and range == core.magic.RANGE.Touch then
            text = "Touch"
            break
        end
    end

    -- however, if constant effect only self is allowed
    if enchanter.enchantment.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect then
        print("Constant Effect")

        range = core.magic.RANGE.Self -- range has to be self
        text = "Self"
        enchanter.enchantment.isAutocalc = false -- disable autocalc
    end

    enchanter.effect_to_add.range = range
    enchanting_ui.range.content[2].props.text = text
    print("New range: ", text)

    -- Now get all possible parameters to customize
    if core.magic.effects.records[enchanter.effect_to_add.id].hasAttribute then
        print("Effect has attribute")

    else
        
    end
    if core.magic.effects.records[enchanter.effect_to_add.id].hasSkill then
        print("Effect has skill")
        
    else
        
    end

    enchanter.effect_to_add.duration = 0
    set_visible(enchanting_ui.duration, core.magic.effects.records[enchanter.effect_to_add.id].hasDuration)
    
    enchanter.effect_to_add.magnitudeMax = 0
    enchanter.effect_to_add.magnitudeMin = 0
    set_visible(enchanting_ui.magnitude, core.magic.effects.records[enchanter.effect_to_add.id].hasMagnitude)
    set_visible(enchanting_ui.magnitude_max, core.magic.effects.records[enchanter.effect_to_add.id].hasMagnitude)

    enchanter.effect_to_add.area = 0
    set_visible(enchanting_ui.area, enchanter.effect_to_add.range ~= core.magic.RANGE.Self)

    enchanting_ui.magic_effect_add:update()
end

enchanting_ui.range = templates.button("Self", toggle_range_type, 100, 30)

local function ok_magic_effect()
    print("ok_magic_effect")
    local effect_index
    
    for index, effect in ipairs(enchanter.effects_with_params) do
        if effect.id == enchanter.effect_to_add.id then
            if enchanter.effect_to_modify==false then
                UI.showMessage("This magic effect has already been added")
            end
            effect_index = index
        end
    end
    print(index)

    if enchanter.effect_to_modify then 
        enchanter.effects_with_params[effect_index] = enchanter.effect_to_add -- replace existing entry
        enchanting_ui.effects:remove_item(effect_index) -- remove UI element, will replace it later
    else
        table.insert(enchanter.effects_with_params, enchanter.effect_to_add)
        
    end
    
    local effect_to_add_ui = ui_helpers.create_effect_item(enchanter.effect_to_add, on_effect_clicked)
    enchanting_ui.effects:add_item(effect_to_add_ui)

    auxUi.deepDestroy(enchanting_ui.magic_effect_add)
    enchanting_ui.magic_effect_add:update()
    enchanting_ui.root:update()
end

local function cancel_magic_effect()
    print("cancel_magic_effect")
    
    auxUi.deepDestroy(enchanting_ui.magic_effect_add)
    enchanting_ui.magic_effect_add:update()
end

local function delete_effect()
    print("delete_effect")
    for i, effect in ipairs(enchanter.effects_with_params) do
        if effect.id == enchanter.effect_to_add.id then
            enchanting_ui.effects:remove_item(i)
            table.remove(enchanter.effects_with_params, i)
            break
        end
    end
    enchanter.reset_effect_to_add()
    auxUi.deepDestroy(enchanting_ui.magic_effect_add)
    enchanting_ui.magic_effect_add:update()
    enchanting_ui.root:update()
end

local function create_magic_effect_add_UI(modify, id) 

    local delete_btn

    if modify then
        delete_btn = templates.button("Delete", delete_effect, 100, 30)
    else
        delete_btn = nil             
    end
    
    return {
        name = "magic_effect_add",
        layer = "Windows",
        template = I.MWUI.templates.boxSolid,
        props = {
            
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
        },
        content = UI.content {
            templates.make_border(v2(400, 300)),
            {
                name = "magic_effect_add_flex",
                type = UI.TYPE.Flex,
                props = {
                    horizontal = false,
                    arrange = UI.ALIGNMENT.Start,
                    align = UI.ALIGNMENT.Center,
                },
                content = UI.content {
                    {
                        name = "effect_icon",
                        type = UI.TYPE.Flex,
                        props = {
                            horizontal = true,
                            arrange = UI.ALIGNMENT.Start,
                            align = UI.ALIGNMENT.Start,
                        },
                        content = UI.content {
                            {
                                name = "icon",
                                type = UI.TYPE.Image,
                                template = I.MWUI.templates.borders,
                                props = {
                                    resource = UI.texture({
                                        path = core.magic.effects.records[id].icon
                                    }),
                                    alpha = 1,
                                    size = v2(20,20),
                                },
                            },
                            templates.padding(10, 0),
                            {
                                name = "name",
                                type = UI.TYPE.Text,
                                template = I.MWUI.templates.textNormal,
                                props = {
                                    text = core.magic.effects.records[id].name,
                                    textSize = 20,
                                }
                            },
                            
                        }
                    },
                    {
                        name = "effect_icon",
                        type = UI.TYPE.Flex,
                        props = {
                            horizontal = true,
                            arrange = UI.ALIGNMENT.Start,
                            align = UI.ALIGNMENT.Start,
                        },
                        content = UI.content {
                            {
                                name = "range",
                                type = UI.TYPE.Text,
                                template = I.MWUI.templates.textNormal,
                                props = {
                                    text = "Range",
                                    textSize = 20,
                                }
                            },
                            templates.padding(100, 0),
                            enchanting_ui.range,
                        }
                    },
                    enchanting_ui.magnitude:create(),
                    enchanting_ui.magnitude_max:create(),
                    enchanting_ui.duration:create(),
                    enchanting_ui.area:create(),
                    templates.button("Cancel", cancel_magic_effect, 100, 30),
                    templates.button("OK", ok_magic_effect, 100, 30),
                    delete_btn,
                }
            }
        }
    }
end

local function on_magic_effect_clicked(id)

    print("On magic effect clicked: ", id)
    enchanter.reset_effect_to_add()
    enchanter.effect_to_add.id = id
    enchanter.effect_to_modify = false
    
    print("CREATING MAGIC EFFECT ADD UI")
    enchanting_ui.magic_effect_add = UI.create(create_magic_effect_add_UI(enchanter.effect_to_modify, id))

    toggle_range_type()

    enchanting_ui.root:update()
    enchanting_ui.magic_effect_add:update()

end

function on_effect_clicked(id)

    print("On effect clicked: ", id)
    for i, effect in ipairs(enchanter.effects_with_params) do
        if effect.id == id then
            enchanter.effect_to_add = enchanter.effects_with_params[i]
            break
        end
    end
    enchanter.effect_to_modify = true

    print("CREATING EFFECT ADD UI")
    enchanting_ui.magic_effect_add = UI.create(create_magic_effect_add_UI(enchanter.effect_to_modify, id))

    toggle_range_type()

    enchanting_ui.root:update()
    enchanting_ui.magic_effect_add:update()

end

ui_helpers.set_on_magic_effect_clicked(on_magic_effect_clicked)
enchanting_ui.magic_effects = templates.list.new("Magic Effects", v2(200,300), ui_helpers.make_magic_effects_list)
ui_helpers.set_on_effect_clicked(on_effect_clicked)
enchanting_ui.effects = templates.list.new("Effects", v2(350,300), function() end)

main_content.element = {
    name = "content",
    template = I.MWUI.templates.padding,
    content = UI.content { {
        name = "content_flex",
        type = UI.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = UI.ALIGNMENT.Start,
            align = UI.ALIGNMENT.Start,
            -- gap = 20,
        },
        content = UI.content {
            templates.padding(10, 0),
            enchanting_ui.magic_effects:create(),
            templates.padding(10, 0),
            enchanting_ui.effects:create(),
            templates.padding(10, 0),
        }
    } }
}
-- End main_content

-- footer

local function toggle_cast_type()
    print("toggle_cast_type")
    enchanting_ui.cast_type_btn.content[2].props.text = enchanter.toggle_cast_type()
    enchanting_ui.root:update()
end

enchanting_ui.cast_type_btn = templates.button("Cast Once", toggle_cast_type, 100, 30)
enchanting_ui.price = templates.text_output.new("Price:", 200, 10, "0", UI.ALIGNMENT.End)

footer.element = {
    name = "footer",
    template = I.MWUI.templates.padding,
    content = UI.content { {
        name = "footer_flex",
        type = UI.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = UI.ALIGNMENT.Start,
            align = UI.ALIGNMENT.Start,
        },
        content = UI.content {
            templates.padding(10, 0),
            enchanting_ui.cast_type_btn,
            templates.padding(10, 0),
            enchanting_ui.price:create(),
            templates.padding(200, 0),
            templates.button("Create", (function()
                print("Clicked Create")
                ambient.playSound('menu click')
                enchanting_ui.enchant_item()
                return true
            end), 50, 30),
            templates.padding(10, 0),
            templates.button("Cancel", (function()
                print("Clicked Cancel")
                ambient.playSound('menu click')
                enchanter.reset()   -- Clean up enchanter
                enchanting_ui.hide()
            end), 50, 30),
            templates.padding(10, 0),
        }
    } }
}
-- End footer

enchanting_ui.show = function()
    print("Menu Show")
    enchanting_ui.create_ui()
    enchanting_ui.root:update()
end

-- TODO: fix this
enchanting_ui.hide = function()
    print("Menu Hide")
    auxUi.deepDestroy(enchanting_ui.root)
    enchanting_ui.root:update()
    I.UI.removeMode('EnchantingDialog')
end

enchanting_ui.enchant_item = function()
    print("enchant_item")
    enchanter.enchant_item()
end

return enchanting_ui