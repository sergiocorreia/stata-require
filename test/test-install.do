noi cscript "require, install" adofile require

// --------------------------------------------------------------------------
// Test installing packages
// --------------------------------------------------------------------------

	cap ado uninstall mdesc
	cap noi which mdesc
	assert c(rc)
	assert_error require mdesc
	require mdesc, install
	require mdesc, install

	cap ado uninstall bimap
	cap noi which bimap
	assert c(rc)
	assert_error require bimap
	require bimap, install from("https://raw.githubusercontent.com/asjadnaqvi/stata-bimap/main/installation/")
	require bimap, install


// --------------------------------------------------------------------------
// Test upgrades
// --------------------------------------------------------------------------

	*cap ado uninstall bimap
	*cap noi which bimap
	*assert c(rc)
	*assert_error require bimap
	*ssc install bimap
	*require bimap==1.81.1 // typo???
	*require bimap>=1.8.1, install from("https://raw.githubusercontent.com/asjadnaqvi/stata-bimap/main/installation/")
	*require bimap, install

// --------------------------------------------------------------------------
// Test upgrades from a local/controlled env
// --------------------------------------------------------------------------

	cap ado uninstall fake2

	* program fake2 has two versions
	* first (v1) is in path1, the other (v2) in path2
	mata: st_local("path1", pathresolve(pwd(), "./fake-repo1"))
	mata: assert(direxists("`path1'"))
	mata: st_local("path2", pathresolve(pwd(), "./fake-repo2"))
	mata: assert(direxists("`path2'"))
	
	* Install v1
	net install fake2, from("`path1'")
	which fake2
	fake2

	* require fails to get v2 if we point to path1
	assert_error require fake2 >= 2, from("`path1'")
	assert_error require fake2 >= 2, from("`path1'") install

	* Fail if we don't require to install from specific folder
	assert_error require fake2 >= 2, from("`path2'")
	assert_error require fake2 >= 2, install

	* require succeeds if we point to path2 and ask to install
	require fake2 >= 2, from("`path2'") install
	sreturn list

	fake2
	ado uninstall fake2


// --------------------------------------------------------------------------
// Install to another adopath
// --------------------------------------------------------------------------

	mata: st_local("adopath", pathresolve(pwd(), "./fake-ado-folder"))
	mata: assert(direxists("`adopath'"))

	assert_error fake2

	require fake2, from("`path1'") install adopath("`adopath'")
	assert_error require fake2>=2, from("`path1'") install adopath("`adopath'")
	require fake2>=2, from("`path2'") install adopath("`adopath'")

	ado uninstall fake2, from("`adopath'")

	adopath
	net query
	* Reset search path
	net set ado PLUS

exit	
