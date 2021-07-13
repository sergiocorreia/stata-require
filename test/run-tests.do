* ===========================================================================
* Test require.ado against list of prechecked packages
* ===========================================================================
	clear all
	cls
	cap ado uninstall require
	net install require, from("c:\git\stata-require\src")

	
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

	su version_ok // 60.37% // 64.15
	su version_ok [fw=weight] // 88.35% // 90.20


* Quick tests on Github packages
	require synth_runner>=1.6, verbose
	require parallel>=1.20, // install from("https://raw.github.com/gvegayon/parallel/stable/")
	require gtools>=1.7.5, // install from("https://raw.githubusercontent.com/mcaceresb/stata-gtools/master/build/")
	require scheme-sergio>=0.1, // install from("https://raw.githubusercontent.com/sergiocorreia/stata-schemes/main")
	require stripplot>=2.9, verbose
	require tabout>=2.0.8
	require mdesc>=2.1

exit


Cases not handled:

1) RCALL:

// documentation written for markdoc

/***
[Version: 3.0.5](https://github.com/haghish/rcall/tags) 

cite: [Haghish, E. F. (2019). Seamless interactive language interfacing between R and Stata. The Stata Journal, 19(1), 61-82.](https://journals.sagepub.com/doi/full/10.1177/1536867X19830891)

-----

2) moremata: no version history, should be enough to do "require moremata"

----

3) diff.ado has month and year but no day


