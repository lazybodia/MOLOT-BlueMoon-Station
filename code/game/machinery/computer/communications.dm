#define IMPORTANT_ACTION_COOLDOWN (60 SECONDS)
#define MAX_STATUS_LINE_LENGTH 40

#define STATE_BUYING_SHUTTLE "buying_shuttle"
#define STATE_CHANGING_STATUS "changing_status"
#define STATE_MAIN "main"
#define STATE_MESSAGES "messages"

// The communications computer
/obj/machinery/computer/communications
	name = "Сommunications Сonsole"
	desc = "Эта консоль используется для объявления важной информации по станции, для связи с ЦК и Синдикатом, или для повышения уровня тревоги."
	icon_screen = "comm"
	icon_keyboard = "tech_key"
	req_access = list(ACCESS_HEADS)
	circuit = /obj/item/circuitboard/computer/communications
	light_color = LIGHT_COLOR_BLUE

	/// Cooldown for important actions, such as messaging CentCom or other sectors
	COOLDOWN_DECLARE(static/important_action_cooldown)

	/// The current state of the UI
	var/state = STATE_MAIN

	/// The current state of the UI for AIs
	var/cyborg_state = STATE_MAIN

	/// The name of the user who logged in
	var/authorize_name

	/// The access that the card had on login
	var/list/authorize_access

	/// The messages this console has been sent
	var/list/datum/comm_message/messages

	/// How many times the alert level has been changed
	/// Used to clear the modal to change alert level
	var/alert_level_tick = 0

	/// The last lines used for changing the status display
	var/static/last_status_display

	/// Whether syndicate mode is enabled or not.
	var/syndicate = FALSE

/obj/machinery/computer/communications/syndicate
	name = "Syndicate Communications Console"
	icon_screen = "commsyndie"
	icon_keyboard = "syndie_key"
	req_access = list(ACCESS_SYNDICATE_LEADER)
	light_color = LIGHT_COLOR_BLOOD_MAGIC
	obj_flags = EMAGGED
	syndicate = TRUE

/obj/machinery/computer/communications/syndicate/emag_act(mob/user, obj/item/card/emag/emag_card)
	return

/obj/machinery/computer/communications/syndicate/authenticated_as_silicon_or_captain(mob/user)
	return FALSE

/obj/machinery/computer/communications/Initialize(mapload)
	. = ..()
	GLOB.shuttle_caller_list += src
	AddComponent(/datum/component/gps, "Secured Communications Signal")

/// Are we NOT a silicon, AND we're logged in as the captain?
/obj/machinery/computer/communications/proc/authenticated_as_non_silicon_captain(mob/user)
	if (issilicon(user))
		return FALSE
	return ACCESS_CAPTAIN in authorize_access

/obj/machinery/computer/communications/proc/authenticated_as_non_silicon_command(mob/user)
	if (issilicon(user))
		return FALSE
	return ACCESS_HEADS in authorize_access	//Should always be the case if authorized as it usually needs head access to log in, buut lets be sure.

/// Are we a silicon, OR we're logged in as the captain?
/obj/machinery/computer/communications/proc/authenticated_as_silicon_or_captain(mob/user)
	if (issilicon(user))
		return TRUE
	return ACCESS_CAPTAIN in authorize_access

/// Are we a silicon, OR logged in?
/obj/machinery/computer/communications/proc/authenticated(mob/user)
	if (issilicon(user))
		return TRUE
	return authenticated

/obj/machinery/computer/communications/attackby(obj/I, mob/user, params)
	if(istype(I, /obj/item/card/id))
		attack_hand(user)
	else
		return ..()

/obj/machinery/computer/communications/emag_act(mob/user)
	. = ..()
	if ((obj_flags & EMAGGED) || syndicate)
		return
	obj_flags |= EMAGGED
	if (authenticated)
		authorize_access = get_all_accesses()
	to_chat(user, span_danger("Вы искажаете схемы маршрутизации коммуникаций!"))
	playsound(src, 'sound/machines/terminal_alert.ogg', 50, FALSE)
	log_admin("[key_name(usr)] emagged [src] at [AREACOORD(src)]")
	icon_screen = "commsyndie"
	SSshuttle.shuttle_purchase_requirements_met["emagged"] = TRUE

/obj/machinery/computer/communications/ui_act(action, list/params)
	var/static/list/approved_states = list(STATE_BUYING_SHUTTLE, STATE_CHANGING_STATUS, STATE_MAIN, STATE_MESSAGES)
	var/static/list/approved_status_pictures = list("biohazard", "blank", "default", "lockdown", "redalert", "shuttle")
	var/static/list/state_status_pictures = list("blank", "shuttle")

	. = ..()
	if (.)
		return

	if (!has_communication())
		return

	. = TRUE

	switch (action)
		if ("answerMessage")
			if (!authenticated(usr))
				return

			var/answer_index = params["answer"]
			var/message_index = params["message"]

			// If either of these aren't numbers, then bad voodoo.
			if(!isnum(answer_index) || !isnum(message_index))
				message_admins("[ADMIN_LOOKUPFLW(usr)] provided an invalid index type when replying to a message on [src] [ADMIN_JMP(src)]. This should not happen. Please check with a maintainer and/or consult tgui logs.")
				CRASH("Non-numeric index provided when answering comms console message.")

			if (!answer_index || !message_index || answer_index < 1 || message_index < 1)
				return
			var/datum/comm_message/message = messages[message_index]
			if (message.answered)
				return
			message.answered = answer_index
			message.answer_callback.InvokeAsync()
		if ("callShuttle")
			if (!authenticated(usr) || !SSshuttle.canEvac(usr, TRUE))
				return
			var/reason = trim(params["reason"], MAX_MESSAGE_LEN)
			if (length(reason) < CALL_SHUTTLE_REASON_LENGTH)
				return
			SSshuttle.requestEvac(usr, reason)
			post_status("shuttle")
		if ("changeSecurityLevel")
			if (!authenticated_as_silicon_or_captain(usr))
				return

			// Check if they have
			if (!issilicon(usr))
				var/obj/item/held_item = usr.get_active_held_item()
				var/obj/item/card/id/id_card = held_item?.GetID()
				if (!istype(id_card))
					to_chat(usr, span_warning("Вам нужно провести своим ID!"))
					playsound(src, 'sound/machines/terminal_prompt_deny.ogg', 50, FALSE)
					return
				if (!(ACCESS_CAPTAIN in id_card.access))
					to_chat(usr, span_warning("У вас нет доступа!"))
					playsound(src, 'sound/machines/terminal_prompt_deny.ogg', 50, FALSE)
					return

			var/new_sec_level = SECLEVEL2NUM(params["newSecurityLevel"])
			if (new_sec_level != SEC_LEVEL_GREEN && new_sec_level != SEC_LEVEL_BLUE && new_sec_level != SEC_LEVEL_ORANGE && new_sec_level != SEC_LEVEL_VIOLET && new_sec_level != SEC_LEVEL_AMBER)
				return
			if (GLOB.security_level == new_sec_level)
				return

			set_security_level(new_sec_level)

			to_chat(usr, span_notice("Доступ разрешён. Обновляю уровень угрозы."))
			playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)

			// Only notify people if an actual change happened
			log_game("[key_name(usr)] has changed the security level to [params["newSecurityLevel"]] with [src] at [AREACOORD(usr)].")
			message_admins("[ADMIN_LOOKUPFLW(usr)] has changed the security level to [params["newSecurityLevel"]] with [src] at [AREACOORD(usr)].")
			deadchat_broadcast(" сменил уровень угрозы [params["newSecurityLevel"]] с помощью [src] в [span_name("[get_area_name(usr, TRUE)]")].", span_name("[usr.real_name]"), usr, message_type=DEADCHAT_ANNOUNCEMENT)

			alert_level_tick += 1
		if ("deleteMessage")
			if (!authenticated(usr))
				return
			var/message_index = text2num(params["message"])
			if (!message_index)
				return
			LAZYREMOVE(messages, LAZYACCESS(messages, message_index))
		if ("emergency_meeting")
			if(!(SSevents.holidays && SSevents.holidays[APRIL_FOOLS]))
				return
			if (!authenticated_as_silicon_or_captain(usr))
				return
			emergency_meeting(usr)
		if ("makePriorityAnnouncement")
			if (!authenticated_as_silicon_or_captain(usr))
				if(syndicate == TRUE)
					make_announcement(usr)
				return
			make_announcement(usr)
		if ("messageAssociates")
			if (!authenticated_as_non_silicon_command(usr))
				return
			if (!COOLDOWN_FINISHED(src, important_action_cooldown))
				return

			playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)
			var/message = trim(html_encode(params["message"]), MAX_MESSAGE_LEN)

			var/emagged = obj_flags & EMAGGED
			if (emagged && GLOB.master_mode == "Extended")
				message_syndicate(message, usr)
				to_chat(usr, span_danger("SYSERR @l(19833)of(transmit.dm): !@$ СООБЩЕНИЕ УСПЕШНО ОТПРАВЛЕНО ПО ПОДПРОСТРАНСТВЕННОЙ СВЯЗИ."))
			else if (emagged)
				message_inteq(message, usr)
				to_chat(usr, span_danger("SYSERR @l(19833)of(transmit.dm): $^#^@#%@== СООБЩЕНИЕ УСПЕШНО БЫЛО ОТПРАВЛЕНО ВСЕГО ЗА 0,523 МИЛЛИСЕКУНД. АДРЕСАТ НАХОДИТСЯ ВСЕГО В $%#^@ КИЛЛОМЕТРАХ $#y%)%&==..."))
			else if(syndicate)
				message_syndicate(message, usr)
				to_chat(usr, span_danger("Сообщение успешно отправлено по Подпространственной Связи."))
			else
				message_centcom(message, usr)
				to_chat(usr, span_notice("Сообщение успешно отправлено Центральному Командованию."))

			var/associates = (emagged || syndicate) ? "the Illegal Channel": "CentCom"
			usr.log_talk(message, LOG_SAY, tag = "сообщение для [associates]")
			deadchat_broadcast(" отправляет [associates], \"[message]\" где-то на территории [span_name("[get_area_name(usr, TRUE)]")].", span_name("[usr.real_name]"), usr, message_type = DEADCHAT_ANNOUNCEMENT)
			COOLDOWN_START(src, important_action_cooldown, IMPORTANT_ACTION_COOLDOWN)
		if ("purchaseShuttle")
			var/can_buy_shuttles_or_fail_reason = can_buy_shuttles(usr)
			if (can_buy_shuttles_or_fail_reason != TRUE)
				if (can_buy_shuttles_or_fail_reason != FALSE)
					to_chat(usr, span_alert("[can_buy_shuttles_or_fail_reason]"))
				return
			var/list/shuttles = flatten_list(SSmapping.shuttle_templates)
			var/datum/map_template/shuttle/shuttle = locate(params["shuttle"]) in shuttles
			if (!istype(shuttle))
				return
			if (!shuttle.prerequisites_met())
				to_chat(usr, span_alert("Требования для покупки этого шаттла - не выполнены!"))
				return
			var/datum/bank_account/bank_account = SSeconomy.get_dep_account(ACCOUNT_CAR)
			if (bank_account.account_balance < shuttle.credit_cost)
				return
			SSshuttle.shuttle_purchased = SHUTTLEPURCHASE_PURCHASED
			SSshuttle.unload_preview()
			SSshuttle.existing_shuttle = SSshuttle.emergency
			SSshuttle.action_load(shuttle, replace = TRUE)
			bank_account.adjust_money(-shuttle.credit_cost)
			minor_announce("[usr.real_name] купил шаттл [shuttle.name] за [shuttle.credit_cost] кредитов.[shuttle.extra_desc ? " [shuttle.extra_desc]" : ""]" , "Shuttle Purchase")
			message_admins("[ADMIN_LOOKUPFLW(usr)] purchased [shuttle.name].")
			log_shuttle("[key_name(usr)] has purchased [shuttle.name].")
			SSblackbox.record_feedback("text", "shuttle_purchase", 1, shuttle.name)
			state = STATE_MAIN
		if ("recallShuttle")
			// AIs cannot recall the shuttle
			if (!authenticated(usr) || issilicon(usr) || syndicate)
				return
			SSshuttle.cancelEvac(usr)
		if ("requestNukeCodes")
			if (syndicate == TRUE)
				balloon_alert_to_viewers("ОШИБКА")
				to_chat(usr, span_danger("ОШИБКА"))
				return
			if (!authenticated_as_non_silicon_captain(usr))
				return
			if (!COOLDOWN_FINISHED(src, important_action_cooldown))
				return
			var/reason = trim(html_encode(params["reason"]), MAX_MESSAGE_LEN)
			nuke_request(reason, usr)
			to_chat(usr, span_notice("Request sent."))
			usr.log_message("запросил коды запуска систем ядерного самоуничтожения с причиной \"[reason]\"", LOG_SAY)
			priority_announce("Запрос на коды от ядерного заряда станции для активации протокола самоуничтожения были запрошены [usr]. Решение будет отправлено в ближайшее время.", "Запрошены коды для запуска систем ядерного самоуничтожения.", SSstation.announcer.get_rand_report_sound())
			playsound(src, 'sound/machines/terminal_prompt.ogg', 50, FALSE)
			COOLDOWN_START(src, important_action_cooldown, IMPORTANT_ACTION_COOLDOWN)
		if ("restoreBackupRoutingData")
			if (syndicate == TRUE)
				balloon_alert_to_viewers("ОШИБКА")
				to_chat(usr, span_danger("ОШИБКА"))
				return
			if (!authenticated_as_non_silicon_captain(usr))
				return
			if (!(obj_flags & EMAGGED))
				return
			to_chat(usr, span_notice("Backup routing data restored."))
			playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)
			obj_flags &= ~EMAGGED
		if ("sendToOtherSector")
			if (!authenticated_as_non_silicon_captain(usr))
				return
			if (!can_send_messages_to_other_sectors(usr))
				return
			if (!COOLDOWN_FINISHED(src, important_action_cooldown))
				return

			var/message = trim(params["message"], MAX_MESSAGE_LEN)
			if (!message)
				return

			playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)

			var/destination = params["destination"]
			var/list/payload = list()

			var/network_name = CONFIG_GET(string/cross_comms_network)
			if (network_name)
				payload["network"] = network_name
			payload["sender_ckey"] = usr.ckey

			send2otherserver(html_decode(station_name()), message, "Comms_Console", destination == "all" ? null : list(destination), additional_data = payload)
			minor_announce(message, title = "Outgoing message to allied station")
			usr.log_talk(message, LOG_SAY, tag = "message to the other server")
			message_admins("[ADMIN_LOOKUPFLW(usr)] has sent a message to the other server\[s].")
			deadchat_broadcast(" has sent an outgoing message to the other station(s).</span>", "<span class='bold'>[usr.real_name]", usr, message_type = DEADCHAT_ANNOUNCEMENT)

			COOLDOWN_START(src, important_action_cooldown, IMPORTANT_ACTION_COOLDOWN)
		if ("setState")
			if (!authenticated(usr))
				return
			if (!(params["state"] in approved_states))
				return
			if (state == STATE_BUYING_SHUTTLE && can_buy_shuttles(usr) != TRUE)
				return
			set_state(usr, params["state"])
			playsound(src, "terminal_type", 50, FALSE)
		if ("setStatusMessage")
			if (!authenticated(usr))
				return
			var/line_one = reject_bad_text(params["lineOne"] || "", MAX_STATUS_LINE_LENGTH)
			var/line_two = reject_bad_text(params["lineTwo"] || "", MAX_STATUS_LINE_LENGTH)
			post_status("alert", "blank")
			post_status("message", line_one, line_two)
			log_admin("[key_name(usr)] меняет текст в строке Статус-Дисплея: [line_one] & [line_two]")
			last_status_display = list(line_one, line_two)
			playsound(src, "terminal_type", 50, FALSE)
		if ("setStatusPicture")
			if (!authenticated(usr))
				return
			var/picture = params["picture"]
			if (!(picture in approved_status_pictures))
				return
			if(picture in state_status_pictures)
				post_status(picture)
			else
				post_status("alert", picture)
			playsound(src, "terminal_type", 50, FALSE)
		if ("toggleAuthentication")
			// Log out if we're logged in
			if (authorize_name)
				authenticated = FALSE
				authorize_access = null
				authorize_name = null
				playsound(src, 'sound/machines/terminal_off.ogg', 50, FALSE)
				return

			if (obj_flags & EMAGGED)
				authenticated = TRUE
				authorize_access = get_all_accesses()
				authorize_name = "NULL"
				to_chat(usr, span_warning("[src] испускает тихий щелчок, а на консоли высвечивает полный доступ."))
				playsound(src, 'sound/machines/terminal_alert.ogg', 25, FALSE)
			else if(isliving(usr))
				var/mob/living/L = usr
				var/obj/item/card/id/id_card = L.get_idcard(hand_first = TRUE)
				if (check_access(id_card))
					authenticated = TRUE
					authorize_access = id_card.access
					authorize_name = "[id_card.registered_name] - [id_card.assignment]"

			state = STATE_MAIN
			playsound(src, 'sound/machines/terminal_on.ogg', 50, FALSE)
		if ("toggleEmergencyAccess")
			if (!authenticated_as_silicon_or_captain(usr))
				return
			if (GLOB.emergency_access)
				revoke_maint_all_access()
				log_game("[key_name(usr)] disabled emergency maintenance access.")
				message_admins("[ADMIN_LOOKUPFLW(usr)] disabled emergency maintenance access.")
				deadchat_broadcast(" disabled emergency maintenance access at [span_name("[get_area_name(usr, TRUE)]")].", span_name("[usr.real_name]"), usr, message_type = DEADCHAT_ANNOUNCEMENT)
			else
				make_maint_all_access()
				log_game("[key_name(usr)] enabled emergency maintenance access.")
				message_admins("[ADMIN_LOOKUPFLW(usr)] enabled emergency maintenance access.")
				deadchat_broadcast(" enabled emergency maintenance access at [span_name("[get_area_name(usr, TRUE)]")].", span_name("[usr.real_name]"), usr, message_type = DEADCHAT_ANNOUNCEMENT)

		if("toggleBought")
			var/boughtID = params["id"]
			for(var/tracked_slave in GLOB.tracked_slaves)
				var/obj/item/electropack/shockcollar/slave/C = tracked_slave
				var/mob/living/M = C.loc
				if (REF(C) == boughtID) // Get collar

					var/datum/bank_account/bank = SSeconomy.get_dep_account(ACCOUNT_CAR)
					if(bank)
						if(C.bought)
							bank.adjust_money(C.price)
							C.setBought(FALSE)

							for(var/obj/machinery/computer/slavery/tracked_slave_console in GLOB.tracked_slave_consoles)
								priority_announce("Станция отменяет плату в [C.price] кредитов за [M.real_name].", sender_override = GLOB.slavers_team_name)
								tracked_slave_console.radioAnnounce("Станция отказалась платить за [C.loc.name].")

						else
							bank.adjust_money(-C.price)
							C.setBought(TRUE)

							for(var/obj/machinery/computer/slavery/tracked_slave_console in GLOB.tracked_slave_consoles)
								priority_announce("Станция оплачивает возвращение [M.real_name] за [C.price] кредитов.", sender_override = GLOB.slavers_team_name)
								tracked_slave_console.radioAnnounce("Станция заплатила выкуп за [C.loc.name].")
					break

/obj/machinery/computer/communications/ui_data(mob/user)
	var/list/data = list(
		"authenticated" = FALSE,
		"emagged" = FALSE,
		"syndicate" = syndicate,
	)

	var/ui_state = issilicon(user) ? cyborg_state : state

	var/has_connection = has_communication()
	data["hasConnection"] = has_connection

	// if(!SSjob.assigned_captain && !SSjob.safe_code_requested && SSid_access.spare_id_safe_code && has_connection)
	// 	data["canRequestSafeCode"] = TRUE
	// 	data["safeCodeDeliveryWait"] = 0
	// else
	// 	data["canRequestSafeCode"] = FALSE
	// 	if(SSjob.safe_code_timer_id && has_connection)
	// 		data["safeCodeDeliveryWait"] = timeleft(SSjob.safe_code_timer_id)
	// 		data["safeCodeDeliveryArea"] = get_area(SSjob.safe_code_request_loc)
	// 	else
	// 		data["safeCodeDeliveryWait"] = 0
	// 		data["safeCodeDeliveryArea"] = null

	if (authenticated || issilicon(user))
		data["authenticated"] = TRUE
		data["canLogOut"] = !issilicon(user)
		data["page"] = ui_state

		if (obj_flags & EMAGGED)
			data["emagged"] = TRUE

		switch (ui_state)
			if (STATE_MAIN)
				data["canBuyShuttles"] = can_buy_shuttles(user)
				data["canMakeAnnouncement"] = FALSE
				data["canMessageAssociates"] = FALSE
				data["canRecallShuttles"] = !issilicon(user)
				data["canRequestNuke"] = FALSE
				data["canSendToSectors"] = FALSE
				data["canSetAlertLevel"] = FALSE
				data["canToggleEmergencyAccess"] = FALSE
				data["importantActionReady"] = COOLDOWN_FINISHED(src, important_action_cooldown)
				data["shuttleCalled"] = FALSE
				data["shuttleLastCalled"] = FALSE
				data["aprilFools"] = SSevents.holidays && SSevents.holidays[APRIL_FOOLS]
				data["alertLevel"] = NUM2SECLEVEL(GLOB.security_level)
				data["authorizeName"] = authorize_name
				data["canLogOut"] = !issilicon(user)
				data["shuttleCanEvacOrFailReason"] = SSshuttle.canEvac(user)
				if(syndicate)
					data["shuttleCanEvacOrFailReason"] = "Вы не можете вызвать Шаттл Эвакуации с этой консоли!"

				var/list/slaves = list()
				data["slaves"] = list()
				var/datum/bank_account/bank = SSeconomy.get_dep_account(ACCOUNT_CAR)
				data["cargocredits"] = bank.account_balance

				for(var/tracked_slave in GLOB.tracked_slaves)
					var/obj/item/electropack/shockcollar/slave/C = tracked_slave
					if (!C.price || !isliving(C.loc))
						continue;

					var/mob/living/L = C.loc
					var/turf/pos = get_turf(L)
					if(!pos || C != L.get_item_by_slot(ITEM_SLOT_NECK))
						continue

					var/list/slave = list()
					slave["id"] = REF(C)
					slave["name"] = L.real_name
					slave["bought"] = C.bought
					slave["price"] = C.price

					var/canToggleRansom = FALSE
					var/ransomFeedback = ""
					var/ransomChangeCooldown = C.nextRansomChange - world.time

					if(ransomChangeCooldown > 0) // On cooldown.
						ransomFeedback += " (can undo in [round(ransomChangeCooldown / 10)])"
					else if (C.bought || (bank && bank.account_balance >= C.price)) // Slave already bought
						canToggleRansom = TRUE

					slave["cantoggleransom"] = canToggleRansom
					slave["toggleransomfeedback"] = ransomFeedback

					slaves += list(slave) //Add this slave to the list of slaves
				data["slaves"] = slaves

				if (authenticated_as_non_silicon_captain(user))
					data["canRequestNuke"] = TRUE
				if (authenticated_as_non_silicon_command(user))
					data["canMessageAssociates"] = TRUE

				if (can_send_messages_to_other_sectors(user))
					data["canSendToSectors"] = TRUE

					var/list/sectors = list()
					var/our_id = CONFIG_GET(string/cross_comms_name)

					for (var/server in CONFIG_GET(keyed_list/cross_server))
						if (server == our_id)
							continue
						sectors += server

					data["sectors"] = sectors

				if (authenticated_as_silicon_or_captain(user))
					data["canToggleEmergencyAccess"] = TRUE
					data["emergencyAccess"] = GLOB.emergency_access

					data["alertLevelTick"] = alert_level_tick
					data["canMakeAnnouncement"] = TRUE
					data["canSetAlertLevel"] = issilicon(user) ? "NO_SWIPE_NEEDED" : "SWIPE_NEEDED"
				else if(syndicate)
					data["canMakeAnnouncement"] = TRUE

				if (SSshuttle.emergency.mode != SHUTTLE_IDLE && SSshuttle.emergency.mode != SHUTTLE_RECALL)
					data["shuttleCalled"] = TRUE
					data["shuttleRecallable"] = SSshuttle.canRecall() || syndicate

				if (SSshuttle.emergencyCallAmount)
					data["shuttleCalledPreviously"] = TRUE
					if (SSshuttle.emergencyLastCallLoc)
						data["shuttleLastCalled"] = format_text(SSshuttle.emergencyLastCallLoc.name)
			if (STATE_MESSAGES)
				data["messages"] = list()

				if (messages)
					for (var/_message in messages)
						var/datum/comm_message/message = _message
						data["messages"] += list(list(
							"answered" = message.answered,
							"content" = message.content,
							"title" = message.title,
							"possibleAnswers" = message.possible_answers,
						))
			if (STATE_BUYING_SHUTTLE)
				var/datum/bank_account/bank_account = SSeconomy.get_dep_account(ACCOUNT_CAR)
				var/list/shuttles = list()

				for (var/shuttle_id in SSmapping.shuttle_templates)
					var/datum/map_template/shuttle/shuttle_template = SSmapping.shuttle_templates[shuttle_id]

					if (shuttle_template.credit_cost == INFINITY)
						continue

					if (!shuttle_template.can_be_bought)
						continue

					shuttles += list(list(
						"name" = shuttle_template.name,
						"description" = shuttle_template.description,
						"creditCost" = shuttle_template.credit_cost,
						"prerequisites" = shuttle_template.prerequisites,
						"ref" = REF(shuttle_template),
					))

				data["budget"] = bank_account.account_balance
				data["shuttles"] = shuttles
			if (STATE_CHANGING_STATUS)
				data["lineOne"] = last_status_display ? last_status_display[1] : ""
				data["lineTwo"] = last_status_display ? last_status_display[2] : ""

	return data

/obj/machinery/computer/communications/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if (!ui)
		if (EMAGGED && GLOB.master_mode == "Extended" || syndicate == TRUE)
			ui = new(user, src, "CommunicationsConsole")
			ui.open()
		else if (EMAGGED)
			ui = new(user, src, "CommunicationsConsoleInteq")
			ui.open()
		else
			ui = new(user, src, "CommunicationsConsole")
			ui.open()

/obj/machinery/computer/communications/ui_static_data(mob/user)
	return list(
		"callShuttleReasonMinLength" = CALL_SHUTTLE_REASON_LENGTH,
		"maxStatusLineLength" = MAX_STATUS_LINE_LENGTH,
		"maxMessageLength" = MAX_MESSAGE_LEN,
	)

/// Returns whether or not the communications console can communicate with the station
/obj/machinery/computer/communications/proc/has_communication()
	var/turf/current_turf = get_turf(src)
	var/z_level = current_turf.z
	if(syndicate)
		return TRUE
	return is_station_level(z_level) || is_centcom_level(z_level)

/obj/machinery/computer/communications/proc/set_state(mob/user, new_state)
	if (issilicon(user))
		cyborg_state = new_state
	else
		state = new_state

/// Returns TRUE if the user can buy shuttles.
/// If they cannot, returns FALSE or a string detailing why.
/obj/machinery/computer/communications/proc/can_buy_shuttles(mob/user)
	if (!SSmapping.config.allow_custom_shuttles)
		return FALSE
	if (!authenticated_as_non_silicon_captain(user))
		return FALSE

	if (SSshuttle.emergency.mode != SHUTTLE_RECALL && SSshuttle.emergency.mode != SHUTTLE_IDLE)
		return "The shuttle is already in transit."
	if (SSshuttle.shuttle_purchased == SHUTTLEPURCHASE_PURCHASED)
		return "A replacement shuttle has already been purchased."
	if (SSshuttle.shuttle_purchased == SHUTTLEPURCHASE_FORCED)
		return "Due to unforseen circumstances, shuttle purchasing is no longer available."
	return TRUE

/obj/machinery/computer/communications/proc/can_send_messages_to_other_sectors(mob/user)
	if (!authenticated_as_non_silicon_captain(user))
		return

	return length(CONFIG_GET(keyed_list/cross_server)) > 0

/**
 * Call an emergency meeting
 *
 * Comm Console wrapper for the Communications subsystem wrapper for the call_emergency_meeting world proc.
 * Checks to make sure the proc can be called, and handles relevant feedback, logging and timing.
 * See the SScommunications proc definition for more detail, in short, teleports the entire crew to
 * the bridge for a meetup. Should only really happen during april fools.
 * Arguments:
 * * user - Mob who called the meeting
 */
/obj/machinery/computer/communications/proc/emergency_meeting(mob/living/user)
	if(!SScommunications.can_make_emergency_meeting(user))
		to_chat(user, span_alert("The emergency meeting button doesn't seem to work right now. Please stand by."))
		return
	SScommunications.emergency_meeting(user)
	deadchat_broadcast(" called an emergency meeting from [span_name("[get_area_name(usr, TRUE)]")].", span_name("[user.real_name]"), user, message_type=DEADCHAT_ANNOUNCEMENT)

/obj/machinery/computer/communications/proc/make_announcement(mob/living/user)
	var/is_ai = issilicon(user)
	if(!SScommunications.can_announce(user, is_ai))
		to_chat(user, span_alert("Система оповещения испытывает перегрузку. Пожалуйста, подождите."))
		return
	var/input = input(user, "Напишите сообщение для объявления экипажу станции.", "Приоритетное оповещение") as message|null
	if(!input || !user.canUseTopic(src, !issilicon(usr)))
		return
	if(!(user.can_speak())) //No more cheating, mime/random mute guy!
		input = "..."
		to_chat(user, span_warning("Вы не можете говорить."))
	else
		input = user.treat_message(input) //Adds slurs and so on. Someone should make this use languages too.
	SScommunications.make_announcement(user, is_ai, input, syndicate)
	deadchat_broadcast(" делает важное объявление в [span_name("[get_area_name(usr, TRUE)]")].", span_name("[user.real_name]"), user, message_type=DEADCHAT_ANNOUNCEMENT)

/obj/machinery/computer/communications/proc/post_status(command, data1, data2)

	var/datum/radio_frequency/frequency = SSradio.return_frequency(FREQ_STATUS_DISPLAYS)

	if(!frequency)
		return

	var/datum/signal/status_signal = new(list("command" = command))
	switch(command)
		if("message")
			status_signal.data["msg1"] = data1
			status_signal.data["msg2"] = data2
			if(istype(usr, /mob/living))
				log_admin("STATUS: [key_name(usr)] set status screen with [src]. Message: [data1] [data2]")
				message_admins("STATUS: [key_name(usr)] set status screen with [src]. Message: [data1] [data2]")
		if("alert")
			status_signal.data["picture_state"] = data1

	frequency.post_signal(src, status_signal)

/obj/machinery/computer/communications/Destroy()
	GLOB.shuttle_caller_list -= src
	SSshuttle.autoEvac()
	return ..()

/// Override the cooldown for special actions
/// Used in places such as CentCom messaging back so that the crew can answer right away
/obj/machinery/computer/communications/proc/override_cooldown()
	COOLDOWN_RESET(src, important_action_cooldown)

/obj/machinery/computer/communications/proc/add_message(datum/comm_message/new_message)
	LAZYADD(messages, new_message)

/datum/comm_message
	var/title
	var/content
	var/list/possible_answers = list()
	var/answered
	var/datum/callback/answer_callback

/datum/comm_message/New(new_title,new_content,new_possible_answers)
	..()
	if(new_title)
		title = new_title
	if(new_content)
		content = new_content
	if(new_possible_answers)
		possible_answers = new_possible_answers

#undef IMPORTANT_ACTION_COOLDOWN
#undef MAX_STATUS_LINE_LENGTH
#undef STATE_BUYING_SHUTTLE
#undef STATE_CHANGING_STATUS
#undef STATE_MAIN
#undef STATE_MESSAGES
