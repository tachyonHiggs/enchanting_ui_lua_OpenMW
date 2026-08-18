-- Tooltip text rules
--  1. Place a space at the front of each line for fake padding.
--  2. Place a space at the end of each line for fake padding.
--  3. Use \n for a new line
--  4. Break up text as desired, does not have to be a full sentence per line

local tooltips_text = {}

-- Buttons
tooltips_text.add_effect_btn = " This initiates a pop-up showing \n all available magic effects "
tooltips_text.cast_type_btn = " Selects the Enchantment Type "

-- Text inputs
tooltips_text.name_input = " The name the enchanted item shall take "

-- Text outputs
tooltips_text.cost = " Effect to add cost "

-- Stats panel
tooltips_text.stats_max_enchantment_pts = " The maximum Enchantment points this item can handle. \n Determined by the selected item "
tooltips_text.stats_in_use_enchantment_pts = " The used Enchantment points. \n Determined by the selected effects "

tooltips_text.stats_charge = " The Soul gem's charge. Determined by the Soul gem's soul strength "
tooltips_text.stats_num_uses = " The number of uses the resulting enchanted item can be used. This will increase as player enchanting skill increases. \n For constant effects, is value will show 'Constant' as that type has infinite uses "

tooltips_text.stats_skill_bonus = "TODO"

tooltips_text.price = " Price "
tooltips_text.chance = " Chance "

-- Unused
tooltips_text.create_btn = " Attempts to create or buy an enchanted item, \n if all menu inputs are valid "
tooltips_text.cancel_btn = " Cancel enchanting and close the menu "

return tooltips_text