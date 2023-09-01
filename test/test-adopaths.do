* ===========================================================================
* Test advanced features
* ===========================================================================
require fake1, adopath(./fake-ado-folder)

stopit

	clear all
	cls
	loc alt_path "C:\Git\asd\test"

	net query
	cap ado uninstall require
	cap ado uninstall mdesc
	
	cap ado uninstall require, from("`alt_path'")
	cap ado uninstall mdesc, from("`alt_path'")

	net set ado `c(sysdir_plus)'
	cap ado uninstall require, from(`c(sysdir_plus)')
	cap ado uninstall mdesc, from(`c(sysdir_plus)')


	* require will CHANGE the default directory


	net install require, from("c:\git\stata-require\src")


	* TODO: temp folders or something similar
	cap mkdir "`alt_path'"
	which require
	
	net query
	require mdesc, adopath("`alt_path'") install verbose
	net query

	cap noi which mdesc
	findfile mdesc.ado, path("`alt_path'")




	* This autoinstalls on version check error
	* Sure, it's conservative but also annoying as it reruns every time
	* We should only autoinstall if the file does not exist of the version doesn't match, not if the file exist and we can't parse the version
	require sutex>=0, install
