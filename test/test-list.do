noi cscript "require, list" adofile require


* ===========================================================================
* Test "require, list" functionality
* ===========================================================================

	require, list

	require, list exact
	require, list date
	require, list stata

	require, list save replace
	require using ignore.txt, list replace stata exact
	cap noi require using ignore.txt, list replace

// --------------------------------------------------------------------------
// Test with diff adopath
// --------------------------------------------------------------------------

	mata: st_local("adopath", pathresolve(pwd(), "./fake-ado-folder"))
	mata: assert(direxists("`adopath'"))

	require mdesc, install adopath("`adopath'")
	require, list adopath("`adopath'")

	di as text `""require, list" test completed successfully"'
exit


