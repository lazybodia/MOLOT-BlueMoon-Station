//Main code edits
/datum/emote/living/audio_emote/laugh/run_emote(mob/user, params)
	. = ..()

	// Check parent return
	if(!.)
		return

	// Define carbon user
	var/mob/living/carbon/carbon_user = user

	// Check if carbon user exists
	if(!istype(carbon_user))
		return

	// Check for subraces
	if(ishumanbasic(carbon_user) || iscatperson(carbon_user) || isinsect(carbon_user) || isjellyperson(carbon_user))
		return

	// Define default laugh type
	// Defaults to male
	var/laugh_sound = 'sound/voice/human/manlaugh1.ogg'

	// Check gender
	switch(user.gender)
		// Female
		if(FEMALE)
			// Set laugh sound
			laugh_sound = 'sound/voice/human/womanlaugh.ogg'

		/*
		 * Please add more gendered laughs
		 *
		// Male
		if(MALE)
			// Set laugh sound
			laugh_sound = 'sound/voice/human/laugh_male.ogg'

		// Non-binary
		if(PLURAL)
			// Set laugh sound
			laugh_sound = 'sound/voice/human/laugh_nonbinary.ogg'

		// Object
		if(NEUTER)
			// Set laugh sound
			laugh_sound = 'sound/voice/human/laugh_object.ogg'
		*/

		// Other
		else
			// Set laugh sound
			laugh_sound = pick('sound/voice/human/manlaugh1.ogg', 'sound/voice/human/manlaugh2.ogg')

	// Play laugh sound
	playsound(carbon_user, laugh_sound, 50, 1)

// Living variant
/datum/emote/living/audio
	// List of mob types that can run emote
	mob_type_allowed_typecache = list(/mob/living)

	// Default type
	// Can be EMOTE_AUDIBLE, EMOTE_VISIBLE, EMOTE_BOTH, or EMOTE_OMNI
	emote_type = EMOTE_AUDIBLE

	// Placeholder variables
	// These should NOT appear in-game
	message = "makes an indescribable noise"
	var/emote_sound = 'sound/arcade/Boom.ogg'

	// Default time before using another audio emote
	emote_cooldown = 1 SECONDS

	// Default volume of the emote
	var/emote_volume = 50

	// Default range modifier
	var/emote_range = -1
	var/emote_distance_multiplier = SOUND_DEFAULT_DISTANCE_MULTIPLIER
	var/emote_distance_multiplier_min_range = SOUND_DEFAULT_MULTIPLIER_EFFECT_RANGE

	// Default pitch variance
	var/emote_pitch_variance = 1

	// Default audio falloff settings
	var/emote_falloff_exponent = SOUND_FALLOFF_EXPONENT
	var/emote_falloff_distance = SOUND_DEFAULT_FALLOFF_DISTANCE

	// Default frequency
	var/emote_frequency = null

	// Default channel
	var/emote_channel = 0

	// Should the emote consider atmospheric pressure?
	var/emote_check_pressure = TRUE

	// Should the emote ignore walls?
	var/emote_ignore_walls = FALSE

	// Default wet and dry settings (???)
	var/emote_wetness = -10000
	var/emote_dryness = 0

// Check if audio emote can run
/datum/emote/living/audio/can_run_emote(mob/living/user, status_check)
	. = ..()

	// Check parent return
	if(!.)
		return FALSE

	// Allow use
	return TRUE

// Run audio emote
/datum/emote/living/audio/run_emote(mob/user, params)
	. = ..()

	// Check parent return
	if(!.)
		return

	// Check if user is miming
	if(user?.mind?.miming)
		// Do nothing
		return

	// Play sound
	// Accepts all possible parameters
	playsound(user.loc, emote_sound, emote_volume, emote_pitch_variance, emote_range, emote_falloff_exponent, emote_frequency, emote_channel, emote_check_pressure, emote_ignore_walls, emote_falloff_distance, emote_wetness, emote_dryness, emote_distance_multiplier, emote_distance_multiplier_min_range)

/datum/emote/living/surrender/run_emote(mob/user, params, type_override, intentional)
	// Set message with pronouns
	message = "puts [user.p_their()] hands on [user.p_their()] head and falls to the ground, [user.p_they()] surrender[user.p_s()]!"

	// Return normally
	. = ..()

// SPLURT emotes
/datum/emote/living/tilt
	key = "tilt"
	key_third_person = "tilts"
	message = "tilts their head."
	emote_type = EMOTE_VISIBLE

/datum/emote/living/squint
	key = "squint"
	key_third_person = "squints"
	message = "squints their eyes." // i dumb
	emote_type = EMOTE_VISIBLE

/datum/emote/living/fart
	key = "fart"
	key_third_person = "farts"
	message = "farts out shitcode."

/datum/emote/living/fart/run_emote(mob/living/user, params, type_override, intentional)
	if(TIMER_COOLDOWN_CHECK(user, COOLDOWN_EMOTE_FART))
		to_chat(user, span_warning("You try your hardest, but no shart comes out."))
		return
	var/list/fart_emotes = list( //cope goonies
		"lets out a girly little 'toot' from [user.p_their()] butt.",
		"farts loudly!",
		"lets one rip!",
		"farts! It sounds wet and smells like rotten eggs.",
		"farts robustly!",
		"farted! It smells like something died.",
		"farts like a muppet!",
		"defiles the station's air supply.",
		"farts for a whole ten seconds.",
		"groans and moans, farting like the world depended on it.",
		"breaks wind!",
		"expels intestinal gas through [user.p_their()] anus.",
		"releases an audible discharge of intestinal gas.",
		"is a farting motherfucker!!!",
		"suffers from flatulence!",
		"releases flatus.",
		"releases methane.",
		"farts up a storm.",
		"farts. It smells like Soylent Surprise!",
		"farts. It smells like pizza!",
		"farts. It smells like George Melons' perfume!",
		"farts. It smells like the kitchen!",
		"farts. It smells like medbay in here now!",
		"farts. It smells like the bridge in here now!",
		"farts like a pubby!",
		"farts like a goone!",
		"sharts! That's just nasty.",
		"farts delicately.",
		"farts timidly.",
		"farts very, very quietly. The stench is OVERPOWERING.",
		"farts egregiously.",
		"farts voraciously.",
		"farts cantankerously.",
		"farts in [user.p_their()] own mouth. A shameful \the <b>[user]</b>.",
		"breaks wind noisily!",
		"releases gas with the power of the gods! The very station trembles!!",
		"<B><span style='color:red'>f</span><span style='color:blue'>a</span>r<span style='color:red'>t</span><span style='color:blue'>s</span>!</B>",
		"laughs! [user.p_their(TRUE)] breath smells like a fart.",
		"farts, and as such, blob cannot evoulate.",
		"farts. It might have been the Citizen Kane of farts."
	)
	var/new_message = pick(fart_emotes)
	//new_message = replacetext(new_message, "%OWNER", "\the [user]")
	message = new_message
	. = ..()
	if(.)
		playsound(user, pick(GLOB.brap_noises), 50, 1, -1)
		TIMER_COOLDOWN_START(user, COOLDOWN_EMOTE_FART, 3 SECONDS)

/datum/emote/living/audio/cackle
	key = "cackle"
	key_third_person = "cackles"
	message = "cackles hysterically!"
	message_mime = "cackles silently!"
	emote_sound = 'modular_splurt/sound/voice/cackle_yeen.ogg'
	emote_cooldown = 5 SECONDS

/datum/emote/living/audio/speen
	key = "speen"
	key_third_person = "speens"
	message = "speeeeens!"
	message_mime = "speeeeens silently!"
	restraint_check = TRUE
	mob_type_allowed_typecache = list(/mob/living)
	emote_sound = 'modular_splurt/sound/voice/speen.ogg'
	// No cooldown var required

/datum/emote/living/audio/speen/run_emote(mob/user, params)
	. = ..()

	// Check parent return
	if(!.)
		return

	// Spin user
	user.spin(20, 1)

	// Check for cyborg
	// Check for buckled mobs
	if(iscyborg(user) && user.has_buckled_mobs())
		// Define cyborg user
		var/mob/living/silicon/robot/user_cyborg = user

		// Define riding datum
		var/datum/component/riding/riding_datum = user_cyborg.GetComponent(/datum/component/riding)

		// Check if riding datum exists
		if(riding_datum)
			// Iterate over buckled mobs
			for(var/mob/buckled_mob in user_cyborg.buckled_mobs)
				// Unbuckle iterated mob
				riding_datum.force_dismount(buckled_mob)

		// Riding datum does not exist
		else
			// Unbuckle all mobs
			user_cyborg.unbuckle_all_mobs()

/datum/emote/living/audio/chirp
	key = "chirp"
	key_third_person = "chirps"
	message = "chirps!"
	message_mime = "chirps silently!"
	emote_sound = 'modular_splurt/sound/voice/chirp.ogg'

/datum/emote/living/audio/caw
	key = "caw"
	key_third_person = "caws"
	message = "caws!"
	message_mime = "caws silently!"
	emote_sound = 'modular_splurt/sound/voice/caw.ogg'

/datum/emote/living/audio/burp
	key = "burp"
	key_third_person = "burps"
	message = "рыгает."
	emote_cooldown = 20 SECONDS
	emote_sound = 'modular_splurt/sound/voice/burps/belch1.ogg'

/datum/emote/living/audio/burp/run_emote(mob/user, params, type_override, intentional)
	// Check if user is muzzled
	if(user.is_muzzled())
		// Set muzzled sound
		emote_sound = 'modular_splurt/sound/voice/bababooey/ffff.ogg'

	// User is not muzzled
	else
		emote_sound = pick('modular_splurt/sound/voice/burps/belch1.ogg','modular_splurt/sound/voice/burps/belch2.ogg','modular_splurt/sound/voice/burps/belch3.ogg','modular_splurt/sound/voice/burps/belch4.ogg',
		'modular_splurt/sound/voice/burps/belch5.ogg','modular_splurt/sound/voice/burps/belch6.ogg','modular_splurt/sound/voice/burps/belch7.ogg','modular_splurt/sound/voice/burps/belch8.ogg',
		'modular_splurt/sound/voice/burps/belch9.ogg','modular_splurt/sound/voice/burps/belch10.ogg','modular_splurt/sound/voice/burps/belch11.ogg','modular_splurt/sound/voice/burps/belch12.ogg',
		'modular_splurt/sound/voice/burps/belch13.ogg','modular_splurt/sound/voice/burps/belch14.ogg','modular_splurt/sound/voice/burps/belch15.ogg')

	// Return normally
	. = ..()

/datum/emote/living/audio/bleat
	key = "bleat"
	key_third_person = "bleats"
	message = "bleats loudly!"
	message_mime = "bleats silently!"
	emote_sound = 'modular_splurt/sound/voice/bleat.ogg'
	emote_cooldown = 3 SECONDS

/datum/emote/living/carbon/moan/run_emote(mob/user, params, type_override, intentional) //I can't not port this shit, come on.
	if(user.stat != CONSCIOUS)
		return
	var/sound
	var/miming = user.mind ? user.mind.miming : 0
	if(!user.is_muzzled() && !miming)
		if(user.gender != FEMALE || (user.gender == PLURAL && ismasculine(user)))
			sound = pick('modular_splurt/sound/voice/moan_m1.ogg', 'modular_splurt/sound/voice/moan_m2.ogg', 'modular_splurt/sound/voice/moan_m3.ogg')
		if(user.gender == FEMALE || (user.gender == PLURAL && isfeminine(user)))
			sound = pick('modular_splurt/sound/voice/moan_f1.ogg', 'modular_splurt/sound/voice/moan_f2.ogg', 'modular_splurt/sound/voice/moan_f3.ogg', 'modular_splurt/sound/voice/moan_f4.ogg', 'modular_splurt/sound/voice/moan_f5.ogg', 'modular_splurt/sound/voice/moan_f6.ogg', 'modular_splurt/sound/voice/moan_f7.ogg')
		if(isalien(user))
			sound = 'sound/voice/hiss6.ogg'
		playsound(user.loc, sound, 50, 1, 4, 1.2)
		message = "moans!"
	else if(miming)
		message = "acts out a moan."
	else
		message = "makes a very loud noise."
	. = ..()

/datum/emote/living/audio/chitter2
	key = "chitter2"
	key_third_person = "chitters2"
	message = "chitters."
	message_mime = "chitters silently!"
	emote_sound = 'modular_splurt/sound/voice/moth/mothchitter2.ogg'

/datum/emote/living/audio/monkeytwerk
	key = "twerk"
	key_third_person = "twerks"
	message = "shakes it harder than James Russle himself!"
	emote_sound = 'modular_splurt/sound/misc/monkey_twerk.ogg'
	emote_cooldown = 13.2 SECONDS

/datum/emote/living/audio/bruh
	key = "bruh"
	key_third_person = "bruhs"
	message = "thinks this is a bruh moment."
	message_mime = "silently acknowledges the bruh moment."
	emote_sound = 'modular_splurt/sound/voice/bruh.ogg'
	emote_cooldown = 10.6 SECONDS

/datum/emote/living/audio/bababooey
	key = "bababooey"
	key_third_person = "bababooeys"
	message = "spews bababooey."
	message_mime = "spews something silently."
	emote_sound = 'modular_splurt/sound/voice/bababooey/bababooey.ogg'
	emote_cooldown = 5 SECONDS

/datum/emote/living/audio/bababooey/run_emote(mob/user, params)
	// Check if user is muzzled
	if(user.is_muzzled())
		// Set muzzled sound
		emote_sound = 'modular_splurt/sound/voice/bababooey/ffff.ogg'

	// User is not muzzled
	else
		// Set random emote sound
		emote_sound = pick('modular_splurt/sound/voice/bababooey/bababooey.ogg', 'modular_splurt/sound/voice/bababooey/bababooey2.ogg')

	// Return normally
	. = ..()

/datum/emote/living/audio/babafooey
	key = "babafooey"
	key_third_person = "babafooeys"
	message = "spews babafooey."
	message_mime = "spews something silently."
	emote_sound = 'modular_splurt/sound/voice/bababooey/babafooey.ogg'
	emote_cooldown = 5 SECONDS

/datum/emote/living/audio/fafafooey
	key = "fafafooey"
	key_third_person = "fafafooeys"
	message = "spews fafafooey."
	message_mime = "spews something silently."
	emote_sound = 'modular_splurt/sound/voice/bababooey/fafafooey.ogg'
	emote_cooldown = 5 SECONDS

/datum/emote/living/audio/fafafooey/run_emote(mob/user, params)
	// Check if user is muzzled
	if(user.is_muzzled())
		// Set muzzled sound
		emote_sound = 'modular_splurt/sound/voice/bababooey/ffff.ogg'

	// User is not muzzled
	else
		// Set random emote sound
		emote_sound = pick('modular_splurt/sound/voice/bababooey/fafafooey.ogg', 'modular_splurt/sound/voice/bababooey/fafafooey2.ogg', 'modular_splurt/sound/voice/bababooey/fafafooey3.ogg')

	// Return normally
	. = ..()

/datum/emote/living/audio/fafafoggy
	key = "fafafoggy"
	key_third_person = "fafafoggys"
	message = "spews fafafoggy."
	message_mime = "spews something silently."
	emote_sound = 'modular_splurt/sound/voice/bababooey/fafafoggy.ogg'
	emote_cooldown = 5 SECONDS

/datum/emote/living/audio/fafafoggy/run_emote(mob/user, params)
	// Check if user is muzzled
	if(user.is_muzzled())
		// Set muzzled sound
		emote_sound = 'modular_splurt/sound/voice/bababooey/ffff.ogg'

	// User is not muzzled
	else
		// Set random emote sound
		emote_sound = pick('modular_splurt/sound/voice/bababooey/fafafoggy.ogg', 'modular_splurt/sound/voice/bababooey/fafafoggy2.ogg')

	// Return normally
	. = ..()

/datum/emote/living/audio/hohohoy
	key = "hohohoy"
	key_third_person = "hohohoys"
	message = "spews hohohoy."
	message_mime = "spews something silently."
	emote_sound = 'modular_splurt/sound/voice/bababooey/hohohoy.ogg'
	emote_cooldown = 5 SECONDS

/datum/emote/living/audio/ffff
	key = "ffff"
	key_third_person = "ffffs"
	message = "spews something softly."
	message_mime = "spews something silently."
	muzzle_ignore = TRUE
	emote_sound = 'modular_splurt/sound/voice/bababooey/ffff.ogg'
	emote_cooldown = 5 SECONDS

/datum/emote/living/audio/fafafail
	key = "fafafail"
	key_third_person = "fafafails"
	message = "spews something unintelligible."
	message_mime = "spews something silent."
	emote_sound = 'modular_splurt/sound/voice/bababooey/ffffhvh.ogg'
	emote_cooldown = 5 SECONDS

/datum/emote/living/audio/boowomp
	key = "boowomp"
	key_third_person = "boowomps"
	message = "produces a sad boowomp."
	message_mime = "produces a silent boowomp."
	emote_sound = 'modular_splurt/sound/voice/boowomp.ogg'
	emote_cooldown = 5 SECONDS

/datum/emote/living/audio/swaos
	key = "swaos"
	key_third_person = "swaos"
	message = "mutters swaos."
	message_mime = "imitates swaos."
	emote_sound = 'modular_splurt/sound/voice/swaos.ogg'
	emote_cooldown = 10.7 SECONDS

/datum/emote/living/audio/eyebrow2
	key = "eyebrow2"
	key_third_person = "eyebrows2"
	message = "<b>raises an eyebrow.</b>"
	message_mime = "<b>raises an eyebrow with quaking force!</b>"
	emote_sound = 'modular_splurt/sound/voice/vineboom.ogg'
	emote_cooldown = 5 SECONDS

/datum/emote/living/audio/eyebrow3
	key = "eyebrow3"
	key_third_person = "eyebrows3"
	message = "raises an eyebrow <i>quizzaciously</i>."
	emote_sound = 'modular_splurt/sound/voice/moonmen.ogg'
	emote_cooldown = 15 SECONDS

/datum/emote/living/audio/blink2
	key = "blink2"
	key_third_person = "blinks2"
	message = "blinks."
	message_mime = "blinks expressively."
	emote_sound = 'modular_splurt/sound/voice/blink.ogg'
	emote_cooldown = 0

/datum/emote/living/audio/laugh2
	key = "laugh2"
	key_third_person = "laughs2"
	message = "laughs like a king."
	message_mime = "acts out laughing like a king."
	emote_sound = 'modular_splurt/sound/voice/laugh_king.ogg'
	// No cooldown var required

/datum/emote/living/audio/laugh3
	key = "laugh3"
	key_third_person = "laughs3"
	message = "laughs silly."
	message_mime = "acts out laughing silly."
	emote_sound = 'modular_splurt/sound/voice/lol.ogg'
	emote_cooldown = 15 SECONDS

/datum/emote/living/audio/laugh4
	key = "laugh4"
	key_third_person = "laughs4"
	message = "burst into laughter!"
	message_mime = "acts out bursting into laughter."
	emote_sound = 'modular_splurt/sound/voice/laugh_muta.ogg'
	emote_cooldown = 10 SECONDS

/datum/emote/living/audio/laugh5
	key = "laugh5"
	key_third_person = "laughs5"
	message = "laughs in Scottish."
	message_mime = "acts out laughing in Scottish."
	emote_sound = 'modular_splurt/sound/voice/laugh_deman.ogg'
	emote_cooldown = 10 SECONDS

/datum/emote/living/audio/laugh6
	key = "laugh6"
	key_third_person = "laughs6"
	message = "laughs like a kettle!"
	message_mime = "acts out laughing like a kettle."
	emote_sound = 'modular_splurt/sound/voice/laugh6.ogg'
	emote_cooldown = 10 SECONDS

/datum/emote/living/audio/breakbad
	key = "breakbad"
	key_third_person = "breakbads"
	message = "stares intensively with determination."
	emote_sound = 'modular_splurt/sound/voice/breakbad.ogg'
	emote_cooldown = 16.4 SECONDS

/datum/emote/living/audio/lawyerup
	key = "lawyerup"
	key_third_person = "lawyerups"
	message = "emits an aura of expertise."
	emote_sound = 'modular_splurt/sound/voice/lawyerup.ogg'
	emote_cooldown = 17.5 SECONDS

/datum/emote/living/audio/goddamn
	key = "damn"
	key_third_person = "damns"
	message = "is in utter stupor."
	message_mime = "appears to be in utter stupor."
	emote_sound = 'modular_splurt/sound/voice/god_damn.ogg'
	emote_cooldown = 11.25 SECONDS

/datum/emote/living/audio/spoonful
	key = "spoonful"
	key_third_person = "spoonfuls"
	message = "asks for a spoonful."
	message_mime = "pretends to ask for a spoonful."
	emote_sound = 'modular_splurt/sound/voice/spoonful.ogg'
	// No cooldown var required

/datum/emote/living/audio/ohhmygod
	key = "mygod"
	key_third_person = "omgs"
	message = "invokes the presence of Jesus Christ."
	message_mime = "invokes the presence of Jesus Christ through silent prayer."
	emote_sound = 'modular_splurt/sound/voice/OMG.ogg'
	emote_cooldown = 11.6 SECONDS

/datum/emote/living/audio/whatthehell
	key = "wth"
	key_third_person = "wths"
	message = "condemns the abysses of hell!"
	message_mime = "silently condemns the abysses of hell!"
	emote_sound = 'modular_splurt/sound/voice/WTH.ogg'
	emote_cooldown = 14.4 SECONDS

/datum/emote/living/audio/fusrodah
	key = "fusrodah"
	key_third_person = "furodahs"
	message = "yells, \"<b>FUS RO DAH!!!</b>\""
	message_mime = "acts out a dragon shout."
	emote_sound = 'modular_splurt/sound/voice/fusrodah.ogg'
	emote_cooldown = 17 SECONDS

/datum/emote/living/audio/skibidi
	key = "skibidi"
	key_third_person = "skibidis"
	message = "yells, \"<b>Skibidi bop mm dada!</b>\""
	message_mime = "makes incoherent mouth motions."
	emote_sound = 'modular_splurt/sound/voice/skibidi.ogg'
	emote_cooldown = 11.1 SECONDS

/datum/emote/living/audio/fbi
	key = "fbi"
	key_third_person = "fbis"
	message = "yells, \"<b>FBI OPEN UP!</b>\""
	message_mime = "acts out being the FBI."
	emote_sound = 'modular_splurt/sound/voice/fbi.ogg'
	emote_cooldown = 12 SECONDS

/datum/emote/living/audio/illuminati
	key = "illuminati"
	key_third_person = "illuminatis"
	message = "exudes a mysterious aura!"
	emote_sound = 'modular_splurt/sound/voice/illuminati.ogg'
	emote_cooldown = 17.8 SECONDS

/datum/emote/living/audio/bonerif
	key = "bonerif"
	key_third_person = "bonerifs"
	message = "riffs!"
	message_mime = "riffs silently!"
	emote_sound = 'modular_splurt/sound/voice/bonerif.ogg'
	emote_cooldown = 10 SECONDS

/datum/emote/living/audio/cry2
	key = "cry2"
	key_third_person = "cries2"
	message = "cries like a king."
	message_mime = "acts out crying like a king."
	emote_sound = 'modular_splurt/sound/voice/cry_king.ogg'
	emote_cooldown = 5 SECONDS // Uses longest sound's time

/datum/emote/living/audio/cry2/run_emote(mob/user, params)
	// Set random emote sound
	emote_sound = pick('modular_splurt/sound/voice/cry_king.ogg', 'modular_splurt/sound/voice/cry_king2.ogg')

	// Return normally
	. = ..()

/datum/emote/living/audio/choir
	key = "choir"
	key_third_person = "choirs"
	message = "let out a choir!"
	message_mime = "acts out a choir."
	emote_sound = 'modular_splurt/sound/voice/choir.ogg'
	emote_cooldown = 16 SECONDS

/datum/emote/living/audio/agony
	key = "agony"
	key_third_person = "agonys"
	message = "let out a choir of agony!"
	message_mime = "is visibly in agony."
	emote_sound = 'modular_splurt/sound/voice/agony.ogg'
	emote_cooldown = 17 SECONDS

/datum/emote/living/audio/wtune
	key = "whistle_tune"
	key_third_person = "whistle_tunes"
	message = "насвистывает мелодию."
	message_mime = "имитирует насвистывание своем ртом."
	emote_sound = 'modular_splurt/sound/voice/wtune1.ogg'
	emote_cooldown = 6 SECONDS // Uses longest sound's time.

/datum/emote/living/audio/wtune/run_emote(mob/user, params)
	// Set random emote sound
	emote_sound = pick('modular_splurt/sound/voice/wtune1.ogg', 'modular_splurt/sound/voice/wtune2.ogg')

	// Return normally
	. = ..()

/datum/emote/living/audio/terror
	key = "terror"
	key_third_person = "terrors"
	message = "насвистывает какую-то жуткую мелодию..."
	message_mime = "смотрит на вас взглядом, полным ужаса..."
	emote_sound = 'modular_splurt/sound/voice/terror1.ogg'
	emote_cooldown = 13.07 SECONDS // Uses longest sound's time.

/datum/emote/living/audio/terror/run_emote(mob/user, params)
	// Set random emote sound
	emote_sound = pick('modular_splurt/sound/voice/terror1.ogg', 'modular_splurt/sound/voice/terror2.ogg')

	// Return normally
	. = ..()

/datum/emote/living/audio/sicko
	key = "sicko"
	key_third_person = "sickos"
	message = "briefly goes sicko mode!"
	message_mime = "briefly imitates sicko mode!"
	emote_sound = 'modular_splurt/sound/voice/sicko.ogg'
	emote_cooldown = 5 SECONDS

/datum/emote/living/audio/chill
	key = "chill"
	key_third_person = "chills"
	message = "feels a chill running down their spine..."
	message_mime = "acts out a chill running down their spine..."
	emote_sound = 'modular_splurt/sound/voice/waterphone.ogg'
	emote_cooldown = 13.4 SECONDS

/datum/emote/living/audio/taunt
	key = "tt"
	key_third_person = "taunts"
	message = "strikes a pose!"
	message_param = "taunts %t!"
	emote_sound = 'modular_splurt/sound/voice/phillyhit.ogg'

/datum/emote/living/audio/taunt/alt
	key = "tt2"
	key_third_person = "taunts2"
	emote_sound = 'modular_splurt/sound/voice/orchestrahit.ogg'

/datum/emote/living/audio/weh2
	key = "weh2"
	key_third_person = "wehs2"
	message = "let out a weh!"
	message_mime = "acts out a weh!"
	emote_sound = 'modular_splurt/sound/voice/weh2.ogg'
	emote_cooldown = 3 SECONDS

/datum/emote/living/audio/weh3
	key = "weh3"
	key_third_person = "wehs3"
	message = "let out a weh!"
	message_mime = "acts out a weh!"
	emote_sound = 'modular_splurt/sound/voice/weh3.ogg'
	emote_cooldown = 3 SECONDS

/datum/emote/living/audio/weh4
	key = "weh-s"
	key_third_person = "wehs4"
	message = "let out a surprised weh!"
	message_mime = "acts out a surprised weh!"
	emote_sound = 'modular_splurt/sound/voice/weh_s.ogg'
	emote_cooldown = 3 SECONDS

/datum/emote/living/audio/waa
	key = "waa"
	key_third_person = "waas"
	message = "let out a waa!"
	message_mime = "acts out a waa!"
	emote_sound = 'modular_splurt/sound/voice/waa.ogg'
	emote_cooldown = 10 SECONDS

/datum/emote/living/audio/bark2
	key = "bark2"
	key_third_person = "barks2"
	message = "barks!"
	message_mime = "acts out a bark!"
	emote_sound = 'modular_splurt/sound/voice/bark_alt.ogg'

/datum/emote/living/audio/yap
	key = "yap"
	key_third_person = "yaps"
	message = "yaps!"
	message_mime = "acts out a yap!"
	emote_sound = 'modular_splurt/sound/voice/yap.ogg'

/datum/emote/living/audio/woof
	key = "woof"
	key_third_person = "woofs"
	message = "woofs!"
	message_mime = "acts out a woof!"
	emote_sound = 'modular_splurt/sound/voice/woof.ogg'

/datum/emote/living/audio/howl
	key = "howl"
	key_third_person = "howls"
	message = "howls!"
	message_mime = "acts out a howl!"
	emote_sound = 'modular_splurt/sound/voice/wolfhowl.ogg'
	emote_cooldown = 5 SECONDS
	emote_volume = 100

/datum/emote/living/audio/howl/run_emote(mob/user, params)
	if (HAS_TRAIT(user, TRAIT_AWOO))
		var/mob/living/carbon/M = user
		var/datum/quirk/awoo/quirk_target = locate() in M.roundstart_quirks
		quirk_target.last_awoo = world.time
		quirk_target.chance = quirk_target.default_chance
		SEND_SIGNAL(user, COMSIG_ADD_MOOD_EVENT, "to_awoo", /datum/mood_event/to_awoo)
	. = ..()

/datum/emote/living/audio/coyhowl
	key = "coyhowl"
	key_third_person = "coyhowls"
	message = "howls like coyote!"
	message_mime = "acts out a coyote's howl!"
	emote_sound = 'modular_splurt/sound/voice/coyotehowl.ogg'
	emote_cooldown = 5 SECONDS // Uses longest sound's time

/datum/emote/living/audio/coyhowl/run_emote(mob/user, params)
	emote_sound = pick('modular_splurt/sound/voice/coyotehowl.ogg', 'modular_splurt/sound/voice/coyotehowl2.ogg', 'modular_splurt/sound/voice/coyotehowl3.ogg', 'modular_splurt/sound/voice/coyotehowl4.ogg', 'modular_splurt/sound/voice/coyotehowl5.ogg')
	. = ..()

/datum/emote/living/mlem
	key = "mlem"
	key_third_person = "mlems"
	message = "sticks their tongue for a moment. Mlem!"
	emote_type = EMOTE_VISIBLE

/datum/emote/living/audio/snore/snore2
	key = "snore2"
	key_third_person = "snores2"
	message = "lets out an <b>earthshaking</b> snore"
	message_mime = "lets out an <b>inaudible</b> snore!"
	emote_sound = 'modular_splurt/sound/voice/aauugghh1.ogg'
	emote_cooldown = 12.1 SECONDS

/datum/emote/living/audio/snore/snore2/run_emote(mob/user, params)
	var/datum/dna/D = user.has_dna()
	var/say_mod = (D ? D.species.say_mod : "says")
	var/list/aaauughh = list(
		"lets out an <b>earthshaking</b> snore.",
		"lets out what sounds like a <b>painful</b> snore.",
		"[say_mod], <b>\"AAAAAAUUUUUUGGGHHHHH!!!\"</b>"
	)
	message = pick(aaauughh)

	// Set random emote sound
	emote_sound = pick('modular_splurt/sound/voice/aauugghh1.ogg', 'modular_splurt/sound/voice/aauugghh2.ogg')

	// Return normally
	. = ..()

/datum/emote/living/pant
	key = "pant"
	key_third_person = "pants"
	message = "pants!"

/datum/emote/living/pant/run_emote(mob/user, params, type_override, intentional)
	var/list/pants = list(
		"pants!",
		"pants like a dog.",
		"lets out soft pants.",
		"pulls [user.p_their()] tongue out, panting."
	)
	message = pick(pants)
	. = ..()

/datum/emote/living/audio/yippee
	key = "yippee"
	key_third_person = "yippees"
	message = "lets out a yippee!"
	message_mime = "acts out a yippee!"
	emote_sound = 'modular_splurt/sound/voice/yippee.ogg'
	emote_cooldown = 11.2 SECONDS

/datum/emote/living/audio/mewo
	key = "mewo"
	key_third_person = "mewos"
	message = "mewos!"
	message_mime = "mewos silently!"
	emote_sound = 'modular_splurt/sound/voice/mewo.ogg'
	emote_cooldown = 3 SECONDS

/datum/emote/living/audio/ara_ara
	key = "ara"
	key_third_person = "aras"
	message = "coos with sultry surprise~..."
	message_mime = "exudes a sultry aura~"
	emote_sound = 'modular_splurt/sound/voice/ara-ara.ogg'
	emote_cooldown = 5 SECONDS

/datum/emote/living/audio/ara_ara/alt
	key = "ara2"
	emote_sound = 'modular_splurt/sound/voice/ara-ara2.ogg'
	emote_cooldown = 5 SECONDS

/datum/emote/living/audio/missouri
	key = "missouri"
	key_third_person = "missouris"
	message = "has relocated to Missouri."
	message_mime = "starts thinking about Missouri."
	emote_sound = 'modular_splurt/sound/voice/missouri.ogg'
	emote_cooldown = 13.4 SECONDS

/datum/emote/living/audio/missouri/run_emote(mob/user, params)
	// Set message pronouns
	message = "appears to believe [user.p_theyre()] in Missouri."

	// Return normally
	. = ..()

/datum/emote/living/audio/facemetacarpus
	key = "facehand" // Facepalm was taken
	key_third_person = "facepalms"
	// Message is generated from metacarpus_type below. You shouldn't see this!
	message = "creates an error in the code." // Hear a slapping sound
	muzzle_ignore = TRUE // Not a spoken emote
	restraint_check = TRUE // Uses your hands
	emote_sound = 'modular_splurt/sound/effects/slap.ogg'
	// Defines appendage type for generated message
	var/metacarpus_type = "palm" // Default to hands
	emote_cooldown = 0

/datum/emote/living/audio/facemetacarpus/run_emote(mob/user, params)
	// Randomly pick a message using metacarpus_type for hand
	message = pick(list(
			"places [usr.p_their()] [metacarpus_type] across [usr.p_their()] face.",
			"lowers [usr.p_their()] face into [usr.p_their()] [metacarpus_type].",
			"face[metacarpus_type]s",
		))

	// Return normally
	. = ..()

/datum/emote/living/audio/facemetacarpus/paw
	key = "facepaw" // For furries
	key_third_person = "facepaws"
	metacarpus_type = "paw"

/datum/emote/living/audio/facemetacarpus/claw
	key = "faceclaw" // For scalies and avians
	key_third_person = "faceclaws"
	metacarpus_type = "claw"

/datum/emote/living/audio/facemetacarpus/hoof
	key = "facehoof" // For horse enthusiasts
	key_third_person = "facehoofs"
	metacarpus_type = "hoof"

/datum/emote/living/audio/poyo
	key = "poyo"
	key_third_person = "poyos"
	message = "%SAYS, \"Poyo!\""
	message_mime = "acts out an excited motion!"
	emote_sound = 'modular_splurt/sound/voice/barks/poyo.ogg'
	// No cooldown var required

/datum/emote/living/audio/poyo/run_emote(mob/user, params)
	var/datum/dna/D = user.has_dna()
	var/say_mod = (D ? D.species.say_mod : "says")
	message = replacetextEx(message, "%SAYS", say_mod)

	// Return normally
	. = ..()
