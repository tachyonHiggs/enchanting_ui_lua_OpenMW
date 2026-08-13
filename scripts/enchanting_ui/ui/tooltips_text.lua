-- Tooltip text rules
--  1. Place a space at the front of each line for fake padding.
--  2. Place a space at the end of each line for fake padding.
--  3. Use \n for a new line
--  4. Break up text as desired, does not have to be a full sentence per line

local tooltips_text = {}

-- Buttons
tooltips_text.add_effect_btn = " This initiates a pop-up showing \n all available magic effects "
tooltips_text.cast_type_btn = " Depending on the item selected for enchanting, \n iterrates through the valid cast types "

-- Text inputs
tooltips_text.name_input = " The name the enchanted item shall take "

-- Text outputs
tooltips_text.cost = " Effect to add cost "
tooltips_text.stats_enchantment = " Enchantment "
tooltips_text.stats_charge = " Charge "
tooltips_text.price = " Price "
tooltips_text.chance = " Chance "

-- Unused
tooltips_text.create_btn = " Attempts to create or buy an enchanted item, \n if all menu inputs are valid "
tooltips_text.cancel_btn = " Cancel enchanting and close the menu "

return tooltips_text