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
---@param size userdata?
---@param anchor userdata?
---@param relativePosition userdata?
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


templates.slider = {}

---@param text string
---@param max number
---@param min number
---@param start number
---@param update_target function?
---@param value_to_set_fnc function?
---@param on_slider_moved function?
---@return table
templates.slider.new = function(text, max, min, start, update_target, value_to_set_fnc, on_slider_moved, text_length, value_length, background_bar_length, anchor, relativePosition)
    local slider = {}

    slider.ui = {}
    slider.text = text -- sets the slider name and starting text value

    slider.value = start
    slider.value_text = tostring(slider.value)
    slider.text_size = 20
    slider.visible = false

    slider.min = min
    slider.max = max
    slider.interval = 1 -- hard coded
    slider.background_bar_length = background_bar_length
    if not slider.background_bar_length then
        slider.background_bar_length = 220
    end

    slider.text_length = text_length
    if not slider.text_length then
        slider.text_length = 140
    end
    slider.value_length = value_length
    if not slider.value_length then
        slider.value_length = 60
    end

    slider.anchor = anchor
    if not slider.anchor then
        slider.anchor = v2(0,0)
    end
    slider.relativePosition = relativePosition
    if not slider.relativePosition then
        slider.relativePosition = v2(0,0)
    end

    local thumbWidth = 20
    slider.bar_padding = (thumbWidth / 2) / slider.background_bar_length
    
    slider.value_to_set_fnc = value_to_set_fnc
    slider.on_slider_moved = on_slider_moved

    slider.update_target = update_target

    function slider:get_bar_width()
        local bar_width = 0
        if slider.max <= slider.min then
            bar_width = slider.background_bar_length
        else
            bar_width = math.max( slider.background_bar_length / (100*(slider.max - slider.min)), 20)
        end
        print("Slider:get_bar_width: ", bar_width)
        return bar_width
    end
    slider.bar_width = slider:get_bar_width()

    function slider:value_to_position(value)
        print("Slider value_to_position")
        local t = 0
        if self.max <= self.min then
            t = 0.5
        else
            t = (value - self.min) / (self.max - self.min)
        end
        local x = self.bar_padding +
                t * (1 - 2 * self.bar_padding)

        return v2(x, 0)
    end
    
    slider.bar = {
        name = "bar",
        template = I.MWUI.templates.borders,
        type = UI.TYPE.Image,
        props = {
            resource = UI.texture({
                path = "Textures/menu_bar_yellow.dds"
            }),
            alpha = 1,
            size = v2(slider.bar_width, slider.text_size),
            anchor = v2(0.5,0),
            relativePosition = slider:value_to_position(start)
        }
    }

    slider.value_element = {
        name = "value",
        type = UI.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = slider.value_text,
            textSize = slider.text_size,
            size = v2(slider.value_length, slider.text_size),
            autoSize = false
        }
    }

    function slider:get_value()
        -- print("Slider get_value")
        return slider.value
    end

    function slider:set_value(value)
        -- print("set_value")

        self.value = value

        -- print("Setting slider to: ", value)
        
        if self.value < self.min then
            self.value = self.min
        elseif self.value > self.max then
            self.value = self.max
        end
        self.bar.props.relativePosition = slider:value_to_position(self.value)

        self.value_text = tostring(self.value)
        self.value_element.props.text = self.value_text

        if self.value_to_set_fnc then
            self.value_to_set_fnc(self.value)
        end

        if self.update_target then
            self.update_target()
        end
    end

    function slider:set_max_min(max, min)
        print('slider:set_max_min')

        if max then
            print("New slider max is: ", max)
            self.max = max
        end
        if min then
            print("New slider min is: ", min)
            self.min = min
        end
        self.bar_width = self:get_bar_width()
        self.bar.props.size = v2(slider.bar_width, 20)
        
        self:set_value(self.min)
    end

    function slider:move_left()

        ambient.playSound('menu click')

        local relativeInterval = self.interval / (self.max - self.min + 1)
        print("Moving slider left by: ", relativeInterval)

        self.value = self.value - self.interval
        if self.value < self.min then
            self.value = self.min
        end
        self.bar.props.relativePosition = slider:value_to_position(self.value)

        self.value_text = tostring(self.value)
        self.value_element.props.text = self.value_text

        if self.value_to_set then
            self.value_to_set = self.value
        end

        if self.value_to_set_fnc then
            self.value_to_set_fnc(self.value)
        end

        if self.on_slider_moved then
            self.on_slider_moved(self.text, self.value)
        end

        if self.update_target then
            self.update_target()
        end
    end

    function slider:move_right()

        ambient.playSound('menu click')

        local relativeInterval = self.interval / (self.max - self.min + 1)
        -- print("Moving slider right by: ", relativeInterval)

        self.value = self.value + self.interval
        if self.value > self.max then
            self.value = self.max
        end
        self.bar.props.relativePosition = slider:value_to_position(self.value)

        self.value_text = tostring(self.value)
        self.value_element.props.text = self.value_text

        if self.value_to_set_fnc then
            self.value_to_set_fnc(self.value)
        end

        if self.on_slider_moved then
            self.on_slider_moved(self.text, self.value)
        end

        if self.update_target then
            self.update_target()
        end
    end

    function slider:on_background_bar_clicked(position)
        -- print("slider:on_background_bar_clicked at position: ", position)

        -- Convert position to value
        local value = self.min + position*(self.max - self.min)/self.background_bar_length
        -- print(value)

        -- Check value is in bounds
        value = math.floor(value + 0.5)
        if value > self.max then
            value = self.max
        elseif value < self.min then
            value = self.min
        end

        -- Update slider to new position
        self:set_value(value)

        -- if set, call callback function on slider moved
        if self.on_slider_moved then
            self.on_slider_moved(self.text, self.value)
        end
    end

    function slider:create()
        self.ui = {
            name = self.text .. "_slider",
            type = UI.TYPE.Flex,
            props = {
                horizontal = true,
                arrange = UI.ALIGNMENT.Start,
                align = UI.ALIGNMENT.Start,
                visible = true,
                anchor = slider.anchor,
                relativePosition = slider.relativePosition,
            },
            content = UI.content {
                {
                    name = self.text  .. "_name",
                    type = UI.TYPE.Text,
                    template = I.MWUI.templates.textNormal,
                    props = {
                        text = self.text .. ":   ",
                        textSize = 20,
                        size = v2(slider.text_length, 20),
                        visible = true,
                        autoSize = false,
                    },
                    content = UI.content {}
                }, 
                self.value_element,
                {
                    name = "left",
                    template = I.MWUI.templates.borders,
                    type = UI.TYPE.Image,
                    props = {
                        resource = UI.texture({
                            path = "Textures/menu_scroll_left.dds",
                            offset = v2(-5, -5), -- TODO: what to set this as to avoid magic nums
                        }),
                        alpha = 1,
                        size = v2(20, 20),
                        
                    },
                    events = {
                        mouseClick = async:callback(function() self:move_left() end)
                    }
                },
                {
                    name = self.text  .. "_background_bar",
                    template = I.MWUI.templates.borders,
                    type = UI.TYPE.Image,
                    props = {
                        resource = UI.texture({
                            path = "black"
                        }),
                        alpha = 1,
                        size = v2(self.background_bar_length, 20),
                    },
                    content = UI.content {
                        self.bar
                    },
                    events = {
                        mousePress = async:callback(function(mouseEvent) self:on_background_bar_clicked(mouseEvent.offset.x) end)
                    }
                },
                {
                    name = "right",
                    template = I.MWUI.templates.borders,
                    type = UI.TYPE.Image,
                    props = {
                        resource = UI.texture({
                            path = "Textures/menu_scroll_right.dds",
                            offset = v2(-5, -5), -- TODO: what to set this as to avoid magic nums
                        }),
                        alpha = 1,
                        size = v2(20, 20),
                    },
                    events = {
                        mouseClick = async:callback(function() self:move_right() end)
                    }
                },
            }
        }
        return self.ui
    end

    function slider:hide() 
        print("hiding: ", self.text)
        if self.ui.props then
            self.ui.props.visible = false
            self.ui.props.autoSize = false
            self.ui.props.size = v2(0,0)
        end

        if self.update_target then
            self.update_target()
        end
    end

    function slider:show() 
        print("show: ", self.text)
        self.ui.props.visible = true
        self.ui.props.autoSize = true

        if self.update_target then
            self.update_target()
        end
    end

    return slider
end

return templates