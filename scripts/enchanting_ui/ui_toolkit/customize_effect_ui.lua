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

local function generate_slider(name, text_width, scrollBar_element)
    local theme = I.UIToolkit.getTheme()

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
    return templates.flex({text_element, scrollBar_element}, name.."_slider", true, UI.ALIGNMENT.End, UI.ALIGNMENT.End, 5, 5)
    
end

---@param wnd EnchantingHandler
function customize_effect_ui.show_customize_effect_ui(wnd, effect_id, modify_effect, index_to_modify)
    print("customize_effect_ui.show_customize_effect_ui")

    -- First reset this guy
    enchanter.reset_effect_to_add()
    enchanter.effect_to_add.id = effect_id
    enchanter.effect_to_modify = modify_effect

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
        local cost = enchanter.get_effect_to_add_cost()
        enchanter.effect_to_add.cost = cost
        effect_cost.props.text = "Effect Cost: " .. string.format("%.1f", cost)
        print("effect cost: ", cost)
        -- TODO: how to update display text?
    end

    local constant_effect_constant_magnitude = false
    if storage.globalSection("constant_enchanting_ui"):get("constant_effect_constant_magnitude") then
        constant_effect_constant_magnitude = true
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
            wnd:modify_effect(index_to_modify)
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
    enchanter.effect_to_add.range = valid_ranges[1]
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
    -- however, if constant effect only self is allowed
    if enchanter.enchantment.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect then
        print("Constant Effect")
        force_no_duration = true
        force_no_area = true
    end
    
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
                update_effect_to_add_cost()
            end,
        }
    local magnitudeMin = generate_slider(
        "Magnitude Min:",
        125,
        magnitudeMin_scrollbar.element
    )
    local magnitudeMax_scrollbar = I.UIToolkit.Components.scrollBar{
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
                update_effect_to_add_cost()
            end,
        }
    local magnitudeMax = generate_slider(
        "Magnitude Max:",
        125,
        magnitudeMax_scrollbar.element
    )
    if core.magic.effects.records[enchanter.effect_to_add.id].hasMagnitude then
        table.insert(valid_sliders, magnitudeMin)
        table.insert(valid_sliders, magnitudeMax)
    end

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
                update_effect_to_add_cost()
            end,
    }
    local duration = generate_slider(
        "Duration:",
        125,
        duration_scrollbar.element
    )
    if core.magic.effects.records[enchanter.effect_to_add.id].hasDuration and not force_no_duration then
        table.insert(valid_sliders, duration)
    end
    
    area_scrollbar = I.UIToolkit.Components.scrollBar{
        horizontal = true,
        length = 250,
        handleSize = 25,
        scrollStep = 2,
        maxScroll = 99,
        onScroll = function(position)
            local value = math.floor(position/2) + 1
            print('Value:', value)
            enchanter.effect_to_add.duration = value
            update_effect_to_add_cost()
        end,
    }
    local area = generate_slider(
        "Area:",
        125,
        area_scrollbar.element
    )
    if not force_no_area then -- Will handle enchanter.effect_to_add.range ~= core.magic.RANGE.Self on range change
        table.insert(valid_sliders, area)
    end
    
    local sliders = templates.flex(valid_sliders, "customize_effect_sliders", false, UI.ALIGNMENT.Start, UI.ALIGNMENT.Start, 5, 5)
    
    if modify_effect then
        -- TODO: load current values to sliders/range
    end

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