* ===========================================================================
* Deal with packages with no corresponding ado file
* ===========================================================================
	clear all
	cls

	* Remove this
	cap ado uninstall require
	net install require, from("c:\git\stata-require\src")

	require gr0070>=1.2.5
	require scheme_scientific>=1.0, strict
	require egenmisc>=1.2.14, strict

	require scheme_tufte, strict
	require scheme-tfl, strict
	require egenmisc, strict
	require rdmulti, strict
	require moremata, strict
	require pr0062_2, strict
	require g538schemes, strict
	require palettes, strict
	require colrspace, strict
	require labutil, strict
	require scheme-burd, strict

exit
