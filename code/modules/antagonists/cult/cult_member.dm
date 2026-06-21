/datum/antagonist/subordinate/cult_member
	id = ROLE_CULT_MEMBER
	display_name = "cult member"
	antagonist_icon = "cult"
	wiki_link = "https://wiki.ss13.co/Cult"

	give_equipment()
		if (!ishuman(src.owner.current))
			return FALSE

		//var/mob/living/carbon/human/H = src.owner.current
		src.owner.current.ensure_speech_tree().AddSpeechOutput(SPEECH_OUTPUT_CULTCHAT_CULTIST)
		src.owner.current.ensure_listen_tree().AddListenInput(LISTEN_INPUT_CULTCHAT)

	remove_equipment()
		src.owner.current.ensure_speech_tree().RemoveSpeechOutput(SPEECH_OUTPUT_CULTCHAT_CULTIST)
		src.owner.current.ensure_listen_tree().RemoveListenInput(LISTEN_INPUT_CULTCHAT)
