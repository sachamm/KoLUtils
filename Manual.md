# KoL Utils Manual

A very incomplete list of useful functions in this project.



## Code Utils

### assert

<pre>
void assert(boolean asserted, string abortString)
</pre>

Assert "asserted" is true, aborting with abortString if not.



## General KoL Utils

### timeToRollover

<pre>
timeToRollover;
</pre>

Prints the time until rollover in the CLI.


### isUnlocked

<pre>
boolean isUnlocked(location aLocation)
</pre>

Partially implemented. Returns true if the given location is unlocked and available to adventure in.
Does not check if the proper outfit is being worn -- or other preconditions -- just if it is theoretically possible
to adventure there.


### mmcd

<pre>
boolean mmcd()
</pre>

Maximizes the Monster Control Device to level 10 or 11, depending on which is available.


### fullAcquire

<pre>
boolean fullAcquire(int target, item anItem)
boolean fullAcquire(item anItem)
</pre>

Acquire target amount of anItem, using all possible means including buying from the market (will confirm before buying).
Tries Hganks, the closet, folding it, creating it, and finally buying. Similar to retrieve_item(), but
with slightly different semantics around equipped items (fullAcquire won't unequip items and put them into your inventory
for example), and the buying.


### accordionSongsActive

<pre>
int accordionSongsActive()
</pre>

Returns the number of AT songs being played.


### maxAccordionSongs

<pre>
int maxAccordionSongs()
</pre>

Max possible songs at the current moment.


### unequipAll

<pre>
void unequipAll()
void unequipAll(boolean unequipFamiliar)
</pre>

Unequip everything. unequipFamiliar defaults to true.


### nutrition

<pre>
int nutrition(item food_booze)
</pre>

Returns the expected adventure gain from consuming the given food or booze.


### isPPUseful

<pre>
boolean isPPUseful()
boolean isPPUseful(location aLocation)
</pre>

Returns true if at least one monster has a pickpocketable item at the given (or current) location.
