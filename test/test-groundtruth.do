* ===========================================================================
* Test package against lines in ground-truth.tsv
* ===========================================================================

* Note:
* "ground-truth.tsv" is based on a manual review of "ground-truth-pending.tsv"
* which was in turn created by "create-ground-truth-require.do"

	* clear all doesn't work because of the collect.ado file (clear collect clashes with it)
	cap adopath - "C:\WH\ssc-mirror-2023-06-26\fmwww.bc.edu\repec\bocode"

	clear all
	cls

	** * Install from ../src
	mata: st_local("path", pathresolve(pwd(), "../src"))
	mata: assert(direxists("`path'"))
	cap ado uninstall require
	net install require, from("`path'")
	which require


	import delim "../benchmark/ground-truth.tsv", delim(tab) asdouble varnames(1) clear
	replace version_date = subinstr(version_date, "X", "", 1)

	*keep if inlist(package, "adjust", "mdesc", "newey2")
	*keep if inlist(package, "b1x2", "fsum", "ivreg2hdfe", "spmap", "winsor2")

	gen byte ok = .
	loc n = c(N)
	set trace off
	set tracedepth 2
	forval i = 1/`n' {
		
		loc package = package[`i']
		loc line = starbang[`i']
		loc version = version[`i']
		loc version_date = version_date[`i']

		if (`"`line'"' == "") {
			qui replace ok = 0 in `i'
			continue
		}

		di as text "processing `i' `package'"
		loc cmd require `package', debug(`"`line'"')
		*di as input `"`cmd'"'
		*`cmd'
		*sreturn list

		cap // reset any previous error codes
		cap `cmd'

		* Intercept errors (triggered by debug option only)
		* 2221 = New (v1.3) 2222 = Old (v1)
		if (inlist(c(rc), 2221, 2222)) {
			qui replace ok = 0 in `i'
			continue
		}
		_assert !c(rc), msg("not expecting RC here")

		loc ok 1
		if ("`s(package)'" != "`package'") {
			*asd1
			loc ok 0
		}

		* a) if there's a version we must match it
		if ("`version'" != "") {
			if (s(version) != "`version'") {
				*asd2
				loc ok 0
			}
			* and we can keep the date missing but cannot have it wrong
			if ("`s(version_date)'" != "" & "`version_date'" != "") {
				if ("`s(version_date)'" != "`version_date'") {
					*asd3
					loc ok 0
				}
			}
		}
		* b) if there's no version, we must have a nonmissing version date and match it
		else {
			if ("`s(version_date)'" == ".") {
				*asd4
				loc ok 0
			}
			if ("`s(version_date)'" != "`version_date'") {
				*asd5
				loc ok 0
			}
		}

		*assert `ok'
		qui replace ok = `ok' in `i'
	}

	save "../benchmark/performance-detailed", replace
	di as text "Done!"

	tab is_valid
	tab manual_review
	tab manual_review [aw=share_usage]

	tab ok
	tab ok if is_valid
	tab ok if is_valid [aw=share_ssc]
	tab ok if is_valid [aw=share_papers]
	tab ok if is_valid [aw=share_usage]


	su ok, mean
	loc ok_unweighted = r(mean)
	su ok if is_valid, mean
	loc ok_valid = r(mean)
	su ok if is_valid [aw=share_ssc], mean
	loc ok_ssc = r(mean)
	su ok if is_valid [aw=share_papers], mean
	loc ok_papers = r(mean)
	su ok if is_valid [aw=share_usage], mean
	loc ok_usage = r(mean)

	clear
	set obs 5
	gen x = ""
	*replace x = "Unweighted" in 1
	*replace x = "Excl. packages with missing info." in 2
	replace x = "Unweighted" in 2
	replace x = "Weights: SSC downloads" in 3
	replace x = "Weights: usage in published papers" in 4
	replace x = "Weights: usage intensity" in 5

	gen double y = .
	*replace y = `ok_unweighted' in 1
	replace y = `ok_valid' in 2
	replace y = `ok_ssc' in 3
	replace y = `ok_papers' in 4
	replace y = `ok_usage' in 5

	compress
	save "../benchmark/performance", replace

exit

* To validate regressions against older versions, you can do something like:
* Run with old version, rename performance-detailed to performance-detailed-old
* Run with new version, open "performance-detailed"
* Run:

cd "C:\Git\stata-require\benchmark"
cls
clear all
use performance-detailed, clear
rename (filename starbang is_valid version version_date manual_review ok) (new_=)
merge 1:1 package using "performance-detailed-old.dta", keep(match) // assert(match)
*br if ok!=new_ok
tab ok new_ok

order _all, alpha
order package ok
loc vars package *filename *is_valid *version *version_date *manual_review *ok // *starbang 
li `vars' if ok==0 & new_ok==1
li `vars' if ok==1 & new_ok==0
