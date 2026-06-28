/datum/speech_module/prefix/premodifier/channel/cultchat
	id = SPEECH_PREFIX_CULTCHAT
	priority = SPEECH_PREFIX_PRIORITY_LOW
	prefix_id = PREFIX_TEXT_CULTCHAT
	channel_id = SAY_CHANNEL_CULT

/datum/speech_module/prefix/premodifier/channel/cultchat/get_prefix_choices()
	return list("Cultspeak" = PREFIX_TEXT_CULTCHAT)
