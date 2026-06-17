/datum/game_mode/cult
	name = "Cult"
	config_tag = "cult"
	regular = FALSE

	var/list/datum/cult/cult = list()

	var/const/setup_min_teams = 1
#ifdef RP_MODE
	var/const/setup_max_teams = 2
#else
	var/const/setup_max_teams = 3
#endif
	var/const/waittime_l = 600 //lower bound on time before intercept arrives (in tenths of seconds)
	var/const/waittime_h = 1800 //upper bound on time before intercept arrives (in tenths of seconds)

	var/minimum_players = 15 // Minimum ready players for the mode

	var/slow_process = 0			//number of ticks to skip the extra cult process loops
	var/shuttle_called = FALSE

/datum/game_mode/cult/announce()
	boutput(world, "<B>The current game mode is - Cult!</B>")
	boutput(world, "<B>A number of cults are competing for control of the station!</B>")
	boutput(world, "<B>Cult members are antagonists and can kill or be killed!</B>")

#ifdef RP_MODE
#define PLAYERS_PER_CULT_GENERATED 15
#else
#define PLAYERS_PER_CULT_GENERATED 12
#endif
/datum/game_mode/cult/pre_setup()
	var/num_players = src.roundstart_player_count()

#ifndef ME_AND_MY_40_ALT_ACCOUNTS
	if (num_players < minimum_players)
		message_admins("<b>ERROR: Minimum player count of [minimum_players] required for Cult game mode, aborting cult round pre-setup.</b>")
		logTheThing(LOG_GAMEMODE, src, "Failed to start cult mode. [num_players] players were ready but a minimum of [minimum_players] players is required. ")
		return 0
#endif

	var/num_teams = clamp(round((num_players) / PLAYERS_PER_CULT_GENERATED), setup_min_teams, setup_max_teams) //1 cult per 9 players, 15 on RP
	logTheThing(LOG_GAMEMODE, src, "Counted [num_players] available, with [PLAYERS_PER_CULT_GENERATED] per cult that means [num_teams] cults.")

	var/list/leaders_possible = get_possible_enemies(ROLE_CULT_LEADER, num_teams)
	if (num_teams > length(leaders_possible))
		logTheThing(LOG_GAMEMODE, src, "Reducing number of cult from [num_teams] to [length(leaders_possible)] due to lack of available cult leaders.")
		num_teams = length(leaders_possible)

	if (!length(leaders_possible))
		return 0

	var/list/chosen_leader = antagWeighter.choose(pool = leaders_possible, role = ROLE_CULT_LEADER, amount = num_teams, recordChosen = 1)
	src.traitors |= chosen_leader

#ifndef ME_AND_MY_40_ALT_ACCOUNTS
	// check if we can actually run the mode before assigning special roles to minds
	if(length(get_possible_enemies(ROLE_CULT_MEMBER, round(num_teams * CULT_MAX_MEMBERS), force_fill = FALSE) - src.traitors) < round(num_teams * CULT_MAX_MEMBERS * 0.66)) //must have at least 2/3 full cults or there's no point
		//boutput(world, SPAN_ALERT("<b>ERROR: The readied players are not collectively cultist enough for the selected mode, aborting cult.</b>"))
		return 0
#endif

	for (var/datum/mind/leader in src.traitors)
		leaders_possible.Remove(leader)
		leader.special_role = ROLE_CULT_LEADER

	return 1
#undef PLAYERS_PER_CULT_GENERATED

/datum/game_mode/cult/post_setup()
	for(var/datum/mind/antag_mind in src.traitors)
		if(antag_mind.special_role == ROLE_CULT_LEADER)
			antag_mind.add_antagonist(ROLE_CULT_LEADER, silent=TRUE)

	fill_cults()

	// we delay announcement to make sure everyone gets information about the other members
	for(var/datum/mind/antag_mind in src.traitors)
		antag_mind.get_antagonist(ROLE_CULT_LEADER)?.unsilence()
		antag_mind.get_antagonist(ROLE_CULT_MEMBER)?.unsilence()

	SPAWN(rand(waittime_l, waittime_h))
		send_intercept()

	return 1

/datum/game_mode/cult/proc/fill_cults(list/datum/mind/candidates = null, max_member_count = INFINITY)
	logTheThing(LOG_GAMEMODE, src, "begins using random crew members to fill cult roster.")
	var/num_teams = length(src.cults)
	var/num_people_needed = 0
	if(num_teams == 0)
		logTheThing(LOG_DEBUG, null, "Cult gamemode attempted to fill cults, but there were no cults to fill.")
		message_admins("It's cults, but there are no cults??")
		return
	for(var/datum/cult/cult in src.cults)
		num_people_needed += min(cult.current_max_cult_members, max_member_count) - length(cult.members)
	if(isnull(candidates))
		candidates = get_possible_enemies(ROLE_CULT_MEMBER, num_people_needed, allow_carbon=TRUE, force_fill = FALSE)
	var/num_people_available = min(num_people_needed, length(candidates))
	var/people_added_per_cult = round(num_people_available / num_teams)
	logTheThing(LOG_GAMEMODE, src, "assigning [people_added_per_cult] members each to [length(src.cults)] cults from a pool of [num_people_available] crew members.")
	num_people_available = people_added_per_cult * num_teams
	shuffle_list(candidates)
	var/i = 1
	var/cult_count = 0
	for(var/datum/cult/cult in src.cults)
		cult_count++
		for(var/j in 1 to people_added_per_cult)
			var/datum/mind/candidate = candidates[i++]
			logTheThing(LOG_GAMEMODE, src, "assigned [candidate.ckey] to cult #[cult_count]")
			candidate.add_subordinate_antagonist(ROLE_CULT_MEMBER, master = cult.leader, silent=TRUE)
			traitors |= candidate

/datum/game_mode/cult/send_intercept()
	..(src.traitors)


/datum/game_mode/cult/process()
	..()
	slow_process ++
	if (slow_process < 5)
		return
	else
		slow_process = 0


/datum/game_mode/cult/declare_completion()
	for (var/datum/cult/cult in src.cults)
		logTheThing(LOG_GAMEMODE, src, "Cult [cult.cult_name] ended the round with [cult.cult_score()] total score.")
	if (!check_winner())
		boutput(world, "<h2><b>The round was a draw!</b></h2>")

	else
		var/datum/cult/winner = check_winner()
		if (istype(winner))
			boutput(world, "<h2><b>[winner.cult_name], led by [winner.leader.current.real_name], won the round!</b></h2>")

			var/datum/hud/cult_victory/victory_hud = get_singleton(/datum/hud/cult_victory)
			victory_hud.set_winner(winner)
			for (var/client/C in clients)
				victory_hud.add_client(C)
				C.mob.addAbility(/datum/targetable/toggle_cult_victory_hud)

	..()

/datum/game_mode/cult/proc/check_winner()
	var/datum/cult/victorius_cult = null

	// Find the highest scoring cult.
	for (var/datum/cult/cult in src.cults)
		if(!victorius_cult)
			victorius_cult = cult
		else if(victorius_cult.cult_score() < cult.cult_score())
			victorius_cult = cult

	// Check if the highest score is a draw.
	for (var/datum/cult/cult in src.cults)
		if((victorius_cult != cult) && (victorius_cult.cult_score() == cult.cult_score()))
			return 0

	if (istype(victorius_cult))
		return victorius_cult

/proc/broadcast_to_all_cults(message)
	for (var/datum/cult/cult as anything in global.get_all_cults())
		cult.announcer_say_source.say(message, flags = SAYFLAG_IGNORE_HTML)

/datum/cult
	/// The maximum number of cult members per cult.
	var/static/current_max_cult_members = CULT_MAX_MEMBERS
	/// Cult tag icon states that are being used by other cults.
	var/static/list/used_tags
	/// Cult names that are being used by other cults.
	var/static/list/used_names
	/// Radio frequencies that are being used by other cults.
	var/static/list/used_frequencies
	/// Jumpsuit items that are being used by other cults as part of their cult uniform.
	var/static/list/uniform_list
	/// Mask or hat items that are being used by other cults as part of their cult uniform.
	var/static/list/headwear_list
	var/static/list/color_list = list("#88CCEE","#117733","#332288","#DDCC77","#CC6677","#AA4499") //(hopefully) colorblind friendly palette
	var/static/list/colors_left = null
	/// The abstarct radio say source for this cult's announcer, who will announce various messages of importance over the cult's frequency.
	var/atom/movable/abstract_say_source/radio/cult_announcer/announcer_say_source
	/// String displayed to show the next spray paint restock
	var/next_spray_paint_restock = "--:--"
	/// The chosen name of this cult.
	var/cult_name = "Cult Name"
	/// The randomly selected tag of this cult.
	var/cult_tag = 0
	/// The ID of the color selected
	var/color_id = 0
	/// The unique radio frequency that members of this cult will communicate over.
	var/cult_frequency = 0
	/// The amount of spray paint cans this cult may spawn.
	var/spray_paint_remaining = CULT_STARTING_SPRAYPAINT
	/// The chosen jumpsuit item of this cult.
	var/obj/item/clothing/uniform = null
	/// The chosen mask or hat item of this cult.
	var/obj/item/clothing/headwear = null
	/// The location of this cult's locker.
	var/area/base = null
	/// The various areas that this cult currently controls.
	var/list/area/controlled_areas = list()
	/// The mind of this cult's leader.
	var/datum/mind/leader = null
	/// The minds of cult members associated with this cult. Does not include the cult leader.
	var/list/datum/mind/members = list()
	var/list/tags = list()
	/// The minds of members of this cult who are currently on cooldown from redeeming their gear from the cult base.
	var/list/gear_cooldown = list()
	/// List of antag datums who have obtained their free knife from the base so far
	var/list/free_knife_owners = list()
	/// The cult object of this cult.
	var/obj/cultworship/worship = null

	proc/living_member_count()
		var/result = 0
		for (var/datum/mind/member as anything in members)
			if (!isdead(member.current))
				result++
		return result

	/// how to handle the cult leader dying horribly early into the shift (suicide etc)
	proc/handle_leader_early_death()
		if (!src.locker)
			choose_new_leader()
			logTheThing(LOG_ADMIN, src.leader.ckey, "was given the role of leader for [cult_name], as their previous leader died early with no locker.")
			message_admins("[src.leader.ckey] has been granted the role of leader for their cult, [cult_name], as the previous leader died early with no locker.")
			src.announcer_say_source.say("Your leader has died early into the shift. Leadership has been transferred to [src.leader.current.real_name]")
		else
			src.announcer_say_source.say("Your leader has died early into the shift. If not revived, a new leader will be picked in [CULT_LEADER_SOFT_DEATH_DELAY/(1 MINUTE)] minutes.")
			SPAWN (CULT_LEADER_SOFT_DEATH_DELAY)
				if (!isalive(src.leader.current))
					choose_new_leader()
					logTheThing(LOG_ADMIN, src.leader.ckey, "was given the role of leader for [cult_name], as their previous leader died early and wasn't respawned/revived.")
					message_admins("[src.leader.ckey] has been granted the role of leader for their cult, [cult_name], as the previous leader died early and wasn't respawned/revived.")
					src.announcer_say_source.say("Your leader has died early into the shift. Leadership has been transferred to [src.leader.current.real_name]")

	/// how to handle the cult leader entering cryo (but not guaranteed to be permanent)
	proc/handle_leader_temp_cryo()
		if (!src.locker)
			choose_new_leader()
		else
			src.announcer_say_source.say("Your leader has entered temporary cryogenic storage. You can claim leadership at your base in [CULT_CRYO_LOCKOUT/(1 MINUTE)] minutes.")

	/// handle the cult leader entering cryo permanently
	proc/handle_leader_perma_cryo()
		if (src.locker)
			src.announcer_say_source.say("Your leader has entered permanent cryogenic storage. You can claim leadership at your locker.")
			leader_claimable = TRUE
		else
			logTheThing(LOG_ADMIN, src.leader.ckey, "was given the role of leader for [cult_name], as their leader cryo'd without a base.")
			message_admins("[src.leader.ckey] has been granted the role of leader for their cult, [cult_name], as leader cryo'd without a base.")
			src.announcer_say_source.say("As your leader has entered cryogenic storage without a base, [src.leader.current.real_name] is now your new leader.")
			choose_new_leader()

	proc/choose_new_leader()
		var/datum/mind/smelly_unfortunate
		for (var/datum/mind/member in members)
			if (isliving(member.current))
				var/mob/living/carbon/candidate = member.current
				if (!candidate.hibernating)
					smelly_unfortunate = member
		if (!smelly_unfortunate)
			logTheThing(LOG_ADMIN, leader.ckey, "The leader of [cult_name] cryo'd/died early with no living members to take the role.")
			message_admins("The leader of [cult_name], [leader.ckey] cryo'd/died early with no living members to take the role.")
			return

		var/datum/mind/bad_leader = leader
		var/datum/antagonist/leaderRole = leader.get_antagonist(ROLE_CULT_LEADER)
		var/datum/antagonist/oldRole = smelly_unfortunate.get_antagonist(ROLE_CULT_MEMBER)
		smelly_unfortunate.current.remove_ability_holder(/datum/abilityHolder/cult)
		oldRole.silent = TRUE // so they dont get a spooky 'you are no longer a cult member' popup!
		smelly_unfortunate.remove_antagonist(ROLE_CULT_MEMBER,ANTAGONIST_REMOVAL_SOURCE_OVERRIDE,FALSE)
		leaderRole.transfer_to(smelly_unfortunate, FALSE, ANTAGONIST_REMOVAL_SOURCE_EXPIRED)
		bad_leader.add_subordinate_antagonist(ROLE_CULT_MEMBER, master = smelly_unfortunate)

	proc/get_dead_memberlist()
		var/list/result = list()
		for (var/datum/mind/member as anything in members)
			if (istype(member.current.loc, /obj/cryotron))
				var/obj/cryotron/cryo = member.current.loc
				var/cryoTime = cryo.stored_mobs[member.current]
				if (TIME - cryoTime > CULT_CRYO_LOCKOUT)
					result[(member.current?.real_name)] = member
				continue
			if (isdead(member.current))
				result[(member.current?.real_name)] = member
		return result

	New()
		. = ..()
		if (colors_left == null)
			colors_left = new/list(length(color_list))
			for (var/color = 1 to length(color_list))
				colors_left[color] = color
		if (!src.used_tags)
			src.used_tags = list()
		if (!src.used_names)
			src.used_names = list()
		if (!src.used_frequencies)
			src.used_frequencies = list()
		if (!src.uniform_list || !src.headwear_list)
			src.make_item_lists()
		color_id = pick(colors_left)
		colors_left -= color_id
		color = color_list[color_id]
		src.cult_tag = rand(0, 22)
		while(src.cult_tag in src.used_tags)
			src.cult_tag = rand(0, 22)
		src.used_tags += src.cult_tag

		src.cult_frequency = rand(1360, 1420)
		while(src.cult_frequency in src.used_frequencies)
			src.cult_frequency = rand(1360, 1420)
		src.used_frequencies += src.cult_frequency
		protected_frequencies += cult_frequency

		src.announcer_say_source = new(null, src)

		if (istype(ticker?.mode, /datum/game_mode/cult))
			var/datum/game_mode/cult/gamemode = ticker.mode
			gamemode.cults += src

	proc/generate_random_name()
		if (prob(70))
			. = pick_string("gangtwar.txt", "fullchosen")
		else
			. = "[pick(first_names)] [pick(second_names)]"

	proc/select_cult_name()
		var/temporary_name = generate_random_name()

		while(src.cult_name == "Cult Name")
			var/choice = "Accept"
			if(src.leader?.current)
				// if the leader is disconnected, this tgui_alert call will return null, breaking everything. Default to "Accept" and give them the random name
				choice = tgui_alert(src.leader?.current, "Name: [temporary_name].", "Approve Your Cult's Name", list("Accept", "Reselect", "Randomise")) || "Accept"
			switch(choice)
				if ("Accept")
					if (temporary_name in src.used_names)
						boutput(src.leader.current, SPAN_ALERT("Another cult has this name."))
						// to prevent the incredibly slim chance that a disconncted cult leader rolls the same name as an existing cult
						temporary_name = generate_random_name()
						continue

					src.cult_name = temporary_name
					src.used_names += temporary_name

					for(var/datum/mind/member in src.members + list(src.leader))
						boutput(member.current, SPAN_ALERT("<h4>Your cult name is [src.cult_name]!</h4>"))

				if ("Reselect")
					var/first_name = tgui_input_list(src.leader.current, "Select the first word in your cult's name:", "Cult Name Selection", first_names)
					var/second_name = tgui_input_list(src.leader.current, "Select the second word in your cult's name:", "Cult Name Selection", second_names)
					temporary_name = "[first_name] [second_name]"

				if ("Randomise")
					temporary_name = generate_random_name()


		// add the cult to their displayed name for antag and round end stuff. works hopefully??
		var/datum/antagonist/leader_antag = src.leader.get_antagonist(ROLE_CULT_LEADER)
		leader_antag.display_name = "[src.cult_name] [leader_antag.display_name]"

		for (var/datum/mind/culter in src.members)
			var/datum/antagonist/antag = culter.get_antagonist(ROLE_CULT_MEMBER)
			antag.display_name = "[src.cult_name] [antag.display_name]"

	proc/select_cult_uniform()
		// Jumpsuit Selection.
		var/temporary_jumpsuit = tgui_input_list(src.leader.current, "Select your cult's uniform slot item:", "Cult Uniform Selection", src.uniform_list)
		var/frustration = 0
		while (!src.uniform_list[temporary_jumpsuit])
			if (frustration++ > 10)
				return FALSE
			boutput(src.leader.current , SPAN_ALERT("That uniform has been claimed by another cult."))
			temporary_jumpsuit = tgui_input_list(src.leader.current, "Select your cult's uniform slot item:", "Cult Uniform Selection", src.uniform_list)

		src.uniform = src.uniform_list[temporary_jumpsuit]
		src.uniform_list -= temporary_jumpsuit

		// Mask/Headwear Selection.
		if(src.cult_name == "NICOLAS CAGE FAN CLUB")
			src.headwear = /obj/item/clothing/mask/niccage
		else
			var/temporary_headwear = tgui_input_list(src.leader.current, "Select your cult's mask or head slot item:", "Cult Uniform Selection", src.headwear_list)

			while(!src.headwear_list[temporary_headwear])
				if (frustration++ > 10)
					return FALSE
				boutput(src.leader.current , SPAN_ALERT("That mask or hat has been claimed by another cult."))
				temporary_headwear = tgui_input_list(src.leader.current, "Select your cult's mask or head slot item:", "Cult Uniform Selection", src.headwear_list)

			src.headwear = src.headwear_list[temporary_headwear]
			src.headwear_list -= temporary_headwear
		return TRUE

	proc/num_tiles_controlled()
		return src.tiles_controlled

	proc/cult_score()
		var/score = 0

		score += score_turf
		score += score_cash
		score += score_gun
		score += score_drug
		score += score_event
		score_total = round(score)
		return score_total

	/// Shows maptext to the cult, with formatting for score increases.
	proc/show_vandal_maptext(score, area/targetArea, turf/location, notable)
		if (isnull(src.vandalism_tracker[targetArea]))
			return

		var/content
		if (!notable)
			content = "+[score]"
		else
			content = "+[score]\n [vandalism_tracker[targetArea]]/[vandalism_tracker_target[targetArea]]"

		DISPLAY_MAPTEXT(location, (src.members + src.leader), MAPTEXT_MIND_RECIPIENTS_WITH_OBSERVERS, /image/maptext/cult_vandalism, content)

	/// add points to this cult, bonusMob optionally getting a bonus
	/// if location is defined, maptext will come from that location, for all members.
	proc/add_points(amount, mob/bonusMob = null, turf/location = null, showText = FALSE)
		street_cred += amount
		var/datum/mind/bonusMind = bonusMob?.mind
		if (leader)
			if (cult_points[leader] == null)
				cult_points[leader] = CULT_STARTING_POINTS
			if (leader == bonusMind)
				cult_points[leader] += round(amount * 1.25) //give a 25% reward for the one providing
			else
				cult_points[leader] += amount
		for (var/datum/mind/M in members)
			if (cult_points[M] == null)
				cult_points[M] = CULT_STARTING_POINTS
			if (M == bonusMind)
				cult_points[M] += round(amount * 1.25)
			else
				cult_points[M] += amount

		cult_score()
		if (!showText)
			return
		if (location)
			DISPLAY_MAPTEXT(location, (src.members + src.leader), MAPTEXT_MIND_RECIPIENTS_WITH_OBSERVERS, /image/maptext/cult_score, amount)
		else if (bonusMind)
			DISPLAY_MAPTEXT(bonusMob, list(bonusMind), MAPTEXT_MIND_RECIPIENTS_WITH_OBSERVERS, /image/maptext/cult_score, amount)

	proc/can_be_joined() //basic for now but might be expanded on so I'm making it a proc of its own
		if(length(src.members) >= src.current_max_cult_members)
			return FALSE
		return TRUE

	proc/gear_worn(var/mob/living/carbon/human/M)
		if(!istype(M))
			return FALSE

		var/count = 0

		if(istype(M.w_uniform, src.uniform))
			count++

		if(istype(M.head, src.headwear) || istype(M.wear_mask, src.headwear))
			count++

		if (M.wear_suit && !istype(M.wear_suit, /obj/item/clothing/suit/armor/cult))
			count--
		return count
