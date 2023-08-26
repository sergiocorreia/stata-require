* ===========================================================================
* Test "require, list codepath()" functionality
* ===========================================================================
	clear all
	cls
	cap ado uninstall require
	net install require, from("c:\git\stata-require\src")

	cap ado uninstall packagesearch
	net install packagesearch, from("c:\git\packagesearch")

	set trace off
	set tracedepth 3

	packagesearch , codedir("./demo-dofiles")
	asd

	require, list dopath("./demo-dofiles")

	di as text "require + packagesearch test completed successfully"

exit


