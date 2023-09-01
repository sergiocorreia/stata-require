noi cscript "require package>=x.y.z" adofile require


// --------------------------------------------------------------------------
// Simple test without any advanced options
// --------------------------------------------------------------------------
* Let's use Stata's built-in commands to test without having to download/install anything


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


* Egenmisc is a bit complex b/c we have to parse a helpfile
	cap which egenmisc.sthlp
	if (c(rc)) ssc install egenmisc
	require egenmisc, verbose strict
	sreturn list


exit
