/datum/speech_module/output/bundled/cultchat
	id = SPEECH_OUTPUT_CULTCHAT
	channel = SAY_CHANNEL_CULT
	speech_prefix = SPEECH_PREFIX_CULTCHAT
	var/role = ""
	var/css_class = ""
	var/datum/say_channel/outloud_channel

/datum/speech_module/output/bundled/cultchat/New(datum/speech_module_tree/parent, subchannel)
	. = ..()
	//src.outloud_channel = global.SpeechManager.GetSayChannelInstance(SAY_CHANNEL_OUTLOUD)

/datum/speech_module/output/bundled/cultchat/process(datum/say_message/message)
	message.flags |= SAYFLAG_NO_MAPTEXT
	// Whisper message under breath (Current commented out because it doesn't work, but I want you to have a working vers now)
	//var/datum/say_message/whispered_message = message.Copy()
	//PASS_MESSAGE_TO_SAY_CHANNEL(outloud_channel, whispered_message)
	// Ignore Unused Warning! This is commented out so it works.

	// Apply formatting to messages (similar to Thrallspeak)
	var/mind_ref = ""
	if (ismob(message.speaker))
		var/mob/mob_speaker = message.speaker
		mind_ref = "\ref[mob_speaker.mind]"

	message.format_speaker_prefix = {"\
		<span class='game cultsay'>\
			<span class='prefix'>CULTSPEAK: </span>\
			<span class='name [src.css_class]' data-ctx='[mind_ref]'>\
	"}

	message.format_verb_prefix = {"\
		<span class='text-normal'>[src.role]</span></span> \
		<span class='message'>\
	"}

	message.format_content_prefix = {"\
		, \
	"}

	message.format_content_suffix = {"\
		</span></span>\
	"}

	. = ..()


/datum/speech_module/output/bundled/cultchat/cultleader
	id = SPEECH_OUTPUT_CULTCHAT_CULTLEADER
	role = " (LEADER)"
	css_class = "cultleader"


/datum/speech_module/output/bundled/cultchat/cultist
	id = SPEECH_OUTPUT_CULTCHAT_CULTIST
	role = " (CULTIST)"


/datum/speech_module/output/bundled/cultchat/global_cultchat
	id = SPEECH_OUTPUT_CULTCHAT_GLOBAL
	channel = SAY_CHANNEL_GLOBAL_CULT
	speech_prefix = null
