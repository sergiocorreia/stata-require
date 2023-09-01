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

	cap ado uninstall wclogit
	cap noi which wclogit
	assert c(rc)

	assert_error require using "test-requirements-not-installed.txt"
	
	ssc install wclogit
	require using "test-requirements-not-installed.txt"
	ado uninstall wclogit
	

exit	



which regress

* Quick tests on a package we know to exist
	require regress
	sreturn list
	assert s(package) == "regress"
	assert s(filename) == "regress.ado"
	require regress >= 1.0.0
	require regress >= 1.0.0


* Don't expect zap_s to change after 30 years
	which zap_s // *! version 3.0.2  15dec1994 StataCorp use only
	require zap_s
	sreturn list
	assert s(package) == "zap_s"
	assert s(filename) == "zap_s.ado"
	assert s(raw_line) == "*! version 3.0.2  15dec1994 StataCorp use only"
	assert s(version) == "3.0.2"
	assert s(version_major) == "3"
	assert s(version_minor) == "0"
	assert s(version_patch) == "2"
	assert s(version_date) == "15dec1994"
	require zap_s == 3.0.2
	require zap_s >= 3
	require zap_s >= 3.0.0
	require zap_s >= 3.0
	require zap_s >= 3.0.1
	require zap_s >= 2

* This should fail
	assert_error require asdfghjk
	assert_error require asdfghjk >= 1
	assert_error require asdfghjk == 1
	assert_error require zap_s >= 5
	assert_error require zap_s >= 5.0
	assert_error require zap_s >= 5.0.1
	assert_error require zap_s == 1.2.3



exit
