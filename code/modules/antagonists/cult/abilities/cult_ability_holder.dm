/atom/movable/screen/ability/topBar/cult
	clicked(params)
		var/datum/targetable/cult/spell = owner
		var/datum/abilityHolder/holder = owner.holder

		if (!istype(spell))
			return
		if (!spell.holder)
			return

		if(params["shift"] && params["ctrl"])
			if(owner.waiting_for_hotkey)
				holder.cancel_action_binding()
				return
			else
				owner.waiting_for_hotkey = 1
				src.UpdateIcon()
				boutput(usr, SPAN_NOTICE("Please press a number to bind this ability to..."))
				return

		if (!isturf(owner.holder.owner.loc))
			boutput(owner.holder.owner, SPAN_ALERT("You can't use this spell here."))
			return
		if (spell.targeted && usr.targeting_ability == owner)
			usr.targeting_ability = null
			usr.update_cursor()
			return
		if (spell.targeted)
			if (world.time < spell.last_cast)
				return
			owner.holder.owner.targeting_ability = owner
			owner.holder.owner.update_cursor()
		else
			SPAWN(0)
				spell.handleCast()
		return


/* 	/		/		/		/		/		/		Ability Holder		/		/		/		/		/		/		/		/		*/

/datum/abilityHolder/cult
	usesPoints = 0
	regenRate = 0
	tabName = "cult"
	// notEnoughPointsMessage = SPAN_ALERT("You need more blood to use this ability.")
	points = 0
	pointName = "points"
	var/stealthed = 0
	var/const/MAX_POINTS = 100

	New()
		..()


	disposing()
		..()

	onLife(var/mult = 1)
		if(..()) return


/datum/targetable/cult
	icon = 'icons/mob/gang_abilities.dmi' //placeholder
	icon_state = "gang-template" //placeholder
	cooldown = 0
	last_cast = 0
	pointCost = 0
	preferred_holder_type = /datum/abilityHolder/cult
	var/when_stunned = 0 // 0: Never | 1: Ignore mob.stunned and mob.weakened | 2: Ignore all incapacitation vars
	var/not_when_handcuffed = 0
	var/unlock_message = null
	var/can_cast_anytime = 0		//while alive

	New()
		var/atom/movable/screen/ability/topBar/cult/B = new /atom/movable/screen/ability/topBar/cult(null)
		B.icon = src.icon
		B.icon_state = src.icon_state
		B.owner = src
		B.name = src.name
		B.desc = src.desc
		src.object = B
		return

	onAttach(var/datum/abilityHolder/H)
		..()
		if (src.unlock_message && src.holder && src.holder.owner)
			boutput(src.holder.owner, SPAN_NOTICE("<h3>[src.unlock_message]</h3>"))
		return

	updateObject()
		..()
		if (!src.object)
			src.object = new /atom/movable/screen/ability/topBar/cult()
			object.icon = src.icon
			object.owner = src
		if (src.last_cast > world.time)
			var/pttxt = ""
			if (pointCost)
				pttxt = " \[[pointCost]\]"
			object.name = "[src.name][pttxt] ([round((src.last_cast-world.time)/10)])"
			object.icon_state = src.icon_state + "_cd"
		else
			var/pttxt = ""
			if (pointCost)
				pttxt = " \[[pointCost]\]"
			object.name = "[src.name][pttxt]"
			object.icon_state = src.icon_state
		return

	castcheck()
		if (!holder)
			return 0

		var/mob/living/M = holder.owner

		if (!M)
			return 0

		if (!(iscarbon(M) || ismobcritter(M)))
			boutput(M, SPAN_ALERT("You cannot use any powers in your current form."))
			return 0

		if (can_cast_anytime && !isdead(M))
			return 1
		if (!can_act(M, 0))
			boutput(M, SPAN_ALERT("You can't use this ability while incapacitated!"))
			return 0

		if (src.not_when_handcuffed && M.restrained())
			boutput(M, SPAN_ALERT("You can't use this ability when restrained!"))
			return 0

		return 1

	cast(atom/target)
		. = ..()
		actions.interrupt(holder.owner, INTERRUPT_ACT)
		return


/datum/targetable/cult/summon_robe
	name = "Summon robe"
	desc = "Summons your robe."
	icon_state = "toggle_overlays" //placeholder
	do_logs = FALSE
	interrupt_action_bars = FALSE

	cast(mob/target)
		if (!holder)
			return 1

		var/mob/living/carbon/human/M = holder.owner

		if (!M)
			return 1

		if (!istype(M))
			return 1

		if (M.getStatusDuration("stunned") > 0 || M.getStatusDuration("knockdown") || M.getStatusDuration("unconscious") > 0 || !isalive(M) || M.restrained())
			boutput(M, SPAN_ALERT("Not when you're incapacitated or restrained."))
			return 1

		boutput(M, SPAN_ALERT("You are now wearing your robe."))
		M.equip_new_if_possible(/obj/item/clothing/suit/antagcult, SLOT_WEAR_SUIT)
