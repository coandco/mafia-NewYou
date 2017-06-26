script "NewYou.ash"
notify "digitrev";

import "zlib.ash";
import "canadv.ash"

skill _sk;
monster _mon;
int _amount;
location _loc;

location WhichLocation(location l){
	if (l.to_string().contains_text("Frat")){
		foreach f in $locations[Wartime Frat House,Frat House,The Orcish Frat House (Bombed Back to the Stone Age)]{
			if (can_adv(f))
				return f;
		}
	}
	return l;
}

void readCorrespondence(){
	load_kmail();
	string mtext;
	int timestamp = 0;
	foreach i, m in mail{
		if (m.fromname == "The New-You Club" && m.azunixtime > timestamp){
			mtext = m.message;
			timestamp = m.azunixtime;
		}
	}

	//Cast Dissonant Riff, once per fight, against a Wardröb nightstand 8 times (look in The Haunted Bedroom)
	//matcher m = create_matcher("Cast ([^,]+), once per fight, against a (.+) ([0-9]+) times \\(look in the (.+)\\)", mtext);
	matcher m = create_matcher("Cast ([^,]+), once per fight, against (a|an|some|the)? (.+) ([0-9]+) times \\(look in (.+?)\\)", mtext);
	while (m.find()) {
		_sk = m.group(1).to_skill();
		matcher u00 = create_matcher("\\\\u00..", m.group(3));
		if (u00.find())
			_mon = u00.replace_all("").to_monster();
		else 
			_mon = m.group(3).to_monster();
		_amount = m.group(4).to_int();
		_loc = m.group(5).replace_string("\\", "").to_location().WhichLocation(); //" This silly comment is only here to fix my poorly written syntax parser
	}
}

void SharpenSaw() {
	int MonstersFought = get_property("_NewYou.SawsSharpened").to_int();
	while (MonstersFought < _amount){
		string combatText;
		cli_execute(get_property("betweenBattleScript"));
		string page_text = _loc.to_url().visit_url();
		if (page_text.contains_text("Combat") && (last_monster() == _mon || _mon == $monster[none])) {
			if (have_skill($skill[Transcendent Olfaction]) && $effect[On the Trail].have_effect() <= 0) {
				use_skill($skill[Transcendent Olfaction]);
			}
			combatText = use_skill(_sk);
		}
		run_turn();
//		string combatText = run_combat();
		if (combatText.contains_text("You're really sharpening the old saw.")) {
			matcher m = create_matcher("Looks like you've done ([0-9]+) out of [0-9]+!", combatText);
			if (m.find()) {
				MonstersFought = m.group(1).to_int();
				print("Fought " + MonstersFought + " " + _mon + " out of " + _amount, "blue");
			} else {
				MonstersFought += 1;
			}
		} else if (combatText.contains_text("Your saw is so sharp!")) {
			MonstersFought = _amount;
		}
		set_property("_NewYou.SawsSharpened", MonstersFought.to_string());
	}
}

void NewYou(){
	if (my_inebriety() > inebriety_limit())
		abort("Sharpening your saw right now would be dangerous. You're too drunk to hold even a rusty saw right now.");
	if (eudora() != "New-You Club")
		abort("You should set your Eudora to the New-You Club before running this.");
	readCorrespondence();
	if (_loc == $location[none] || _amount == 0 || _sk == $skill[none]){
		abort("Parsing failed. Please message digitrev with the New You correspondence text, and he'll do what he can.");
	}
	if (_mon != $monster[none]){
		effect olf = $effect[On the Trail];
		if (olf.have_effect() > 0 && get_property("olfactedMonster").to_monster() != _mon)
			cli_execute("uneffect On the Trail");
		set_property("autoOlfact", "monster " + _mon.to_string());
	}
	SharpenSaw();
	print("Your saw is so sharp!", "blue");
}

void main(){
	NewYou();
}

