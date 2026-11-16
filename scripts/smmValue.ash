script "smmValue.ash";

// smmValue.ash -- one place to answer "what is this item worth, in mall Meat?"
//
// Items sold in the mall are worth their mall price. Every other item is
// valued through the conversions KoLmafia knows about, read from its bundled
// data files (coinmasters.txt, concoctions.txt, npcstores.txt) plus fold groups:
//
//   EXIT  what the item can be turned into. A currency (Rubee, FDKOL
//         commendation, ...) or an ingredient is worth the best
//         (product value - other inputs) / amount used, over everything
//         it converts into. Products are valued by market or by their own
//         exits, never by their cost, so values stay anchored to the mall.
//   COST  what the item is made from. An item with no exit (FantasyRealm
//         mead: you can only eat it) is worth what you give up to get it:
//         100 Rubees x the value of a Rubee.
//   AUTOSELL is the floor.
//
// Example: neither Rubees nor FantasyRealm mead can be sold, but the Rubee
// store also sells the FantasyRealm guest pass and tattoo kit, which can.
// Rubee = max(guest pass / 350, tattoo kit / 10000, ...); mead = 100 x Rubee.
//
// Library use (ASH):   import <smmValue.ash>
//   float smmItemValue(item it)              value of one
//   float smmItemValue(item it, int qty)
//   float smmItemLiquidValue(item it)        what one copy can be turned into: mall, best exit
//                                            or autosell, never its cost (FantasyRealm mead: 0).
//                                            Market value only: it ignores the Museum. Before
//                                            spending copies you own, use smmMuseumOwnedValue()
//                                            in smmMuseumPolicy.ash: until you are #1 for an item,
//                                            the copies you hold are collection stock.
//   SmmValue smmValueOf(item it)             value + method + one-line reason
//   void smmValueExplain(item it)            prints the derivation tree
//   void smmValueReset()                     forget cached values (e.g. after prices change)
// Library use (JS):    const v = require("smmValue.ash"); v.smmItemValue(Item.get("Rubee™"))
//                      KoLmafia's JS require() refuses .ash files whose real path is outside
//                      the KoLmafia folder, so this only works from a real copy, not a symlink.
// CLI:                 smmValue FantasyRealm mead, Rubee™
//
// Settings:
//   smm.value.maxPriceAge    days a historical price stays good before mall_price is asked (default 7)
//   smm.value.maxQuotes      fresh mall_price lookups allowed per session (default 100)
//   smm.value.placeholderPrice  mall prices at or above this are "not for sale" listings (default 100,000,000)
//   smm.value.outlierFactor  an exit more than this x the next-best exit is ignored (default 3)
//   smm.value.override.<id>  fixed value for an item, in Meat (wins over everything)


record SmmValue {
	float value;     // Meat per item; 0 when unknown
	boolean known;   // false: nothing could value it (not even autosell)
	string method;   // override, mall, exit, cost, autosell, unknown
	string why;      // one line, human readable
};

record SmmConversion {
	string kind;          // coinmaster, shop row, craft, npc, sell to shop
	string via;           // shop or crafting method
	int [item] inputs;
	int [item] outputs;
	int meat;             // Meat paid on top of the inputs
};

SmmConversion [int] smmVConversions;
boolean [item, int] smmVProducedBy;  // item -> conversions that output it
boolean [item, int] smmVConsumedBy;  // item -> conversions that take it as input
boolean smmVGraphBuilt = false;
boolean [string] smmVRowsSeen; // shop rows already read from coinmasters.txt

// Two caches: [true] may use COST, [false] may not (used when valuing an exit's products).
SmmValue [boolean, item] smmVCache;
string [boolean, item, int] smmVAlternatives;
item [boolean, item, int] smmVRefs;
boolean [item] smmVInProgress;
int smmVQuotes = 0;

int kSmmVMaxDepth = 6;



// ---------------------------------------------------------------- data files

string smmVFormat(float f) {
	if (f >= 100 || f == 0) return to_string(round(f), "%,d");
	return to_string(f, "%.2f");
}

int smmVInt(string s) { return replace_string(s, ",", "").to_string().to_int(); }
float smmVFloat(string s) { return replace_string(s, ",", "").to_string().to_float(); }

string smmVTrim(string s) {
	return replace_all(create_matcher("^\\s+|\\s+$", s), "");
}

// "beer bong (3)" -> item + 3; "1,000 Meat" -> none + 1000 and isMeat.
record SmmVAmount { item it; int amount; boolean isMeat; boolean ok; };

SmmVAmount smmVParseAmount(string field) {
	SmmVAmount rval;
	field = field.smmVTrim();
	if (field == "") return rval;
	matcher meat = create_matcher("^([0-9,]+) Meat$", field);
	if (meat.find()) {
		rval.isMeat = true; rval.amount = meat.group(1).smmVInt(); rval.ok = true;
		return rval;
	}
	rval.amount = 1;
	matcher counted = create_matcher("^(.*) \\(([0-9,]+)\\)$", field);
	if (counted.find()) {
		field = counted.group(1);
		rval.amount = counted.group(2).smmVInt();
	}
	rval.it = to_item(field);
	rval.ok = rval.it != $item[none] && rval.amount > 0;
	return rval;
}

void smmVAddConversion(SmmConversion conv) {
	if (count(conv.outputs) == 0 || (count(conv.inputs) == 0 && conv.meat <= 0)) return;
	int id = count(smmVConversions);
	smmVConversions[id] = conv;
	foreach it in conv.outputs smmVProducedBy[it, id] = true;
	foreach it in conv.inputs smmVConsumedBy[it, id] = true;
}

coinmaster smmVCoinmaster(string name) {
	coinmaster c = to_coinmaster(name);
	return c;
}

void smmVLoadCoinmasters() {
	foreach lineNum, line in file_to_array("data/coinmasters.txt") {
		if (line.starts_with("#")) continue;
		string [int] f = split_string(line, "\t");
		if (count(f) < 3) continue;
		foreach i, field in f if (field.starts_with("ROW")) smmVRowsSeen[field.smmVTrim()] = true;
		else if (field.contains_text(", ROW")) smmVRowsSeen[field.substring(field.index_of("ROW")).smmVTrim()] = true;
		coinmaster shop = smmVCoinmaster(f[0]);
		if (shop == $coinmaster[none]) continue;
		SmmConversion conv;
		conv.via = f[0];

		if (f[1] == "buy" || f[1] == "sell") { // single-currency row: the shop's token
			if (count(f) < 4 || shop.item == $item[none]) continue; // property-based currencies are not items
			int price = f[2].smmVInt();
			SmmVAmount product = smmVParseAmount(f[3]);
			if (!product.ok || price <= 0) continue;
			if (f[1] == "buy") {
				conv.kind = "coinmaster";
				conv.inputs[shop.item] = price;
				conv.outputs[product.it] = product.amount;
			} else {
				conv.kind = "sell to shop";
				conv.inputs[product.it] = product.amount;
				conv.outputs[shop.item] = price;
			}
			smmVAddConversion(conv);

		} else if (f[1].starts_with("ROW")) { // shop row: product, then any number of costs
			if (count(f) < 4) continue;
			SmmVAmount product = smmVParseAmount(f[2]);
			if (!product.ok) continue;
			conv.kind = "shop row";
			conv.outputs[product.it] = product.amount;
			boolean ok = true;
			for i from 3 to count(f) - 1 {
				SmmVAmount cost = smmVParseAmount(f[i]);
				if (cost.isMeat) conv.meat += cost.amount;
				else if (cost.ok) conv.inputs[cost.it] += cost.amount;
				else if (f[i].smmVTrim() != "") ok = false;
			}
			if (ok) smmVAddConversion(conv);
		}
	}
}

void smmVLoadConcoctions() {
	foreach lineNum, line in file_to_array("data/concoctions.txt") {
		if (line.starts_with("#")) continue;
		string [int] f = split_string(line, "\t");
		if (count(f) < 3) continue;
		if (f[1].contains_text("MANUAL")) continue;
		SmmVAmount product = smmVParseAmount(f[0]);
		if (!product.ok) continue;
		SmmConversion conv;
		conv.kind = "craft";
		conv.via = f[1];
		conv.outputs[product.it] = product.amount;
		boolean ok = true;
		for i from 2 to count(f) - 1 {
			SmmVAmount ingredient = smmVParseAmount(f[i]);
			if (ingredient.ok && !ingredient.isMeat) conv.inputs[ingredient.it] += ingredient.amount;
			else if (ingredient.isMeat) conv.meat += ingredient.amount;
			else ok = false; // unknown ingredient: don't guess
		}
		if (conv.inputs contains product.it) ok = false; // upgrades in place are not conversions
		if (ok) smmVAddConversion(conv);
	}
}

// shoprows.txt: row number, shop id, product, costs... (NPC shops paid in items, not in coinmasters.txt)
void smmVLoadShopRows() {
	string [string] shopNames;
	foreach lineNum, line in file_to_array("data/shops.txt") {
		string [int] f = split_string(line, "\t");
		if (!line.starts_with("#") && count(f) >= 2) shopNames[f[0]] = f[1];
	}
	foreach lineNum, line in file_to_array("data/shoprows.txt") {
		if (line.starts_with("#")) continue;
		string [int] f = split_string(line, "\t");
		if (count(f) < 4 || (smmVRowsSeen contains ("ROW" + f[0].smmVTrim()))) continue;
		SmmVAmount product = smmVParseAmount(f[2]);
		if (!product.ok) continue;
		SmmConversion conv;
		conv.kind = "shop row";
		conv.via = (shopNames contains f[1]) ? shopNames[f[1]] : f[1];
		conv.outputs[product.it] = product.amount;
		boolean ok = true;
		for i from 3 to count(f) - 1 {
			SmmVAmount cost = smmVParseAmount(f[i]);
			if (cost.isMeat) conv.meat += cost.amount;
			else if (cost.ok) conv.inputs[cost.it] += cost.amount;
			else if (f[i].smmVTrim() != "") ok = false;
		}
		if (ok) smmVAddConversion(conv);
	}
}

void smmVLoadNpcStores() {
	foreach lineNum, line in file_to_array("data/npcstores.txt") {
		if (line.starts_with("#")) continue;
		string [int] f = split_string(line, "\t");
		if (count(f) < 4) continue;
		SmmVAmount product = smmVParseAmount(f[2]);
		int price = f[3].smmVInt();
		if (!product.ok || price <= 0) continue;
		SmmConversion conv;
		conv.kind = "npc";
		conv.via = f[0];
		conv.outputs[product.it] = product.amount;
		conv.meat = price;
		smmVAddConversion(conv);
	}
}

void smmVBuildGraph() {
	if (smmVGraphBuilt) return;
	smmVLoadCoinmasters();
	smmVLoadShopRows();
	smmVLoadConcoctions();
	smmVLoadNpcStores();
	smmVGraphBuilt = true;
}



// ---------------------------------------------------------------- valuation

float smmVSetting(string name, float fallback) {
	string v = get_property("smm.value." + name);
	return v == "" ? fallback : v.to_float();
}

// Mall price, or 0 when the item can't be bought there.
int smmVMarket(item it) {
	if (!it.tradeable) return 0;
	int price = 0;
	if (historical_age(it) <= smmVSetting("maxPriceAge", 7)) price = historical_price(it);
	if (price <= 0 && smmVQuotes < smmVSetting("maxQuotes", 100).to_int() && can_interact()) {
		smmVQuotes += 1;
		price = mall_price(it);
	}
	if (price <= 0) price = historical_price(it); // stale is better than nothing
	// 999,999,998 and 987,654,321 are "not for sale" listings, not prices
	if (price >= smmVSetting("placeholderPrice", 100000000)) price = 0;
	int npc = npc_price(it);
	if (npc > 0 && (price <= 0 || npc < price)) price = npc;
	return max(0, price);
}

SmmValue smmVValue(item it, boolean allowCost, int depth);

void smmVAddAlternative(boolean allowCost, item it, string text) {
	smmVAlternatives[allowCost, it, count(smmVAlternatives[allowCost, it])] = text;
}

string smmVAmountText(int amount, item it) {
	return (amount == 1 ? "" : to_string(amount, "%,d") + " ") + it;
}

string smmVConversionText(SmmConversion conv) {
	string ins;
	foreach it, n in conv.inputs ins += (ins == "" ? "" : " + ") + smmVAmountText(n, it);
	if (conv.meat > 0) ins += (ins == "" ? "" : " + ") + to_string(conv.meat, "%,d") + " Meat";
	string outs;
	foreach it, n in conv.outputs outs += (outs == "" ? "" : " + ") + smmVAmountText(n, it);
	return ins + " -> " + outs + " (" + conv.kind + ": " + conv.via + ")";
}

// What one `it` is worth if spent on this conversion. -1 when it can't be priced.
float smmVExitValue(SmmConversion conv, item it, int depth) {
	float outputs = 0;
	foreach o, n in conv.outputs {
		SmmValue v = smmVValue(o, false, depth + 1); // never value products by their cost
		if (v.known) outputs += v.value * n;
	}
	if (outputs <= 0) return -1;
	float others = conv.meat;
	foreach i, n in conv.inputs {
		if (i == it) continue;
		SmmValue v = smmVValue(i, true, depth + 1);
		if (!v.known) return -1;
		others += v.value * n;
	}
	return (outputs - others) / conv.inputs[it];
}

// What one `it` costs to make through this conversion. -1 when it can't be priced.
float smmVCostValue(SmmConversion conv, item it, int depth) {
	float inputs = conv.meat;
	foreach i, n in conv.inputs {
		SmmValue v = smmVValue(i, true, depth + 1);
		if (!v.known) return -1;
		inputs += v.value * n;
	}
	return inputs / conv.outputs[it];
}

SmmValue smmVValue(item it, boolean allowCost, int depth) {
	SmmValue rval;
	if (it == $item[none]) return rval;
	if (smmVCache[allowCost] contains it) return smmVCache[allowCost, it];
	if (smmVInProgress contains it || depth > kSmmVMaxDepth) { rval.method = "unknown"; return rval; } // don't cache: incomplete

	string override = get_property("smm.value.override." + it.to_int());
	if (override != "") {
		rval.value = override.to_float(); rval.known = true; rval.method = "override";
		rval.why = "smm.value.override." + it.to_int() + " = " + override;
		smmVCache[allowCost, it] = rval;
		return rval;
	}

	int market = smmVMarket(it);
	if (market > 0) {
		rval.value = market; rval.known = true; rval.method = "mall";
		rval.why = "mall price " + smmVFormat(market);
		smmVCache[allowCost, it] = rval;
		return rval;
	}

	smmVBuildGraph();
	smmVInProgress[it] = true;
	remove smmVAlternatives[allowCost, it];
	remove smmVRefs[allowCost, it];

	// EXIT: the best thing it can be turned into
	SmmConversion [int] exits;
	float [int] exitValues;
	foreach id in smmVConsumedBy[it] {
		SmmConversion conv = smmVConversions[id];
		float v = smmVExitValue(conv, it, depth);
		if (v <= 0) continue;
		exitValues[count(exits)] = v;
		exits[count(exits)] = conv;
	}
	foreach other in get_related(it, "fold") {
		if (other == it) continue;
		SmmValue v = smmVValue(other, false, depth + 1);
		if (!v.known || v.value <= 0) continue;
		SmmConversion fold; fold.kind = "fold"; fold.via = "fold"; fold.inputs[it] = 1; fold.outputs[other] = 1;
		exitValues[count(exits)] = v.value;
		exits[count(exits)] = fold;
	}

	// The best exit wins, unless it is a lone spike: an exit more than
	// outlierFactor x the next-best one is more likely a thin or stale listing
	// than a price anyone pays, so drop it and look at the next.
	float ceiling = -1;
	if (count(exitValues) >= 2) {
		float [int] sorted;
		foreach i, v in exitValues sorted[i] = v;
		sort sorted by -value;
		int top = 0;
		while (top < count(sorted) - 1 && sorted[top] > sorted[top + 1] * smmVSetting("outlierFactor", 3)) top += 1;
		ceiling = sorted[top];
	}
	float bestExit = -1;
	string bestExitWhy;
	SmmConversion bestExitConv;
	foreach i, conv in exits {
		float v = exitValues[i];
		boolean outlier = ceiling > 0 && v > ceiling;
		smmVAddAlternative(allowCost, it, "exit " + smmVFormat(v) + ": " + smmVConversionText(conv) + (outlier ? " [ignored: outlier]" : ""));
		if (!outlier && v > bestExit) { bestExit = v; bestExitWhy = smmVConversionText(conv); bestExitConv = conv; }
	}

	int autosell = autosell_price(it);
	if (bestExit > 0 && bestExit >= autosell) {
		rval.value = bestExit; rval.known = true; rval.method = "exit"; rval.why = bestExitWhy;
		foreach i in bestExitConv.outputs smmVRefs[allowCost, it, count(smmVRefs[allowCost, it])] = i;
		foreach i in bestExitConv.inputs if (i != it) smmVRefs[allowCost, it, count(smmVRefs[allowCost, it])] = i;
	}

	// COST: what it takes to get one (only when nothing better is known)
	if (allowCost && !rval.known) {
		float bestCost = -1;
		SmmConversion bestCostConv;
		foreach id in smmVProducedBy[it] {
			SmmConversion conv = smmVConversions[id];
			float v = smmVCostValue(conv, it, depth);
			if (v <= 0) continue;
			smmVAddAlternative(allowCost, it, "cost " + smmVFormat(v) + ": " + smmVConversionText(conv));
			if (bestCost < 0 || v < bestCost) { bestCost = v; bestCostConv = conv; }
		}
		if (bestCost > 0 && bestCost >= autosell) {
			rval.value = bestCost; rval.known = true; rval.method = "cost"; rval.why = smmVConversionText(bestCostConv);
			foreach i in bestCostConv.inputs smmVRefs[allowCost, it, count(smmVRefs[allowCost, it])] = i;
		}
	}

	if (!rval.known && autosell > 0) {
		rval.value = autosell; rval.known = true; rval.method = "autosell"; rval.why = "autosell " + smmVFormat(autosell);
	}
	if (!rval.known) { rval.method = "unknown"; rval.why = "no mall price, no conversion to anything priced, no autosell value"; }

	remove smmVInProgress[it];
	smmVCache[allowCost, it] = rval;
	return rval;
}



// ---------------------------------------------------------------- public API

void smmValueReset() {
	clear(smmVCache);
	clear(smmVAlternatives);
	clear(smmVRefs);
}

SmmValue smmValueOf(item it) {
	return smmVValue(it, true, 0);
}

float smmItemValue(item it) {
	return smmValueOf(it).value;
}

float smmItemValue(item it, int qty) {
	return smmItemValue(it) * qty;
}

// What one you already hold can be turned into: mall, best exit or autosell.
// Unlike smmItemValue, an item whose only use is itself (FantasyRealm mead)
// is not worth what it cost to get.
float smmItemLiquidValue(item it) {
	return smmVValue(it, false, 0).value;
}

float [item] smmItemValues(boolean [item] items) {
	float [item] rval;
	foreach it in items rval[it] = smmItemValue(it);
	return rval;
}

void smmVExplain(item it, boolean allowCost, string indent, int depth, boolean [item] shown) {
	SmmValue v = smmVValue(it, allowCost, 0);
	string line = indent + it + ": " + (v.known ? smmVFormat(v.value) + " Meat" : "unknown") + " [" + v.method + "]";
	if (v.method != "mall" && v.why != "") line += " " + v.why;
	print(line);
	if (shown contains it || depth >= 4) return;
	shown[it] = true;
	// products of an exit were valued without COST; inputs of a cost with it
	boolean childCost = v.method != "exit";
	foreach i, ref in smmVRefs[allowCost, it]
		smmVExplain(ref, childCost, indent + "  - ", depth + 1, shown);
}

void smmValueExplain(item it) {
	boolean [item] shown;
	smmVExplain(it, true, "", 0, shown);
	string [int] alts;
	foreach i, text in smmVAlternatives[true, it] alts[count(alts)] = text;
	if (count(alts) > 1) {
		sort alts by -(value.substring(value.index_of(" ") + 1, value.index_of(":")).smmVFloat());
		print("  alternatives considered (" + count(alts) + "):");
		foreach i, text in alts if (i < 10) print("  - " + text);
	}
}

void main(string items) {
	foreach i, name in split_string(items, ",") {
		if (name.smmVTrim() == "") continue;
		item it = to_item(name.smmVTrim());
		if (it == $item[none]) { print("unknown item: " + name, "red"); continue; }
		smmValueExplain(it);
		print("");
	}
}
