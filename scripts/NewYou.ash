script "NewYou.ash";
notify "digitrev";

import "zlib.ash";
import "canadv.ash";

skill _sk_NewYou;
monster _mon_NewYou;
int _amount_NewYou;
location _loc_NewYou;

location WhichLocation(location l){
	if (l.to_string() == "The Icy Peak") {
		if (numeric_modifier("cold resistance") < 5.0) {
		    print("Not enough cold resistance to adventure in The Icy Peak", "red");
			return $location[none];
		}
	}
	if (l.to_string().contains_text("Frat")) {
		foreach f in $locations[Wartime Frat House,Frat House,The Orcish Frat House (Bombed Back to the Stone Age)]{
			if (can_adv(f))
				return f;
		}
	}
	return l;
}

monster fixedmon(string monstr) {
	if (to_monster(monstr) != $monster[none]) return to_monster(monstr);
	switch (monstr) {
		case "Orcish Frat Boy": return $monster[orcish frat boy (music lover)];
		case "Ninja Snowman": return $monster[ninja snowman (chopsticks)];
	}
	return $monster[none];
}

void checkQuest() {
    string quest_text = visit_url("questlog.php?which=1");
	matcher m = create_matcher("Looks like you've cast (.+?) during (\\d+) of the required (\\d+) encounters with  ?(?:a|an|some|the) (.+?)!", quest_text);
	if (m.find()) {
		_mon_NewYou = fixedmon(m.group(4));
		_sk_NewYou = m.group(1).to_skill();
		_amount_NewYou = m.group(3).to_int();
		if (_mon_NewYou == $monster[none]) {
			print("Unable to identify monster '"+m.group(4)+"'", "red");
			return;
		}
		set_property("_newYouMonster", _mon_NewYou);
		set_property("_newYouSkill", _sk_NewYou);
		set_property("_newYouSharpeningsCast", m.group(2));
		set_property("_newYouSharpeningsNeeded", _amount_NewYou);

		foreach l in $locations[] {
			float highest_rate = 0;
			if (!l.nocombats) {
				foreach mon,rate in appearance_rates(l) {
					if (mon == _mon_NewYou && can_adv(l) && rate > highest_rate) {
					    highest_rate = rate;
						_loc_NewYou = l;
						set_property("_newYouLocation", l.to_string());
						print("Found in "+l+" with an appearance rate of "+rate);
					}
				}
			}
		}
	} else {
		// We didn't find the full quest text in the quest log.  Check to see if the quest is there at all.
		matcher quest_there = create_matcher("New-You VIP Club", quest_text);
		if (quest_there.find())
			abort("The New-You quest is present, but parsing failed.  Please message CrankyOne with the New-You text from your quest log, and he'll see what he can do.");
	}
}

void SharpenSaw() {
	// BatBrain now olfacts, uses the correct skill, and keeps track of sharpenings automatically
	while (get_property("_newYouSharpeningsCast").to_int() < get_property("_newYouSharpeningsNeeded").to_int()) {
		if (get_property("_newYouUseBatBrain").to_boolean()) {
			boolean success = adventure(1,_loc_NewYou);

			// A location can become unavailable mid-adventure (if, for example, your location is McMillicancuddy's Farm)
			if (!success)
				abort("Could not adventure at " + _loc_NewYou);
		} else {
			string combatText;
			int MonstersFought = get_property("_newYouSharpeningsCast").to_int();
			cli_execute(get_property("betweenBattleScript"));
			string page_text = _loc_NewYou.to_url().visit_url();
			if (page_text.contains_text("Combat") && (last_monster() == _mon_NewYou || _mon_NewYou == $monster[none])) {
				if (have_skill($skill[Transcendent Olfaction]) && $effect[On the Trail].have_effect() <= 0) {
					use_skill($skill[Transcendent Olfaction]);
				}
				combatText = use_skill(_sk_NewYou);
			}
			run_turn();
			if (combatText.contains_text("You're really sharpening the old saw.")) {
					matcher m = create_matcher("Looks like you've done ([0-9]+) out of [0-9]+!", combatText);
					if (m.find()) {
							MonstersFought = m.group(1).to_int();
					} else {
							MonstersFought += 1;
					}
			} else if (combatText.contains_text("Your saw is so sharp!")) {
					MonstersFought = _amount_NewYou;
			}
			set_property("_newYouSharpeningsCast", MonstersFought.to_string());
		}

		string msg = "New You progress: cast " + _sk_NewYou + " " + get_property("_newYouSharpeningsCast") + " of ";
		msg = msg + get_property("_newYouSharpeningsNeeded") + " times against " + _mon_NewYou + " at " + _loc_NewYou;
		print(msg, "blue");
	}
}

void NewYou(int saw_max, boolean useBatBrain){
	set_property("_newYouUseBatBrain", useBatBrain);
	if (my_inebriety() > inebriety_limit())
		abort("Sharpening your saw right now would be dangerous. You're too drunk to hold even a rusty saw right now.");
	if (eudora() != "New-You Club")
		abort("You should set your Eudora to the New-You Club before running this.");
	checkQuest();
	if (_loc_NewYou == $location[none] || _amount_NewYou == 0 || _sk_NewYou == $skill[none]){
		// This doesn't need to abort and kill upstream scripts if you don't have the quest in your log
		print("No New-You quest, so there's nothing to do", "blue");
		return;
	}
	if (_mon_NewYou == $monster[none]) {
		print("The requested monster has multiple variants, and this script doesn't account for them yet.  Please message CrankyOne with today's quest text and he'll see what he can do.", "blue");
		return;
	}
	if (saw_max > 0 && _amount_NewYou > saw_max) {
		print("Quest would take too long (must fight " + _amount_NewYou + " " + _mon_NewYou + ", limit is " + saw_max + ")", "blue");
		return;
	}
	if (_mon_NewYou != $monster[none]){
		effect olf = $effect[On the Trail];
		if (olf.have_effect() > 0 && get_property("olfactedMonster").to_monster() != _mon_NewYou)
			cli_execute("uneffect On the Trail");
	}
	SharpenSaw();
	print("Your saw is so sharp!", "blue");
}

void NewYou(boolean useBatBrain) {
	// If called without arguments, don't limit the maximum number of saws needed
	NewYou(0, useBatBrain);
}

void main(boolean useBatBrain){
	NewYou(useBatBrain);
}

