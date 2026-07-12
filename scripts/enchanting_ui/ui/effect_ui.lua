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

    if table.getn(enchanter.effects_with_params) >= 8 then
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
    disable_ui(elements.root)

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
            textSize = 20,
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
    enable_ui(elements.root)

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
            size = v2(20,20),
        },
    }

    local parts = { name }

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
            textSize = 20,
        },
    }

    return 
    {
        name = name.."_effect_item",
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
                if effect_ui.on_effect_clicked then
                    print("EFFECT CLICKED")
                    effect_ui.on_effect_clicked(effect.id)
                end
            end)
        }
    }
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

        -- set_visible(effect_ui.magnitude, core.magic.effects.records[enchanter.effect_to_add.id].hasSkill)
        -- set_visible(effect_ui.magnitude_max, core.magic.effects.records[enchanter.effect_to_add.id].hasAttribute)

        -- enchanter.effect_to_add.duration = 0
        set_visible(instance.duration, (core.magic.effects.records[enchanter.effect_to_add.id].hasDuration and force_no_duration==false))
        
        -- enchanter.effect_to_add.magnitudeMax = 1
        -- enchanter.effect_to_add.magnitudeMin = 1
        set_visible(instance.magnitude, core.magic.effects.records[enchanter.effect_to_add.id].hasMagnitude)
        set_visible(instance.magnitude_max, core.magic.effects.records[enchanter.effect_to_add.id].hasMagnitude)

        -- enchanter.effect_to_add.area = 0
        set_visible(instance.area, (enchanter.effect_to_add.range ~= core.magic.RANGE.Self and force_no_area==false))

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
        instance.range.content[2].props.text = text
        print("New range: ", text)

        show_valid_effect_sliders()
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

        print("Effect to modify duration: ", enchanter.effect_to_add.duration)
        local effect_to_add_ui = effect_ui.create_effect_item(enchanter.effect_to_add)

        if enchanter.effect_to_modify then 
            enchanter.effects_with_params[effect_index] = enchanter.effect_to_add -- replace existing entry
            effect_ui.effects:update_item(effect_index, effect_to_add_ui)
        else
            table.insert(enchanter.effects_with_params, enchanter.effect_to_add)
            effect_ui.effects:add_item(effect_to_add_ui)
        end
        
        enchanter.enchantment.cost = enchanter.get_effects_total_cost()
        elements.stats_charge:set_text(tostring(enchanter.enchantment.cost) .. "/" .. tostring(enchanter.soul.charge))
        elements.stats_enchantment:set_text(tostring(enchanter.enchantment.cost).."/"..tostring(enchanter.item.enchantment_capacity))

        auxUi.deepDestroy(elements.effects_root)
        elements.effects_root:update()
        enable_ui(elements.root)
    end

    local function cancel_magic_effect()
        print("cancel_magic_effect")
        
        auxUi.deepDestroy(elements.effects_root)
        elements.effects_root:update()
        enable_ui(elements.root)
    end

    local function delete_effect()
        print("delete_effect")
        for i, effect in ipairs(enchanter.effects_with_params) do
            if effect.id == enchanter.effect_to_add.id then
                effect_ui.effects:remove_item(i)
                table.remove(enchanter.effects_with_params, i)
                break
            end
        end
        enchanter.reset_effect_to_add()

        enchanter.enchantment.cost = enchanter.get_effects_total_cost()
        elements.stats_charge:set_text(tostring(enchanter.enchantment.cost).. "/".. tostring(enchanter.soul.charge))

        auxUi.deepDestroy(elements.effects_root)
        elements.effects_root:update()
        enable_ui(elements.root)
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

    instance.range = templates.button("Self", toggle_range_type, 100, 30)
    instance.cost = templates.text_output.new("Cost:", 100, 10, "0", UI.ALIGNMENT.End)
    instance.delete_btn = nil

    if modify then
        instance.delete_btn = templates.button("Delete", delete_effect, 100, 30)

        instance.magnitude = templates.slider.new("Magnitude Min", 100, 1, effect_to_add.magnitudeMin, 1, function(value) enchanter.effect_to_add.magnitudeMin = value update_effect_to_add_cost(true) end)
        instance.magnitude_max = templates.slider.new("Magnitude Max", 100, 1, effect_to_add.magnitudeMax, 1, function(value) enchanter.effect_to_add.magnitudeMax = value update_effect_to_add_cost(true) end)
        instance.duration = templates.slider.new("Duration", 1440, 1, effect_to_add.duration, 1, function(value) enchanter.effect_to_add.duration = value update_effect_to_add_cost(true) end)
        instance.area = templates.slider.new("Area", 50, 0, effect_to_add.area, 1, function(value) enchanter.effect_to_add.area = value update_effect_to_add_cost(true) end)
    else
        instance.magnitude = templates.slider.new("Magnitude Min", 100, 1, 1, 1, function(value) enchanter.effect_to_add.magnitudeMin = value update_effect_to_add_cost(true) end)
        instance.magnitude_max = templates.slider.new("Magnitude Max", 100, 1, 1, 1, function(value) enchanter.effect_to_add.magnitudeMax = value update_effect_to_add_cost(true) end)
        instance.duration = templates.slider.new("Duration", 1440, 1, 1, 1, function(value) enchanter.effect_to_add.duration = value update_effect_to_add_cost(true) end)
        instance.area = templates.slider.new("Area", 50, 0, 0, 1, function(value) enchanter.effect_to_add.area = value update_effect_to_add_cost(true) end)
    
    end

    function instance:create()

        instance.ui = {
            name = "effect_add",
            layer = "Windows",
            template = I.MWUI.templates.boxSolid,
            props = {
                relativeSize = v2(1, 1),
                relativePosition = v2(0.5, 0.5),
                anchor = v2(0.5, 0.5),
            },
            content = UI.content {
                templates.make_border(v2(400, 400)),
                {
                    name = "magic_effect_add_flex",
                    type = UI.TYPE.Flex,
                    props = {
                        horizontal = false,
                        arrange = UI.ALIGNMENT.Start,
                        align = UI.ALIGNMENT.Center,
                        size = v2(500, 300),
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
                                        size = v2(20,20),
                                    },
                                },
                                templates.padding(40, 0),
                                {
                                    name = "name",
                                    type = UI.TYPE.Text,
                                    template = I.MWUI.templates.textNormal,
                                    props = {
                                        text = tostring(core.magic.effects.records[id].name),
                                        textSize = 20,
                                    }
                                },
                                
                            }
                        },
                        templates.padding(30, 0),
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
                                        textSize = 20,
                                        size = v2(100, 20)
                                    }
                                },
                                templates.padding(100, 0),
                                instance.range,
                                -- TODO: add cost
                                templates.padding(100, 0),
                                instance.cost:create(),
                            }
                        },
                        templates.padding(30, 0),
                        instance.magnitude:create(),
                        templates.padding(10, 0),
                        instance.magnitude_max:create(),
                        templates.padding(10, 0),
                        instance.duration:create(),
                        templates.padding(10, 0),
                        instance.area:create(),
                        templates.padding(30, 0),
                        templates.button("Cancel", cancel_magic_effect, 100, 30),
                        templates.padding(10, 0),
                        templates.button("OK", ok_magic_effect, 100, 30),
                        templates.padding(10, 0),
                        instance.delete_btn,
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


effect_ui.magic_effects = templates.list.new("Magic Effects", v2(350,300), effect_ui.make_magic_effects_list)
effect_ui.effects = templates.list.new("Effects", v2(350,300), function() end)

elements.magic_effects = effect_ui.magic_effects
elements.effects = effect_ui.effects

return effect_ui