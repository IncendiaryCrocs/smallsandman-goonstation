/datum/antagonist/subordinate/cult_member
	id = ROLE_CULT_MEMBER
	display_name = "cult member"
	antagonist_icon = "cult"
	wiki_link = "https://wiki.ss13.co/Cult"

/// The cult that this cult member belongs to.
	var/datum/cult/cult
	/// The headset of this cult member, tracked so that additional channels may be later removed.
	var/obj/item/device/radio/headset/headset
	/// The ability holder of this cult member, containing their abilities
	var/datum/abilityHolder/cult/ability_holder

	New(datum/mind/new_owner, do_equip, do_objectives, do_relocate, silent, source, do_pseudo, do_vr, late_setup, master)
		src.master = master
		var/datum/antagonist/cult_leader/antagrole = src.master.get_antagonist(ROLE_CULT_LEADER)
		src.cult = antagrole.cult
		antagonist_icon = "cult_[cult.color_id]"
		src.cult.members += new_owner
		if (src.cult.cult_points[new_owner] == null)
			src.cult.cult_points[new_owner] = CULT_STARTING_POINTS
		. = ..()

	disposing()
		src.cult.members -= src.owner

		. = ..()

	is_compatible_with(datum/mind/mind)
		return ishuman(mind.current)

	give_equipment()
		if (!ishuman(src.owner.current))
			return FALSE


		var/datum/abilityHolder/cult/cultHolder = src.owner.current.get_ability_holder(/datum/abilityHolder/cult)
		if (!cultHolder)
			src.ability_holder = src.owner.current.add_ability_holder(/datum/abilityHolder/cult)
		else
			src.ability_holder = cultHolder

		src.ability_holder.addAbility(/datum/targetable/cult/worship_spot)

		var/mob/living/carbon/human/H = src.owner.current

		// If possible, get the cult member's headset.
		if (istype(H.ears, /obj/item/device/radio/headset))
			src.headset = H.ears
		else
			src.headset = new /obj/item/device/radio/headset(H)
			if (!H.r_store)
				H.equip_if_possible(src.headset, SLOT_R_STORE)
			else if (!H.l_store)
				H.equip_if_possible(src.headset, SLOT_L_STORE)
			else if (H.back?.storage && !H.back.storage.is_full())
				H.equip_if_possible(src.headset, SLOT_IN_BACKPACK)
			else
				H.put_in_hand_or_drop(src.headset)

		src.headset.install_radio_upgrade(new /obj/item/device/radio_upgrade/cult(frequency = src.cult.cult_frequency))

	remove_equipment()
		src.headset.remove_radio_upgrade()
		src.owner.current.remove_ability_holder(/datum/abilityHolder/cult)

	add_to_image_groups()
		. = ..()
		var/datum/client_image_group/image_group = get_image_group(src.cult)
		image_group.add_mind_mob_overlay(src.owner, get_antag_icon_image())
		image_group.add_mind(src.owner)

		var/datum/client_image_group/imgroup = get_image_group(CLIENT_IMAGE_GROUP_CULTS)
		imgroup.add_mind(src.owner)
		var/datum/client_image_group/objimgroup = get_image_group(CLIENT_IMAGE_GROUP_CULT_OBJECTIVES)
		objimgroup.add_mind(src.owner)

	remove_from_image_groups()
		. = ..()
		var/datum/client_image_group/image_group = get_image_group(src.cult)
		image_group.remove_mind_mob_overlay(src.owner)
		image_group.remove_mind(src.owner)
		var/datum/client_image_group/imgroup = get_image_group(CLIENT_IMAGE_GROUP_CULTS)
		imgroup.remove_mind(src.owner)

		var/datum/client_image_group/objimgroup = get_image_group(CLIENT_IMAGE_GROUP_cult_OBJECTIVES)
		objimgroup.remove_mind(src.owner)

	assign_objectives()
		ticker.mode.bestow_objective(src.owner, /datum/objective/specialist/cult/member, src)
