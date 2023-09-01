* ===========================================================================
* Reinstall require, clean up sandbox folder
* ===========================================================================


// --------------------------------------------------------------------------
// Setup
// --------------------------------------------------------------------------

	set trace off
	set varabbrev on
	log close _all
	clear all
	discard
	cls
	pr drop _all


// --------------------------------------------------------------------------
// Cleanup sandbox folder (used for alternative install paths)
// --------------------------------------------------------------------------
	global sandbox "C:\Git\asd\test"
	* ...


// --------------------------------------------------------------------------
// Reinstall everything
// --------------------------------------------------------------------------

	cap ado uninstall require
	net set ado `c(sysdir_plus)' // just in case it's in the wrong place
	cap ado uninstall require
	cap which require
	assert (c(rc))

	* Note: "net install" requires hardcoded paths so we do a workaround
	mata: st_local("path", pathresolve(pwd(), "../src"))
	mata: assert(direxists("`path'"))
	net install require, from("`path'")


// --------------------------------------------------------------------------
// Quick test to see if it works
// --------------------------------------------------------------------------
	* TODO...

exit
