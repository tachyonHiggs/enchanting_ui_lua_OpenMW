local I = require('openmw.interfaces')
local auxUi = require("openmw_aux.ui")

local enchanting_ui = require("scripts.enchanting_ui.enchanting_ui")

-- For the menu settings tab
I.Settings.registerPage ({
    key = 'enchanting_ui_page',
    l10n = 'enchanting_ui',
    name = 'Enchanting Remastered',
    description = 'Enchanting Remastered Description and Settings.',
})


local function show()
    enchanting_ui.update_lists()
end
    
local function hide()
    enchanting_ui.destroy()
end

local function onMouseWheel()
    
end

local function onFrame()
    
end

local function onSave()
    
end

local function onLoad(data)
    -- Register Window and reset
    I.UI.registerWindow('EnchantingDialog', show, hide)
    enchanting_ui.reset()
end

return {
    engineHandlers = {
        onInit = onLoad,
        onLoad = onLoad,
        onSave = onSave,
        onMouseWheel = onMouseWheel,
        onFrame = onFrame,
    },
    eventHandlers = {
        UiModeChanged = function(data)
            print('UiModeChanged from', data.oldMode , 'to', data.newMode, '('..tostring(data.arg)..')')
            -- TODO: use arg here to make it the soul gem
            if data.newMode == 'Enchanting' then
                -- This handles displaying the actual UI depending on which one is appropiate
                if data.oldMode == 'Dialogue' then
                    enchanting_ui.show(true)
                else 
                    enchanting_ui.show(false)
                end
                
            end

        end,
        update_enchant_ui_after_object_removed = function(data)
            print("update_enchant_ui_after_object_removed")
            enchanting_ui.update_lists()
        end,
    }
}
