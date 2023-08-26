* ===========================================================================
* Test "require, list" functionality
* ===========================================================================
	clear all
	cls
	cap ado uninstall require
	net install require, from("c:\git\stata-require\src")


	* syntax [using/]	, list [exact] [path(string)] [replace] [date] [stata]
	set trace off
	set tracedepth 3

	*h require
	*asd

	require, list
	require, list exact
	require, list date
	require, list stata
	require using ignore.txt, list replace stata exact
	cap noi require using ignore.txt, list

	di as text `""require, list" test completed successfully"'

exit


