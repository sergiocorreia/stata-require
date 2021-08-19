* ===========================================================================
* Run tests on starbang lines
* ===========================================================================
* These tests are more convenient than testing on the actual files,
* but only test some of the functionality

	clear all
	cls

	* Remove this
	cap ado uninstall require
	net install require, from("c:\git\stata-require\src")


// --------------------------------------------------------------------------
// Run tests
// --------------------------------------------------------------------------
	require gr0070==1.2.5, debug("*!  version 1.2.5   16jun2011") // multiple spacing
	require scheme_scientific==1, debug("*!  version 1.0  01aug2018") // multiple spacing
	require egenmisc==1.2.14, debug("{* *! version 1.2.14  02feb2013}{...}") // sthlp file
	require rdmulti==0.6, debug("* !version 0.6 2021-01-04") // star split from bang



exit
