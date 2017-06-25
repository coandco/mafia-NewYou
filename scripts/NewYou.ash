script "NewYou.ash"
notify "digitrev";

import "zlib.ash";
import "canadv.ash"

skill sk;
monster mon;
int amount;
location loc;

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
	matcher m = create_matcher("Cast ([^,]+), once per fight, against (a|an|some)? (.+) ([0-9]+) times \\(look in (.+?)\\)", mtext);
	while (m.find()) {
		sk = m.group(1).to_skill();
		matcher u00 = create_matcher("\\\\u00..", m.group(3));
		if (u00.find())
			mon = u00.replace_all("").to_monster();
		else 
			mon = m.group(3).to_monster();
		amount = m.group(4).to_int();
		loc = m.group(5).replace_string("\\", "").to_location().WhichLocation(); //" This silly comment is only here to fix my poorly written syntax parser
	}
}

string NewYouCCS (int r, monster m, string t){
	if (m != mon){
		return get_ccs_action(r);
	}
	else if (r == 0){
		return "skill " + sk.to_string();
	}
	else{
		return get_ccs_action(r-1);
	}
}

void SharpenSaw(){
	int MonstersFought = get_property("_NewYou.SawsSharpened").to_int();
	while (MonstersFought < amount){
		//adventure(1, loc, "NewYouCCS");
		string combatText;
		cli_execute(get_property("betweenBattleScript"));
		string page_text = loc.to_url().visit_url();
		if (page_text.contains_text("Combat") && (last_monster() == mon || mon == $monster[none]))
			combatText = use_skill(sk);
		run_turn();
//		string combatText = run_combat();
		if (combatText.contains_text("You're really sharpening the old saw."))
			MonstersFought += 1;
		else if (combatText.contains_text("Your saw is so sharp!"))
			MonstersFought = amount;
		set_property("_NewYou.SawsSharpened", MonstersFought.to_string());
	}
}

void NewYou(){
	if (my_inebriety() > inebriety_limit())
		abort("Sharpening your saw right now would be dangerous. You're too drunk to hold even a rusty saw right now.");
	if (eudora() != "New-You Club")
		abort("You should set your Eudora to the New-You Club before running this.");
	readCorrespondence();
	if (loc == $location[none] || amount == 0 || sk == $skill[none]){
		abort("Parsing failed. Please message digitrev with the New You correspondence text, and he'll do what he can.");
	}
	if (mon != $monster[none]){
		effect olf = $effect[On the Trail];
		if (olf.have_effect() > 0 && get_property("olfactedMonster").to_monster() != mon)
			cli_execute("uneffect On the Trail");
		set_property("autoOlfact", "monster " + mon.to_string());
	}
	SharpenSaw();
	print("Your saw is so sharp!", "blue");
}

void main(){
	NewYou();
}