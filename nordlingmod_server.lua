nordlingmod = {
}

local log = radiant.log.create_logger('Nordling Mod Server')

radiant.events.listen_once(radiant,'radiant:required_loaded', nordlingmod, nordlingmod._on_required_loaded)

return nordlingmod