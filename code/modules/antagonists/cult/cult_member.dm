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

		src.ability_holder.addAbility(/datum/targetable/cult/summon_robe)

		var/mob/living/carbon/human/H = src.owner.current

	remove_equipment()
		src.owner.current.remove_ability_holder(/datum/abilityHolder/cult)
