/datum/antagonist/heretic
	name = "Heretic"
	roundend_category = "Heretics"
	antagpanel_category = "Heretic"
	antag_moodlet = /datum/mood_event/heretics
	job_rank = ROLE_HERETIC
	antag_hud_type = ANTAG_HUD_HERETIC
	antag_hud_name = "heretic"
	threat = 10
	var/give_equipment = TRUE
	var/list/researched_knowledge = list()
	var/total_sacrifices = 0
	var/list/sac_targetted = list()		//Which targets did living hearts give them, but they did not sac?
	var/list/actually_sacced = list()	//Which targets did they actually sac?
	var/ascended = FALSE
	var/datum/mind/yandere

	reminded_times_left = 2 // BLUEMOON ADD

/datum/antagonist/heretic/admin_add(datum/mind/new_owner,mob/admin)
	give_equipment = TRUE
	new_owner.add_antag_datum(src)
	message_admins("[key_name_admin(admin)] has heresized [key_name_admin(new_owner)].")
	log_admin("[key_name(admin)] has heresized [key_name(new_owner)].")

/datum/antagonist/heretic/greet()
	owner.current.playsound_local(get_turf(owner.current), 'sound/ambience/antag/ecult_op.ogg', 100, FALSE, pressure_affected = FALSE)//subject to change
	to_chat(owner, "<span class='boldannounce'>You are the Heretic!</span><br>\
	<B>The old ones gave you these tasks to fulfill:</B>")
	owner.announce_objectives()
	to_chat(owner, "<span class='cult'>The book whispers softly, its forbidden knowledge walks this plane once again!<br>\
	Your book allows you to research abilities. Read it very carefully, for you cannot undo what has been done!<br>\
	You gain charges by either collecting influences or sacrificing people tracked by the living heart.<br> \
	You can find a basic guide at : https://tgstation13.org/wiki/Heresy_101 </span>")

/datum/antagonist/heretic/on_gain()
	var/mob/living/current = owner.current
	owner.teach_crafting_recipe(/datum/crafting_recipe/heretic/codex)
	owner.special_role = ROLE_HERETIC
	if(ishuman(current))
		forge_primary_objectives()
		gain_knowledge(/datum/eldritch_knowledge/spell/basic)
		gain_knowledge(/datum/eldritch_knowledge/living_heart)
		gain_knowledge(/datum/eldritch_knowledge/codex_cicatrix)
	current.log_message("has been converted to the cult of the forgotten ones!", LOG_ATTACK, color="#960000")
	GLOB.reality_smash_track.AddMind(owner)
	START_PROCESSING(SSprocessing,src)
	if(give_equipment)
		equip_cultist()
	return ..()

/datum/antagonist/heretic/on_removal()

	for(var/X in researched_knowledge)
		var/datum/eldritch_knowledge/EK = researched_knowledge[X]
		EK.on_lose(owner.current)
	owner.special_role = null
	if(!silent)
		to_chat(owner.current, "<span class='userdanger'>Your mind begins to flare as the otherwordly knowledge escapes your grasp!</span>")
		owner.current.log_message("has renounced the cult of the old ones!", LOG_ATTACK, color="#960000")
	GLOB.reality_smash_track.RemoveMind(owner)
	STOP_PROCESSING(SSprocessing,src)

	on_death()

	return ..()


/datum/antagonist/heretic/proc/equip_cultist()
	var/mob/living/carbon/H = owner.current
	if(!istype(H))
		return
	. += ecult_give_item(/obj/item/forbidden_book, H)
	. += ecult_give_item(/obj/item/living_heart, H)

/datum/antagonist/heretic/proc/ecult_give_item(obj/item/item_path, mob/living/carbon/human/H)
	var/list/slots = list(
		"backpack" = ITEM_SLOT_BACKPACK,
		"left pocket" = ITEM_SLOT_LPOCKET,
		"right pocket" = ITEM_SLOT_RPOCKET
	)

	var/T = new item_path(H)
	var/item_name = initial(item_path.name)
	var/where = H.equip_in_one_of_slots(T, slots, critical = TRUE)
	if(!where)
		to_chat(H, "<span class='userdanger'>Unfortunately, you weren't able to get a [item_name]. This is very bad and you should adminhelp immediately (press F1).</span>")
		return FALSE
	else
		to_chat(H, "<span class='danger'>You have a [item_name] in your [where].</span>")
		if(where == "backpack")
			SEND_SIGNAL(H.back, COMSIG_TRY_STORAGE_SHOW, H)
		return TRUE

/datum/antagonist/heretic/process()
	. = ..()

	if(owner.current.stat == DEAD)
		return

	for(var/X in researched_knowledge)
		var/datum/eldritch_knowledge/EK = researched_knowledge[X]
		EK.on_life(owner.current)

///What happens to the heretic once he dies, used to remove any custom perks
/datum/antagonist/heretic/proc/on_death()

	for(var/X in researched_knowledge)
		var/datum/eldritch_knowledge/EK = researched_knowledge[X]
		EK.on_death(owner.current)

// needs to be refactored to base /datum/antagonist sometime..
/datum/antagonist/heretic/proc/add_objective(datum/objective/O)
	objectives += O

/datum/antagonist/heretic/proc/forge_single_objective(datum/antagonist/heretic/heretic)
	var/datum/objective/protect/protection_objective = new
	protection_objective.owner = heretic.owner
	heretic.add_objective(protection_objective)
	protection_objective.find_target()

/datum/antagonist/heretic/proc/forge_primary_objectives()
	var/datum/objective/sacrifice_ecult/SE = new
	SE.owner = owner
	SE.update_explanation_text()
	objectives += SE

/datum/antagonist/heretic/apply_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/current = owner.current
	if(mob_override)
		current = mob_override
	add_antag_hud(antag_hud_type, antag_hud_name, current)
	handle_clown_mutation(current, mob_override ? null : "Ancient knowledge described in the book allows you to overcome your clownish nature, allowing you to use complex items effectively.")
	current.faction |= "heretics"

/datum/antagonist/heretic/remove_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/current = owner.current
	if(mob_override)
		current = mob_override
	remove_antag_hud(antag_hud_type, current)
	handle_clown_mutation(current, removing = FALSE)
	current.faction -= "heretics"

/datum/antagonist/heretic/get_admin_commands()
	. = ..()
	.["Equip"] = CALLBACK(src,.proc/equip_cultist)

/datum/antagonist/heretic/roundend_report()
	var/list/parts = list()

	var/cultiewin = TRUE

	parts += printplayer(owner)
	parts += "<b>Sacrifices Made:</b> [total_sacrifices]"

	if(length(objectives))
		var/count = 1
		for(var/o in objectives)
			var/datum/objective/objective = o
			if(objective.check_completion())
				parts += "<b>Objective #[count]</b>: [objective.explanation_text] <span class='greentext'>Success!</b></span>"
			else
				parts += "<b>Objective #[count]</b>: [objective.explanation_text] <span class='redtext'>Fail.</span>"
				cultiewin = FALSE
			count++
	if(ascended)
		parts += "<span class='greentext big'>THE HERETIC ASCENDED!</span>"
	else
		if(cultiewin)
			parts += "<span class='greentext'>The heretic was successful!</span>"
		else
			parts += "<span class='redtext'>The heretic has failed.</span>"

	parts += "<b>Knowledge Researched:</b> "

	var/list/knowledge_message = list()
	var/list/knowledge = get_all_knowledge()
	for(var/X in knowledge)
		var/datum/eldritch_knowledge/EK = knowledge[X]
		knowledge_message += "[EK.name]"
	parts += knowledge_message.Join(", ")

	parts += "<b>Targets assigned by living hearts, but not sacrificed:</b>"
	if(!sac_targetted.len)
		parts += "None."
	else
		parts += sac_targetted.Join(",")
	parts += "<b>Sacrifices performed:</b>"
	if(!actually_sacced.len)
		parts += "<span class='redtext'>None!</span>"
	else
		parts += actually_sacced.Join(",")

	return parts.Join("<br>")
////////////////
// Knowledge //
////////////////

/datum/antagonist/heretic/proc/gain_knowledge(datum/eldritch_knowledge/EK)
	if(get_knowledge(EK))
		return FALSE
	var/datum/eldritch_knowledge/initialized_knowledge = new EK
	researched_knowledge[initialized_knowledge.type] = initialized_knowledge
	initialized_knowledge.on_gain(owner.current)
	return TRUE

/datum/antagonist/heretic/proc/get_researchable_knowledge()
	var/list/researchable_knowledge = list()
	var/list/banned_knowledge = list()
	for(var/X in researched_knowledge)
		var/datum/eldritch_knowledge/EK = researched_knowledge[X]
		researchable_knowledge |= EK.next_knowledge
		banned_knowledge |= EK.banned_knowledge
		banned_knowledge |= EK.type
	researchable_knowledge -= banned_knowledge
	return researchable_knowledge

/datum/antagonist/heretic/proc/get_knowledge(wanted)
	return researched_knowledge[wanted]

/datum/antagonist/heretic/proc/get_all_knowledge()
	return researched_knowledge

/datum/antagonist/heretic/threat()
	. = ..()
	for(var/X in researched_knowledge)
		var/datum/eldritch_knowledge/EK = researched_knowledge[X]
		. += EK.cost
	if(ascended)
		. += 20

/datum/antagonist/heretic/antag_panel()
	var/list/parts = list()
	parts += ..()
	parts += "<b>Targets currently assigned by living hearts (Can give a false negative if they stole someone elses living heart):</b>"
	if(!sac_targetted.len)
		parts += "Отсутствует."
	else
		parts += sac_targetted.Join(",")
	parts += "<b>Принесенные в жертву цели:</b>"
	if(!actually_sacced.len)
		parts += "Отсутствует."
	else
		parts += actually_sacced.Join(",")

	return (parts.Join("<br>") + "<br>")


////////////////
// Objectives //
////////////////

/datum/objective/sacrifice_ecult
	name = "sacrifice"

/datum/objective/sacrifice_ecult/update_explanation_text()
	. = ..()
	target_amount = rand(2,3)
	explanation_text = "Принеси в жертву как минимум [target_amount] живых существ."

/datum/objective/sacrifice_ecult/check_completion()
	if(!owner)
		return FALSE
	var/datum/antagonist/heretic/cultie = owner.has_antag_datum(/datum/antagonist/heretic)
	if(!cultie)
		return FALSE
	return cultie.total_sacrifices >= target_amount
