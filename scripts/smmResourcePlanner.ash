// Shared budgets and bounded optimal allocation. No imports or game actions.
// Values are incremental to the caller's baseline, not gross monster income.
string __smm_resource_planner_version = "1.0";

record SmmRPResource {
    string label;
    int remaining;
    boolean known;
    string reason;
};

record SmmRPAction {
    string description;
    int limit;
    boolean eligible;
    string unavailable_reason;
    boolean valued;
    float direct_meat;
    float loot_value;
    float adventure_delta;
    float avoided_cost;
    float input_cost;
    float displaced_value;
    float future_cost;
    string goal;
    int missing;
    float collection_value;
    int [string] costs;
    // Mutually exclusive configuration across this planning block, e.g. workshed.
    // Do not use this for a familiar that can change between encounters.
    string choice_group;
    string choice;
};

record SmmRPContext {
    string owner;
    float turn_value;
    boolean collection;
    int collection_budget;
    int node_limit;
};

record SmmRPReservation {
    string resource;
    string owner;
    int units;
};

record SmmRPPlan {
    int [string] quantity;
    string [string] reason;
    float economic_value;
    float objective_value;
    int nodes;
    boolean optimal;
    boolean valid;
    string error;
    string fingerprint;
};

record SmmRPLease {
    string owner;
    string epoch;
    string previous_owner;
    SmmRPResource [string] before;
};

record SmmRPLootEstimate {
    float value;
    boolean complete;
    string reason;
};

boolean smmRPIdentifier(string id) {
    return create_matcher("^[a-zA-Z0-9_.:-]+$", id).find();
}

float smmRPEconomicValue(SmmRPAction action, SmmRPContext context) {
    return action.direct_meat + action.loot_value + action.adventure_delta * context.turn_value
        + action.avoided_cost - action.input_cost - action.displaced_value - action.future_cost;
}

SmmRPAction smmRPNewAction(string description, int limit, float incremental_meat) {
    SmmRPAction action;
    action.description = description;
    action.limit = limit;
    action.eligible = true;
    action.valued = true;
    action.direct_meat = incremental_meat;
    return action;
}

SmmRPAction smmRPCloneAction(SmmRPAction source) {
    SmmRPAction a;
    a.description=source.description; a.limit=source.limit; a.eligible=source.eligible;
    a.unavailable_reason=source.unavailable_reason; a.valued=source.valued;
    a.direct_meat=source.direct_meat; a.loot_value=source.loot_value;
    a.adventure_delta=source.adventure_delta; a.avoided_cost=source.avoided_cost;
    a.input_cost=source.input_cost; a.displaced_value=source.displaced_value;
    a.future_cost=source.future_cost; a.goal=source.goal; a.missing=source.missing;
    a.collection_value=source.collection_value; a.choice_group=source.choice_group; a.choice=source.choice;
    foreach resource, cost in source.costs a.costs[resource]=cost;
    return a;
}

string smmRPEpoch() {
    return today_to_string() + ":" + my_ascensions();
}

// Explicit epoch avoids depending on Mafia's handling of unknown _ properties.
SmmRPReservation [int] smmRPReservations() {
    SmmRPReservation [int] result;
    if (get_property("smmPlanner.reservationEpoch") != smmRPEpoch()) return result;
    string text = get_property("smmPlanner.reservations");
    if (text == "") return result;
    foreach i, line in split_string(text, ";") {
        string [int] fields = split_string(line, ",");
        if (count(fields) != 3 || !smmRPIdentifier(fields[0]) || !smmRPIdentifier(fields[1])
            || !create_matcher("^[0-9]+$", fields[2]).find())
            abort("Invalid smmPlanner reservation ledger; use resources clear to repair it.");
        int units = fields[2].to_int();
        if (units < 0) abort("Overflow in smmPlanner reservation ledger.");
        result[count(result)] = new SmmRPReservation(fields[0], fields[1], units);
    }
    return result;
}

void smmRPSaveReservations(SmmRPReservation [int] entries) {
    string text;
    foreach i, entry in entries {
        if (entry.units <= 0) continue;
        if (text != "") text += ";";
        text += entry.resource + "," + entry.owner + "," + entry.units;
    }
    set_property("smmPlanner.reservations", text);
    set_property("smmPlanner.reservationEpoch", smmRPEpoch());
}

int smmRPReservedForOthers(string resource, string owner, SmmRPReservation [int] entries) {
    int result;
    foreach i, entry in entries
        if (entry.resource == resource && entry.owner != owner) {
            if (entry.units > 1000000000 - result) return 1000000000;
            result += entry.units;
        }
    return result;
}

int smmRPSpendable(string resource, string owner, SmmRPResource [string] resources,
                   SmmRPReservation [int] entries) {
    if (!(resources contains resource) || !resources[resource].known) return 0;
    return max(0, resources[resource].remaining - smmRPReservedForOthers(resource, owner, entries));
}

// Pure snapshots: never refresh, pull, acquire, maximize or query the Mall here.
boolean smmRPOwns(string kind, string name) {
    if (!can_interact()) return false; // initial scope is unrestricted aftercore
    if (kind == "item") {
        item it = to_item(name);
        return it != $item[none] && is_unrestricted(it) && available_amount(it) > 0;
    }
    if (kind == "familiar") {
        familiar fam = to_familiar(name);
        return fam != $familiar[none] && is_unrestricted(fam) && have_familiar(fam);
    }
    if (kind == "skill") {
        skill sk = to_skill(name);
        return sk != $skill[none] && have_skill(sk);
    }
    if (kind == "workshed") return get_workshed() == to_item(name);
    return false;
}

void smmRPPool(SmmRPResource [string] pools, string id, string label, string property,
               int capacity, string mode, string kind, string source) {
    SmmRPResource pool;
    pool.label = label;
    pool.known = property_exists(property);
    if (!pool.known) pool.reason = "unknown Mafia property " + property;
    else {
        string raw = get_property(property);
        boolean valid = mode == "boolean" ? (raw == "true" || raw == "false")
            : create_matcher("^[0-9]+$", raw).find();
        if (!valid) {
            pool.known = false;
            pool.reason = "invalid value for " + property;
        } else {
            int used = mode == "boolean" ? (raw.to_boolean() ? 1 : 0) : raw.to_int();
            if (used < 0) { pool.known = false; pool.reason = "overflow in " + property; }
            else pool.remaining = mode == "balance" ? used : max(0, capacity - used);
        }
    }
    if (!smmRPOwns(kind, source)) {
        pool.remaining = 0;
        pool.reason = "source unavailable in unrestricted aftercore: " + source;
    }
    pools[id] = pool;
}

SmmRPResource [string] smmRPLiveResources() {
    SmmRPResource [string] p;
    smmRPPool(p,"maiden.physical","Maiden Physical blessing","_blessingShieldPhysicalReceived",1,"boolean","familiar","Meat Shield Maiden");
    smmRPPool(p,"maiden.hot","Maiden Hot blessing","_blessingShieldHotReceived",1,"boolean","familiar","Meat Shield Maiden");
    smmRPPool(p,"maiden.cold","Maiden Cold blessing","_blessingShieldColdReceived",1,"boolean","familiar","Meat Shield Maiden");
    smmRPPool(p,"maiden.spooky","Maiden Spooky blessing","_blessingShieldSpookyReceived",1,"boolean","familiar","Meat Shield Maiden");
    smmRPPool(p,"maiden.stench","Maiden Stench blessing","_blessingShieldStenchReceived",1,"boolean","familiar","Meat Shield Maiden");
    smmRPPool(p,"maiden.sleaze","Maiden Sleaze blessing","_blessingShieldSleazeReceived",1,"boolean","familiar","Meat Shield Maiden");
    smmRPPool(p,"acorn.plants","Acorn plantings","_legendaryAcornsUsed",12,"used","item","legendary acorndion");
    smmRPPool(p,"sword.loot","Sword loot replacements","_swordOfSWordsKills",100,"used","familiar","Sword of S Words");
    smmRPPool(p,"sword.targets","Sword target changes","_swordOfSWordsMonsterChanged",3,"used","familiar","Sword of S Words");
    smmRPPool(p,"club.battlefield","Across the Battlefield","_clubEmBattlefieldUsed",5,"used","item","legendary seal-clubbing club");
    smmRPPool(p,"club.nextweek","Into Next Week","_clubEmNextWeekUsed",5,"used","item","legendary seal-clubbing club");
    smmRPPool(p,"club.backtime","Back in Time","_clubEmTimeUsed",5,"used","item","legendary seal-clubbing club");
    smmRPPool(p,"spade.digs","Spade successful digs","_archSpadeDigs",11,"used","item","Archaeologist's Spade");
    smmRPPool(p,"baseball.innings","Baseball innings","_baseballInnings",3,"used","item","Baseball Diamond");
    smmRPPool(p,"cup.jewels","Cup jewels","_cupOf13sJewels",13,"balance","item","Cup of 13s");
    smmRPPool(p,"heart.kill","Heartstone kills","_heartstoneKillUsed",5,"used","item","Heartstone");
    smmRPPool(p,"heart.banish","Heartstone banishes","_heartstoneBanishUsed",5,"used","item","Heartstone");
    smmRPPool(p,"heart.stun","Heartstone stuns","_heartstoneStunUsed",5,"used","item","Heartstone");
    smmRPPool(p,"heart.pals","Heartstone familiar buffs","_heartstonePalsUsed",5,"used","item","Heartstone");
    smmRPPool(p,"heart.buff","Heartstone attribute buffs","_heartstoneBuffUsed",5,"used","item","Heartstone");
    smmRPPool(p,"heart.luck","Heartstone Lucky","_heartstoneLuckUsed",1,"boolean","item","Heartstone");
    smmRPPool(p,"pasta.crafts","Pasta wand free crafts","_legendaryPastaWandCrafting",5,"used","item","legendary pasta wand");
    smmRPPool(p,"bat.swoop","Bat pickpockets","_batWingsSwoopUsed",11,"used","item","bat wings");
    smmRPPool(p,"bat.rest","Bat recovery","_batWingsRestUsed",11,"used","item","bat wings");
    smmRPPool(p,"bat.cauldron","Bat damage skills","_batWingsCauldronUsed",11,"used","item","bat wings");
    smmRPPool(p,"bat.savings","Bat turn savings","_batWingsFreeFights",5,"used","item","bat wings");
    smmRPPool(p,"camera.copies","Camera replacements","_backUpUses",11,"used","item","backup camera");
    smmRPPool(p,"mimic.eggs","Mimic egg creations","_mimicEggsObtained",11,"used","familiar","Chest Mimic");
    smmRPPool(p,"beret.busking","Beret busking","_beretBuskingUses",5,"used","item","prismatic beret");
    smmRPPool(p,"beret.blast","Beret blasts","_beretBlastUses",11,"used","item","prismatic beret");
    smmRPPool(p,"beret.boast","Beret boasts","_beretBoastUses",11,"used","item","prismatic beret");
    smmRPPool(p,"monodent.wave","Monodent wave","_seadentWaveUsed",1,"boolean","item","Monodent of the Sea");
    smmRPPool(p,"monodent.lightning","Monodent lightning","_seadentLightningUsed",11,"used","item","Monodent of the Sea");
    smmRPPool(p,"sweat.points","Sweatpants sweat","sweat",100,"balance","item","designer sweatpants");
    smmRPPool(p,"sweat.booze","Sweat booze reductions","_sweatOutSomeBoozeUsed",3,"used","item","designer sweatpants");
    smmRPPool(p,"cinch.points","Cinch","_cinchUsed",100,"used","item","Cincho de Mayo");
    smmRPPool(p,"glove.battery","Powerful Glove battery","_powerfulGloveBatteryPowerUsed",100,"used","item","Powerful Glove");
    smmRPPool(p,"meteor.replacements","Macrometeorites","_macrometeoriteUses",10,"used","skill","Macrometeorite");
    smmRPPool(p,"doctor.xray","Chest X-Rays","_chestXRayUsed",3,"used","item","Lil' Doctor™ bag");
    smmRPPool(p,"doctor.hammer","Reflex Hammers","_reflexHammerUsed",3,"used","item","Lil' Doctor™ bag");
    smmRPPool(p,"doctor.otoscope","Otoscopes","_otoscopeUsed",3,"used","item","Lil' Doctor™ bag");
    smmRPPool(p,"emotion.envy","Feel Envy","_feelEnvyUsed",3,"used","skill","Feel Envy");
    smmRPPool(p,"emotion.nostalgic","Feel Nostalgic","_feelNostalgicUsed",3,"used","skill","Feel Nostalgic");
    smmRPPool(p,"emotion.hatred","Feel Hatred","_feelHatredUsed",3,"used","skill","Feel Hatred");
    smmRPPool(p,"emotion.pride","Feel Pride","_feelPrideUsed",3,"used","skill","Feel Pride");
    smmRPPool(p,"saber.force","Saber Force","_saberForceUses",5,"used","item","Fourth of May Cosplay Saber");
    smmRPPool(p,"genie.wishes","Genie bottle wishes","_genieWishesUsed",3,"used","item","genie bottle");
    smmRPPool(p,"monkey.wishes","Monkey wishes","_monkeyPawWishesUsed",5,"used","item","cursed monkey's paw");
    smmRPPool(p,"time.minutes","Time-Spinner minutes","_timeSpinnerMinutesUsed",10,"used","item","Time-Spinner");
    smmRPPool(p,"latte.banish","Latte banish before refill","_latteBanishUsed",1,"boolean","item","latte lovers member's mug");
    smmRPPool(p,"latte.copy","Latte copy before refill","_latteCopyUsed",1,"boolean","item","latte lovers member's mug");
    smmRPPool(p,"latte.refills","Latte refills","_latteRefillsUsed",3,"used","item","latte lovers member's mug");
    smmRPPool(p,"kgb.darts","Briefcase darts","_kgbTranquilizerDartUses",3,"used","item","Kremlin's Greatest Briefcase");
    smmRPPool(p,"scrapbook.charges","Scrapbook charges","scrapbookCharges",0,"balance","item","familiar scrapbook");
    smmRPPool(p,"embers","Sept-Embers","availableSeptEmbers",0,"balance","item","Sept-Ember Censer");
    smmRPPool(p,"catalog.credits","2002 catalog credits","availableMrStore2002Credits",0,"balance","item","2002 Mr. Store Catalog");
    smmRPPool(p,"taker.spice","TakerSpace spices","takerSpaceSpice",0,"balance","workshed","TakerSpace letter of Marque");
    smmRPPool(p,"taker.rum","TakerSpace rum","takerSpaceRum",0,"balance","workshed","TakerSpace letter of Marque");
    smmRPPool(p,"taker.anchor","TakerSpace anchors","takerSpaceAnchor",0,"balance","workshed","TakerSpace letter of Marque");
    smmRPPool(p,"taker.mast","TakerSpace masts","takerSpaceMast",0,"balance","workshed","TakerSpace letter of Marque");
    smmRPPool(p,"taker.silk","TakerSpace silk","takerSpaceSilk",0,"balance","workshed","TakerSpace letter of Marque");
    smmRPPool(p,"taker.gold","TakerSpace gold","takerSpaceGold",0,"balance","workshed","TakerSpace letter of Marque");
    smmRPPool(p,"shattering.kills","Shattering Punches","_shatteringPunchUsed",3,"used","skill","Shattering Punch");
    smmRPPool(p,"ginger.kills","Gingerbread Mob Hit","_gingerbreadMobHitUsed",1,"boolean","skill","Gingerbread Mob Hit");
    smmRPPool(p,"asdon.missile","Asdon missile","_missileLauncherUsed",1,"boolean","workshed","Asdon Martin keyfob");
    foreach color in $strings[Red,Blue,Yellow,Green,Purple] {
        SmmRPResource pool;
        pool.label = "Everything Looks " + color + " cooldown gate";
        pool.known = true;
        pool.remaining = have_effect(to_effect("Everything Looks " + color)) == 0 ? 1 : 0;
        p["color." + color.to_lower_case()] = pool;
    }
    return p;
}

string smmRPFingerprint(SmmRPResource [string] resources, SmmRPReservation [int] entries,
                        SmmRPContext context) {
    string value = smmRPEpoch() + "|" + context.owner + "|" + context.turn_value + "|"
        + context.collection + "|" + context.collection_budget;
    foreach id, r in resources value += "|" + id + ":" + r.known + ":" + r.remaining;
    foreach i, e in entries value += "|reserve:" + e.resource + ":" + e.owner + ":" + e.units;
    return value;
}

string smmRPModelFingerprint(SmmRPAction [string] actions) {
    string value;
    foreach id, a in actions {
        value += "|action:" + id + ":" + a.description + ":" + a.limit + ":" + a.eligible + ":" + a.valued
            + ":" + a.direct_meat + ":" + a.loot_value + ":" + a.adventure_delta + ":" + a.avoided_cost
            + ":" + a.input_cost + ":" + a.displaced_value + ":" + a.future_cost + ":" + a.goal
            + ":" + a.missing + ":" + a.collection_value + ":" + a.choice_group + ":" + a.choice;
        foreach pool, cost in a.costs value += ":cost:" + pool + "=" + cost;
    }
    return value;
}

// Search state is reset for every solve. ASH is sequential; no callbacks in search.
SmmRPAction [int] smmRPSearchActions;
string [int] smmRPSearchIDs;
float [int] smmRPSearchValue;
float [int] smmRPSearchUpper;
int [string] smmRPSearchRemaining;
int [string] smmRPSearchPicked;
string [string] smmRPSearchChoices;
SmmRPPlan smmRPSearchBest;
int smmRPSearchLimit;
boolean smmRPSearchStopped;

void smmRPSearch(int index, float value) {
    if (smmRPSearchBest.nodes >= smmRPSearchLimit) { smmRPSearchStopped = true; return; }
    smmRPSearchBest.nodes += 1;
    // Every prefix is a feasible plan (all later quantities may be zero).
    if (value > smmRPSearchBest.objective_value) {
        smmRPSearchBest.objective_value = value;
        clear(smmRPSearchBest.quantity);
        foreach id, q in smmRPSearchPicked if (q > 0) smmRPSearchBest.quantity[id] = q;
    }
    if (index >= count(smmRPSearchActions) || value + smmRPSearchUpper[index] <= smmRPSearchBest.objective_value) return;
    SmmRPAction action = smmRPSearchActions[index];
    string id = smmRPSearchIDs[index];
    int maximum = action.limit;
    foreach resource, cost in action.costs maximum = min(maximum, smmRPSearchRemaining[resource] / cost);
    boolean has_choice = action.choice_group != "" && (smmRPSearchChoices contains action.choice_group);
    if (has_choice && smmRPSearchChoices[action.choice_group] != action.choice) maximum = 0;
    for q from maximum downto 0 {
        if (smmRPSearchStopped) return;
        smmRPSearchPicked[id] = q;
        foreach resource, cost in action.costs smmRPSearchRemaining[resource] -= q * cost;
        if (q > 0 && action.choice_group != "" && !has_choice) smmRPSearchChoices[action.choice_group] = action.choice;
        smmRPSearch(index + 1, value + q * smmRPSearchValue[index]);
        foreach resource, cost in action.costs smmRPSearchRemaining[resource] += q * cost;
        if (q > 0 && action.choice_group != "" && !has_choice) remove smmRPSearchChoices[action.choice_group];
    }
    remove smmRPSearchPicked[id];
}

SmmRPPlan smmRPSolve(SmmRPAction [string] actions, SmmRPResource [string] resources,
                    SmmRPReservation [int] reservations, SmmRPContext context) {
    clear(smmRPSearchActions); clear(smmRPSearchIDs); clear(smmRPSearchValue);
    clear(smmRPSearchUpper); clear(smmRPSearchRemaining); clear(smmRPSearchPicked);
    clear(smmRPSearchChoices);
    smmRPSearchBest = new SmmRPPlan(); smmRPSearchStopped = false;
    smmRPSearchLimit = min(1000000, max(1, context.node_limit));
    smmRPSearchBest.valid = true;
    smmRPSearchBest.fingerprint = smmRPFingerprint(resources, reservations, context) + smmRPModelFingerprint(actions);
    if (!smmRPIdentifier(context.owner) || !(context.turn_value >= 0 && context.turn_value <= 1000000000.0) || context.collection_budget < 0) {
        smmRPSearchBest.valid = false; smmRPSearchBest.error = "invalid planning context";
        return smmRPSearchBest;
    }
    foreach resource, pool in resources smmRPSearchRemaining[resource] = smmRPSpendable(resource, context.owner, resources, reservations);
    smmRPSearchRemaining["budget.collection"] = context.collection_budget;
    foreach id, original in actions {
        SmmRPAction action = smmRPCloneAction(original);
        string reason;
        if (!smmRPIdentifier(id)) reason = "invalid action ID";
        else if (!action.eligible) reason = action.unavailable_reason == "" ? "ineligible" : action.unavailable_reason;
        else if (!action.valued) reason = action.unavailable_reason == "" ? "value not supplied" : action.unavailable_reason;
        else if (action.limit <= 0) reason = "no uses requested";
        else if (action.limit > 10000) reason = "action limit exceeds 10000; split the planning horizon";
        float economic = smmRPEconomicValue(action, context);
        float objective = economic;
        if (reason == "" && !(economic >= -1000000000000.0 && economic <= 1000000000000.0))
            reason = "invalid or excessive valuation";
        if (reason == "" && action.goal != "") {
            if (!context.collection) reason = "collection mode disabled";
            else if (action.missing <= 0) reason = "collection goal complete";
            else if (!(action.collection_value >= 0 && action.collection_value <= 1000000000.0) || economic < -1000000000.0)
                reason = "collection valuation exceeds supported range";
            else {
                action.limit = min(action.limit, action.missing);
                objective += max(0, action.collection_value);
                if (economic < 0) action.costs["budget.collection"] = ceil(-economic);
            }
        }
        if (reason == "" && objective <= 0) reason = "not positive marginal value";
        if (reason == "") foreach resource, cost in action.costs {
            if (cost <= 0) { reason = "invalid nonpositive resource cost: " + resource; break; }
            if (resource == "budget.collection" && action.goal == "") {
                reason = "collection budget is reserved for goal actions"; break;
            }
            if (resource != "budget.collection" && (!(resources contains resource) || !resources[resource].known)) {
                reason = "unknown resource: " + resource; break;
            }
            if (smmRPSearchRemaining[resource] < cost) {
                reason = "exhausted, unavailable or reserved: " + resource; break;
            }
        }
        if (reason == "" && action.choice_group != "" && action.choice == "") reason = "missing exclusive choice";
        smmRPSearchBest.reason[id] = reason;
        if (reason != "") continue;
        int index = count(smmRPSearchActions);
        smmRPSearchActions[index] = action;
        smmRPSearchIDs[index] = id;
        smmRPSearchValue[index] = objective;
    }
    // Optimistic bound ignores shared capacity and choice conflicts; therefore safe.
    float upper;
    if (count(smmRPSearchActions) > 64) {
        smmRPSearchBest.valid = false; smmRPSearchBest.error = "more than 64 candidates; split the planning block";
        return smmRPSearchBest;
    }
    if (count(smmRPSearchActions) > 0) for index from count(smmRPSearchActions)-1 downto 0 {
        upper += smmRPSearchActions[index].limit * smmRPSearchValue[index];
        smmRPSearchUpper[index] = upper;
    }
    smmRPSearch(0, 0.0);
    smmRPSearchBest.optimal = !smmRPSearchStopped;
    foreach id, action in actions {
        int q = smmRPSearchBest.quantity[id];
        smmRPSearchBest.economic_value += q * smmRPEconomicValue(action, context);
        if (smmRPSearchBest.reason[id] == "") smmRPSearchBest.reason[id] = q > 0 ? "selected" : "better competing allocation";
    }
    return smmRPSearchBest;
}

boolean smmRPPlanIsCurrent(SmmRPPlan plan, SmmRPAction [string] actions, SmmRPResource [string] resources,
                           SmmRPReservation [int] reservations, SmmRPContext context) {
    return plan.valid && plan.fingerprint == smmRPFingerprint(resources, reservations, context) + smmRPModelFingerprint(actions);
}

// Reserve a reviewed plan in one ledger write, after a fresh local snapshot.
// Forecast carrier and collection budgets remain local to this block.
boolean smmRPReservePlan(SmmRPPlan plan, SmmRPAction [string] actions,
                         SmmRPResource [string] planned_resources, SmmRPContext context) {
    SmmRPResource [string] fresh=smmRPLiveResources();
    foreach id, resource in planned_resources {
        if (fresh contains id) continue;
        if (id != "carrier.free") return false;
        fresh[id]=resource;
    }
    SmmRPReservation [int] entries=smmRPReservations();
    if (!smmRPPlanIsCurrent(plan,actions,fresh,entries,context)) return false;
    SmmRPPlan checked=smmRPSolve(actions,fresh,entries,context);
    if (!checked.valid) return false;
    foreach id, a in actions if (checked.quantity[id] != plan.quantity[id]) return false;
    foreach id, q in plan.quantity if (!(actions contains id)) return false;
    int [string] demand;
    foreach id, q in plan.quantity foreach pool, cost in actions[id].costs {
        if (pool == "carrier.free" || pool == "budget.collection") continue;
        demand[pool] += q*cost;
    }
    SmmRPReservation [int] updated;
    foreach i, e in entries if (e.owner != context.owner) updated[count(updated)]=e;
    foreach pool, units in demand {
        if (units > smmRPSpendable(pool,context.owner,fresh,entries)) return false;
        if (units > 0) updated[count(updated)]=new SmmRPReservation(pool,context.owner,units);
    }
    smmRPSaveReservations(updated);
    return true;
}

SmmRPLease smmRPBegin(string owner) {
    if (!smmRPIdentifier(owner)) abort("Invalid resource planner owner.");
    SmmRPLease lease;
    lease.owner=owner; lease.epoch=smmRPEpoch(); lease.before=smmRPLiveResources();
    lease.previous_owner=get_property("smmPlanner.owner");
    set_property("smmPlanner.owner",owner);
    return lease;
}

boolean smmRPReserve(string resource, string owner, int units) {
    if (!smmRPIdentifier(resource) || !smmRPIdentifier(owner) || units < 0) return false;
    SmmRPResource [string] resources = smmRPLiveResources();
    SmmRPReservation [int] entries = smmRPReservations();
    if (!(resources contains resource) || !resources[resource].known) return false;
    if (units > smmRPSpendable(resource, owner, resources, entries)) return false;
    boolean found;
    foreach i, entry in entries if (entry.resource == resource && entry.owner == owner) {
        entries[i].units = units; found = true;
    }
    if (!found && units > 0) entries[count(entries)] = new SmmRPReservation(resource, owner, units);
    smmRPSaveReservations(entries);
    return true;
}

// Commit only observed consumption. Call around the worker's action, not its macro submission.
// Reservations are promises, never pretend-used Mafia counters.
void smmRPObserve(string owner, SmmRPResource [string] before, SmmRPResource [string] after) {
    SmmRPReservation [int] entries = smmRPReservations();
    foreach i, entry in entries {
        string id = entry.resource;
        if (entry.owner != owner || !(before contains id) || !(after contains id)
            || !before[id].known || !after[id].known) continue;
        int spent = max(0, before[id].remaining - after[id].remaining);
        entries[i].units = max(0, entry.units - spent);
    }
    smmRPSaveReservations(entries);
}

void smmRPFinish(SmmRPLease lease) {
    try {
        if (lease.epoch == smmRPEpoch()) smmRPObserve(lease.owner,lease.before,smmRPLiveResources());
    } finally {
        set_property("smmPlanner.owner",lease.previous_owner);
    }
}

// Prices are explicit realizable values supplied by the caller. Unknown prices,
// conditional drops and unknown drop rates fail closed rather than become zero.
SmmRPLootEstimate smmRPLootValue(monster mob, float item_bonus, float [item] sale_values) {
    SmmRPLootEstimate estimate;
    estimate.complete=true;
    if (mob == $monster[none]) { estimate.complete=false; estimate.reason="no monster"; return estimate; }
    foreach i, drop in item_drops_array(mob) {
        if (drop.type == "p" || drop.type == "b" || drop.type == "a") continue;
        if ((drop.type != "" && drop.type != "n" && drop.type != "f") || drop.rate <= 0) {
            estimate.complete=false; estimate.reason="unsupported drop condition/rate: " + drop.drop; continue;
        }
        if (!(sale_values contains drop.drop) || !(sale_values[drop.drop] >= 0 && sale_values[drop.drop] <= 1000000000.0)) {
            estimate.complete=false; estimate.reason="missing/invalid sale value: " + drop.drop; continue;
        }
        float chance=min(1.0,max(0.0,drop.rate * (drop.type == "f" ? 1.0 : 1.0+item_bonus/100.0)/100.0));
        estimate.value += chance*sale_values[drop.drop];
    }
    return estimate;
}

SmmRPAction smmRPSwordCandidate(monster native, monster target, int carriers,
                               float native_item_bonus, float sword_item_bonus,
                               float familiar_and_gear_displacement, float [item] sale_values,
                               boolean verified_carrier) {
    SmmRPAction action=smmRPNewAction("Sword replaces " + native + " loot with " + target,carriers,0);
    action.costs["sword.loot"]=1; action.costs["carrier.free"]=1;
    action.eligible=verified_carrier && native != $monster[none] && target != $monster[none]
        && native.copyable && target.copyable && !native.boss && !target.boss;
    action.unavailable_reason="carrier or monster is not verified eligible";
    if (target.to_int() != get_property("swordOfSWordsMonster").to_int()) {
        action.eligible=false; action.unavailable_reason="Sword target must already be configured; target changes need a separate setup plan";
    }
    SmmRPLootEstimate original=smmRPLootValue(native,native_item_bonus,sale_values);
    SmmRPLootEstimate replacement=smmRPLootValue(target,sword_item_bonus,sale_values);
    action.valued=original.complete && replacement.complete;
    action.loot_value=replacement.value;
    action.displaced_value=original.value + familiar_and_gear_displacement;
    if (action.eligible && !action.valued) action.unavailable_reason=original.complete ? replacement.reason : original.reason;
    return action;
}

string smmRPSkillResource(skill sk) {
    // These skill display names may change after Heartstone word unlocks.
    switch (sk.to_int()) {
    case 7586: return "heart.kill";
    case 7587: return "heart.banish";
    case 7588: return "heart.stun";
    case 7589: return "heart.luck";
    case 7590: return "heart.pals";
    case 7591: return "heart.buff";
    case 7593: return "sword.targets";
    }
    switch (sk.to_string()) {
    case "Chest X-Ray": return "doctor.xray";
    case "Reflex Hammer": return "doctor.hammer";
    case "Otoscope": return "doctor.otoscope";
    case "Beret Busking": return "beret.busking";
    case "Beret Blast": return "beret.blast";
    case "Beret Boast": return "beret.boast";
    case "Swoop like a Bat": return "bat.swoop";
    case "Rest upside down": return "bat.rest";
    case "Summon Cauldron of Bats": return "bat.cauldron";
    case "Macrometeorite": return "meteor.replacements";
    case "CHEAT CODE: Replace Enemy":
    case "CHEAT CODE: Invisible Avatar":
    case "CHEAT CODE: Triple Size":
    case "CHEAT CODE: Shrink Enemy": return "glove.battery";
    case "Feel Envy": return "emotion.envy";
    case "Feel Nostalgic": return "emotion.nostalgic";
    case "Feel Hatred": return "emotion.hatred";
    case "Feel Pride": return "emotion.pride";
    case "Use the Force": return "saber.force";
    case "KGB tranquilizer dart": return "kgb.darts";
    case "Throw Latte on Opponent": return "latte.banish";
    case "Offer Latte to Opponent": return "latte.copy";
    case "Show Your Boring Familiar Pictures": return "scrapbook.charges";
    case "Shattering Punch": return "shattering.kills";
    case "Gingerbread Mob Hit": return "ginger.kills";
    case "Asdon Martin: Missile Launcher": return "asdon.missile";
    case "Sweat Out Some Booze": return "sweat.booze";
    case "Cincho: Confetti Extravaganza":
    case "Cincho: Dispense Salt and Lime":
    case "Cincho: Fiesta Exit":
    case "Cincho: Party Foul":
    case "Cincho: Party Soundtrack":
    case "Cincho: Projectile Piñata": return "cinch.points";
    case "Club 'Em Across the Battlefield": return "club.battlefield";
    case "Club 'Em Into Next Week": return "club.nextweek";
    case "Club 'Em Back in Time": return "club.backtime";
    case "Sea *dent: Throw a Lightning Bolt": return "monodent.lightning";
    case "Sea *dent: Summon a Wave": return "monodent.wave";
    case "Darts: Aim for the Bullseye":
    case "Blow the Red Candle!":
    case "Free-for-all": return "color.red";
    case "Spring Away":
    case "Blow the Green Candle!": return "color.green";
    case "Blow the Yellow Candle!": return "color.yellow";
    case "Blow the Purple Candle!": return "color.purple";
    case "Blow the Blue Candle!": return "color.blue";
    }
    return "";
}

int smmRPSkillCost(skill sk) {
    switch (sk.to_string()) {
    case "CHEAT CODE: Replace Enemy": return 10;
    case "CHEAT CODE: Invisible Avatar":
    case "CHEAT CODE: Triple Size": return 5;
    case "CHEAT CODE: Shrink Enemy": return 5;
    case "Show Your Boring Familiar Pictures": return 100;
    case "Cincho: Confetti Extravaganza":
    case "Cincho: Party Foul":
    case "Cincho: Projectile Piñata": return 5;
    case "Cincho: Dispense Salt and Lime":
    case "Cincho: Party Soundtrack": return 25;
    case "Cincho: Fiesta Exit": return 60;
    }
    return 1;
}

// Existing selectors use this only when explicit current-epoch reservations exist.
// Unmapped skills keep their existing behavior. This is a reservation gate, not
// an assertion of combat eligibility or support for arbitrary externally-run macros.
int smmRPAllowedSkillUses(skill sk, int existing_limit) {
    string pool = smmRPSkillResource(sk);
    if (pool == "" || get_property("smmPlanner.reservationEpoch") != smmRPEpoch()
        || get_property("smmPlanner.reservations") == "") return existing_limit;
    string owner = get_property("smmPlanner.owner");
    if (owner == "") owner = "legacy";
    SmmRPReservation [int] entries = smmRPReservations();
    int [string] costs;
    costs[pool]=smmRPSkillCost(sk);
    if (sk == $skill[Sweat Out Some Booze]) costs["sweat.points"]=25;
    if (sk == $skill[Asdon Martin: Missile Launcher]) costs["color.yellow"]=1;
    SmmRPResource [string] resources;
    boolean loaded;
    foreach resource, cost in costs {
        if (smmRPReservedForOthers(resource,owner,entries)==0) continue;
        if (!loaded) { resources=smmRPLiveResources(); loaded=true; }
        existing_limit=min(existing_limit,smmRPSpendable(resource,owner,resources,entries)/cost);
    }
    return existing_limit;
}

void smmRPReport(SmmRPPlan plan, SmmRPAction [string] actions, SmmRPContext context) {
    if (!plan.valid) { print("Resource planner: " + plan.error, "red"); return; }
    print("Resource planner for " + context.owner + ": economic delta " + plan.economic_value
        + " Meat; objective " + plan.objective_value + "; " + plan.nodes + " search nodes; "
        + (plan.optimal ? "optimal within supplied model" : "bounded feasible result; search limit reached"), "blue");
    foreach id, action in actions print(id + ": " + plan.quantity[id] + " / " + action.limit + " — " + plan.reason[id]);
}
