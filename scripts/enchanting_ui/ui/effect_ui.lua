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


local effect_ui = {}

effect_ui.on_magic_effect_clicked = function(id)

    print("On magic effect clicked: ", id)

    if #enchanter.effects_with_params >= 8 then
        print("Max effects added, returning!")
        UI.showMessage("Max number of effects reached")
        return
    end

    enchanter.reset_effect_to_add()
    enchanter.effect_to_add.id = id
    enchanter.effect_to_modify = false

    print("CREATING MAGIC EFFECT ADD UI")
    elements.effects_root = UI.create(effect_ui.new(enchanter.effect_to_modify, enchanter.effect_to_add):create())
    elements.effects_root:update()
    elements.disable_ui(elements.root)

end

local function create_magic_effect_item(id, name)
    -- TODO: add more like magic school info
    return 
    {
        name = id,
        type = UI.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = name,
            textSize = elements.text_size,
        },
        events = {
            mouseClick = async:callback(function()
                effect_ui.on_magic_effect_clicked(id)
            end)
        }
    }
end

function effect_ui.make_magic_effects_list()
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

effect_ui.on_effect_clicked = function(id)

    print("On effect clicked: ", id)
    enchanter.reset_effect_to_add()

    local found = false

    for i, effect in ipairs(enchanter.effects_with_params) do
        if effect.id == id then
            enchanter.effect_to_add = enchanter.effects_with_params[i]
            found = true
            break
        end
    end
    if found == false then
        print("ERROR: could not find matching effect id in existing effects")
        return
    end
    enchanter.effect_to_modify = true

    print("CREATING EFFECT ADD UI")
    effect_ui.effects_ui = effect_ui.new(enchanter.effect_to_modify, enchanter.effect_to_add)
    elements.effects_root = UI.create(effect_ui.effects_ui:create())
    elements.effects_root:update()
    elements.disable_ui(elements.root)

end

effect_ui.create_effect_item = function(effect)
    print("create_effect_item")
    print(effect.id)
    local name = core.magic.effects.records[effect.id].name

    local icon_element = {
        name = "icon",
        type = UI.TYPE.Image,
        template = I.MWUI.templates.borders,
        props = {
            resource = UI.texture({
                path = core.magic.effects.records[effect.id].icon
            }),
            alpha = 1,
            size = elements.effect_icon_size,
        },
    }

    local parts = { name }

    if core.magic.effects.records[effect.id].hasSkill then
        table.insert(parts, effect.affectedSkill)
    end

    if core.magic.effects.records[effect.id].hasAttribute then
        table.insert(parts, effect.affectedAttribute)
    end

    if core.magic.effects.records[effect.id].hasMagnitude then
        table.insert(parts, ("%d to %d"):format(effect.magnitudeMin, effect.magnitudeMax))
    end

    if core.magic.effects.records[effect.id].hasDuration and enchanter.enchantment.type ~= core.magic.ENCHANTMENT_TYPE.ConstantEffect then
        table.insert(parts, ("for %d sec"):format(effect.duration))
    end

    if core.magic.effects.records[effect.id].hasArea then
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
            textSize = elements.text_size,
        },
    }

    return 
    {
        name = name.."_effect_item",
        type = UI.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = UI.ALIGNMENT.Center,
            align = UI.ALIGNMENT.Start,
        },
        content = UI.content {
            icon_element,
            text_element,
        },
        events = {
            mouseClick = async:callback(function()
                if effect_ui.on_effect_clicked then
                    print("EFFECT CLICKED")
                    effect_ui.on_effect_clicked(effect.id)
                end
            end)
        }
    }
end

local select_list_ui = {}
select_list_ui.new = function(name, records, on_click_fnc)

    local instance = {}
    instance.list = {}
    for _, record in ipairs(records) do
        table.insert(instance.list, record.name)
    end
    instance.on_click_fnc = on_click_fnc

    local function generate_list_elements() 
        print("select_list_ui.generate_list_elements")
        local list_elements = {}

        for _, item in pairs(instance.list) do
            local element = {
                name = item,
                type = UI.TYPE.Text,
                template = I.MWUI.templates.textNormal,
                props = {
                    text = tostring(item),
                    textSize = 20,
                    textAlignV = UI.ALIGNMENT.Center,
                    textAlignH = UI.ALIGNMENT.Center,
                    autoSize = false,
                    size = v2(elements.effects_size[1], 20)
                },
                events = {
                    mouseClick = async:callback(function()
                        instance.on_click_fnc(item)
                    end)
                }
            }
            table.insert(list_elements, element)
        end
        print("generate list elements")
        return list_elements
    end

    local name_element = {
        name = "text",
        type = UI.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = name,
            textSize = elements.text_size,
            size = v2(elements.effects_size[1], elements.text_size),
            autoSize = false,
            textAlignH = UI.ALIGNMENT.Center,
            textAlignV = UI.ALIGNMENT.Center,
        },
    }

    local list_basic_props = {
        alignment = UI.ALIGNMENT.Center,
        relativePosition = v2(0.5, 0.5),
        border = "",
    }
    local list_element = templates.list.new("", v2(elements.effects_size[1], elements.effects_size[2]), nil, generate_list_elements, nil, list_basic_props)
    
    function instance:create()
        print("select_list_ui.create")
        self.ui = {
            name = name.."_element",
            layer = "Windows",
            type = UI.TYPE.Widget,
            props = {
                relativePosition = v2(0.5, 0.5),
                relativeSize = v2(1,1),
                anchor = v2(0.5, 0.5),
                visible = true,
            },
            content = UI.content {
                templates.make_border(v2(elements.effects_size[1], elements.effects_size[2]), 1),
                {
                    type = UI.TYPE.Flex,
                    props = {
                        horizontal = false,
                        arrange = UI.ALIGNMENT.Center,
                        align = UI.ALIGNMENT.Center,
                        anchor = v2(0.5, 0.5),
                        relativePosition = v2(0.5, 0.5),

                        autoSize = true,
                        visible = true,
                        wrap = true
                    },
                    content = UI.content{
                        name_element,
                        list_element:create(),
                    }
                }
            }
        }
        return self.ui
    end

    return instance
end

effect_ui.new = function(modify, effect_to_add) 

    local instance = {}

    local id = effect_to_add.id
    enchanter.effect_to_add.cost = 0


    local function show_valid_effect_sliders(update_ui)

        print("show_valid_effect_sliders")

        local force_no_duration = false
        local force_no_area = false

        local function set_visible(control, visible)
            if visible then
                control:show()
            else
                control:hide()
            end
        end

        -- however, if constant effect only self is allowed
        if enchanter.enchantment.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect then
            print("Constant Effect")
            force_no_duration = true
            force_no_area = true
        end


        set_visible(instance.skill, core.magic.effects.records[enchanter.effect_to_add.id].hasSkill)
        set_visible(instance.attribute, core.magic.effects.records[enchanter.effect_to_add.id].hasAttribute)

        set_visible(instance.duration, (core.magic.effects.records[enchanter.effect_to_add.id].hasDuration and force_no_duration==false))

        set_visible(instance.magnitude, core.magic.effects.records[enchanter.effect_to_add.id].hasMagnitude)
        set_visible(instance.magnitude_max, core.magic.effects.records[enchanter.effect_to_add.id].hasMagnitude)

        -- enchanter.effect_to_add.area = 0
        set_visible(instance.area, (enchanter.effect_to_add.range ~= core.magic.RANGE.Self and force_no_area==false))

        if update_ui then
            elements.effects_root:update()
        end
    end

    local function update_effect_to_add_cost(update_ui)
        print("update_effect_to_add_cost")

        local cost = enchanter.get_effect_to_add_cost()

        enchanter.effect_to_add.cost = cost
        instance.cost:set_text(tostring(cost))
        print("effect cost: ", cost)

        if update_ui then
            elements.effects_root:update()
        end
    end

    local function toggle_range_type()
        print("toggle_range_type")
        local text = ""

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
        instance.range:set_text(text)
        print("New range: ", text)

        show_valid_effect_sliders(false)
        update_effect_to_add_cost(false)
        elements.effects_root:update()
    end

    local function ok_magic_effect()
        print("ok_magic_effect")
        local effect_index
        
        for index, effect in ipairs(enchanter.effects_with_params) do
            if effect.id == enchanter.effect_to_add.id then
                if enchanter.effect_to_modify==false then
                    UI.showMessage("This magic effect has already been added")
                    return
                end
                effect_index = index
            end
        end

        local effect_to_add_ui = effect_ui.create_effect_item(enchanter.effect_to_add)

        if enchanter.effect_to_modify then 
            enchanter.effects_with_params[effect_index] = enchanter.effect_to_add -- replace existing entry
            elements.effects:update_item(effect_index, effect_to_add_ui)
        else
            table.insert(enchanter.effects_with_params, enchanter.effect_to_add)
            elements.effects:add_item(effect_to_add_ui)
        end
        
        enchanter.enchantment.base_cost = enchanter.get_effects_total_base_cost()
        enchanter.enchantment.effective_cost = enchanter.get_effective_cost()
        
        elements.stats_enchantment:set_text(tostring(enchanter.enchantment.base_cost).."/"..tostring(enchanter.item.enchantment_capacity))
        elements.stats_charge:set_text(tostring(enchanter.enchantment.effective_cost) .. "/" .. tostring(enchanter.soul.charge))

        auxUi.deepDestroy(elements.effects_root)
        elements.effects_root:update()
        elements.enable_ui(elements.root)
    end

    local function cancel_magic_effect()
        print("cancel_magic_effect")
        
        auxUi.deepDestroy(elements.effects_root)
        elements.effects_root:update()
        elements.enable_ui(elements.root)
    end

    local function delete_effect()
        print("delete_effect")
        for i, effect in ipairs(enchanter.effects_with_params) do
            if effect.id == enchanter.effect_to_add.id then
                elements.effects:remove_item(i)
                table.remove(enchanter.effects_with_params, i)
                break
            end
        end
        enchanter.reset_effect_to_add()

        enchanter.enchantment.base_cost = enchanter.get_effects_total_base_cost()
        enchanter.enchantment.effective_cost = enchanter.get_effective_cost()

        elements.stats_enchantment:set_text(tostring(enchanter.enchantment.base_cost).."/"..tostring(enchanter.item.enchantment_capacity))
        elements.stats_charge:set_text(tostring(enchanter.enchantment.effective_cost) .. "/" .. tostring(enchanter.soul.charge))

        auxUi.deepDestroy(elements.effects_root)
        elements.effects_root:update()
        elements.enable_ui(elements.root)
    end

    local function on_skill_select_click()
        print("on_skill_select_click")

        -- Disable previous UI
        elements.disable_ui(elements.effects_root)
        elements.effects_root:update()

        function instance.set_skill(skill) 

            -- Close UI
            auxUi.deepDestroy(instance.skill_root)
            instance.skill_root:update()

            -- Update current enchantment with new value
            enchanter.effect_to_add.affectedSkill = skill
            print("enchanter.effect_to_add.affectedSkill: ", enchanter.effect_to_add.affectedSkill)

            -- Update UI
            instance.skill:set_text(skill)

            -- enable effect UI
            elements.enable_ui(elements.effects_root)
            elements.effects_root:update()
        end

        -- New UI popup
        instance.skill_root = UI.create(select_list_ui.new("Choose Skill", core.stats.Skill.records, instance.set_skill):create())
        instance.skill_root:update()
        
    end
    local function on_attribute_select_click()
        -- Disable previous UI
        elements.disable_ui(elements.effects_root)
        elements.effects_root:update()

        function instance.set_attribute(attribute) 
            print("effect_ui.set_attribute: ", attribute)

            -- Close UI
            auxUi.deepDestroy(instance.attribute_root)
            instance.attribute_root:update()

            -- Update current enchantment with new value
            enchanter.effect_to_add.affectedAttribute = attribute
            print("enchanter.effect_to_add.affectedAttribute: ", enchanter.effect_to_add.affectedAttribute)

            -- Update UI
            instance.attribute:set_text(attribute)

            -- enable effect UI
            elements.enable_ui(elements.effects_root)
            elements.effects_root:update()
        end

        -- New UI popup
        instance.attribute_root = UI.create(select_list_ui.new("Choose an Attribute", core.stats.Attribute.records, instance.set_attribute):create())
        instance.attribute_root:update()
        
    end

    instance.delete_btn = nil
    
    if modify then
        instance.delete_btn = templates.button.new("Delete", delete_effect, 100, 30)

        instance.skill =  templates.button.new(enchanter.effect_to_add.affectedSkill, on_skill_select_click, elements.attribute_button_size[1], elements.attribute_button_size[2])
        instance.attribute = templates.button.new(enchanter.effect_to_add.affectedAttribute, on_attribute_select_click, elements.attribute_button_size[1], elements.attribute_button_size[2])
        instance.magnitude = templates.slider.new("Magnitude Min", 100, 1, effect_to_add.magnitudeMin, 1, function(value) enchanter.effect_to_add.magnitudeMin = value update_effect_to_add_cost(true) end)
        instance.magnitude_max = templates.slider.new("Magnitude Max", 100, 1, effect_to_add.magnitudeMax, 1, function(value) enchanter.effect_to_add.magnitudeMax = value update_effect_to_add_cost(true) end)
        instance.duration = templates.slider.new("Duration", 1440, 1, effect_to_add.duration, 1, function(value) enchanter.effect_to_add.duration = value update_effect_to_add_cost(true) end)
        instance.area = templates.slider.new("Area", 50, 0, effect_to_add.area, 1, function(value) enchanter.effect_to_add.area = value update_effect_to_add_cost(true) end)
    else
        instance.skill =  templates.button.new(core.stats.Skill.records[1].name, on_skill_select_click, elements.attribute_button_size[1], elements.attribute_button_size[2])
        instance.attribute = templates.button.new(core.stats.Attribute.records[1].name, on_attribute_select_click, elements.attribute_button_size[1], elements.attribute_button_size[2])
        instance.magnitude = templates.slider.new("Magnitude Min", 100, 1, 1, 1, function(value) enchanter.effect_to_add.magnitudeMin = value update_effect_to_add_cost(true) end)
        instance.magnitude_max = templates.slider.new("Magnitude Max", 100, 1, 1, 1, function(value) enchanter.effect_to_add.magnitudeMax = value update_effect_to_add_cost(true) end)
        instance.duration = templates.slider.new("Duration", 1440, 1, 1, 1, function(value) enchanter.effect_to_add.duration = value update_effect_to_add_cost(true) end)
        instance.area = templates.slider.new("Area", 50, 0, 0, 1, function(value) enchanter.effect_to_add.area = value update_effect_to_add_cost(true) end)
    end

    instance.range = templates.button.new("Self", toggle_range_type, 100, 30)
    instance.cost = templates.text_output.new("Cost:", 100, 10, "0", UI.ALIGNMENT.End)

    function instance:create()

        local delete_btn
        if instance.delete_btn then
            delete_btn = instance.delete_btn:create()
        end

        instance.ui = {
            name = "effect_add",
            layer = "Windows",
            type = UI.TYPE.Widget,
            -- template = I.MWUI.templates.boxSolid,
            props = {
                relativeSize = v2(1, 1),
                relativePosition = v2(0.5, 0.5),
                anchor = v2(0.5, 0.5),
                visible = true,
            },
            content = UI.content {
                templates.make_border(v2(elements.effects_size[1], elements.effects_size[2])),
                {
                    name = "magic_effect_add_flex",
                    type = UI.TYPE.Flex,
                    props = {
                        horizontal = false,
                        arrange = UI.ALIGNMENT.Start,
                        align = UI.ALIGNMENT.Start,
                        relativePosition = v2(0.5, 0.5),
                        anchor = v2(0.5, 0.5),
                        size = v2(elements.effects_size[1], elements.effects_size[2]),
                        autoSize = false,
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
                                        size = elements.effect_icon_size,
                                    },
                                },
                                templates.padding(40, 0),
                                {
                                    name = "name",
                                    type = UI.TYPE.Text,
                                    template = I.MWUI.templates.textNormal,
                                    props = {
                                        text = tostring(core.magic.effects.records[id].name),
                                        textSize = elements.text_size,
                                    }
                                },
                                
                            }
                        },
                        templates.padding(elements.padding_size, 4*elements.padding_size),
                        {
                            name = "range",
                            type = UI.TYPE.Flex,
                            props = {
                                horizontal = true,
                                arrange = UI.ALIGNMENT.Start,
                                align = UI.ALIGNMENT.Start,
                            },
                            content = UI.content {
                                {
                                    name = "range_text",
                                    type = UI.TYPE.Text,
                                    template = I.MWUI.templates.textNormal,
                                    props = {
                                        text = "Range",
                                        textSize = elements.text_size,
                                        size = v2(100, elements.text_size)
                                    }
                                },
                                templates.padding(100, 0),
                                instance.range:create(),
                                -- TODO: add cost
                                templates.padding(100, 0),
                                instance.cost:create(),
                            }
                        },
                        instance.skill:create(),
                        templates.padding(elements.padding_size, 2*elements.padding_size),
                        instance.attribute:create(),
                        templates.padding(elements.padding_size, 2*elements.padding_size),
                        instance.magnitude:create(),
                        templates.padding(elements.padding_size, elements.padding_size),
                        instance.magnitude_max:create(),
                        templates.padding(elements.padding_size, elements.padding_size),
                        instance.duration:create(),
                        templates.padding(elements.padding_size, elements.padding_size),
                        instance.area:create(),
                        templates.padding(elements.padding_size, elements.padding_size),
                        templates.button.new("Cancel", cancel_magic_effect, 100, 30):create(),
                        templates.padding(elements.padding_size, elements.padding_size),
                        templates.button.new("OK", ok_magic_effect, 100, 30):create(),
                        templates.padding(elements.padding_size, elements.padding_size),
                        delete_btn,
                    }
                }
            }
        }

        update_effect_to_add_cost(false)
        show_valid_effect_sliders(false)

        return instance.ui
    end

    return instance
    
end


elements.magic_effects = templates.list.new("Magic Effects", v2(350,300), nil, effect_ui.make_magic_effects_list)
elements.effects = templates.list.new("Effects", v2(350,300), nil, function() end)

return effect_ui