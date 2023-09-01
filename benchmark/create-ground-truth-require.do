* ===========================================================================
* Add require.do data to prepopulate the ground truth, before checking it by hand
* ===========================================================================

	* clear all doesn't work because of the collect.ado file (clear collect clashes with it)
	cap adopath - "C:\WH\ssc-mirror-2023-06-26\fmwww.bc.edu\repec\bocode"
	discard
	sysdir
	clear all


	cap ado uninstall require
	net install require, from("C:/Git/stata-require/src")
	which require
	set trace off
	set tracedepth 2
	require reghdfe, strict
	sreturn list



// --------------------------------------------------------------------------
// 
// --------------------------------------------------------------------------

	
	cls
	use "./package-list"

	* Lars' mirror
	adopath ++ "C:\WH\ssc-mirror-2023-06-26\fmwww.bc.edu\repec\bocode"

	require asd, debug("*! 1.0.0 NJC 9 November 2018")
	sreturn list
	require asd, debug("*! 1.0.0 NJC 9 November 1998")
	sreturn list
	
	require asd, debug("*! Date: 18 July 2016")
	sreturn list

	require lmhglnl, strict verbose
	sreturn list

	require spregsacxt, strict verbose
	sreturn list

	require revrs, strict verbose
	sreturn list

	require xtvar, strict verbose
	sreturn list

	require brmunid, strict verbose
	sreturn list

	require hdfe, strict verbose
	sreturn list

	require xtbalance, strict verbose
	sreturn list
	
	require bcuse, strict verbose
	sreturn list
	
	require ereplace, strict verbose
	sreturn list
	

	* Difficult; either search for the loc version or eat the star without bangs
	require rd, strict verbose
	sreturn list

	* ROGER NEWSON AD-HOC: lincomest qqvalue
	require lincomest, strict verbose

	*TODO 
	
	require carryforward, strict verbose
	require stripplot, strict verbose
	require synth_runner, strict verbose
	require synth, strict verbose
	require asgen, strict verbose
	require unique, strict verbose
	require colorpalette, strict verbose
	require distinct, strict verbose
	require estout, strict verbose
	require unique, strict verbose
	require rdrobust, strict verbose
	require boottest, strict verbose
	*stopit



	gen filename = ""
	gen starbang = ""
	gen version = ""
	gen version_date = ""

	set trace off

	loc n = c(N)
	forval i = 1/`n' {
		loc package = package[`i']

		loc fn "`package'.ado"
		cap findfile `fn'
		assert inlist(c(rc), 0, 601)

		//if (c(rc)==601) {
		//	loc alt_fn = file[`i']
		//	if ("`alt_fn'" != "") loc fn "`alt_fn'"
		//}

		loc fn = subinstr("`fn'", ".ado", "", .)
		di as text "[`i'] `package' (searching for `fn')"
		cap noi require `fn', strict // require `package'
		if (!c(rc)) {
			*sreturn list
			qui replace filename = s(filename) in `i'
			qui replace starbang = s(raw_line) in `i'
			qui replace version = s(version) in `i'
			qui replace version_date = s(version_date) in `i'
		}
		else {
			*sreturn list
			if ("`s(filename)'" != "") qui replace filename = s(filename) in `i'
			if (`"`s(raw_line)'"' != "") qui replace starbang = s(raw_line) in `i'
			di as text "<failed>"
		}
	}

	replace version = "" if version=="....."
	replace version_date = "" if version_date == "."


	* Save ground truth candidate; to be checked by hand
	preserve
		gsort -share_usage
		gen byte is_valid = 1 // 0 if the package doesn't have a valid starbang line
		gen byte ok = !mi(version) | !mi(version_date)
		replace version_date = "X" + version_date if !mi(version_date) // Prevent Excel from converting dates
		keep package share_* filename starbang is_valid version version_date ok
		order package share_* filename starbang is_valid version version_date ok
		export delim "ground-truth-pending.tsv", delim(tab) replace // this file will be reviewed by hand into ground-truth.tsv
	restore


	loc k 80
	replace starbang = substr(starbang, 1, `k'-3) + "..." if strlen(starbang)>`k'
	compress
	*gen byte valid = 1
	gen byte ok = !mi(version) | !mi(version_date)
	tab ok
	tab ok [aw=share_ssc]
	tab ok [aw=share_papers]
	tab ok [aw=share_usage]


exit

	drop if ok
	gen score = 5 * share_usage + 2 * share_papers + 1 * share_ssc
	gsort -score

	asd


	gsort -share_usage
	br

exit
	
