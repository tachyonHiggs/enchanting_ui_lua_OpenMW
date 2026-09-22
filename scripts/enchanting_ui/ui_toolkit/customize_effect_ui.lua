---@omw-context player

local UI = require('openmw.ui')
local I = require('openmw.interfaces')
local Util = require('openmw.util')
local v2 = Util.vector2
local ui = require("openmw.ui")
local ambient = require('openmw.ambient')
local core = require('openmw.core')
local storage = require('openmw.storage')

local templates = require("scripts.enchanting_ui.templates")
local enchanter = require("scripts.enchanting_ui.enchanter")
local elements = require("scripts.enchanting_ui.ui.elements")

local customize_effect_ui = {}
local rowHeight = 25
local window_size = {400, 600}
local effect_icon_size = v2(20,20)

-- TODO: this for slider values, is there a better option?
local function generate_slider_value(default_value)
    local element = I.UIToolkit.Components.textButton { text = default_value, width = 35, canClick = false, style = 'thin', thickness = 0}
    return element
end

local function generate_slider(name, value_element, scrollBar_element)
    local theme = I.UIToolkit.getTheme()
    local text_width = 129

    local text_element = {
        type = UI.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = name,
            textSize = theme.Sizes.textNormal,
            size = v2(text_width, theme.Sizes.textNormal),
            autoSize = false
        }
    }
    return templates.flex({text_element, value_element, scrollBar_element}, name.."_slider", true, UI.ALIGNMENT.End, UI.ALIGNMENT.End, 1, 5)
end

---@param wnd EnchantingHandler
function customize_effect_ui.show_customize_effect_ui(wnd, effect_id, modify_effect, index_to_modify)
    print("customize_effect_ui.show_customize_effect_ui")

    -- First reset this guy
    enchanter.reset_effect_to_add()
    enchanter.effect_to_modify = modify_effect
    if enchanter.effect_to_modify then
        if index_to_modify > #enchanter.effects_with_params then
            print("CRITICAL ERROR: attempting to modify effect outside of existing ones")
            return
        end
        enchanter.effect_to_add = enchanter.effects_with_params[index_to_modify]
    end
    enchanter.effect_to_add.id = effect_id
    enchanter.effect_to_add.index = index_to_modify

    local titleHeight = math.floor(1.5 * rowHeight)
    local theme = I.UIToolkit.getTheme()

    local effect_icon_element = {
        name = "effect_icon",
        type = UI.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = UI.ALIGNMENT.Start,
            align = UI.ALIGNMENT.Start,
        },
        content = UI.content {
            templates.padding(10, rowHeight),
            {
                name = "icon",
                type = UI.TYPE.Image,
                template = I.MWUI.templates.borders,
                props = {
                    resource = UI.texture({
                        path = core.magic.effects.records[effect_id].icon
                    }),
                    alpha = 1,
                    size = effect_icon_size,
                },
            },
            templates.padding(10, rowHeight),
            {
                name = "name",
                type = UI.TYPE.Text,
                template = I.MWUI.templates.textNormal,
                props = {
                    text = tostring(core.magic.effects.records[effect_id].name),
                    textSize = theme.Sizes.textNormal,
                }
            },
            
        }
    }

    local effect_cost = {
        type = UI.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = "Effect Cost: 0",
            textSize = theme.Sizes.textNormal,
            size = v2(125, titleHeight),
            autoSize = false,
            position = v2(300, 10),
        }
    }
    local function update_effect_to_add_cost()
        local cost = enchanter.get_effect_cost(enchanter.effect_to_add)
        enchanter.effect_to_add.cost = cost
        effect_cost.props.text = "Effect Cost: " .. string.format("%.1f", cost)
        print("effect cost: ", cost)
        -- TODO: how to update display text?
    end

    local okay_btn = I.UIToolkit.Components.textButton { text = "Okay", onClick = function() print("Okay!") 
        
        for index, effect in ipairs(enchanter.effects_with_params) do
            -- Attribute and skill effects allow multiple/duplicates on one enchantment
            local allow_duplicate_effects = core.magic.effects.records[effect.id].hasAttribute or core.magic.effects.records[effect.id].hasSkill or storage.globalSection("effects_enchanting_ui"):get("allow_duplicate_effects")
            if effect.id == enchanter.effect_to_add.id then
                if enchanter.effect_to_modify==false and not allow_duplicate_effects then
                    UI.showMessage("This magic effect has already been added")
                    return
                end
            end
        end

        -- print("wnd.effects_list: ", wnd.effects_list)
        if enchanter.effect_to_modify then
            wnd:modify_effect(enchanter.effect_to_add.index)
        else
            wnd:add_effect()
        end
        
        wnd:updateUI(wnd)

        customize_effect_ui.closePopup()

    end}
    okay_btn:updateProps({})
    local cancel_btn = I.UIToolkit.Components.textButton { text = "Cancel", onClick = function() customize_effect_ui.closePopup() end}
    cancel_btn:updateProps({})
    local delete_btn = I.UIToolkit.Components.textButton { text = "Delete", onClick = function() print("Delete!") 
        
        -- TODO: 
        -- if enchanter.effect_to_add.index > #enchanter.effects_with_params then
        --     print("ERROR: tried to delete effect outside of effects_with_params")
        --     return
        -- end

        -- Remove from enchanter effects
        -- Remove from UI effects 
        
        wnd:updateUI(wnd)

        customize_effect_ui.closePopup()
    end}
    delete_btn:updateProps({})

    local buttons = templates.flex({okay_btn.element, cancel_btn.element, delete_btn.element}, "customize_effect_btns", true, UI.ALIGNMENT.End, UI.ALIGNMENT.End, 5, 5, v2(window_size[1], titleHeight), v2(1,1), v2(1, 1))
    
    if not modify_effect then
        delete_btn:setDisabled(true)
    end

    local valid_ranges = {}
    local area_scrollbar = {}
    local is_constant_effect = enchanter.enchantment.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect
    if core.magic.effects.records[enchanter.effect_to_add.id].onSelf then
        table.insert(valid_ranges, { id = core.magic.RANGE.Self,       text = "Self" })
    end
    if core.magic.effects.records[enchanter.effect_to_add.id].onTarget and not is_constant_effect then
        table.insert(valid_ranges, { id = core.magic.RANGE.Target,     text = "Target" })
    end
    if core.magic.effects.records[enchanter.effect_to_add.id].onTouch and not is_constant_effect then
        table.insert(valid_ranges, { id = core.magic.RANGE.Touch,      text = "Touch" })
    end

    if not enchanter.effect_to_modify then
        enchanter.effect_to_add.range = valid_ranges[1].id
        print("Range defaulting to: ", valid_ranges[1].id)
    end

    local range_input = I.UIToolkit.Components.dropbox { -- Default is this guys is disabled
        items = valid_ranges,
        onItemSelected = function(item, index)
            print('Type:', item.text, 'Id:', item.id)
            enchanter.effect_to_add.range = item.id

            update_effect_to_add_cost()
            
            if enchanter.effect_to_add.range == core.magic.RANGE.Self then
                print("disabling area")
                area_scrollbar:setDisabled(true)
            else
                area_scrollbar:setDisabled(false)
            end
        end,
    }
    local range_text_element = {
        type = UI.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = " Range: ",
            textSize = theme.Sizes.textNormal,
            size = v2(125, theme.Sizes.textNormal),
            autoSize = false,
        }
    }
    local range = templates.flex({range_text_element, range_input.element}, "range", true, UI.ALIGNMENT.Start, UI.ALIGNMENT.Start, 5, 5)

    local valid_sliders = {}
    local force_no_duration = false
    local force_no_area = false

    -- If constant effect only self is allowed
    if enchanter.enchantment.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect then
        print("Constant Effect")
        force_no_duration = true
        force_no_area = true
    end


    local function on_effect_mag_slider_clicked(other_slider, other_value, position, value, is_max_slider)

        print("Setting slider mag values: ", position, value)
        print("is_max_slider", is_max_slider)
        if is_max_slider and position < other_slider:getPosition() then
            other_slider:setPosition(position)
            other_value:setText(tostring(value))
        elseif not is_max_slider and other_slider:getPosition() < position then
            other_slider:setPosition(position)
            other_value:setText(tostring(value))
        end
    end

    local magnitudeMax_value = {}
    local magnitudeMax_scrollbar = {}

    local magnitudeMin_value = generate_slider_value(tostring(enchanter.effect_to_add.magnitudeMin))
    local magnitudeMin_scrollbar = I.UIToolkit.Components.scrollBar{
        horizontal = true,
        length = 250,
        handleSize = 20,
        scrollStep = 2,
        maxScroll = 198,
        onScroll = function(position)
            local value = math.floor(position / 2) + 1
            print('Value:', value)
            -- TODO: handle mag specific things
            enchanter.effect_to_add.magnitudeMin = value
            magnitudeMin_value:setText(tostring(value))

            on_effect_mag_slider_clicked(magnitudeMax_scrollbar, magnitudeMax_value, position, value, false)

            update_effect_to_add_cost()
        end,
    }
    local magnitudeMin = generate_slider(
        "Magnitude Min:",
        magnitudeMin_value.element,
        magnitudeMin_scrollbar.element
    )

    magnitudeMax_value = generate_slider_value(tostring(enchanter.effect_to_add.magnitudeMax))
    magnitudeMax_scrollbar = I.UIToolkit.Components.scrollBar{
        horizontal = true,
        length = 250,
        handleSize = 20,
        scrollStep = 2,
        maxScroll = 198,
        onScroll = function(position)
            local value = math.floor(position / 2) + 1
            print('Value:', value)
            -- TODO: handle mag specific things
            enchanter.effect_to_add.magnitudeMax = value
            magnitudeMax_value:setText(tostring(value))
            
            on_effect_mag_slider_clicked(magnitudeMin_scrollbar, magnitudeMin_value, position, value, true)

            update_effect_to_add_cost()
        end,
    }
    local magnitudeMax = generate_slider(
        "Magnitude Max:",
        magnitudeMax_value.element,
        magnitudeMax_scrollbar.element
    )

    local magnitude_value = generate_slider_value(tostring(enchanter.effect_to_add.magnitudeMin))
    local magnitude_scrollbar = I.UIToolkit.Components.scrollBar{
        horizontal = true,
        length = 250,
        handleSize = 20,
        scrollStep = 2,
        maxScroll = 198,
        onScroll = function(position)
            local value = math.floor(position / 2) + 1
            print('Value:', value)
            enchanter.effect_to_add.magnitudeMin = value
            enchanter.effect_to_add.magnitudeMax = value
            magnitude_value:setText(tostring(value))
            update_effect_to_add_cost()
        end,
    }
    local magnitude = generate_slider(
        "Magnitude:",
        magnitude_value.element,
        magnitude_scrollbar.element
    )
    local constant_effect_constant_magnitude = false
    if core.magic.effects.records[enchanter.effect_to_add.id].hasMagnitude then
        if storage.globalSection("constant_enchanting_ui"):get("constant_effect_constant_magnitude") and enchanter.enchantment.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect then
            constant_effect_constant_magnitude = true
            table.insert(valid_sliders, magnitude)
        else
            table.insert(valid_sliders, magnitudeMin)
            table.insert(valid_sliders, magnitudeMax)
        end
    end

    local duration_value = generate_slider_value(tostring(enchanter.effect_to_add.duration))
    local duration_scrollbar = I.UIToolkit.Components.scrollBar{
        horizontal = true,
        length = 250,
        handleSize = 15,
        scrollStep = 1,
        maxScroll = 1439,
        onScroll = function(position)
            local value = math.floor(position) + 1
            print('Value:', value)
            enchanter.effect_to_add.duration = value
            duration_value:setText(tostring(value))

            update_effect_to_add_cost()
        end,
    }
    local duration = generate_slider(
        "Duration:",
        duration_value.element,
        duration_scrollbar.element
    )
    if core.magic.effects.records[enchanter.effect_to_add.id].hasDuration and not force_no_duration then
        table.insert(valid_sliders, duration)
    end
    
    local area_value = generate_slider_value(tostring(enchanter.effect_to_add.area))
    area_scrollbar = I.UIToolkit.Components.scrollBar{
        horizontal = true,
        length = 250,
        handleSize = 25,
        scrollStep = 2,
        maxScroll = 99,
        onScroll = function(position)
            local value = math.floor(position/2) + 1
            print('Value:', value)
            enchanter.effect_to_add.area = value
            area_value:setText(tostring(value))

            update_effect_to_add_cost()
        end,
    }
    local area = generate_slider(
        "Area:",
        area_value.element,
        area_scrollbar.element
    )
    if enchanter.effect_to_add.range == core.magic.RANGE.Self then
        print("disabling area")
        area_scrollbar:setDisabled(true)
    else
        area_scrollbar:setDisabled(false)
    end
    if not force_no_area then -- Will handle enchanter.effect_to_add.range ~= core.magic.RANGE.Self on range change
        table.insert(valid_sliders, area)
    end
    
    if enchanter.effect_to_modify then
        print("setting range: ", enchanter.effect_to_add.range)
        range_input:selectById(enchanter.effect_to_add.range)
        if constant_effect_constant_magnitude then
            magnitude_scrollbar:setPosition(math.max(enchanter.effect_to_add.magnitudeMin*2 - 1, 0))
        else
            print("enchanter.effect_to_add.magnitudeMax: ", enchanter.effect_to_add.magnitudeMax)
            print("enchanter.effect_to_add.magnitudeMin: ", enchanter.effect_to_add.magnitudeMin)
            magnitudeMax_scrollbar:setPosition(math.max(enchanter.effect_to_add.magnitudeMax*2 - 1, 0))
            magnitudeMin_scrollbar:setPosition(math.max(enchanter.effect_to_add.magnitudeMin*2 - 1, 0)) -- MAX must be set before min, to avoid min overriding the max
        end
        print("effect_to_add.duration: ", enchanter.effect_to_add.duration)
        duration_scrollbar:setPosition(math.max(enchanter.effect_to_add.duration - 1, 0))
        area_scrollbar:setPosition(math.max(enchanter.effect_to_add.area*2 - 1, 1))
    end
    
    local sliders = templates.flex(valid_sliders, "customize_effect_sliders", false, UI.ALIGNMENT.Start, UI.ALIGNMENT.Start, 5, 5)
    
    ambient.playSound('menu click')

    local layout = {
        name = "customize_effect_ui",
        type = UI.TYPE.Flex,
        props = {
            horizontal = false,
        },
        content = UI.content {
            {
                props = {
                    size = v2(window_size[1], titleHeight),
                },
                content = ui.content {
                    {
                        template = I.UIToolkit.Templates.header(),
                        props = {
                            text = 'Customize Effect:',
                            textSize = theme.Sizes.textNormal + 2,
                            position = v2(5, 5),
                        },
                    },
                    effect_cost
                },
            },
            effect_icon_element,
            range,
            sliders,
            buttons,
        }
    }

    customize_effect_ui._closeListPopup = I.UIToolkit.Popups.show {
        body = layout,
    }
end

function customize_effect_ui.closePopup()
    if not customize_effect_ui._closeListPopup then return end
    customize_effect_ui._closeListPopup()
    customize_effect_ui._closeListPopup = nil
end

return customize_effect_ui