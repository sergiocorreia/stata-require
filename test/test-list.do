noi cscript "require, setup" adofile require


* ===========================================================================
* Test "require, setup" functionality
* ===========================================================================

	require, setup
	require, list
	require, list

	require, list exact
	require, setup exact
	require, setup date
	require, setup stata

	require, setup save replace
	require using ignore.txt, setup replace stata exact
	cap noi require using ignore.txt, setup replace

// --------------------------------------------------------------------------
// Test with diff adopath
// --------------------------------------------------------------------------

	mata: st_local("adopath", pathresolve(pwd(), "./fake-ado-folder"))
	mata: assert(direxists("`adopath'"))

	require mdesc, install adopath("`adopath'")
	require, list adopath("`adopath'")


	di as text `""require, list" test completed successfully"'
exit


