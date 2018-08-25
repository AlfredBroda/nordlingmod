local ValorTownBonus = class()

local RECIPES_TO_UNLOCK = {
   ['stonehearth:jobs:blacksmith'] = {
      'building_parts:fence_gate_iron',
      'decoration:valor_brazier_large',
      'decoration:wall_hanging_plaque',
      'decoration:valor_war_horn',
      'legendary:steel_frame',
      'legendary_hammer',
	  'legendary_hammer_head',
	  'legendary_hammer_haft',
      'legendary:circlet_valor',
   },
   ['stonehearth:jobs:engineer'] = {
      'building_parts:portcullis_valor',
      'legendary:mechanism',
   },
   ['stonehearth:jobs:mason'] = {
      'signage_decoration:statue_knight',
      'signage_decoration:statue_knight_male',
      'signage_decoration:window_arrow_short',
      'signage_decoration:valor_window_arrow_tall',
      'signage_decoration:valor_window_frame_barred',
      'signage_decoration:valor_window_frame_xlarge',
      'legendary:lucid_gem',
      'legendary:giants_shield',
   },
   ['stonehearth:jobs:carpenter'] = {
      'legendary:bow_valor',
      'legendary:giants_face',
   },
   ['stonehearth:jobs:herbalist'] = {
      'legendary:leaf_setting',
   },
   ['stonehearth:jobs:potter'] = {
     'legendary_hammer_mounting',
   },
   ['stonehearth:jobs:weaver'] = {
      'legendary:silver_bowstring',
      'legendary:woven_grip',
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

function ValorTownBonus:initialize()
   self._sv.player_id = nil
   self._sv.display_name = 'i18n(stonehearth:data.gm.campaigns.town_progression.shrine_choice.valor.name)'
   self._sv.description = 'i18n(stonehearth:data.gm.campaigns.town_progression.shrine_choice.valor.description)'
end

function ValorTownBonus:create(player_id)
   self._sv.player_id = player_id
end

function ValorTownBonus:initialize_bonus()
   --unlock the new epic weapon recipes
end

function ValorTownBonus:get_recipe_unlocks()
   return RECIPES_TO_UNLOCK, RECIPE_UNLOCK_BULLETIN_TITLES
end

return ValorTownBonus

