since r26249;
import <smmResourcePlanner.ash>

string __smm_utils_version = "1.0";


/*
A collection of utilities for Kingdom of Loathing.

To use the functions from this ASH file in the gCLI, do this:
using smmUtils.ash;

You can then call any function in this file from the command line. For example:
itemDescription (pantogram pants);
     NOTE this ^ space between the name of the subroutine and the parenthesis is important for some reason

Functions without any params must be called without the empty parens (), e.g.:
timeToRollover;

To stop using this on the gCLI, do:
get commandLineNamespace
set commandLineNamespace=
(if you have other files that you are "using", the first command will show them -- you'll
have to re-"using" them after resetting the name space)

@author Sacha Mallais (TQuilla #2771003)
*/

// -------------------------------------
// DATA TYPES, CONSTANTS, AND DATA
// -------------------------------------

// aborts with abortString if asserted is not true
void assert(boolean asserted, string abortString) {
	if (!asserted)
		abort("assertion failed: " + abortString);
}



record IntRange {
	int top;
	int bottom;
};



// abstracts the notion of an adventure to include not just a location but also item uses and skill uses.
// this uniquely identifies a single method to start an adventure
// One and only one field should be filled out, all others should be none / empty.
record AdventureRecord {
	location locationToUse;
	skill skillToUse;
	item itemToUse;
	string funcString; // name of a function called with "call"
};



record ChoiceRecord {
   int choiceNum;
   string choiceString;
};



record ItemDropRecord {
   item drop;
   int rate;
   string type;
};

// this uniquely identifies a single action to take in combat
// One and only one field should be filled out, all others should be false/none.
record ActionRecord {
	boolean attack;
	boolean pickpocket;
	skill skillToUse;
	item itemToUse;
	item item2ToUse;
};



// record BanishRecord {
// 	skill skillUsed;
// 	int turnUsed;
// 	monster monsterBanished;
// 	phylum phylumBanished;
// };

record BanishTrackRecord {
	monster targettedMonster;
	phylum targettedPhylum; // only used with banishing
	skill skillUsed;
	int turnUsed; // the turn count on which the banish or tracker skill was used
};


record PrioritySkillRecord {
	skill theSkill;			// OLD
	item theItem;        	// OLD item to equip/use(?) to enable/cast(?) the skill
	int mpCost;             // estimated cost of the skill in mp
	int meatCost;           // estimated cost of the skill in meat -- use the default cost of a turn if the skill costs turns (such as Batter Up!)
	float priority;         // whole part is the group, fractional part only affects which is chosen if usesAvailable are equal
	int usesAvailable;      // number available to use assuming all conditions are met (i.e. the item is worn, have enough mana, etc.)
	boolean isAvailableNow; // if we had uses available, could we cast it now?
};


// the final version of the priority scheme
record PriorityRecord {
	string cliExecuteString;   // when this game object is used outside of combat (skill, potion, item)
	string customCombatString; // when this game object is used in combat (skill, item, potion, combat item)
	string maximizeString;	   // NEW string to run through maximize to ensure we are dressed properly
	int mpCost;                // estimated cost of the skill in mp
	int meatCost;              // estimated cost of the skill in meat -- use the default cost of a turn if the skill costs turns (such as Batter Up!)
	int duration;              // duration of the effect, if applicable
	float priority;            // whole part is the group, fractional part only affects which is chosen if other things are equal
	int usesAvailable;         // number available to use assuming all conditions are met (i.e. the item is worn, have enough mana, etc.)
	boolean isAvailableNow;    // if we had uses available, could we cast it now?
};



// represents a single buff, with its buff amount, duration, opportunity cost, and effect. for use with analysis tools such as buffColdRes
record AnalyzeRecord {
	int buffAmount; // amount of the buff, either in percent or absolute terms
	boolean buffIsPercentBased;
	int duration;
	int opportunityCost; // turn cost, spleen cost, etc.
	effect theEffect;
	string activationString; // CLI string where %d is number of activations, e.g. "synthesize %d Synthesis: Cold". default activations are handled automatically (use, chew, eat, drink)
};



int kMaxInt = 2147483647;
int kMinInt = -2147483648;
int kUnlimitedUses = 1000; // a number we could never expect to use in a day
int kIndefiniteBanish = 500; // roughly the most turns we can expect to do in a day

int kTurnValue = "smm.TurnValue".get_property() == "" ? 5000 : get_property("smm.TurnValue").to_int(); // the value of a turn

item kSpleenItem = $item[grim fairy tale];
item kFillerSpleenItem = $item[prismatic wad];
float kTurnsPerSpleen = 1.88;
int kSpleenValue = kTurnsPerSpleen * kTurnValue; // the value of a spleen point

// int kCraftingTurnValue = min(2 * kSpleenValue / 11, // 2 spleen is 11 turns of crafting
// 							mall_price($item[Inigo's Incantation of Inspiration]) / 4);
int kCraftingTurnValue = 750; // somewhere between 500 and 1000 probably

// number of turns we expect to run today
int kExpectedDailyTurns = 500;

float kExpectedDamageSafetyFactor = 1.10;

float kPersueFamiliarIfOver = 1.0/3.0; // if a familiar is this much progress into getting a drop, include it as a default familiar choice (among other things, such as inclusion in mummery)
if (!can_interact()) kPersueFamiliarIfOver = 2.0/3.0; // get closer to done before including in default processing if we're in ronin

int gUnrestrictedManaToSave = 150; // save at least this much mana by default

string kDefaultMood = "current";
string kNoMood = "apathetic";

string kFloundrySpotsKey = "_floundryFishingSpots";

string kHadGoalsKey = "smm.HadGoals";

string kDCPropertyPrefix = "_smm.DCTop10For";

string kSavedOutfitKeyPrefix = "_smm.SavedOutfit";
string kSavedFamiliarKeyPrefix = "_smm.SavedFamiliar";
string kSavedFamiliarEquipKeyPrefix = "_smm.SavedFamiliarEquipment";
string kDefaultOutfit = "base";
string kForceDressupKey = "_smm.DressupForce";
string kDressupLocationKey = "_smm.DressupLocation";
string kDressupSelectorKey = "_smm.DressupSelector";
string kDressupFamiliarSelectorKey = "_smm.DressupFamiliarSelector";
string kDressupMaxStringKey = "_smm.DressupMaxString";
string kDressupLastFullMaxStringKey = "_smm.DressupLastFullMaxString";
string kDressupTweakStringKey = "_smm.DressupTweakString";
string kDressupSavedEquipSetKey = "smm.DressupSavedEquipSet";

string kCheckForLastSausageGoblinKey = "smm.CheckForLastSausageGoblin";

string kAgoraProgressKey = "smm.AgoraProgress";
string kSentientATMProgressKey = "smm.SentientATMProgress";
string kSmutOrcPervertProgressKey = "smm.SmutOrcPervertProgress";
string kLastSmutOrcPervertTurnsSpentKey = "smm.LastSmutOrcPervertTurnsSpent";

string kSpaceJellyfishDeepSauceCollectedKey = "_smm.SpaceJellyfishDeepSauceCollected";


// number of seconds between refreshing and restocking the store
int gkSecondsPerHour = 60 * 60;
int gkSecondsPerDay = gkSecondsPerHour * 24;
int gkStoreHeartbeat = 2 * gkSecondsPerHour * 1000; // 2 hr in milliseconds

int kCocoonHealing = 1000;

int kSausagesToGet = 11; // after this, the kramco grinder becomes low-priority equipment
int kSausagesToEat = 23;
int kMaxSausagesToEat = 23;


int kDreadsylvaniaCompleteTurns = 3000;
int kHobopolisCompleteTurns = 5000;
int kHobopolisTownCenterCompleteTurns = 2000;
int kHobopolisOutskirtsCompleteTurns = 500;


location [string, int] kAutumnatonUpgradeLocations = {
	"base_blackhat" : {$location[The Spooky Forest], $location[The Sleazy Back Alley], $location[8-Bit Realm], },
	"rightarm1" : {$location[The Old Landfill], $location[The Overgrown Lot], $location[Whitey's Grove], $location[The Goatlet], },
	"periscope" : {$location[Sonofa Beach], $location[The Hole in the Sky], $location[The Penultimate Fantasy Airship], $location[The Oasis], $location[McMillicancuddy's Granary], },
	"leftarm1" : {$location[The Haunted Pantry], },
	"rightleg1" : {$location[The Haunted Kitchen], $location[The Haunted Library], $location[A Barroom Brawl], $location[The Skeleton Store], $location[Gingerbread Industrial Zone], },
	"radardish" : {$location[The Red Zeppelin], $location[The Castle in the Clouds in the Sky (Top Floor)], },
	"leftleg1" : {$location[Noob Cave], $location[Cobb's Knob Barracks], $location[Cobb's Knob Kitchens], $location[The Haiku Dungeon], $location[The Batrat and Ratbat Burrow], $location[The Beanbat Chamber], },
	"cowcatcher" : {$location[The Daily Dungeon], $location[The Enormous Greater-Than Sign], $location[The Dungeons of Doom], $location[Itznotyerzitz Mine], $location[The Defiled Nook], $location[The Defiled Cranny], $location[The Defiled Alcove], $location[The Defiled Niche], },
	"dualexhaust" : {$location[The Castle in the Clouds in the Sky (Basement)], $location[The Haunted Boiler Room], $location[The Haunted Wine Cellar], $location[The Haunted Laundry Room], $location[The Upper Chamber], $location[The Middle Chamber], },
};

string [] kAutumnatonDesiredUpgrades = {"rightleg1", "leftleg1", "leftarm1", "rightarm1", "radardish", "periscope", "cowcatcher", };



int [string] kQualityStringToPerAdventureMap = {
	"crappy" : 1,
	"decent" : 2,
	"good" : 3,
	"awesome" : 4,
	"EPIC" : 5,
};



string [int] rave_combo_map = {
	1 : "item", // +30% aka Rave Concentration
	2 : "meat", // +50% aka Rave Nirvana
	3 : "knockout", // 3-rd stun + DOT
	4 : "bleeding",
	5 : "steal",
	6 : "stats"
};



location [] kDreadLocs = {
	$location[Dreadsylvanian Woods],
	$location[Dreadsylvanian Village],
	$location[Dreadsylvanian Castle]
};

location [] kHoboLos = {
	$location[A Maze of Sewer Tunnels],
	$location[Burnbarrel Blvd.],
	$location[Exposure Esplanade],
	$location[Hobopolis Town Square],
	$location[The Ancient Hobo Burial Ground],
	$location[The Heap],
	$location[The Purple Light District]
};

location [string] kEndGameNameToLocationMap = {
	"Sewers" : $location[A Maze of Sewer Tunnels],
	"Town Square" : $location[Hobopolis Town Square],
	"Burnbarrel Blvd." : $location[Burnbarrel Blvd.],
	"Exposure Esplanade" : $location[Exposure Esplanade],
	"The Heap" : $location[The Heap],
	"The Ancient Hobo Burial Ground" : $location[The Ancient Hobo Burial Ground],
	"The Purple Light District" : $location[The Purple Light District]
};



skill [] BloodySkillsArray = {
	$skill[Blood Frenzy],
	$skill[Blood Bond],
	$skill[Blood Bubble]
};



monster [location] kTargetableMonstersMap = {
	$location[The Goatlet] : $monster[dairy goat],
	$location[The Fungal Nethers] : $monster[angry mushroom guy]
};



effect [] kDrivingStyles = {
	$effect[Driving Obnoxiously],
	$effect[Driving Stealthily],
	$effect[Driving Wastefully],
	$effect[Driving Safely],
	$effect[Driving Recklessly],
	$effect[Driving Intimidatingly],
	$effect[Driving Quickly],
	$effect[Driving Observantly],
	$effect[Driving Waterproofly]
};



// in order of to-get
location [string] kLatteLocations = {
	// the ones we want
	"carrot" : $location[The Dire Warren], // +20% Items from Monsters
	"cajun" : $location[The Black Forest], // +40% Meat from Monsters
	"rawhide" : $location[The Spooky Forest], // +5 to Familiar Weight
	"guarna" : $location[The Bat Hole Entrance], // +4 Adventures Per Day

	// useful
	"hellion" : $location[The Dark Neck of the Woods], // +6 PvP Fights Per Day
	"fresh grass" : $location[The Hidden Park], // +3 Stats Per Fight
	"lizard" : $location[The Arid, Extra-Dry Desert], // lizard milk -- Regenerate 5-15 MP per Adventure?
	"vitamin" : $location[The Dark Elbow of the Woods], // +3 Familiar Experience Per Combat
	"ink" : $location[The Haunted Library], // -10% Combat Frequency
	"wing" : $location[The Dark Heart of the Woods], // hot wing -- +10% Combat Frequency

	// not so useful -- in alphabetical order
	"ancient spice" : $location[The Mouldering Mansion], // +50 spooky dmg -- not unlocked by default
	"asp venom" : $location[The Middle Chamber], // +25 weapon dmg
	"basil" : $location[The Overgrown Lot], // 5hp/adv regen
	"Belgian Vanilla" : $location[Whitey's Grove], // all stats +20%
	"blue chalks" : $location[The Haunted Billiards Room], // +25 cold dmg
	"bug-thistle" : $location[The Bugbear Pen], // +20 mys -- not unlocked by default
	"butternut" : $location[Madness Bakery], // +10 spell dmg
	"carrrdamom" : $location[Barrrney's Barrr], // 5mp/adv regen
	"chili seeds" : $location[The Haunted Kitchen], // +3 hot res
	"clove" : $location[The Sleazy Back Alley], // +3 stench res
	"coal" : $location[The Haunted Boiler Room], // +25 hot dmg
	"cocoa powder" : $location[The Icy Peak], // +3 cold res
	"diet soda" : $location[Battlefield (No Uniform)], // The Cola Wars Battlefield, +50 init -- not unlocked by default
	"Dwarf Cream" : $location[Itznotyerzitz Mine], // +30 mus
	"Dyspepsi" : $location[Battlefield (Dyspepsi Uniform)], // The Cola Wars Battlefield, +25 init -- not unlocked by default
	"filth milk" : $location[The Feeding Chamber], // +20 dr
	"fungus" : $location[The Fungal Nethers], // +30 max mp
	"grave mold" : $location[The Unquiet Garves], // +20 spooky dmg
	"greek spice" : $location[Frat House], // Frat/Undisguised, +25 sleaze dmg
	"grobold rum" : $location[The Old Rubee Mine], // +25 sleaze dmg -- not unlocked by default
	"gunpowder" : $location[1st Floor, Shiawase-Mitsuhama Building], // +50 weapon dmg -- not unlocked by default
	"Health Potion" : $location[The Daily Dungeon], // 15hp/adv regen
	"hobo spices" : $location[Hobopolis Town Square], // +50 da
	"hot sausage" : $location[Cobb's Knob Barracks], // +50% mus
	"kombucha" : $location[Hippy Camp], // Hippy/Undisguised, +25 stench dmg
	"Lihc saliva" : $location[The Defiled Niche], // +25 spooky dmg
	"Macaroni" : $location[The Haunted Pantry], // +20 max hp
	"mega sausage" : $location[Cobb's Knob Laboratory], // +50 mox
	"motor oil" : $location[The Old Landfill], // +20 sleaze dmg
	"MSG" : $location[The Briniest Deepests], //
	"norwhal milk" : $location[The Ice Hole], // +200% max hp -- not unlocked by default
	"oil paint" : $location[The Haunted Gallery], // +5 pris dmg
	"paradise milk" : $location[The Stately Pleasure Dome], // +20 all stat -- not unlocked by default
	"rock salt" : $location[The Brinier Deepers], // +10% crit
	"salt" : $location[The Briny Deeps], // +5% crit
	"sandalwood" : $location[Noob Cave], // +5 all stats
	"sausage" : $location[Cobb's Knob Kitchens], // +50% mys
	"space pumpkin" : $location[The Hole in the Sky], // +10 all stats
	"spaghetti squash" : $location[The Copperhead Club], // +20 spell dmg
	"teeth" : $location[The VERY Unquiet Garves], // +25 spooky dmg, +25 weapon dmg
	"white flour" : $location[The Road to the White Citadel], // +3 sleaze res
	"squamous salt" : $location[The Caliginous Abyss], // +3 spooky res
};



item [phylum] kRobortenderStrongBooze = {
	$phylum[bug] : $item[eighth plague],
	$phylum[constellation] : $item[single entendre],
	$phylum[demon] : $item[reverse Tantalus],
	$phylum[elemental] : $item[elemental caipiroska],
	$phylum[elf] : $item[Feliz Navidad],
	$phylum[fish] : $item[Bloody Nora],
	$phylum[goblin] : $item[moreltini],
	$phylum[hippy] : $item[hell in a bucket],
	$phylum[hobo] : $item[Newark],
	$phylum[horror] : $item[R'lyeh],
	$phylum[humanoid] : $item[Gnollish sangria],
	$phylum[mer-kin] : $item[vodka barracuda],
	$phylum[orc] : $item[Mysterious Island iced tea],
	$phylum[penguin] : $item[drive-by shooting],
	$phylum[pirate] : $item[gunner's daughter],
	$phylum[plant] : $item[dirt julep],
	$phylum[slime] : $item[Simepore slime],
	$phylum[weird] : $item[Phil Collins],
};



item [stat] kStatToDivineCombatItemMap = {
	$stat[muscle] : $item[divine noisemaker],
	$stat[mysticality] : $item[divine can of silly string],
	$stat[moxie] : $item[divine blowout],
};



boolean kAbortOnCounter = true;
boolean kDontAbort = false;



// -------------------------------------
// PREFERENCE COVER METHODS
// -------------------------------------

boolean freeWanderingMonstersOnly() {
	return to_boolean(get_property("smm.FreeWanderingMonstersOnly"));
}



// -------------------------------------
// CODE UTILITIES
// -------------------------------------

// TODO one of the libraries i'm importing includes an abs function, should use that????
int smm_abs(int val) {
	if (val < 0)
		return -val;
	else
		return val;
}



// returns the number of the given string is in the name of the given equipment
// useful for PVP ASCII-7 of the moment
int count_string(string testString, string countMe) {
	int rval;
	for i from 0 to length(testString) - 1 {
		string aChar = char_at(testString, i);
		if (aChar == countMe)
			rval++;
	}
	return rval;
}


// conditional print
void cprint(boolean condition, string toPrint, string colour) {
	if (condition)
		print(toPrint, colour);
}

void cprint(boolean condition, string toPrint) {
	cprint(condition, toPrint, "");
}



// returns a new array composed of the given array minus the first item
string [int] cdr(string [int] anArray) {
	string [int] newArray;

	if (count(anArray) == 1) return newArray;

	for i from 1 to count(anArray) - 1 {
		newArray[i-1] = anArray[i];
	}

	return newArray;
}



// strip the given characters off the beginning and end of the given string and return the resulting string
string strip(string stripString, string charsToStrip) {
	if (stripString == "") return "";

	int stripIndexStart = 0;
	for i from 0 to length(stripString) - 1 {
		string aChar = char_at(stripString, i);
		if (charsToStrip.contains_text(aChar))
			stripIndexStart = i + 1;
		else
			break;
	}

	int stripIndexEnd = length(stripString);
	if (stripIndexStart == stripIndexEnd)
		return "";

	for i from length(stripString) - 1 to stripIndexStart {
		string aChar = char_at(stripString, i);
		if (charsToStrip.contains_text(aChar))
			stripIndexEnd = i;
		else
			break;
	}

	return substring(stripString, stripIndexStart, stripIndexEnd);
}

string strip(string stripString) {
	return strip(stripString, " ");
}



// joins the strings in an array
string joinString(string [] anArray, string midString) {
	string rval;
	foreach idx, aString in anArray {
		if (rval != "") rval += midString;
		rval += aString;
	}
	return rval;
}


// appends a string to another, inserting the given string between if both strings are non-empty
string joinString(string baseString, string stringToAppend, string joinString) {
	string rval = baseString;
	if (baseString != "" && stringToAppend != "") rval += joinString;
	return rval += stringToAppend;
}


// appends a string to another, inserting a comma and space between if both strings are non-empty
string maxStringAppend(string maxString, string stringToAppend) {
	return maxString.joinString(stringToAppend, ", ");
}



// this set of functions all return true if the test thing is in the given array
boolean arrayContains(string [] array, string test) {
	foreach aThing in array {
		if (array[aThing] == test)
			return true;
	}
	return false;
}

boolean arrayContains(skill [] array, skill test) {
	foreach aThing in array {
		if (array[aThing] == test)
			return true;
	}
	return false;
}

// returns true if the test monster is in the given array
boolean arrayContains(monster [] array, monster test) {
	foreach aMonster in array {
		if (array[aMonster] == test)
			return true;
	}
	return false;
}

boolean arrayContains(PrioritySkillRecord [] array, PrioritySkillRecord test) {
	foreach idx, psr in array {
		if (psr.theSkill == test.theSkill && psr.theItem == test.theItem)
			return true;
	}
	return false;
}

boolean arrayContains(PriorityRecord [] array, PriorityRecord test) {
	foreach idx, psr in array {
		if (psr.cliExecuteString == test.cliExecuteString && psr.customCombatString == test.customCombatString && psr.maximizeString == test.maximizeString)
			return true;
	}
	return false;
}



// cribbed from bastille.ash
void arrayAppend(int [int] list, int entry) {
	int position = list.count();
	while (list contains position)
		position += 1;
	list[position] = entry;
}



// -------------------------------------
// KOL UTILITIES
// -------------------------------------


// cover method for my_name()
// also useful to correct KoLmafia bug in my_name() changing capitalization
boolean isMe(string name) {
	return my_name().to_lower_case() == name.to_lower_case();
}



boolean restoreAllMP() {
	return restore_mp(my_maxmp() - my_mp());
}



void timeToRollover() {
	print("You have "+(23 - (gametime_to_int() / (86400000 / 24)))+":"+(59 - ((gametime_to_int() / (86400000 / 1440)) % 60))+" left until rollover begins.");
}

int minutesToRollover() {
	int msPerDay = 1000 * 60 * 60 * 24;
	return (msPerDay - gametime_to_int()) / (1000 * 60);
}



boolean inCombat() {
// 	return current_round() != 0 && monster_hp() > 0 && my_hp() > 0;
	return current_round() != 0;
}



string element_color(element anElement) {
	switch (anElement) {
		case $element[none]:   return "";
		case $element[cold]:   return "blue";
		case $element[spooky]: return "grey";
		case $element[hot]:    return "red";
		case $element[stench]: return "green";
		case $element[sleaze]: return "purple";
	}
	abort("element_color: should never get here, passed element: " + anElement);
	return "";
}



boolean [element] weak_elements(element anElement) {
	switch (anElement) {
		case $element[cold]:   return $elements[spooky, hot];
		case $element[spooky]: return $elements[hot, stench];
		case $element[hot]:    return $elements[stench, sleaze];
		case $element[stench]: return $elements[sleaze, cold];
		case $element[sleaze]: return $elements[cold, spooky];
	}
	return $elements[none];
}



float bestElementalResistance(monster foe) {
	float rval;
	foreach ele in $elements[] {
		float val = elemental_resistance(ele);
		if (val > rval)
			rval = val;
	}
	return rval;
}



void saveProperty(string property) {
	set_property("_smm.Backup_" + property, get_property(property));
}

void saveAndSetProperty(string property, string value) {
	saveProperty(property);
	set_property(property, value);
}

void restoreSavedProperty(string property) {
	string savedPropertyKey = "_smm.Backup_" + property;
	if (property_exists(savedPropertyKey))
		set_property(property, get_property(savedPropertyKey));
}

boolean haveSavedProperty(string property) {
	return property_exists("_smm.Backup_" + property);
}

void deleteSavedProperty(string property) {
	remove_property("_smm.Backup_" + property);
}



boolean isRegularClass() {
	return my_class() == $class[Seal Clubber]
		|| my_class() == $class[Turtle Tamer]
		|| my_class() == $class[Pastamancer]
		|| my_class() == $class[Sauceror]
		|| my_class() == $class[Disco Bandit]
		|| my_class() == $class[Accordion Thief];
}



boolean isLucky() {
	return have_effect($effect[Lucky!]) > 0;
}



string statAbbr(stat aStat) {
	if (aStat == $stat[muscle]) return "mus";
	if (aStat == $stat[mysticality]) return "mys";
	if (aStat == $stat[moxie]) return "mox";
	assert(false, "not a valid stat??");
	return "should never get here"; // parser requires this
}



boolean uneffect(effect anEffect) {
	return cli_execute("uneffect " + anEffect);
}

boolean uneffect(skill aSkill) {
	return uneffect(to_effect(aSkill));
}



void printProperties() {
	foreach prop in get_all_properties("", false)
		print(prop + ": " + get_property(prop));
}



boolean inRonin() {
	return !can_interact();
}



boolean max_mcd() {
	int maxmcd = 10;
	if (canadia_available())
		maxmcd = 11;
	if (current_mcd() == maxmcd)
		return true;
	return change_mcd(maxmcd);
}

// ease of use alias
boolean mmcd() {
	return max_mcd();
}



float hitPercent(int attack, int defense) {
	// ( (Attack - Defense) / 18 ) * 100 + 50 = Hit%
	float percent = 100.0 * (attack - defense) / 18 + 50.0;
	return max(min(percent, 100), 0);
}



// TODO normalize these 2 functions
int my_familiar_weight() {
	return familiar_weight(my_familiar());
}

int familarWeight(familiar fam) {
	return familiar_weight(fam) + weight_adjustment();
}



// returns the largest familiar weight adjustment we could get by dressing in the right clothes
int maxWeightAdjustement() {
	maximize("familiar weight", true);
	return numeric_modifier("Generated:_spec", "Familiar Weight");
}



item [familiar] my_familiars() {
	item [familiar] rval;
	foreach fam in $familiars[] {
		if (have_familiar(fam))
			rval[fam] = familiar_equipped_equipment(fam);
	}
	return rval;
}


item [familiar] all_familiar_equipped_equipment() {
	item [familiar] rval;
	foreach fam in $familiars[] {
		item famee = familiar_equipped_equipment(fam);
		if (have_familiar(fam) && my_familiar() != fam)
			rval[fam] = famee;
	}
	return rval;
}


// returns all equipment equipped by any familiar EXCEPT the one we're using (which is considered
// to be equipped by us and not our familiar)
int [item] all_familiar_equipped_amount() {
	int [item] rval;
	foreach fam in $familiars[] {
		item famee = familiar_equipped_equipment(fam);
		if (have_familiar(fam) && my_familiar() != fam)
			rval[famee] += 1;
	}
	return rval;
}

int familiar_equipped_amount(item anItem) {
	return all_familiar_equipped_amount()[anItem];
}


void printMyFamiliars() {
	foreach fam, it in my_familiars() {
		print(fam + " equipped with: " + it);
	}
}

void printMyFamiliarEquippedEquipment() {
	foreach it, amt in all_familiar_equipped_amount() {
		print(it + " X " + amt);
	}
}



string itemDescription(item anItem) {
	buffer descriptionPage = visit_url("/desc_item.php?whichitem=" + anItem.descid);

	matcher descMatcher = create_matcher("<body>(.*)</body>", to_string(descriptionPage));
	find(descMatcher);
	return group(descMatcher, 1);
}

void print_description(item anItem) {
	print_html(itemDescription(anItem));
}


string effectDescription(effect anEffect) {
	buffer descriptionPage = visit_url("/desc_effect.php?whicheffect=" + anEffect.descid, false, false);

	matcher descMatcher = create_matcher("<div id=\"description\">(.*)</div>", to_string(descriptionPage));
	find(descMatcher);
	return group(descMatcher, 1);
}

void printEffectDescription(effect anEffect) {
	print_html(effectDescription(anEffect));
	print_html("");
}


string skillDescription(skill aSkill) {
	return effectDescription(to_effect(aSkill));
}

void printSkillDescription(skill aSkill) {
	print_html(skillDescription(aSkill));
}



int poolSkill() {
	int luckSkillGains = 10; // from lucky adventures / semi-rares
	int skillGainsThisAscension = "poolSkill".get_property().to_int();
	int skillGainsFromBooze = my_inebriety() <= 10 ? my_inebriety() : 10 - (2 * my_inebriety());
	return luckSkillGains + skillGainsThisAscension + skillGainsFromBooze;
}



// returns the number of free crafting turns are available
// types: all, food, drink, meat, food-only, drink-only, meat-only, universal (meaning NOT food-only or drink-only)
int availableFreeCraftTurns(string type) {
	int rapidPrototypingFreeCraftTurns = 5 - to_int(get_property("_rapidPrototypingUsed"));
	int inigosFreeCraftTurns = floor(have_effect($effect[Inigo's Incantation of Inspiration]) / 5.0);
	int cutCornersFreeCraftTurns = 5 - to_int(get_property("_expertCornerCutterUsed"));
	int homebodylFreeCraftTurns = to_int(get_property("homebodylCharges"));
	int holidyMultitaskingFreeCraftTurns = to_int(get_property("holidayMultitaskingCharges"));

	int cbbFreeFoodTurns = 5 - to_int(get_property("_cookbookbatCrafting"));

	int universalFreeCraftingTurns = rapidPrototypingFreeCraftTurns + inigosFreeCraftTurns + cutCornersFreeCraftTurns + homebodylFreeCraftTurns + holidyMultitaskingFreeCraftTurns;
	int foodOnlyFreeCraftingTurns = cbbFreeFoodTurns;
	int drinkOnlyFreeCraftingTurns = 0;
	int meatOnlyFreeCraftingTurns = 0;

	if (type == "food-only") return foodOnlyFreeCraftingTurns;
	if (type == "drink-only") return drinkOnlyFreeCraftingTurns;
	if (type == "paste-only") return meatOnlyFreeCraftingTurns;

	if (type == "universal") return universalFreeCraftingTurns;

	if (type == "food") return universalFreeCraftingTurns + foodOnlyFreeCraftingTurns;
	if (type == "drink") return universalFreeCraftingTurns + drinkOnlyFreeCraftingTurns;
	if (type == "paste") return universalFreeCraftingTurns + meatOnlyFreeCraftingTurns;

	assert(type == "all", "unknown type: " + type);
	return universalFreeCraftingTurns + foodOnlyFreeCraftingTurns + drinkOnlyFreeCraftingTurns + meatOnlyFreeCraftingTurns;
}



int total_meat() {
	return my_meat() + my_closet_meat() + my_storage_meat();
}



void refreshMallPrice(item it) {
	assert(buy(it, 1, 1) == 0, "refreshMallPrice: we actually bought something for 1 meat??");
}


// returns the mall_price or the historical_price if the historical_age is less than age
int get_price(item itm, float age) {
	if (historical_age(itm) < age) return historical_price(itm);
	return mall_price(itm);
}


int current_price_helper(item anItem, boolean historicalFirst) {
	int buyPrice = 0;

	// FIRST, figure out the mall price
	if (historicalFirst && historical_age(anItem) < 7.0)
		buyPrice = historical_price(anItem);
// 	print(anItem + " historical price: " + buyPrice + " @ " + historical_age(anItem) + " historicalFirst: " + historicalFirst);

	if (buyPrice < 1) // we didn't ask for historical first or we didn't get it
		buyPrice = mall_price(anItem);

	if (buyPrice < 1 && !historicalFirst) // if we didn't try historical prices first, and we didn't get a price from mall_price, try the historical_price now
		buyPrice = historical_price(anItem);

	// SECOND, if we're selling it for cheaper than the mall price, the "cost" of that item is our shop price
	int shopPrice = shop_price(anItem);
	if (shopPrice != 999999999 && shopPrice > 0 && (shopPrice < buyPrice || buyPrice < 1))
		buyPrice = shopPrice;

	// LAST, if we can buy it from an NPC for cheaper, use that price instead
	int npcPrice = npc_price(anItem);
	if (npcPrice != 0 && (buyPrice < 1 || npcPrice < buyPrice))
		buyPrice = npcPrice;

	return buyPrice;
}

// Returns the cheapest cost to purchase anItem from the mall or npc, or 0 if the items is not CURRENTLY purchasable.
// Checks the mall_price and then historical_price if mall_price returns 0 for some reason (which it sometimes does)
// See cheapest_price (below) for a function that returns a best guess at a price if the item isn't currently available for purchase
int current_price(item anItem) {
	return current_price_helper(anItem, false);
}

// like current_price, but checks historical price first and only if the historical price is 0 does it check mall price
int current_historical_price(item anItem) {
	return current_price_helper(anItem, true);
}


// Returns the cheapest cost to purchase anItem, with a default of 2 times the autosell price if no other price can be determined.
// (Stuff sold by NPCs that are guild-specific and in a different guild are examples of items that this would be useful for.)
int cheapest_price(item anItem) {
	int buyPrice = current_price(anItem);

	// if we're using the autosell price, it's because we're out of other options, not because it's cheaper
	if (buyPrice == 0)
		buyPrice = 2 * autosell_price(anItem);

	return buyPrice;
}


// Returns the cheapest cost to purchase anItem from the mall, or 0 if the items is not purchasable.
int [item] cheapest_prices(boolean [item] items) {
	int [item] rval;

	mall_prices(items); // a more efficient way of getting all the mall prices ...

	foreach it in items
		rval[it] = cheapest_price(it); // ... but we want the cheapest price available

	return rval;
}


// refreshes the mall price, then returns mall_price without our own shop items interfering with the price
// WARNING: might be lots of server hits, so want to limit usage. Try historical_age(it) < gkStoreHeartbeat
int realMallPrice(item it) {
	if (historical_age(it) > gkStoreHeartbeat)
		refreshMallPrice(it);
	int rval = current_price(it);
	int price = shop_price(it);
	if (price > 100 && (rval >= price || rval < 100)) {
		int stock = shop_amount(it);
		int limit = shop_limit(it);
		take_shop(it);
		refreshMallPrice(it); // this is, apparently, the way to refresh the price
		rval = current_price(it); // even after all this, mall_price might return -1
		put_shop(price, limit, stock, it);
	}
	assert(rval >= 100, "mall prices are all 100 or above, we got " + rval + " for " + it);
	return rval;
}



boolean isCraftable(item anItem) {
	return count(get_ingredients(anItem)) > 0;
}


// returns the number of craftable we can make given the current availability of mats (including if it is purchase-able)
int craftable_amount(item craftable, boolean buyMats) {
	int rval = kMaxInt;
	assert(isCraftable(craftable), "craftable_amount: " + craftable + " is not craftable");
	foreach mat, amt in get_ingredients(craftable) {
		int avail;
		if (buyMats && current_historical_price(mat) > 0)
			avail = kMaxInt;
		else
			avail = available_amount(mat);

		// causes a stack overflow
// 		if (isCraftable(mat))
// 			avail = craftable_amount(mat, buyMats);

		rval = min(rval, avail);
		if (rval <= 0)
			return 0;
	}

	return rval;
}

boolean have_mats(item craftable, int needed) {
	assert(isCraftable(craftable), "have_mats: " + craftable + " is not craftable");
	return craftable_amount(craftable, false) >= needed;
}

boolean have_mats(item craftable) {
	return have_mats(craftable, 1);
}



string cchIndent(int level) {
	string rval;
	int times = level;
	while (times > 0) {
		rval += "+";
		times--;
	}
	return rval;
}

// Returns the cost to acquire a new anItem, either by buying the item or by crafting it if that's cheaper.
// Throws if anItem is neither craftable nor purchasable.
// Recursively determines the cost to purchase or buy of each ingredient, ultimately
// returning the cheapest possible cost to acquire anItem
int acquireCostHelper(item anItem, int [item] costs, boolean historicalPrice, boolean printReceipt, int amtToAcquire, int level) {
	int costToPurchase = historicalPrice ? current_historical_price(anItem) : current_price(anItem);
	int costToCraft;

	int cheapestAcquireCost;
	int craftingTurns;
	int acquireCostWithTurnsIncluded;
	string isCraftableString;
	string isPurchasableString;

	// if we don't have the cost cached, compute it
	if ( ! (costs contains anItem)) {
		costs[anItem] = costToPurchase;

		if (isCraftable(anItem))
			foreach ingred, amt in get_ingredients(anItem)
				costToCraft += acquireCostHelper(ingred, costs, historicalPrice, printReceipt, amtToAcquire * amt, level + 1);

		if (costToCraft > 0 && (costToCraft < costToPurchase || costToPurchase == 0))
			costs[anItem] = costToCraft;

		// ASSUMES that craftingTurns > 1 means there are ingredients that require turns to craft, i.e. only 1 turn max at the current level
		cheapestAcquireCost = costs[anItem];
		craftingTurns = creatable_turns(anItem, amtToAcquire, false);
		acquireCostWithTurnsIncluded = cheapestAcquireCost + (craftingTurns > 0 ? kTurnValue : 0);
	} else {
		// ASSUMES that craftingTurns > 1 means there are ingredients that require turns to craft, i.e. only 1 turn max at the current level
		// the cost of crafting turns is already included in the cached value, so back it out for detailed printing below
		cheapestAcquireCost = costs[anItem];
		craftingTurns = creatable_turns(anItem, amtToAcquire, false);
		acquireCostWithTurnsIncluded = cheapestAcquireCost;
		cheapestAcquireCost -= (craftingTurns > 0 ? kTurnValue : 0);
	}

	isCraftableString = (isCraftable(anItem) && cheapestAcquireCost != costToPurchase) ? ", craftable@" + cheapestAcquireCost : "";
	isCraftableString += (craftingTurns > 0 && cheapestAcquireCost != costToPurchase) ? ", taking a turn to craft @ " + kTurnValue + ", TOTAL: " + acquireCostWithTurnsIncluded : "";
	isPurchasableString = costToPurchase > 0 ? ", purchasable@" + costToPurchase : "";

	if (level == 0)
		cprint(printReceipt, cchIndent(level) + anItem + isCraftableString + isPurchasableString);
	else
		cprint(printReceipt, cchIndent(level) + amtToAcquire + "X " + anItem + isCraftableString + isPurchasableString);

	return acquireCostWithTurnsIncluded * amtToAcquire;
}

int acquireCost(item anItem, boolean printReceipt) {
	return acquireCostHelper(anItem, int [item] {}, false, printReceipt, 1, 0);
}

int acquireCost(item anItem) {
	return acquireCostHelper(anItem, int [item] {}, false, true, 1, 0);
}

int acquireCostHistorical(item anItem, boolean printReceipt) {
	return acquireCostHelper(anItem, int [item] {}, true, printReceipt, 1, 0);
}

int acquireCostHistorical(item anItem) {
	return acquireCostHelper(anItem, int [item] {}, true, true, 1, 0);
}


int arbitrageProfit(item it) {
	return current_price(it) - acquireCost(it, false);
}

int historicalArbitrageProfit(item it) {
	return current_historical_price(it) - acquireCostHistorical(it, false);
}


// attempts to put target amount of NEW anItem in your inventory, i.e. items that were either newly crafted or newly purchased.
// attempts to determine if crafting or buying is cheaper and use the cheaper option preferentially.
// returns amount of newly acquired anItems
int newAcquire(item anItem, int target, int priceLimit) {
	assert(anItem != $item[none], "newAcquire: invalid item: " + anItem);
	assert(target > 0, "newAcquire: invalid target number: " + target + " for item " + anItem);
	print("newly acquire " + target + "X " + anItem + " @ not more than " + priceLimit, "green");

	float kSlop = 1.05;

	int equippedAmount = equipped_amount(anItem);
	int familiarEquippedAmount = familiar_equipped_amount(anItem); // familiars holding the equipment but NOT our current familiar, which will be caught by equippedAmount
	int invAmount = item_amount(anItem);
	int storageAmount = storage_amount(anItem);
	int closetAmount = closet_amount(anItem);
	int displayAmount = display_amount(anItem);
	int shopAmount = shop_amount(anItem);
	int availableAmount = equippedAmount + familiarEquippedAmount + invAmount + storageAmount + closetAmount;
	int total = equippedAmount + familiarEquippedAmount + invAmount + storageAmount + closetAmount + displayAmount + shopAmount;

	int needed = target;
	int startAmount = invAmount;
	int acquireCost = acquireCost(anItem, false);
	int craftingTurns = creatable_turns(anItem, needed, true);
	int buyPrice = current_price(anItem);
	int startMeat = my_meat();

	// MAIN LOOP, try several times to acquire the item
	int tries = 3;
	int acquiredThisPass;
	repeat {
		int iterationStartAmount = invAmount;
		acquiredThisPass = 0;

		// CRAFT/CREATE the item
		if (needed > 0 && isCraftable(anItem)
			&& acquireCost > 0 && acquireCost <= priceLimit && acquireCost != buyPrice
		    && ((acquireCost * 0.9) < buyPrice || buyPrice == 0)) { // craft unless it is at least 10% cheaper to buy
			print("trying to craft remaining " + needed + ", as it is cheaper (" + acquireCost + ") than purchasing @ " + buyPrice);

			int craftableComponents = needed; // the number we can make this time around
			foreach ingred, amt in get_ingredients(anItem) {
				acquiredThisPass = newAcquire(ingred, amt * craftableComponents, current_price(ingred));
				craftableComponents = min(craftableComponents, acquiredThisPass / amt);
			}

			craftingTurns = creatable_turns(anItem, craftableComponents, false);
			boolean proceed = true;
			if (craftingTurns > 0)
				if (!user_confirm("Will spend " + craftingTurns + " turns crafting " + craftableComponents + "X " + anItem
					+ ", we have " + availableFreeCraftTurns("all") + " turns of free crafting available. Proceed?", 60000, true))
					break;

			acquiredThisPass = 0;
			int innerTries = craftableComponents + 3;
			while (acquiredThisPass < craftableComponents && needed > 0 && innerTries > 0) {
				invAmount = item_amount(anItem);

				boolean sexy = create(craftableComponents, anItem);
				if (!sexy) cli_execute("refresh inv"); // weird things happen when it fails

				acquiredThisPass += item_amount(anItem) - invAmount;
				invAmount = item_amount(anItem);
				needed = target - (invAmount - startAmount);

				if (acquiredThisPass <= 0) break;
				innerTries--;
			}

			invAmount = item_amount(anItem);
			acquiredThisPass = invAmount - iterationStartAmount;
			needed = target - (invAmount - startAmount);
			buyPrice = current_price(anItem);
			acquireCost = acquireCost(anItem, false);
		}

		// BUY the item
		if (needed > 0 && buyPrice > 0 && buyPrice <= priceLimit) {
			//print("trying to buy remaining " + needed + " @ " + buyPrice + ", already considered crafting @ " + acquireCost);
			// BUY
			if (needed > 0)
				buy(anItem, needed, priceLimit * kSlop);

			invAmount = item_amount(anItem);
			acquiredThisPass = invAmount - startAmount;
			needed = target - acquiredThisPass;
			buyPrice = current_price(anItem);
			acquireCost = acquireCost(anItem, false);
		}

		tries--;
	} until (needed == 0 || tries <= 0 || acquiredThisPass <= 0);
	int acquired = invAmount - startAmount;
	assert(tries > -1, "newAcquire " + anItem + ": only acquired: " + acquired + " (target: " + target + ") -- ran out of tries!");

	invAmount = item_amount(anItem);
	int meatCost = startMeat - my_meat();
	print("newly acquired " + acquired + " " + anItem + " @ " + (acquired > 0 ? to_string(meatCost / acquired) : "not acquired!") + (acquired > 1 ? ", total meat cost: " + meatCost : ""), "green");
	return acquired;
}


// attempts to put target amount of anItem in your inventory.
// if target is less than the number of currently equipped items, will count your equipped items as your inventory
// (differs from retrieve_item in this respect -- useful when acquiring items for equipping)
// if target is more than the number you have equipped, it might end up unequip'ing any items
// you DO have equipped, though other avenues will be pursued first

// checks inventory and equipped items
// folds
// pulls from closet or storage
// craft or buy (whichever is cheaper with a user confirmation for buying over mafia's preference-set limit)
// finally uses retrieve_item (see Retrieval order in the wiki for more info))

// attempts to determine if crafting or buying is cheaper and use the cheaper option preferentially.
// differs from retrieve_item in that it crafts or buys depending on price

// returns the number of acquired target items
int fullAcquire(item anItem, int target, int maxAcquireCost) {
	float kSlop = 1.05;
	int equippedAmount = equipped_amount(anItem);
	int familiarEquippedAmount = familiar_equipped_amount(anItem); // familiars holding the equipment but NOT our current familiar, which will be caught by equippedAmount
	int invAmount = item_amount(anItem);
	int storageAmount = storage_amount(anItem);
	int closetAmount = closet_amount(anItem);
	int displayAmount = display_amount(anItem);
	int shopAmount = shop_amount(anItem);
	int availableAmount = equippedAmount + familiarEquippedAmount + invAmount + storageAmount + closetAmount;
	int total = equippedAmount + familiarEquippedAmount + invAmount + storageAmount + closetAmount + displayAmount + shopAmount;

	// already have target items in our inventory or equipped?
	if (invAmount + equippedAmount + familiarEquippedAmount >= target)
		return target;

	int needed = target - invAmount;
	int acquireCost = acquireCost(anItem, false);
	int craftingTurns = creatable_turns(anItem, needed, true);
	int buyPrice = mall_price(anItem);

	// FOLD
	if (needed > 0 && count(get_related(anItem, "fold")) > 0) {
		boolean success = true;
		int tries = needed + 3;
		while (success && needed > 0 && tries > 0) {
			success = cli_execute("fold " + anItem);
			invAmount = item_amount(anItem);
			needed = target - invAmount;
			tries--;
		}
	}

	// CLOSET
	if (needed > 0 && closetAmount > 0) {
		take_closet(anItem, needed);
		invAmount = item_amount(anItem);
		needed = target - invAmount;
	}

	// STORAGE
	if (needed > 0 && storageAmount > 0) {
		take_storage(anItem, needed);
		invAmount = item_amount(anItem);
		needed = target - invAmount;
	}

	// CRAFT OR PURCHASE
	if (needed > 0 && acquireCost > 0) {
		boolean doit = (acquireCost < 500 && target * acquireCost < 10000) // MAGIC NUMBERS: below this single acquire cost and full acquire cost, we don't ask the user TODO: make a property
			|| (maxAcquireCost > 0 && acquireCost < maxAcquireCost)
			|| user_confirm("Craft or purchase the " + needed + "X " + anItem + " @ " + acquireCost + ", total cost with 5% slop: " + (acquireCost * needed * kSlop) + "?", 60000, true);
		int acquireCostToUse = max(maxAcquireCost, acquireCost * kSlop); // if the actual cost is higher than maxAcquireCost, we'll get a warning, but if accepted we must use the higher meat cost to actually acquire it!
		if (doit)
			newAcquire(anItem, needed, acquireCostToUse);
		invAmount = item_amount(anItem);
		needed = target - invAmount;
	}

	// try the built-in retrieve_item LAST, as this doesn't check for the cheapest way to acquire before doing it
	// but will buy from coinmasters correctly
	if (needed > 0) {
		retrieve_item(target, anItem);
		invAmount = item_amount(anItem);
		needed = target - invAmount;
	}

// 	print("target: " + target + " in inv: " + item_amount(anItem) + " acquired: " + acquired);
	return target - needed;
}

int fullAcquire(item anItem, int target) {
	return fullAcquire(anItem, target, 0);
}

// workaround/shortcut for gCLI use
int fa(item anItem, int target) {
	return fullAcquire(anItem, target);
}

// attempts to acquire the given item, possibly pulling or buying the item
int fullAcquire(item anItem) {
	return fullAcquire(anItem, 1);
}



// attempts to acquire a new item unless it costs more than maxCost, in which case use fullAcquire to get one of our own or buy with user approval
int preferNewAcquire(item acquireItem, int targetAmt, int maxCost) {
	int aa = newAcquire(acquireItem, targetAmt, maxCost);
	if (aa < targetAmt) {
		print("WARNING: was not able to newly acquire " + targetAmt + "X" + acquireItem + " at less than " + maxCost, "red");
		aa += fullAcquire(acquireItem, targetAmt - aa, maxCost);
	}
	return aa;
}



// attempts to put an existing item in our inventory, failing that will first attempt to craft from existing mats
// basically a retrieve_item that returns how many it retrieved
int preferExistingAcquire(item acquireItem, int targetAmt, int maxCost) {
	int startingInv = item_amount(acquireItem);

	if (retrieve_item(acquireItem, targetAmt))
		return targetAmt;

	return item_amount(acquireItem) - startingInv;
}



boolean isFood(item it) {
	return it.fullness > 0;
}

boolean isBooze(item it) { # isDrink
	return it.inebriety > 0;
}

boolean isSpleen(item it) {
	return it.spleen > 0;
}


boolean isPotion(item it) {
    effect potEff = effect_modifier(it, "effect");
    return it.usable && potEff != $effect[none]
        && ! (isFood(it) || isBooze(it) || isSpleen(it));
}



// returns the average number of adventures gained by eating/drinking the given item
float nutrition(item food_booze) {
	matcher aMatcher = create_matcher("([0-9]+)-?([0-9]*)", food_booze.adventures);
	if (!find(aMatcher))
		abort("nutrition: non-food/non-booze -- or at least non-adventure generating: " + food_booze + ", adventures: " + food_booze.adventures);

	string lowString = group(aMatcher, 1);
	string highString = group(aMatcher, 2);
	int low = to_int(lowString);
	int high = to_int(highString);

	if (highString == "" && lowString == 0) // 0 adventures? use a default based on quality
		return kQualityStringToPerAdventureMap[food_booze.quality] * (food_booze.inebriety + food_booze.fullness);
	else if (highString == "")
		return low;
	else // take the average, the default and most usual case
		return (low + high) / 2;
}


boolean isNutritious(item it) {
	return nutrition(it) > 0;
}

boolean [item] nutritiousItems() {
	boolean [item] rval;
	return rval;
}



int turnValue() {
    return "smm.TurnValue".get_property() == "" ? 5000 : get_property("smm.TurnValue").to_int(); // the value of a turn
}


// best food for the current stomach value, based on turn value
item bestFood(boolean useFillerIfRequired) {
    item foodItem = $item[baked veggie ricotta casserole];
    item fillItem = $item[roasted vegetable of Jarlsberg];
    if (! useFillerIfRequired || my_fullness() - fullness_limit() >= foodItem.fullness) {
        return foodItem;
    } else {
        return fillItem;
    }
}


float turnsPerStomach(item stomachItem) {
    return stomachItem.nutrition() / stomachItem.fullness.to_float();
}

// the number of turns generated by the best food
float turnsPerStomach() {
    return turnsPerStomach(bestFood(false));
}


// value of 1 fullness consuming the best food
int stomachValue() {
    return turnsPerStomach() * turnValue();
}


int foodOpportunityCost(item foodItem) {
    return foodItem.fullness * turnsPerStomach(bestFood(false)) * turnValue();
}



item bestDrink(boolean useFillerIfRequired) {
    item drinkItem = $item[perfect dark and stormy];
    item fillItem = $item[splendid martini];
    if (! useFillerIfRequired || my_inebriety() - inebriety_limit() >= drinkItem.inebriety) {
        return drinkItem;
    } else {
        return fillItem;
    }
}


float turnsPerLiver(item liverItem) {
    return liverItem.nutrition() / liverItem.inebriety;
}

// the number of turns generated by the best drink
float turnsPerLiver() {
    return turnsPerLiver(bestDrink(false));
}


// value of 1 inebriety consuming the best drink
int liverValue() {
    return turnsPerLiver() * turnValue();
}


int boozeOpportunityCost(item drinkItem) {
    return drinkItem.inebriety * turnsPerLiver(bestDrink(false)) * turnValue();
}



item bestSpleen(boolean useFillerIfRequired) {
    item spleenItem = $item[grim fairy tale]; // 4 spleen -- OR use prismatic wad @ 3 spleen
    item fillItem = $item[transdermal smoke patch];
    if (! useFillerIfRequired || my_spleen_use() - spleen_limit() >= spleenItem.spleen) {
        return spleenItem;
    } else {
        return fillItem;
    }
}


// returns the opportunity cost of consuming the given item. Opportunity cost is the difference
// between the adv gain of the given item and the adv gain of our default diet multiplied by
// the cost of a turn -- AND might be negative, i.e. there's no cost to doing it, only gain
float turnsPerSpleen(item spleenItem) {
	assert(spleenItem.spleen > 0, "spleen item doesn't take up any spleen?");
	return spleenItem.nutrition() / spleenItem.spleen;
}

float turnsPerSpleen() {
	return turnsPerSpleen(bestSpleen(false));
}


int spleenValue() {
    return turnsPerSpleen() * turnValue();
}


int spleenOpportunityCost(item spleenItem) {
    return spleenItem.spleen * turnsPerSpleen(bestSpleen(false)) * turnValue();
}



// returns the opportunity cost of consuming the given item, which could be 0 if the item is 
// not consumable or is and costs no adventures, or even negative if the item costs little and gives adventures
int opportunityCostToConsume(item toConsume) {
	if (isFood(toConsume)) return foodOpportunityCost(toConsume);
	if (isBooze(toConsume)) return boozeOpportunityCost(toConsume);
	if (isSpleen(toConsume)) return spleenOpportunityCost(toConsume);
	return 0;
}



item [] allOffhand() {
	item [int] sortArray;
	int ctr;
	// marshal the data
	foreach it in $items[] {
		if (it.item_type() == "offhand")
			sortArray[ctr++] = it;
	}
	sort sortArray by -value.current_historical_price();

	foreach idx, it in sortArray {
		string itMod = string_modifier(it, "Modifiers");
		print(it + "@" + it.current_historical_price() + ": " + itMod);
	}
	return sortArray;
}



// assumes potions are items with effects and no fullness or inebriety
item [] allPotions(boolean shouldPrint) {
	item [int] sortArray;
	int ctr;
	// marshal the data
	foreach it in $items[] {
		if (it.isPotion())
			sortArray[ctr++] = it;
	}
	sort sortArray by -value.current_historical_price();

	foreach idx, it in sortArray {
		effect potEff = effect_modifier(it, "effect");
		cprint(shouldPrint, it + ": " + potEff + "@" + it.current_historical_price());
	}
	return sortArray;
}

item [] allPotions() {
    return allPotions(true);
}


// number of accordion thief buffs / effects currently active
int accordionSongsActive() {
	int rval;
	int [effect] currentEffects = my_effects(); // Array of current active effects
	foreach buff in currentEffects {
		skill currentEffect = to_skill(buff);
		if (currentEffect.class == $class[accordion thief] && currentEffect.buff) { // True if AT buff
			rval++;
		}
	}
	return rval;
}



string kTurtleAdventureTurnsKey = "smm.TurtleAdventureTurns";
// best GUESS at when the next turtle adventure will be
int turtleAdventureTurns() {
	if (kTurtleAdventureTurnsKey.get_property() == "")
		return 15;
	else
		return kTurtleAdventureTurnsKey.get_property().to_int();
}



boolean isATSong(skill aSkill)  {
	return aSkill.class == $class[accordion thief] && aSkill.buff;
}

boolean isATSong(effect anEffect)  {
	return isATSong(to_skill(anEffect));
}


int maxAccordionSongs()  {
// 	int maxSongs = boolean_modifier("Four Songs") ? 4 : 3;
	int maxSongs = boolean_modifier("Four Songs") ? 3 : 2;
	int additionalSongs = numeric_modifier("Additional Song");
	return maxSongs + additionalSongs;
}



item [slot] current_equipment() {
	item [slot] rval;

	foreach aSlot in $slots[] {
		item eItem = equipped_item(aSlot);
		if (eItem != $item[none])
			rval[aSlot] = eItem;
	}

	return rval;
}

// prints out all worn equipment
string logEquipmentString(boolean shortForm) {
	item [slot] cEquip = current_equipment();

	string [] outputStrings = {
		$slot[hat] + ": " + cEquip[$slot[hat]] + "\t" + $slot[back] + ": " + cEquip[$slot[back]] + "\t" + $slot[shirt] + ": " + cEquip[$slot[shirt]],
		$slot[weapon] + ": " + cEquip[$slot[weapon]] + "\t" + $slot[off-hand] + ": " + cEquip[$slot[off-hand]] + "\t" + $slot[pants] + ": " + cEquip[$slot[pants]],
		$slot[acc1] + ": " + cEquip[$slot[acc1]] + "\t" + $slot[acc2] + ": " + cEquip[$slot[acc2]] + "\t" + $slot[acc3] + ": " + cEquip[$slot[acc3]],
		"fam: " + my_familiar() + "\t" + $slot[familiar] + ": " + cEquip[$slot[familiar]]
	};

	string rval;
	if (shortForm)
		rval = joinString(outputStrings, "\t");
	else
		rval = joinString(outputStrings, "\n");

	return rval;
}

string logEquipmentString() {
	return logEquipmentString(true);
}

void logEquipment(boolean shortForm) {
	print(logEquipmentString(shortForm));
}

void logEquipment() {
	logEquipment(false);
}



void unequip(item unequipItem) {
    if (have_equipped(unequipItem)) {
        foreach aSlot in $slots[] {
            if (equipped_item(aSlot) == unequipItem) {
                equip(aSlot, $item[none]);
                break;
            }
        }
    }
}


void unequipAll(boolean unequipFamiliar) {
// 	visit_url("/inv_equip.php?pwd&action=unequipall", true, false); // doesn't seem to be an actual shortcut
	foreach slt in $slots[] {
		if ((slt != $slot[familiar] || unequipFamiliar) && equipped_item(slt) != $item[none])
			equip(slt, $item[none]);
	}
}

void unequipAll() {
	unequipAll(true);
}



// executes the given Custom Combat Script
string executeScript(string script) {
	if (script != "") {
		print("executing script: " + script, "blue");
		return visit_url("fight.php?action=macro&macrotext=" + url_encode(script), true, true);
	}
	else {
		return "";
	}
}



// returns the frequency of non-combats for given location #NC #non combats
float nonCombatChance(location aLoc) {
	foreach mob, freq in appearance_rates(aLoc)
		switch {
			case mob == $monster[none]:
				return freq;
			default:
		}
	abort("should never get here");
	return 0;
}



// wraps item_drops_array to return something that can be stored in a variable
ItemDropRecord [] normalized_item_drops_array(monster mob) {
	ItemDropRecord [int] itemDropRecordArray;
	ItemDropRecord tempIDR;
	int counter = 0;

	foreach idx, monsterDropsArray in item_drops_array(mob) {
		tempIDR = new ItemDropRecord();
		tempIDR.drop = monsterDropsArray.drop;
		tempIDR.rate = monsterDropsArray.rate;
		tempIDR.type = monsterDropsArray.type;
		itemDropRecordArray[counter] = tempIDR;
		counter++;
	}

	return itemDropRecordArray;
}


// returns pickpocket-able items dropped by aMonster, with pp-only items in array slot 0
// includes accordion-stealable items -- should it?????????????????
ItemDropRecord [int] ppItemDropsArray(monster aMonster) {
	ItemDropRecord [int] itemDropRecordArray;
	ItemDropRecord tempIDR;
	int counter = 1; // save index 0 for any potential pp-only item -- assumes there will only ever be 1 PP-only item
	boolean ppOnlyItemFound = false;

	foreach idx, monsterDropsArray in item_drops_array(aMonster) {
		if (monsterDropsArray.rate > 0 && monsterDropsArray.type == "p") {
			assert(!ppOnlyItemFound, "found more than one pp-only item!");
			ppOnlyItemFound = true;
			itemDropRecordArray[0] = new ItemDropRecord(monsterDropsArray.drop, monsterDropsArray.rate, monsterDropsArray.type);

		} else if ((monsterDropsArray.rate > 0 || monsterDropsArray.type == "0") && (monsterDropsArray.type != "n" && monsterDropsArray.type != "b"))
			itemDropRecordArray[counter++] = new ItemDropRecord(monsterDropsArray.drop, monsterDropsArray.rate, monsterDropsArray.type);
	}

	return itemDropRecordArray;
}


boolean hasPPOnly(monster amon) {
	return ppItemDropsArray(amon)[0].type == "p";
}

boolean hasStealableAccordion(monster amon) {
	foreach idx, monsterDropsRecord in item_drops_array(amon)
		if (monsterDropsRecord.type == "a" && monsterDropsRecord.rate > 0)
			return true;
	return false;
}


// returns true iff at least one monster at the location has an appearance rate > 0% AND
// has one pickpocket-able item
boolean isPPUseful(location aLocation) {
	float [monster] monsterMap = appearance_rates(aLocation);
	foreach m in monsterMap {
		//print("testing monster: " + m);
		if (m != $monster[none] && monsterMap[m] > 0 && count(ppItemDropsArray(m)) > 1)
			return true;
	}

	return false;
}

boolean isPPUseful() {
	return isPPUseful(my_location());
}



// bubbly potion, cloudy potion, dark potion, effervescent potion, fizzy potion, milky potion, murky potion, smoky potion, swirly potion
boolean potionsOfDoomIdentified() {
	return !("lastBangPotion819".get_property() == ""
		|| "lastBangPotion820".get_property() == ""
		|| "lastBangPotion821".get_property() == ""
		|| "lastBangPotion822".get_property() == ""
		|| "lastBangPotion823".get_property() == ""
		|| "lastBangPotion824".get_property() == ""
		|| "lastBangPotion825".get_property() == ""
		|| "lastBangPotion826".get_property() == ""
		|| "lastBangPotion827".get_property() == ""
	);
}

// potionName is one of the effects (sleepiness, drunkenness, healing, confusion, object detection, strength, moxie, mysticality, teleportation)
item potionOfDoom(string potionName) {
	assert(potionsOfDoomIdentified(), "we can't get a Dungeon of Doom potion before identifying them!");

	for i from 819 to 827 {
		string potStringer = get_property("lastBangPotion" + i);
		if (potStringer == potionName)
			return i.to_item();
	}

	assert(false, "potionOfDoom: should never get here, potionName: " + potionName);
	return $item[none];
}



// -------------------------------------
// OLFACT UTILITIES
// -------------------------------------

BanishTrackRecord [] parseTrackedMonsters() {
	string [int, int] parser = group_string(get_property("trackedMonsters"), "([^:]+):([^:]+):(\\d+)");
	BanishTrackRecord [int] rval;
	int rvalIndex = 0;
	foreach i in parser {
		rval[rvalIndex].targettedMonster = to_monster(parser[i][1]);
		rval[rvalIndex].skillUsed = to_skill(parser[i][2]);
		rval[rvalIndex].turnUsed = to_int(parser[i][3]);
		rvalIndex++;
	}
	return rval;
}



int olfactsAvailable() {
	return 3 - get_property("_olfactionsUsed").to_int();
}


// returns true if Get a Good Whiff has been called on the given monster and the effect is still active
boolean gotAGoodWhiff(monster aMonster) {
	return my_familiar() == $familiar[Nosy Nose] && get_property("nosyNoseMonster").to_monster() == aMonster;
}


// returns true if Gallapagosian Mating Call has been called on the given monster and the effect is still active
boolean callOfTheGallapagos(monster aMonster) {
	return get_property("_gallapagosMonster").to_monster() == aMonster;
}


// returns true if the Red-Nosed Snapper will track this monster
// only returns true if Red-Nosed Snapper is actually equipped
boolean isGuidedByRedNosedSnapper(monster aMonster) {
	return my_familiar() == $familiar[Red-Nosed Snapper] && get_property("redSnapperPhylum").to_phylum() == aMonster.phylum;
}


boolean hasBeenOfferedLatte(monster aMonster) {
	if (get_property("_latteMonster").to_monster() == aMonster // we've offered AND
		&& get_counters("Latte Monster", 0, 30) != "") // the counter hasn't expired
		return true;
	return false;
}


// returns true if the given monster is olfacted
// if aMonster is none, returns true if ANY monster is olfacted
boolean isOlfacted(monster aMonster) {
	if (have_effect($effect[On the Trail]) > 0) {
		if (aMonster == $monster[none]) // is ANYTHING olfacted
			return true;
		else if (to_monster(get_property("olfactedMonster")) == aMonster)
			return true;
	}

	return false;
}

// returns true if at least one target monster is olfacted
boolean isOlfacted(monster [] targetMonsters) {
	foreach idx, aMonster in targetMonsters {
		if (isOlfacted(aMonster))
			return true;
	}

	return false;
}



// returns the number of copies of the given monster in the monster queue of the location associated with the monster
// unless the monster is olfacted or sniffed or offered latte or... or... or... this will return 1
int monsterQueueCopies(monster aMonster) {
	int rval = 1;

	if (isOlfacted(aMonster)) rval += 3;
	if (hasBeenOfferedLatte(aMonster)) rval += 2;
	if (callOfTheGallapagos(aMonster)) rval += 1;
	if (isGuidedByRedNosedSnapper(aMonster)) rval += 2;
	if (gotAGoodWhiff(aMonster)) rval += 1;
	if (aMonster.phylum == $phylum[beast] && have_effect($effect[A Beastly Odor]) > 0) rval += 2;
	if (aMonster.phylum == $phylum[dude] && have_effect($effect[Ew, The Humanity]) > 0) rval += 2;

	return rval;
}



// logs the current monster's stats
void logMonsterCombatStats() {
	print("monster: " + last_monster() + " attack: " + monster_attack() + " defense: " + monster_defense() + " hp: " + monster_hp(), "green");
	print("phylum: " + monster_phylum() + " element: " + monster_element() + " elemental res: " + elemental_resistance() + " physical res: " + last_monster().physical_resistance, "green");
}



// is the item in the inventory, or stored, or equipped
boolean have_item(item anItem) {
	//print(anItem + ": " + available_amount(anItem) + ", returning: " + (available_amount(anItem) > 0));
	return available_amount(anItem) > 0;
}



// returns the item for which we have the highest number in inventory
item mostOfItem(item [] itemList) {
	sort itemList by -item_amount(value);
	return itemList[0];
}

item mostOfItemAvailable(item [] itemList) {
	sort itemList by -available_amount(value);
	return itemList[0];
}



int [item] gHatchlings;
int [item] hatchlings() {
	if (count(gHatchlings) > 0)
		return gHatchlings;

	int i = 0;
	foreach fam in $familiars[] {
		gHatchlings[fam.hatchling] = 1;
	}
	return gHatchlings;
}


boolean is_gift(item anItem) {
	return anItem.gift;
}


int [item] gkTattooKits = {
	$item[Red Roger tattoo kit] :					available_amount($item[Red Roger tattoo kit]),
};
// TODO can probably sniff this somehow -- certainly by searching the description for "tattoo kit"
boolean is_tattookit(item anItem) {
	return gkTattooKits contains anItem;
}


int [item] gSkillbooks = {
	$item[the Crymbich Manuscript] :					available_amount($item[the Crymbich Manuscript]),
	$item[Island Drinkin', a Tiki Mixology Odyssey] :	available_amount($item[Island Drinkin', a Tiki Mixology Odyssey]),
	$item[My Life of Crime, a Memoir] :					available_amount($item[My Life of Crime, a Memoir]),
	$item[Never Don't Stop Not Striving] :				available_amount($item[Never Don't Stop Not Striving]),
	$item[Illustrated Mating Rituals of the Gallapagos]:available_amount($item[Illustrated Mating Rituals of the Gallapagos]),
};
// TODO can probably sniff this somehow -- certainly by searching the description for "skillbook"
boolean is_skillbook(item anItem) {
	return gSkillbooks contains anItem;
}


boolean is_equipment(item anItem) {
	return anItem.to_slot() != $slot[none];
}


// TODO there's got to be a better way
boolean is_hatchling(item anItem) {
	return hatchlings() contains anItem;
}


// this belongs below with the other CLL stuff, but it is used for isCopyable()
// returns the list of all reminiscences stored in the combat lover's locket
// caches the result on the first access, use cllReminiscenceClearCache() to clear it
boolean [monster] cllReminiscences() {
	boolean [monster] monsterList;

	if (!property_exists("_smm.CLLMonsters")) {
		// NOT CACHED
		string pageString = visit_url("/inventory.php?reminisce=1", false, false);
		matcher monsterMatcher = create_matcher("<option value=\"([0-9]+)\" >(.*?)</option>", pageString);
		while (find(monsterMatcher)) {
			monster aMonster = group(monsterMatcher, 2).to_monster();
			int monID = group(monsterMatcher, 1).to_int();
			monsterList[aMonster] = true;
		}

		// STORE IN CACHE
		saveAndSetProperty("logPreferenceChange", "false"); // avoid log spam
		try {
			foreach aMonster, ignore in monsterList {
				string startChar = char_at(aMonster, 0);
				string storedProperty = get_property("_smm.CLLMonstersStartingWith" + startChar);
				string storedString = aMonster.to_int() + "\t";
				if (!storedProperty.contains_text("," + storedString) && !storedProperty.starts_with(storedString)) {
					storedProperty += storedString;
					set_property("_smm.CLLMonstersStartingWith" + startChar, storedProperty);
				}
			}
			set_property("_smm.CLLMonsters", true);
		} finally {
			restoreSavedProperty("logPreferenceChange");
		}

	} else {
		// CACHE
		foreach aPropertyName, ignore in get_all_properties("_smm.CLLMonstersStartingWith", false) {
			string [int] monsterIds = get_property(aPropertyName).split_string("\t");
			foreach idx, anID in monsterIds {
				monsterList[to_monster(anID)] = true;
			}
		}
	}

	return monsterList;
}

// returns true iff the combat lover's locket can reminisce about aMonster
boolean cllHasReminiscence(monster aMonster) {
	return cllReminiscences() contains aMonster;
}

boolean isCopyable(monster aMonster) {
	return !aMonster.boss && cllHasReminiscence(aMonster);
}



// -------------------------------------
// MOOD UTILITIES
// -------------------------------------


string moodStringAppend(string moodString, string stringToAppend) {
	return moodString.joinString(stringToAppend, ", ");
}


// songs to sing, in order, if we don't have other songs filling our head
// TODO different songs depending on situation
skill [] defaultSongs() {
	skill [] rval = {
		$skill[Fat Leon's Phat Loot Lyric],
		$skill[The Polka of Plenty],
		$skill[Aloysius' Antiphon of Aptitude],
		$skill[Stevedave's Shanty of Superiority],
	};
	return rval;
}


// default facial expression
skill defaultFacialExpression() {
	if (my_primestat() == $stat[muscle])
		return $skill[Patient Smile];
	else if (my_primestat() == $stat[mysticality]) {
		if (have_skill($skill[Inscrutable Gaze]))
			return $skill[Inscrutable Gaze];
		else
			return $skill[Wry Smile];
	} else
		return $skill[Knowing Smile];
}


// default use for soul sauce
skill defaultSoulsauce() {
	return $skill[Soul Rotation];
}


// prints all the skills in the current mood
void listMood() {
	foreach idx, moodString in mood_list() {
		print(moodString);
	}
}


skill [int] moodSkills() {
	skill [int] rval;
	int idx = 0;

	foreach idx, moodString in mood_list() {
		string skillString = moodString.split_string(" \\| ")[1];
		rval[idx++] = to_skill(skillString);
	}

	return rval;
}


// the AT song buffs we currently have active
int [skill] activeSongs() {
	int [skill] activeSongs;
	foreach anEffect, duration in my_effects() {
		skill aSkill = anEffect.to_skill();
		if (aSkill.class == $class[accordion thief] && aSkill.buff
			|| anEffect == $effect[Rolando's Rondo of Resisto]) { // for some reason this isn't an AT buff
			activeSongs[aSkill] = duration;
			print(aSkill + " for " + duration + " turns");
		}
	}
	return activeSongs;
}


// the AT song buffs in the current mood
int [skill] moodSongs() {
	int [skill] moodSongs;
	foreach idx, aSkill in moodSkills() {
		if (aSkill.class == $class[accordion thief] && aSkill.buff)
			moodSongs[aSkill] = have_effect(aSkill.to_effect());
	}
	return moodSongs;
}


int countMoodSongs() {
	return count(moodSongs());
}


// the facial expression we currently have active
skill activeFacialExpression() {
	foreach anEffect in my_effects() {
		if (anEffect.to_skill().expression)
			return anEffect.to_skill();
	}
	return $skill[none];
}


// the facial expression in the current mood
skill moodFacialExpression() {
	foreach idx, aSkill in moodSkills() {
		if (aSkill.expression)
			return aSkill;
	}
	return $skill[none];
}


boolean inMood(skill aSkill) {
	return arrayContains(moodSkills(), aSkill);
}

boolean inMood(effect anEffect) {
	return arrayContains(moodSkills(), anEffect.to_skill());
}


string getMoodRaw() {
	return get_property("currentMood");
}

string getMood() {
	return getMoodRaw().replace_string(", defaultfacialexpression", "").replace_string(", default1song", "").replace_string(", default2song", "").replace_string(", default3song", "").replace_string(", default4song", "");
}


void moodExecute() {
	string currentMood = get_property("currentMood");
	boolean sexy = cli_execute("mood execute");

	// auto-fill songs and facial expression with something
	if (!inRonin() && count(my_effects()) > 0) { // don't auto-fill in ronin
		// EXPRESSION
		if (activeFacialExpression() == $skill[none])
			if (!use_skill(1, defaultFacialExpression()))
				abort("moodExecute: could not fill facial expression with " + defaultFacialExpression());

		// SONGS
		int songSpace = maxAccordionSongs() - count(activeSongs());
		foreach idx, buffSkill in defaultSongs() {
			if (songSpace <= 0) break;
			if (have_effect(buffSkill.to_effect()) == 0) {
				if (my_mp() < mp_cost(buffSkill)) {
					print("moodExecute: not enough mp to fill song space with " + buffSkill, "red");
					continue;
				}
				if (use_skill(1, buffSkill))
					songSpace--;
				else
					print("moodExecute: could not fill song space with " + buffSkill, "red");
			}
		}

		// SOUL SAUCE
		if (my_soulsauce() >= 95) {
			sexy = use_skill(1, defaultSoulsauce());
			assert(sexy, "moodExecute: could not spend soul sauce on " + defaultSoulsauce());
		}
	}
}


void setMoodRaw(string moodString) {
// 	print("setMoodRaw: " + moodString, "blue");
	string parsedMoodString = moodString.replace_string("|", ","); // the CLI parser doesn't like commas
	cli_execute("mood " + parsedMoodString);
}


// will replace "[primestat]" in the moodString with the abbreviation of the prime stat
// will attempt to fill out missing songs or facial expressions with something minimally useful (mp regen? or xp?)
void setMood(string moodString) {
	print("setMood: " + moodString, "blue");

	string parsedMoodString = moodString.replace_string("[primestat]", statAbbr(my_primestat()));

	// instead of doing this here, let's try in moodExecute()
// 	setMoodRaw(parsedMoodString); // so we can properly detect the expression
// 	if (activeFacialExpression() == $skill[none] && !moodString == "apathetic")
// 		parsedMoodString = parsedMoodString.moodStringAppend("defaultfacialexpression");
//
// 	setMoodRaw(parsedMoodString); // so we can properly count the songs in the mood
// 	int songSpace = maxAccordionSongs() - count(activeSongs());
// 	print("song space: " + songSpace);
// 	if (songSpace > 0 && !moodString.contains_text("apathetic"))
// 		parsedMoodString = parsedMoodString.moodStringAppend("default" + songSpace + "song");

	setMoodRaw(parsedMoodString);
	boolean unused = cli_execute("mood execute");
}


void setCurrentMoodRaw(string tweakMood) {
	setMoodRaw(moodStringAppend(kDefaultMood, tweakMood));
}


// set the mood to the default (currently "current"), adjusted by tweakMood, which will be appended with a comma
void setCurrentMood(string tweakMood) {
	setMood(moodStringAppend(kDefaultMood, tweakMood));
}


// set the default mood with no extraneous moods
void setDefaultMoodRaw() {
	setMoodRaw(kDefaultMood);
}


// set the mood to the default, adding expressions or songs as necessary to max out expressions (1) and songs (usually 4)
void setDefaultMood() {
	setMood(kDefaultMood);
}


// always raw
void setNoMood() {
	setMoodRaw(kNoMood);
	assert(count(moodSkills()) == 0, "setNoMood: set mood to apathetic, but the apathetic mood has triggers");
}


void saveMood() {
	saveProperty("currentMood");
}

void saveAndSetMood(string newMood) {
	saveMood();
	setCurrentMood(newMood);
}

void restoreSavedMood() {
	restoreSavedProperty("currentMood");
}

boolean haveSavedMood() {
	return haveSavedProperty("currentMood");
}

void deleteSavedMood() {
	deleteSavedProperty("currentMood");
}



// make sure the default mood ("current") is set up correctly
void setUpMood() {
	string moodString;
	if (!inRonin()) {
		string className = replace_string(my_class().to_lower_case(), " ", "");
		moodString = "current extends unrestricted, " + className;
	} else {
		moodString = "current extends apathetic";
	}
	print("setUpMood: " + moodString, "blue");
	setMoodRaw(moodString);
	setMoodRaw("current");
	mood_execute(1);
}



// cast in-mood bloody skills until they are at buffTurns turns
// should be called with a decent amount of mp
boolean burnHP(int buffTurns) {
// 	if (my_maxhp() < kCocoonHealing) {
// 		int tries = 0;
// 		float mp_mod = .1;
// 		repeat {
// 			tries++;
// 			string temp_max_string = "hp, " + mp_mod + " mp";
// 			print("max " + temp_max_string);
// 			maximize(temp_max_string, 1, 2, true, true);
// 			print("max mp " + numeric_modifier("Generated:_spec", "Maximum MP"));
// 			if (numeric_modifier("Generated:_spec", "Maximum MP") < my_mp()) mp_mod *= 10;
// 		} until (tries > 3 || numeric_modifier("Generated:_spec", "Maximum MP") >= my_mp());
//
// 		if (numeric_modifier("Generated:_spec", "Maximum MP") < my_mp())
// 			abort("unable to get more hp without losing mp");
// 	}

	// calculate mp cost for all the healing we're going to do
	int casts = 0;
	foreach idx, aSkill in BloodySkillsArray {
		effect buff = aSkill.to_effect();
		if (have_effect(buff) < buffTurns && have_skill(aSkill) && inMood(buff)) {
			int turnsToGet = buffTurns - have_effect(buff);
			int turnsPerCast = turns_per_cast(aSkill);
			casts += ceil(turnsToGet / to_float(turnsPerCast));
		}
	}
	if (casts == 0) return true;

	if (my_maxhp() < kCocoonHealing) {
		if (!user_confirm("burnHP: proceed with max hp " + my_maxhp() + " less than " + kCocoonHealing + "?\nTry maximize 5 mp, hp 1000 min", 30000, true))
			abort();
// 		maximize("5 mp, hp 1000 min", false); // this ensures we don't lose mp while increasing the max hp as well
	}

	int hpNeeded = casts * 30;
	int maxHP = my_maxhp();
	int cocoonsNeeded = ceil(hpNeeded / to_float(min(maxHP, kCocoonHealing))) + 1;
	if (my_mp() < cocoonsNeeded * 20)
		abort ("burnHP: not enough mana, need: " + (cocoonsNeeded * 20));
	else
		print("have enough mana", "green");

	// buff it up
	boolean success = true;
	foreach idx, aSkill in BloodySkillsArray {
		effect buff = aSkill.to_effect();
		if (have_effect(buff) < buffTurns && have_skill(aSkill) && inMood(buff)) {
			int turnsToGet = buffTurns - have_effect(buff);
			int turnsPerCast = turns_per_cast(aSkill);
			int castAccumulator = ceil(turnsToGet / to_float(turnsPerCast));

			while (castAccumulator > 0) {
				int numberOfCasts = min(castAccumulator, floor(my_hp() / 30.0));
				print("casting " + aSkill + " " + numberOfCasts + " times", "blue");

				success = use_skill(numberOfCasts, aSkill) && success;
				castAccumulator -= numberOfCasts;

				// recover HP only if we have more casting to do
				if (castAccumulator > 0)
					success = success && use_skill(1, $skill[Cannelloni Cocoon]); // won't cast unless the bloody skill cast was successful

				if (!success)
					return false;
			}
		}
	}

	return true;
}

void burnHP() {
	burnHP(1000);
}



void hpMood() {
	int lowestBloodyEffectDuration = 1000;
	skill lowestBloodySkill;
	if (my_hp() == my_maxhp() && my_maxhp() > 300) {
		foreach idx, aSkill in BloodySkillsArray {
			effect buff = aSkill.to_effect();
			if (have_effect(buff) < lowestBloodyEffectDuration && have_skill(aSkill)) {
				lowestBloodyEffectDuration = have_effect(buff);
				lowestBloodySkill = aSkill;
			}
		}

		if (lowestBloodyEffectDuration < 1000)
			use_skill(lowestBloodySkill);
	}
}



// Similar to the CLI command "burn" with these exceptions:
// 1) does a "mood execute" first, which ensures all in-mood effects are active, regardless of burnAmount.
// 2) then resets the mood to the default mood -- this causes spare mp to be spent on the main buffs first
// and then, once those are max'ed out, the rest of the mp amount will be spent on the rest of the actual current mood.
// 3) once all buffs in the mood have been max'ed (more than ~1000 turns), will pick the buff in the default mood with
// the lowest number of turns and blow the rest of the burnAmount on that.
// 4) a negative burnAmount acts like burn in that it saves abs(burnAmount) mp with the above restrictions. A zero burnAmount represents "burn *" i.e. burn all mp
//
// This is most appropriate in aftercore.
void burnMP(int burnAmount) {
	print("burnMP burning " + burnAmount + " mp with current mood: " + getMood() + " (raw: " + getMoodRaw() + ")", "blue");

	string currentMood = getMoodRaw();
	if (currentMood == "" || currentMood == kNoMood)
		return;

	int targetMP = my_mp() - burnAmount;
	if (burnAmount < 0) targetMP = -burnAmount;
	else if (burnAmount == 0) targetMP = 0;

	// first, spend any mp we have (regardless of burnAmount) to ensure all in-mood effects are active
	int mpBefore = my_mp();
	moodExecute();

	// if we already spent all the mp we wanted to, exit now
	if (burnAmount > 0) {
		burnAmount -= (mpBefore - my_mp());
		if (burnAmount <= 0)
			return;
	}

	// then, switch to the default mood and "burn" all mp on that -- this should get us to about 1000 adv of each effect in the default mood
	skill [int] defaultMoodSkills;
	try {
		saveAndSetProperty("logPreferenceChange", "false"); // try to avoid log spam with this
		// if we have Gygaxian Libram set to be cast, it will drain all our mp without leaving anything for anything else
		saveAndSetProperty("libramSkillsHardcore", "none");
		saveAndSetProperty("libramSkillsSoftcore", "none");

		setDefaultMoodRaw(); // we don't want any extraneous stuff that setDefaultMood might do
		defaultMoodSkills = moodSkills();

		if (burnAmount == 0)
			cli_execute("burn *");
		else
			cli_execute("burn " + burnAmount);
	} finally {
		setMoodRaw(currentMood); // also does a mood execute, so might burn more mp...

		restoreSavedProperty("libramSkillsSoftcore");
		restoreSavedProperty("libramSkillsHardcore");
		restoreSavedProperty("logPreferenceChange");
	}

	// burn as much of the rest as we can on Gygaxian Libram
	while ((my_mp() - mp_cost($skill[Summon Dice])) > targetMP && use_skill(1, $skill[Summon Dice]));

	// if we still have mp to burn here, dump it all on one buff to avoid wasting it -- this also makes future burning quicker since it will have 1 less buff to top up
// 	if (targetMP == 0 || my_mp() > smm_abs(targetMP)) {
// 		sort defaultMoodSkills by have_effect(value.to_effect());
// 		foreach i, aSkill in defaultMoodSkills
// 			if (have_effect(aSkill.to_effect()) > 1000 && mp_cost(aSkill) > 0 && have_skill(aSkill)) {
// 				use_skill(floor((my_mp() - targetMP) / to_float(mp_cost(aSkill))), aSkill);
// 				break;
// 			}
// 	}

    print("burnMP done, mp: " + my_mp(), "blue");
}

void burnMP() {
	int amountToSave = gUnrestrictedManaToSave;
	if (my_basestat($stat[mysticality]) > amountToSave)
		amountToSave = my_basestat($stat[mysticality]);
	burnMP(-amountToSave);
}


void burnExtraMP() {
	float manaBurningThreshold = "manaBurningThreshold".get_property().to_float();
	if (manaBurningThreshold < 0) // a negative value means don't burn mana
		burnMP(-my_maxmp()); // don't burn anything, but go through the function in case there are expiring buffs
	else
		burnMP(min(-100, -get_property("manaBurningThreshold").to_float() * my_maxmp())); // save at least 100 mana, or use the threshold, whichever is saving more mana
}



boolean isBeatenUp() {
	return have_effect($effect[Beaten Up]) > 0;
}


void ensure_not_beaten_up() {
	if (have_effect($effect[Beaten Up]) > 0) {
		print("AUTOMATICALLY REMOVING BEATEN UP!", "red");
		// TODO Hottub is very useful for the slimetube
// 		if (get_property("_hotTubSoaks") < 5)
// 			cli_execute("hottub");
// 		else
			use_skill($skill[Tongue of the Walrus]);
	}
}

boolean ensureNotBeatenUp() {
	ensure_not_beaten_up();
	return !isBeatenUp();
}


boolean isPoisoned() {
	return have_effect($effect[Hardly Poisoned at All]) > 0 || have_effect($effect[A Little Bit Poisoned]) > 0 || have_effect($effect[Somewhat Poisoned]) > 0 || have_effect($effect[Really Quite Poisoned]) > 0 || have_effect($effect[Majorly Poisoned]) > 0;
}

boolean ensureNotPoisoned() {
	// if any buffed stat is at or below 100 while we're out of ronin, we're most likely trying to get to FantasyRealm or some other place that requires stats below 100
	// in which case, DO NOT remove the debuff
	if (!inRonin()
		&& (my_buffedstat($stat[muscle]) <= 100
			|| my_buffedstat($stat[mysticality]) <= 100
			|| my_buffedstat($stat[moxie]) <= 100)) {
		// do nothing

	} else if (isPoisoned()) {
		fullAcquire($item[anti-anti-antidote]);
		use(1, $item[anti-anti-antidote]);
	}
	return !isPoisoned();
}

boolean ensureNoTeleportitis() {
	if (have_effect($effect[Teleportitis]) > 0) {
		fullAcquire($item[soft green echo eyedrop antidote]);
		cli_execute("uneffect Teleportitis");
	}
	return have_effect($effect[Teleportitis]) == 0;
}

// includes poison, teleportitis, and Beaten Up
// returns true if all debuffs were removed
boolean ensureNotDebuffed() {
	boolean rval = true;
	rval = ensureNotBeatenUp() && rval;
	rval = ensureNotPoisoned() && rval;
	rval = ensureNoTeleportitis() && rval;
	return rval;
}


// heal up to the given hp or higher
void haveAtLeastHP(int minHP) {
	int cocoCasts = floor(minHP / 1000.0);
	use_skill(cocoCasts, $skill[Cannelloni Cocoon]);

	while (my_hp() < minHP && my_hp() < my_maxhp()) {
		int hp_needed = minHP - my_hp();
		if (hp_needed <= 10 && my_mp() >= 6)
			use_skill($skill[Lasagna Bandages]);
// 		else if (hp_needed <= 30 && my_mp() >= 10) // this removes Beaten Up when we most need it (Pirate Realm, Fantasy Realm)
// 			use_skill($skill[Tongue of the Walrus]);
		else if (my_mp() < 20)
			abort("don't have mp to heal");
		else
			// use_skill(ceil(hp_needed/kCocoonHealing)), $skill[Cannelloni Cocoon]); // SHOULD WORK but borks mafia itself!!
			use_skill($skill[Cannelloni Cocoon]);
	}
}

void haveAtLeastHPWithMPRestore(int minHP) {
	int cocoCasts = ceil((minHP - my_hp()) / kCocoonHealing);
	restore_mp(20 * cocoCasts);
	haveAtLeastHP(minHP);
}

void healIfRequired(float hpFractionMin) {
	haveAtLeastHP(my_maxhp() * hpFractionMin);
}

float gkDefaultHealPercent = 0.9; // heal at least to 90%

// heal if 10% less than max hp
void healIfRequired() {
	healIfRequired(gkDefaultHealPercent);
}

// restores enough mp to heal to max hp
void healIfRequiredWithMPRestore(float hpFractionMin) {
	int cocoCasts = ceil((my_maxhp() * hpFractionMin) / kCocoonHealing);
	restore_mp(20 * cocoCasts);
	healIfRequired(hpFractionMin);
}

void healIfRequiredWithMPRestore() {
	healIfRequiredWithMPRestore(gkDefaultHealPercent);
}


void healToMax() {
	healIfRequired(1.0);
}

void healToMaxWithMPRestore() {
	healIfRequiredWithMPRestore(1);
}


void coco() {
	healIfRequiredWithMPRestore();
}

void cocoa() {
	healToMaxWithMPRestore();
}


// includes removing Beated Up
void healAndRemoveDebuffs(float hpFractionMin) {
	ensureNotDebuffed(); //  includes poisoned
	healIfRequired(hpFractionMin);
}

void healAndRemoveDebuffs() {
	healAndRemoveDebuffs(gkDefaultHealPercent);
}

void healAndRemoveDebuffsWithMPRestore(float hpFractionMin) {
	int cocoCasts = ceil((my_maxhp() * hpFractionMin) / kCocoonHealing);
	restore_mp(20 * cocoCasts);
	healAndRemoveDebuffs(hpFractionMin);
}

void healAndRemoveDebuffsWithMPRestore() {
	healAndRemoveDebuffsWithMPRestore(gkDefaultHealPercent);
}



// returns true if a counter is set to expire between now and max_turns
boolean check_counters(int max_turns, boolean should_abort) {
	string kCounterWarningDoneKey = "_smm.CounterWarningDone";

	boolean has_warned = to_boolean(get_property(kCounterWarningDoneKey));
	boolean will_expire = get_counters("", 0, max_turns) != "";

	if (will_expire && has_warned) {
		set_property(kCounterWarningDoneKey, "false");
		return false;
	}

	if (will_expire && should_abort) {
		set_property(kCounterWarningDoneKey, "true");
		abort("A counter is about to expire.");
	}

	if (!will_expire)
		set_property(kCounterWarningDoneKey, "false");

	return will_expire;
}

// returns true if a counter is set to expire next turn
boolean check_counters(boolean should_abort) {
	return check_counters(0, should_abort);
}



// returns true if the given page is an error page TODO probably a more efficient way to do this
boolean isErrorPage(string checkPage) {
	if (checkPage == "") return true;
	if (checkPage.contains_text("A voice from the terminal says")) return true; // error at ?? Source Terminal?
	if (checkPage.contains_text("<td>You shouldn't be here.<center>")) return true; // not dressed for Obligatory Pirate's Cove
	if (checkPage.contains_text("That isn't a place you can get to the way you're dressed.")) return true; // not dressed for Palindome
	if (checkPage.contains_text("Resistance Required]")) return true; // not enough elemental res

	if (checkPage.contains_text("<td>You're not currently at sea.<center>")) return true; // adv at PirateRealm sea, but we're not at sea
	if (checkPage.contains_text("You're not currently on island time.")) return true; // adv at PirateRealm Island, but we're not at an island
	if (checkPage.contains_text("None of your stats can be higher than 100")) return true; // stats too high for PR

	return false;
}


boolean isWinPage(string checkPage) {
	return checkPage.contains_text("You win the fight!");
}



string makeClickableCommand(string commandName, string command, boolean confirm) {
	string confirm_string = "confirm+";
	if (!confirm) confirm_string = "";
	return "<strong style=\"color:blue;\"><a href=\"KoLmafia/sideCommand?cmd=" + commandName + "+" + confirm_string + command + "&pwd=" + my_hash() + "\">" + command + "</a></strong>";
}



boolean isOysterDay() {
	return get_property("_isOysterDay").to_boolean();
}

boolean isSneakyPeteDay() {
	return holiday().contains_text("St. Sneaky Pete's Day");
}



// returns the number of the last choice option -- which is usually the "do nothing" or "get out of here" option
int last_choice_option() {
	int lastChoiceOption;
	string [int] choices = available_choice_options();
	foreach num, choice_text in choices {
		lastChoiceOption = num;
	}
	return lastChoiceOption;
}

// run_choice on the the last choice option -- which is usually the "do nothing" or "get out of here" option
buffer run_last_choice_option() {
	return run_choice(last_choice_option());
}



boolean isChoicePage(string lastPage) {
	return lastPage.contains_text("choice.php");
}

// TODO fix this
boolean isFightPage(string lastPage) {
	return !lastPage.isChoicePage();
}



boolean canPickpocket() {
	return (my_class() == $class[Disco Bandit]
		|| my_class() == $class[Accordion Thief]
		|| equipped_amount($item[tiny black hole]) >= 1
		|| equipped_amount($item[mime army infiltration glove]) >= 1);
}



boolean isPizzaWorkshed() {
	return get_workshed() == $item[diabolic pizza cube];
}

boolean isAsdonWorkshed() {
	return get_workshed() == $item[Asdon Martin keyfob (on ring)];
}

boolean isColdMedicineWorkshed() {
	return get_workshed() == $item[cold medicine cabinet];
}

boolean isTrainshed() {
	return get_workshed() == $item[none];
}



boolean vipLoungeAvailable() {
	return count(get_clan_lounge()) > 0;
}



float pickpocketChance() {
	return numeric_modifier("Pickpocket Chance");
}



// returns all equipment that can be equipped in aSlot
boolean [item] equipmentForSlot(slot aSlot) {
	slot testSlot = aSlot;
	if (aSlot == $slot[acc2] || aSlot == $slot[acc3])
		testSlot = $slot[acc1];

	boolean [item] rval;
	foreach anItem in $items[]
		if (anItem.to_slot() == testSlot)
			rval[anItem] = true;
	return rval;
}



// returns a map relating equipment to count of the given string within the equipment name.
int [item] lettersForSlot(slot checkSlot, string countMe, boolean shouldPrint) {
	int [item] rval;
	item [int] sortData;
	int i;
	int amt;
	foreach anItem in equipmentForSlot(checkSlot) {
		amt = count_string(anItem, countMe);
		rval[anItem] = amt;
		sortData[i++] = anItem;
	}

	if (shouldPrint) {
		sort sortData by -rval[value];
		foreach idx, anItem in sortData
			print(anItem + ": " + rval[anItem] + ", have: " + available_amount(anItem));
	}

	return rval;
}

int [item] lettersForSlot(slot checkSlot, string countMe) {
	return lettersForSlot(checkSlot, countMe, true);
}


// wantMost == false means want least
void equipWithLetters(string aLetter, boolean wantMost) {
	// use our equipment slots to remember which accessories we've already identified as the best-in-slot
	equip($slot[acc1], $item[none]);
	equip($slot[acc2], $item[none]);
	equip($slot[acc3], $item[none]);

	foreach azlot in $slots[hat, back, shirt, weapon, off-hand, pants, acc1, acc2, acc3] {
		int i;
		item [int] sortData;
		int [item] slotData = lettersForSlot(azlot, aLetter, false);

		foreach it, letters in slotData
			if (((wantMost && letters > 0) || (!wantMost && letters < 3)) && available_amount(it) > 0) sortData[i++] = it;
		print("sorting " + count(sortData) + " items for slot " + azlot);

		if (wantMost)
			sort sortData by -slotData[value];
		else
			sort sortData by slotData[value];

		item bestItem;
		int bestLetters;
		int bestPower;
		foreach idx, anItem in sortData {
			int itPower = get_power(anItem);
// 			print("letters: " + slotData[anItem] + ", bestLetters: " + bestLetters + ", bestPower: " + bestPower + ", weapon hands: " + weapon_hands(anItem));
			if (((wantMost && slotData[anItem] >= bestLetters) || (!wantMost && slotData[anitem] <= bestLetters))
				&& itPower > bestPower && weapon_hands(anItem) < 2 && can_equip(anItem)
				&& (item_type(anItem) != "accessory" || equipped_amount(anItem) == 0)) {
				print("for slot: " + azlot + ": " + anItem + "(" + itPower + " power) with " + slotData[anItem] + " " + aLetter + "'s is better than " + bestItem + "(" + bestPower + " power) with " + bestLetters, "green");
				bestItem = anItem;
				bestLetters = slotData[anItem];
				bestPower = itPower;
			}
		}

		equip(azlot, bestItem);
	}
}



void removeEffectsWithLetter(string aLetter) {
	foreach ef in my_effects() {
		if (ef.to_string().to_lower_case().contains_text(aLetter.to_lower_case()) && user_confirm("Remove " + ef + "?", 6000, true)) {
			boolean unuused = cli_execute("uneffect " + ef);
		} else
			print("no " + aLetter + " in " + ef);
	}
}



string expandOutfits(string maxString) {
	string rval = maxString;
	matcher aMatcher = create_matcher("outfit\\s+([^,]+)", maxString);
	while (find(aMatcher)) {
		string outfitName = strip(group(aMatcher, 1), "' \"");
		foreach key,doodad in outfit_pieces(outfitName) {
			rval = maxStringAppend(rval, "equip " + to_string(doodad));
		}
	}
	return rval;
}



item [slot] slotted_outfit_pieces(string outfitName) {
	item[slot] rval;
	int accessoryNumber = 1;

	foreach idx, anItem in outfit_pieces(outfitName) {
		slot itemSlot = to_slot(anItem);
		if (itemSlot == $slot[acc1]) {
			switch (accessoryNumber) {
				case 1:
					break;

				case 2:
					itemSlot = $slot[acc2];
					break;

				case 3:
					itemSlot = $slot[acc3];
					break;

				default:
					abort("slotted_outfit_pieces: invalid accessory number: " + accessoryNumber);
			}
			accessoryNumber++;
		}
		rval[itemSlot] = anItem;
	}

	return rval;
}


// return the number of weapon or off-hand items explicitly requested in the maxStringToTest
int countHandsUsed(string maxString) {
	int rval = 0;
	string maxStringToTest = expandOutfits(maxString);
	matcher aMatcher = create_matcher("(?<!-)equip\\s+([^,]+)", maxStringToTest);
	while (find(aMatcher)) {
		item anItem = to_item(strip(group(aMatcher, 1), "' \""));
		if (anItem == $item[none]) abort("couldn't convert '" + group(aMatcher, 1) + "' to an item");
		slot aSlot = to_slot(anItem);
		//print("found " + to_item(group(aMatcher, 1)) + ": " + aSlot);
		if (aSlot == $slot[weapon] || aSlot == $slot[off-hand])
			rval++;
	}
	return rval;
}


int count_accessories(string maxString) {
	int rval = 0;
	string maxStringToTest = expandOutfits(maxString);
	matcher aMatcher = create_matcher("(?<!-)equip\\s+([^,]+)", maxStringToTest);
	while (find(aMatcher)) {
		item anItem = to_item(strip(group(aMatcher, 1), "' \""));
		if (anItem == $item[none]) abort("couldn't convert '" + group(aMatcher, 1) + "' to an item");
		slot aSlot = to_slot(anItem);
		if (aSlot == $slot[acc1] || aSlot == $slot[acc2] || aSlot == $slot[acc3])
			rval++;
	}
	return rval;
}



// returns true iff the maxString contains a "-equip" directive for the given item
boolean wantsToNotEquip(string maxString, item anItem) {
	matcher desc_matcher = create_matcher("-equip ([^,]+)", maxString);
	while (find(desc_matcher)) {
		if (to_item(group(desc_matcher, 1)) == anItem)
			return true;
	}
	return false;
}

// returns true iff in the given maxString there is an equip directive for a melee weapon OR
// a "melee" directive
boolean wantsToEquipMelee(string maxString) {
	// melee?
	string [] directives = split_string(maxString, ", ");
	if (arrayContains(directives, "melee"))
		return true;

	// +equip a melee weapon?
	string maxStringToTest = expandOutfits(maxString);
	matcher desc_matcher = create_matcher("(?<!-)equip\\s+([^,]+)", maxStringToTest);
	while (find(desc_matcher)) {
		if (weapon_type(to_item(group(desc_matcher, 1))) == $stat[muscle])
			return true;
	}
	return false;
}


boolean wantsToEquip(string maxString, item anItem) {
	string maxStringToTest = expandOutfits(maxString);
	matcher desc_matcher = create_matcher("(?<!-)equip\\s+([^,]+)", maxStringToTest);
	while (find(desc_matcher)) {
		if (to_item(group(desc_matcher, 1)) == anItem)
			return true;
	}
	return false;
}

// returns true iff all of checkSlot's available room is taken up by "equip" directives in the given maxString
// for most things available room = 1
// weapons = 2, or 1 with an off-hand item, further complicated by 2H items and the left-hand man
// off-hand = 0 with 2H weapon, 1 normally, or 2 with left-hand man
// accessories = 3
boolean wantsToEquip(string maxString, slot checkSlot) {
	string maxStringToTest = maxString.expandOutfits();
	matcher equipMatcher = create_matcher("(?<!-)equip\\s+([^,]+)", maxStringToTest);

	int offHands = 1;
	int totalHands = 2;
    // maximizing with the Left-Hand Man doesn't work
	//if (my_familiar() == $familiar[Left-Hand Man]) {
	//	totalHands++;
	//	offHands++;
	//}

	int weaponsEquipped = 0;
	int offhandsEquipped = 0;
	int accessoriesEquipped = 0;
	while (find(equipMatcher)) {
		item equippedItem = to_item(group(equipMatcher, 1));
		assert(equippedItem != $item[none], "could not convert the item in the max string to an item object");
		slot equippedItemSlot = equippedItem.to_slot();

		// if we're looking at a weapon or offhand, check 2H weapons and more than 1 weapon as well
		if (equippedItemSlot == $slot[acc1] || equippedItemSlot == $slot[acc2] || equippedItemSlot == $slot[acc3])
			accessoriesEquipped++;
		else if (equippedItemSlot == $slot[off-hand])
			offhandsEquipped++;
		else if (equippedItemSlot == $slot[weapon] && weapon_type(equippedItem) != $stat[none]) // stat none weapons are weird for some reason
			weaponsEquipped += weapon_hands(equippedItem);

		if ((checkSlot == $slot[off-hand] || checkSlot == $slot[weapon]) && weaponsEquipped + offhandsEquipped >= totalHands)
			return true;
		else if (checkSlot == $slot[off-hand] && offhandsEquipped + max(0, weaponsEquipped - 1) >= offHands)
			return true;
		else if ((checkSlot == $slot[acc1] || checkSlot == $slot[acc2] || checkSlot == $slot[acc3]) && accessoriesEquipped >= 3)
			return true;
		else if (equippedItemSlot == checkSlot && !(checkSlot == $slot[acc1] || checkSlot == $slot[acc2] || checkSlot == $slot[acc3] || checkSlot == $slot[off-hand] || checkSlot == $slot[weapon]))
			return true;
	}

// 	if ((checkSlot == $slot[weapon] || checkSlot == $slot[off-hand]) && weaponsEquipped >= 1)
// 		return maxStringToTest.contains_text("+club") || maxStringToTest.contains_text("type club") || maxStringToTest.contains_text("+accordion") || maxStringToTest.contains_text("type accordion");

	return false;
}


// returns true if the given maximize string allows equipping the given item
// i.e. we're not already equipping an item in the same slot
boolean canEquipWithMaxString(string maxString, item anItem) {
	string actualMaxString = expandOutfits(maxString);
	return ((!actualMaxString.wantsToEquip(to_slot(anItem))) && (!actualMaxString.wantsToNotEquip(anItem)));
}

// returns true if the current automated dressup string allows equipping the given item
boolean canEquipWithExistingAutomatedDressup(item anItem) {
	string maxString = get_property(kDressupMaxStringKey);
	return canEquipWithMaxString(maxString, anItem);
}



string maxStringAppendIfPossibleToEquip(string maxString, item itemToEquip) {
	if (canEquipWithMaxString(maxString, itemToEquip))
		return maxStringAppend(maxString, "equip " + itemToEquip);
	else
		return maxString;
}



string toString(ActionRecord ar) {
	if (ar.attack != false) return "attack!";
	if (ar.pickpocket != false) return "pickpocket!";
	if (ar.skillToUse != $skill[none]) return "use skill: " + ar.skillToUse;
	if (ar.itemToUse != $item[none]) return "use item: " + ar.itemToUse + ", item 2: " + ar.item2ToUse;
	return "empty action!";
}


boolean isEmptyAction(ActionRecord ar) {
	if (ar.attack != false) return false;
	if (ar.pickpocket != false) return false;
	if (ar.skillToUse != $skill[none]) return false;
	if (ar.itemToUse != $item[none]) return false;
	return true;
}


// returns true if the contents of the two ActionRecords are the same, i.e. they reference the same action
boolean isSameAction(ActionRecord one, ActionRecord two) {
	if (one.attack != two.attack) return false;
	if (one.pickpocket != two.pickpocket) return false;
	if (one.skillToUse != two.skillToUse) return false;
	if (one.itemToUse != two.itemToUse) return false;
	if (one.item2ToUse != two.item2ToUse) return false;
	return true;
}


// returns the HTML page that is the result of taking the given action -- must be in combat!
string takeAction(ActionRecord theAction) {
	if (theAction.attack)
		return attack();
	else if (theAction.pickpocket)
		return steal();
	else if (theAction.skillToUse != $skill[none])
		return use_skill(theAction.skillToUse);
	else if (theAction.item2ToUse == $item[none])
		return throw_item(theAction.itemToUse);
	else
		return throw_items(theAction.itemToUse, theAction.item2ToUse);
}


string macroForAction(ActionRecord theAction) {
	if (theAction.attack)
		return "attack;";
	else if (theAction.pickpocket)
		return "pickpocket;";
	else if (theAction.skillToUse != $skill[none])
		return "skill " + theAction.skillToUse + ";";
	else if (theAction.item2ToUse == $item[none])
		return "use " + theAction.itemToUse + ";";
	else
		return "use " + theAction.itemToUse.to_int() + ", " + theAction.item2ToUse.to_int() + ";";
}

string macroForActions(ActionRecord [int] actions) {
	string rval;

	// order is important and the records might not have been inserted in order
	for i from 0 to count(actions) {
		ActionRecord action = actions[i];
// 		print("creating macro for action: " + toString(action));
		if (!isEmptyAction(action))
			rval += macroForAction(action);
	}
	return rval;
}


string equipStringForAction(ActionRecord theAction) {
	string rval;
	if (theAction.itemToUse != $item[none] && !theAction.itemToUse.combat) // assumes all non-combat items are equippable and all combat items are not equippable
		rval = "equip " + theAction.itemToUse;
	return rval;
}



// PRIORTY QUEUE STUFF


void printPSR(PrioritySkillRecord toPrint) {
	print("[" + toPrint.priority + "]" + toPrint.theSkill
		+ " with item " + toPrint.theItem + "@" + toPrint.meatCost
		+ ", " + toPrint.usesAvailable
		+ " uses, available now: " + toPrint.isAvailableNow);
}

void printPSRArray(PrioritySkillRecord [] arrayToPrint) {
	print("");
	foreach psrIndex, psrToPrint in arrayToPrint
		printPSR(psrToPrint);
}


boolean isEmpty(PrioritySkillRecord psr) {
	if (psr.theSkill != $skill[none]) return false;
	if (psr.theItem != $item[none]) return false;
	if (psr.mpCost != 0) return false;
	if (psr.meatCost != 0) return false;
	if (psr.priority != 0.0) return false;
	if (psr.usesAvailable != 0) return false;

	return true;
}



// take the floor of the priority: the lowest of those goes first, ties are broken first by number of uses available, then by the fractional part of the priority
PrioritySkillRecord skillToUse(PrioritySkillRecord [] skillData, location aLocation, int maxPerTurnCost, PrioritySkillRecord [] excludedSkills) {
	boolean isInCombat = inCombat();
	print("skillToUse, in combat: " + isInCombat + ", location: " + aLocation + ", maxPerTurnCost: " + maxPerTurnCost);
// 	printPSRArray(skillData);
	PrioritySkillRecord psr;

	// start by getting the set of skills with the same lowest integer priority with usesAvailable > 0 and isAvailableNow
	PrioritySkillRecord [int] setOfSkillsSamePriority;
	int prioritySetIndex = 0;
	int lowestIntegerPriority = kMaxInt;
	foreach idx in skillData {
		psr = skillData[idx];
		psr = new PrioritySkillRecord(psr.theSkill, psr.theItem, psr.mpCost, psr.meatCost,
			psr.priority, smmRPAllowedSkillUses(psr.theSkill, psr.usesAvailable), psr.isAvailableNow);
		if (arrayContains(excludedSkills, psr)) {
			print("excluding " + psr.theSkill);
			continue;
		}
		if (truncate(psr.priority) == lowestIntegerPriority && psr.usesAvailable > 0 && psr.isAvailableNow) {
			setOfSkillsSamePriority[prioritySetIndex++] = psr;
		} else if (truncate(psr.priority) < lowestIntegerPriority && psr.usesAvailable > 0 && psr.isAvailableNow) {
			prioritySetIndex = 0;
			clear(setOfSkillsSamePriority);
			setOfSkillsSamePriority[prioritySetIndex++] = psr;
			lowestIntegerPriority = truncate(psr.priority);
		}
	}
	// should end up with a set of skills with the lowest integer priority and all available to use now
// 	printPSRArray(setOfSkillsSamePriority);

	// select the set of skills with the highest usesAvailable within the results so far
	PrioritySkillRecord [int] setOfSkillsSameUses;
	prioritySetIndex = 0;
	int highestAvailableUses = 0;
	foreach idx in setOfSkillsSamePriority {
		psr = setOfSkillsSamePriority[idx];
		if (psr.usesAvailable == highestAvailableUses) {
			setOfSkillsSameUses[prioritySetIndex++] = psr;
		} else if (psr.usesAvailable > highestAvailableUses) {
			prioritySetIndex = 0;
			clear(setOfSkillsSameUses);
			setOfSkillsSameUses[prioritySetIndex++] = psr;
			highestAvailableUses = psr.usesAvailable;
		}
	}
	// should end up with a set of skills with the lowest integer priority and highest usesAvailable
// 	printPSRArray(setOfSkillsSameUses);

	// select the skill with the highest fractional priority within the results so far
	PrioritySkillRecord [int] setOfSkillsLowestPriority;
	prioritySetIndex = 0;
	float lowestPriority = kMaxInt;
	foreach idx in setOfSkillsSameUses {
		psr = setOfSkillsSameUses[idx];
		if (psr.priority == lowestPriority) {
			setOfSkillsLowestPriority[prioritySetIndex++] = psr;
		} else if (psr.priority < lowestPriority) {
			prioritySetIndex = 0;
			clear(setOfSkillsLowestPriority);
			setOfSkillsLowestPriority[prioritySetIndex++] = psr;
			lowestPriority = psr.priority;
		}
	}

	print("skillToUse final recommendations:");
	printPSRArray(setOfSkillsLowestPriority);
	// choose one of the remaining and make sure we can use it
	int i = 0;
	while (i < count(setOfSkillsLowestPriority)) {
		psr = setOfSkillsLowestPriority[i];
		if (psr.theSkill == $skill[none] // no skill means we're prioritizing items that we don't have to equip, in which case, return the first one
			|| psr.theItem == $item[none] || equipped_amount(psr.theItem) > 0 // otherwise, make sure we can equip the item
			|| (!isInCombat && can_equip(psr.theItem) && canEquipWithExistingAutomatedDressup(psr.theItem)))
			break;
		i++;
	}

	// if all the recommended are invalid (mostly because we can't equip the item for
	// one reason or another -- not enough stats usually), add everything we got to the
	// existing excludeSkills and try again
// 	if(count(setOfSkillsLowestPriority) > 0 && i >= count(setOfSkillsLowestPriority)) {
// 		print("chosen item can't be equipped, trying again", "orange");
// 		foreach idx, psr in excludedSkills
// 			setOfSkillsLowestPriority[i++] = psr;
// 		return skillToUse(skillData, aLocation, maxPerTurnCost, setOfSkillsLowestPriority);
// 	}

	print("choosing number " + i);
	printPSR(setOfSkillsLowestPriority[i]);
	return setOfSkillsLowestPriority[i];
}

// how many banishes do we have available right now? the fact that a banish is already in use doesn't matter
int skillsAvailable(PrioritySkillRecord [] priorityData, int maxCost) {
	int rval;
	foreach idx, psr in priorityData {
		int allowedUses = smmRPAllowedSkillUses(psr.theSkill, psr.usesAvailable);
		if (psr.isAvailableNow && (maxCost >= psr.meatCost)) {
			// some records use kMaxInt rather than kUnlimitedUses for "unlimited": count either as one
			// so the total can't overflow, and never let a negative count subtract from it
			if (allowedUses >= kUnlimitedUses)
				rval++;
			else if (allowedUses > 0)
				rval += allowedUses;
		}
	}
	return rval;
}


int skillsAvailable(PrioritySkillRecord [] priorityData) {
	return skillsAvailable(priorityData, kMaxInt);
}

PrioritySkillRecord topPriority(PrioritySkillRecord [] priorityData) {
	PrioritySkillRecord [] excludedData;
	PrioritySkillRecord topPri = skillToUse(priorityData, $location[none], kMaxInt, excludedData);
	assert(!isEmpty(topPri), "topPriority: no top priority returned!");
	return topPri;
}



void printPR(PriorityRecord toPrint) {
	print("[" + toPrint.priority + "]" + toPrint.maximizeString
		+ " with cli script: " + toPrint.cliExecuteString + "@"
		+ " with combat script: " + toPrint.customCombatString + "@" + toPrint.meatCost
		+ ", " + toPrint.usesAvailable
		+ " uses, available now: " + toPrint.isAvailableNow);
}

void printPRArray(PriorityRecord [] arrayToPrint) {
	print("");
	foreach prIndex, prToPrint in arrayToPrint
		printPR(prToPrint);
}



PriorityRecord skillToUse(PriorityRecord [] skillData, location aLocation, int maxPerTurnCost, PriorityRecord [] excludedSkills) {
	boolean isInCombat = inCombat();
	print("skillToUse, in combat: " + isInCombat + ", location: " + aLocation + ", maxPerTurnCost: " + maxPerTurnCost);
// 	printPSRArray(skillData);
	PriorityRecord psr;

	// start by getting the set of skills with the same lowest integer priority with usesAvailable > 0 and isAvailableNow
	PriorityRecord [int] setOfSkillsSamePriority;
	int prioritySetIndex = 0;
	int lowestIntegerPriority = kMaxInt;
	foreach idx in skillData {
		psr = skillData[idx];
		if (arrayContains(excludedSkills, psr)) {
			print("excluding " + psr.maximizeString);
			continue;
		}
		if (truncate(psr.priority) == lowestIntegerPriority && psr.usesAvailable > 0 && psr.isAvailableNow) {
			setOfSkillsSamePriority[prioritySetIndex++] = psr;
		} else if (truncate(psr.priority) < lowestIntegerPriority && psr.usesAvailable > 0 && psr.isAvailableNow) {
			prioritySetIndex = 0;
			clear(setOfSkillsSamePriority);
			setOfSkillsSamePriority[prioritySetIndex++] = psr;
			lowestIntegerPriority = truncate(psr.priority);
		}
	}
	// should end up with a set of skills with the lowest integer priority and all available to use now
// 	printPRArray(setOfSkillsSamePriority);

	// select the set of skills with the highest usesAvailable within the results so far
	PriorityRecord [int] setOfSkillsSameUses;
	prioritySetIndex = 0;
	int highestAvailableUses = 0;
	foreach idx in setOfSkillsSamePriority {
		psr = setOfSkillsSamePriority[idx];
		if (psr.usesAvailable == highestAvailableUses) {
			setOfSkillsSameUses[prioritySetIndex++] = psr;
		} else if (psr.usesAvailable > highestAvailableUses) {
			prioritySetIndex = 0;
			clear(setOfSkillsSameUses);
			setOfSkillsSameUses[prioritySetIndex++] = psr;
			highestAvailableUses = psr.usesAvailable;
		}
	}
	// should end up with a set of skills with the lowest integer priority and highest usesAvailable
// 	printPRArray(setOfSkillsSameUses);

	// select the skill with the highest fractional priority within the results so far
	PriorityRecord [int] setOfSkillsLowestPriority;
	prioritySetIndex = 0;
	float lowestPriority = kMaxInt;
	foreach idx in setOfSkillsSameUses {
		psr = setOfSkillsSameUses[idx];
		if (psr.priority == lowestPriority) {
			setOfSkillsLowestPriority[prioritySetIndex++] = psr;
		} else if (psr.priority < lowestPriority) {
			prioritySetIndex = 0;
			clear(setOfSkillsLowestPriority);
			setOfSkillsLowestPriority[prioritySetIndex++] = psr;
			lowestPriority = psr.priority;
		}
	}

	print("skillToUse final recommendations:");
	printPRArray(setOfSkillsLowestPriority);
	// choose one of the remaining
	int i = 0;
	while (i < count(setOfSkillsLowestPriority)) {
		psr = setOfSkillsSameUses[i];
		// TODO: make sure we can equip the item
        if (psr.meatCost / psr.duration <= maxPerTurnCost) {
            print("choosing number " + i);
            printPR(setOfSkillsLowestPriority[i]);
            return setOfSkillsLowestPriority[i];
        }
	}

	// if all the recommended are invalid (mostly because we can't equip the item for
	// one reason or another -- not enough stats usually), add everything we got to the
	// existing excludeSkills and try again
	if(count(setOfSkillsLowestPriority) > 0) {
 		print("highest priority items are too expensive, excluding them and trying again", "orange");
        // add the existing excluded skills to the new set
        i = count(setOfSkillsLowestPriority);
 		foreach idx, psr in excludedSkills
 			setOfSkillsLowestPriority[i++] = psr;
 		return skillToUse(skillData, aLocation, maxPerTurnCost, setOfSkillsLowestPriority);
	}

	print("no available skill", "red");
	print("current search data:");
	printPRArray(skillData);
	print("excluded skills:");
	printPRArray(excludedSkills);
	return new PriorityRecord();
}

// how many banishes do we have available right now? the fact that a banish is already in use doesn't matter
int skillsAvailable(PriorityRecord [] priorityData, int maxCost) {
	int rval;
	foreach idx, psr in priorityData {
		if (psr.isAvailableNow && (maxCost >= psr.meatCost)) {
			if (psr.usesAvailable == kUnlimitedUses)
				rval++;
			else
				rval += psr.usesAvailable;
		}
	}
	return rval;
}


int skillsAvailable(PriorityRecord [] priorityData) {
	return skillsAvailable(priorityData, kMaxInt);
}

PriorityRecord topPriority(PriorityRecord [] priorityData) {
	PriorityRecord [] excludedData;
	return skillToUse(priorityData, $location[none], kMaxInt, excludedData);
}



// -------------------------------------
// OUTFIT UTILITIES
// -------------------------------------


boolean haveOutfit(string outfitName) {
// 	print("checking outfit name: " + outfitName, "green");
	boolean rval = false;
	if (outfitName.starts_with("_")) {
		string prop = get_property(kSavedOutfitKeyPrefix + outfitName);
// 		rval = get_property(kSavedOutfitKeyPrefix + outfitName) != "";
		rval = prop != "" && !prop.contains_text(",");
	}
	else
		rval = have_outfit(outfitName);

	print("haveOutfit " + outfitName + ": " + rval, rval ? "green" : "orange");
	return rval;
}



void saveEquippedFamiliar(string outfitName) {
	set_property(kSavedFamiliarKeyPrefix + outfitName, my_familiar());
	set_property(kSavedFamiliarEquipKeyPrefix + outfitName, equipped_item($slot[familiar]));
}

void saveEquippedFamiliar() {
	saveEquippedFamiliar("Backup");
}


void saveOutfit(string outfitName, string outfitString) {
	assert(outfitName != "" && outfitString != "", "saveOutfit: bad params, outfitName: " + outfitName + "; outfitString: " + outfitString);
	print("Saving outfit named: " + outfitName, "blue");
	print(outfitString);

	// use the built-in facility for outfits that aren't meant to be used internally (i.e. those that start with an underscore)
	if (!outfitName.starts_with("_")) {
		cli_execute("outfit save " + outfitName);
	}

	set_property(kSavedOutfitKeyPrefix + outfitName, outfitString);
	saveEquippedFamiliar(outfitName);
}

void saveOutfit(string outfitName) {
	string outfitString = logEquipmentString(true);
	saveOutfit(outfitName, outfitString);
}

void saveOutfit() {
	saveOutfit("Backup");
}


boolean restoreEquippedFamiliar(string outfitName) {
	familiar theFamiliar = to_familiar(get_property(kSavedFamiliarKeyPrefix + outfitName));
	if (my_familiar() != theFamiliar)
		if (!use_familiar(theFamiliar))
			return false;

	item familiarEquipment = to_item(get_property(kSavedFamiliarEquipKeyPrefix + outfitName));
	if (equipped_item($slot[familiar]) != familiarEquipment) {
		fullAcquire(familiarEquipment);
		if (equip(familiarEquipment))
			return true;
		return false;
	}
	return true;
}

boolean restoreEquippedFamiliar() {
	return restoreEquippedFamiliar("");
}


// restore an outfit using the built-in outfit system iff the outfit name does not start with "_" underscore
// if it does start with underscore, will use the property database to store the outfit and re-equip one piece at a time.
boolean restoreOutfit(boolean restoreFamiliar, string outfitName) {
	assert(haveOutfit(outfitName), "restoreOutfit: we don't have outfit '" + outfitName + "' to restore!");

	string outfitPiecesString = get_property(kSavedOutfitKeyPrefix + outfitName);
	print("restoreOutfit: " + outfitName + ", restoring familiar: " + restoreFamiliar, "blue");
	print(outfitPiecesString, "green");

	boolean rval = true;

	// parse the outfit pieces we need to be wearing from the saved outfitName property
	item [slot] outfitPieces;
	if (outfitName.starts_with("_")) {
		foreach idx, pieceString in outfitPiecesString.split_string("\t") {
			string [] pieces = pieceString.split_string(": ");
			if (count(pieces) < 2) {
				print("problem parsing: " + pieceString);
				continue;
			}
			if (pieces[1] == "none") continue; // some slots will have no item equipped
			if (pieces[0].starts_with("fam")) continue; // ignore saved familiar (fam will be done by restoreEquippedFamiliar)

			slot theSlot = pieces[0].to_slot();
			item theEquipment = pieces[1].to_item();

			assert(theEquipment != $item[none] && theSlot != $slot[none], "restoreOutfit: something wrong with item: " + pieces[1] + " in slot: " + pieces[0]);
			outfitPieces[theSlot] = theEquipment;
		}
	} else
		outfitPieces = slotted_outfit_pieces(outfitName);

	// count the number of each item we need
	int [item] itemCount;
	foreach aSlot, doodad in outfitPieces
		itemCount[doodad]++;

	// calc the difference between what we are wearing and what we want to wear
	int [item] needed;
	foreach doodad, amt in itemCount {
		if (equipped_amount(doodad) < amt) {
			needed[doodad] = amt - equipped_amount(doodad);
		}
	}

	// acquire each piece
	foreach doodad, amt in needed {
		if (fullAcquire(doodad, amt) < amt) {
			rval = false;
			print("restoreOutfit: could not acquire " + amt + " X " + doodad + "!!!", "orange");
		}
	}

	if (outfitName.starts_with("_") || !cli_execute("outfit " + outfitName)) {
		// equip one piece at a time
		foreach aSlot, anItem in outfitPieces {
			if (can_equip(anItem) && have_item(anItem) && equipped_amount(anItem) < itemCount[anItem])
				equip(anItem, aSlot);
		}
	}

	if (restoreFamiliar)
		rval = restoreEquippedFamiliar(outfitName) && rval; // order is important with short-circuiting

	return rval;
}

boolean restoreOutfit(string outfitName) {
	return restoreOutfit(true, outfitName);
}

boolean restoreOutfit() {
	return restoreOutfit("Backup");
}


void clearSavedFamiliar(string outfitName) {
	set_property("_" + outfitName + "_savedFamiliar", "");
	set_property("_" + outfitName + "_savedFamiliarEquipment", "");
}

void clearSavedFamiliar() {
	clearSavedFamiliar("");
}


void wearDefaultOutfit() {
	cli_execute("outfit " + kDefaultOutfit);
}



int fullnessRoom() {
	return fullness_limit() - my_fullness();
}


int inebrietyRoom() {
	return inebriety_limit() - my_inebriety();
}


int spleenRoom() {
	return spleen_limit() - my_spleen_use();
}


boolean isOverdrunk() {
	return my_inebriety() > inebriety_limit();
}


// returns true if we're max'ed out on food and drink
// if checkSpleen is true, check we have at least 5 spleen to recover from overdrinking fermented pickle juice
boolean readyToOverdrink(boolean checkSpleen) {
	int myLimit = inebriety_limit();
	if (my_familiar() == $familiar[Stooper]) myLimit--;

	if (my_inebriety() != myLimit && my_inebriety() != myLimit + 1) return false;
	if (my_fullness() != fullness_limit()) return false;
	if (checkSpleen && my_spleen_use() < 5) return false;

	return true;
}


// returns true if we have yet to drink 1 drunkenness for the stooper
boolean isStooperPending() {
	boolean haveStooper = my_familiar() == $familiar[Stooper];
	return (haveStooper && my_inebriety() < inebriety_limit()) || (!haveStooper && my_inebriety() <= inebriety_limit());
}



// returns the number of UNBANISHED monsters at aLocation.
// if get_all is false, only monsters with a positive appearance rate will be counted
// (which means bosses and monsters in NCs are excluded)
int number_monsters(location aLocation, boolean get_all) {
	float [monster] monster_map = appearance_rates(aLocation);
	int total_monsters = 0;
	foreach m in monster_map {
		if ((m != $monster[none]) && (get_all || (monster_map[m] > 0))) {
			total_monsters++;
		}
	}
	return total_monsters;
}


// does the given location have the given monster?
boolean contains_monster(location aLocation, monster a_monster) {
	monster [int] monster_map = get_monsters(aLocation);
	foreach i in monster_map
		if (monster_map[i] == a_monster) return true;
	return false;
}



// returns the number of the step or stage of the quest represented by questPropertyName #quest tracking preferences
// "unstarted" state returns -1, "started" returns 0, "finished" returns kMaxInt
int questStage(string questPropertyName) {
	string stage = get_property(questPropertyName);
	if (stage == "unstarted") return -1;
	if (stage == "started") return 0;
	if (stage == "finished") return kMaxInt;
	if (stage == "") abort("questStage: no stage for " + questPropertyName);
	return stage.substring(4).to_int();
}



string raw_quest_log_string = "";
string get_quest_log() {
	if (raw_quest_log_string == "") {
		raw_quest_log_string = visit_url("/questlog.php?which=7", true, false);
	}
	return raw_quest_log_string;
}

string [string] quest_log_entries;
string [string] parse_quest_log() {
	if (count(quest_log_entries) == 0) {
		string page = get_quest_log();
		matcher aMatcher = create_matcher("<b>([^>]+)</b><br>(.+?)<p>", page);
		while (find(aMatcher)) {
			string quest_name = group(aMatcher, 1);
			string quest_text = group(aMatcher, 2);
			quest_log_entries[quest_name] = quest_text;
		}
	}

	return quest_log_entries;
}

void clear_quest_log_cache() {
	raw_quest_log_string = "";
	clear(quest_log_entries);
}

// returns the quest text for the given quest
string quest(string quest) {
	return parse_quest_log()[quest];
}

boolean is_on_quest(string quest) {
	return parse_quest_log() contains quest;
}

void print_quest(string quest_name) {
	print_html("<b>" + quest_name + ": </b>" + quest(quest_name));
}

void print_quest_log() {
	string [string] quest_log_entries = parse_quest_log();
	foreach quest in quest_log_entries {
		print_html("<b>" + quest + ": </b>" + quest_log_entries[quest]);
	}
}



boolean isUnlocked(location aLocation) {
	switch (aLocation) {
		// guild
		case $location[The "Fun" House]:
			return questStage("questG04Nemesis") >= 5;

		case $location[The Fungal Nethers]:
			return questStage("questG04Nemesis") >= 12;

		case $location[Belowdecks]:
			return questStage("questM12Pirate") > 6;
		case $location[The Poop Deck]:
			return questStage("questM12Pirate") >= 6;
		case $location[The F'c'le]:
			return questStage("questM12Pirate") >= 5;

		case $location[Cobb's Knob Menagerie, Level 1]:
		case $location[Cobb's Knob Menagerie, Level 2]:
		case $location[Cobb's Knob Menagerie, Level 3]:
			return have_item($item[Cobb's Knob Menagerie key]);
		case $location[The Knob Shaft]:
		case $location[Cobb's Knob Laboratory]:
			return have_item($item[Cobb's Knob lab key]);

		case $location[Tower Ruins]:
			return questStage("questG03Ego") >= 2;

		// Underwater
		case $location[The Dive Bar]:
			return "mapToTheDiveBarPurchased".get_property().to_boolean();
		case $location[Anemone Mine]:
			return "mapToAnemoneMinePurchased".get_property().to_boolean();
		case $location[The Marinara Trench]:
			return "mapToTheMarinaraTrenchPurchased".get_property().to_boolean();

		// Elemental International Airport
		case $location[The Deep Dark Jungle]:
		case $location[The Mansion of Dr. Weirdeaux]:
		case $location[The Secret Government Laboratory]:
		case $location[The Mouldering Mansion]:
		case $location[The Rogue Windmill]:
		case $location[The Stately Pleasure Dome]:
		case $location[The Fun-Guy Mansion]:
		case $location[Sloppy Seconds Diner]:
		case $location[The Sunken Party Yacht]:
		case $location[Barf Mountain]:
		case $location[Pirates of the Garbage Barges]:
		case $location[The Toxic Teacups]:
		case $location[Uncle Gator's Country Fun-Time Liquid Waste Sluice]:
		case $location[The Ice Hotel]:
		case $location[VYKEA]:
		case $location[The Ice Hole]:
		case $location[The SMOOCH Army HQ]:
		case $location[The Velvet / Gold Mine]:
		case $location[LavaCo&trade; Lamp Factory]:
		case $location[The Bubblin' Caldera]:
			return false;

		case $location[The Red Queen's Garden]:
			return have_effect($effect[Down the Rabbit Hole]) > 0;

		case $location[Domed City of Ronaldus]:
		case $location[Domed City of Grimacia]:
		case $location[Hamburglaris Shield Generator]:
			return have_effect($effect[Transpondent]) > 0;
	}

	return true;
}


// prints useful info for the location we're about to adventure in
// only prints the info once per day per location
void notesForLocation(location aLocation) { // location notes locationnotes
	string doOnceProperty = "_smm.DoOnceNotesForLocation" + aLocation;
	boolean doneOnce = to_boolean(get_property(doOnceProperty));

	string [location] notes = {
		$location[The Fungal Nethers] : "can OLFACT angry fungus",
		$location[Thugnderdome] : "can OLFACT gnarly and gnasty gnome",
		$location[8-bit realm] : "can OLFACT blooper",
		$location[The Haunted Library] : "can OLFACT writing desk",
		$location[The Defiled Niche] : "can OLFACT dirty old lihc",
		$location[The Goatlet] : "can OLFACT dairy goat",
		$location[Twin Peak] : "can OLFACT topiary",
		$location[The Hidden Temple] : "can OLFACT sheep",
		$location[The Haunted Wine Cellar] : "can OLFACT possessed wine rack",
		$location[The Haunted Laundry Room] : "can OLFACT cabinet",
		$location[The Haunted Boiler Room] : "can OLFACT boiler",
		$location[The Penultimate Fantasy Airship] : "can OLFACT healer",
		$location[Belowdecks] : "can OLFACT gaudy pirate",
		$location[The Hidden Bowling Alley] : "can OLFACT bowler pygmy",
		$location[The Middle Chamber] : "can OLFACT tomb rat",
		$location[The Battlefield (Hippy Uniform)] : "can OLFACT sorority operator",

		$location[The Haunted Laundry Room] : "can get INVISIBLE STRING for use with li'l ghost costume",
		$location[The Haunted Storage Room] : "can get_all INVISIBLE SEAM RIPPER for use with li'l ghost costume",
		$location[Lair of the Ninja Snowmen] : "can get INVISIBLE SEAM RIPPER for use with li'l ghost costume",
	};

	print("\n\nAdventuring at: " + aLocation, "blue");
	if (notes[aLocation] != "" && !doneOnce) {
		print(notes[aLocation], "blue");
		int times = 3;
		repeat {
			waitq(5);
			print(notes[aLocation], "blue");
			times--;
		} until (times == 0);
	}

	set_property(doOnceProperty, "true");
}



boolean is_pvpable(item thing) {
	return thing.tradeable && thing.discardable && !thing.gift && !thing.quest;
}


// closet any items valued greater than expensiveValue
// WARNING: will store items that are potentially useful in combat
void store_pvp() {
	int expensiveValue = 400;

	int [item] inventory = get_inventory();
	batch_open();
	foreach it in inventory {
		if(is_pvpable(it) && get_price(it, 3) > expensiveValue) {
			print_html("storing: " + item_amount(it) + " " + it + "@" + get_price(it, 3));
			put_closet(item_amount(it), it);
		}
	}
	batch_close();
}

void stow_pvpable_items() {
	if (hippy_stone_broken()) {
		store_pvp();
	}
}


int pvpVictories(boolean printList) {
	int rval;
	foreach idx, aVictory in split_string(get_property("currentPvpVictories"), ",") {
		rval++;
		cprint(printList, aVictory);
	}
	return rval;
}


// [80]The Valley of Rof L'm Fao@8503
// [113]The Haunted Pantry@6233
// [353]The Degrassi Knoll Gym@3987
// [172]The Purple Light District@22788
// [166]A Maze of Sewer Tunnels@3895
location kAutumnatonLocation = "smm.AutumnatonLocation".get_property() == "" ? $location[The Copperhead Club] : "smm.AutumnatonLocation".get_property().to_location();




// -------------------------------------
// DISPLAY CASE UTILITIES
// -------------------------------------


string rawDisplayCase() {
	return visit_url("/displaycollection.php?who=" + my_id(), true, false);
}


int [item] shelfItems(string pageString, string shelfName) {
	int [item] rval;

	matcher shelfMatcher = create_matcher("<table.+?(shelf[0-9]+).+?" + shelfName + ".+?(shelf[0-9]+)(.+?)</table>", pageString);
	find(shelfMatcher);
	string shelfId = group(shelfMatcher, 1);
	string shelfPage = group(shelfMatcher, 3);

	matcher listMatcher = create_matcher("<td valign=center><b>(.*?)</b> ?\\(?([0-9,]*)\\)?</td>", shelfPage);
	while (find(listMatcher)) {
		item anItem = group(listMatcher, 1).to_item();
		int itemAmount = to_int(group(listMatcher, 2));
		rval[anItem] = itemAmount;
	}

	return rval;
}

int [item] shelfItems(string shelfName) {
	return shelfItems(rawDisplayCase(), shelfName);
}


int shelfItemCount(string pageName, string shelfName) {
	return count(shelfItems(pageName, shelfName));
}

int shelfItemCount(string shelfName) {
	return shelfItemCount(rawDisplayCase(), shelfName);
}


string [] shelves() {
	string [int] rval;
	string pageString = rawDisplayCase();
	matcher shelfMatcher = create_matcher("shelf([\\d]+)\\\"\\);\\\' class=nounder><font color=white>([\\w ]+?)</font>", pageString);
	while (find(shelfMatcher)) {
		int shelfNumber = to_int(group(shelfMatcher, 1));
		string shelfName = group(shelfMatcher, 2);
		rval[shelfNumber] = shelfName;
	}
	return rval;
}

int [string] shelvesByItemCount() {
	int [string] rval;
	string pageString = rawDisplayCase();
	matcher shelfMatcher = create_matcher("shelf([\\d]+)\\\"\\);\\\' class=nounder><font color=white>([\\w ]+?)</font>", pageString);
	while (find(shelfMatcher)) {
		int shelfNumber = to_int(group(shelfMatcher, 1));
		string shelfName = group(shelfMatcher, 2);

		rval[shelfName] = shelfItemCount(pageString, shelfName);
	}
	return rval;
}



int countTop10(int [int, string] top10List) {
	int totalCount = 0;
	foreach rank, name, num in top10List {
		totalCount++;
	}
	return totalCount;
}


// ensure there are 10 or 11 entries and that the ranks go non-decreasing sequentially from 1
boolean isValidTop10List(int [int, string] top10List) {
	int followRank = 1;
	int ties = 0;
	int totalCount = 0;
	foreach rank, name, num in top10List {
		totalCount++;
// 		print("totalCount: " + totalCount + ", followRank: " + followRank + ", ties: " + ties + ", rank: " + rank + ", name: " + name + ", num: " + num);
		// sequential order
		if (rank == followRank) {
			followRank++;
			continue;
		}
		// same rank as last, i.e. a tie
		if (rank == followRank - 1) {
			ties++;
			continue;
		}
		// the rank after a number of ties
		if (ties > 0 && followRank + ties == rank) {
			ties = 0;
			followRank = rank + 1;
			continue;
		}
		return false;
	}

	if (totalCount < 1) // if we found 1, we found a top 10 list
		return false;

	return true;
}


// returns the value of the given index without having to dereference the string
int amountAtRank(int [int, string] aCollection, int aRank) {
    assert(isValidTop10List(aCollection), "amountAtRank: not a valid top 10 list");
	int totalCount = 0;
	foreach rank, name, num in aCollection {
		totalCount++;
		if (totalCount == aRank)
			return num;
	}
	abort("could not find amount at rank " + aRank);
	return 0;
}


string nameAtRank(int [int, string] aCollection, int aRank) {
    assert(isValidTop10List(aCollection), "nameAtRank: not a valid top 10 list");
	int totalCount = 0;
	foreach rank, name, num in aCollection {
		totalCount++;
		if (totalCount == aRank)
			return name;
	}
	abort("could not find name at rank " + aRank);
	return 0;
}


int rank1Amount(int [int, string] top10List) {
    assert(isValidTop10List(top10List), "rank1Amount: not a valid top 10 list");
	return amountAtRank(top10List, 1);
}

// strictly misnamed: returns the amount at the lowest rank, even if there are fewer than 10 in the top 10
int rank10Amount(int [int, string] top10List) {
    assert(isValidTop10List(top10List), "rank10Amount: not a valid top 10 list");
	int rank = 10;
	int top10Count = countTop10(top10List);
	if (top10Count < 10) {
		rank = top10Count;
	}
	return amountAtRank(top10List, rank);
}

IntRange collectionRange(int [int, string] top10List) {
    assert(isValidTop10List(top10List), "collectionRange: not a valid top 10 list");
	IntRange rval;
	rval.top = rank1Amount(top10List);
	rval.bottom = rank10Amount(top10List);
	return rval;
}


// returns true if the amount of the given item in our display case is in the top 10
boolean in_top10(item anItem, int [int, string] top10List) {
    assert(isValidTop10List(top10List), "in_top10: not a valid top 10 list");
	return display_amount(anItem) >= rank10Amount(top10List);
}


string toStringCompact(int [int, string] top10List) {
    assert(isValidTop10List(top10List), "toStringCompact: not a valid top 10 list");
	string rval;
	foreach rank, name, num in top10List {
		rval += rank + ". " + name + ": " + num + ", ";
	}
	return rval;
}

string toString(int [int, string] top10List) {
    assert(isValidTop10List(top10List), "toString: not a valid top 10 list");
	string rval;
	foreach rank, name, num in top10List {
		rval += rank + ". " + name + ": " + num + "</br>\n";
	}
	return rval;
}

void printTop10List(int [int, string] top10List) {
    assert(isValidTop10List(top10List), "printTop10List: not a valid top 10 list");
	print_html(toString(top10List));
}


// The current wiki renders Museum rankings as a Collection list. Keep the legacy
// formats as fallbacks for older pages and the original collection database.
int [int, string] parseCollectionPage(string pageString) {
	int [int, string] top10List;
	matcher collection = create_matcher("(?is)<div\\b[^>]*class=['\"][^'\"]*\\bcollection\\b[^'\"]*['\"][^>]*>(.*?)</div>", pageString);
	if (find(collection)) {
		matcher entries = create_matcher("(?is)<li\\b[^>]*>(.*?)</li>", group(collection, 1));
		while (find(entries)) {
			string entry = entity_decode(replace_all(create_matcher("(?s)<[^>]*>", group(entries, 1)), ""));
			matcher row = create_matcher("^\\s*(🥇|🥈|🥉|#[0-9]+):\\s*(.*?)\\s*\\(#[0-9]+\\)\\s*-\\s*([0-9,]+)\\s*$", entry);
			if (!find(row)) {
				clear(top10List);
				return top10List;
			}
			string label = group(row, 1);
			int rank = label == "🥇" ? 1 : label == "🥈" ? 2 : label == "🥉" ? 3 : substring(label, 1).to_int();
			string name = group(row, 2);
			string amount = group(row, 3).replace_string(",", "");
			top10List[rank, name] = amount.to_int();
		}
		return top10List;
	}
	matcher rows = create_matcher("<tr><td bgcolor=\"white\" align=\"center\" valign=\"center\"><b>([0-9]+)</b></td>.*?<b>([^<]*)</b>.*?<b>([0-9,]+)</b></td></tr>", pageString);
	while (find(rows))
		top10List[group(rows, 1).to_int(), group(rows, 2)] = group(rows, 3).replace_string(",", "").to_string().to_int();
	if (!isValidTop10List(top10List)) {
		clear(top10List);
		rows = create_matcher("([1-9]0?)\\. <a href=['\"][^'\"]*['\"]>(.*?) - ([0-9,]+)</a>", pageString);
		while (find(rows))
			top10List[group(rows, 1).to_int(), group(rows, 2)] = group(rows, 3).replace_string(",", "").to_string().to_int();
	}
	return top10List;
}

// Museum is the current source behind the wiki's Collection section. Its item
// page also works for clients that receive HTTP 403 from the wiki.
int [int, string] parseMuseumCollectionPage(string pageString) {
	int [int, string] top10List;
	matcher rows = create_matcher("(?is)<tr\\b[^>]*>(.*?)</tr>", pageString);
	while (find(rows)) {
		string row = group(rows, 1);
		if (!contains_text(row, "href=\"/player/"))
			continue;
		row = replace_all(create_matcher("(?is)<style\\b[^>]*>.*?</style>", row), "");
		matcher cells = create_matcher("(?is)<td\\b[^>]*>(.*?)</td>", row);
		string [int] values;
		int idx;
		while (find(cells)) {
			string text = entity_decode(replace_all(create_matcher("(?s)<[^>]*>", group(cells, 1)), ""));
			values[idx++] = replace_all(create_matcher("^\\s+|\\s+$", text), "");
		}
		if (idx < 3) {
			clear(top10List);
			return top10List;
		}
		string label = values[0];
		int rank = label == "🥇" ? 1 : label == "🥈" ? 2 : label == "🥉" ? 3 : label.starts_with("#") && length(label) > 1 ? substring(label, 1).to_int() : 0;
		if (rank > 10)
			break;
		string amount = values[2].replace_string(",", "");
		if (rank < 1 || !amount.is_integer() || amount.to_int() < 1) {
			clear(top10List);
			return top10List;
		}
		top10List[rank, values[1]] = amount.to_int();
	}
	return top10List;
}

// Returns a validated ranking list. Optional lookups return an empty map on failure;
// an unavailable list must never be used to decide how many items to move or buy.
int [int, string] lookupCollection(item anItem, boolean required) {
	int [int, string] top10List;
	print("[" + anItem.to_int() + "]" + anItem + " @ " + current_price(anItem));
	string cacheString = get_property(kDCPropertyPrefix + anItem);
	matcher cacheMatcher = create_matcher("([0-9]+)\\. (.*?): ([0-9]+), ", cacheString);
	while (find(cacheMatcher))
		top10List[group(cacheMatcher, 1).to_int(), group(cacheMatcher, 2)] = group(cacheMatcher, 3).to_int();

	// Museum is the sole network source for collection rankings.
	if (!isValidTop10List(top10List))
		top10List = parseMuseumCollectionPage(visit_url("https://museum.loathers.net/item/" + to_int(anItem), false, false));

	if (!isValidTop10List(top10List)) {
		clear(top10List);
		if (required)
			abort("lookupCollection: top 10 rankings unavailable for " + anItem);
		print("Top 10 rankings unavailable for " + anItem + "; skipping ranking operations.", "orange");
		return top10List;
	}
	set_property(kDCPropertyPrefix + anItem, toStringCompact(top10List));
	return top10List;
}

// Preserve the strict behavior expected by other scripts.
int [int, string] lookupCollection(item anItem) {
	return lookupCollection(anItem, true);
}


void printTop10Item(item anItem) {
	lookupCollection(anItem).printTop10List();
}



void printMonsterArray(boolean [monster] someMons) {
	if (count(someMons) > 0) {
		monster [int] sortableMons;
		int idx;
		foreach amon in someMons
			sortableMons[idx++] = amon;
		sort sortableMons by value.to_string();

		foreach i, amon in sortableMons {
			string textColour = element_color(amon.monster_element());
			if (amon.boss) textColour = "red";

			string copyableString;
			if (isCopyable(amon)) copyableString = " (copyable)";

			string ppOnlyItemString;
			if (hasPPOnly(amon)) ppOnlyItemString = " (pp-only item)";

			print("[" + amon.to_int() + "]" + amon + copyableString, textColour);
		}
	} else
		print("no monsters");
	print("total monsters: " + count(someMons));
}


monster [] monstersMatchingPhylum(phylum matchingPhylum, boolean doPrint) {
	cprint(doPrint, "monsters matching phylum " + matchingPhylum + ":", "green");

	boolean [monster] matchingRems;
	monster [int] rval;
	int idx;
	foreach amon in $monsters[] {
		if (amon.monster_phylum() == matchingPhylum) {
			matchingRems[amon] = true;
			rval[idx++] = amon;
		}
	}

	if (doPrint)
		printMonsterArray(matchingRems);
	return rval;
}

monster [] monstersMatchingPhylum(phylum matchingPhylum) {
	return monstersMatchingPhylum(matchingPhylum, true);
}



float itemBaseDropChance(item wantedItem, monster fromMonster) {
	foreach index, data in item_drops_array(fromMonster) {
		if (data.drop == wantedItem)
			return data.rate;
	}

	abort(fromMonster + " does not drop " + wantedItem);
	return 0;
}


float itemDropBonusNeededToGuarantee(item wantedItem, monster fromMonster) {
	return ((100.0 / itemBaseDropChance(wantedItem, fromMonster)) - 1) * 100.0;
}



// TODO double check this and generalize
int perAdventureCost(location aLoc) {
	float perAdventureCost = 0.0;
	//perAdventureCost += (mall_price($item[Crimbo fudge]) + mall_price($item[Swizzler])) / 50; // Sweet Synthesis Collection (item)
	if (isAsdonWorkshed()) {
		perAdventureCost += (329 + 462) / 30.0; // Spring-loaded Front Bumper (banish)
		perAdventureCost += (329 + 462) / 30.0; // Driving somethingly
	}

	// 1 turn out of every 6 is wasted in the oasis
	if (aLoc == $location[The Oasis]) {
		perAdventureCost += (kTurnValue / 5);
	}

	//perAdventureCost += 0 / 50; // Items are Forever (KGB) can't guarantee each time
	return perAdventureCost;
}



// returns true if we're an accordion thief with an accordion equipped
boolean atAccordionEquipped() {
	return my_class() == $class[accordion thief] && item_type(equipped_item($slot[weapon])) == "accordion";
}



// returns the total number of adventures gained at rollover. Includes:
// base 40, gains from outfit, gains from special days, any special items that may affect adv at rollover
// if shouldSimulate is true, will use maximize to figure out a best case scenario for outfit, if false, will use whatever we're wearing now
int adventureGainAtRollover(boolean shouldSimulate) {
	int adv = 40;

	if (shouldSimulate) {
		maximize("adventures, switch tot", true);
		adv += numeric_modifier("Generated:_spec", "Adventures");
	} else {
		adv += numeric_modifier("Adventures");
	}

	int circadianRhythmsAdventures = "_circadianRhythmsAdventures".get_property().to_int();
	adv += circadianRhythmsAdventures;

	if (to_boolean(get_property("_borrowedTimeUsed"))) adv -= 20;
	adv += to_int(get_property("extraRolloverAdventures")); // not sure what this is, seems to be 0

	if (gameday_to_string() == "Carlvember 5") adv += 10;

	return adv;
}

int adventureGainAtRollover() {
	return adventureGainAtRollover(false);
}

int myAdventuresAtRollover(boolean shouldSimulate) {
	return adventureGainAtRollover() + my_adventures();
}

// total adventures at rollover based on what you have on now
int myAdventuresAtRollover() {
	return myAdventuresAtRollover(false);
}


void clearGoals() {
	/*int i;
	string g;
	foreach i,g in get_goals();
		remove_item_condition(i, to_item(g)); */
	// above doesn't work for some reason
	cli_execute("goal clear");
}

boolean haveGoals() {
	return count(get_goals()) > 0;
}


// -------------------------------------
// FINANCIAL UTILITIES ITEM UTILITIES MEAT UTILITIES ECONOMIC UTILTIES
// -------------------------------------


int gkDCSaveAmount = get_property("smm.dcSaveAmount") == "" ? 1 : get_property("smm.dcSaveAmount").to_int(); // amount to save from going into the display case


// returns the amount of the given item to save in inventory
// usually returns 1, but some items override that default
int saveAmount(item anItem) {
	// dc will call these functions (is_hatchling, is_gift, etc) on each item. if that function returns true for
	// the item, dc will save the associated number in this map instead of the default gkDCSaveAmount
	int [string] kTypeSaveMap = {
		"is_equipment" : 3, // any type of equipment TODO is_equipment is buggy right now, see is_equipment
		"is_gift" : 3, // gifts
		"is_skillbook" : 0, // skillbooks
		"is_hatchling" : 0, // hatchlings
		"is_tattookit" : 0, // tattoo kits
	};

	// ITEM-SPECIFIC OVERRIDES
	int [item] kSaveAmountItemMap = {
		$item[Guzzlr tattoo kit] : 0,
	};
	foreach it, amt in kSaveAmountItemMap
		if (anItem == it)
			return amt;

	// DEFAULT SAVE AMOUNT
	int saveAmount = gkDCSaveAmount;

	// CATEGORY-BASED OVERRIDES
	foreach evalString, tmpSaveAmount in kTypeSaveMap {
		boolean shouldSave = call boolean evalString (anItem);
		if (shouldSave) {
			saveAmount = tmpSaveAmount;
			print(evalString + " is saving " + saveAmount);
		}
	}

	return saveAmount;
}



void printReceiptItem(item anItem, int amt, int price) {
	print(amt + "X " + anItem + " @ " + price, "green");
}

int receiptTotal(int [item] receipt, boolean printTotal) {
	int numItems, meat;
	foreach anItem in receipt {
		numItems += receipt[anItem];
		meat += cheapest_price(anItem) * receipt[anItem];
	}
	cprint(printTotal, "TOTAL of " + numItems + " items @ " + meat + " meat (estimated)", "green");
	return meat;
}

int printReceipt(int [item] receipt, boolean printTotal) {
	int numItems, meat;
	foreach anItem in receipt {
		int buyPrice = cheapest_price(anItem);
		printReceiptItem(anItem, receipt[anItem], buyPrice);
		numItems += receipt[anItem];
		meat += buyPrice * receipt[anItem];
	}
	cprint(printTotal, "TOTAL of " + count(receipt) + " unique items, " + numItems + " total items @ " + meat + " meat (estimated)", "green");
	return meat;
}

int printReceipt(int [item] receipt) {
	return printReceipt(receipt, true);
}



// returns the higher of the minPrice or the current market price
int undercutPriceWithMin(item itemToUndercut, int minPrice) {
	int itemPrice = realMallPrice(itemToUndercut);
	if (itemPrice < 0) {
		print("price is less than 0 for " + itemToUndercut + ", manual intervention required", "red");
		abort(); // ?????
		return minPrice;
	}

	int actualPrice = max(itemPrice, minPrice);
	return actualPrice;
}

// returns the price the item was set to or 0 if repricing was unsuccessful
int undercutWithMinPrice(item itemToUndercut, int limit, int minPrice) {
	int undercutPrice = undercutPriceWithMin(itemToUndercut, minPrice);
	if (reprice_shop(undercutPrice, limit, itemToUndercut))
		return undercutPrice;
	else
		return 0;
}


int [int,string] smmMuseumCachedCollection(item it) {
    int [int,string] ranks;
    matcher cached=create_matcher("([0-9]+)\\. (.*?): ([0-9]+), ",get_property(kDCPropertyPrefix+it));
    while (cached.find()) ranks[cached.group(1).to_int(),cached.group(2)]=cached.group(3).to_int();
    if (!isValidTop10List(ranks)) clear(ranks);
    return ranks;
}

// Do not sell copies already earmarked by the route, or the stock needed to
// reach the acceptable top-ten milestone. A specific liquidation override is
// explicit; no ranking request is hidden inside a store-heartbeat operation.
int smmMuseumSaleQuantity(item it, int requested) {
    if (requested<=0 || get_property("smm.IR.museum")=="false" || !is_displayable(it) || get_property("smm.IR.museumSell."+it.to_int())=="true") return requested;
    int available=available_amount(it);
    int protected=min(item_amount(it),max(0,get_property("smm.IR.museumHold."+it.to_int()).to_int()));
    int [int,string] ranks=smmMuseumCachedCollection(it);
    if (!isValidTop10List(ranks)) return 0;
    int [int] others;
    foreach rank, name, amount in ranks if (!isMe(name)) others[count(others)]=amount;
    sort others by value;
    int acceptable=count(others)>=10 ? others[count(others)-10]+1 : 1;
    protected=max(protected,max(0,acceptable-display_amount(it)));
    return min(requested,max(0,available-protected));
}

// stockAmount is the target stock amount, a zero stockAmount means stock all of theItem
// saveAmount is the amount of items in all inventory locations (including the display case) to save
boolean stockItem(int minPrice, int limit, int stockAmount, int saveAmount, item theItem) {
	int lowestPrice = realMallPrice(theItem);
	int price = max(minPrice, lowestPrice - 11);

	int stockedAmount = shop_amount(theItem);
	int availableAmount = available_amount(theItem) + stockedAmount;
	int targetStockAmount = max(min(stockAmount, availableAmount - saveAmount), 0);
	int delta = targetStockAmount - stockedAmount;
	if (delta > 0 && delta > availableAmount - saveAmount) {
		print("don't have enough " + theItem + " to stock " + delta + " more -- inventory amount: " + item_amount(theItem) + ", save amount: " + saveAmount, "red");
		return false;
	}

	print("stocking " + theItem + "@" + price + "(min price: " + minPrice + ") limit: " + limit
		+ ", target amt: " + stockAmount + ", save amt: " + saveAmount + ", actual target stock amt: " + targetStockAmount
		+ " -- lowest mkt price: " + lowestPrice + ", stocked amt: " + stockedAmount
		+ ", avail amt: " + availableAmount + ", delta: " + delta, "green");

	if (stockedAmount > 0 && price != shop_price(theItem) || limit != shop_limit(theItem)) {
		reprice_shop(price, limit, theItem);
	}

    if (delta>0) delta=smmMuseumSaleQuantity(theItem,delta);

	if (delta < 0) {
		print("removing " + (-delta) + " of " + theItem + "@" + price, "blue");
		return take_shop(-delta, theItem);
	}

	if (delta > 0) {
		print("adding " + delta + " of " + theItem + "@" + price, "blue");
		if (!retrieve_item(delta, theItem))
			abort("could not retrieve " + delta + " of " + theItem + " for store stocking");
		return put_shop(price, limit, delta, theItem);
	}

	return true; // delta == 0
}


// stockAmount is the target stock amount, a zero stockAmount means stock all of theItem
// a negative stockAmount means stock all of theItem except abs(stockAmount)
boolean stockItem(int minPrice, int limit, int stockAmount, item theItem) {
	int lowestPrice = realMallPrice(theItem);
	int price = max(minPrice, lowestPrice - 11);

	int stockedAmount = shop_amount(theItem);
	int delta = stockAmount - stockedAmount;
	if (stockAmount < 0) {
		delta = available_amount(theItem) + stockAmount;
	}
	if (delta > available_amount(theItem)) {
		print("don't have enough " + theItem + " to stock " + delta + " more -- inventory amount: " + item_amount(theItem), "red");
		return false;
	}

	print("stocking " + theItem + "@" + price + "(min price given: " + minPrice + ") limit " + limit + ", target amount: " + stockAmount + " -- lowest price on market: " + lowestPrice + ", stocked amount: " + stockedAmount + ", delta: " + delta, "green");

	if (price != shop_price(theItem) || limit != shop_limit(theItem)) {
		reprice_shop(price, limit, theItem);
	}

    if (delta>0) delta=smmMuseumSaleQuantity(theItem,delta);

	if (delta < 0) {
		print("removing " + (-delta) + " of " + theItem + "@" + price, "blue");
		return take_shop(-delta, theItem);
	}

	if (delta > 0) {
		print("adding " + delta + " of " + theItem + "@" + price, "blue");
		if (!retrieve_item(delta, theItem))
			abort("could not retrieve " + delta + " of " + theItem + " for store stocking");
		return put_shop(price, limit, delta, theItem);
	}

	return true; // delta == 0
}

// uses stockItem to stock the item with a price set by the higher of the current market price or the given minPrice
boolean undercutItemWithMin(int minPrice, int limit, int stockAmount, item theItem) {
	return stockItem(undercutPriceWithMin(theItem, minPrice), limit, stockAmount, theItem);
}

boolean stockItem(int limit, int stockAmount, item theItem) {
	return stockItem(current_price(theItem) - 11, limit, stockAmount, theItem);
}


boolean stockAllItem(item theItem, int minPrice, int limit) {
	return stockItem(minPrice, limit, available_amount(theItem) + shop_amount(theItem), theItem);
}


// stock item with min price equal to cost of a clover plus the turn cost
boolean stockLuckyItem(item theItem, int stockAmount, int limit, int saveAmount) {
	int cloverCost = current_price(theItem);
	return stockItem(cloverCost + kTurnValue, limit, stockAmount, saveAmount, theItem);
}

boolean stockLuckyItem(item theItem, int stockAmount, int limit) {
	int cloverCost = current_price(theItem);
	return stockItem(cloverCost + kTurnValue, limit, stockAmount, theItem);
}



// given an array of amounts indexed by items and prices, will attempt to purchase the amount of each item at the specified price.
void buySpecials(int [item, int] buyMap) {
	int startingMeat = my_meat();
	int [item] receipt;

	batch_open();
	foreach buyItem, price, amount in buyMap {
		int itemsBought;
		print("buying " + amount + "x " + buyItem + "@" + price);
		if (!inRonin())
			itemsBought = buy(amount, buyItem, price);
		else
			itemsBought = buy_using_storage(amount, buyItem, price);

		if (itemsBought > 0)
			receipt[buyItem] = itemsBought;
	}
	boolean success = batch_close();
	if (!success) abort("buy batch wasn't successful!");

	print("buySpecials receipt:");
	printReceipt(receipt);
	print("actual meat spent: " + (startingMeat - my_meat()), "blue");
}



// ensures we have the mats to craft craftable, buying them if we don't have them
boolean ensure_have_mats(item craftable, int needed) {
	assert(isCraftable(craftable), "ensure_have_mats: " + craftable + " is not craftable");

	foreach mat, amt in get_ingredients(craftable) {
		int avail = available_amount(mat);
		int matPrice = current_historical_price(mat);
		int required = amt * needed; // each craft takes amt of this ingredient
		if (avail < required) {
			if (matPrice > 0) {
				print("buying mat: " + mat + " @ " + matPrice, "red");
				// fullAcquire takes the total wanted on hand and returns how many of that total we now hold
				if (fullAcquire(mat, required) < required)
					return false;
			} else
				return false;
		}
	}

	return true;
}

boolean ensure_have_mats(item craftable) {
	return ensure_have_mats(craftable, 1);
}



// returns the possible profit from buying materials and selling the result (or vice versa with untinker??? unimplemented)
// profit is based on the crafting cost and EITHER the current market value, OR the current price in our shop, whichever is lower
// returns 0 if any mat is both unbuyable and uncraftable
int arbitrage(item arbIt, boolean shouldPrint) {
	assert(isCraftable(arbIt), "arbitrage: " + arbIt + " is not craftable");
	int buyPrice = current_price(arbIt);
	int myPrice = shop_price(arbIt);
	int sellPrice = myPrice > 0 ? min(buyPrice, myPrice) : buyPrice;
	int acquireCost = acquireCost(arbIt, shouldPrint);

	int [item] ingredients = get_ingredients(arbIt);
	int amtMeatPaste = count(ingredients) - 1;

	if (acquireCost == 0) {
		cprint(shouldPrint, "crafting " + arbIt + ": at least one ingredient cannot be bought or crafted from bought materials.");
		return 0;
	}

	int profit = sellPrice - acquireCost;
	cprint(shouldPrint, "TOTAL of " + count(ingredients) + " ingredients @ " + acquireCost + " meat (estimated)");
	cprint(shouldPrint, "potential profit on " + arbIt + ": " + profit);
	return profit;
}


int arbitrage(item arbIt) {
	return arbitrage(arbIt, true);
}


// recursive arbitrage, returns the profit on the top-level item ONLY
int arrbitrage(item arbIt, boolean shouldPrint) {
	int [item] ingredients = get_ingredients(arbIt);
	if (count(ingredients) > 0) {
		foreach it, amt in ingredients
			if (count(get_ingredients(it)) > 0) {
				arrbitrage(it, shouldPrint);
			}
	}

	cprint(shouldPrint, "");
	int profit = arbitrage(arbIt, shouldPrint);
	return profit;
}

int arrbitrage(item arbIt) {
	return arrbitrage(arbIt, true);
}



// tries to make a profit by buying the ingredients, crafting arbIt, and putting on the market
void doArbitrage(item arbIt, int stockTarget) {
	assert(stockTarget >= 0, "doArbitrage: invalid stockTarget");
	assert(arbIt != $item[none], "doArbitrage: invalid item");

	if (historical_age(arbIt) < gkStoreHeartbeat) {
		print("too soon to reconsider " + arbIt, "green");
		return;
	}

	float kSlop = 1.05;
	float kMinProfitPercent = 0.25;

	int mallPrice = realMallPrice(arbIt);
	int historicalCraftingCost = get_property("smm.ArbitrageCraftingCostFor" + arbIt).to_int();
	int minPrice = max(mallPrice, historicalCraftingCost * (1 + kMinProfitPercent));
	int kMinProfitThreshold = max(minPrice * kMinProfitPercent, 1000);

	int amountToCraft = max(stockTarget - shop_amount(arbIt), 0);
	int profit = arbitrage(arbIt, false);

	int [item] ingredients = get_ingredients(arbIt);
	if (!isCraftable(arbIt)) {
		print("we can't craft " + arbIt + ", no arbitrage opportunities", "orange");
		return;
	}

	print(arbIt + " stock target: " + stockTarget + " current stock: " + shop_amount(arbIt) + " delta: " + amountToCraft + ", expected profit per item: " + profit, "green");

	// SANITY CHECKS
	if (amountToCraft <= 0) {
		print("store is already stocked with " + stockTarget + "X " + arbIt, "blue");
		stockItem(minPrice - 1, 0, stockTarget, 0, arbIt); // undercut price
		return;
	}
	if (profit < kMinProfitThreshold) {
		print("not enough profit to be made on creating " + arbIt, "blue");
		stockItem(minPrice - 1, 0, shop_amount(arbIt), 0, arbIt); // undercut price
		return;
	}
	if (total_meat() < mallPrice * amountToCraft * 30) { // should have a fair cushion of meat before trying to arbitrage
	   print("not enough meat to safely arbitrage " + arbIt, "blue");
	   stockItem(minPrice - 1, 0, shop_amount(arbIt), 0, arbIt); // undercut price
	   return;
	}

	// ACQUIRE
	int acquireCost = acquireCost(arbIt, false);
	int acquired = newAcquire(arbIt, amountToCraft, acquireCost * kSlop);
	if (acquired == 0) {
	   print("was unable to newly acquire " + arbIt + " @ " + acquireCost + " (with a 5% slop)", "blue");
	   stockItem(minPrice - 1, 0, shop_amount(arbIt), 0, arbIt); // undercut price
	   return;
	}
	if (acquireCost > historicalCraftingCost) // it can only ever go UP so we can use it as a backstop for pricing
		set_property("smm.ArbitrageCraftingCostFor" + arbIt, acquireCost);

	// STOCK
	stockTarget -= (amountToCraft - acquired);
	stockItem(minPrice - 11, 0, stockTarget, 0, arbIt);
}


void doArrbitrage(item arbIt, int stockTarget) {
	doArbitrage(arbIt, stockTarget);
	print("");

	foreach it, amt in get_ingredients(arbIt) {
		if (count(get_ingredients(it)) > 0) {
			doArrbitrage(it, stockTarget);
		}
	}
}



// returns creatable items mapped to number of turns to craft
// creatable means we have the mats available or can buy them
// haveMatsOnly true iff we should return only those items we can create that we have mats for
int [item] creatableItems(boolean haveMatsOnly, boolean doPrint) {
	int [item] rval;
	int i;
	foreach it in $items[] {
		if (count(get_ingredients(it)) > 0 && (!haveMatsOnly || craftable_amount(it, true) > 0)) {
			i++;
			rval[it] = creatable_turns(it, 1, false);
			cprint(doPrint, it + " craftable with " + rval[it] + " turns, profit from crafting: " + historicalArbitrageProfit(it));
		}
	}

	cprint(doPrint, "total creatable items: " + i);

	return rval;
}

int [item] creatableItems(boolean haveMatsOnly) {
	return creatableItems(haveMatsOnly, true);
}


// returns items mapped to profit from crafting that item
// if onlyTurnCostingCrafts is true, only returns those craftables that have a turn cost
int [item] craftingEconomics(boolean onlyTurnCostingCrafts, boolean haveMatsOnly, boolean doPrint) {
	int [item] data = creatableItems(haveMatsOnly, false);
	item [int] sortableData;
	int i;
	int [item] resultData;

	foreach it, craftingTurns in data
		sortableData[i++] = it;

	sort sortableData by historicalArbitrageProfit(value);

	foreach idx, it in sortableData {
		if (!onlyTurnCostingCrafts || data[it] > 0) {
			int profit = historicalArbitrageProfit(it);
			cprint(profit > 0 && doPrint, it + " craftable with " + data[it] + " turns, profit from crafting: " + profit);
			resultData[it] = profit;
		}
	}

	return resultData;
}

int [item] craftingEconomics(boolean onlyTurnCostingCrafts, boolean haveMatsOnly) {
	return craftingEconomics(onlyTurnCostingCrafts, haveMatsOnly, true);
}



// returns 0 if the item gives no MP as recorded in the mafia database
float costPerMPGained(item anItem) {
	int bestPrice = cheapest_price(anItem);
	effect anEffect = effect_modifier(anItem, "Effect");
	if (anEffect != $effect[none]) {
		float mpPerTurn = (numeric_modifier(anEffect, "MP Regen Min") + numeric_modifier(anEffect, "MP Regen Max")) / 2;
		int effectTurns = numeric_modifier(anItem, "Effect Duration");
		return bestPrice/(mpPerTurn * effectTurns);
	} else {
		float avgMP = (anItem.minmp + anItem.maxmp) / 2;
		if (avgMP == 0)
			return 0;
		return bestPrice/avgMP;
	}
}

void printItemRange(int start, int end) {
	for i from start to end {
		item it = i.to_item();
		string questString = it.quest ? " (quest)" : "";
		print("[" + i + "]" + it + questString);
	}
}



// returns the cost of the given item per buff given, including the number used and the opportunity cost of using it
int costPerBuffPercentage(item itemToAnalyze, int buffPercentage, int useAmount, int opportunityCost) {
	return ((historical_price(itemToAnalyze) * useAmount) + opportunityCost) / buffPercentage;
}


// returns the cost of the given item per buffAmount given, including the number used and the opportunity cost of using it
int costPerBuffPerTurn(item itemToAnalyze, int buffAmount, int duration, int opportunityCost) {
	return round((historical_price(itemToAnalyze).to_float() + opportunityCost) / buffAmount / duration);
}


// returns the cost of the given item per buff turn, including the number used and the opportunity cost of using it
int costPerBuffTurn(item itemToAnalyze, int buffLength, int buffTurnsNeeded, int opportunityCost) {
	int useAmount = ceil(buffTurnsNeeded / buffLength);
	return ((historical_price(itemToAnalyze) * useAmount) + opportunityCost) / buffLength;
}



float estimateDropRate(item anItem) {
	float estimate = 5.0;
	print("estimating " + estimate + "% drop rate for " + anItem, "orange");
	return 0.05;
}



// returns the meat value of all items (items only NOT MEAT) dropped by the given mob at the given item drop bonus
// if something is not salable at the mall (determined by the mall price being equal to the min price) use the autosell price in the calculation instead
int monsterItemMeatValue(monster mob, boolean conditionalDrops, float bonusItemDrop) {
	if (mob == $monster[none]) return 0;
	float bonusPP = 1.0 + numeric_modifier("Pickpocket Chance").to_float() / 100.0;
	float bonusItem = (1.0 + (bonusItemDrop/100.0));

	float totalMeatValue = 0;
	foreach index, data in item_drops_array(mob) {
		if (data.type == "c" && !conditionalDrops) continue;

		float dropRate = min(1.0, (data.rate * bonusItem) / 100.0);
		if (data.type == "p") dropRate = min(1.0, (data.rate * bonusPP) / 100.0);
		if (data.type == "0") dropRate = (estimateDropRate(data.drop) * bonusItem); // no info available
		if (data.type == "f") dropRate = min(1.0, data.rate / 100.0); // fixed drop rate

		// ****SPECIAL CASE**** for gnasty/gnarly gnome
		if (mob == $monster[gnarly gnome] || mob == $monster[gnasty gnome])
			dropRate = dropRate / 3.0;

		int mallPrice = historical_price(data.drop);
		if (autosell_price(data.drop) > 0 && mallPrice == autosell_price(data.drop) * 2) { // unsellable item, use the autosell price iff it has a non-zero autosell price
			//print("unsellable item: " + data.drop);
			mallPrice = autosell_price(data.drop);
		}

// 		print(dropRate + " " + data.drop + " @ " + mallPrice); // debugging

		totalMeatValue += mallPrice * dropRate;
	}
	return totalMeatValue;
}

int monsterBaseItemMeatValue(monster mob, boolean conditionalDrops) {
	return monsterItemMeatValue(mob, conditionalDrops, 0);
}

int monsterCurrentItemMeatValue(monster mob, boolean conditionalDrops) {
	return monsterItemMeatValue(mob, conditionalDrops, item_drop_modifier());
}


// returns the meat value dropped by the given mob at the given item and meat drop level
int monsterMeatDropValue(monster mob, float bonusMeatDrop) {
	if (mob == $monster[none]) return 0;
	return meat_drop(mob) * (1 + bonusMeatDrop/100);
}

int monsterBaseMeatDropValue(monster mob) {
	return monsterMeatDropValue(mob, 0.0);
}

int monsterCurrentMeatDropValue(monster mob) {
	return monsterMeatDropValue(mob, meat_drop_modifier());
}



string dropTypeToString(string aTypeChar) {
	switch (aTypeChar) {
		case "": return "normal";
		case "0": return "no info available";
		case "n": return "not pp-able";
		case "c": return "conditional";
		case "p": return "pp-only";
		case "b": return "bounty";
		case "a": return "accordion";
		case "f": return "fixed"; // +item has no effect
	}
	print("unknown drop type: " + aTypeChar);
	return "";
}


float pp_chance(monster mob) {
	float discount = 1.0; // each subsequent pp-able item is less likely due to the fact that we stop after successfully pp'ing
	foreach idx, idr in ppItemDropsArray(mob) {
		if (idr.type != "n" && idr.type != "b") {
			float ppPercent = idr.rate * ((numeric_modifier("Pickpocket Chance") / 100.0) + 1.0) * discount;
			if (idr.type == "f") ppPercent = idr.rate * discount;
			int meatValue = historical_price(idr.drop) * (ppPercent / 100) * discount;
			discount = discount * (1 - (ppPercent / 100.0));
		}
	}

	return 1.0 - discount;
}



// calculates the value of pickpocketing the given monster at the given bonus pickpocket drop
// includes the discount for each subsequent pickpocketable item
int monsterPPMeatValue(monster mob, float bonusPPDrop, boolean doPrint) {
	float rval;
	cprint(doPrint, mob + " pp-able items with pp bonus: " + bonusPPDrop + "%", "blue");

	float discount = 1.0;
	foreach idx, idr in ppItemDropsArray(mob) {
		if (idr.type != "n" && idr.type != "b" && idr.type != "a") {
			float ppPercent = idr.rate * ((bonusPPDrop / 100.0) + 1.0) * discount;
			if (idr.type == "f") ppPercent = idr.rate * discount; // fixed drop rate

			float meatValue = historical_price(idr.drop) * (ppPercent / 100.0);
			rval += meatValue;

			string ppType = dropTypeToString(idr.type);
			cprint(doPrint, idr.drop + ": " + idr.rate + "% drop, discounted pp chance: " + ppPercent + "% - " + ppType + " @ " + historical_price(idr.drop) + ", discount: " + discount + ", value: " + meatValue, idr.type == "p" ? "green" : "");

			discount = discount * (1.0 - (ppPercent / 100.0));
		}
	}

	return rval;
}

int monsterPPMeatValue(monster mob, float bonusPPDrop) {
	return monsterPPMeatValue(mob, bonusPPDrop, true);
}

int monsterPPMeatValue(monster mob) {
	return monsterPPMeatValue(mob, numeric_modifier("Pickpocket Chance"), true);
}



float hugpocketChance(monster mob) {
	return 1.0 - (1.0 - pp_chance(mob)) ** 50.0;
}


// calculates the value of hugpocketing the given monster
int monsterHugpocketMeatValue(monster mob, boolean doPrint) {
	float rval;
	cprint(doPrint, mob + " hugpocket-able items", "blue");

	float discount = 1.0;
	float totalPPables = 0.0;
	float ppPercent;

	// normalize probabilities, first get the sum of all PP probabilities
	float ppAccumulator = 0.0;
	foreach idx, idr in ppItemDropsArray(mob) {
		if (idr.type != "n" && idr.type != "b" && idr.type != "a") {
			ppPercent = idr.rate * discount;
			ppAccumulator += ppPercent;
			discount = discount * (1.0 - (ppPercent / 100.0));
			print("ppPercent: " + ppPercent + ", ppAccumulator: " + ppAccumulator + ", discount: " + discount);
		}
	}

	discount = 1.0;
	foreach idx, idr in ppItemDropsArray(mob) {
		if (idr.type != "n" && idr.type != "b") {
			ppPercent = (idr.rate * discount) / ppAccumulator; // normalized percent chance of dropping (all ppPercent should sum to 100%)
			float meatValue = historical_price(idr.drop) * (ppPercent / 100.0);
			rval += meatValue;

			string ppType = dropTypeToString(idr.type);
			cprint(doPrint, idr.drop + ": " + idr.rate + "% drop, discounted pp chance: " + ppPercent + "% - " + ppType + " @ " + historical_price(idr.drop) + ", discount: " + discount + ", value: " + meatValue, idr.type == "p" ? "green" : "");

			discount = discount * (1.0 - (ppPercent / 100.0));
		}
	}

	float ppRange = 1.0 - ((1.0 - (ppAccumulator / 100.0)) ** 50); // chance that the hugpocket will return anything
	return rval * ppRange;
}

int monsterHugpocketMeatValue(monster mob) {
	return monsterHugpocketMeatValue(mob, true);
}



void locationPPDetails(location aloc) {
	foreach mob, rate in appearance_rates(aloc)
		if (mob != $monster[none]) {
			print("monster: " + mob + " appearing " + rate, "blue");
			monsterPPMeatValue(mob);
		}
}



// returns the meat value dropped by the given mob at the given item and meat drop level
// TODO doesn't consider pp'ing
int monsterTotalMeatValue(monster mob, boolean conditionalDrops, float bonusItemDrop, float bonusMeatDrop) {
// 	float meatDrop = meat_drop(mob) * (1 + bonusMeatDrop/100);
// 	meatDrop += monsterItemMeatValue(mob, bonusItemDrop);
	return monsterItemMeatValue(mob, conditionalDrops, bonusItemDrop) + monsterMeatDropValue(mob, bonusMeatDrop);
}

int monsterBaseTotalMeatValue(monster mob, boolean conditionalDrops) {
	return monsterTotalMeatValue(mob, conditionalDrops, 0.0, 0.0);
}

int monsterCurrentTotalMeatValue(monster mob, boolean conditionalDrops) {
	return monsterTotalMeatValue(mob, conditionalDrops, item_drop_modifier(), meat_drop_modifier());
}



// returns the meat value dropped by the given location at the given item and meat drop level, pro-rated by appearance rate
int locationMeatValue(location aLocation, boolean conditionalDrops, float bonusItemDrop, float bonusMeatDrop) {
	float meatDrop = 0.0;
	foreach mob, rate in appearance_rates(aLocation) {
		if (rate < 0.0)
			rate = 0.0;
		meatDrop += (rate / 100.0) * monsterTotalMeatValue(mob, conditionalDrops, bonusItemDrop, bonusMeatDrop);
	}
	return meatDrop;
}

int locationBaseMeatValue(location aLocation, boolean conditionalDrops) {
	return locationMeatValue(aLocation, conditionalDrops, 0, 0);
}

int locationCurrentMeatValue(location aLocation, boolean conditionalDrops) {
	return locationMeatValue(aLocation, conditionalDrops, item_drop_modifier(), meat_drop_modifier());
}



monster [] monsterEconomics(boolean conditionalDrops, boolean doPrint) {
	monster [int] allmons;
	int idx;
	foreach amon in $monsters[]
		if (!amon.boss && amon.monsterCurrentTotalMeatValue(conditionalDrops) > 0)
			allmons[idx++] = amon;
	sort allmons by -value.monsterCurrentTotalMeatValue(conditionalDrops);
	if (doPrint)
	    foreach i, amon in allmons
			print(amon + " @ " + amon.monsterCurrentTotalMeatValue(conditionalDrops));
	return allmons;
}

monster [] monsterEconomics(boolean conditionalDrops) {
	return monsterEconomics(conditionalDrops, true);
}


monster [] copyableMonsterEconomics(boolean conditionalDrops, boolean doPrint) {
	monster [int] allmons;
	int idx;
	foreach amon in $monsters[]
		if (!amon.boss && amon.monsterCurrentTotalMeatValue(conditionalDrops) > 0 && isCopyable(amon))
			allmons[idx++] = amon;
	sort allmons by -value.monsterCurrentTotalMeatValue(conditionalDrops);
	if (doPrint)
	    foreach i, amon in allmons
			print(amon + " @ " + amon.monsterCurrentTotalMeatValue(conditionalDrops));
	return allmons;
}

monster [] copyableMonsterEconomics(boolean conditionalDrops) {
	return copyableMonsterEconomics(conditionalDrops, true);
}



// returns the given locations sorted by each location's total meat value
location [] locationEconomics(boolean [location] locations, boolean conditionalDrops, float itemBonus, float meatBonus, boolean doPrint) {
	location [int] alllocs;
	int idx;
	foreach aloc in locations
		if (isUnlocked(aloc) && aloc.locationMeatValue(conditionalDrops, itemBonus, meatBonus) > 0)
			alllocs[idx++] = aloc;
	sort alllocs by -value.locationMeatValue(conditionalDrops, itemBonus, meatBonus);
	if (doPrint)
	    foreach i, aloc in alllocs
			print(aloc + " @ " + aloc.locationMeatValue(conditionalDrops, itemBonus, meatBonus));
	return alllocs;
}

location [] locationBaseEconomics(boolean [location] locations, boolean conditionalDrops, boolean doPrint) {
	return locationEconomics(locations, conditionalDrops, 0, 0, doPrint);
}

location [] locationBaseEconomics(boolean conditionalDrops, boolean doPrint) {
	return locationBaseEconomics($locations[], conditionalDrops, doPrint);
}

location [] locationBaseEconomics(boolean conditionalDrops) {
	return locationBaseEconomics(conditionalDrops, true);
}

location [] locationCurrentEconomics(boolean [location] locations, boolean conditionalDrops, boolean doPrint) {
	return locationEconomics(locations, conditionalDrops, item_drop_modifier(), meat_drop_modifier(), doPrint);
}

location [] locationCurrentEconomics(boolean conditionalDrops, boolean doPrint) {
	return locationCurrentEconomics($locations[], conditionalDrops, doPrint);
}

location [] locationCurrentEconomics(boolean conditionalDrops) {
	return locationCurrentEconomics(conditionalDrops, true);
}



location [] shadowEconomics(boolean shouldPrint) {
	boolean [location] shadowLocs = {
		$location[Shadow Rift (Desert Beach)] : true,
		$location[Shadow Rift (Forest Village)] : true,
		$location[Shadow Rift (Mt. McLargeHuge)] : true,
		$location[Shadow Rift (Somewhere Over the Beanstalk)] : true,
		$location[Shadow Rift (Spookyraven Manor Third Floor)] : true,
		$location[Shadow Rift (The 8-Bit Realm)] : true,
		$location[Shadow Rift (The Ancient Buried Pyramid)] : true,
		$location[Shadow Rift (The Castle in the Clouds in the Sky)] : true,
		$location[Shadow Rift (The Distant Woods)] : true,
		$location[Shadow Rift (The Hidden City)] : true,
		$location[Shadow Rift (The Misspelled Cemetary)] : true,
		$location[Shadow Rift (The Nearby Plains)] : true,
		$location[Shadow Rift (The Right Side of the Tracks)] : true,
	};
	return locationEconomics(shadowLocs, false, item_drop_modifier() / 5, meat_drop_modifier() / 5, shouldPrint);
}

location [] shadowEconomics() {
	return shadowEconomics(true);
}



int smutOrcPervertProgress() {
	//return $location[The Smut Orc Logging Camp].turns_spent % 20;
	return to_int(get_property(kSmutOrcPervertProgressKey));
}

void setSmutOrcPervertProgress(int progress) {
	set_property(kSmutOrcPervertProgressKey, progress);
}


int sentientATMProgress() {
	return to_int(get_property(kSentientATMProgressKey));
}

void setSentientATMProgress(int progress) {
	set_property(kSentientATMProgressKey, progress);
}


int agoraProgress() {
	return to_int(get_property(kAgoraProgressKey));
}

void setAgoraProgress(int progress) {
	set_property(kAgoraProgressKey, progress);
}


void normalizeSmutOrcPervertProgress() {
	print("smut orc logging camp turns spent: " + $location[The Smut Orc Logging Camp].turns_spent);
}



int turnsSinceSausageGoblin() {
	return total_turns_played() - to_int(get_property("_lastSausageMonsterTurn"));
}


int maxTurnsToNextSausageGoblin() {
	int sausageFights = to_int(get_property("_sausageFights"));
// 	return 1 + (3 * numberOfSausageGoblins) + (max(0, numberOfSausageGoblins - 5) ^ 3);
	return 5 + sausageFights * 3 + max(0, sausageFights - 5) ** 3 - 1;
}


float chanceOfSausageGoblinNextTurn() {
	return (turnsSinceSausageGoblin() + 1.0) / (maxTurnsToNextSausageGoblin() + 1.0);
}


// aborts if we encounter a sausage goblin
boolean wantToGrindSausageGoblin() {
	if (!inRonin() && kCheckForLastSausageGoblinKey.get_property().to_boolean()) {
// 		print("turns since last sausage goblin: " + turnsSinceSausageGoblin() + ", chance of encounter: " + chanceOfSausageGoblinNextTurn() + "%");
		if (last_monster() == $monster[sausage goblin] && get_property("_backUpUses").to_int() < 11
			&& get_property("_sausageFights").to_float() >= (kSausagesToGet * (1.0/2.0))) // when we grind, we can encounter non-combats, so we want to wait until we've burned our largest +item buffs before grinding sausage goblins since they don't require a lot of +item
			return true;
	}
	return false;
}


// aborts if we encounter a sausage goblin
void checkForLastSausageGoblin() {
	if (!inRonin() && get_property(kCheckForLastSausageGoblinKey).to_boolean()) {
// 		print("turns since last sausage goblin: " + turnsSinceSausageGoblin() + ", chance of encounter: " + chanceOfSausageGoblinNextTurn() + "%");
		if (last_monster() == $monster[sausage goblin] && get_property("_backUpUses").to_int() < 11
			&& get_property("_sausageFights").to_float() >= (kSausagesToGet * (1.0/2.0)))
			abort("sausage goblin!");
	}
}



boolean isUnderwaterLocation(location aLocation) {
	switch (aLocation) {
		case $location[The Briny Deeps]:
		case $location[The Brinier Deepers]:
		case $location[The Briniest Deepests]:
		case $location[An Octopus's Garden]:
		case $location[The Wreck of the Edgar Fitzsimmons]:
		case $location[The Mer-Kin Outpost]:
		case $location[Anemone Mine]:
		case $location[The Marinara Trench]:
		case $location[The Dive Bar]:
		case $location[Madness Reef]:
		case $location[The Coral Corral]:
		case $location[The Skate Park]:
		case $location[The Caliginous Abyss]:
		case $location[Mer-kin Elementary School]:
		case $location[Mer-kin Library]:
		case $location[Mer-kin Gymnasium]:
		case $location[Mer-kin Colosseum]:
			return true;
			break;
	}

	return false;
}

int breatheWaterEffectTurns() {
	int breathWaterFor;
	breathWaterFor = max(breathWaterFor, have_effect($effect[Really Deep Breath]));
	breathWaterFor = max(breathWaterFor, have_effect($effect[Oxygenated Blood]));
	breathWaterFor = max(breathWaterFor, have_effect($effect[Pneumatic]));
	breathWaterFor = max(breathWaterFor, have_effect($effect[Driving Waterproofly]));
	breathWaterFor = max(breathWaterFor, have_effect($effect[Pumped Stomach]));
	breathWaterFor = max(breathWaterFor, have_effect($effect[Mer-kinny Flavor]));
	breathWaterFor = max(breathWaterFor, have_effect($effect[Hyperoxygenated Blood]));

	return breathWaterFor;
}

int breatheWaterTurns() {
    if (equipped_amount($item[crappy Mer-kin mask]) > 0
        || equipped_amount($item[Mer-kin gladiator mask]) > 0
        || equipped_amount($item[Mer-kin scholar mask]) > 0
        || equipped_amount($item[aerated diving helmet]) > 0
        || equipped_amount($item[old SCUBA tank]) > 0
        || equipped_amount($item[oxygenated eggnog helmet]) > 0
        || equipped_amount($item[The Crown of Ed the Undying]) > 0
        || equipped_amount($item[Elf Guard SCUBA tank]) > 0) {
        return kMaxInt;
    }
	return breatheWaterEffectTurns();
}

boolean canBreatheWater() {
	return breatheWaterTurns() > 0;
}


boolean canMyFamiliarBreatheWater() {
	switch (my_familiar()) {
		case $familiar[Barrrnacle]:
		case $familiar[Emo Squid]:
		case $familiar[Cuddlefish]:
		case $familiar[Imitation Crab]:
		case $familiar[Magic Dragonfish]:
		case $familiar[Midget Clownfish]:
		case $familiar[Rock Lobster]:
		case $familiar[Urchin Urchin]:
		case $familiar[Grouper Groupie]:
		case $familiar[Squamous Gibberer]:
		case $familiar[Dancing Frog]:
		case $familiar[Reagnimated Gnome]:
		case $familiar[Adorable Space Buddy]:
		case $familiar[Space Jellyfish]:
		case $familiar[Robortender]:
		case $familiar[God Lobster]:
		case $familiar[Red-nosed Snapper]:
			return true;
	}

	return breatheWaterEffectTurns() > 0;
}



// hippy camp and orcish frat house locations are weird
location mysterious_island_camp(string camp) {
	assert(camp == "hippy" || camp == "frat", "incorrect param");
	location rval;

	string warProgress = get_property("warProgress");
	string sideDefeated = get_property("sideDefeated");

	if (warProgress == "unstarted" || warProgress == "started") {
		if (camp == "hippy")
			return $location[Hippy Camp];
		else
			return $location[Frat House];
	} else { // warProgress == "finished"
		if (camp == "hippy" && (sideDefeated == "hippies" || sideDefeated == "both"))
			return $location[The Hippy Camp (Bombed Back to the Stone Age)];
		else if (camp == "hippy")
			return $location[Hippy Camp];
		else if (camp == "frat" && (sideDefeated == "fratboys" || sideDefeated == "both"))
			return $location[The Orcish Frat House (Bombed Back to the Stone Age)];
		else // frat, not defeated
			return $location[Frat House];
	}
	return rval;
}



// TODO
void getFreeGoofballs() {
	buffer goofballVendorString = visit_url("/tavern.php?place=susguy", true, false);
	matcher freeGoofballMatcher = create_matcher("(for free!)", goofballVendorString);
	if (find(freeGoofballMatcher)) {
		// get those free goofballs
	}
}



int fernswarthy_level() {
	string raw_fernswarthy_string = visit_url("/basement.php", true, false);
	matcher aMatcher = create_matcher("Fernswarthy's Basement, Level ([0-9]+)", raw_fernswarthy_string);
	if (!find(aMatcher)) return 0;
	return to_int(group(aMatcher, 1));
}



void getDefaultPastaThrall() {
	use_skill($skill[bind spice ghost]);
}



// returns true if we detect that we have restarted mafia after running breakfast
// assumes Advanced Cocktail Crafting will be cast during breakfast
boolean haveRestartedMafia() {
	int cocktailCraftingDrops = my_session_items($item[coconut shell]) + my_session_items($item[little paper umbrella]) + my_session_items($item[magical ice cubes]);
	return cocktailCraftingDrops < 5 && get_property("breakfastCompleted").to_boolean();
}



int aerogelAttacheCaseItemDrops() {
	int dropsFromCocktailCrafting = (get_property("cocktailSummons").to_int() > 0 || haveRestartedMafia()) ? 5 : 0;
	return my_session_items($item[coconut shell]) + my_session_items($item[little paper umbrella]) + my_session_items($item[magical ice cubes]) - dropsFromCocktailCrafting;
}



item [] inventoryArray() {
	item [int] invItems;

	int i = 0;
	foreach it in get_inventory() {
		invItems[i] = it;
		i++;
	}
	return invItems;
}



void pull_high_quantity_items() {
	item [int] storage_items;

	int i = 0;
	foreach it in get_storage() {
		storage_items[i] = it;
		i++;
	}

	sort storage_items by -storage_amount(value);

	batch_open();
	foreach x, it in storage_items {
		int stored = storage_amount(it);
		if (stored > 2 * my_ascensions()) {
			print("pulling " + stored + " of " + it);
			take_storage(stored, it);
		}
	}
	boolean sexy = batch_close();
	print("pull batch successful: " + sexy);
}



// can the item be ground by the kramco sausage grinder
boolean is_grindable(item grind_test) {
	return item_amount(grind_test) > 2 * my_ascensions() && item_type(grind_test) != "food" && item_type(grind_test) != "booze";
}

void list_grindable_items() {
	int expensiveValue = 200;
	item [int] inv_items = inventoryArray();
	sort inv_items by -item_amount(value);

	foreach x, it in inv_items
		if (is_grindable(it) && get_price(it, 3) < expensiveValue && is_pvpable(it)) {
			print(item_amount(it) + " " + it);
		}
}


boolean setBoombox(string boom) {
	string [string] kBoomboxCommandToSongMap = {"giger": "", "spooky": "", "food": "Food Vibrations", "alive": "", "dr": "", "fists": "", "damage": "", "meat": ""};

	if (get_property("_boomBoxSongsLeft").to_int() > 0 && !get_property("boomBoxSong").contains_text(kBoomboxCommandToSongMap[boom]))
		return cli_execute("boombox " + boom);
	else
		return get_property("boomBoxSong").contains_text(boom);
}

void setDefaultBoombox() {
	setBoombox("food");
}



// TODO
boolean saveState() {
	return true;
}

boolean restoreState() {
	return true;
}



// set us up in the default state: goals, outfit, mood, boombox
void setDefaultKoLState() {
// 	wearDefaultOutfit(); // this really slows things down when doing the same thing over and over from the CLI
	clearGoals();
	max_mcd();
	setDefaultMood();
	setDefaultBoombox();
}



void checkIfRunningOut(item anItem, int runningOutThreshold) {
	int availableAmount = available_amount(anItem);
	if (availableAmount < runningOutThreshold)
		print("warning: running out of " + anItem + ", " + availableAmount + " available", "orange");
}



boolean useMoMifNeeded() {
	checkIfRunningOut($item[milk of magnesium], 30);
	fullAcquire($item[milk of magnesium]); // TODO probably only need one of the running-out-check or the fullAcquire

	if (!to_boolean(get_property("_milkOfMagnesiumUsed")))
		return use(1, $item[milk of magnesium]);
	return true;
}



boolean isMonday() {
	return itemDescription($item[Tuesday's ruby]).contains_text("+5% Muscle");
}



// ensures the given song buff can be cast right now
// returns true if it could make the room (or room already exists)
boolean ensureSongRoom(skill [] songsToPlay) {
	int roomNeeded = 0;
	skill [int] songsThatNeedSpace;
	foreach idx, song in songsToPlay {
		if (have_effect(to_effect(song)) == 0) {
			songsThatNeedSpace[roomNeeded] = song;
			roomNeeded++;
		}
	}
	if (roomNeeded == 0 || accordionSongsActive() + roomNeeded <= maxAccordionSongs())
		return true;

	skill [int] uneffectSongOrder = {
		1: $skill[The Ode to Booze],
		2: $skill[The Power Ballad of the Arrowsmith],
		3: $skill[The Magical Mojomuscular Melody],
		4: $skill[The Moxious Madrigal],
		5: $skill[Stevedave's Shanty of Superiority],
		6: $skill[The Psalm of Pointiness],
		7: $skill[Brawnee's Anthem of Absorption],
		8: $skill[Prelude of Precision],
		9: $skill[Cletus's Canticle of Celerity],
		10: $skill[Jackasses' Symphony of Destruction],
		11: $skill[Dirge of Dreadfulness],
		12: $skill[Benetton's Medley of Diversity],
		13: $skill[Elron's Explosive Etude],
		14: $skill[Aloysius' Antiphon of Aptitude],
		15: $skill[Ur-Kel's Aria of Annoyance],
		16: $skill[The Sonata of Sneakiness],
		17: $skill[Carlweather's Cantata of Confrontation],
		18: $skill[Chorale of Companionship],
		19: $skill[The Polka of Plenty],
		20: $skill[Fat Leon's Phat Loot Lyric],
		// never uneffect these
// 		21: $skill[Inigo's Incantation of Inspiration],
// 		22: $skill[Donho's Bubbly Ballad],
// 		23: $skill[The Ballad of Richie Thingfinder],
	};

	foreach idx, songToPlay in songsThatNeedSpace {
		print("uneffecting a song buff to make room for " + songToPlay, "green");

		// first, go through and uneffect in order a buff that isn't part of our mood
		foreach idx, aSong in uneffectSongOrder {
			if (roomNeeded == 0)
				return true;
			if (have_effect(to_effect(aSong)) > 0 && !inMood(aSong) && !arrayContains(songsToPlay, aSong)) {
				if (uneffect(aSong))
					roomNeeded--;
				else
					abort("failed uneffecting non-mood skill " + aSong + " to make room for " + songToPlay);
			}
		}

		// if we got here, we don't have a song that isn't in the current mood
		// go through in order and uneffect the first song we find
		foreach idx, aSong in uneffectSongOrder {
			if (roomNeeded == 0)
				return true;
			if (have_effect(to_effect(aSong)) > 0 && !arrayContains(songsToPlay, aSong)) {
				if (uneffect(aSong))
					roomNeeded--;
				else
					abort("failed uneffecting mood skill " + aSong + " to make room for " + songToPlay);
			}
		}
	}

	return roomNeeded == 0;
}

boolean ensureSongRoom(skill songToPlay) {
	skill [] songsToPlay = {songToPlay};
	return ensureSongRoom(songsToPlay);
}

boolean ensureSongRoom()  {
	return ensureSongRoom($skill[none]);
}


// ensure we can cast buff by uneffecting anything that would block it
boolean uneffectIfNeeded(skill buff) {
	if (isATSong(buff))
		return ensureSongRoom(buff);

	return true;
}


void shakeOffNonMoodSongs() {
	int [skill] activeSongs = activeSongs();
	int [skill] moodSongs = moodSongs();

	foreach aSkill in activeSongs {
		print("testing:  " + aSkill);
		if (!(moodSongs contains aSkill))
			uneffect(aSkill.to_effect());
	}
}



boolean use_skill_if_needed(int minimumNumberOfTurns, skill aSkill) {
	assert(aSkill != $skill[none], "use_skill_if_needed: no skill");

	boolean executed = true;
	effect theEffect = to_effect(aSkill);
	while (have_effect(theEffect) < minimumNumberOfTurns && executed) {
		int effectTurns = have_effect(theEffect);
		executed = use_skill(1, aSkill); // this is not returning false under all circumstances where the skill fails
		if (have_effect(theEffect) == effectTurns) // no extra turns_per_cast
			break;
	}

	if (have_effect(theEffect) < minimumNumberOfTurns)
		abort("unable to get enough " + theEffect);

	return executed;
}

boolean use_skill_if_needed(skill aSkill) {
	return use_skill_if_needed(1, aSkill);
}



// ensure we have enough buff space to play songToPlay and then insure we have minimumNumberOfTurns of the associated effect
// will try to avoid uneffecting buffs in the current mood
boolean songBuffIfNeededWithUneffect(skill songToPlay, int minimumNumberOfTurns) {
	uneffectIfNeeded(songToPlay);
	return use_skill_if_needed(minimumNumberOfTurns, songToPlay);
}


boolean useOdeToBoozeIfNeeded(int minTurns) {
	boolean success = songBuffIfNeededWithUneffect($skill[The Ode To Booze], minTurns);
	assert(!success || have_effect($effect[Ode to Booze]) >= minTurns, "didn't get enough ode to booze");
	return success;
}



// will Ode To Booze or milk of magnesium as necessary
// uses "drink", so will give a user-confirm warning when overdrinking
string cliStringToConsume(int quantity, item itemToConsume) {
	string rval;
	if (itemToConsume.fullness > 0) {
		if (!to_boolean(get_property("_milkOfMagnesiumUsed")))
			rval = "use milk of magnesium; ";
		return rval + "eat " + quantity + " " + itemToConsume;

	} else if (itemToConsume.inebriety > 0) {
		return "useOdeToBoozeIfNeeded (" + (itemToConsume.inebriety * quantity) + "); drink " + quantity + " " + itemToConsume;

	} else if (itemToConsume.spleen > 0)
		return "chew " + quantity + " " + itemToConsume;

	else
		return "use " + quantity + " " + itemToConsume;
}



// returns true iff the fullness, inebriety, and spleen of checkMe are less than the available fullness, inebriety, and spleen limits
boolean haveRoom(item checkMe) {
	if (checkMe.fullness > fullnessRoom())
		return false;
	if (checkMe.inebriety > inebrietyRoom())
		return false;
    if (checkMe.spleen > spleenRoom())
        return false;
	return true;
}


// consume (eat/drink/chew/use) any item.
// will Ode To Booze or milk of magnesium as necessary
// uses "drink", so will give a user-confirm warning when overdrinking
boolean consume(int quantity, item itemToConsume) {
	print("consuming: " + quantity + " X " + itemToConsume, "green");

	if (itemToConsume.fullness > 0) {
		useMoMifNeeded();
		return eat(quantity, itemToConsume);

	} else if (itemToConsume.inebriety > 0) {
		useOdeToBoozeIfNeeded(itemToConsume.inebriety * quantity);
		return drink(quantity, itemToConsume);

	} else if (itemToConsume.spleen > 0)
		return chew(quantity, itemToConsume);

	else
		return use(quantity, itemToConsume);
}



// consume any item, one at a time, to achieve minimumNumberOfTurns of anEffect
// assumes itemToConsume actually gives anEffect
boolean consumeIfNeeded(item itemToConsume, effect anEffect, int minimumNumberOfTurns) {
	boolean executed = true;
	while (have_effect(anEffect) < minimumNumberOfTurns && executed) {
		int beforeEffect = have_effect(anEffect);
		executed = consume(1, itemToConsume);
		int afterEffect = have_effect(anEffect);
		if (beforeEffect == afterEffect) {
			print("consumeIfNeeded: not getting " + anEffect + " from " + itemToConsume + "!", "red");
			executed = false;
		}
	}
	return executed;
}

// consume any item, one at a time, to achieve minimumNumberOfTurns of its effect
boolean consumeIfNeeded(item itemToConsume, int minimumNumberOfTurns) {
    boolean executed = true;
    effect anEffect = effect_modifier(itemToConsume, "Effect");
	print("looks like effect of " + itemToConsume + " is " + anEffect);
    while (have_effect(anEffect) < minimumNumberOfTurns && executed) {
        int beforeEffect = have_effect(anEffect);
        executed = consume(1, itemToConsume);
        int afterEffect = have_effect(anEffect);
        if (beforeEffect == afterEffect) {
            print("consumeIfNeeded: not getting " + anEffect + " from " + itemToConsume + "!", "red");
            executed = false;
        }
    }
    return executed;
}

boolean use_if_needed(item itemToUse, effect anEffect, int minimumNumberOfTurns) {
	return consumeIfNeeded(itemToUse, anEffect, minimumNumberOfTurns);
}


boolean consumeIfNeededWithUneffect(item itemToConsume, effect anEffect, int minimumNumberOfTurns) {
	if (to_skill(anEffect) != $skill[none] && !uneffectIfNeeded(to_skill(anEffect)))
		abort("consumeIfNeededWithUneffect");
	return consumeIfNeeded(itemToConsume, anEffect, minimumNumberOfTurns);
}


// consume each item in the array, one at a time, to achieve minimumNumberOfTurns of its effect
// returns true if all items' effects were achieved to minimumNumberOfTurns, false otherwise.
boolean consumeIfNeeded(item[] itemsToConsume, int minimumNumberOfTurns) {
    boolean allExecuted = true;
    foreach idx, itemToConsume in itemsToConsume {
        boolean executed = consumeIfNeeded(itemToConsume, minimumNumberOfTurns);
        if (!executed) {
            allExecuted = false;
        }
    }
    return allExecuted;
}



// executes the given string in the cli until anEffect has minimumNumberOfTurns
boolean cli_execute_if_needed(string executeString, effect anEffect, int minimumNumberOfTurns) { // #cliExecuteIfNeeded #cli_execute_if_required
	if (to_skill(anEffect) != $skill[none] && !uneffectIfNeeded(to_skill(anEffect)))
		abort("cli_execute_if_needed");

	boolean executed = true;
	int turnsOfEffect = have_effect(anEffect);
	while (turnsOfEffect < minimumNumberOfTurns && executed) {
		executed = cli_execute(executeString);
		int newTurnsOfEffect = have_effect(anEffect);
		if (turnsOfEffect == newTurnsOfEffect)
			return false;
		else
			turnsOfEffect = newTurnsOfEffect;
	}
	return executed;
}

boolean cli_execute_if_needed(string executeString, effect anEffect) {
	return cli_execute_if_needed(executeString, anEffect, 1);
}



// ensures the given buff's effect has minimumNumberOfTurns
// will uneffect anything that interfere's with casting buff
boolean buffIfNeededWithUneffect(skill buff, int minimumNumberOfTurns) {
	return songBuffIfNeededWithUneffect(buff, minimumNumberOfTurns);
}

boolean buffIfNeededWithUneffect(skill buff) {
	return songBuffIfNeededWithUneffect(buff, 1);
}



// gets anEffect from either using anItem or from casting aSkill
// will always use aSkill if it is non-none
boolean getEffectIfNeededWithUneffect(effect anEffect, item anItem, skill aSkill, int minimumNumberOfTurns) {
	if (aSkill != $skill[none])
		return buffIfNeededWithUneffect(aSkill, minimumNumberOfTurns); // anEffect is only needed if we're using an item
	else
		return consumeIfNeededWithUneffect(anItem, anEffect, minimumNumberOfTurns);
}



void buffColdRes(AnalyzeRecord [item] itemsToAnalyze, int buffTurnsNeeded, int maxMeatcostPerBuffTurn) {
	item [int] sortArray;
	int ctr = 0;
	foreach it in itemsToAnalyze {
		sortArray[ctr] = it;
		ctr += 1;
	}
	sort sortArray by costPerBuffPerTurn(value, itemsToAnalyze[value].buffAmount, itemsToAnalyze[value].duration, itemsToAnalyze[value].opportunityCost);

	// CHOOSE BUFFS TO USE
	int totalBuffs;
	int totalCostPerTurn;
	string htmlOutput = "<table><th>Item</th><th>current turns</th><th>buff amount</th><th>duration</th><th>effect</th><th>cost per buff turn</th><th></tr>\n";
	for idx from 0 to count(sortArray) - 1 {
		item anItem = sortArray[idx];
		int costPerBuffTurn = costPerBuffPerTurn(anItem, itemsToAnalyze[anItem].buffAmount, itemsToAnalyze[anItem].duration, itemsToAnalyze[anItem].opportunityCost);
		string textColour = "blue";
		if (costPerBuffTurn <= maxMeatcostPerBuffTurn) {
			textColour = "green";
			totalBuffs += itemsToAnalyze[anItem].buffAmount;
			totalCostPerTurn += costPerBuffTurn * itemsToAnalyze[anItem].buffAmount;
		}

// 		print(anItem + " (current turns: " + have_effect(itemsToAnalyze[anItem].theEffect) + ", buffs for: " + itemsToAnalyze[anItem].buffAmount + (itemsToAnalyze[anItem].buffIsPercentBased ? "%" : "")
// 			+ ", " + itemsToAnalyze[anItem].duration + " turns, effect: " + itemsToAnalyze[anItem].theEffect + ") @ "
// 			+ costPerBuffTurn + " / buff" + (itemsToAnalyze[anItem].buffIsPercentBased ? " percentage" : "")
// 			+ " / duration", textColour);
		htmlOutput += "<tr><td>" + anItem + "</td><td>" + have_effect(itemsToAnalyze[anItem].theEffect)
			+ "</td><td>" + itemsToAnalyze[anItem].buffAmount + (itemsToAnalyze[anItem].buffIsPercentBased ? "%" : "")
			+ "</td><td>" + itemsToAnalyze[anItem].duration + "</td><td>" + itemsToAnalyze[anItem].theEffect
			+ "</td><td>" + costPerBuffTurn + "</td></tr>\n";
	}

	htmlOutput += "</table>\n";
	print_html(htmlOutput);

	if (totalBuffs == 0)
		abort("no buffs were chosen, try raising maxMeatcostPerBuffTurn");
	print("current Cold Resistance: " + numeric_modifier("Cold Resistance"), "blue");
	print("total cost: " + totalCostPerTurn + "/turn, total buff: " + totalBuffs + ", total cost/buff/turn: " + (totalCostPerTurn / totalBuffs), "blue");

	// BUFF UP
	if (!user_confirm("Proceed under the following circumstances?\nTotal buff cost: " + totalCostPerTurn + ", total buff: "
		+ totalBuffs + "%, total cost per buff percent: " + (totalCostPerTurn / totalBuffs)
		+ " meat\nTurn cost: " + (kTurnValue * 30) + " -- total cost per buff: "
		+ totalCostPerTurn + "\n", 60000, false))
		abort();

	// ACQUIRE AND CONSUME ITEMS
	foreach idx, anItem in sortArray {
		int costPerBuffPerTurn = costPerBuffPerTurn(anItem, itemsToAnalyze[anItem].buffAmount, itemsToAnalyze[anItem].duration, itemsToAnalyze[anItem].opportunityCost);
		if (costPerBuffPerTurn <= maxMeatcostPerBuffTurn) {
			int amt = ceil(buffTurnsNeeded.to_float() / itemsToAnalyze[anItem].duration);
			if (fullAcquire(anItem, amt) < amt) {
				abort("could not acquire consumable: " + anItem);
			}
			consumeIfNeededWithUneffect(anItem, itemsToAnalyze[anItem].theEffect, buffTurnsNeeded);
		}
	}
}



string coldResBuffMakeClickableCommand(string command, string title) {
	return "<strong style=\"color:blue;\"><a href=\"KoLmafia/sideCommand?cmd=" + command.url_encode() + "&pwd=" + my_hash() + "\">" + title + "</a></strong>";
}

void coldResBuff(AnalyzeRecord [item] coldResItemsToAnalyze, int buffTurnsNeeded) {
	// SPECIAL CASES
	// Frosty Hand -- cargo pocket
	// KGB
	// pillkeeper

	item [int] sortArray;
	item [effect] effectMap;
	int ctr = 0;
	foreach it in coldResItemsToAnalyze {
		sortArray[ctr] = it;
		effectMap[coldResItemsToAnalyze[it].theEffect] = it;
		ctr += 1;
	}
	sort sortArray by costPerBuffPerTurn(value, coldResItemsToAnalyze[value].buffAmount, coldResItemsToAnalyze[value].duration, coldResItemsToAnalyze[value].opportunityCost);

	// CHOOSE BUFFS TO USE
	int buffCurrentlyOn;
	int newBuffs;
	int totalCost;
	int currentColdRes = numeric_modifier("Cold Resistance");
	string htmlOutput = "<html><head><style>table, td {border:none; border-collapse:collapse; padding:0px;}; th {border:1px}</style></head><body>"
		+ "<table><tr><th>Amount</th><th>Item (click to use 1)</th><th>Price</th><th>current turns</th><th>buff amount</th><th>duration</th><th>effect</th><th>cost per buff turn</th><th># needed</th><th>one less</th></tr>\n";

	// first, get the current state and calculate the items we need to maintain it for buffTurnsNeeded
	int [item] itemsNeeded; // item to number of turns needed
	for idx from 0 to count(sortArray) - 1 {
		item theItem = sortArray[idx];
		int costPerBuffTurn = costPerBuffPerTurn(theItem, coldResItemsToAnalyze[theItem].buffAmount, coldResItemsToAnalyze[theItem].duration, coldResItemsToAnalyze[theItem].opportunityCost);
		effect theEffect = coldResItemsToAnalyze[theItem].theEffect;
		string textColour = "#ADD8E6";
		if (have_effect(theEffect) > 0) {
			itemsNeeded[theItem] = buffTurnsNeeded - have_effect(theEffect);
			buffCurrentlyOn += coldResItemsToAnalyze[theItem].buffAmount;
			textColour = "#90ee90";
		} else {
			itemsNeeded[theItem] = buffTurnsNeeded;
			newBuffs += coldResItemsToAnalyze[theItem].buffAmount;
		}
		int numberNeeded = max(ceil(itemsNeeded[theItem].to_float() / coldResItemsToAnalyze[theItem].duration), 0);
		totalCost += numberNeeded * mall_price(theItem);

// 		print(theItem + " (current turns: " + have_effect(coldResItemsToAnalyze[theItem].theEffect)
// 			+ ", buffs for: " + coldResItemsToAnalyze[theItem].buffAmount + (coldResItemsToAnalyze[theItem].buffIsPercentBased ? "%" : "")
// 			+ ", " + coldResItemsToAnalyze[theItem].duration + " turns, effect: " + coldResItemsToAnalyze[theItem].theEffect + ") @ "
// 			+ costPerBuffTurn + " / buff" + (coldResItemsToAnalyze[theItem].buffIsPercentBased ? " percentage" : "")
// 			+ " / duration. Planning to consume " + numberNeeded, textColour);
		string activate1String = cliStringToConsume(1, theItem);
		if (coldResItemsToAnalyze[theItem].activationString != "")
			activate1String = to_string(1, coldResItemsToAnalyze[theItem].activationString);
		string activateAllString = coldResItemsToAnalyze[theItem].activationString == "" ? cliStringToConsume(numberNeeded, theItem) : to_string(numberNeeded, coldResItemsToAnalyze[theItem].activationString);
		string activateAllLessOneString = coldResItemsToAnalyze[theItem].activationString == "" ? cliStringToConsume(numberNeeded - 1, theItem) : to_string(numberNeeded - 1, coldResItemsToAnalyze[theItem].activationString);
		htmlOutput += "<tr style='background-color: " + textColour + "'><td>"
			+ available_amount(theItem) + "</td><td>"
			+ coldResBuffMakeClickableCommand(activate1String, coldResItemsToAnalyze[theItem].activationString == "" ? theItem.to_string() : activate1String) + "</td><td>"
			+ mall_price(theItem) + "</td><td>"
			+ have_effect(coldResItemsToAnalyze[theItem].theEffect)+ "</td><td>"
			+ coldResItemsToAnalyze[theItem].buffAmount + (coldResItemsToAnalyze[theItem].buffIsPercentBased ? "%" : "") + "</td><td>"
			+ coldResItemsToAnalyze[theItem].duration + "</td><td>" + coldResItemsToAnalyze[theItem].theEffect+ "</td><td>"
			+ costPerBuffTurn + "</td><td>"
			+ coldResBuffMakeClickableCommand(activateAllString, numberNeeded.to_string()) + "</td><td>"
			+ (numberNeeded > 0 ? coldResBuffMakeClickableCommand(activateAllLessOneString, to_string(numberNeeded - 1)) : "") + "</td></tr>\n";
	}

	htmlOutput += "</table></body></html>\n";
	print_html(htmlOutput);
	print_html("<html></html>"); // clears screen thrash from my seemingly well-formed HTML

	int baseColdRes = currentColdRes - buffCurrentlyOn; // the cold res minus the buffs we're managing

	// BUFF UP
// 	if (!user_confirm("Proceed under the following circumstances?\nTotal buff cost: " + totalCost + ", total buff: "
// 		+ (buffCurrentlyOn + newBuffs) + ", total cost per buff: " + (totalCost / (buffCurrentlyOn + newBuffs))
// 		+ " meat\nTOTAL COST: " + totalCost, 60000, false))
// 		abort("user aborted");
//
// 	// ACQUIRE AND CONSUME ITEMS
// 	foreach theItem, amount in itemsNeeded {
// 		int numberNeeded = ceil(amount.to_float() / coldResItemsToAnalyze[theItem].duration);
// 		if (fullAcquire(theItem, numberNeeded) < numberNeeded) {
// 			abort("could not acquire consumable: " + theItem);
// 		}
// 		consumeIfNeededWithUneffect(theItem, coldResItemsToAnalyze[theItem].theEffect, amount);
// 	}
}


void autoColdResBuff(AnalyzeRecord [item] coldResItemsToAnalyze) {
	int longestEffect;
	int totalTurnsForAverage, effectsForAverage;
	foreach theItem, ar in coldResItemsToAnalyze {
		int effectDuration = have_effect(ar.theEffect);
		if (effectDuration > 0) {
			totalTurnsForAverage += effectDuration;
			effectsForAverage++;
		}
		if (effectDuration > longestEffect)
			longestEffect = effectDuration;
	}
	if (effectsForAverage == 0)
		abort("no existing cold res buffs, use coldResBuff(int buffTurnsNeeded)");
	int averageEffect = totalTurnsForAverage / effectsForAverage;
	coldResBuff(coldResItemsToAnalyze, averageEffect);
}



// sorted by cost/turn/weight buffed
float [item] potionsThatBuffFamWt(boolean shouldPrint) {
	item [int] sortArray;
	int ctr;
	float [item] rval;

	// marshal the data
	foreach idx, it in allPotions() {
		effect potEff = effect_modifier(it, "effect");
		if (potEff.numeric_modifier("Familiar Weight") > 0.0) {
			sortArray[ctr++] = it;
		}
	}

	sort sortArray by -(value.current_historical_price() / value.numeric_modifier("Effect Duration") / value.effect_modifier("effect").numeric_modifier("Familiar Weight"));

	foreach idx, it in sortArray {
		effect potEff = it.effect_modifier("effect");
		float duration = it.numeric_modifier("Effect Duration");
		int weightBuff = potEff.numeric_modifier("Familiar Weight");
		float price = it.current_historical_price();
		float costPerTurnPerWeight = price / duration / weightBuff;
		cprint(shouldPrint, it + ": " + potEff + "@" + price + " -- cost per turn per weight: " + costPerTurnPerWeight + " -- effect " + potEff + " modifiers: " + potEff.string_modifier("Modifiers"));
		rval[it] = costPerTurnPerWeight;
	}

	return rval;
}



// returns a sorted list of consumables that buff the given modifier name
// list is sorted by buff per meat per turn
// does not consider untradeable items
AnalyzeRecord [item] consumablesToAnalyze(string modifierName, boolean shouldPrint) {
	AnalyzeRecord [item] rval, tempArray;
	item [int] sortableItems;
	int i;

	foreach it in $items[] {
		effect anEffect = effect_modifier(it, "Effect");
		if (anEffect == $effect[none]) continue;
		int buffAmount = numeric_modifier(anEffect, modifierName);

		if ((it.isPotion() || it.isFood() || it.isBooze() || it.isSpleen()) && buffAmount > 0) {
			int price = it.historical_price();
			if (price == 0) continue;
			int cost = it.opportunityCostToConsume();
			int duration = numeric_modifier(it, "Effect Duration");
			float rate = it.costPerBuffPerTurn(buffAmount, duration, cost);

			tempArray[it] = new AnalyzeRecord(buffAmount, false, duration, cost, anEffect);
			sortableItems[i++] = it;
        }
    }

	sort sortableItems by tempArray[value].opportunityCost / (tempArray[value].buffAmount * tempArray[value].duration);

	cprint(shouldPrint, modifierName + " buffs (orange means not currently enough room to consume):");
	foreach idx, it in sortableItems {
		effect anEffect = tempArray[it].theEffect;
		int buffAmount = tempArray[it].buffAmount;
		int price = it.historical_price();
		int cost = tempArray[it].opportunityCost;
		int duration = tempArray[it].duration;
		float rate = it.costPerBuffPerTurn(buffAmount, duration, cost);

		string colour = "green", consumeString = "";
		if (!haveRoom(it)) colour = "orange";
		if (it.isFood()) consumeString = " (and stomach " + it.fullness + ")";
		if (it.isBooze()) consumeString = " (and liver " + it.inebriety + ")";
		if (it.isSpleen()) consumeString = " (and spleen " + it.spleen + ")";
		cprint(shouldPrint, it + " +" + buffAmount + " for " + duration + " turns@" + (price+cost) + " meat" + consumeString + " -- " + rate + " meat/buff/turns", colour);

		rval[it] = new AnalyzeRecord(buffAmount, false, duration, cost, anEffect);
    }

	return rval;
}

AnalyzeRecord [item] consumablesToAnalyze(string modifierName) {
    return consumablesToAnalyze(modifierName, true);
}



string consumableBuffMakeClickableCommand(string command, string title) {
	return "<strong style=\"color:blue;\"><a href=\"KoLmafia/sideCommand?cmd=" + command.url_encode() + "&pwd=" + my_hash() + "\">" + title + "</a></strong>";
}

// print a sorted list of consumables that we are interested in
void printConsumableBuffs(AnalyzeRecord [item] consumablesToPrint, int buffTurnsNeeded) {
	int buffCurrentlyOn;
	int newBuffs;
	int totalCost;
	string htmlOutput = "<html><head><style>table, td {border:none; border-collapse:collapse; padding:0px;}; th {border:1px}</style></head><body>"
		+ "<table><tr><th>Amount</th><th>Item (click to use 1)</th><th>Price</th><th>Opportunity Cost</th><th>current turns</th><th>buff amount</th><th>duration</th><th>effect</th><th>cost per buff turn</th><th># needed</th><th>one less</th></tr>\n";

	// first, get the current state and calculate the items we need to maintain it for buffTurnsNeeded
	int [item] itemsNeeded; // item to number of turns needed
	foreach theItem, ar in consumablesToPrint {
		int costPerBuffTurn = costPerBuffPerTurn(theItem, ar.buffAmount, min(ar.duration, buffTurnsNeeded), ar.opportunityCost);
		effect theEffect = ar.theEffect;
		string textColour = "#ADD8E6";
		if (have_effect(theEffect) > 0) {
			itemsNeeded[theItem] = buffTurnsNeeded - have_effect(theEffect);
			buffCurrentlyOn += ar.buffAmount;
			textColour = "#90ee90";
		} else {
			itemsNeeded[theItem] = buffTurnsNeeded;
			newBuffs += ar.buffAmount;
		}
		int numberNeeded = max(ceil(itemsNeeded[theItem].to_float() / consumablesToPrint[theItem].duration), 0);
		totalCost += numberNeeded * mall_price(theItem);

		string activate1String = cliStringToConsume(1, theItem);
		if (ar.activationString != "")
			activate1String = to_string(1, ar.activationString);
		string activateAllString = ar.activationString == "" ? cliStringToConsume(numberNeeded, theItem) : to_string(numberNeeded, consumablesToPrint[theItem].activationString);
		string activateAllLessOneString = ar.activationString == "" ? cliStringToConsume(numberNeeded - 1, theItem) : to_string(numberNeeded - 1, consumablesToPrint[theItem].activationString);
		htmlOutput += "<tr style='background-color: " + textColour + "'><td>"
			+ available_amount(theItem) + "</td><td>"
			+ consumableBuffMakeClickableCommand(activate1String, ar.activationString == "" ? theItem.to_string() : activate1String) + "</td><td>"
			+ mall_price(theItem) + "</td><td>"
			+ ar.opportunityCost + "</td><td>"
			+ have_effect(ar.theEffect) + "</td><td>"
			+ ar.buffAmount + (ar.buffIsPercentBased ? "%" : "") + "</td><td>"
			+ ar.duration + "</td><td>" + ar.theEffect+ "</td><td>"
			+ costPerBuffTurn + "</td><td>"
			+ consumableBuffMakeClickableCommand(activateAllString, numberNeeded.to_string()) + "</td><td>"
			+ (numberNeeded > 0 ? consumableBuffMakeClickableCommand(activateAllLessOneString, to_string(numberNeeded - 1)) : "") + "</td></tr>\n";
	}

	htmlOutput += "</table></body></html>\n";
	print_html(htmlOutput);
	print_html("<html></html>"); // clears screen thrash from my seemingly well-formed HTML
}


void showConsumableBuffs(string modifierName, int buffTurnsNeeded, int maxCostPerBuffPerTurn) {
	AnalyzeRecord [item] consumablesToPrint;
	AnalyzeRecord [item] consumablesToAnalyze = consumablesToAnalyze(modifierName, false);

	// we have to resort the array because we limit duration to buffTurnsNeeded or less, which affects the cost per buff per turn
	item [int] sortArray;
	int idx = 0;
	foreach it in consumablesToAnalyze
		sortArray[idx++] = it;
	sort sortArray by costPerBuffPerTurn(value, consumablesToAnalyze[value].buffAmount, min(consumablesToAnalyze[value].duration, buffTurnsNeeded), consumablesToAnalyze[value].opportunityCost);
	foreach idx, it in sortArray
		consumablesToPrint[it] = consumablesToAnalyze[it];

	printConsumableBuffs(consumablesToPrint, buffTurnsNeeded);
}


// given a list of consumables we're interested in consuming and the number of turns we need to buff for, returns the cost of purchasing all the needed consumables.
int consumablesCost(AnalyzeRecord [item] consumablesToAnalyze, int buffTurnsNeeded) {
	int totalCost = 0;
	foreach it, ar in consumablesToAnalyze {
		effect anEffect = effect_modifier(it, "Effect");
		int numberNeeded = max(ceil((buffTurnsNeeded.to_float() - have_effect(anEffect)) / ar.duration), 0);
		totalCost += numberNeeded * mall_price(it);
	}
	return totalCost;
}


// given a list of consumables and the number of turns we need their buffs for and a maximum cost per buff per turn,
// return a list of consumables that cost less than maxCostPerBuffPerTurn sorted by cost per buff per turn
AnalyzeRecord [item] consumablesBuffToApply(AnalyzeRecord [item] consumablesToAnalyze, int buffTurnsNeeded, int maxCostPerBuffPerTurn) {
	AnalyzeRecord [item] rval;
	item [int] sortArray;
	int idx = 0;

	foreach it in consumablesToAnalyze
		sortArray[idx++] = it;

	sort sortArray by costPerBuffPerTurn(value, consumablesToAnalyze[value].buffAmount, min(consumablesToAnalyze[value].duration, buffTurnsNeeded), consumablesToAnalyze[value].opportunityCost);

	foreach i, theItem in sortArray {
		AnalyzeRecord ar = consumablesToAnalyze[theItem];
		int costPerBuffTurn = costPerBuffPerTurn(theItem, ar.buffAmount, min(ar.duration, buffTurnsNeeded), ar.opportunityCost);
		if (costPerBuffTurn <= maxCostPerBuffPerTurn) {
			rval[theItem] = ar;
		}
	}

	return rval;
}


// determine how long we should be buffing for by looking at the list of our currently active buffs which affect the modifier we're interested in and selecting the longest
// ignores any effect with a number of turns over 900 as those are likely only limited by MP
int determineBuffDuration(string modifierName) {
    int longestEffect = 0;
    foreach anEffect, effectDuration in my_effects() {
        if (numeric_modifier(anEffect, modifierName) > 0) {
            if (effectDuration > 0 && effectDuration <= 900) {
                if (effectDuration > longestEffect) {
                    longestEffect = effectDuration;
                }
            }
        }
    }
    return longestEffect;
}


boolean applyConsumablesBuff(string modifierName, int buffDuration, int maxCostPerBuffPerTurn) {
	AnalyzeRecord [item] consumables = consumablesToAnalyze(modifierName, false);
	AnalyzeRecord [item] consumablesBuffToApply = consumablesBuffToApply(consumables, buffDuration, maxCostPerBuffPerTurn);

	int totalCost = consumablesCost(consumablesBuffToApply, buffDuration);
	print("Consumables that buff " + modifierName + ", planning to buff for " + buffDuration + " turns at a cost of " + maxCostPerBuffPerTurn + " meat maximum per buff per turn, total cost: " + totalCost + " or " + (totalCost / buffDuration) + "/turn");
	if (!user_confirm("Do you want to proceed applying the listed buffs at a cost of " + totalCost + "?", 60000, true)) {
		print("Operation cancelled by user.", "red");
		return false;
	}

	int i;
	item[int] buffitList;
	foreach it, ar in consumablesBuffToApply
		buffitList[i++] = it;

	return consumeIfNeeded(buffitList, buffDuration);
}

boolean autoConsumablesBuff(string modifierName, int maxCostPerBuffPerTurn) {
	int buffDuration = max(1, determineBuffDuration(modifierName));
	return applyConsumablesBuff(modifierName, buffDuration, maxCostPerBuffPerTurn);
}



// -------------------------------------
// CLASS UTILITIES
// -------------------------------------

int infernalSealFights() {
	if (my_class() != $class[seal clubber]) return 0;
	int baseSealSummons = 5;
	if (have_item($item[Claw of the Infernal Seal])) baseSealSummons += 5;
	return baseSealSummons - to_int(get_property("_sealsSummoned"));
}



// -------------------------------------
// END GAME UTILITIES
// -------------------------------------

// return an array of locations and turns spent for all end game locations
// only hits the server once
int [location] endGameTurnsSpent() {
	int [location] rval;
	string aPage = visit_url("clan_raidlogs.php");

	// dreadsylvania
	matcher m = create_matcher("Your clan has defeated <b>([\\d,]*)</b> monster\\\(s\\\) in the ([\\w]+)", aPage);
	while (m.find()) {
		int killCount = m.group(1).to_int();
		string locString = m.group(2);
		location killLoc = to_location("dreadsylvanian " + (locString == "Forest" ? "Woods" : locString));
		rval[killLoc] = killCount;
	}

	// hobopolis TODO can probably do everything in xpath...
	string [int] hobopolisNames = xpath(aPage, "//div[@id='Hobopolis']//p/b/text()");
	string [int] hobopolisCompletion = xpath(aPage, '//div[@id="Hobopolis"]//blockquote'
	                                         );
	foreach idx, aString in hobopolisCompletion {
		int turnsTaken = 0;
		matcher hoboMatcher = create_matcher("\\(([0-9]+) turns?\\)", aString);
		string hoboName;
		while (find(hoboMatcher)) {
			hoboName = hoboMatcher.group(1);
			turnsTaken += hoboName.to_int();
		}

		hoboName = hobopolisNames[idx];
		string aloc = substring(hoboName, 0, length(hoboName) - 1);
		location theLocation = kEndGameNameToLocationMap[aloc];
		if (theLocation != $location[none])
			rval[theLocation] = turnsTaken;
	}

	// slimetube
	string [int] slimetubeCompletion = xpath(aPage, '//div[@id="SlimeTube"]//center//center/b/text()'
	                                         );
	if (count(slimetubeCompletion) < 1) {
		rval[$location[The Slime Tube]] = 0;
	} else
		rval[$location[The Slime Tube]] = slimetubeCompletion[0].to_int();

	return rval;
}


int [location] dreadsylvaniaTurnsSpent(int [location] turnsSpent) {
	int [location] dreadLocs;
	foreach idx, dreadLoc in kDreadLocs {
		dreadLocs[dreadLoc] = turnsSpent[dreadLoc];
	}
	return dreadLocs;
}

int dreadsylvaniaTotalTurnsSpent(int [location] turnsSpent) {
	int dreadTurns;
	foreach idx, dreadLoc in kDreadLocs {
		dreadTurns += turnsSpent[dreadLoc];
	}
	return dreadTurns;
}

int [location] hobopolisTurnsSpent(int [location] turnsSpent) {
	int [location] hoboLos;
	foreach idx, hoboLo in kHoboLos {
		hoboLos[hoboLo] = turnsSpent[hoboLo];
	}
	return hoboLos;
}

int hobopolisTotalTurnsSpent(int [location] turnsSpent) {
	int hoboTurns;
	foreach idx, hoboLo in kHoboLos {
		hoboTurns += turnsSpent[hoboLo];
	}
	return hoboTurns;
}



void printTurnsSpent(int [location] turnsSpent) {
	int total;
	foreach aLocation, spent in turnsSpent {
		print(aLocation + ": " + spent, "green");
		total += spent;
	}
	print("TOTAL turns spent: " + total, "green");
}


void printDreadsylvaniaTurnsSpent(int [location] turnsSpent) {
	printTurnsSpent(dreadsylvaniaTurnsSpent(turnsSpent));
}

void printDreadsylvaniaTurnsSpent() {
	printDreadsylvaniaTurnsSpent(endGameTurnsSpent());
}


void printHobopolisTurnsSpent(int [location] turnsSpent) {
	printTurnsSpent(hobopolisTurnsSpent(turnsSpent));
}

void printHobopolisTurnsSpent() {
	printHobopolisTurnsSpent(endGameTurnsSpent());
}


void printSlimetubeTurnsSpent(int [location] turnsSpent) {
	int [location] printTurnsSpent = {$location[The Slime Tube]: turnsSpent[$location[The Slime Tube]]};
	printTurnsSpent(printTurnsSpent);
}

void printSlimetubeTurnsSpent() {
	printSlimetubeTurnsSpent(endGameTurnsSpent());
}


void printEndGameTurnsSpent() {
	int [location] printTurnsSpent = endGameTurnsSpent();
	print("Dreadsylvania:");
	printDreadsylvaniaTurnsSpent(printTurnsSpent);
	print("\nHobopolis:");
	printHobopolisTurnsSpent(printTurnsSpent);
	print("\nSlime Tube:");
	printSlimetubeTurnsSpent(printTurnsSpent);
}


float dreadsylvaniaCompletion(int [location] turnsSpent) {
	return dreadsylvaniaTotalTurnsSpent(turnsSpent).to_float() / kDreadsylvaniaCompleteTurns.to_float();
}

float dreadsylvaniaCompletion() {
	return dreadsylvaniaCompletion(endGameTurnsSpent());
}


float hobopolisCompletion(int [location] turnsSpent) {
	return hobopolisTotalTurnsSpent(turnsSpent).to_float() / kHobopolisCompleteTurns.to_float();
}

float hobopolisCompletion() {
	return hobopolisCompletion(endGameTurnsSpent());
}



// -------------------------------------
// IOTM ITEMS OF THE MONTH
// -------------------------------------

// ensures we have the right familiar before mumming
void safeMumming(familiar aFamiliar, string mumBuff) {
	if (get_property("_mummeryMods").contains_text(aFamiliar)) {
		print(aFamiliar + " already has a mumming trunk buff");
		return;
	}

	use_familiar(aFamiliar);
	assert(my_familiar() == aFamiliar, "unable to switch to " + aFamiliar);
	boolean unused = cli_execute("mummery " + mumBuff);
}


void doseRobortender(item drinkItem) {
	if (!get_property("_roboDrinks").contains_text(drinkItem)) {
		fullAcquire(drinkItem);
		boolean unused = cli_execute("robo " + drinkItem);
	}
}

// default dosing
void doseRobortender() {
	//doseRobortender($item[Newark]);
}


item [phylum] kRobortenderWeakBooze() {
	item [phylum] rval;

	foreach phy, strongBooze in kRobortenderStrongBooze {
		foreach ingred, amt in get_ingredients(strongBooze) {
			if (ingred.to_int() > 9300)
				rval[phy] = ingred;
		}
	}

	return rval;
}

item [phylum] kRobortenderDrops() {
	item [phylum] rval;

	foreach phy, weakBooze in kRobortenderWeakBooze() {
		foreach ingred, amt in get_ingredients(weakBooze) {
			if (ingred.to_int() > 9300)
				rval[phy] = ingred;
		}
	}

	// default booze
	rval[$phylum[beast]] = $item[bottle of gin];
	rval[$phylum[construct]] = $item[bottle of gin];
	rval[$phylum[dude]] = $item[bottle of gin];
	rval[$phylum[undead]] = $item[bottle of gin];

	return rval;
}

// returns the number of robo items dropped so far today
int roboDrops(boolean doPrint) {
	int rval;
	int [item] receipt;
	foreach roboPhylum, roboDrop in kRobortenderDrops() {
		int drops = my_session_items(roboDrop);
		if (drops > 0) {
			receipt[roboDrop] = drops;
			rval += drops;
		}
	}
	if (doPrint)
		printReceipt(receipt);
	return rval;
}

int roboDrops() {
	return roboDrops(true);
}


void printRoboArray(item [phylum] anArray) {
	int i;
	foreach phy, roboItem in anArray {
		print(i++ + ": " + roboItem + " drops from " + phy);
	}
}

void printRoboArray() {
	printRoboArray(kRobortenderDrops());
}


// chance for the next drop
float roboDropChance() {
	int drops = roboDrops(false);
	switch (drops) {
		case 0: return 1.0;

		case 1: case 2: case 3: return 0.5;

		case 4: case 5: case 6: return 0.4;

		case 7: case 8: case 9: return 0.3;

		default: return 0.2;
	}
}


// chance for the next drop at a given location
// including the chance of a NC
float [location] _gRoboDropChanceToLocation;
float roboDropChanceForLocation(location roboLo, boolean doPrint) {
	// cached value
	if (_gRoboDropChanceToLocation contains roboLo)
		return _gRoboDropChanceToLocation[roboLo];

	float baseDropChance = roboDropChance();
	float rval;

	cprint(doPrint, "roboDropChanceForLocation @ " + roboLo + ", with base robo drop chance: " + (baseDropChance * 100) + "%");

	foreach mon, rate in appearance_rates(roboLo) {
		phylum monPhy = monster_phylum(mon);
		float realRate = rate / 100;
		if (kRobortenderDrops() contains monPhy) {
			rval += (realRate * baseDropChance);
		}

		cprint(doPrint, mon + " (" + monPhy + ") appears " + rate + "%", "green");
	}

	cprint(doPrint, "Chance of a robo drop: " + (rval * 100) + "% / turn", "green");

	// cache the value
	_gRoboDropChanceToLocation[roboLo] = rval;
	return rval;
}

float roboDropChanceForLocation(location roboLo) {
	return roboDropChanceForLocation(roboLo, true);
}



// returns the meat value of equipping the robortender for the given monster
int roboEconomicsForMonster(monster roboMo, boolean doPrint) {
	int bestValue = 100;
	float baseDropChance = roboDropChance();
	item [phylum] drops = kRobortenderDrops();
	item [phylum] weak = kRobortenderWeakBooze();
	item [phylum] strong = kRobortenderStrongBooze;
	phylum monPhy = monster_phylum(roboMo);
	if (monPhy == $phylum[none])
		return 0;
	assert(drops contains monPhy, "unknown monster phylum: " + monPhy);

	item bestValueItem = drops[monPhy];
	int bestValuePrice = mall_price(bestValueItem);

	if (mall_price(weak[monPhy]) > bestValuePrice) {
		bestValueItem = weak[monPhy];
		bestValuePrice = mall_price(bestValueItem);
	}
	if (mall_price(strong[monPhy]) > bestValuePrice) {
		bestValueItem = strong[monPhy];
		bestValuePrice = mall_price(bestValueItem);
	}

	bestValue = bestValuePrice * baseDropChance;

	if (doPrint)
		print(roboMo
			+ " drops " + drops[monPhy] + "@" + mall_price(drops[monPhy])
			+ ", weak: " + weak[monPhy] + "@" + mall_price(weak[monPhy])
			+ ", strong: " + strong[monPhy] + "@" + mall_price(strong[monPhy])
			+ " -- best value * robo drop chance: " + bestValue + " meat value per kill"
			, "green");

	return bestValue;
}

int roboEconomicsForMonster(monster roboMo) {
	return roboEconomicsForMonster(roboMo, true);
}



// returns average ROI for the given location
int [location] _gRoboEconomicsToLocation;
int roboEconomicsForLocation(location roboLo, boolean doPrint) {
	// cached value
	if (_gRoboEconomicsToLocation contains roboLo)
		return _gRoboEconomicsToLocation[roboLo];

	float baseDropChance = roboDropChance();
	item [phylum] drops = kRobortenderDrops();
	item [phylum] weak = kRobortenderWeakBooze();
	item [phylum] strong = kRobortenderStrongBooze;
	int totalValue;

	cprint(doPrint, "roboEconomicsForLocation @ " + roboLo + ", with base robo drop chance: " + (baseDropChance * 100) + "%", "green");

	foreach mon, rate in appearance_rates(roboLo) {
		if (mon != $monster[none]) {
			float realRate = max(rate, 0) / 100;
			int roboMoValue = roboEconomicsForMonster(mon, doPrint);
			cprint(doPrint, mon + " @ " + realRate);
			totalValue += roboMoValue * realRate;
		}
	}

	// cache the value
	_gRoboEconomicsToLocation[roboLo] = totalValue;
	return totalValue;
}

int roboEconomicsForLocation(location roboLo) {
	return roboEconomicsForLocation(roboLo, true);
}



boolean canAugustSkill(int day) {
	boolean augSkillCast = ("_aug" + day + "Cast").get_property().to_boolean();
	int augSkillsCast = "_augSkillsCast".get_property().to_int();
	boolean augTodayCast = "_augTodayCast".get_property().to_boolean();
    int todaysDate = today_to_string().substring(6).to_int();
    assert(todaysDate > 0 && todaysDate < 32, "canAugustSkill: didn't get today's date!");

	return (augSkillsCast < 5 && !augSkillCast) || (todaysDate == day && !augTodayCast);
}



boolean freePillKeeperUsed() {
	return "_freePillKeeperUsed".get_property().to_boolean();
}



int luckyValue() {
	return mall_price($item[11-leaf clover]);
}


item nextLuckyToUse() {
	int cost = 0;
	item lowestCostItem;
	int lowestCostItemCost = kMaxInt;

    if (have_item($item[Apriling band saxophone]) && "_aprilBandSaxophoneUses".get_property().to_int() < 3)
        return $item[Apriling band saxophone];

	if (!freePillKeeperUsed())
		return $item[Eight Days a Week Pill Keeper];

	if (canAugustSkill(2))
		return $item[august scepter];

	int speakeasyCost = (3 * 6 * kTurnValue) + 500;
	if (get_property("_speakeasyDrinksDrunk").to_int() < 3 && lowestCostItemCost > speakeasyCost) {
		lowestCostItem = $item[Lucky Lindy];
		lowestCostItemCost = speakeasyCost;
	}

	int pillkeeperCost = 3 * kSpleenValue;
	if (my_spleen_use() <= spleen_limit() - 3 && lowestCostItemCost > pillkeeperCost) {
		lowestCostItem = $item[Eight Days a Week Pill Keeper];
		lowestCostItemCost = pillkeeperCost;
	}

	int cloverCost = mall_price($item[11-leaf clover]);
	if (have_item($item[11-leaf clover]) && lowestCostItemCost > cloverCost) {
		lowestCostItem = $item[11-leaf clover];
		lowestCostItemCost = mall_price($item[11-leaf clover]);
	}

	return lowestCostItem;
}


int nextLuckyCost() {
	item nextLuck = nextLuckyToUse();

	if (nextLuck == $item[Apriling band saxophone])
		return 0;

	if (nextLuck == $item[Eight Days a Week Pill Keeper])
		return (freePillKeeperUsed() ? (3 * kTurnsPerSpleen * kTurnValue) : 0);

	if (nextLuck == $item[august scepter])
		return (canAugustSkill(2) ? 0 : kMaxInt);

	return current_price(nextLuck);
}


// can we get lucky for the given cost
boolean canGetLucky(int cost) {
    return nextLuckyCost() <= cost;
}

// get lucky by whatever means necessary
boolean getLucky() {
	if (have_effect($effect[Lucky!]) > 0)
		return true;

	item nextLuck = nextLuckyToUse();

    if (nextLuck == $item[Apriling band saxophone])
        return cli_execute("apriling lucky");

	if (nextLuck == $item[Eight Days a Week Pill Keeper])
		return cli_execute("pillkeeper lucky");

	if (nextLuck == $item[august scepter])
		return use_skill(1, $skill[Aug. 2nd: Find an Eleven-Leaf Clover Day]);

	if (nextLuck != $item[11-leaf clover])
		abort("unknown lucky-getting mechanism");

	fullAcquire($item[11-leaf clover]);
	return use(1, $item[11-leaf clover]);
}



int [location] luckyAdventuresByMeatGainMap() {
	return int [location] {
		$location[Camp Logging Camp] : historical_price($item[poutine]) + historical_price($item[balaclava baklava]) + historical_price($item[blatantly canadian]),
		$location[The Poker Room] : 300, // 20 mox
		$location[The Roulette Tables] : 320, // 20 mys
		$location[The Copperhead Club] : historical_price($item[Flamin' Whatshisname]) * 3,
		$location[The Haunted Ballroom] : 0, // 2xmainstat mox
		$location[The Haunted Bathroom] : 0, // 2xmainstat mys
		$location[The Haunted Billiards Room] : historical_price($item[cube of billiard chalk]),
		$location[The Haunted Conservatory] : historical_price($item[pile of dusty animal bones]),
		$location[The Haunted Gallery] : 0, // 2xmainstat mus
		$location[The Haunted Kitchen] : historical_price($item[freezerburned ice cube]),
		$location[The Haunted Library] : historical_price($item[black eyedrops]),
		$location[The Haunted Pantry] : historical_price($item[tasty tart]) * 3,
		$location[The Haunted Storage Room] : 1000, // 1 PVP-able item that you're wearing
		$location[Outskirts of Camp Logging Camp] : historical_price($item[forest tears]) * 3,
		$location[The Haunted Boiler Room] : historical_price($item[Bram's choker]),
		$location[The Sleazy Back Alley] : historical_price($item[distilled fortified wine]) * 3,
		$location[The Limerick Dungeon] : historical_price($item[cyclops eyedrops]),
		$location[Itznotyerzitz Mine] : historical_price($item[asbestos ore]), // could be any ore, assume they're all the same price
		$location[The Goatlet] : historical_price($item[can of spinach]),
		$location[Lair of the Ninja Snowmen] : historical_price($item[bottle of antifreeze]),
		$location[The Icy Peak] : historical_price($item[frozen Mob Penguin]),
		$location[The Smut Orc Logging Camp] : 0, // 3xglue, 3xplank (all quest items)
		$location[A-boo Peak] : historical_price($item[death blossom]), // +2 a-boo clues (quest items)
		$location[Twin Peak] : 0, // 10 turns of Your Interest is Peaked
		$location[Oil Peak] : historical_price($item[bubblin' crude]) * 3 + historical_price($item[unnatural gas]),
		$location[A Mob of Zeppelin Protesters] : 0, // NC for Zep quest
		$location[The Red Zeppelin] : historical_price($item[red foxglove]) + 0.01 * historical_price($item[Red Fox glove]),
		$location[The Valley of Rof L'm Fao] : historical_price($item[ASCII shirt]) + historical_price($item[30669 scroll]) + historical_price($item[33398 scroll]) + historical_price($item[334]) * 2,
		$location[The Outskirts of Cobb's Knob] : historical_price($item[Knob Goblin lunchbox]),
		$location[Cobb's Knob Barracks] : historical_price($item[Knob Goblin elite helm]) + historical_price($item[Knob Goblin elite pants]) + historical_price($item[Knob Goblin elite polearm]),
		$location[Cobb's Knob Kitchens] : historical_price($item[Knob Kitchen grab-bag]),
		$location[Cobb's Knob Harem] : historical_price($item[scented massage oil]) * 3,
		$location[Cobb's Knob Treasury] : historical_price($item[Knob Goblin visor ]) * 0.5 + 2 * 100 + 1000,
		$location[The Knob Shaft] : historical_price($item[bubblewrap ore]) * 3, // or cardboard, or styrofoam
		$location[Cobb's Knob Laboratory] : historical_price($item[bottle of Mystic Shell]),
		$location[Cobb's Knob Menagerie\, Level 2] : historical_price($item[irradiated pet snacks]),
		$location[The Spooky Gravy Burrow] : historical_price($item[spooky lipstick]),
		$location[Post-Quest Bugbear Pens] : historical_price($item[bugbear beanie]) + historical_price($item[bugbear bungguard]),
		$location[Tower Ruins] : historical_price($item[disembodied brain]), // 15 mys
		$location[The "Fun" House] : historical_price($item[box]) * 3,
		$location[Battlefield (No Uniform)] : historical_price($item[six-pack of New Cloaca-Cola]),
		$location[Battlefield (Cloaca Uniform)] : historical_price($item[six-pack of New Cloaca-Cola]),
		$location[Battlefield (Dyspepsi Uniform)] : historical_price($item[six-pack of New Cloaca-Cola]),
		$location[The Unquiet Garves] : historical_price($item[poltergeist-in-the-jar-o]),
		$location[The VERY Unquiet Garves] : historical_price($item[disembodied brain]) + historical_price($item[smart skull]),
		$location[Guano Junction] : historical_price($item[Eau de Guaneau]),
		$location[The Batrat and Ratbat Burrow] : historical_price($item[Dogsgotnonoz pills]),
		$location[The Castle in the Clouds in the Sky (Basement)] : 0, // NAGAMAR quest items
		$location[The Castle in the Clouds in the Sky (Ground Floor)] : historical_price($item[possibility potion]),
		$location[The Castle in the Clouds in the Sky (Top Floor)] : historical_price($item[Mick's IcyVapoHotness Inhaler]),
		$location[The Spectral Pickle Factory] : historical_price($item[spectral pickle]), // not normally available
		$location[The Spooky Forest] : max(historical_price($item[bowl of lucky charms]), historical_price($item[leprechaun hatchling]) * 0.5),
		$location[Whitey's Grove] : historical_price($item[bag of lard]),
		$location[The Black Forest] : historical_price($item[black picnic basket]),
		$location[The Dark Elbow of the Woods] : historical_price($item[SPF 451 lip balm]),
		$location[The Dark Heart of the Woods] : historical_price($item[SPF 451 lip balm]),
		$location[The Dark Neck of the Woods] : historical_price($item[SPF 451 lip balm]),
		$location[Pandamonium Slums] : historical_price($item[SPF 451 lip balm]),
		$location[The Hidden Park] : historical_price($item[shrinking powder]),
		$location[The Hidden Temple] : historical_price($item[stone wool]) * 3,
		$location[8-Bit Realm] : historical_price($item[[2426]fire flower]),
		$location[Thugnderdome] : historical_price($item[Gnomish toolbox]),
		$location[South of the Border] : historical_price($item[donkey flipbook]),
		$location[The Oasis] : 0, // 20 turns of Ultrahydrated
		$location[Frat House] : historical_price($item[bottle of rhinoceros hormones]),
		$location[Frat House (Frat Disguise)] : historical_price($item[roll of drink tickets]),
		$location[Hippy Camp] : historical_price($item[teeny-tiny magic scroll]),
		$location[Hippy Camp (Hippy Disguise)] : historical_price($item[fruit basket]),
		$location[The Obligatory Pirate's Cove] : historical_price($item[bottle of pirate juice]),
		$location[A Maze of Sewer Tunnels] : 0, // clan trophy
		$location[Burnbarrel Blvd.] : historical_price($item[jar of squeeze]) - 5 * kTurnValue, // costs 5 hobo coins, which are untradeable
		$location[Exposure Esplanade] : historical_price($item[bowl of fishysoisse]) - 5 * kTurnValue, // costs 5 hobo coins, which are untradeable
		$location[The Heap] : historical_price($item[concentrated garbage juice]) - 5 * kTurnValue, // costs 5 hobo coins, which are untradeable
		$location[The Ancient Hobo Burial Ground] : historical_price($item[deadly lampshade]) - 5 * kTurnValue, // costs 5 hobo coins, which are untradeable
		$location[The Purple Light District] : historical_price($item[lewd playing card]) - 5 * kTurnValue, // costs 5 hobo coins, which are untradeable
		$location[The Briny Deeps] : historical_price($item[beefy fish meat]) * 2 + historical_price($item[glistening fish meat]) * 2 + historical_price($item[slick fish meat]) * 2,
		$location[The Brinier Deepers] : 50 * 1000, // 50 adv of Fishy
		$location[An Octopus's Garden] : historical_price($item[giant pearl]),
		$location[The Wreck of the Edgar Fitzsimmons] : historical_price($item[long-forgotten necklace]),
		$location[The Dive Bar] : historical_price($item[shavin' razor]),
		$location[Madness Reef] : 20 * 500, // 20 adv of +100 item (underwater only)
		$location[The Mer-Kin Outpost] : historical_price($item[sand dollar]) * 17.5,
		$location[The Primordial Soup] : historical_price($item[memory of some delicious amino acids]) * 3.5 + historical_price($item[memory of a CA base pair]) * 0.5 + historical_price($item[memory of a CT base pair]) * 0.5 + historical_price($item[memory of a GT base pair]) * 0.5 + historical_price($item[memory of an AG base pair]) * 0.5 + historical_price($item[memory of an AT base pair]) * 0.5 + historical_price($item[memory of a CA base pair]) * 0.5,
		$location[Ye Olde Medievale Villagee] : historical_price($item[straw]) + historical_price($item[leather]) + historical_price($item[clay]),
		$location[Vanya's Castle Chapel] : historical_price($item[pixel stopwatch]),
		$location[Art Class] : historical_price($item[twisted piece of wire]) + historical_price($item[angry inch]) + historical_price($item[eraser nubbin]) + historical_price($item[lump of clay]),
		$location[Chemistry Class] : historical_price($item[chlorine crystal]) + historical_price($item[ph balancer]) + historical_price($item[mysterious chemical residue]) + historical_price($item[nugget of sodium]),
		$location[Shop Class] : historical_price($item[jigsaw blade]) + historical_price($item[wood screw]) + historical_price($item[balsa plank]) + historical_price($item[blob of wood glue]),
		$location[The Hallowed Halls] : historical_price($item[folder (KOLHS)]),
	};
}


location [] luckyEconomics(boolean shouldPrint) {
	int [location] luckyAdventuresByMeatGainMap = luckyAdventuresByMeatGainMap();
	location [int] sortableLucky;
	int idx;
	foreach aloc, meatGain in luckyAdventuresByMeatGainMap {
		sortableLucky[idx++] = aloc;
	}
	sort sortableLucky by -luckyAdventuresByMeatGainMap[value];

	if (shouldPrint)
		foreach ind, aloc in sortableLucky
			print(aloc + ": " + luckyAdventuresByMeatGainMap[aloc]);

	return sortableLucky;
}

location [] luckyEconomics() {
	return luckyEconomics(true);
}



// returns meat gain info at CURRENT bonus drop. only returns copyable monsters TODO should be copyable OR able to get to via (relatively) normal adventuring
// only returns monsters with values over a threshold (currently kTurnValue) OR with pp-only items
// #pickpocketEconomics #pickpocket economics #ppEconomics #pp economics
int [monster] pickpocketonomics(boolean doPrint) {
	int [monster] rval;
	monster [int] allMons;
	int idx;
	foreach amon in $monsters[] {
		allMons[idx++] = amon;
	}

	sort allMons by -monsterPPMeatValue(value, numeric_modifier("Pickpocket Chance"), false);

	cprint(doPrint, "value of picketpocketing this monster:");
	foreach i, amon in allMons {
		boolean hasPPOnly = hasPPOnly(amon);
		int ppVal = monsterPPMeatValue(amon, numeric_modifier("Pickpocket Chance"), false);
		if (isCopyable(amon) && (ppVal > kTurnValue || hasPPOnly)) {
			cprint(doPrint && ppVal > 0, amon + " @ "  + ppVal, hasPPOnly ? "green" : "");
			//cprint(doPrint, amon + " @ "  + ppVal, hasPPOnly ? (isCopyable ? "green" : "orange") : (isCopyable ? "" : "red")); // printing non-copyable monsters makes the list too long
			rval[amon] = ppVal;
		}
	}

	return rval;
}

int [monster] pickpocketonomics() {
	return pickpocketonomics(true);
}


// #hug pocket
int [monster] hugpocketenomics(boolean doPrint) {
	int [monster] rval;
	monster [int] allMons;
	int idx;
	foreach amon in $monsters[] {
		allMons[idx++] = amon;
	}

	sort allMons by -monsterHugpocketMeatValue(value, false);

	cprint(doPrint, "value of hugpocketenomics this monster:");
	foreach i, amon in allMons {
		if (isCopyable(amon)) {
			int ppVal = monsterHugpocketMeatValue(amon, false);
			cprint(doPrint && ppVal > 0, amon + " @ "  + ppVal, hasPPOnly(amon) ? "green" : "");
			rval[amon] = ppVal;
		}
	}

	return rval;
}

int [monster] hugpocketenomics() {
	return hugpocketenomics(true);
}


int familiarMeatValue(familiar afam, item famEq, monster amon, boolean conditionalDrops) {
	int famItemBonus = numeric_modifier(afam, "Item Drop", familarWeight(afam), famEq);
	int famMeatBonus = numeric_modifier(afam, "Meat Drop", familarWeight(afam), famEq);

	return amon.monsterTotalMeatValue(conditionalDrops, famItemBonus, famMeatBonus) - amon.monsterBaseTotalMeatValue(conditionalDrops);
}


// returns the meat gain for the given monster
// includes: +item/+meat familiars, robortender
int [familiar, item] familiarMeatValue(monster amon, boolean conditionalDrops, boolean doPrint) {
	int [familiar, item] rval;

	rval[$familiar[Robortender], $item[toggle switch (Bartend)]] = familiarMeatValue($familiar[Robortender], $item[toggle switch (Bartend)], amon, conditionalDrops) + roboEconomicsForMonster(amon, false);
	rval[$familiar[Trick-or-Treating Tot], $item[li'l ninja costume]] = familiarMeatValue($familiar[Trick-or-Treating Tot], $item[li'l ninja costume], amon, conditionalDrops);
	rval[$familiar[Trick-or-Treating Tot], $item[li'l pirate costume]] = familiarMeatValue($familiar[Trick-or-Treating Tot], $item[li'l pirate costume], amon, conditionalDrops);
	rval[$familiar[Cat Burglar], $item[burglar/sleep mask]] = familiarMeatValue($familiar[Cat Burglar], $item[burglar/sleep mask], amon, conditionalDrops);
	rval[$familiar[XO Skeleton], $item[exo-xo-skeleton-skeleton]] = familiarMeatValue($familiar[XO Skeleton], $item[exo-xo-skeleton-skeleton], amon, conditionalDrops);
	rval[$familiar[Hobo Monkey], $item[tiny bindle]] = familiarMeatValue($familiar[Hobo Monkey], $item[tiny bindle], amon, conditionalDrops);

	if (doPrint)
		foreach afam, it, meatVal in rval
			print(afam + " wearing " + it + " adds " + meatVal + " value");

	return rval;
}

int [familiar, item] familiarMeatValue(monster amon, boolean conditionalDrops) {
	return familiarMeatValue(amon, conditionalDrops, true);
}



int effectiveGingerbreadCityTurns() {
	int base = to_int(get_property("_gingerbreadCityTurns"));
	int clockAdvance = 0;
	if (to_boolean(get_property("_gingerbreadClockAdvanced"))) clockAdvance = 5;
	return base + clockAdvance;
}


int [int, string] gingerbreadLeaderboard() {
	string page = visit_url("/place.php?whichplace=gingerbreadcity&action=gc_leaderboard", false);
	matcher leaderboardMatcher = create_matcher("<tr><td><b><a class=nounder href=showplayer.php\\?who=[0-9]+>(.+?)</a></b></td><td></td><td>([0-9,]+) sprinkles</td></tr>", page);
	int [int, string] rval;
	int i = 1; // first place is 1
	while (find(leaderboardMatcher)) {
		string leaderName = group(leaderboardMatcher, 1);
		int leaderAmount = to_int(group(leaderboardMatcher, 2));
        rval[i++, leaderName] = leaderAmount;
	}

    assert(isValidTop10List(rval), "didn't get a valid gingerbread leaderboard");
    return rval;
}

void printGingerbreadLeaderboard() {
    int [int, string] leaderboard = gingerbreadLeaderboard();
    printTop10List(leaderboard);
}



int [monster] parseFantasyRealmMonstersKilled() {
	int [monster] rval;
	string [int, int] parser = group_string(get_property("_frMonstersKilled"), ",?([^:]+):(\\d+)");
	foreach i in parser {
		monster aMonster = to_monster(parser[i][1]);
		int aKillCount = to_int(parser[i][2]);
		rval[aMonster] = aKillCount;
		//print("found monster: " + aMonster + ", killed: " + aKillCount);
	}
	return rval;
}



// map location to monster for fantasy realm zones (or any zone with 1 monster really)
monster zoneMonster(location aloc) {
	float [monster] zonemons = appearance_rates(aloc);
	foreach amon, rate in zonemons
		if (rate > 0)
			return amon;
	assert(false, "all FR zones should have a monster!");
	return $monster[none];
}



int frHoursNeeded(string [] locStrings) {
	int hoursNeeded = count(locStrings) + 1;
	int hoursLeft = get_property("_frHoursLeft") == "" ? 5 : get_property("_frHoursLeft").to_int();
	string unlockString;

	foreach idx, aloc in locStrings {
		unlockString += aloc;
		if (get_property("_frAreasUnlocked").contains_text(aloc))
			hoursNeeded--;
	}

	return hoursNeeded;
}

// TODO fixme
void frEnsureHoursNeeded(string [] locStrings) {
	return;
// 	int hoursLeft = get_property("_frHoursLeft") == "" ? 5 : get_property("_frHoursLeft").to_int();
// 	assert(hoursLeft >= frHoursNeeded(locStrings), "FantasyRealm: not enough HOURS left");
}


// if a location is unlocked, add 5 - number of zone monsters killed
// if a location is not unlocked, add 5 for the locked zone, plus 5 for the (unknown) zone that unlocks it
void frEnsureTurnsNeeded(string [] locStrings) {
	assert(my_adventures() >= (frHoursNeeded(locStrings) * 6) + 1, "FantasyRealm: not enough TURNS left");
}



// uses the briefcase to get anEffect until anEffect has minimumNumberOfTurns
boolean briefcase_if_needed(effect anEffect, int minimumNumberOfTurns) {
	return true;

	string [effect] BriefcaseEffectsMap = {
		$effect[A View to Some Meat] : "meat",
		$effect[Items Are Forever] : "item",
		$effect[Initiative and Let Die] : "init"
	};

	int clicksUsed = to_int(get_property("_kgbClicksUsed"));
	boolean executed = false;
	while (have_effect(anEffect) < minimumNumberOfTurns && clicksUsed < 22) {
		executed = cli_execute("briefcase buff " + BriefcaseEffectsMap[anEffect]);
		clicksUsed = to_int(get_property("_kgbClicksUsed"));
		if (!executed) return false;
	}
	return true;

	return cli_execute_if_needed("briefcase buff " + BriefcaseEffectsMap[anEffect], anEffect, minimumNumberOfTurns);
}



// returns true if any Asdon Martin buff is current on
boolean drivingAsdonMartin() {
	effect [] AsdonMartinEffects = {
		$effect[Driving Obnoxiously],
		$effect[Driving Stealthily],
		$effect[Driving Wastefully],
		$effect[Driving Safely],
		$effect[Driving Recklessly],
		$effect[Driving Intimidatingly],
		$effect[Driving Quickly],
		$effect[Driving Observantly],
		$effect[Driving Waterproofly]
	};
	foreach index in AsdonMartinEffects
		if (have_effect(AsdonMartinEffects[index]) > 0)
			return true;
	return false;
}


// returns true if we have no asdon marten effect or we have the given effect
boolean drivingAsdonMartin(effect asdonEffect) {
	return have_effect(asdonEffect) > 0 || !drivingAsdonMartin();
}



// returns all possible asdon martin fuel sorted by best meat efficiency
item [] asdonFuel() {
	int expensiveValue = 100;
	item [int] inv_items = inventoryArray();

	// filter for fuel items
	item [int] fuelItems;
	int fuelIndex;
	foreach idx, it in inv_items {
		if ((item_type(it) == "food" || item_type(it) == "booze")
			&& (it.fullness > 0 || it.inebriety > 0)
			&& (count(get_ingredients(it)) > 0)
			&& is_pvpable(it))
			fuelItems[fuelIndex++] = it;
	}

	// filter for price
	item [int] filteredItems;
	int filteredIndex;
	foreach idx, it in fuelItems {
		int nutrition = nutrition(it); // number of adventures
		if (historical_price(it) / nutrition < expensiveValue)
			filteredItems[filteredIndex++] = it;
	}

	// sort by cost per adventure gained
	sort filteredItems by historical_price(value) / nutrition(value);

	return filteredItems;
}


void printAsdonMartFuel() {
	item [int] filteredItems = asdonFuel();
	foreach idx, it in filteredItems {
		int nutrition = nutrition(it); // number of adventures
		print(item_amount(it) + "x " + it + " (" + nutrition + " adv @ " + (historical_price(it) / nutrition) + " meat/adv)");
	}
}


item bestAsdonFuel() {
	return asdonFuel()[0];
}


// uses generic food to fuel the asdon martin
void fuelAsdonMartin(int moreFuel) {
	assert(isAsdonWorkshed(), "fuelAsdonMartin: no Asdon Martin in your workshed!");

	int goalFuel = get_fuel() + moreFuel;
	int neededFuel = moreFuel;

	while (neededFuel > 0) {
		item bestFuel = bestAsdonFuel();
		int amtFuelToAcquire = ceil(neededFuel.to_float() / nutrition(bestFuel).to_float());
		print("fuelAsdonMartin: have " + get_fuel() + " need " + goalFuel + ". Fuelling with: " + amtFuelToAcquire + " x " + bestFuel, "green");

		int amtFuelBought;
		int amtFuelToUse;
		int tries = 3;
		while (amtFuelToUse == 0 && tries > 0) {
			amtFuelBought = bestFuel.buy(amtFuelToAcquire, bestFuel.historical_price() * 1.05);
			amtFuelToUse = min(amtFuelBought, available_amount(bestFuel));

			bestFuel = bestAsdonFuel();
			amtFuelToAcquire = ceil(neededFuel / nutrition(bestFuel));
			tries--;
		}
		assert(amtFuelToUse > 0, "fuelAsdonMartin: we should have fuel at this point");
		cli_execute("asdonmartin fuel " + amtFuelToUse + " " + bestFuel);

		neededFuel = goalFuel - get_fuel();
		bestFuel = bestAsdonFuel();
		amtFuelToAcquire = ceil(neededFuel / nutrition(bestFuel));
	}
}


int costOfAsdonMartinFuel(int fuelLevel) {
	item bestFuel = bestAsdonFuel();
	int amtFuelToAcquire = ceil(fuelLevel.to_float() / nutrition(bestFuel).to_float());
	return historical_price(bestFuel) * amtFuelToAcquire;
}

int costOfAsdonMartinBuff() {
	return costOfAsdonMartinFuel(37);
}


// ensure the Asdon Martin is fueled up to fuelLevel
void ensureAsdonMartinFuel(int fuelLevel) {
	assert(isAsdonWorkshed(), "ensureAsdonMartinFuel: no Asdon Martin in your workshed!");

	int moreFuel = fuelLevel - get_fuel();
	if (moreFuel > 0)
		fuelAsdonMartin(moreFuel);
}


// use the asdonmartin, fueling enough for the buff if we're not in ronin
boolean unfueled_asdonmartin(string style, int times) {
	assert(isAsdonWorkshed(), "unfueled_asdonmartin: no Asdon Martin in your workshed!");

	print("buffing asdon martin " + style + ", " + times + " times", "blue");
	for i from 1 to times {
		if (!cli_execute("asdonmartin drive " + style))
			return false;
	}

	return true;
}


boolean multi_asdonmartin(string style, int times) {
	assert(isAsdonWorkshed(), "fueled_asdonmartin: no Asdon Martin in your workshed!");
	ensureAsdonMartinFuel(times * 37);
	return unfueled_asdonmartin(style, times);
}


// use the asdonmartin, fueling enough for the buff if we're not in ronin
boolean fueled_asdonmartin(string style, int minimumNumberOfTurns) {
	assert(isAsdonWorkshed(), "fueled_asdonmartin: no Asdon Martin in your workshed!");

	// inv elven hardtack; inv elven squeeze; inv unidentified jerky; inv white lightning; inv handful of nuts and berries;
	// fill up enough to handle the uses we're about to do
	int effect_turns = have_effect(to_effect("Driving " + style));
	int neededTurns = minimumNumberOfTurns - effect_turns;
	int toDrive = ceil(neededTurns / 30.0) + 1;

	if (neededTurns > 0)
		ensureAsdonMartinFuel(toDrive * 37);

	print("buffing " + toDrive + " times, total fuel required: " + (toDrive * 37) + " to get: " + minimumNumberOfTurns + " turns of style: " + style + " effect turns: " + effect_turns + " needed turns: " + neededTurns);
	return cli_execute_if_needed("asdonmartin drive " + style, to_effect("Driving " + style), minimumNumberOfTurns);
}


// does a fueledAsdonMartin() only if we aren't already driving some other buff
void safeFueledAsdonMartin(effect desiredEffect, int minTurns) {
	assert(isAsdonWorkshed(), "safeFueledAsdonMartin: no Asdon Martin in your workshed!");

	foreach idx, aDriveEffect in kDrivingStyles {
		if (aDriveEffect != desiredEffect && have_effect(aDriveEffect) > 0)
			return;
	}

	// fill up enough to handle the uses we're about to do
	int effect_turns = have_effect(desiredEffect);
	int neededTurns = minTurns - effect_turns;
	if (neededTurns > 0) {
		int toDrive = ceil(neededTurns / 30.0) + 1;
		ensureAsdonMartinFuel(toDrive * 37);
		print("buffing " + toDrive + " times, total fuel required: " + (toDrive * 37) + " to get: " + minTurns + " turns of style: " + desiredEffect + " effect turns: " + effect_turns + " needed turns: " + neededTurns);
	}

	cli_execute_if_needed("asdonmartin drive " + substring(desiredEffect, 8), desiredEffect, minTurns);
}



// return the current debuff that the micrometerorite skill does
float micrometerorite_percent() {
	return max(0.10, 0.25 - (get_property("_micrometeoriteUses").to_float() / 100.0));
}



// returns the location to find the given latte lovers member's mug ingredient
location latteGrindLocationForIngredient(string ingredient) {
	return kLatteLocations[ingredient];
}


// returns the latte lovers member's mug ingredient we might find at the given location (note that it might already be unlocked!)
string latteIngredientForLocation(location aLocation) {
	foreach ingredient, latteLocation in kLatteLocations {
		if (latteLocation == aLocation)
			return ingredient;
	}
	return "";
}


boolean isLatteIngredientUnlocked(string ingredient) {
	return get_property("latteUnlocks").contains_text(ingredient);
}


// returns true if we have the latte lovers member's mug ingredient that is unlocked by adventuring at aLocation
boolean isLatteLocationUnlocked(location aLocation) {
	return isLatteIngredientUnlocked(latteIngredientForLocation(aLocation));
}


// ease-of-use helper function for refilling latte lovers member's mug automatically
boolean refillLatteIfRequired(string ing1, string ing2, string ing3) {
	int latteRefillsAvailable = 3 - to_int(get_property("_latteRefillsUsed"));
	boolean latteBanishAvailable = !to_boolean(get_property("_latteBanishUsed"));
	if (!latteBanishAvailable && latteRefillsAvailable > 0) {
		return cli_execute("latte refill " + ing1 + " " + ing2 + " " + ing3);
	}
	return latteBanishAvailable;
}

// refills the latte lovers member's mug if required with priority ingredients (+item, +meat, +fam OR +adv)
// will refill with random default ingredients (+exp/+stats) if any of the priority items are not unlocked
// returns true if the latte is filled
boolean refillLatteIfRequired() {
	boolean cajunUnlocked = isLatteIngredientUnlocked("cajun");
	boolean carrotUnlocked = isLatteIngredientUnlocked("carrot");
	boolean rawhideUnlocked = isLatteIngredientUnlocked("rawhide");
	boolean guarnaUnlocked = isLatteIngredientUnlocked("guarna");

	int latteRefillsAvailable = 3 - to_int(get_property("_latteRefillsUsed"));
	boolean latteBanishAvailable = !to_boolean(get_property("_latteBanishUsed"));
	if (!latteBanishAvailable && latteRefillsAvailable > 0) {
		string ing1 = cajunUnlocked ? "cajun" : "cinnamon"; // +meat or mox
		string ing2 = carrotUnlocked ? "carrot" : "pumpkin"; // +item or mys
		string ing3 = rawhideUnlocked ? "rawhide" : "vanilla"; // +fam or mus
		if (latteRefillsAvailable == 1)
			ing3 = guarnaUnlocked ? "guarna" : "vanilla"; // +adv or mus
		return refillLatteIfRequired(ing1, ing2, ing3);
	}
	return latteBanishAvailable;
}



boolean onGuzzlrQuest() {
	if (get_property("questGuzzlr") == "unstarted")
		return false;
	return true;
}


// returns the number of combats at the Guzzlr quest location that will complete the quest
int guzzlrQuestTurns(boolean withShoes) {
	assert(onGuzzlrQuest(), "guzzlrQuestTurns: we're not on a Guzzlr quest!");
    int guzzlrQuestProgressLeft = 100 - get_property("guzzlrDeliveryProgress").to_int();
    float guzzlrQuestIncrement = max(3, 10 - get_property("_guzzlrDeliveries").to_int());
    float guzzlrQuestShoedIncrement = floor(1.5 * guzzlrQuestIncrement);
    int guzzlrQuestFightsLeft = ceil(guzzlrQuestProgressLeft / guzzlrQuestIncrement);
    int guzzlrQuestShoedFightsLeft = ceil(guzzlrQuestProgressLeft / guzzlrQuestShoedIncrement);

	if (withShoes)
		return guzzlrQuestShoedFightsLeft;
	else
		return guzzlrQuestFightsLeft;
}


void printGuzzlrQuest() {
	if (get_property("questGuzzlr") == "unstarted")
		print("No Guzzlr quest started!", "green");
	else
		print(get_property("guzzlrQuestTier") + " tier quest: go to " + get_property("guzzlrQuestLocation") + " and give a " + get_property("guzzlrQuestBooze"), "green");
	print("abandoned a quest: " + get_property("_guzzlrQuestAbandoned") + ", today's deliveries plat: " + get_property("_guzzlrPlatinumDeliveries") + ", gold: " + get_property("_guzzlrGoldDeliveries") + ", total deliveries today: " + get_property("_guzzlrDeliveries"), "green");
}


// choiceOption = 2 for bronze, 3 for gold, 4 for platinum
// returns true if we're on the selected tier of quest, whether we had to get a new quest or we're on it already
boolean getGuzzlrQuest(int choiceOption) {
	if (onGuzzlrQuest()) {
		print(get_property("guzzlrQuestTier") + " Guzzlr quest already started!", "red");
		printGuzzlrQuest();
		return choiceOption == 4 ? get_property("guzzlrQuestTier") == "platinum" : choiceOption == 3 ? get_property("guzzlrQuestTier") == "gold" : get_property("guzzlrQuestTier") == "bronze";
	}
	if (choiceOption == 3) { // gold
		if (to_int(get_property("_guzzlrGoldDeliveries")) >= 3) {
			print("Already done 3 gold Guzzlr quests!", "red");
			printGuzzlrQuest();
			return false;
		}
	} else if (choiceOption == 4) { // platinum
		if (to_int(get_property("_guzzlrPlatinumDeliveries")) >= 1) {
			print("Already done a platinum Guzzlr quest!", "red");
			printGuzzlrQuest();
			return false;
		}
	} else if (choiceOption != 2) { // bronze
		abort("incorrect choiceOption passed to getGuzzlrQuest");
	}

	visit_url("/inventory.php?tap=guzzlr", false, false);
	string pageString = run_choice(choiceOption);
	boolean success = pageString.contains_text("You select a ");
	if (success) {
		printGuzzlrQuest();
		set_property("_smm.GuzzlrLocationLockedWarningDone", "false");
	}
	return success;
}



boolean getGoldGuzzlrQuest() {
	if (onGuzzlrQuest()) {
		printGuzzlrQuest();
		return "guzzlrQuestTier".get_property() == "gold";
	}

	return getGuzzlrQuest(3);
}


// gets the next Guzzlr quest in descending order from platinum
// returns the quest tier (plat = 1, gold = 2, bronze = 3)
int getGuzzlrQuest() {
	int questTier = 3;
	int choiceOption = 2;

	if (onGuzzlrQuest()) {
		printGuzzlrQuest();
		string questTier = get_property("guzzlrQuestTier");
		return questTier == "platinum" ? 1 : questTier == "gold" ? 2 : 3;
	}

	if (get_property("_guzzlrPlatinumDeliveries").to_int() == 0) {
		questTier = 1;
		choiceOption = 4;
	} else if (get_property("_guzzlrGoldDeliveries").to_int() < 3) {
		questTier = 2;
		choiceOption = 3;
	}

	if (!getGuzzlrQuest(choiceOption))
		abort("failed getting a tier " + questTier + " guzzlr quest");
	return questTier;
}


void getAndCancelPlatinumGuzzlrQuest() {
	buffer pageText;
	string tweakOutfit = "";

	if ((get_property("questGuzzlr") == "unstarted") && (to_int(get_property("_guzzlrPlatinumDeliveries")) == 0))
		getGuzzlrQuest(4); // platinum

	if (get_property("guzzlrQuestTier") != "platinum") {
		print("getAndCancelPlatinumGuzzlrQuest: platinum quest already cancelled or a quest of a different tier is already started", "red");
		return;
	}

	// cancel the platinum quest and continue
	visit_url("/inventory.php?tap=guzzlr", false, false);
	run_choice(1);
	run_choice(5);
}



void summon_pants(string element_string, string sacrifice1, string sacrifice2, string sacrifice3) {
	if (have_item($item[pantogram pants])) {
		print("you already have your pants!");
		print_description($item[pantogram pants]);
		return;
	}

	string [stat] alignment_map = {
		$stat[muscle]:"1",
		$stat[mysticality]:"2",
		$stat[moxie]:"3"
	};
	string [string] element_map = {
		"hot":"1",
		"cold":"2",
		"spooky":"3",
		"sleaze":"4",
		"stench":"5"
	};
	string [string] sacrifice1_map = {
		"hp":"-1,0",
		"mp":"-2,0",
		"hp regen 1":to_int($item[red pixel potion]) + ",1",
		"hp regen 2":to_int($item[royal jelly]) + ",1",
		"hp regen 3":to_int($item[scented massage oil]) + ",1",
		"mp regen 1":to_int($item[cherry cloaca cola]) + ",1",
		"mp regen 2":to_int($item[bubblin' crude]) + ",1",
		"mp regen 3":to_int($item[glowing new age crystal]) + ",1",
		"-mp cost":to_int($item[baconstone]) + ",1",
		"red pixel potion":to_int($item[red pixel potion]) + ",1",
		"royal jelly":to_int($item[royal jelly]) + ",1",
		"scented massage oil":to_int($item[scented massage oil]) + ",1",
		"cherry cloaca cola":to_int($item[cherry cloaca cola]) + ",1",
		"bubblin' crude":to_int($item[bubblin' crude]) + ",1",
		"glowing new age crystal":to_int($item[glowing new age crystal]) + ",1",
		"baconstone":to_int($item[baconstone]) + ",1"
	};
	string [string] sacrifice2_map = {
		"weapon dmg":"-1,0",
		"spell dmg":"-2,0",
		"meat drop 1":to_int($item[taco shell]) + ",1",
		"meat drop 2":to_int($item[porquoise]) + ",1",
		"item drop 1":to_int($item[fairy gravy boat]) + ",1",
		"item drop 2":to_int($item[tiny dancer]) + ",1",
		"mus exp 1":to_int($item[knob goblin firecracker]) + ",3",
		"mys exp 1":to_int($item[razor-sharp can lid]) + ",3",
		"mox exp 1":to_int($item[spider web]) + ",3",
		"mus exp 2":to_int($item[synthetic marrow]) + ",5",
		"mys exp 2":to_int($item[haunted battery]) + ",5",
		"mox exp 2":to_int($item[the funk]) + ",5",
		"taco shell":to_int($item[taco shell]) + ",1",
		"porquoise":to_int($item[porquoise]) + ",1",
		"fairy gravy boat":to_int($item[fairy gravy boat]) + ",1",
		"tiny dancer":to_int($item[tiny dancer]) + ",1",
		"knob goblin firecracker":to_int($item[knob goblin firecracker]) + ",3",
		"razor-sharp can lid":to_int($item[razor-sharp can lid]) + ",3",
		"spider web":to_int($item[spider web]) + ",3",
		"synthetic marrow":to_int($item[synthetic marrow]) + ",5",
		"haunted battery":to_int($item[haunted battery]) + ",5",
		"the funk":to_int($item[the funk]) + ",5"
	};
	string [string] sacrifice3_map = {
		"-combat":"-1,0",
		"+combat":"-2,0",
		"init":to_int($item[bar skin]) + ",1",
		"crit":to_int($item[hamethyst]) + ",1",
		"fam":to_int($item[lead necklace]) + ",1",
		"candy":to_int($item[huge bowl of candy]) + ",1",
		"sea":to_int($item[sea salt crystal]) + ",1",
		"fishing":to_int($item[wriggling worm]) + ",1",
		"pool":to_int($item[8-ball]) + ",1",
		"avatar":to_int($item[moxie weed]) + ",1",
		"hilarity":to_int($item[ten-leaf clover]) + ",1",
		"bar skin":to_int($item[bar skin]) + ",1",
		"hamethyst":to_int($item[hamethyst]) + ",1",
		"lead necklace":to_int($item[lead necklace]) + ",1",
		"huge bowl of candy":to_int($item[huge bowl of candy]) + ",1",
		"sea salt crystal":to_int($item[sea salt crystal]) + ",1",
		"wriggling worm":to_int($item[wriggling worm]) + ",1",
		"8-ball":to_int($item[8-ball]) + ",1",
		"moxie weed":to_int($item[moxie weed]) + ",1",
		"ten-leaf clover":to_int($item[ten-leaf clover]) + ",1"
	};

	if (!(element_map contains element_string)) abort ("element_string value '" + element_string + "' unknown");
	if (!(sacrifice1_map contains sacrifice1)) abort ("sacrifice1 value '" + sacrifice1 + "' unknown");
	if (!(sacrifice2_map contains sacrifice2)) abort ("sacrifice2 value '" + sacrifice2 + "' unknown");
	if (!(sacrifice3_map contains sacrifice3)) abort ("sacrifice3 value '" + sacrifice3 + "' unknown");

	// visit the item link to prime the pump
	visit_url("/inv_use.php?which=3&pwd&whichitem=9573", true, false);

	string url_to_visit = "choice.php?whichchoice=1270&pwd&option=1&m=" + alignment_map[my_primestat()] +
																  "&e=" + element_map[element_string] +
																  "&s1=" + sacrifice1_map[sacrifice1] +
																  "&s2=" + sacrifice2_map[sacrifice2] +
																  "&s3=" + sacrifice3_map[sacrifice3];
	print("creating pantogram pants with: " + url_to_visit);
	visit_url(url_to_visit, true, false);

	if (!have_item($item[pantogram pants]))
		print("WARNING: pants not created, missing reagent?", "red");
	else
		print_description($item[pantogram pants]);
}



// is it safe to switch the january garbage tote to a different item without losing champagne charges
// TODO detect all charges spent
boolean isToteSwitchSafe() {
// 	return "_garbageItemChanged".get_property().to_boolean();
	boolean haveChampagneBottleCharges = have_item($item[broken champagne bottle]) && to_int(get_property("garbageChampagneCharge")) > 0;
	boolean changingWillEraseCharges = !to_boolean(get_property("_garbageItemChanged"));
	return !(haveChampagneBottleCharges && changingWillEraseCharges);
}



// prints the summary from the sausage-o-matic
void sausageSummary() {
	buffer grindSummary = visit_url("/inventory.php?action=grind", true, false);
	matcher desc_matcher = create_matcher("(It looks like your grinder needs .*? units\\.)", to_string(grindSummary));
	find(desc_matcher);
	print(group(desc_matcher, 1));
}


// use the Kramco sausage-o-matic to grind the given item and quantity
int sausageGrind(item grindItem, int qty) {
	buffer grind_page = visit_url("/choice.php?pwd&whichchoice=1339&option=1&qty=" + qty + "&iid=" + to_int(grindItem), true, false);
	matcher desc_matcher = create_matcher("filling counter increments by ([0-9,]+)", to_string(grind_page));
	find(desc_matcher);
	return to_int(group(desc_matcher, 1));
}


void grindForSausages() {
	assert(!inRonin(), "grindForSausages: use only in ronin -- grinds lots of things you care about");

	sausageSummary();
	int [item, string] grindMap;
	file_to_map("sausage_grind_map.txt", grindMap);
	foreach grindItem, pathName in grindMap {
		print("");
		int qty = available_amount(grindItem);
		if (qty > 0 && (pathName == "" || pathName == my_path())) {
			print("grinding " + grindItem + " x" + qty + "@" + grindMap[grindItem, pathName]);
			sausageGrind(grindItem, qty);
		}
	}
	sausageSummary();
}



// equip each familiar so that the shorter-order cook benefit happens
// presumably helps with maximize
void cycleFavouriteFamiliars() {
	use_familiar($familiar[Shorter-Order Cook]);
	if (have_item($item[blue plate]))
		equip($item[blue plate]);

	if (equipped_amount($item[blue plate]) == 0 && !user_confirm("The Shorter-Order Cook isn't equipped with a blue plate... continue anyway?", 60000, true))
		abort("cycleFavouriteFamiliars");

	foreach fam in favorite_familiars() {
		use_familiar(fam);
	}
}



string getFloundrySpots() {
	assert(vipLoungeAvailable(), "can't access clan VIP lounge");

	if (get_property(kFloundrySpotsKey) == "") {
		buffer page = visit_url("/clan_viplounge.php?action=floundry", true, false);
		matcher desc_matcher = create_matcher("(<b>Good fishing spots today:.*?)</td>", to_string(page));

		assert(find(desc_matcher), "unable to find fishing spots");
		string rval = group(desc_matcher, 1);
		print("found good fishing spots: " + rval, "green");
		set_property(kFloundrySpotsKey, rval);
	}

	return get_property(kFloundrySpotsKey);
}

void printFloundrySpots() {
	print_html(getFloundrySpots());
}


boolean isFloundryLocation(location testLocation) {
	string page = getFloundrySpots();
	matcher desc_matcher = create_matcher(to_string(testLocation), page);
	if (find(desc_matcher))
		return true;
	return false;
}



// get the beach comb effect associated with the given choice number
void getBeachCombBuff(int effectNumber) {
	visit_url("/main.php?comb=1");
	visit_url("/choice.php?whichchoice=1388&pwd&option=3&buff=" + effectNumber);
	run_choice(5);
}


// save savAmt free beach combs and burn the rest #beachcomber #beach comber #beachcombing #beach combing #combbeach #comb beach
void burnFreeCombs(int saveAmt) {
	boolean unused;
	int combs = 11 - get_property("_freeBeachWalksUsed").to_int() - saveAmt;
	if (combs > 0)
		unused = cli_execute("combo " + combs);
}



int spacegateEnergy() {
	string thePage = visit_url("/place.php?whichplace=spacegate&action=sg_Terminal");
	matcher energyMatcher = create_matcher("Spacegate Energy remaining: <b><font size=\\+2>([0-9][0-9]?) </font></b>Adventures", thePage);
	if (!find(energyMatcher))
		return 20;
	int energyLeft = group(energyMatcher, 1).to_int();
	set_property("_spacegateTurnsLeft", energyLeft);
	return energyLeft;
}



int pocketProfessorLectures(int weight) {
	int rval = floor(square_root(weight - 1.0) + 1.0);
	if (familiar_equipped_equipment($familiar[Pocket Professor]) == $item[Pocket Professor memory chip])
		rval += 2;
	return rval;
}

int pocketProfessorLectures() {
	return pocketProfessorLectures(familarWeight($familiar[Pocket Professor]));
}

int pocketProfessorLecturesAvailable() {
	return max(0, pocketProfessorLectures() - to_int(get_property("_pocketProfessorLectures")));
}

// uses the results of a simulated maximize to see the potential
int pocketProfessorLecturesPossiblyAvailable() {
	int base = familiar_weight($familiar[Pocket Professor]);
	int adj = numeric_modifier("Generated:_spec", "Familiar Weight");
	return pocketProfessorLectures(base + adj) - to_int(get_property("_pocketProfessorLectures"));
}



int baseCombatsToNextCatBurglarHeist() {
	int nextDrop = 10;
	int catBurglarCharge = to_int(get_property("_catBurglarCharge"));

	while (catBurglarCharge > nextDrop) {
		catBurglarCharge -= nextDrop;
		nextDrop *= 2;
	}

	return nextDrop;
}

int progressToNextCatBurglarHeist() {
	int nextDrop = 10;
	int catBurglarCharge = to_int(get_property("_catBurglarCharge"));

	while (catBurglarCharge > nextDrop) {
		catBurglarCharge -= nextDrop;
		nextDrop *= 2;
	}

	return catBurglarCharge;
}



int backupCameraUses() {
	return to_int(get_property("_backUpUses"));
}

int backupCameraUsesAvailable() {
	return 11 - backupCameraUses();
}



phylum snapperGuideMeToPhylum() {
	string snapperGuideMe = get_property("redSnapperPhylum");
	if (snapperGuideMe == "merkin") snapperGuideMe = "mer-kin";
	return to_phylum(snapperGuideMe);
}


void setRedNosedSnapperGuideMe(string aPhylum) {
// 	assert(my_familiar() == $familiar[Red-nosed Snapper]) "setting snapper's 'guide me' without the snapper equipped");
	if (my_familiar() != $familiar[Red-nosed Snapper])
		use_familiar($familiar[Red-nosed Snapper]);

	string propertyValue = aPhylum;
	if (aPhylum == "merkin") propertyValue = "mer-kin";
	if (aPhylum == "mer-kin") aPhylum = "merkin";

	if (get_property("redSnapperPhylum") != propertyValue) {
		visit_url('familiar.php?action=guideme&pwd', true, false);
		assert(handling_choice(), "setRedNosedSnapperGuideMe: should be handling a choice at this point");
		visit_url('choice.php?pwd&whichchoice=1396&option=1&cat=' + aPhylum, true, false);
	}
}



// fight the given monster, which must be one that we've already fought at least once this ascension
string timespinnerRecentFight(monster toFight) {
// 	use(1, $item[Time-Spinner]); // this doesn't get things started correctly for some reason
	visit_url("/inv_use.php?pwd&which=99&whichitem=9104&ajax=1", true, false);

	string aPage = run_choice(1); // return to a previous fight

	// testString will be present in the page if we've fought the monster before
	string testString = "<option value=\"" + to_int(toFight) + "\">" + toFight + "</option>";
	if (!aPage.contains_text(testString)) {
		run_choice(2); // maybe later
		return "";
	}

	return visit_url("/choice.php?pwd&whichchoice=1196&option=1&monid=" + to_int(toFight), true, false); // select the monster to fight
}


monster [] timespinnerRecentFightEconomics(boolean doPrint) {
	monster [int] rval;
	int idx;

	visit_url("/inv_use.php?pwd&which=99&whichitem=9104&ajax=1", true, false);
	string aPage = run_choice(1); // return to a previous fight
	run_choice(2); // "maybe later" get out of the choice

	matcher fightOptionMatcher = create_matcher("<option value=\"([0-9]+)\">(.+?)</option>", aPage);
	while (find(fightOptionMatcher)) {
		string optionString = group(fightOptionMatcher, 1);
		string nameString = group(fightOptionMatcher, 2);
		monster amon = optionString.to_int().to_monster();
		if (amon == $monster[none])
		    amon = group(fightOptionMatcher, 2).to_monster();
		assert(amon != $monster[none] || nameString == "-- Recall a monster before you spin the spinner. --", "didn't get a monster for string: " + nameString + ", id: " + optionString);
		rval[idx++] = amon;
	}

	sort rval by -value.monsterCurrentTotalMeatValue(false);

	if (doPrint)
		foreach i, amon in rval
			print("[" + amon.to_int() + "]" + amon + " @ " + amon.monsterCurrentTotalMeatValue(false));

	return rval;
}

monster [] timespinnerRecentFightEconomics() {
	return timespinnerRecentFightEconomics(true);
}



boolean canConsultColdMedicineCabinet() {
	int consultsRemaining = 5 - get_property("_coldMedicineConsults").to_int();
	int nextColdMedicineConsult = get_property("_nextColdMedicineConsult").to_int();
	return isColdMedicineWorkshed() && consultsRemaining > 0 && nextColdMedicineConsult <= total_turns_played();
}


// returns a ChoiceRecord for each CMC choice option with the item (not the Doctor Name) as the choiceString
ChoiceRecord [] coldMedicineCabinet(boolean shouldPrint) {
	ChoiceRecord [int] rval;
	string cabinetPage = visit_url("/campground.php?action=workshed", false, false); // use post?, encoded?

	string [int] itemStrings = xpath(cabinetPage, "//form//table//tr//td//table//tr//td//b/text()");
	foreach idx, itemString in itemStrings {
		ChoiceRecord cr = new ChoiceRecord(++idx, itemString);
		rval[idx] = cr;
		item it = itemString.to_item();
		if (shouldPrint) print(idx + ": " + itemString + " @ " + cheapest_price(it));
	}

	return rval;
}

ChoiceRecord [] coldMedicineCabinet() {
	return coldMedicineCabinet(true);
}


// TODO fix this: static map doesn't work, need to build dynamically based on sniffing the items from the HTML
void getColdMedicineCabinetMedication() {
	int consultsRemaining = 5 - get_property("_coldMedicineConsults").to_int();
	int nextColdMedicineConsult = get_property("_nextColdMedicineConsult").to_int();
	print("coldMedicineCabinet consultsRemaining: " + consultsRemaining + " nextColdMedicineConsult=" + nextColdMedicineConsult + " (current turncount: " + total_turns_played() + ")", "green");
	if (!canConsultColdMedicineCabinet())
		abort("can't consult coldMedicineCabinet");

	ChoiceRecord [] cmcItems = coldMedicineCabinet(false);
	sort cmcItems by -mall_price(to_item(value.choiceString));
	foreach idx, cr in cmcItems {
		print("coldMedicineCabinet getting choice " + cr.choiceNum + ": " + cr.choiceString + " worth " + mall_price(cr.choiceString.to_item()), "blue");
		run_choice(cr.choiceNum);
		break;
	}
}



// returns the number of turns the NEXT cosmic bowling ball use will last
int cosmicBowlingBallDuration() {
	return 2 * get_property("_cosmicBowlingSkillsUsed").to_int() + 3;
}


// returns the number of turns until the cosmic bowling ball returns or -1 if it's in our inventory
int cosmicBowlingBallReturnCombats() {
	return get_property("cosmicBowlingBallReturnCombats").to_int();
}



// combat lover's locket #combat locket #combatlocket

// returns the monsters we've fought with the combat lover's locket, 3 per day, each has to be unique
boolean [monster] cllMonstersFought(boolean shouldPrint) {
	boolean [monster] rval;
	string monstersFoughtString = get_property("_locketMonstersFought");
	string [] monstersFought = monstersFoughtString.split_string(",");
	if (shouldPrint) print("monsters fought with the combat lover's locket:");
	foreach idx, monString in monstersFought {
		monster aMonster = monString.to_monster();
		if (aMonster == $monster[none]) continue; // empty string (no reminiscences) or an unrecognized entry: skip it, keep the rest
		rval[aMonster] = true;
		if (shouldPrint) print(aMonster);
	}
	return rval;
}

boolean [monster] cllMonstersFought() {
	return cllMonstersFought(true);
}

int cllNumMonstersFought() {
	return count(cllMonstersFought(false));
}


boolean cllHasFought(monster amon) {
	return cllMonstersFought(false) contains amon;
}


void cllReminiscenceClearCache() {
	remove_property("_smm.CLLMonsters");
}


boolean [monster] cllLocalReminiscence(location atLocation) {
	boolean [monster] rval;
	boolean [monster] cllReminiscences = cllReminiscences();

	foreach aMonster, rate in appearance_rates(atLocation) {
		if (aMonster != $monster[none] && rate > 0.0 && (cllReminiscences contains aMonster))
			rval[aMonster] = true;
	}
	return rval;
}


void printCLLReminiscences() {
	print("all combat locket reminiscences:");
	printMonsterArray(cllReminiscences());
}

void printCLLNoReminiscences() {
	print("missing combat locket reminiscences:");
	foreach amon in $monsters[] {
		if (!amon.boss && !cllHasReminiscence(amon))
			print("[" + amon.to_int() + "]" + amon);
	}
}

void printCLLLocalReminiscence(location atLocation) {
	print("combat locket reminiscences in [" + atLocation.to_int() + "]" + atLocation + ":");
	printMonsterArray(cllLocalReminiscence(atLocation));
}


boolean [monster] cllLocalNoReminiscence(location atLocation) {
	boolean [monster] rval;

	// these locations don't have any knowable reminiscences -- can't detect these any other way right now
	if (atLocation == $location[Dreadsylvanian Woods] ||atLocation == $location[Dreadsylvanian Village] ||atLocation == $location[Dreadsylvanian Castle])
		return rval;

	boolean [monster] cllReminiscences = cllReminiscences();
	foreach aMonster, rate in appearance_rates(atLocation) {
		if (aMonster != $monster[none] && rate > 0.0 && !aMonster.boss
			&& !(cllReminiscences contains aMonster))
			rval[aMonster] = true;
	}
	return rval;
}

void printCLLLocalNoReminiscence(location atLocation) {
	print("missing combat locket reminiscences in [" + atLocation.to_int() + "]" + atLocation + ":");
	printMonsterArray(cllLocalNoReminiscence(atLocation));
}


void printCLLReminiscencesMatching(string monsterMatchString) {
	print("combat locket reminiscences matching '" + monsterMatchString + "':");

	boolean [monster] matchingRems;
	foreach amon in cllReminiscences() {
		string amonString = amon.to_lower_case();
		string matchingString = monsterMatchString.to_lower_case();
		if (amonString.contains_text(matchingString))
			matchingRems[amon] = true;
	}

	printMonsterArray(matchingRems);
}


monster [] cllNoReminiscencesMatchingPhylum(phylum matchingPhylum, boolean doPrint) {
	cprint(doPrint, "missing combat locket reminiscences matching phylum " + matchingPhylum + ":", "green");

	boolean [monster] matchingRems;
	monster [int] rval;
	boolean [monster] allRem = cllReminiscences();
	monster [int] monstersMatching = monstersMatchingPhylum(matchingPhylum, false);
	int idx;
	foreach idx, amon in monstersMatching {
		if (!amon.boss && !(allRem contains amon)) {
			matchingRems[amon] = true;
			rval[idx++] = amon;
		}
	}

	if (doPrint)
		printMonsterArray(matchingRems);
	return rval;
}


monster [] cllReminiscencesMatchingPhylum(phylum matchingPhylum, boolean doPrint) {
	cprint(doPrint, "combat locket reminiscences matching phylum " + matchingPhylum + ":");

	boolean [monster] matchingRems;
	monster [int] rval;
	int idx;
	foreach amon in cllReminiscences() {
		if (amon.monster_phylum() == matchingPhylum) {
			matchingRems[amon] = true;
			rval[idx++] = amon;
		}
	}

	if (doPrint)
		printMonsterArray(matchingRems);
	return rval;
}

monster [] cllReminiscencesMatchingPhylum(phylum matchingPhylym) {
	return cllReminiscencesMatchingPhylum(matchingPhylym, true);
}


monster [int] combatLoversLocketonomics(boolean doPrint) {
	boolean [monster] allMons = cllReminiscences();
	monster [int] sortableMons;
	int idx;
	foreach amon in allMons {
		sortableMons[idx++] = amon;
	}
	sort sortableMons by -value.monsterCurrentTotalMeatValue(false);

	if (doPrint)
		print("value of each combat lover's locket reminiscence at current +item/+meat: +" + item_drop_modifier().to_string("%.1f") + "% / +" + meat_drop_modifier().to_string("%.1f") + "%");

	foreach ind, amon in sortableMons {
		int monMeat = amon.monsterCurrentTotalMeatValue(false);
		if (doPrint)
			print(amon + ": " + monMeat);
	}
	if (doPrint)
		print("total monsters: " + idx);

	return sortableMons;
}

monster [int] combatLoversLocketonomics() {
	return combatLoversLocketonomics(true);
}



void sendAutumnaton() {
	boolean unused = cli_execute("autumnaton upgrade");
	string [] upgrades = split_string(get_property("autumnatonUpgrades"), ",");
	location [] orderedArray;
	location goTo;

	foreach idx, upgrade in kAutumnatonDesiredUpgrades {
		if ( ! arrayContains(upgrades, upgrade)) {
			print("sendAutumnaton: need upgrade: " + upgrade, "blue");
			boolean [location] testArray;
			foreach idx2, aloc in kAutumnatonUpgradeLocations[upgrade]
				testArray[aloc] = true;
			orderedArray = locationBaseEconomics(testArray, false, true);
			break;
		}
	}

	boolean [location] badLocs = { //  locations we can't get to if we're not in Ronin (which is the only time we'll be automatically sending the bot)
		$location[The Defiled Nook]: true, $location[The Defiled Cranny]: true, $location[The Defiled Alcove]: true, $location[The Defiled Niche]: true,
	};

	// return the highest value location, but don't return locations we can't reach
	int locIndex = 0;
	while (goTo == $location[none]) {
		if (count(orderedArray) == locIndex) { // default if we somehow run out of locations
			goTo = kAutumnatonLocation;
			break;
		}
		if (badLocs contains orderedArray[locIndex]) {
			locIndex++;
			continue;
		}
		goTo = orderedArray[locIndex];
	}

	cli_execute("autumnaton send " + goTo);
}


item [int] _gkTeaTreeItems;

item [] teaTreeItems() {
	if (count(_gkTeaTreeItems) == 0) {
		_gkTeaTreeItems = {
			$item[cuppa Activi tea],
			$item[cuppa Alacri tea],
			$item[cuppa Boo tea],
			$item[cuppa Chari tea],
			$item[cuppa Craft tea],
			$item[cuppa Cruel tea],
			$item[cuppa Dexteri tea],
			$item[cuppa Feroci tea],
			$item[cuppa Flamibili tea],
			$item[cuppa Flexibili tea],
			$item[cuppa Frost tea],
			$item[cuppa Gill tea],
			$item[cuppa Impregnabili tea],
			$item[cuppa Improprie tea],
			$item[cuppa Insani tea],
			$item[cuppa Irritabili tea],
			$item[cuppa Loyal tea],
			$item[cuppa Mana tea],
			$item[cuppa Mediocri tea],
			$item[cuppa Monstrosi tea],
			$item[cuppa Morbidi tea],
			$item[cuppa Nas tea],
			$item[cuppa Net tea],
			$item[cuppa Neuroplastici tea],
			$item[cuppa Obscuri tea],
			$item[cuppa Physicali tea],
			$item[cuppa Proprie tea],
			$item[cuppa Royal tea],
			$item[cuppa Serendipi Tea],
			$item[cuppa Sobrie tea],
			$item[cuppa Toast tea],
			$item[cuppa Twen tea],
			$item[cuppa Uncertain tea],
			$item[cuppa Vitali tea],
			$item[Cuppa Voraci tea],
			$item[cuppa Wit tea],
			$item[cuppa Yet tea],
		};
	}

	return _gkTeaTreeItems;
}

item [] bestTeaTree(boolean shouldPrint) {
	item [int] rval;
	int [item] lookupData;
	item [int] sortingData;
	int totalValue;
	foreach idx, it in teaTreeItems() {
		sortingData[idx] = it;
		totalValue += current_price(it);
	}

	sort sortingData by -value.current_price();

	int averageValue = totalValue / count(sortingData);
	int bestValue = current_price(sortingData[0]);
	cprint(shouldPrint, "best value: " + bestValue + ", 3*avg value: " + averageValue);

	rval[0] = sortingData[0];
	cprint(shouldPrint, rval[0]);
	if (bestValue < averageValue * 3) {
		rval[1] = sortingData[1];
		rval[2] = sortingData[2];
		cprint(shouldPrint, rval[1]);
		cprint(shouldPrint, rval[2]);
	}

	return rval;
}



// lazy init
item [int] _gkCargoCultistShortsPocketItems;

item [int] cargoCultistShortsPocketItems() {
	if (count(_gkCargoCultistShortsPocketItems) == 0) {
		_gkCargoCultistShortsPocketItems = {
			533 : $item[greasy desk bell],
			587 : $item[frost-rimed desk bell],
			590 : $item[uncanny desk bell],
			653 : $item[nasty desk bell],
			517 : $item[sizzling desk bell],

			567 : $item[alabaster bishop],
			523 : $item[alabaster king],
			275 : $item[alabaster knight],
			46 : $item[alabaster pawn],
			651 : $item[alabaster queen],
			111 : $item[alabaster rook],
			537 : $item[onyx bishop],
			88 : $item[onyx king],
			4 : $item[onyx knight],
			105 : $item[onyx pawn],
			506 : $item[onyx queen],
			197 : $item[onyx rook],

			284 : $item[Yeg's Motel toothbrush],
			177 : $item[Yeg's Motel hand soap],
			26 : $item[Yeg's Motel mouthwash],
			439 : $item[Yeg's Motel pillow mint],
			660 : $item[Yeg's Motel minibar key],
			121 : $item[Yeg's Motel alarm clock],
			642 : $item[Yeg's Motel sewing kit],
			409 : $item[Yeg's Motel ashtray],
			322 : $item[Yeg's Motel disposable razor],
			130 : $item[Yeg's Motel stationery],

			381 : $item[chocolate seal-clubbing club],
			477 : $item[chocolate turtle totem],
			654 : $item[chocolate pasta spoon],
			438 : $item[chocolate saucepan],
			430 : $item[chocolate disco ball],
			189 : $item[chocolate stolen accordion],
			331 : $item[extra-fancy ring setting],
			144 : $item[heavy necklace chain],
			403 : $item[precious piercing post],
			27 : $item[baconstone],
			510 : $item[blue pixel],
			167 : $item[green pixel],
			301 : $item[red pixel],
			184 : $item[star],
			199 : $item[line],
			50 : $item[fruitfilm],
			252 : $item[gnoll teeth],
			187 : $item[handful of bees],
			350 : $item[handful of drink tickets],
			28 : $item[handful of honey],
			481 : $item[handful of juicy garbage],
			158 : $item[handful of moss],
			129 : $item[handful of numbers],
			541 : $item[handful of sawdust],
			91 : $item[handful of sand],
			116 : $item[honey-dipped locust],
			569 : $item[loose teeth],
			631 : $item[rusty metal key],
			196 : $item[skeleton key],

			141 : $item[ancient vinyl coin purse],
			338 : $item[black pension check],
			157 : $item[collection of tiny spooky objects],
			281 : $item[CSA discount card],
			600 : $item[cursed piece of thirteen],
			38 : $item[fat wallet],
			512 : $item[Gathered Meat-Clip],
			109 : $item[handful of tips],
			419 : $item[old coin purse],
			417 : $item[old leather wallet],
			524 : $item[SMOOCH bottlecap],
			434 : $item[Warm Subject gift certificate],

			335 : $item[black paisley oyster egg],
			356 : $item[black plastic oyster egg],
			618 : $item[black polka-dot oyster egg],
			190 : $item[black striped oyster egg],
			212 : $item[blue paisley oyster egg],
			629 : $item[blue plastic oyster egg],
			475 : $item[blue polka-dot oyster egg],
			427 : $item[blue striped oyster egg],
			661 : $item[lavender paisley oyster egg],
			51 : $item[lavender plastic oyster egg],
			574 : $item[lavender polka-dot oyster egg],
			445 : $item[lavender striped oyster egg],
			276 : $item[mauve paisley oyster egg],
			255 : $item[mauve plastic oyster egg],
			622 : $item[mauve polka-dot oyster egg],
			453 : $item[mauve striped oyster egg],
			14 : $item[off-white paisley oyster egg],
			581 : $item[off-white plastic oyster egg],
			473 : $item[off-white polka-dot oyster egg],
			294 : $item[off-white striped oyster egg],
			3 : $item[puce paisley oyster egg],
			390 : $item[puce plastic oyster egg],
			605 : $item[puce polka-dot oyster egg],
			492 : $item[puce striped oyster egg],
			308 : $item[red paisley oyster egg],
			462 : $item[red plastic oyster egg],
			534 : $item[red polka-dot oyster egg],
			415 : $item[red striped oyster egg],
			313 : $item[yellow paisley oyster egg],
			223 : $item[yellow plastic oyster egg],
			137 : $item[yellow polka-dot oyster egg],
			315 : $item[yellow striped oyster egg],

			81 : $item[candy cane],
			122 : $item[ghuol egg],
			557 : $item[goat cheese],
			17 : $item[Handful of nuts and berries],
			429 : $item[handful of walnuts],
			485 : $item[nanite-infested candy cane],
			478 : $item[pigeon egg],
			268 : $item[blackberry],
			570 : $item[cherry],
			249 : $item[cranberries],
			489 : $item[grapefruit],
			413 : $item[grapes],
			65 : $item[kiwi],
			474 : $item[kumquat],
			33 : $item[lemon],
			300 : $item[lime],
			29 : $item[orange],
			41 : $item[papaya],
			599 : $item[raspberry],
			376 : $item[strawberry],
			396 : $item[tangerine],

			324 : $item[flask of moonshine],
			233 : $item[bottle of gin],
			426 : $item[bottle of rum],
			374 : $item[bottle of tequila],
			292 : $item[bottle of vodka],
			327 : $item[bottle of whiskey],
			94 : $item[boxed wine],
			324 : $item[flask of moonshine],

			310 : $item[Cold Hots candy],
			248 : $item[Comet Drop],
			636 : $item[cursed chocolate doubloon],
			287 : $item[daub-breaker],
			389 : $item[Drizzlers&trade; Black Licorice],
			627 : $item[dubious peppermint],
			265 : $item[elderly jawbreaker],
			546 : $item[Elvish delight],
			355 : $item[Everlasting Deckswabber],
			643 : $item[Finnish Fish],
			142 : $item[frostbite-flavored Hob-O],
			472 : $item[fry-oil-flavored Hob-O],
			491 : $item[Gabarbar],
			423 : $item[garbage-juice-flavored Hob-O],
			662 : $item[Glo-Pop],
			467 : $item[Good 'n' Slimy],
			483 : $item[government-issued candy],
			145 : $item[Gummi-DNA],
			455 : $item[Gummi-Gnauga],
			532 : $item[handful of hand chalk],
			493 : $item[handful of pine needles],
			173 : $item[Hersey&trade; SMOOCH],
			20 : $item[holly-flavored Hob-O],
			325 : $item[honey stick],
			518 : $item[Hot 'n' Scarys],
			460 : $item[leftover chocolate bar],
			286 : $item[licorice snake],
			74 : $item[Mallomarbles],
			280 : $item[marshroom],
			572 : $item[mutated candy lump],
			463 : $item[mystery lollipop],
			208 : $item[nasty gum],
			604 : $item[Necbro wafers],
			566 : $item[Now and Earlier],
			571 : $item[orange and black Crimboween candy],
			456 : $item[Pain Dip],
			525 : $item[piece of after eight],
			83 : $item[pile of candy],
			19 : $item[pixellated candy heart],
			392 : $item[PlexiPips],
			237 : $item[Pneumo bar],
			203 : $item[polyeaster egg],
			175 : $item[porcelain candy dish],
			639 : $item[rainbow jellybean],
			369 : $item[ribbon candy],
			106 : $item[Rock Pops],
			71 : $item[Senior Mints],
			304 : $item[Shrubble Bubble],
			101 : $item[Spechunky bar],
			346 : $item[Steal This Candy],
			397 : $item[Sterno-flavored Hob-O],
			93 : $item[strawberry-flavored Hob-O],
			76 : $item[Sugar Cog],
			450 : $item[sugar sphere],
			75 : $item[sugar-coated pine cone],
			229 : $item[Take Eleven Bar],
			333 : $item[Tallowcreme Halloween Pumpkin],
			311 : $item[Tasty Fun Good rice candy],
			649 : $item[violent pastilles],
			67 : $item[virgin jello shot],
			16 : $item[Wax Flask],
			25 : $item[Whenchamacallit bar],
			630 : $item[Wickers bar],
			404 : $item[Wint-O-Fresh mint],
			548 : $item[worst candy],
			488 : $item[Wrotz],
			217 : $item[Yolo&trade; chocolates],

			262 : $item[8-bit banana],
			146 : $item[abandoned candy],
			22 : $item[Aerheads],
			431 : $item[alphabet gum],
			580 : $item[Angry Farmer's Wife Candy],
			63 : $item[Atomic Pop],
			399 : $item[Bit O' Ectoplasm],
			79 : $item[Bit O' Quail Spleen],
			353 : $item[bone bons],
			60 : $item[Boss Drops],
			44 : $item[candied kobold],
			123 : $item[candy brain],
			169 : $item[candy chalk],
			87 : $item[candy crayons],
			414 : $item[candy skeleton],
			362 : $item[candy UFOs],
			529 : $item[children of the candy corn],
			578 : $item[chocolate filthy lucre],
			298 : $item[chocolate-covered caviar],
			78 : $item[cocoa chondrule],

			344 : $item[alien autoautopsy kit],
			351 : $item[bucket of fish juice],
			601 : $item[child-sized dracula cloak],
			536 : $item[conjured ice cream],
			8 : $item[creepy nursery rhyme],
			113 : $item[ectoplasm <i>au jus</i>],
			411 : $item[eldritch dough],
			498 : $item[enchanted muesli],
			408 : $item[forest spirit rattle],
			348 : $item[glass of warm milk],
			597 : $item[haunted flame],
			407 : $item[Illuminati earpiece],
			366 : $item[infrablack lipstick],
			495 : $item[ravenous eye],
			55 : $item[red-hot jawbreaker],
			168 : $item[shamanic ham],
			354 : $item[Shivering Ch&egrave;vre],
			616 : $item[skeletal banana],
			594 : $item[skeleton beans],
			476 : $item[Smart Bone Dust],
			607 : $item[tiny canopic jar],
			303 : $item[tube of villain white],
			135 : $item[unholy water],
			559 : $item[vial of swamp vapors],
		};
	}

	return _gkCargoCultistShortsPocketItems;
}



boolean [int] cargoPocketsEmptied(boolean shouldPrint) {
	boolean [int] rval;
	string [int] itemIds = get_property("cargoPocketsEmptied").split_string(",");
	foreach idx, idString in itemIds {
		int itID = idString.to_int();
		rval[itID] = true;
		if (cargoCultistShortsPocketItems() contains itID)
			cprint(shouldPrint, "pocket # " + idString + ": " + cargoCultistShortsPocketItems()[itID] + " @ " + cheapest_price(cargoCultistShortsPocketItems()[itID]));
		else
			cprint(shouldPrint, "pocket # " + idString + ": unknown");
	}
	return rval;
}

boolean [int] cargoPocketsEmptied() {
	return cargoPocketsEmptied(true);
}


int [] bestCargoPockets(boolean shouldPrint) {
	int [int] rval;
	int [item] lookupData;
	item [int] sortingData;
	foreach idx, it in cargoCultistShortsPocketItems() {
		lookupData[it] = idx;
		sortingData[idx] = it;
	}

	sort sortingData by -value.current_price();

	boolean [int] emptyPockets = cargoPocketsEmptied(false);

	int i;
	foreach idx, it in sortingData {
		int itNum = it.to_int();
		int pocketNum = lookupData[it];
		boolean isEmpty = emptyPockets contains pocketNum;
		if (!isEmpty) {
			cprint(shouldPrint, "pocket # " + pocketNum + ": " + it + " @ " + current_historical_price(it));
			rval[i++] = pocketNum;
		}
	}

	return rval;
}

int [] bestCargoPockets() {
	return bestCargoPockets(true);
}

int bestCargoPocket() {
	return bestCargoPockets(false)[0];
}



// group = -1 for all
boolean [item] iRefuseItems(int group) {
	item [] kIRefuseGroup1 = {$item[barbed-wire fence],
		$item[bat guano],
		$item[batgut],
		$item[big rock],
		$item[briefcase],
		$item[cog],
		$item[dead guy's piece of double-sided tape],
		$item[empty meat tank],
		$item[fat stacks of cash],
		$item[ghuol egg],
		$item[gnoll teeth],
		$item[hemp string],
		$item[hermit permit],
		$item[ice-cold fotie],
		$item[ice-cold sir schlitz],
		$item[ice-cold six-pack],
		$item[ice-cold Willer],
		$item[lihc eye],
		$item[loose teeth],
		$item[meat from yesterday],
		$item[pretty flower],
		$item[rat appendix],
		$item[rusty metal ring],
		$item[rusty metal shaft],
		$item[skeleton bone],
		$item[skewer],
		$item[spring],
		$item[sprocket],
		$item[ten-leaf clover],
		$item[uncooked chorizo],
		$item[valuable trinket],
		$item[worthless gewgaw],
		$item[worthless knick-knack],
		$item[worthless trinket]};
	item [] kIRefuseGroup2 = {$item[asbestos crossbow string],
		$item[asbestos stick],
		$item[asbestos sword hilt],
		$item[beer lens],
		$item[bloody clown pants],
		$item[box],
		$item[cast],
		$item[catgut],
		$item[chrome crossbow string],
		$item[chrome stick],
		$item[chrome sword hilt],
		$item[dead guy's watch],
		$item[disease],
		$item[enormous belt buckle],
		$item[flaming crutch],
		$item[hippopotamus skin],
		$item[leather mask],
		$item[linoleum crossbow string],
		$item[linoleum stick],
		$item[linoleum sword hilt],
		$item[Mad Train wine],
		$item[mesh cap],
		$item[mullet wig],
		$item[penguin skin],
		$item[pine-fresh air freshener],
		$item[pirate pelvis],
		$item[pr0n legs],
		$item[Ralph IX cognac],
		$item[razor-sharp can lid],
		$item[tenderizing hammer],
		$item[white lightning],
		$item[yak skin],
		$item[yeti fur]};
	item [] kIRefuseGroup3 = {$item[alphabet gum],
		$item[blood flower],
		$item[broken skull],
		$item[dirty hobo gloves],
		$item[disturbing fanfic],
		$item[felt],
		$item[filthy hippy poncho],
		$item[filthy poultice],
		$item[foon],
		$item[fruitcake],
		$item[furry pants],
		$item[gob of wet hair],
		$item[googly eye],
		$item[lead necklace],
		$item[length of string],
		$item[lovecat tail],
		$item[mob penguin cellular phone],
		$item[old coin purse],
		$item[old leather wallet],
		$item[picture of a dead guy's girlfriend],
		$item[pine tar],
		$item[plastic passion fruit],
		$item[[2108]rock],
		$item[sleaze nuggets],
		$item[spiked femur],
		$item[squashed frog],
		$item[stench powder],
		$item[stick],
		$item[stringy sinew],
		$item[stuffing],
		$item[tasket],
		$item[tooth],
		$item[urinal cake],
		$item[wooden block]};

	boolean [item] rval;

	if (group == 1 || group == -1)
		foreach idx, it in kIRefuseGroup1
			rval[it] = true;

	if (group == 2 || group == -1)
		foreach idx, it in kIRefuseGroup2
			rval[it] = true;

	if (group == 3 || group == -1)
		foreach idx, it in kIRefuseGroup3
			rval[it] = true;

	return rval;
}


void iRefuseEconomics() {
	int totalValue;
	foreach it in iRefuseItems(-1) {
		int itValue = cheapest_price(it);
		print(it + " @ " + cheapest_price(it));
	}
}


void printIRefuseSessionItems() {
	print("I Refuse! items acquired this session:");
	int totalValue;
	foreach it in iRefuseItems(-1) {
		int seshAmt = my_session_items(it);
		if (seshAmt > 0) {
			int itValue = cheapest_price(it);
			int gain = itValue * seshAmt;
			print(it + " @ " + cheapest_price(it) + ": " + seshAmt + ", total: " + gain);

			totalValue += gain;
		}
	}
	print("total value acquired: " + totalValue);
}



string sweetSynthesisHelper(item candyA, item candyB) {
	if (candyA == candyB)
		checkIfRunningOut(candyA, 200);
	else {
		checkIfRunningOut(candyA, 100);
		checkIfRunningOut(candyB, 100);
	}

    assert(available_amount(candyA) > 0 && available_amount(candyB) > 0, "not enough candy to synth!");
	return "synthesize " + candyA + ", " + candyB;
}

void sweetSynthesis(effect buff, int minimumNumberOfTurns) {
	if (my_spleen_use() >= spleen_limit()) {
		print("no spleen available to synth!", "red");
		return;
	}

//	if (buff == $effect[Synthesis: Collection])
//		cli_execute_if_needed(sweetSynthesisHelper($item[frostbite-flavored Hob-O], $item[Everlasting Deckswabber]), buff, minimumNumberOfTurns);
//	else if (buff == $effect[Synthesis: Greed])
///		cli_execute_if_needed(sweetSynthesisHelper($item[children of the candy corn], $item[Comet Drop]), buff, minimumNumberOfTurns);
//	else if (buff == $effect[Synthesis: Smart])
//		cli_execute_if_needed(sweetSynthesisHelper($item[Daffy Taffy], $item[candy stake]), buff, minimumNumberOfTurns);

	cli_execute_if_needed("synthesize " + buff, buff, minimumNumberOfTurns);
}



void setParkaMode(string modeString) {
	if ("parkaMode".get_property() == modeString)
		return;

	cli_execute("parka " + modeString);
}



// #Oliver's Place #milk-eyed sot #milky-eyed sot
// returns $location[none] if the quest is done, get's the quest if it isn't started
location sotsQuestLocation() {
    assert(!"_sotParcelReturned".get_property().to_boolean(), "sotsQuestLocation: milk-eyed sot's parcel already returned");

    // check the cached value
	string sotsQuestString = "_sotParcelLocation".get_property();
	assert(sotsQuestString != "-1", "milk-eyed sot's quest location not found (-1)");
	location sotsQuestLocation = sotsQuestString.to_location();
    if (sotsQuestLocation != $location[none]) return sotsQuestLocation;

    // looks like we haven't got the quest yet, let's get it
	string pageString = visit_url("/place.php?whichplace=speakeasy&action=olivers_sot", false, false);

	sotsQuestString = "_sotParcelLocation".get_property();
	sotsQuestLocation = sotsQuestString.to_location();
	assert(sotsQuestString != "-1", "milk-eyed sot's quest location not found (-1)");
	return sotsQuestLocation;
}



int spikolodonSpikesUsed() {
	return "_spikolodonSpikeUses".get_property().to_int();
}

int spikolodonSpikesAvailable() {
	return 5 - spikolodonSpikesUsed();
}


// returns the number of times (0-3) the Mayam Calendar is available to use
int mayamCalendarUsesAvailable() {
	int usesAvailable = 3;
    if ("_mayamSymbolsUsed".get_property().contains_text("yam4")) usesAvailable--;
    if ("_mayamSymbolsUsed".get_property().contains_text("clock")) usesAvailable--;
    if ("_mayamSymbolsUsed".get_property().contains_text("explosion")) usesAvailable--;

	return usesAvailable;
}


int cinchUsed() {
	return "_cinchUsed".get_property().to_int();
}


int cinchRestsUsed() {
	return "_cinchoRests".get_property().to_int();
}


// ensure the Cincho de Mayo has at least minCinch cinch
boolean readyCinch(int minCinch) {
	while ((100 - cinchUsed()) < minCinch && total_free_rests() > "timesRested".get_property().to_int()) {
		assert(equipped_amount($item[Cincho de Mayo]) >= 1, "we'd like to get more cinch but we're not wearing the Cincho de Mayo");
		cli_execute("rest free");
	}

	return (100 - cinchUsed()) >= minCinch;
}


int cinchCurrentlyAvailable() {
	return 100 - cinchUsed();
}



// choice: 1 = fight entity; 2 = get shadow quest item; 3 = get regular shadow items
void getRufusQuest(int choice) {
	assert(questStage("questRufus") < 0, "rufus quest already started?");

	// we don't have a quest, and the quest is ready to pick up, so pick it up
	visit_url("/inv_use.php?pwd&which=3&whichitem=11169", true, false);
	string pageString = run_choice(choice);
	assert(pageString.contains_text("You tell Rufus you'll defeat the shadow entity for him"), "we didn't get the right response, we expect 'You tell Rufus you'll defeat the shadow entity for him' from page " + pageString);

	assert(questStage("questRufus") == 0, "tried to start the Rufus quest, but it isn't started");
}



// requires code to reset the monster property when the quest is done, which I've put in postAdventure
// DEPRECATED
monster rufusMonster() {
	if ($item[Rufus's shadow lodestone].have_item())
		return $monster[none];

	string monString = "rufusDesiredEntity".get_property();
	if (monString == "") {
		// check the quest to see if we already got it
		clear_quest_log_cache();
		string questString = quest("Rufus's Goofin'");
		if (questString == "") {
			// get the quest
			assert(false, "todo");
		}
		matcher monsterMatcher = create_matcher("Rufus wants you to go into a Shadow Rift and defeat a (.*?)\\.", questString);
		assert(monsterMatcher.find(), "rufusMonster: didn't find monster in the quest string");
		monString = group(monsterMatcher, 1);
	}

	return monString.to_monster();
}



void drinkStillsuitDistillate() {
	visit_url("inventory.php?action=distill&pwd", true, false);
	run_choice(1);
}



int aprilBandTubaUses() {
	return "_aprilBandTubaUses".get_property().to_int();
}

int aprilBandTubaUsesAvailable() {
	return 3 - aprilBandTubaUses();
}



int mcHugeLargeAvalancheUses() {
	return "_mcHugeLargeAvalancheUses".get_property().to_int();
}

int mcHugeLargeAvalancheUsesAvailable() {
	return 3 - mcHugeLargeAvalancheUses();
}



// -------------------------------------
// CAMPGROUND UTILS
// -------------------------------------

void printCampground() {
	foreach anItem, amt in get_campground() {
		print(anItem + ": " + amt);
	}
}

boolean haveCampgroundItem(item checkItem) {
	foreach anItem, amt in get_campground() {
		if (anItem == checkItem) return true;
	}
	return false;
}


int freeRestsAvailableNow() {
	return (have_skill($skill[Adventurer of Leisure]) ? 2 : 0)
		+ (have_skill($skill[Disco Nap]) ? 1 : 0)
		+ "_mayamRests".get_property().to_int()
		+ (haveCampgroundItem($item[forest canopy bed]) ? 5 : 0)
		+ (have_item($item[Cincho de Mayo]) ? 3 : 0)
		+ (have_item($item[mother's necklace]) ? 5 : 0)
		+ (have_skill($skill[Long Winter's Nap]) ? 5 : 0)
		+ (have_skill($skill[Executive Narcolepsy]) ? 1 : 0)
		+ ("getawayCampsiteUnlocked".get_property().to_boolean() ? 1 : 0)
		+ (have_skill($skill[Elf Guard Relaxation Techniques]) ? 3 : 0);
}

// 
int freeRestsPossible() {
	return freeRestsAvailableNow()
		+ ((!"_mayamSymbolsUsed".get_property().contains_text("chair") && mayamCalendarUsesAvailable() >= 1) ? 5 : 0) // use the Mayam Calendar with the chair icon in the outer ring
		+ spleenRoom(); // use spleen item Nightmare Fuel
}




// returns the amount of cinch that would be regenerated by rests rests
int cinchForRests(int rests) {
	return (rests <= 5) ? (30 * rests) : 
		   (rests <= 9) ? (150 + 25 * (rests - 5)) : 
						  (220 + 5 * (rests - 9));
}


// returns the total possible cinch we could have if we used all FREE rests that are available now (doesn't consider future possible free rests)
int cinchPossibleWithFreeRests() {
	return cinchCurrentlyAvailable() + cinchForRests(freeRestsAvailableNow());
}



// -------------------------------------
// BANISH UTILITIES
// -------------------------------------

int [skill] banishSkillMapData() {
	int [skill] banishSkillMap = {
		$skill[Batter Up!] : kIndefiniteBanish,
		$skill[KGB tranquilizer dart] : 20,
		$skill[Throw Latte on Opponent] : 30,
		$skill[Reflex Hammer] : 30,
		$skill[Show them your ring] : 60,
		$skill[Asdon Martin: Spring-Loaded Front Bumper] : 30,
		$skill[Snokebomb] : 30,
		$skill[Feel Hatred] : 50,
		$skill[Breathe Out] : 20,
		$skill[Bowl a Curveball] : cosmicBowlingBallDuration(),
		$skill[%fn\, Release the Patriotic Screech!] : 100,
		$skill[Spring Kick] : kIndefiniteBanish,
	};

	return banishSkillMap;
}



// returns the turns a given banish skill is in effect for
int banishedTurnsPerCast(skill banish_skill) {
	return banishSkillMapData()[banish_skill];
}


BanishTrackRecord [] parseBanishedMonsters() {
	string [int, int] parser = group_string(get_property("banishedMonsters"), "([^:]+):([^:]+):(\\d+)");
	BanishTrackRecord [int] rval;
	int rvalIndex = 0;
	foreach i in parser {
		rval[rvalIndex].targettedMonster = to_monster(parser[i][1]);
		rval[rvalIndex].skillUsed = to_skill(parser[i][2]);
		rval[rvalIndex].turnUsed = to_int(parser[i][3]);
		rvalIndex++;
	}
	return rval;
}


BanishTrackRecord [] parseBanishedPhyla() {
	string [int, int] parser = group_string(get_property("banishedPhyla"), "([^:]+):([^:]+):(\\d+)");
	BanishTrackRecord [int] rval;
	int rvalIndex = 0;
	foreach i in parser {
		rval[rvalIndex].targettedPhylum = to_phylum(parser[i][1]);
		rval[rvalIndex].skillUsed = to_skill(parser[i][2]);
		rval[rvalIndex].turnUsed = to_int(parser[i][3]);
		rvalIndex++;
	}
	return rval;
}


// returns the number of turns remaining in the banish, or -1 if it is not in effect
// based on the property "banishedMonsters" and "banishedPhyla"
int turnsRemainingInBanish(skill aBanisher, location aLocation) {
	BanishTrackRecord [] banishedMonsters = parseBanishedMonsters();
	foreach i, br in banishedMonsters {
		if (br.skillUsed == aBanisher)
			return (br.turnUsed + banishedTurnsPerCast(br.skillUsed)) - my_turncount();
	}

	BanishTrackRecord [] banishedPhyla = parseBanishedPhyla();
	foreach i, br in banishedPhyla {
		if (br.skillUsed == aBanisher)
			return (br.turnUsed + banishedTurnsPerCast(br.skillUsed)) - my_turncount();
	}

	return -1;
}


// returns the longest-duration skill that is banishing the monster or $skill[none] if no skill is banishing it
skill monsterBanisherAtLocation(monster amon, location aLocation) {
	BanishTrackRecord [] banishedPhyla = parseBanishedPhyla();
	BanishTrackRecord [] banishedMonsters = parseBanishedMonsters();
	skill rval;
	int longestBanish = 0;

	foreach i, br in banishedPhyla {
		int banishDuration = turnsRemainingInBanish(br.skillUsed, aLocation);
		if (br.targettedPhylum == amon.phylum && br.turnUsed + banishedTurnsPerCast(br.skillUsed) >= my_turncount() && banishDuration > longestBanish) {
			rval = br.skillUsed;
			longestBanish = banishDuration;
		}
	}

	foreach i, br in banishedMonsters {
		int banishDuration = turnsRemainingInBanish(br.skillUsed, aLocation);
		if (br.targettedMonster == amon && br.turnUsed + banishedTurnsPerCast(br.skillUsed) >= my_turncount() && banishDuration > longestBanish) {
			rval = br.skillUsed;
			longestBanish = banishDuration;
		}
	}

	return rval;
}


// returns a map from monster banished at aLocation to the skill that banished it
skill [monster] monsterBanishedMap(location aLocation, boolean shouldPrint) {
	assert(aLocation != $location[none], "need a location to count banished monsters");
	skill [monster] monsterBanishedMap;

	foreach idx, mon in get_monsters(aLocation) {
		skill banishSkill = monsterBanisherAtLocation(mon, aLocation);
		int turnsRemainingInBanish = turnsRemainingInBanish(banishSkill, aLocation);
// 		print(mon + ": " + turnsRemainingInBanish);
		if (turnsRemainingInBanish > 0) {
			monsterBanishedMap[mon] = banishSkill;
			cprint(shouldPrint, mon + " banished by " + banishSkill + " for " + turnsRemainingInBanish + " turns");
		}
	}

	return monsterBanishedMap;
}

// returns the number of monsters actually banished at the given location
int banishesInEffect(location aLocation) {
	assert(aLocation != $location[none], "need a location to count banished monsters");
	int totalBanishes = 0;

	foreach idx, mon in get_monsters(aLocation)
		if (monsterBanisherAtLocation(mon, aLocation) != $skill[none])
			totalBanishes++;

	return totalBanishes;
}

int banishesInEffect() {
	return banishesInEffect($location[none]);
}


// true if using the given banisher at the given location (or anywhere if aLocation is none)
boolean using_banish(skill aBanisher, location aLocation) {
	BanishTrackRecord [] banishedMonsters = parseBanishedMonsters();
	for i from 0 to count(banishedMonsters) {
		//print("skill: " + banishedMonsters[i].skillUsed + ", banished: " + banishedMonsters[i].monsterBanished + ", turn used: " + banishedMonsters[i].turnUsed);
		if ((banishedMonsters[i].skillUsed == aBanisher) && ((aLocation == $location[none] || contains_monster(aLocation, banishedMonsters[i].targettedMonster)) && (banishedMonsters[i].turnUsed + banishedTurnsPerCast(banishedMonsters[i].skillUsed) > my_turncount())))
			return true;
	}
	return false;
}

// is the banisher being used anywhere?
boolean using_banish(skill aBanisher) {
	return using_banish(aBanisher, $location[none]);
}


int unbanished(location aLocation) {
// 	print("number of monsters: " + number_monsters(aLocation, false) + ", banishes in effect: " + banishesInEffect(aLocation));
	return number_monsters(aLocation, false);
}


// count monsters who aren't targets and aren't banished
int unbanishedNonTargets(location aLocation, monster [] someTargets) {
	int rval = 0;
	float [monster] monsterMap = appearance_rates(aLocation);
	foreach m in monsterMap {
		//print("testing monster: " + m);
		if (m != $monster[none] && monsterMap[m] > 0) {
			boolean found = false;
			foreach targetIndex in someTargets {
				//print("testing target: " + someTargets[targetIndex]);
				if (someTargets[targetIndex] == m) {
					found = true;
					break;
				}
			}
			if (!found)
				rval++;
		}
	}
	return rval;
}


// returns the status of all banishes in an array
// a banish will be "available" if it is castable/usable, AND either availableWhenInUse is true or the banish is not
// currently being used in the given location (or in any location if location is 'none')
// set availableWhenInUse to false when you want to ensure your banishes are not overwritten
// set availableWhenInUse to true when you are changing locations and all banishes are available to use even if they are being used elsewhere
PrioritySkillRecord [int] banishSkillData(boolean availableWhenInUse, location aLocation, int maxPerTurnCost) {
	PrioritySkillRecord tempBSR;
	boolean isInCombat = inCombat();
	int basePriority = 3;
	int lowCostPriority = 1;
	int highCostPriority = 4;
	boolean costIsGood;
	PrioritySkillRecord [int] bsrArray;
	int i = 0;

	// only the Licorice Rope and Restraining Order will banish in the Gingerbread City
	boolean isGingerbreadCityLoc = aLocation == $location[Gingerbread Train Station] || aLocation == $location[Gingerbread Civic Center] || aLocation == $location[Gingerbread Industrial Zone]
		|| aLocation == $location[Gingerbread Upscale Retail District] || aLocation == $location[Gingerbread Sewers];

	// Asdon Martin: Spring-Loaded Front Bumper
	tempBSR = new PrioritySkillRecord($skill[Asdon Martin: Spring-Loaded Front Bumper], $item[none]);
	tempBSR.meatCost = costOfAsdonMartinBuff();
	costIsGood = maxPerTurnCost >= (tempBSR.meatCost / banishedTurnsPerCast($skill[Asdon Martin: Spring-Loaded Front Bumper]));
	tempBSR.priority = (costIsGood ? lowCostPriority : highCostPriority) + 0.1;
	tempBSR.usesAvailable = kUnlimitedUses;
	tempBSR.isAvailableNow = costIsGood && isAsdonWorkshed() && turnsRemainingInBanish($skill[Asdon Martin: Spring-Loaded Front Bumper], aLocation) == -1 && get_fuel() >= 50 && !isGingerbreadCityLoc;
	bsrArray[i++] = tempBSR;

	// Batter Up!
	tempBSR = new PrioritySkillRecord($skill[Batter Up!]);
	if ( ! $slot[weapon].equipped_item().item_type().contains_text("club"))
		tempBSR.theItem = have_item($item[oversized sparkler]) ? $item[oversized sparkler] : $item[sea-worn candlestick];
	tempBSR.meatCost = kTurnValue;
	costIsGood = maxPerTurnCost >= (tempBSR.meatCost / 20); // banishes for the rest of the day, using 20 as duration
	tempBSR.priority = (costIsGood ? lowCostPriority : highCostPriority) + 0.2;
	tempBSR.usesAvailable = kUnlimitedUses;
	boolean weildingAClub = item_type(equipped_item($slot[weapon])).contains_text("club") || (item_type(equipped_item($slot[weapon])).contains_text("sword") && have_effect($effect[Iron Palms]) > 0);
	tempBSR.isAvailableNow = costIsGood && my_class() == $class[seal clubber] && my_fury() >= 5 && (weildingAClub || !isInCombat) && (availableWhenInUse || !using_banish($skill[Batter Up!], aLocation)) && !isGingerbreadCityLoc;
	bsrArray[i++] = tempBSR;

	// Breathe Out
	tempBSR = new PrioritySkillRecord();
	tempBSR.theSkill = $skill[Breathe Out];
	tempBSR.theItem = $item[none];
	tempBSR.meatCost = mall_price($item[hot jelly]) + kSpleenValue;
	costIsGood = maxPerTurnCost >= (tempBSR.meatCost / banishedTurnsPerCast($skill[Breathe Out]));
	tempBSR.priority = (costIsGood ? lowCostPriority : highCostPriority) + 0.2;
	tempBSR.usesAvailable = spleen_limit() - my_spleen_use();
	tempBSR.isAvailableNow = costIsGood && have_skill($skill[Breathe Out]) && (availableWhenInUse || !using_banish($skill[Breathe Out], aLocation)) && !isGingerbreadCityLoc;
	bsrArray[i++] = tempBSR;

	// Patriotic Eagle TODO this is a skill added by a familiar, so it doesn't fit in .theItem
	tempBSR = new PrioritySkillRecord();
	tempBSR.theSkill = $skill[%fn\, Release the Patriotic Screech!];
	tempBSR.theItem = $item[none]; // eww this is a familiar skill
	tempBSR.meatCost = kTurnValue;
	costIsGood = maxPerTurnCost >= (tempBSR.meatCost / banishedTurnsPerCast($skill[%fn\, Release the Patriotic Screech!]));
	tempBSR.priority = (costIsGood ? lowCostPriority : highCostPriority) + 0.3; // lower priority because it takes a bit to recharge and we don't generally want to use it unless we call for it explicitly
	tempBSR.usesAvailable = "screechCombats".get_property().to_int() == 0 ? 1 : 0;
	tempBSR.isAvailableNow = costIsGood && have_skill($skill[%fn\, Release the Patriotic Screech!]) && (availableWhenInUse || !using_banish($skill[Breathe Out], aLocation)) && !isGingerbreadCityLoc;
	bsrArray[i++] = tempBSR;

	// Show them your ring
	tempBSR = new PrioritySkillRecord();
	tempBSR.theSkill = $skill[Show them your ring];
	tempBSR.theItem = $item[mafia middle finger ring];
	tempBSR.priority = basePriority + 0.1;
	tempBSR.usesAvailable = to_boolean(get_property("_mafiaMiddleFingerRingUsed")) ? 0 : 1;
	tempBSR.isAvailableNow = equipped_amount($item[mafia middle finger ring]) > 0 || (!isInCombat && canEquipWithExistingAutomatedDressup($item[mafia middle finger ring])) && !isGingerbreadCityLoc;
	bsrArray[i++] = tempBSR;

	// Throw Latte on Opponent
	tempBSR = new PrioritySkillRecord($skill[Throw Latte on Opponent], $item[Latte lovers member's mug]);
	tempBSR.priority = basePriority + 0.2;
	int latteRefillsAvailable = 3 - to_int(get_property("_latteRefillsUsed"));
	boolean latteBanishAvailable = !to_boolean(get_property("_latteBanishUsed"));
	int latteBanishesAvailable = latteRefillsAvailable;
	if (latteBanishAvailable) latteBanishesAvailable++;
	tempBSR.usesAvailable = latteBanishesAvailable;
	tempBSR.isAvailableNow = ((equipped_amount($item[Latte lovers member's mug]) > 0
		 || (!isInCombat && canEquipWithExistingAutomatedDressup($item[Latte lovers member's mug])))
		&& (availableWhenInUse || !using_banish($skill[Throw Latte on Opponent], aLocation)))
		&& !isGingerbreadCityLoc;
	bsrArray[i++] = tempBSR;

	// Show Your Boring Familiar Pictures
	tempBSR = new PrioritySkillRecord($skill[Show Your Boring Familiar Pictures], $item[familiar scrapbook]);
	tempBSR.priority = basePriority + 0.3; // we want these to be spent after the others
	tempBSR.usesAvailable = to_int(get_property("scrapbookCharges")) / 100;
	tempBSR.isAvailableNow = ((equipped_amount($item[familiar scrapbook]) > 0 && have_skill($skill[Show Your Boring Familiar Pictures]))
		 || (!isInCombat && canEquipWithExistingAutomatedDressup($item[familiar scrapbook])))
		&& (availableWhenInUse || !using_banish($skill[Show Your Boring Familiar Pictures], aLocation))
		&& !isGingerbreadCityLoc;
	bsrArray[i++] = tempBSR; // TODO the skill seems to be bugged??? Seems to work now???

	// KGB tranquilizer dart
	tempBSR = new PrioritySkillRecord();
	tempBSR.theSkill = $skill[KGB tranquilizer dart];
	tempBSR.theItem = $item[Kremlin's Greatest Briefcase];
	tempBSR.priority = basePriority + 0.2;
	tempBSR.usesAvailable = 3 - to_int(get_property("_kgbTranquilizerDartUses"));
	tempBSR.isAvailableNow = (equipped_amount($item[Kremlin's Greatest Briefcase]) > 0 || (!isInCombat && canEquipWithExistingAutomatedDressup($item[Kremlin's Greatest Briefcase])))
		&& (availableWhenInUse || !using_banish($skill[KGB tranquilizer dart], aLocation))
		&& !isGingerbreadCityLoc;
	bsrArray[i++] = tempBSR;

	// Lil' Doctor&trade; bag
	tempBSR = new PrioritySkillRecord();
	tempBSR.theSkill = $skill[Reflex Hammer];
	tempBSR.theItem = $item[Lil' Doctor&trade; bag];
	tempBSR.priority = basePriority + 0.2;
	tempBSR.usesAvailable = 3 - to_int(get_property("_reflexHammerUsed"));
	tempBSR.isAvailableNow = (equipped_amount($item[Lil' Doctor&trade; bag]) > 0 || (!isInCombat && canEquipWithExistingAutomatedDressup($item[Lil' Doctor&trade; bag])))
		&& (availableWhenInUse || !using_banish($skill[Reflex Hammer], aLocation))
		&& !isGingerbreadCityLoc;
	bsrArray[i++] = tempBSR;

	// Cosmic Bowling Ball
	tempBSR = new PrioritySkillRecord();
	tempBSR.theSkill = $skill[Bowl a Curveball];
	tempBSR.theItem = $item[none];
	tempBSR.priority = basePriority + 0.3; // could be the same as snoke and feel hatred, since it checks uses first, and this will always have more uses than those
	tempBSR.usesAvailable = kUnlimitedUses;
	tempBSR.isAvailableNow = (have_item($item[cosmic bowling ball]) || have_skill($skill[Bowl Straight Up])) && !get_property(kDressupSelectorKey).contains_text("item")
		&& !isGingerbreadCityLoc && !isOverdrunk(); // ready and we're NOT wearing +item outfit
	bsrArray[i++] = tempBSR;

	// Snokebomb
	tempBSR = new PrioritySkillRecord();
	tempBSR.theSkill = $skill[Snokebomb];
	tempBSR.theItem = $item[none];
	tempBSR.priority = basePriority + 0.4;
	tempBSR.usesAvailable = 3 - to_int(get_property("_snokebombUsed"));
	tempBSR.isAvailableNow = availableWhenInUse || !using_banish($skill[Snokebomb], aLocation) && !isGingerbreadCityLoc;
	bsrArray[i++] = tempBSR;

	// Feel Hatred
	tempBSR = new PrioritySkillRecord();
	tempBSR.theSkill = $skill[Feel Hatred];
	tempBSR.theItem = $item[none];
	tempBSR.priority = basePriority + 0.4;
	tempBSR.usesAvailable = 3 - to_int(get_property("_feelHatredUsed"));
	tempBSR.isAvailableNow = availableWhenInUse || !using_banish($skill[Feel Hatred], aLocation) && !isGingerbreadCityLoc;
	bsrArray[i++] = tempBSR;

	// Spring Kick
	tempBSR = new PrioritySkillRecord();
	tempBSR.theSkill = $skill[Spring Kick];
	tempBSR.theItem = $item[spring shoes];
	tempBSR.meatCost = kTurnValue;
	costIsGood = maxPerTurnCost >= (tempBSR.meatCost / banishedTurnsPerCast($skill[Spring Kick]));
	tempBSR.priority = (costIsGood ? lowCostPriority : highCostPriority);
	tempBSR.usesAvailable = kUnlimitedUses;
	tempBSR.isAvailableNow = (equipped_amount($item[spring shoes]) > 0 || (!isInCombat && canEquipWithExistingAutomatedDressup($item[spring shoes])))
		&& (availableWhenInUse || !using_banish($skill[Spring Kick], aLocation))
		&& !isGingerbreadCityLoc;
	bsrArray[i++] = tempBSR;


	// licorice rope
	tempBSR = new PrioritySkillRecord();
	tempBSR.theSkill = $skill[licorice rope];
	tempBSR.theItem = $item[none];
	tempBSR.priority = basePriority + 0.1;
	tempBSR.usesAvailable = kUnlimitedUses;
	tempBSR.isAvailableNow = !using_banish($skill[licorice rope], aLocation) && isGingerbreadCityLoc;
	bsrArray[i++] = tempBSR;

	// gingerbread restraining order
	tempBSR = new PrioritySkillRecord();
	tempBSR.theSkill = $skill[none];
	tempBSR.theItem = $item[gingerbread restraining order];
	tempBSR.meatCost = current_price($item[gingerbread restraining order]);
	tempBSR.priority = basePriority + 0.2; // could be the same as snoke and feel hatred, since it checks uses first, and this will always have more uses than those
	tempBSR.usesAvailable = item_amount($item[gingerbread restraining order]);
	tempBSR.isAvailableNow = !using_banish($skill[licorice rope], aLocation) && isGingerbreadCityLoc;
	bsrArray[i++] = tempBSR;

	return bsrArray;
}

PrioritySkillRecord [int] banishSkillData(location aLocation, int maxPerTurnCost) {
	return banishSkillData(false, aLocation, maxPerTurnCost);
}


void printBanishPriorityArray(boolean availableWhenInUse, boolean isInCombat, location aLocation, int maxPerTurnCost) {
	printPSRArray(banishSkillData(availableWhenInUse, aLocation, maxPerTurnCost));
}

void printBanishPriorityArray() {
	printPSRArray(banishSkillData(false, to_location(get_property("lastAdventure")), kMaxInt));
}


// how many banishes do we have available right now? the fact that a banish is already in use doesn't matter
int banishesAvailable(int maxPerTurnCost) {
	return skillsAvailable(banishSkillData(true, $location[none], maxPerTurnCost), maxPerTurnCost);
}


// returns the shortest existing banish -- i.e. the number of turns until at least 1 banish runs out
int turnsUntilBanishNeeded(location aLocation) {
	int rval = kMaxInt;
	foreach amon, banisher in monsterBanishedMap(aLocation, false) {
		int banishDuration = turnsRemainingInBanish(banisher, aLocation);
		print(amon + " banished for " + banishDuration + " turns");
		if (banishDuration > 0 && banishDuration < rval)
			rval = banishDuration;
	}
	return rval;
}


// banish selection:
// start by looking at priorities as ints, and select the set of banishes with the same lowest priority, and where usesAvailable > 0 and isAvailableNow is true
// within the set of banishes with the same integer priority, select the banishes with the highest usesAvailable
// within the set of banishes with the same integer priority and the same number of usesAvailable, select the banish with the highest fractional priority
PrioritySkillRecord banishToUse(PrioritySkillRecord [] skillData, location aLocation, int maxPerTurnCost, PrioritySkillRecord [] excludedBanishes) {
	boolean isInCombat = inCombat();
	if (!isInCombat) refillLatteIfRequired();
	if (maxPerTurnCost > 0 && !isInCombat && isAsdonWorkshed())
		ensureAsdonMartinFuel(50);

	return skillToUse(skillData, aLocation, maxPerTurnCost, excludedBanishes);
}

// banish selection:
// start by looking at priorities as ints, and select the set of banishes with the same lowest priority, and where usesAvailable > 0 and isAvailableNow is true
// within the set of banishes with the same integer priority, select the banishes with the highest usesAvailable
// within the set of banishes with the same integer priority and the same number of usesAvailable, select the banish with the highest fractional priority
PrioritySkillRecord banishToUse(location aLocation, int maxPerTurnCost, PrioritySkillRecord [] excludedBanishes) {
	PrioritySkillRecord [] skillData = banishSkillData(false, aLocation, maxPerTurnCost);
	return banishToUse(skillData, aLocation, maxPerTurnCost, excludedBanishes);
}

PrioritySkillRecord banishToUse(PrioritySkillRecord [] skillData, location aLocation, int maxPerTurnCost) {
	PrioritySkillRecord [] excludedBanishes;
	return banishToUse(skillData, aLocation, maxPerTurnCost, excludedBanishes);
}

PrioritySkillRecord banishToUse(location aLocation, int maxPerTurnCost) {
	PrioritySkillRecord [] skillData = banishSkillData(false, aLocation, maxPerTurnCost);
	PrioritySkillRecord [] excludedBanishes;
	return banishToUse(skillData, aLocation, maxPerTurnCost, excludedBanishes);
}

PrioritySkillRecord banishToUse(location aLocation) {
	return banishToUse(aLocation, 0);
}



// -------------------------------------
// FREE RUNAWAY UTILITIES
// -------------------------------------

// returns the status of all monster replacers
PriorityRecord [int] freeRunawaySkillData() {
	boolean isInCombat = inCombat();
	PriorityRecord tempPR;
	int basePriority = 3;
	PriorityRecord [int] prArray;
	int i = 0;

	// Spring Away
	tempPR = new PriorityRecord();
	tempPR.customCombatString = "skill Spring Away;";
	tempPR.maximizeString = "equip spring shoes";
	tempPR.meatCost = 0;
	tempPR.priority = basePriority - 0.5;
	tempPR.usesAvailable = kUnlimitedUses;
	tempPR.isAvailableNow = (equipped_amount($item[spring shoes]) > 0 || (!isInCombat && canEquipWithExistingAutomatedDressup($item[spring shoes])))
	    && have_effect($effect[Everything Looks Green]) == 0;
	prArray[i++] = tempPR;

	return prArray;
}

PriorityRecord chooseFreeRunawaySkill() {
	PriorityRecord [int] excludedSkills;
	return skillToUse(freeRunawaySkillData(), $location[none], kMaxInt, excludedSkills);
}



// TODO make this use the same PrioritySkillRecord as everything else
// might return a blank record if there are no free runaways to be had
ActionRecord chooseFreeRunaway(int maxPerRunawayCost) {
	ActionRecord theAction;

	if (my_class() == $class[Accordion Thief] && have_item($item[fish-oil smoke bomb]))
		theAction.itemToUse = $item[fish-oil smoke bomb];
	else if (have_item($item[peppermint parasol])
		&& maxPerRunawayCost >= (mall_price($item[peppermint parasol]) / 10)
		&& to_int(get_property("parasolUsed")) < 3) // after 3, less than 100% chance
		theAction.itemToUse = $item[peppermint parasol];

	return theAction;
}

boolean canFreeRunaway(int maxPerRunawayCost) {
	ActionRecord theAction = chooseFreeRunaway(maxPerRunawayCost);
	return theAction.skillToUse != $skill[none] || theAction.itemToUse != $item[none];
}



// -------------------------------------
// REPLACE MONSTER UTILITIES
// -------------------------------------

// returns the status of all monster replacers
PrioritySkillRecord [int] replaceMonsterSkillData() {
	boolean isInCombat = inCombat();
	PrioritySkillRecord tempPSR;
	int basePriority = 3;
	PrioritySkillRecord [int] psrArray;
	int i = 0;

	// Macrometeorite
	tempPSR = new PrioritySkillRecord();
	tempPSR.theSkill = $skill[Macrometeorite];
	tempPSR.theItem = $item[none];
	tempPSR.priority = basePriority;
	tempPSR.usesAvailable = 10 - to_int(get_property("_macrometeoriteUses"));
	tempPSR.isAvailableNow = true;
	psrArray[i++] = tempPSR;

	// Powerful Glove
	int batteryPowerUsed = to_int(get_property("_powerfulGloveBatteryPowerUsed"));
	int usesAvailable = (100 - batteryPowerUsed) / 10;
	boolean isAvailableNow = (equipped_amount($item[Powerful Glove]) > 0 || (!isInCombat && canEquipWithExistingAutomatedDressup($item[Powerful Glove])));
	tempPSR = new PrioritySkillRecord($skill[CHEAT CODE: Replace Enemy], $item[Powerful Glove], 0, 0, basePriority, usesAvailable, isAvailableNow);
	psrArray[i++] = tempPSR;

	return psrArray;
}

PrioritySkillRecord chooseReplaceMonsterSkill() {
	PrioritySkillRecord [int] excludedSkills;
	return skillToUse(replaceMonsterSkillData(), $location[none], kMaxInt, excludedSkills);
}


boolean canReplaceMonster() {
	PrioritySkillRecord chosenReplaceMonsterSkill = chooseReplaceMonsterSkill();
	boolean rval = ((chosenReplaceMonsterSkill.theSkill != $skill[none]) && (chosenReplaceMonsterSkill.usesAvailable > 0) && chosenReplaceMonsterSkill.isAvailableNow);

	if (rval)
		print("we can replace monsters");
	else
		print("we can't replace monsters");

	return rval;
}



// -------------------------------------
// INSTA KILL UTILITIES
// -------------------------------------
// an insta-kill/instakill/insta kill is an auto-kill that takes no turns, these are all from IotM

// monsters that cannot be insta-killed but aren't bosses
boolean [monster] gkNoInstaKillMonsters = {
	$monster[angry ghost] : true,
};

// returns the status of all free kill skills in an array
PrioritySkillRecord [int] instaKillSkillData() { // #free kill #freekill
	boolean isInCombat = inCombat();
	PrioritySkillRecord tempPSR;
	int basePriority = 3;
	PrioritySkillRecord [int] psrArray;
	int i = 0;

	// Gingerbread Mob Hit
	tempPSR = new PrioritySkillRecord();
	tempPSR.theSkill = $skill[Gingerbread Mob Hit];
	tempPSR.theItem = $item[none];
	tempPSR.priority = basePriority;
	tempPSR.usesAvailable = to_boolean(get_property("_gingerbreadMobHitUsed")) ? 0 : 1;
	tempPSR.isAvailableNow = true;
	psrArray[i++] = tempPSR;

	// Chest X-Ray
	tempPSR = new PrioritySkillRecord();
	tempPSR.theSkill = $skill[Chest X-Ray];
	tempPSR.theItem = $item[Lil' Doctor&trade; bag];
	tempPSR.priority = basePriority;
	tempPSR.usesAvailable = 3 - to_int(get_property("_chestXRayUsed"));
	tempPSR.isAvailableNow = (equipped_amount($item[Lil' Doctor&trade; bag]) > 0 || (!isInCombat && canEquipWithExistingAutomatedDressup($item[Lil' Doctor&trade; bag])));
	psrArray[i++] = tempPSR;

	// Shattering Punch
	tempPSR = new PrioritySkillRecord();
	tempPSR.theSkill = $skill[Shattering Punch];
	tempPSR.theItem = $item[none];
	tempPSR.priority = basePriority;
	tempPSR.usesAvailable = 3 - to_int(get_property("_shatteringPunchUsed"));
	tempPSR.isAvailableNow = true;
	psrArray[i++] = tempPSR;

	// Everfull Dart Holster
	tempPSR = new PrioritySkillRecord();
	tempPSR.theSkill = $skill[Darts: Aim for the Bullseye];
	//tempPSR.theSkill = $skill[[7521]Darts: Aim for the Bullseye];
	tempPSR.theItem = $item[Everfull Dart Holster];
	tempPSR.priority = basePriority - 1; // high priority because we have many free uses
	tempPSR.usesAvailable = kMaxInt;
	tempPSR.isAvailableNow = equipped_amount($item[Everfull Dart Holster]) >= 1 && have_effect($effect[Everything Looks Red]) == 0;
	psrArray[i++] = tempPSR;

	// Free for all
	tempPSR = new PrioritySkillRecord();
	tempPSR.theSkill = $skill[Free-for-all];
	tempPSR.theItem = $item[none];
	tempPSR.priority = basePriority - 2; // free built-in skill
	tempPSR.usesAvailable = kMaxInt;
	tempPSR.isAvailableNow = my_class() == $class[Pig Skinner] && have_effect($effect[Everything Looks Red]) == 0;
	psrArray[i++] = tempPSR;

	return psrArray;
}


int instaKillsAvailable() {
	int rval;
	PrioritySkillRecord [int] instaKillSkillData = instaKillSkillData();
	foreach idx in instaKillSkillData {
		rval += instaKillSkillData[idx].usesAvailable;
	}
	return rval;
}


PrioritySkillRecord chooseInstaKillSkill() {
	PrioritySkillRecord [int] excludedSkills;

	if (!inCombat() && isAsdonWorkshed())
		ensureAsdonMartinFuel(100);
	return skillToUse(instaKillSkillData(), $location[none], kMaxInt, excludedSkills);
}



// -------------------------------------
// FREE COMBATS
// -------------------------------------
// a free combat is a combat with a specific monster that doesn't take a turn
// includes dressing up for the specific monster

// returns the status of all free kill skills in an array
AdventureRecord [int] freeCombatData() {
	AdventureRecord [int] arArray;
	AdventureRecord tempAR;
	int idx = 0;

	if ("_glitchMonsterFights".get_property().to_int() < available_amount($item[[glitch season reward name]]))
		arArray[idx++] = new AdventureRecord($location[none], $skill[none], $item[none], "grindGlitchSeasonReward"); // Glitch Season reward

	int glFightsAvailable = 3 - to_int(get_property("_godLobsterFights"));
	if (glFightsAvailable > 0)
		for gli from 1 to glFightsAvailable
			arArray[idx++] = new AdventureRecord($location[none], $skill[none], $item[none], "burnNextGodLobster");

	if (!to_boolean(get_property("_eldritchTentacleFought")))
		arArray[idx++] = new AdventureRecord($location[none], $skill[none], $item[none], "grindEldritchTentacle");
	if (!to_boolean(get_property("_eldritchHorrorEvoked")))
		arArray[idx++] = new AdventureRecord($location[none], $skill[none], $item[none], "grindEldritchHorror");

	if (!"_molehillMountainUsed".get_property().to_boolean())
		arArray[idx++] = new AdventureRecord($location[none], $skill[none], $item[none], "grindMolehillMountain");

	if (canAugustSkill(8))
		arArray[idx++] = new AdventureRecord($location[none], $skill[Aug. 8th: Cat Day!], $item[none], "grindCatDay");
	if (canAugustSkill(22))
		arArray[idx++] = new AdventureRecord($location[none], $skill[Aug. 22nd: Tooth Fairy Day!], $item[none], "grindToothFairy");

    if ("_aprilBandTomUses".get_property().to_int() < 3 && available_amount($item[Apriling band quad tom]) > 0) {
        for i from 1 to 3 - "_aprilBandTomUses".get_property().to_int()
    		arArray[idx++] = new AdventureRecord($location[none], $skill[none], $item[Apriling band quad tom], "burnNextAprilingBandQuadTom");
    }

	// seal clubber fights
// 	if (my_class() == $class[seal clubber]) {
// 		while (infernalSealFights() > 0) {
// 			if (available_amount($item[figurine of a sleek seal]) >= infernalSealFights())
// 				grindSeals($item[figurine of a sleek seal]);
// 			else
// 				grindSeals($item[figurine of an ancient seal]);
// 		}
// 	}

	return arArray;
}


int freeCombatsAvailable() {
	return count(freeCombatData());
}


AdventureRecord chooseFreeCombat() {
	return freeCombatData()[0];
}



// -------------------------------------
// YELLOW RAY UTILITIES
// -------------------------------------
// a yellow ray/yellow-ray/yellowray forces all items to drop, or all non-conditional items to drop
// usually it will end combat, and sometimes without a turn spent
// these are all from IotM

// returns the status of all yellow skills in an array
PrioritySkillRecord [int] yellowRaySkillData() {
	boolean isInCombat = inCombat();
	PrioritySkillRecord tempPSR;
	int basePriority = 3;
	PrioritySkillRecord [int] psrArray;
	int i = 0;

	// Asdon Martin: Spring-Loaded Front Bumper
	tempPSR = new PrioritySkillRecord($skill[Asdon Martin: Missile Launcher]);
	tempPSR.theItem = $item[none];
	tempPSR.meatCost = 2800;
	tempPSR.priority = basePriority;
	tempPSR.usesAvailable = to_boolean(get_property("_missileLauncherUsed")) ? 0 : 1;
	tempPSR.isAvailableNow = isAsdonWorkshed() && get_fuel() >= 100;
	psrArray[i++] = tempPSR;

	// Disintegrate -- yellow rocket is better
// 	tempPSR = new PrioritySkillRecord($skill[Disintegrate]);
// 	tempPSR.theItem = $item[none];
// 	tempPSR.meatCost = kTurnValue;
// 	tempPSR.mpCost = 150;
// 	tempPSR.priority = basePriority;
// 	tempPSR.usesAvailable = kUnlimitedUses;
// 	tempPSR.isAvailableNow = (have_effect($effect[Everything Looks Yellow]) == 0) && (my_mp() >= 150);
// 	psrArray[i++] = tempPSR;

	// yellow rocket -- cost 250 meat but only 75 turns of Everything Looks Yellow
	tempPSR = new PrioritySkillRecord($skill[none], $item[yellow rocket]);
	tempPSR.meatCost = 250;
	tempPSR.mpCost = 0;
	tempPSR.priority = basePriority;
	tempPSR.usesAvailable = kUnlimitedUses;
	tempPSR.isAvailableNow = (have_effect($effect[Everything Looks Yellow]) == 0);
	psrArray[i++] = tempPSR;

	// Feel Envy
	tempPSR = new PrioritySkillRecord($skill[Feel Envy]);
	tempPSR.theItem = $item[none];
	tempPSR.meatCost = kTurnValue;
	tempPSR.mpCost = 0;
	tempPSR.priority = basePriority;
	tempPSR.usesAvailable = 3 - to_int(get_property("_feelEnvyUsed"));
	tempPSR.isAvailableNow = true;
	psrArray[i++] = tempPSR;

	// Use the Force
	tempPSR = new PrioritySkillRecord($skill[Use the Force]);
	tempPSR.theItem = $item[Fourth of May Cosplay Saber];
	tempPSR.meatCost = 0;
	tempPSR.mpCost = 0;
	tempPSR.priority = basePriority;
	tempPSR.usesAvailable = 5 - to_int(get_property("_saberForceUses"));
	tempPSR.isAvailableNow = !isInCombat || equipped_amount($item[Fourth of May Cosplay Saber]) > 0;
	psrArray[i++] = tempPSR;

	// Shocking Lick
	tempPSR = new PrioritySkillRecord($skill[Shocking Lick]);
	tempPSR.theItem = $item[none];
	tempPSR.meatCost = 0;
	tempPSR.mpCost = 0;
	tempPSR.priority = basePriority;
	tempPSR.usesAvailable = to_int(get_property("shockingLickCharges"));
	tempPSR.isAvailableNow = true;
	psrArray[i++] = tempPSR;

	return psrArray;
}


// get mana and other resources to allow YR
// TODO detect which YR we're using and only prep for that
void prepForYellowRay() {
	restore_mp(150);
	if (isAsdonWorkshed() && !to_boolean(get_property("_missileLauncherUsed")))
		ensureAsdonMartinFuel(100);
}

PrioritySkillRecord chooseYellowRaySkill(PrioritySkillRecord [] excludedSkills) {
	if (!inCombat())
		prepForYellowRay();
	return skillToUse(yellowRaySkillData(), $location[none], kMaxInt, excludedSkills);
}

PrioritySkillRecord chooseYellowRaySkill() {
	PrioritySkillRecord [] excludedSkills;
	return chooseYellowRaySkill(excludedSkills);
}


int yellowRaysAvailable() {
	return skillsAvailable(yellowRaySkillData());
}

boolean canYellowRay() {
// 	PrioritySkillRecord chosenYellowRaySkill = chooseYellowRaySkill();
// 	return chosenYellowRaySkill.usesAvailable > 0 && chosenYellowRaySkill.isAvailableNow;
	return yellowRaysAvailable() > 0;
}

// returns true if we have any yellow ray skills available that don't give the Everything Looks Yellow debuff
// can be used to ensure all free yellow ray skills are used
boolean canYellowRayWithoutSeeingYellow() {
	PrioritySkillRecord [] excludedSkills = {new PrioritySkillRecord($skill[Disintegrate], $item[yellow rocket])};
	PrioritySkillRecord chosenYellowRaySkill = chooseYellowRaySkill(excludedSkills);
	return chosenYellowRaySkill.usesAvailable > 0 && chosenYellowRaySkill.isAvailableNow;
}


boolean canDisintegrate() {
	return have_effect($effect[Everything Looks Yellow]) == 0;
}




// -------------------------------------
// SNEAK UTILITIES -- free force non-combats noncombats NCs
// -------------------------------------

// returns the status of all sneak skills in an array
PriorityRecord [int] sneakSkillData() {
	PriorityRecord [int] prArray;
	PriorityRecord tempPR;

	boolean isInCombat = inCombat();
	int basePriority = 3;
	int i = 0;

	// Cincho de Mayo
	tempPR = new PriorityRecord("cast Cincho: Fiesta Exit", "", "");
	tempPR.mpCost = 0;
	tempPR.meatCost = 0;
	tempPR.duration = 0;
	tempPR.priority = basePriority;
	tempPR.usesAvailable = cinchPossibleWithFreeRests() / 60;
	tempPR.isAvailableNow = "_cinchUsed".get_property().to_int() < 40 && !isInCombat; // it's a buff (i.e. noncombat) skill
	prArray[i++] = tempPR;

	// Sneakisol -- Eight Days a Week Pill Keeper
	tempPR = new PriorityRecord("pillkeeper noncombat", "", "");
	tempPR.mpCost = 0;
	tempPR.meatCost = freePillKeeperUsed() ? spleenValue() * 3 : 0;
	tempPR.duration = 0;
	tempPR.priority = basePriority + (freePillKeeperUsed() ? 2 : 0);
	tempPR.usesAvailable = spleenRoom() / 3 + (freePillKeeperUsed() ? 0 : 1);
	tempPR.isAvailableNow = (!freePillKeeperUsed() || spleenRoom() >= 3) && !isInCombat; // it's a buff (i.e. noncombat) skill
	prArray[i++] = tempPR;

	// stench jelly
	tempPR = new PriorityRecord("chew stench jelly", "", "");
	tempPR.mpCost = 0;
	tempPR.meatCost = acquireCost($item[stench jelly]) + spleenValue();
	tempPR.duration = 0;
	tempPR.priority = basePriority + 2;
	tempPR.usesAvailable = spleenRoom();
	tempPR.isAvailableNow = spleenRoom() >= 1 && !isInCombat; // it's a buff (i.e. noncombat) skill
	prArray[i++] = tempPR;

	// Apriling band tuba
	tempPR = new PriorityRecord("aprilband play tuba", "", "");
	tempPR.mpCost = 0;
	tempPR.meatCost = 0;
	tempPR.duration = 0;
	tempPR.priority = basePriority;
	tempPR.usesAvailable = aprilBandTubaUsesAvailable();
	tempPR.isAvailableNow = !isInCombat; // it's a buff (i.e. noncombat) skill
	prArray[i++] = tempPR;

	// McHugeLarge left ski
	tempPR = new PriorityRecord("", "skill McHugeLarge Avalanche", "equip McHugeLarge left ski");
	tempPR.mpCost = 0;
	tempPR.meatCost = 0;
	tempPR.duration = 0;
	tempPR.priority = basePriority;
	tempPR.usesAvailable = mcHugeLargeAvalancheUsesAvailable();
	tempPR.isAvailableNow = equipped_amount($item[McHugeLarge left ski]) > 0 || !isInCombat; // have to cast it in combat
	prArray[i++] = tempPR;

	// Jurassic Parka -- spikolodon tab
	tempPR = new PriorityRecord("", "skill Launch spikolodon spikes", "equip Jurassic Parka");
	tempPR.mpCost = 0;
	tempPR.meatCost = turnValue();
	tempPR.duration = 0;
	tempPR.priority = basePriority;
	tempPR.usesAvailable = spikolodonSpikesAvailable();
	tempPR.isAvailableNow = equipped_amount($item[Jurassic Parka]) > 0 || !isInCombat; // have to cast it in combat
	prArray[i++] = tempPR;

	return prArray;
}


PriorityRecord chooseSneakSkill(int maxPerTurnCost, PriorityRecord [] excludedSkills) {
	return skillToUse(sneakSkillData(), $location[none], maxPerTurnCost, excludedSkills);
}

// maxCost is the max cost of the sneak
PriorityRecord chooseSneakSkill(int maxCost) {
	PriorityRecord [] excludedSkills;
	return chooseSneakSkill(maxCost, excludedSkills);
}


int sneaksAvailable() {
	return skillsAvailable(sneakSkillData());
}

boolean canSneak() {
	return sneaksAvailable() > 0;
}


// TODO
boolean currentlySneaking() {
	assert(false, "unimplemented");
	return true;
}



// -------------------------------------
// POST ADVENTURE PRE ADVENTURE post-adventure pre-adventure
// -------------------------------------


// stow items that we don't want to be auto-used, or which need to be stowed in order to drop
void stowItems() {
	// put in storage items that get auto-used and which we don't want to be auto-used
	put_closet(item_amount($item[funky junk key]), $item[funky junk key]);
	put_closet(item_amount($item[bowling ball]), $item[bowling ball]); // in ronin as well??
	put_closet(item_amount($item[twist of lime]), $item[twist of lime]);
	put_closet(item_amount($item[Swizzler]), $item[Swizzler]);
	put_closet(item_amount($item[thriftshop coupon]), $item[thriftshop coupon]);

	// having none blocks the lucky gold ring from dropping them -- we want the lucky gold ring to drop better items
	if (equipped_amount($item[lucky gold ring]) >= 1) {
    	put_closet(item_amount($item[sand dollar]), $item[sand dollar]);
    	put_closet(item_amount($item[hobo nickel]), $item[hobo nickel]);
    }

	// can't get the superlikely adventure if we have any in our inventory
	put_closet(item_amount($item[Elf Farm Raffle ticket]), $item[Elf Farm Raffle ticket]);

	// having none allows them to drop from the Boxing Daydream
	put_closet(item_amount($item[bauxite beret]), $item[bauxite beret]);
	put_closet(item_amount($item[bauxite boxers]), $item[bauxite boxers]);
	put_closet(item_amount($item[bauxite bow-tie]), $item[bauxite bow-tie]);
	put_closet(item_amount($item[My First Art of War]), $item[My First Art of War]);
	put_closet(item_amount($item[Boxing Day Pass]), $item[Boxing Day Pass]);

	// these get transformed by opening the dungeon
	put_closet(item_amount($item[percent sign]), $item[percent sign]);
	put_closet(item_amount($item[lowercase a]), $item[lowercase a]);
	put_closet(item_amount($item[left parenthesis]), $item[left parenthesis]);
	put_closet(item_amount($item[right parenthesis]), $item[right parenthesis]);
	put_closet(item_amount($item[left bracket]), $item[left bracket]);
	put_closet(item_amount($item[equal sign]), $item[equal sign]);
	put_closet(item_amount($item[dollar sign]), $item[dollar sign]);

    // having none allow them to be dropped in the mer-kin gym NC
    put_closet(item_amount($item[Mer-kin dodgeball]), $item[Mer-kin dodgeball]);
    put_closet(item_amount($item[Mer-kin dragnet]), $item[Mer-kin dragnet]);
    put_closet(item_amount($item[Mer-kin headguard]), $item[Mer-kin headguard]);
    put_closet(item_amount($item[Mer-kin switchblade]), $item[Mer-kin switchblade]);
    put_closet(item_amount($item[Mer-kin thighguard]), $item[Mer-kin thighguard]);

    // make sure we have a skeleton key so we can use it at The Skeleton Store's NC (ring of telling skeletons what to do is worth ~2k meat)
    if (item_amount($item[skeleton key]) == 0)
    	fullAcquire($item[skeleton key], 1, 100);
}



void preAdventureChecks(int checkTurns) {
	assert(!inCombat(), "preAdventureChecks: called while we're in combat");
	assert(my_adventures() > 0, "preAdventureChecks: called with no adventures");

	print("preAdventureChecks: " + checkTurns + " turns in advance", "green");

	check_counters(checkTurns, kAbortOnCounter);
	burnExtraMP();
// 	dressup(); // would be nice, but no way to get it

	// CURSED MAGNIFYING GLASS WARNING
	if (inRonin() && get_property("cursedMagnifyingGlassCount").to_int() >= 13 && !get_property("_smm.VoidMonsterWarningDone").to_boolean() && equipped_amount($item[cursed magnifying glass]) >= 1) {
		if (!user_confirm("You're about to adventure with the cursed magnifying glass when a void monster is expected next... Continue?", 60000, true))
			abort("user aborted");
		set_property("_smm.VoidMonsterWarningDone", true);
	} else if (get_property("cursedMagnifyingGlassCount").to_int() == 0)
		set_property("_smm.VoidMonsterWarningDone", false);

	// LIL DOCTOR BAG QUEST ITEM
	if (get_property("questDoctorBag") == "started") {
		item docQuestItem = get_property("doctorBagQuestItem").to_item();
		string docQuestNumberString = get_property("doctorQuestNumber");
		int docQuestNumber = docQuestNumberString == "" ? 1 : docQuestNumberString.to_int();
		int acquired = fullAcquire(docQuestItem, docQuestNumber);

		assert(item_amount(docQuestItem) >= docQuestNumber, "preAdventureChecks: couldn't get " + docQuestNumber + "X " + docQuestItem + " for a Lil' Doctor bag quest, only got " + acquired);
	}

	// TINY STILLSUIT make sure it's equipped somewhere TODO needs work
	item currentFamEquipment = equipped_item($slot[familiar]);
	if (currentFamEquipment != $item[tiny stillsuit]) {
		familiar currentFamiliar = my_familiar();
		item [familiar] allFamEE = all_familiar_equipped_equipment();
		familiar roninFam = currentFamiliar == $familiar[Grey Goose] ? $familiar[Cookbookbat] : $familiar[Grey Goose]; // the familiar that will wear the stillsuit if our current fam isn't wearing it
		familiar aftercoreFam = currentFamiliar == $familiar[Pocket Professor] ? $familiar[Grey Goose] : $familiar[Pocket Professor]; // the familiar that will wear the stillsuit if our current fam isn't wearing it
		familiar backupFam = inRonin() ? roninFam : aftercoreFam;

		if (allFamEE[backupFam] != $item[tiny stillsuit]) {
			use_familiar(backupFam);
			equip($item[tiny stillsuit]);
			use_familiar(currentFamiliar);
			if (equipped_item($slot[familiar]) != currentFamEquipment)
				equip(currentFamEquipment);
		}
	}

	// TELEPORTITIS -- since we have a ring that gets us this debuff whenever we want, we generally want to ensure we don't have it
	if (have_effect($effect[Teleportitis]) > 0 && user_confirm("Uneffect Teleportitis?", 12000, true))
		ensureNoTeleportitis();

	// ASDON MARTIN fuel
	if (isAsdonWorkshed())
		ensureAsdonMartinFuel(150);

    stowItems();

	// GOALS
	if (count(get_goals()) > 0)
		set_property(kHadGoalsKey, "true");
	else
		set_property(kHadGoalsKey, "false");

    print("preAdventureChecks: done", "green");
}

void preAdventureChecks() {
	preAdventureChecks(0);
}



// does all the bookkeeping and item management that happens after an adventure.
// mostly hiding items in the closet so more of the same can drop or they won't be accidentally used.
// also handles the goal mechanism.
// TODO: play with the boombox???? can only do 11/day
// TODO: LOVe potion #0 / tainted LOVe potion
// returns true if we succeeded and there were goals at the start of the adventure and all goals were satisfied in the last adventure
// returns false if we succeeded and not all goals were satisfied
// failures will raise
// only useful outside of combat
boolean postAdventure() {
	assert(!inCombat(), "postAdventure: called while we're still in combat");

	print("postAdventure", "green");
	monster lastMonster = last_monster();
	location lastLocation = my_location();
	int lastChoice = last_choice();
	string pageString;

	// smut orc pervert progress
	if (lastLocation == $location[The Smut Orc Logging Camp]) {
		setSmutOrcPervertProgress(smutOrcPervertProgress() + 1);
		print("setting smutOrcPervertProgress to: " + smutOrcPervertProgress() + ", turns spent in zone: " + $location[The Smut Orc Logging Camp].turns_spent + ", turns in zone for last pervert: " + to_int(get_property(kLastSmutOrcPervertTurnsSpentKey)));
	}
	if (lastMonster == $monster[smut orc pervert]) {
		int lastSmutOrcPervertTurnsSpent = to_int(get_property(kLastSmutOrcPervertTurnsSpentKey));
		print("found Smut Orc Pervert, progress was " + smutOrcPervertProgress() + ", resetting progress to 0 -- turns spent in zone: " + $location[The Smut Orc Logging Camp].turns_spent + ", turns in zone for last pervert: " + lastSmutOrcPervertTurnsSpent, "orange");
		set_property(kLastSmutOrcPervertTurnsSpentKey, $location[The Smut Orc Logging Camp].turns_spent - 1);
		setSmutOrcPervertProgress(0);
	}

	// turtle tamer adventure
	if (my_class() == $class[Turtle Tamer]) {
		if (kTurtleAdventureTurnsKey.get_property() == "" || kTurtleAdventureTurnsKey.get_property().to_int() <= 0)
			kTurtleAdventureTurnsKey.set_property("16");
		kTurtleAdventureTurnsKey.set_property(kTurtleAdventureTurnsKey.get_property().to_int() + 1);
	}

	// sentient ATM progress
	if (lastLocation == $location[The Post-Mall]) {
		setSentientATMProgress(sentientATMProgress() + 1);
		print("setting sentientATMProgress to: " + sentientATMProgress());
	}
	if (lastMonster == $monster[sentient ATM]) {
		print("found sentient ATM, progress was " + sentientATMProgress() + ", resetting progress to 0", "orange");
		setSentientATMProgress(0);
	}

	// bug fix for feelNostalgicMonster, which doesn't seem to update
	if (lastMonster != get_property("feelNostalgicMonster").to_monster()
		&& isCopyable(lastMonster))
		set_property("feelNostalgicMonster", lastMonster);
	// bug fix for guyMadeOfBeesDefeated, which isn't always updated
	if (item_amount($item[guy made of bee pollen]) >= 1 && !"guyMadeOfBeesDefeated".get_property().to_boolean()
		&& user_confirm("we now have guy made of bee pollen in our inventory but guyMadeOfBeesDefeated is false, set it to true?", 60000, true))
		set_property("guyMadeOfBeesDefeated", "true");

	// AFTERCORE
	if (!inRonin() && !inCombat() && !handling_choice()) {
		cli_execute("dreadstopper"); // TODO move to pre-adventure???

		// Agora progress
		if (lastLocation == $location[The Roman Forum]) {
			setAgoraProgress(agoraProgress() + 1);
			print("setting agoraProgress to: " + agoraProgress());
		}
		if (lastChoice == 979 || lastChoice == 980 || lastChoice == 982 || lastChoice == 983) {
			print("found agora, progress was " + agoraProgress() + ", resetting progress to 0", "orange");
			setAgoraProgress(0);
		}

        stowItems();

		// NUMBEROLOGY -- get +3 adv
		if ("_universeCalculated".get_property().to_int() < 1) { // TODO number depends on number of times we got the Manual of Numberology
			string numOut = cli_execute_output("numberology help");
			matcher numMatcher = create_matcher("Calculate the Universe with [0-9]+ to get: 3 Adventures", numOut);
			if (find(numMatcher))
				cli_execute("numberology 69");
		}

		// GUZZLR -- make sure we have a gold quest open at all times if possible
		// use the cancel on the platinum quest
		if (questStage("questGuzzlr") < 0 // not started
			&& get_property("_guzzlrPlatinumDeliveries").to_int() == 0 // no platinum deliveries made
			&& !get_property("_guzzlrQuestAbandoned").to_boolean()) // we haven't abandoned a quest yet
			getAndCancelPlatinumGuzzlrQuest();

		// get the gold quest
		if (questStage("questGuzzlr") == -1 // unstarted
			&& get_property("_guzzlrGoldDeliveries").to_int() < 3) {
			if (isRegularClass()) {
				getGoldGuzzlrQuest();
			} else {
				print("skipping Guzzlr quest, we're not a regular class and might get sent to somewhere we can't reach", "orange");
			}
		}

		// COLD MEDICINE cabinet
		if (isColdMedicineWorkshed()) {
			if (canConsultColdMedicineCabinet())
				getColdMedicineCabinetMedication();
			else if (!get_property("_workshedItemUsed").to_boolean() && get_property("_coldMedicineConsults").to_int() >= 5)
				print("we can switch workshed items now, and we're done with the cold medicine cabinet for today", "red");
		}

		// MAYDAY PACKAGE
		if (have_item($item[MayDay&trade; supply package]))
			use($item[MayDay&trade; supply package]);

		// SPACE JELLYFISH
		if (last_choice() == 305 && last_decision() == 3)
			set_property(kSpaceJellyfishDeepSauceCollectedKey, "true");

		// OLIVER'S PLACE milk caps need to be spent
		if (have_item($item[milk cap]) || have_item($item[the Sot's parcel])) {
			if (have_item($item[the Sot's parcel])) {
				visit_url("/place.php?whichplace=speakeasy&action=olivers_sot", false, false);
				cli_execute("refresh inv");
			}
			buy($coinmaster[Fancy Dan the Cocktail Man], 1, $item[Strong, Silent Type]);
			assert(!have_item($item[milk cap]) && !have_item($item[the Sot's parcel]), "still have the milk cap!");
		}

		// CLOSED-CIRCUIT PAY PHONE Rufus quest
		if (questStage("questRufus") == 1) {
			// quest finished, complete it.
			visit_url("/inv_use.php?pwd&which=3&whichitem=11169", true, false);
			pageString = run_choice(1);
			assert(pageString.contains_text("Rufus's shadow lodestone"), "we didn't get the right response, we expect 'Rufus's shadow lodestone' from page " + pageString);
			assert(questStage("questRufus") == -1, "tried to finish the Rufus quest and we got the right result page, but it still isn't completed");
		}
		if (questStage("questRufus") < 0 && !have_item($item[Rufus's shadow lodestone])) { // bug in kolmafia resets the quest progress when we use the lodestone
			getRufusQuest(1);
		}

		// JUNE'S CLEAVER -- reset choice adventures when we run out of skips
		if ("_juneCleaverSkips".get_property().to_int() == 5) {
// 			saveAndSetProperty("choiceAdventure1467", "3"); // +5 adv (vs stats) -- same choice as before
			saveAndSetProperty("choiceAdventure1468", "2"); // 5 meat and stats (vs stats)
			saveAndSetProperty("choiceAdventure1469", "2"); // 1500 meat (vs dad's brandy or ml)
			saveAndSetProperty("choiceAdventure1470", "2"); // teacher's pen (vs stats or lame buff)
// 			saveAndSetProperty("choiceAdventure1471", "1"); // savings bond (vs 250 meat or stats) -- same choice as before
			saveAndSetProperty("choiceAdventure1472", (available_amount($item[trampled ticket stub]) > available_amount($item[fire-roasted lake trout]) ? "2" : "1")); // trampled ticket stub or fire-roasted lake trout (vs stats) -- choose the one we have least of
			saveAndSetProperty("choiceAdventure1473", "1"); // gob of wet hair and stats (vs lame buffs)
			saveAndSetProperty("choiceAdventure1474", "2"); // guilty sprout (vs stats)
// 			saveAndSetProperty("choiceAdventure1475", "1"); // mother's necklace (vs stats or random buffs) -- same choice as before

			set_property("_juneCleaverSkips", "6");
		}

	// IN RONIN
	} else if (!inCombat() && !handling_choice()) {
		// FIREWORKS -- ensure we have one rocket of each colour at all times
		if (my_meat() > 5000 && item_amount($item[red rocket]) == 0 && have_effect($effect[Everything Looks Red]) == 0)
			newAcquire($item[red rocket], 1, 250);
		if (my_meat() > 5000 && item_amount($item[blue rocket]) == 0 && have_effect($effect[Everything Looks Blue]) == 0)
			newAcquire($item[blue rocket], 1, 250);
		if (my_meat() > 5000 && item_amount($item[yellow rocket]) == 0 && have_effect($effect[Everything Looks Yellow]) == 0)
			newAcquire($item[yellow rocket], 1, 250);
	}

	// NOTICES TODO could add one for familiar minigame completion?
	if (have_effect($effect[Everything Looks Yellow	]) == 0)
		print("Yellow Ray is ready!", "red");
	if (my_adventures() == 0 && !inRonin())
		print("ZERO adventures! Fight an XO monster?", "red");
	if (canConsultColdMedicineCabinet())
		print("cold medicine cabinet is ready", "red");
	if (!inRonin() && isColdMedicineWorkshed() && get_property("_coldMedicineConsults").to_int() >= 5 && !get_property("_workshedItemUsed").to_boolean())
		print("cold medicine cabinet is EMPTY!", "red");
	if (get_property("cursedMagnifyingGlassCount").to_int() >= 13 && get_property("_voidFreeFights").to_int() <= 5)
		print("cursed magnifying glass is ready", "red");
	if (have_item($item[MayDay&trade; supply package]))
		print("have MayDay™ supply package", "red");
	if (have_item($item[milk cap]))
		print("have milk cap", "red");

	if (have_item($item[autumn-aton]) && !isOverdrunk()) {
		if (inRonin()) {
			print("Autumn-aton READY!!!!!!!!!!!!", "red");
		} else {
			sendAutumnaton();
			assert(!have_item($item[autumn-aton]), "didn't send autumn-aton!");
		}
	}

	if (("familiarSweat".get_property().to_int() >= 279 && "familiarSweat".get_property().to_int() <= 281) // 10 adv
		|| ("familiarSweat".get_property().to_int() >= 358 && "familiarSweat".get_property().to_int() <= 360) // 11 adv
		|| ("familiarSweat".get_property().to_int() >= 449 && "familiarSweat".get_property().to_int() <= 451) // 12 adv
		|| ("familiarSweat".get_property().to_int() >= 554 && "familiarSweat".get_property().to_int() <= 556) // 13 adv
		|| "familiarSweat".get_property().to_int() >= 672) { // 14 adv -- drink any time we can
		if (my_inebriety() < inebriety_limit())
			drinkStillsuitDistillate();
		else
			print("have enough familiar sweat to drink but no room in our liver!", "red");
	}

	// GOALS and return value: true iff we have satisfied our goals
	boolean rval = false;
	if (to_boolean(get_property(kHadGoalsKey)) && !haveGoals()) {
		print("conditions have been satisfied!", "green");
		set_property(kHadGoalsKey, "false");
		rval = true;
	}

    if (wantToGrindSausageGoblin()) {
        print("grinding sausage goblin", "blue");
    	checkForLastSausageGoblin();
        // grindSausageGoblin();
    }

    return rval;
}



// Adventure using visit_url instead of adventure() -- but also attempts to do all the pre-stuff that adventure() does.
// Post-stuff will have to be done elsewhere... Useful when you want the pre-turn automation of adventure() without the turn
// or post-turn automation
// checkTurns is the number of turns to check ahead for counter expiry, where 0 is next turn
// Returns the text of the page returned by visit_url
// Typically, this will return mid-adventure, so you will need to run_turn() or whatever after this.
string advURL(string aURL, int checkTurns, boolean isPost, boolean urlEncoded) {
	preAdventureChecks(checkTurns);
	logEquipment(true);
	return visit_url(aURL, isPost, urlEncoded);
}

string advURL(string aLocation, boolean isPost, boolean urlEncoded) {
	return advURL(aLocation, 0, isPost, urlEncoded);
}

string advURL(string aLocation) {
	return advURL(aLocation, 0, false, false);
}

string advURL(location aLocation, int checkTurns, boolean isPost, boolean urlEncoded) {
	notesForLocation(aLocation);
	return advURL(to_url(aLocation), checkTurns, isPost, urlEncoded);
}

string advURL(location aLocation, int checkTurns) {
	return advURL(to_url(aLocation), checkTurns, false, false);
}

string advURL(location aLocation) {
	return advURL(aLocation, 0);
}



// -------------------------------------
// THINGS THAT SPEND TURNS AND REQUIRE postAdventure()
// -------------------------------------


// returns money spent
int daycareRecruit() {
	int startingMeat = my_meat();
	print("daycareRecruit, starting meat: " + startingMeat, "green");

	preAdventureChecks(0); // takes money, not turns
	visit_url("/place.php?whichplace=town_wrong&action=townwrong_boxingdaycare", true, false);
	visit_url("/choice.php?pwd&whichchoice=1334&option=3", true, false);
	visit_url("/choice.php?pwd&whichchoice=1336&option=1", true, false);
	visit_url("/main.php", true, false);
	postAdventure();

	return startingMeat - my_meat();
}


boolean daycareSpar() {
	print("daycareSpar", "green");
	int startingPVPFights = pvp_attacks_left();

	preAdventureChecks(0);
	visit_url("/place.php?whichplace=town_wrong&action=townwrong_boxingdaycare", true, false);
	visit_url("/choice.php?pwd&whichchoice=1334&option=3", true, false);
	visit_url("/choice.php?pwd&whichchoice=1336&option=4", true, false);
	visit_url("/main.php", true, false);
	postAdventure();

	return pvp_attacks_left() > startingPVPFights;
}


void daycareScavenge() {
	print("daycareScavenge", "green");

	preAdventureChecks(3); // spending up to 3 turns, so do check manually
	advURL("/place.php?whichplace=town_wrong&action=townwrong_boxingdaycare", 1, true, false);
	run_choice(3);
	run_choice(2);
	visit_url("/main.php", true, false);
	postAdventure();
	//visit_url("/choice.php?pwd&whichchoice=1334&option=3", true, false);
	//visit_url("/choice.php?pwd&whichchoice=1336&option=2", true, false);
}

void burnScavengeDaycare(int turnsToSpend) {
	print("burnScavengeDaycare: " + turnsToSpend + " turns", "green");

	int daycareGymScavenges = to_int(get_property("_daycareGymScavenges"));
	int nextScavengeTurnCost = min(daycareGymScavenges, 3);

	while (turnsToSpend >= nextScavengeTurnCost) {
		print("scavenging...");
		daycareScavenge();
		turnsToSpend -= nextScavengeTurnCost;
		daycareGymScavenges = to_int(get_property("_daycareGymScavenges"));
		nextScavengeTurnCost = min(daycareGymScavenges, 3);
	}
}



// enter combat with the given monster via the combat lover's locket
string cllGetToFight(monster fightMon) {
	assert(cllNumMonstersFought() < 3, "not enough combat lover's locket fights");
	assert(!cllHasFought(fightMon), "we already fought that monster");

	advURL("/inventory.php?reminisce=1");
	return visit_url("/choice.php?whichchoice=1463&pwd&option=1&mid=" + fightMon.to_int(), true, false);
}

// Compatibility with scripts written before the restored Mac utility API.
int amountAtRank(int rank, int [int, string] collection) { return amountAtRank(collection, rank); }
string nameAtRank(int rank, int [int, string] collection) { return nameAtRank(collection, rank); }
int monsterItemMeatValue(monster mob, float bonus) { return monsterItemMeatValue(mob, false, bonus); }
int monsterCurrentItemMeatValue(monster mob) { return monsterCurrentItemMeatValue(mob, false); }
int monsterTotalMeatValue(monster mob, float items, float meat) { return monsterTotalMeatValue(mob, false, items, meat); }
int monsterCurrentTotalMeatValue(monster mob) { return monsterCurrentTotalMeatValue(mob, false); }
int locationCurrentMeatValue(location loc) { return locationCurrentMeatValue(loc, false); }
