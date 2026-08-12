-- Tooltip text rules
--  1. Place a space at the front of each line for fake padding.
--  2. Place a space at the end of each line for fake padding.
--  3. Use \n for a new line
--  4. Break up text as desired, does not have to be a full sentence per line

local tooltips_text = {}

tooltips_text.add_effect_btn = " This initiates a pop-up showing \n all available magic effects "
tooltips_text.cast_type_btn = " Depending on the item selected for enchanting, \n iterrates through the valid cast types "

-- Unused
tooltips_text.create_btn = " Attempts to create or buy an enchanted item, \n if all menu inputs are valid "
tooltips_text.cancel_btn = " Cancel enchanting and close the menu "

return tooltips_text