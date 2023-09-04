noi cscript "require using ..." adofile require


// --------------------------------------------------------------------------
// Test using requirement files with already-installed packages
// --------------------------------------------------------------------------

	* Visualize reqs
	type "test-requirements-installed.txt"

	* Ensure the dependencies are already installed
	cap which egenmisc.sthlp
	if (c(rc)) ssc install egenmisc
	cap which mdesc
	if (c(rc)) ssc install mdesc

	require using "test-requirements-installed.txt"


// --------------------------------------------------------------------------
// Test using packages not installed
// --------------------------------------------------------------------------

	assert_error require using "test-requirements-not-installed1.txt"
	
	cap ssc install mdesc
	cap ado uninstall mdesc
	cap noi which mdesc
	assert c(rc)

	assert_error require using "test-requirements-not-installed2.txt"
	
	ssc install mdesc
	require using "test-requirements-not-installed2.txt", install
	ado uninstall mdesc
	

exit	
