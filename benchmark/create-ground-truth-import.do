* ===========================================================================
* Create table listing all SSC packages
* ===========================================================================
* Also include info on version and date (to be hand-checked) and popularity
	
	cap adopath - "C:\WH\ssc-mirror-2023-06-26\fmwww.bc.edu\repec\bocode"
	clear all
	cls
	set varabbrev off

// --------------------------------------------------------------------------
// Parameters
// --------------------------------------------------------------------------

	loc ssc_path "C:/WH/ssc-mirror-2023-06-26/fmwww.bc.edu/repec/bocode"



// --------------------------------------------------------------------------
// Download list of packages from SSC
// --------------------------------------------------------------------------

	use http://repec.org/docs/sschotPPPcur, clear
	bys package: keep if _n==1 // gisid package // not unique b/c of multiple authors
	rename hits_cur share_ssc
	egen total = total(share_ssc)
	replace share_ssc = 100 * share_ssc / total
	replace package = strlower(package)
	keep package share_ssc

	* Hand fixes
	replace package = "ivprob-ivtobit" if package == "ivprob-ivtobit6"

	gisid package
	tempfile ssc
	save "`ssc'"


// --------------------------------------------------------------------------
// Create package popularity measure
// --------------------------------------------------------------------------

	* Inputs:
	* 1) list of commands (including comments, non-SSC commands, etc.) and their popularity
	* 2) list of SSC packages and their files

	import delim "./journal-counts/ado2pkg.tsv", delim(tab) asdouble varnames(1) clear
	gen dot = strpos(file, ".")
	gen suffix = substr(file, dot+1, .)
	gen prefix = substr(file, 1, dot-1)

	* If <package>.ado doesn't exist, use an alternative
	*preserve
		drop if inlist(suffix, "pkg", "toc", "zip", "xlsx", "pdf")
		br if pkg == "art"
		asd
		gegen byte has_match = max(prefix == pkg), by(pkg)
		drop if has_match
		gen byte rank = 10 * (suffix == "ado") + 5 * (suffix == "sthlp") + 3 * (suffix == "hlp") + 2 * (suffix == "mo") + 1 * (suffix == "class")
		replace rank = -rank // we'll keep the FIRST package alphabetically, so we need to reverse rank
		bys pkg (rank file): keep if _n==1
		keep pkg file
		sort pkg
		rename pkg package
		tempfile files
		save "`files'"
	restore
	

	keep if inlist(suffix, "ado", "mlib", "style", "class", "mata")

	* Deduplicate files	
	bys file: gen N = _N
	gen candidate = (strpos(file, pkg) == 1) + (strpos(file, pkg) != 0) if N>1
	tab candidate
	bys file (candidate): keep if _n==_N
	
	gisid file
	keep pkg file prefix
	tempfile map
	save "`map'"

	import delim "./journal-counts/cmd_count.csv", delim(",") asdouble varnames(1) clear
	* cmd,n_projects,share_projects,n_total
	gen file = cmd + ".ado"
	rename n_total num_instances
	rename n_projects num_projects
	keep file cmd num_*

	join pkg prefix, from("`map'") by(file) // keep(master match) assert(match) unique nogen nolabel nonotes
	
	* Try to match non-ado files --> No matches!
	* replace cmd = prefix if _merge==2
	* drop prefix
	* bys cmd (_merge): gen N = _N
	* tab N

	keep if _merge==3
	gcollapse (sum) num_instances num_projects, by(pkg) // not perfect b/c num_projects might count more than once for e.g. gtools/ftools
	gsort -num_projects

	egen total_instances = total(num_instances)
	egen total_projects = total(num_projects)

	gen share_papers = 100 * num_projects / total_projects
	gen share_usage = 100 * num_instances / total_instances
	keep pkg share_papers share_usage
	rename pkg package
	format %8.2f share_*
	compress


// --------------------------------------------------------------------------
// Combine SSC and journal usage scores
// --------------------------------------------------------------------------

	join share_ssc, from("`ssc'") by(package) // keep(master match) assert(match) unique nogen nolabel nonotes
	replace share_papers = 0 if _merge==2
	replace share_usage = 0 if _merge==2
	replace share_ssc = 0 if _merge==1
	drop _merge

	* Drop invalid packages
	drop if inlist(package, "texteditors")


// --------------------------------------------------------------------------
// Combine with candidate files where we'll search for version
// --------------------------------------------------------------------------

	join file, from("`files'") by(package) keep(master match) nogen
	compress

	sort package
	save "./package-list", replace

exit
