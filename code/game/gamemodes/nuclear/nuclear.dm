/datum/game_mode/nuclear
	name = "nuclear emergency"
	config_tag = "nuclear"
	false_report_weight = 10
	chaos = 9
	required_players = 2 // 30 players - 3 players to be the nuke ops = 25 players remaining
	required_enemies = 2
	recommended_enemies = 5
	antag_flag = ROLE_OPERATIVE
	enemy_minimum_age = 0 // BLUEMOON EDIT - было 7, сделал 0, т.к. на сервере ВЛ и загриферить ролью тяжело

	announce_span = "danger"
	announce_text = "InteQ forces are approaching the station in an attempt to destroy it!\n\
	<span class='danger'>Operatives</span>: Secure the nuclear authentication disk and use your nuke to destroy the station.\n\
	<span class='notice'>Crew</span>: Defend the nuclear authentication disk and ensure that it leaves with you on the emergency shuttle."

	var/const/agents_possible = 5 //If we ever need more syndicate agents.
	var/nukes_left = 1 // Call 3714-PRAY right now and order more nukes! Limited offer!
	var/list/pre_nukeops = list()

	var/datum/team/nuclear/nuke_team

	var/operative_antag_datum_type = /datum/antagonist/nukeop
	var/leader_antag_datum_type = /datum/antagonist/nukeop/leader

/datum/game_mode/nuclear/pre_setup()
	var/n_agents = min(round(num_players() / 10), antag_candidates.len, agents_possible)
	if(n_agents >= required_enemies)
		for(var/i = 0, i < n_agents, ++i)
			var/datum/mind/new_op = pick_n_take(antag_candidates)
			pre_nukeops += new_op
			new_op.assigned_role = "Nuclear Operative"
			new_op.special_role = "Nuclear Operative"
			log_game("[key_name(new_op)] has been selected as a nuclear operative")
		return TRUE
	else
		setup_error = "Not enough nuke op candidates"
		return FALSE
////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////

/datum/game_mode/nuclear/post_setup()
	//Assign leader
	var/datum/mind/leader_mind = pre_nukeops[1]
	var/datum/antagonist/nukeop/L = leader_mind.add_antag_datum(leader_antag_datum_type)
	nuke_team = L.nuke_team
	//Assign the remaining operatives
	for(var/i = 2 to pre_nukeops.len)
		var/datum/mind/nuke_mind = pre_nukeops[i]
		nuke_mind.add_antag_datum(operative_antag_datum_type)
	return ..()

/datum/game_mode/nuclear/OnNukeExplosion(off_station)
	..()
	nukes_left--

/datum/game_mode/nuclear/check_win()
	if (nukes_left == 0)
		return TRUE
	return ..()

/datum/game_mode/proc/are_operatives_dead()
	for(var/datum/mind/operative_mind in get_antag_minds(/datum/antagonist/nukeop))
		if(ishuman(operative_mind.current) && (operative_mind.current.stat != DEAD))
			return FALSE
	return TRUE

/datum/game_mode/nuclear/check_finished()
	//Keep the round going if ops are dead but bomb is ticking.
	if(nuke_team.operatives_dead())
		for(var/obj/machinery/nuclearbomb/N in GLOB.nuke_list)
			if(N.proper_bomb && (N.timing || N.exploding))
				return FALSE
	return ..()

/datum/game_mode/nuclear/set_round_result()
	..()
	var result = nuke_team.get_result()
	switch(result)
		if(NUKE_RESULT_FLUKE)
			SSticker.mode_result = "loss - syndicate nuked - disk secured"
			SSticker.news_report = NUKE_SYNDICATE_BASE
		if(NUKE_RESULT_NUKE_WIN)
			SSticker.mode_result = "win - syndicate nuke"
			SSticker.news_report = STATION_NUKED
		if(NUKE_RESULT_NOSURVIVORS)
			SSticker.mode_result = "halfwin - syndicate nuke - did not evacuate in time"
			SSticker.news_report = STATION_NUKED
		if(NUKE_RESULT_WRONG_STATION)
			SSticker.mode_result = "halfwin - blew wrong station"
			SSticker.news_report = NUKE_MISS
		if(NUKE_RESULT_WRONG_STATION_DEAD)
			SSticker.mode_result = "halfwin - blew wrong station - did not evacuate in time"
			SSticker.news_report = NUKE_MISS
		if(NUKE_RESULT_CREW_WIN_SYNDIES_DEAD)
			SSticker.mode_result = "loss - evacuation - disk secured - syndi team dead"
			SSticker.news_report = OPERATIVES_KILLED
		if(NUKE_RESULT_CREW_WIN)
			SSticker.mode_result = "loss - evacuation - disk secured"
			SSticker.news_report = OPERATIVES_KILLED
		if(NUKE_RESULT_DISK_LOST)
			SSticker.mode_result = "halfwin - evacuation - disk not secured"
			SSticker.news_report = OPERATIVE_SKIRMISH
		if(NUKE_RESULT_DISK_STOLEN)
			SSticker.mode_result = "halfwin - detonation averted"
			SSticker.news_report = OPERATIVE_SKIRMISH
		else
			SSticker.mode_result = "halfwin - interrupted"
			SSticker.news_report = OPERATIVE_SKIRMISH

/datum/game_mode/nuclear/generate_report()
	return "One of Central Command's trading routes was recently disrupted by a raid carried out by the Admiral Brown's Chancellery. They seemed to only be after one ship - a highly-sensitive \
			transport containing a nuclear fission explosive, although it is useless without the proper code and authorization disk. While the code was likely found in minutes, the only disk that \
			can activate this explosive is on your station. Ensure that it is protected at all times, and remain alert for possible intruders."

/proc/is_nuclear_operative(mob/M)
	return M && istype(M) && M.mind && M.mind.has_antag_datum(/datum/antagonist/nukeop)

/datum/outfit/inteq
	name = "InteQ Operative - Basic"

	uniform = /obj/item/clothing/under/inteq
	shoes = /obj/item/clothing/shoes/combat
	gloves = /obj/item/clothing/gloves/combat
	back = /obj/item/storage/backpack
	ears = /obj/item/radio/headset/inteq/alt
	l_pocket = /obj/item/pinpointer/nuke/syndicate
	id = /obj/item/card/id/syndicate/inteq
	belt = /obj/item/gun/ballistic/automatic/pistol
	backpack_contents = list(/obj/item/storage/box/survival/syndie=1,\
		/obj/item/kitchen/knife/combat/survival)

	var/tc = 30
	var/command_radio = FALSE
	var/uplink_type = /obj/item/inteq/uplink/radio/nuclear

	give_space_cooler_if_synth = TRUE // BLUEMOON ADD

/datum/outfit/inteq/leader
	name = "InteQ Leader - Basic"
	id = /obj/item/card/id/syndicate/nuke_leader/inteq
	gloves = /obj/item/clothing/gloves/krav_maga/combatglovesplus
	r_hand = /obj/item/nuclear_challenge
	command_radio = TRUE

// BLUEMOON ADD START - командная коробочка для командира
/datum/outfit/inteq/leader/pre_equip(mob/living/carbon/human/H, visualsOnly, client/preference_source)
	. = ..()
	var/list/extra_backpack_items = list(
		/obj/item/storage/box/pinpointer_squad
	)
	LAZYADD(backpack_contents, extra_backpack_items)
// BLUEMOON ADD END

/datum/outfit/inteq/no_crystals
	tc = 0

/datum/outfit/inteq/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	var/obj/item/radio/R = H.ears
	R.set_frequency(FREQ_INTEQ)
	R.freqlock = TRUE
	if(command_radio)
		R.command = TRUE

	if(tc)
		var/obj/item/U = new uplink_type(H, H.key, tc)
		H.equip_to_slot_or_del(U, ITEM_SLOT_BACKPACK)

	var/obj/item/implant/weapons_auth/W = new
	W.implant(H)
	var/obj/item/implant/explosive/E = new
	E.implant(H)

	H.faction |= ROLE_INTEQ
	H.update_icons()

/datum/outfit/inteq/full
	name = "InteQ Operative - Full Kit"

	glasses = /obj/item/clothing/glasses/night/syndicate
	mask = /obj/item/clothing/mask/gas/sechailer
	suit = /obj/item/clothing/suit/space/hardsuit/syndi/elite/inteq
	r_pocket = /obj/item/tank/internals/emergency_oxygen/engi
	internals_slot = ITEM_SLOT_RPOCKET
	belt = /obj/item/storage/belt/military/inteq
	r_hand = /obj/item/gun/ballistic/automatic/ak12
	backpack_contents = list(/obj/item/storage/box/survival/syndie=1,\
		/obj/item/tank/jetpack/oxygen/harness=1,\
		/obj/item/gun/ballistic/automatic/pistol=1,\
		/obj/item/kitchen/knife/combat/survival)

/datum/outfit/inteq/lone/inteq
	name = "InteQ Lone Operative"

	glasses = /obj/item/clothing/glasses/night/syndicate
	uniform = /obj/item/clothing/under/inteq
	mask = /obj/item/clothing/mask/gas/sechailer
	suit = /obj/item/clothing/suit/space/syndicate/inteq
	head = /obj/item/clothing/head/helmet/space/syndicate/inteq
	id = /obj/item/card/id/syndicate/inteq
	r_pocket = /obj/item/tank/internals/emergency_oxygen/engi/syndi
	internals_slot = ITEM_SLOT_RPOCKET
	belt = /obj/item/storage/belt/military/inteq
	back = /obj/item/storage/backpack/security/inteq
	backpack_contents = list(/obj/item/storage/box/survival/syndie=1,\
	/obj/item/tank/jetpack/oxygen/harness=1,\
	/obj/item/gun/ballistic/automatic/pistol=1,\
	/obj/item/kitchen/knife/combat/survival)

	uplink_type = /obj/item/inteq/uplink/radio/nuclear
	tc = 60
