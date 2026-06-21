/datum/antagonist/cult_leader
	id = ROLE_CULT_LEADER
	display_name = "cult leader"
	antagonist_icon = "cult_head"
	wiki_link = "https://wiki.ss13.co/Cult"

	give_equipment()
		if (!ishuman(src.owner.current))
			return FALSE

		//var/mob/living/carbon/human/H = src.owner.current
		src.owner.current.ensure_speech_tree().AddSpeechOutput(SPEECH_OUTPUT_CULTCHAT_CULTLEADER)
		src.owner.current.ensure_listen_tree().AddListenInput(LISTEN_INPUT_CULTCHAT)

	remove_equipment()
		src.owner.current.ensure_speech_tree().RemoveSpeechOutput(SPEECH_OUTPUT_CULTCHAT_CULTLEADER)
		src.owner.current.ensure_listen_tree().RemoveListenInput(LISTEN_INPUT_CULTCHAT)





