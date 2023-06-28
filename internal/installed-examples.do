* ===========================================================================
* Require based on installed packages (listed with <ado> command)
* ===========================================================================
	clear all
	cls

	* Remove this
	cap ado uninstall require
	net install require, from("c:\git\stata-require\src")

require geocode_ip, strict
require randomtag, strict
require distinct, strict
require fastxtile, strict
require poi2hdfe, strict
require rangestat, strict
require des2, strict
require explore, strict
require ensemble_ocr, strict
require avar, strict
require ppml, strict
require dataex, strict
require qsort, strict
require mdesc, strict
require fre, strict
require brewscheme, strict
require spmap, strict
require maptile, strict
require sxpose, strict
require strdist, strict
require findname, strict
require psmatch2, strict
require catplot, strict
require mmerge, strict
require timeit, strict
require parallel, strict
require binscatter, strict
require geodist, strict
require reg2hdfe, strict
require erepost, strict
require estout, strict
require binscatter2, strict
require rdrobust, strict
require rddensity, strict
require lpdensity, strict
require doa, strict
require kosi, strict
require hshell, strict
require bitfield, strict
*require pick_ticks, strict
require fast_destring, strict
*require sumup, strict
require ivreghdfe, strict
require rddsga, strict
require ranktest, strict
require tuples, strict
require unique, strict
require tabplot, strict
require cmp, strict
require ppml_panel_sg, strict
require runby, strict
require rdrobust, strict
require boottest, strict
require frameappend, strict
require grc1leg2, strict
require eventdd, strict
require winsor2, strict
require coefplot, strict
require rdrobust, strict
require ivreg2, strict
require weakiv, strict
require sjlatex, strict
require _grndraw, strict
require heatplot, strict
require dstat, strict
require binsreg, strict
require gtools, strict

exit

*require here, strict
*require rsource, strict
*require did_imputation, strict
*require bcuse, strict
*require did_multiplegt, strict
*require github, strict
*require graph3d, strict
*require rd, strict
