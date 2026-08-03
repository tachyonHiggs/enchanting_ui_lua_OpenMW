local UI = require('openmw.ui')
local I = require('openmw.interfaces')
local Util = require('openmw.util')
local v2 = Util.vector2
local async = require('openmw.async')
local ambient = require('openmw.ambient')
local auxUi = require("openmw_aux.ui")

local templates = {}

-- TODO: replace text size with a passed in parameter

-- Helper fncs
templates.make_border = function(size, alpha)
    return {
        template = I.MWUI.templates.bordersThick,
        type = UI.TYPE.Image,
        props = {
            resource = UI.texture({
            path = "black"
            }),
            alpha = alpha,
            size = size,
            anchor = v2(0.5, 0.5),
            relativePosition = v2(0.5, 0.5),
        }
    }
end

templates.padding = function(x, y, x_r, y_r)

    local prop
    if x or y then
        prop = {
            size = Util.vector2(x, y),
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

    arrange = arrange or UI.ALIGNMENT.Start
    align = align or UI.ALIGNMENT.Start

    local autoSize = false
    if not size then
        autoSize = true
        size = v2(1,1)
    end
    if not anchor then
        anchor = v2(0.5, 0.5)
    end
    if not relativePosition then
        relativePosition = v2(0.5, 0.5)
    end

    print("templates.flex")

    local content = {}
    table.insert(content, templates.padding(gap_x, gap_y))
    for index, item in ipairs(items) do
        if item == nil or item == {} then
            print("Item at index: ", index, " is nil")
        else 
            table.insert(content, item)
            table.insert(content, templates.padding(gap_x, gap_y))
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

templates.window = {}
---@param name string
---@param template number
---@param properties table
---@param content table?
templates.window.new = function(name, type, template, properties, content) 
    print("templates.window.new: ", name)

    local window = {}
    window.name = name or ""
    window.type = type
    window.template = template or I.MWUI.templates.boxSolid
    window.properties = properties or {}
    window.properties.visible = window.properties.visible or true
    window.created = false -- Used to communicate to external scripts
    window.content = content or {}

    function window:show()
        if self.type == UI.TYPE.Widget then
            self.ui.layout.props.visible = true
        elseif self.type == UI.TYPE.Container then
            self.ui.layout.template = self.template
        end
        self:update()
    end

    function window:hide()
        if self.type == UI.TYPE.Widget then
            self.ui.layout.props.visible = false
        elseif self.type == UI.TYPE.Container then
            self.ui.layout.template = I.MWUI.templates.disabled
        end
        self:update()
    end

    function window:set_content(content)
        self.ui.layout.content = content
        self:update()
    end

    function window:create()
        print("templates.window.create: ", self.name)
        window.created = true

        self.ui = UI.create{
            name = self.name .. "_window",
            layer = "Windows",
            type = self.type,
            template = self.template,
            props = properties,
            content = UI.content{
                table.unpack(self.content)
            }
        }
        self:update()
    end

    function window:update()
        print("window:update")
        if self.ui.layout then
            self.ui:update()
        end
    end

    function window:destroy()
        window.created = false 

        if self.ui.layout then
            auxUi.deepDestroy(self.ui)
            self.ui:update()
        end
    end

    return window
end

-- Templates
templates.button = {}
templates.button.new = function(name, on_click_fnc, size_x, size_y)

    local button = {}

    button.name = name
    button.size_x = size_x
    button.size_y = size_y

    button.name_element = {
        name = button.name .. "_btn",
        type = UI.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = button.name,
            textSize = 20,
            size = v2(button.size_x, 20),
            autoSize = false,
            anchor = v2(0.05, 0), -- TODO: magic number here, for some reason the buttons won't be centered otherwise
            relativePosition = v2(0.5, 0.5),
            textAlignH = UI.ALIGNMENT.Center,
            textAlignV = UI.ALIGNMENT.Center,
        },
        events = {
            mouseClick = async:callback(function(...)
                ambient.playSound("menu click")

                if on_click_fnc then
                    return on_click_fnc(...)
                end
            end)
        }
    }

    function button:show()
        self.ui.props.visible = true
        self.ui.content = UI.content {
            templates.padding(self.size_x, self.size_y),
            button.name_element,
        }
    end

    function button:hide()
        self.ui.props.visible = false
        self.ui.content = UI.content {}
    end

    function button:set_text(text)
        button.name_element.props.text = text
    end

    function button:create()

        self.ui = {
            name = self.name .. "_btn_border",
            type = UI.TYPE.Container,
            template = I.MWUI.templates.bordersThick,
            props = {
                visible = true,
            },
            content = UI.content {
                templates.padding(self.size_x, self.size_y),
                button.name_element,
            }
        }

        return self.ui
    end

    return button
end

templates.text_input = {}
templates.text_input.new = function(name, text_length, on_text_changed_fnc, update_ui)

    local text_input = {}

    print("text_input new: ", name)

    text_input.name = name
    text_input.text = ""
    text_input.text_length = text_length
    text_input.update_ui = update_ui or nil

    text_input.input = {
        name = name .. "_input",
        type = UI.TYPE.TextEdit,
        template = I.MWUI.templates.textEditLine,
        props = {
            text = text_input.text,
            textSize = 20,
            size = v2(text_length, 20),
        },
        events = {
            textChanged = async:callback(function(text)
                -- Keep the stored text in sync
                text_input.text = text_input.input.props.text
                print("textChanged event: ", text)
                if on_text_changed_fnc then
                    on_text_changed_fnc(text)
                end
            end)
        }
    }

    text_input.input_bar = templates.flex(
        {templates.padding(text_length, 24), 
        {
            name = name .. "_input_bar",
            type = UI.TYPE.Image,
            template = I.MWUI.templates.horizontalLine,
            props = {
                size = v2(text_length, 1),
            },
        }},
        "input_bar_flex", false, UI.ALIGNMENT.Center,UI.ALIGNMENT.End, 1, 1, v2(text_length, 25), v2(0,0), v2(0,0))

    text_input.input_ui = {
        name = name .. "_input_ui",
        type = UI.TYPE.Container,
        content = UI.content{
            text_input.input_bar,
            text_input.input,
        }
    }
    

    function text_input:set_text(text)
        self.text = text
        self.input.props.text = text
    end

    function text_input:get_text()
        return self.text
    end

    function text_input:clear()
        self:set_text("")
    end

    function text_input:show()
        self.ui.props.visible = true
    end

    function text_input:hide()
        self.ui.props.visible = false
    end

    function text_input:create()

        print("text_input create: ", self.name)

        local name_element = {
            name = self.name .. "_name",
            type = UI.TYPE.Text,
            template = I.MWUI.templates.textNormal,
            props = {
                text = self.name,
                textSize = 20,
            }
        }

        local refresh_element = {
            name = "refresh",
            type = UI.TYPE.Image,
            template = I.MWUI.templates.borders,
            props = {
                resource = UI.texture({
                    -- TODO: this icon lol
                    path = "Textures/menu_bar_yellow.dds"
                }),
                alpha = 1,
                size = v2(20,20),
            },
            events = {
                mouseClick = async:callback(function()
                    text_input:clear()
                    if update_ui then
                        text_input.text = text_input.input.props.text
                        if on_text_changed_fnc then
                            on_text_changed_fnc()
                        end
                        update_ui()
                    end
                end),
            }
        }

        self.ui = templates.flex({name_element, self.input_ui, refresh_element}, "text_input_flex", true, UI.ALIGNMENT.Start, UI.ALIGNMENT.Start, 5, 5)

        return self.ui
    end

    return text_input
end

templates.text_output = {}
templates.text_output.new = function(name, text_length, padding_length, default_text, text_align_h)

    local text_output = {}

    text_output.name = name
    text_output.text = default_text or ""
    text_output.text_length = text_length
    text_output.padding_length = padding_length
    text_output.text_align_h = text_align_h or UI.ALIGNMENT.Start

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
            }
        }

        return self.ui
    end

    return text_output
end

templates.text_image = {}
templates.text_image.new = function(name, image_size, padding_length, on_image_mouse_click)

    local text_image = {}

    text_image.name = name
    text_image.image_size = image_size
    text_image.padding_length = padding_length
    text_image.default_image = "black"

    text_image.image = {
        name = "image",
        type = UI.TYPE.Image,
        template = I.MWUI.templates.borders,
        props = {
            resource = UI.texture({
                path = text_image.default_image
            }),
            alpha = 1,
            size = image_size,
        },
        events = {
            mouseClick = async:callback(on_image_mouse_click),
        }
    }

    function text_image:set_image(path)
        self.image.props.resource = UI.texture({
            path = path
        })
    end

    function text_image:reset_image()
        self:set_image(self.default_image)
    end

    function text_image:show()
        self.ui.props.visible = true
    end

    function text_image:hide()
        self.ui.props.visible = false
    end

    function text_image:create()
        self.ui = {
            name = self.name .. "_text_image",
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
                        autoSize = false,
                        size = v2(45, 20)
                    }
                },
                templates.padding(self.padding_length, 0),
                self.image,
            }
        }

        return self.ui
    end

    return text_image
end

templates.list = {}
templates.list.new = function(name, list_size, update_target, generate_items, header_info, basic_props, enable_search_bar, enable_divider)

    local list = {}

    list.padding = 10

    -- Assign default basic props if not assigned
    list.basic_props = basic_props
    if list.basic_props == nil or list.basic_props == {} then
        list.basic_props = {}
        list.basic_props.alignment = UI.ALIGNMENT.Start
        list.basic_props.relativePosition = v2(0.5, 0.5)
        list.basic_props.border = I.MWUI.templates.boxSolid
    end

    list.name = name

    function list:update_item_indices()
        print("update_item_indices")
        for index, item in ipairs(self.items) do
            -- print(item, " ", index)
            item.userData = item.userData or {}
            item.userData.index = index
        end
        if list.update_target then
            list.update_target()
        end
    end

    print("Creating new list called: ", name)
    list.size = list_size
    list.update_target = update_target
    print("udpate target is: ", list.update_target)
    list.items = generate_items() or {}
    list:update_item_indices()

    list.sort_descending = 0
    list.sort_ascending = 1
    list.sort_descending_texture = UI.texture({
        path = "Textures/menu_scroll_down.dds",
        offset = v2(-5, -5), -- TODO: what to set this as to avoid magic nums?
    }) 
    list.sort_ascending_texture = UI.texture({
        path = "Textures/menu_scroll_up.dds",
        offset = v2(-5, -5), -- TODO: what to set this as to avoid magic nums
    }) 

    list.header = {}
    list.has_header = false

    list.name_element = {
        name = "name",
        type = UI.TYPE.Text,
        template = I.MWUI.templates.textHeader,
        props = {
            text = list.name,
            textSize = 22,
            textAlignH = list.basic_props.alignment,
            textAlignV = list.basic_props.alignment,
        }
    }
    if list.name == "" then
        list.name_element = {}
    end
    
    list.column_elements = {}
    list.search_text_input = {}
    
    if header_info then

        -- Header constants
        list.sort_btn_size = 20
        function list.get_sort_btn_index(column_index)
            return column_index*3 - 1 -- Gets the 
        end

        -- Verify inputs are valid
        if #header_info.column_names ~= #header_info.column_widths and #header_info.column_names ~= #header_info.enable_column_sortings then
            print("Error: incorrectly sized column names and column sizes")
            return
        end

        -- Setup default values
        list.has_header = true
        list.default_sort_column = 1
        for i = 1, #header_info.enable_column_sortings do
            if header_info.enable_column_sortings[i] then
                print("setting the ", i, " as the default column to sort")
                list.default_sort_column = i
                break
            end
        end
        list.default_sort_direction = list.sort_descending
        list.sort_column = list.default_sort_column
        list.sort_direction = list.default_sort_direction

        -- Create each column header and sort button if applicable
        for index, column_name in ipairs(header_info.column_names) do

            print(column_name)
            local column_width = header_info.column_widths[index]
            local column_sort = {}

            local column_element = {
                name = "name"..index,
                type = UI.TYPE.Text,
                template = I.MWUI.templates.textNormal,
                props = {
                    text = column_name,
                    textSize = 20,
                    size = v2(column_width - list.sort_btn_size, 20),
                    autoSize = false
                },
            }
            table.insert(list.column_elements, column_element)

            if header_info.enable_column_sortings[index] then
                print("allow column sorting: ", header_info.enable_column_sortings[index])
                column_sort = {
                    name = "direction"..index,
                    type = UI.TYPE.Image,
                    template = I.MWUI.templates.borders,
                    props = {
                        resource = list.sort_descending_texture,
                        alpha = 1,
                        size = v2(list.sort_btn_size,list.sort_btn_size),
                    },
                    events = {
                        mouseClick = async:callback(function ()
                            list:on_sort_clicked(index)
                        end),
                    }
                }
            else
                column_sort = templates.padding(list.sort_btn_size,list.sort_btn_size)
            end

            table.insert(list.column_elements, column_sort)
            table.insert(list.column_elements, templates.padding(list.padding, list.padding))
        end
        
        if enable_search_bar then
            print("Adding search bar")

            local function on_search_text_changed(text)
                print("Text changed on search: ", text)
                list.text_to_search = text
            
                -- Search all strings in column 2 for now
                for index, item in ipairs(list.items) do
                    if text then
                        if item.userData.info[2]:lower():find(text:lower(), 1, true) then
                            print("found: ", text)
                            list:show_item(index)
                        else 
                            list:hide_item(index)
                        end
                    else
                        list:show_item(index)
                    end
                end
            end

            -- TODO: search icon or word?
            list.search_text_input = templates.text_input.new("Search", header_info.column_widths[#header_info.column_widths], on_search_text_changed, list.update_target)
            table.insert(list.column_elements, list.search_text_input:create())
        end

        list.header = {
            name = "column_header",
            type = UI.TYPE.Flex,
            props = {
                horizontal = true,
                arrange = list.basic_props.alignment,
                align = list.basic_props.alignment,
            },
            content = UI.content (
                list.column_elements
            ),
        }
        
    end

    print("generating items container")

    list.items_container = {
        name = "items",
        type = UI.TYPE.Flex,
        props = {
            horizontal = false,
            arrange = list.basic_props.alignment,
            align = list.basic_props.alignment,
            size = list_size,
        },
        content = UI.content{
            table.unpack(list.items)
        }
    }

    function list:add_item(item)
        print("adding item: ", item.name)
        table.insert(self.items, item)

        -- rebuild the UI content
        self.items_container.content = UI.content({
            table.unpack(list.items)
        })
        list:update_item_indices()
    end

    function list:remove_item(index)
        print("removing item: ", index)
        table.remove(self.items, index)

        -- rebuild the UI content
        self.items_container.content = UI.content({
            table.unpack(list.items)
        })
        list:update_item_indices()
    end

    function list:update_item(index, new_item)
        if not self.items[index] then
            return false
        end

        self.items[index] = new_item
        self.items_container.content = UI.content({
            table.unpack(list.items)
        })
        list:update_item_indices()
        return true
    end

    function list:reset_sort()
        if not list.has_header then
            return
        end
        -- Reset UI elements
        list.column_elements[list.get_sort_btn_index(list.sort_column)].template = I.MWUI.templates.borders
        list.column_elements[list.get_sort_btn_index(list.sort_column)].props.resource = list.sort_descending_texture

        list.sort_column = list.default_sort_column
        list.sort_direction = list.default_sort_direction
        list:update_item_indices()
    end

    function list:regenerate_items()
        self.items = generate_items() or {}

        self.items_container.content = UI.content({
            table.unpack(list.items)
        })

        list:reset_sort()
    end

    function list:sort_items()
        print("list:sort_items")

        local function sort_function(a, b)
            local result
            if list.sort_direction == list.sort_descending then
                result = a.userData.info[list.sort_column] < b.userData.info[list.sort_column]
            else
                result = a.userData.info[list.sort_column] > b.userData.info[list.sort_column]
            end

            return result
        end
        
        table.sort(self.items, sort_function)

        self.items_container.content = UI.content({
            table.unpack(list.items)
        })
        list:update_item_indices()

    end

    function list:on_sort_clicked(index)

        print("list:on_sort_clicked for index: ", index)
        
        ambient.playSound("menu click")
        
        --Normal arrow behavior
        list.column_elements[list.get_sort_btn_index(list.sort_column)].template = I.MWUI.templates.borders
        list.sort_column = index
        list.column_elements[list.get_sort_btn_index(list.sort_column)].template = I.MWUI.templates.bordersThick
        list.sort_direction =( list.sort_direction + 1) % 2 -- toggle direction

        -- Update sort UI
        if list.sort_direction == list.sort_ascending then
            list.column_elements[list.get_sort_btn_index(list.sort_column)].props.resource = list.sort_ascending_texture
        else
            list.column_elements[list.get_sort_btn_index(list.sort_column)].props.resource = list.sort_descending_texture
        end

        -- TBH my superior system where you first have to click on a arrow to make it active and then it sorts 
        -- if list.sort_column == index then
        --     list.column_elements[index*2].template = I.MWUI.templates.bordersThick
        --     list.sort_direction =( list.sort_direction + 1) % 2 -- toggle direction
        --     if list.sort_direction == list.sort_ascending then
        --         list.column_elements[index*2].props.resource = list.sort_ascending_texture
        --     else
        --         list.column_elements[index*2].props.resource = list.sort_descending_texture
        --     end
        -- else
        --     list.column_elements[index*2].template = I.MWUI.templates.bordersThick
        --     list.column_elements[list.sort_column*2].template = I.MWUI.templates.borders
        --     list.sort_column = index
        --     -- Don't toggle direction
        -- end

        --Now sort list items by column and direction
        list:sort_items()

        if list.update_target then
            list.update_target()
        end
        
    end

    function list:hide_item(index)
        print("list:hide_item at index: ", index)
        
        self.items[index].props.visible = false 
        self.items[index].props.autoSize = false 
        self.items[index].props.size = v2(0,0)

        self.items_container.content = UI.content({
            table.unpack(self.items)
        })
        if list.update_target then
            list.update_target()
        end
    end

    function list:show_item(index)
        print("list:show_item at index: ", index)
        self.items[index].props.visible = true 
        self.items[index].props.autoSize = true 

        self.items_container.content = UI.content({
            table.unpack(self.items)
        })
        if list.update_target then
            list.update_target()
        end
    end

    function list:set_input_text() 
        list.search_text_input:set_text(list.text_to_search or "")
    end

    function list:clear()
        self.items = {}
        self.items_container.content = UI.content({})
    end

    function list:create()
        print("list:create")

        self.ui = {
            name = self.name .. "_list",
            type = UI.TYPE.Flex,
            props = {
                horizontal = false,
                arrange = list.basic_props.alignment,
                align = list.basic_props.alignment,
                size = v2(0,20) + self.size,
                relativePosition = list.basic_props.relativePosition
            },
            content = UI.content {
                list.name_element,
                list.header,
                {
                    name = "border",
                    template = list.basic_props.border,
                    props = {
                        size = self.size,
                    },
                    content = UI.content {
                        self.items_container
                    }
                }
            }
        }
        return self.ui
    end

    print("returning list")
    return list
end


-- TODO: take size input
templates.slider = {}

---@param text string
---@param max number
---@param min number
---@param start number
---@param update_target function?
---@param value_to_set_fnc function?
---@param on_slider_moved function?
---@return table
templates.slider.new = function(text, max, min, start, update_target, value_to_set_fnc, on_slider_moved)
    local slider = {}

    slider.ui = {}
    slider.text = text -- sets the slider name and starting text value

    slider.value = start
    slider.value_text = tostring(slider.value)

    slider.min = min
    slider.max = max
    slider.interval = 1 -- hard coded
    slider.background_bar_length = 220

    local backgroundWidth = 220
    local thumbWidth = 20
    slider.bar_padding = (thumbWidth / 2) / backgroundWidth

    slider.value_to_set_fnc = value_to_set_fnc
    slider.on_slider_moved = on_slider_moved

    slider.update_target = update_target

    function slider:value_to_position(value)
        print("Slider value_to_position")
        local t = (value - self.min) / (self.max - self.min)

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
            size = v2(20,20),
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
            textSize = 20,
            size = v2(60,20),
            autoSize = false
        }
    }

    function slider:get_value()
        print("Slider get_value")
        return slider.value
    end

    function slider:set_value(value)
        print("set_value")

        self.value = value

        print("Setting slider to: ", value)
        
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
        print("Moving slider right by: ", relativeInterval)

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
        print("slider:on_background_bar_clicked at position: ", position)

        -- Convert position to value
        local value = self.min + position*(self.max - self.min)/self.background_bar_length
        print(value)

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
            },
            content = UI.content {
                {
                    name = self.text  .. "_name",
                    type = UI.TYPE.Text,
                    template = I.MWUI.templates.textNormal,
                    props = {
                        text = self.text .. ":   ",
                        textSize = 20,
                        size = v2(140, 20),
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
        self.ui.props.visible = false
        self.ui.props.autoSize = false
        self.ui.props.size = v2(0,0)

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