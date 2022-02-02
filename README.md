KoL
=====
A collection of utilities for the online game Kingdom of Loathing.

Installation
----------------
Run this command in the graphical CLI:
<pre>
svn checkout https://github.com/sachamm/KoLUtils/branches/main/
</pre>
Will require [a recent build of KoLMafia](http://builds.kolmafia.us/job/Kolmafia/lastSuccessfulBuild/).

Usage
----------------
To use the subroutines from this ASH file in the CLI, do this in the CLI:
<pre>
using smmUtils.ash;
</pre>

You can then call any subroutine in this file from the command line. For example:
<pre>
itemDescription (yellow rocket);
     NOTE this ^ space between the name of the subroutine and the parenthesis is important for some reason
</pre>

Subroutines without any params must be called without the empty parens (), e.g.:
<pre>
timeToRollover;
</pre>

To stop using this on the CLI, do:
<pre>
get commandLineNamespace
set commandLineNamespace =
</pre>
(if you have other files that you are "using", the first command will show them -- you'll
have to re-"using" them after resetting the name space)


Author
----------------
Sacha Mallais (ingame: TQuilla #2771003)
sachamallais@gmail.com

License
----------------
Licenced under CC BY 4.0
https://creativecommons.org/licenses/by/4.0/
