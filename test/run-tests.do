* ===========================================================================
* Test require.ado against list of prechecked packages
* ===========================================================================
	clear all
	cls
	
	insheet  using "ground-truth.tsv", clear tab names double
	
	qui drop if mi(version)
	qui gen version_found = ""
	qui gen date_found = ""
	qui gen line = ""

	forval i = 1/`c(N)' {
		loc package = package[`i']
		loc expected = version[`i']
		
		cap require `package', path("./cache") strict
		if c(rc) {
			cap noi require `package', path("./cache") strict verbose
		}
		else {
			qui replace version_found = "`s(version)'" in `i'
			qui replace date_found = "`s(version_date)'" in `i'
			qui replace line = "`s(raw_line)'" in `i'
		}
	}

	qui gen byte version_ok = version == version_found
	qui gen byte date_ok = date == date_found
	order line, last
	format %20s line
	tab1 *_ok

	su version_ok
	su version_ok [fw=weight]

exit
