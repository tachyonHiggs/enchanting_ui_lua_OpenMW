---@omw-context player
local UI = require('openmw.ui')
local I = require('openmw.interfaces')
local Util = require('openmw.util')
local v2 = Util.vector2
local async = require('openmw.async')
local ambient = require('openmw.ambient')
local auxUi = require("openmw_aux.ui")

local templates = {}


-- Helper fncs
templates.make_border = function(size, alpha, properties)
    properties = properties or {}
    properties.anchor = properties.anchor or v2(0,0)
    properties.relativePosition = properties.relativePosition or v2(0,0)
    return {
        template = I.MWUI.templates.borders,
        type = UI.TYPE.Image,
        props = {
            resource = UI.texture({
            path = "black"
            }),
            alpha = alpha,
            size = size,
            anchor = properties.anchor,
            properties.relativePosition,
        }
    }
end

templates.padding = function(x, y, x_r, y_r)

    local prop
    if x or y then
        prop = {
            size = Util.vector2(x, y)
        }
    else 
        prop = {
            relativeSize = Util.vector2(x_r, y_r),
        }
    end
    return {
        type = UI.TYPE.Widget,
        props = prop
    }
end

function templates.deepCopy(original)
    if type(original) ~= "table" then
        return original
    end

    local copy = {}

    for key, value in pairs(original) do
        copy[templates.deepCopy(key)] = templates.deepCopy(value)
    end

    return copy
end


---@param items table
---@param name string
---@param horizontal boolean
---@param arrange number
---@param align number
---@param gap_x number
---@param gap_y number
---@param size openmw.util.Vector2?
---@param anchor openmw.util.Vector2?
---@param relativePosition openmw.util.Vector2?
---@return table
templates.flex = function(items, name, horizontal, arrange, align, gap_x, gap_y, size, anchor, relativePosition)

    -- defaults
    arrange = arrange or UI.ALIGNMENT.Start
    align = align or UI.ALIGNMENT.Start

    local autoSize = false
    if not size then
        autoSize = true
        size = v2(1,1)
    end
    if not anchor then
        anchor = v2(0, 0)
    end
    if not relativePosition then
        relativePosition = v2(0.5, 0.5)
    end
    if gap_x == nil then
        gap_x = 1
    end
    if gap_y == nil  then
        gap_y = 1
    end

    local padding = {}

    -- Pad individual items
    local individual_padded_content = {}
    
    if horizontal then
        -- Horizontal list, first add padding above and below to individual items
        padding = templates.padding(1, gap_y)
    else
        -- Vertical list, first add padding infront and behind to individual items
        padding = templates.padding(gap_x, 1)
    end

    for index, item in ipairs(items) do
        if item == nil then
            print("Item at index: ", index, " is nil")
        else 
            local item_flex = {
                name = name .. "_item_" .. index,
                type = UI.TYPE.Flex,
                props = {
                    horizontal = not horizontal,
                    arrange = arrange,
                    align = align,
                    autoSize = true,
                    anchor = anchor,
                    relativePosition = relativePosition,
                    visible = true,
                },
                content = UI.content {
                    padding,
                    item,
                    padding
                }
            }
            table.insert(individual_padded_content, item_flex)
        end
    end

    -- create main horizontal or vertical with padding
    local content = {}
    if horizontal then
        padding = templates.padding(gap_x, 1)
    else
        padding = templates.padding(1, gap_y)
    end

    table.insert(content, padding)
    for index, item in ipairs(individual_padded_content) do
        if item == nil then
            print("Item at index: ", index, " is nil")
        else 
            table.insert(content, item)
            table.insert(content, padding)
        end
    end

    return 
    {
        name = name,
        type = UI.TYPE.Flex,
        props = {
            horizontal = horizontal,
            arrange = arrange,
            align = align,
            autoSize = autoSize,
            size = size,
            anchor = anchor,
            relativePosition = relativePosition,
            visible = true,
        },
        content = UI.content {
            table.unpack(content)
        }
    }
end


templates.text_output = {}
templates.text_output.new = function(name, text_length, padding_length, default_text, text_align_h, tooltip_text, tooltip_element)

    local text_output = {}

    text_output.name = name
    text_output.text = default_text or ""
    text_output.text_length = text_length
    text_output.padding_length = padding_length
    text_output.text_align_h = text_align_h or UI.ALIGNMENT.Start

    text_output.has_tooltip = false
    if tooltip_text then
        -- print("text_input has tooltip")
        text_output.has_tooltip = true
        text_output.tooltip_text = tooltip_text
        text_output.tooltip_element = tooltip_element -- pass by reference
    end

    text_output.output = {
        name = "output",
        type = UI.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = text_output.text,
            textSize = 20,
            size = v2(text_length, 20),
            textAlignH = text_output.text_align_h,
        }
    }

    function text_output:set_text(text)
        self.text = text
        self.output.props.text = text
    end

    function text_output:show()
        self.ui.props.visible = true
    end
    function text_output:hide()
        self.ui.props.visible = false
    end

    function text_output:create()

        local tooltip_events = {}
        if self.has_tooltip then
            tooltip_events = text_output.tooltip_element:get_events(self)
        end

        self.ui = {
            name = self.name .. "_text_output",
            type = UI.TYPE.Flex,
            props = {
                horizontal = true,
                arrange = UI.ALIGNMENT.Start,
                align = UI.ALIGNMENT.Start,
                visible = true,
            },
            content = UI.content {
                {
                    name = "name",
                    type = UI.TYPE.Text,
                    template = I.MWUI.templates.textNormal,
                    props = {
                        text = self.name,
                        textSize = 20,
                    }
                },
                templates.padding(self.padding_length, 0),
                self.output,
            }, events = tooltip_events
        }

        return self.ui
    end

    return text_output
end

return templates