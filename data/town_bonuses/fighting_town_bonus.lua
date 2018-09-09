local ValorTownBonusnordlings = class()

local RECIPES_TO_UNLOCK = {
   ['stonehearth:jobs:blacksmith'] = {
	  'legendary:legendary_hammer',
	  'legendary:legendary_hammer_head',
	  'legendary:legendary_hammer_haft',
      'building_parts:fence_gate_iron',
      'decoration:valor_brazier_large',
      'decoration:wall_hanging_plaque',
      'decoration:valor_war_horn',
   },
   ['stonehearth:jobs:engineer'] = {
      'building_parts:portcullis_valor',
   },
   ['stonehearth:jobs:mason'] = {
      'signage_decoration:statue_knight',
      'signage_decoration:statue_knight_male',
      'signage_decoration:window_arrow_short',
      'signage_decoration:valor_window_arrow_tall',
      'signage_decoration:valor_window_frame_barred',
      'signage_decoration:valor_window_frame_xlarge',
   },
   ['stonehearth:jobs:potter'] = {
     'legendary:legendary_hammer_mounting',
   }
}

local RECIPE_UNLOCK_BULLETIN_TITLES = {
   "i18n(stonehearth:data.gm.campaigns.trader.valor_tier_2_reached.recipe_unlock_blacksmith)",
   "i18n(stonehearth:data.gm.campaigns.trader.valor_tier_2_reached.recipe_unlock_mason)",
   "i18n(stonehearth:data.gm.campaigns.trader.valor_tier_2_reached.recipe_unlock_engineer)",
   "i18n(stonehearth:data.gm.campaigns.trader.valor_tier_2_reached.recipe_unlock_weapons_1)",
   "i18n(stonehearth:data.gm.campaigns.trader.valor_tier_2_reached.recipe_unlock_weapons_2)",
   "i18n(stonehearth:data.gm.campaigns.trader.valor_tier_2_reached.recipe_unlock_weapons_3)",
   "i18n(stonehearth:data.gm.campaigns.trader.valor_tier_2_reached.recipe_unlock_weapons_4)"
}

function ValorTownBonusnordlings:initialize()
   self._sv.player_id = nil
   self._sv.display_name = 'i18n(stonehearth:data.gm.campaigns.town_progression.shrine_choice.valor.name)'
   self._sv.description = 'i18n(stonehearth:data.gm.campaigns.town_progression.shrine_choice.valor.description)'
end

function ValorTownBonusnordlings:create(player_id)
   self._sv.player_id = player_id
end

function ValorTownBonusnordlings:initialize_bonus()
   --unlock the new epic weapon recipes
end

function ValorTownBonusnordlings:get_recipe_unlocks()
   return RECIPES_TO_UNLOCK, RECIPE_UNLOCK_BULLETIN_TITLES
end

return ValorTownBonusnordlings

