*! version 0.9.6 25aug2021

program require
	* Intercept "require using ..."
	cap syntax using, [INSTALL STRICT] // [*]
	if (!c(rc)) {
		RequireFile `using', `install' `strict' // `options'
		exit
	}

	* Normal usage
	syntax anything(name=ado_extra equalok), [INSTALL FROM(string) STRICT] [*]

	* Detect package and minimum/required version names
	loc backup `"`ado_extra'"'
	gettoken ado ado_extra: ado_extra, parse(">= ")
	gettoken op required_version: ado_extra, parse(">= ")
	loc required_version `required_version' // remove leading spaces
	if ("`op'" == "=") loc op "==" // allow "=" instead of "=="
	_assert inlist("`op'", ">=", "==", "")

	* Allow "require stata>=16"
	if ("`ado'"=="stata") {
		version `required_version': qui
		exit
	}

	loc prefix = cond("`install'" == "", "", "cap noi")
	loc strict = cond("`strict'"=="" & "`required_version'"=="", "", "strict")
	
	`prefix' GetVersion `ado', `options' `strict'

	if ( ("`install'" != "") & (c(rc)) ) {
		Install `ado', from(`from')
		require `backup', `options'
	}

	if ("`op'" != "") {
		*di as text "ado: `ado'"
		*di as text "op: `op'"
		*di as text "extra: `required_version'"
		`prefix' mata: ensure_version("`ado'", "`required_version'", "`op'")
		if (c(rc)) {
			Install `ado', from(`from')
			require `backup', `options'
		}
	}
end


program RequireFile
	syntax using, [INSTALL STRICT]
	tempname fh
	file open `fh' `using', read
	while 1 {
		*display %4.0f `linenum' _asis `"  `macval(line)'"'
		file read `fh' line
		if (r(eof)) continue, break

		* Remove surrounding spaces
		loc line = subinstr(`"`line'"', char(9), " ", .) // tab
		loc line = strtrim(`"`line'"')

		if (strlen(`"`line'"')==0) continue
		if (strpos(`"`line'"', "#")==1) continue

		loc 0 `line'
		syntax anything(name=ado_extra equalok), [FROM(string)]
		loc cmd `"require `ado_extra', from(`from') `install' `strict'"'
		di as text `"`cmd'"' 
		`cmd'
	}
	file close `fh'
end


program	GetVersion, sclass
	syntax anything(name=ado), [PATH(string) STRICT VERBOSE DEBUG(string)]
	sreturn clear

	* If we are debugging, we just try to parse a given line
	if (`"`debug'"' != "") {
		mata: exit(inner_get_version(`"`debug'"', "`ado'", 1) ? 0 : 2222)
		exit
	}
	
	* Workaround for bug in Stata:
	* mata findfile() uses filexists() which uses _fopen()
	* however, instead of only checking for error code -601 (file not found), it checks for all error codes
	* which includes: "fopen():  3611  too many open files"
	* which is sometimes returned if a previous fopen() was not followed by fclose()
	cap mata: fclose(1)
	cap // we must reset the error code to zero else it might get used outside this program (unsure why)

	mata: get_version("`ado'", "`path'", "`strict'"!="", "`verbose'"!="")
end


program Install
	syntax anything(name=ado), [FROM(string)]
	cap ado uninstall `ado'
	cap which `ado'
	_assert c(rc), msg(`"Could not install, "`ado'" still exists"')

	di as text "(installing `ado')"
	if inlist(strlower("`from'"), "", "ssc") {
		ssc install `ado'
	}
	else {
		net install `ado', from("`from'") replace
		// replace should be redundant given our previous "ado uninstall", but might be useful in case of conflicts (multiple installs)
		
		* For packages that require it, update mata library index
		if inlist("`ado'", "parallel") {
			mata mata mlib index
		}
	}
end


mata:
mata set matastrict on
void get_version(string scalar ado, string scalar path, real scalar strict, real scalar verbose)
{
	real scalar fh, ok, i
	string scalar fn, full_fn, line, first_char, url

	ok = 0 // default values if we exit early (e.g. if there are no starbang lines)

	fn = sprintf("%s.ado", ado)

	// Fix filenames of graphic schemes
	// We allow for "scheme-*" and "scheme_*" prefixes (former is preferred though)
	if (strpos(ado, "scheme")==1) {
		fn = sprintf("%s.scheme", subinstr(ado, "scheme_", "scheme-", 1))
	}

	// Workaround for SJ packages (might want to search for a more comprehensive strategy)
	if (fn == "gr0070.ado") fn = "scheme-plottig.scheme"
	if (fn == "pr0062_2.ado") fn = "texdoc.ado"

	// Some packages don't have .ado files. This workaround is not comprehensive though
	if (fn == "egenmisc.ado") fn = "egenmisc.sthlp"
	if (fn == "brewscheme.ado") fn = "brewscheme.sthlp" // the starbang line on the .ado is malformed
	if (fn == "binscatter2.ado") fn = "binscatter2.sthlp" // the starbang line on the .ado is malformed
	if (fn == "palettes.ado") fn = "colorpalette.ado"
	if (fn == "colrspace.ado") fn = "colrspace_source.sthlp"
	if (fn == "g538schemes.ado") fn = "scheme-538.scheme"
	if (fn == "scheme-burd.scheme") fn = "scheme_burd.sthlp"
	if (fn == "moremata.ado") fn = "moremata11_source.hlp" // moremata; not perfect b/c other files might have different versions
	if (fn == "rdmulti.ado") fn = "rdmc.ado"  // RDMC: analysis of Regression Discontinuity Designs with multiple cutoffs
	if (fn == "labutil.ado") fn = "labmask.ado"  // 'LABUTIL': modules for managing value and variable labels

	// Load file
	if (path == "") {
		full_fn = findfile(fn, c("adopath"))
	}
	else {
		full_fn = findfile(fn, path)
	}

	if (full_fn == "") {
		printf("{err}file {bf:%s} not found", fn)
		url = sprintf("ssc install %s", ado)
		printf("{err} (try to install from {stata %s:SSC}", url)
		url = sprintf("https://github.com/search?q=filename:%s.pkg", ado)
		printf(`"{err}; search on {browse "%s":Github})\n"', url)
		exit(601)
	}

	if (verbose) printf("{txt}Parsing ADO {res}%s:\n", ado)

	fh = fopen(full_fn, "r")
	// scheme-plottig.scheme -> starbang on line 24
	for (i=1; i<=25; i++) {
		line = fget(fh)
		line = strtrim(line)
		if (verbose) printf("\n{txt} @@ line %f: {res}%s\n", i, line)

		if (!strlen(line)) {
			if (verbose) printf("{txt}   $$ empty line found, continuing\n")
			continue
		}

		if (regexm(line, "^(cap|capt|captu|captur|capture)? *pr")) {
			if (verbose) printf("{txt}   $$ program definition found, continuing\n")
			continue
		}

		first_char = substr(line, 1, 1)
		if (!anyof( ("*", "!", "{") , first_char)) {
			if (verbose) printf("{txt}   $$ non-comment line found, breaking\n")
			break
		}

		ok = inner_get_version(line, ado, verbose)
		
		if (ok) break
	}

	if (strict & !ok) {
		printf(`"{err}require could not parse starbang line of "%s" for version string\n"', ado)
		exit(2223)
	}
	fclose(fh)
}


real scalar inner_get_version(string scalar line, string scalar ado, real scalar verbose)
{
	string scalar raw_line
	string scalar MON, SHORT_MON, NUM, DAY, YEAR, START, END, DOT, SPACE, DATESEP1, DATESEP2, AUTHOR
	string scalar all_months, pat, month

	raw_line = line // backup

	// Constants
	MON = "(jan|feb|ma[ry]|apr|ju[nl]|aug|sep|oct|nov|dec)"
	SHORT_MON = "(0?[1-9]|1[012])"
	NUM = "([0-9]+)"
	DAY = "(0?[1-9]|[12][0-9]|3[01])"
	YEAR = "2?0?([0-3][0-9])"
	START = "^[*]! +version +"
	END = "$"
	HELPSTART = "^[{][*] *[*]! +version +"
	HELPEND = "[}]" // does not need to end the string
	DOT = "[.]"
	SPACE = " +"
	AUTHOR = "([ ,]+[a-z @<>,._'&-]+)?" // must be at the end; also handles <e_mail@addresses.com>, lists (via commas), explanations (&' as ineqdeco)
	TIME = "( +[0-9][0-9]:[0-9][0-9]:[0-9][0-9])?" // used by unique.ado
	DATESEP1 = "[./-]"
	DATESEP2 = "[ -]?"

	// Note: Stata does not support named capturing groups, so we must use author carefully unless its at the end! (because its a group)

	all_months = ("jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec")
	
	line = strlower(line)
	line = subinstr(line, char(9), " ")
	line = invtokens(tokens(line)) // replace multiple consecutive spaces with a single space

	// Try to standardize month names
	line = subinstr(line, "january", "jan")
	line = subinstr(line, "february", "feb")
	line = subinstr(line, "march", "mar")
	line = subinstr(line, "april", "apr")
	line = subinstr(line, "may", "may")
	line = subinstr(line, "june", "jun")
	line = subinstr(line, "july", "jul")
	line = subinstr(line, "august", "aug")
	line = subinstr(line, "september", "sep")
	line = subinstr(line, "october", "oct")
	line = subinstr(line, "november", "nov")
	line = subinstr(line, "december", "dec")
	line = subinstr(line, "sept", "sep")

	// Fix wrong starbang (bang+star instead of star+bang) [rdrobust]
	line = subinstr(line, "!* version ", "*! version ")

	// Replace "*! v " with "!* version "
	line = subinstr(line, "*! v ", "*! version ")

	// Replace "* version " with "!* version " [ppml]
	line = subinstr(line, "* version ", "*! version ")

	// Replace "*! NJC " with "!* version ""
	line = subinstr(line, "*! njc ", "*! version ")

	// Replace "*! This version: v" with "!* version "" [ppml_panel_sg]
	line = subinstr(line, "*! this version: v", "*! version ")

	// Replace "*!version " with "!* version "
	line = subinstr(line, "*!version ", "*! version ")

	// Replace "* !version " with "!* version " (rdmulti)
	line = subinstr(line, "* !version ", "*! version ")

	// Replace "*! <package> version" with "!* version"
	line = subinstr(line, sprintf("*! %s version ", ado), "*! version ")

	// Replace "*! <package>" with "!* version"
	line = subinstr(line, sprintf("*! %s ", ado), "*! version ")

	// Add version string if it's missing after starbang
	if (!strpos(line, "*! version ")) {
		line = subinstr(line, "*! ", "*! version ")
	}

	// Sometimes packages are listed as "v0.1" or "v1.0" instead of "version 0.1"
	if (!strpos(line, "version")) {
		line = subinstr(line, "*! v0.", "*! version 0.")
		line = subinstr(line, "*! v1.", "*! version 1.")
		line = subinstr(line, "*! v2.", "*! version 2.")
	}

	if (verbose) printf(`"{txt}   $$ before parsing, line is: {res}%s\n"', line)


	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Match x.y.z DDmmmYY					[reghdfe ftools]
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (verbose) printf(`"{txt}   $$ trying to parse "<version> DDmmmYY"\n"')
	pat = START + NUM + DOT + NUM + DOT + NUM + SPACE + DAY + DATESEP2 + MON + DATESEP2 + YEAR + AUTHOR + END
	if (regexm(line, pat)) {
		return(store_version(ado, regexs(1), regexs(2), regexs(3), regexs(4), regexs(5), regexs(6), raw_line))
	}
	pat = START + NUM + DOT + NUM + SPACE + DAY + DATESEP2 + MON + DATESEP2 + YEAR + AUTHOR + END
	if (regexm(line, pat)) {
		return(store_version(ado, regexs(1), regexs(2), "0", regexs(3), regexs(4), regexs(5), raw_line))
	}
	pat = START + NUM + SPACE + DAY + DATESEP2 + MON + DATESEP2 + YEAR + AUTHOR + END
	if (regexm(line, pat)) {
		return(store_version(ado, regexs(1), "0", "0", regexs(2), regexs(3), regexs(4), raw_line))
	}
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ "2021-05-18" = "YYYY-MM-DD"
	pat = START + NUM + DOT + NUM + DOT + NUM + SPACE + YEAR + DATESEP1 + SHORT_MON + DATESEP1 + DAY + AUTHOR + END
	if (regexm(line, pat)) {
		month = all_months[strtoreal(regexs(5))]
		return(store_version(ado, regexs(1), regexs(2), regexs(3), regexs(6), month, regexs(4), raw_line))
	}
	pat = START + NUM + DOT + NUM + SPACE + YEAR + DATESEP1 + SHORT_MON + DATESEP1 + DAY + AUTHOR + END
	if (regexm(line, pat)) {
		month = all_months[strtoreal(regexs(4))]
		return(store_version(ado, regexs(1), regexs(2), "0", regexs(5), month, regexs(3), raw_line))
	}
	pat = START + NUM + SPACE + YEAR + DATESEP1 + SHORT_MON + DATESEP1 + DAY + AUTHOR + END
	if (regexm(line, pat)) {
		month = all_months[strtoreal(regexs(3))]
		return(store_version(ado, regexs(1), "0", "0", regexs(4), month, regexs(2), raw_line))
	}


	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Match x.y.z AUTHOR DDmmmYYYY		[distinct, stripplot]
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (verbose) printf(`"{txt}   $$ trying to parse "<version> <author> DDmmmYYYY"\n"')
	pat = START + NUM + DOT + NUM + DOT + NUM + AUTHOR + SPACE + DAY + " ?" + MON + " ?" + YEAR + END
	if (regexm(line, pat)) {
		return(store_version(ado, regexs(1), regexs(2), regexs(3), regexs(4), regexs(5), regexs(6), raw_line))
	}
	pat = START + NUM + DOT + NUM + AUTHOR + SPACE + DAY + " ?" + MON + " ?" + YEAR + END
	if (regexm(line, pat)) {
		return(store_version(ado, regexs(1), regexs(2), "0", regexs(3), regexs(4), regexs(5), raw_line))
	}
	pat = START + NUM + AUTHOR + SPACE + DAY + " ?" + MON + " ?" + YEAR + END
	if (regexm(line, pat)) {
		return(store_version(ado, regexs(1), "0", "0", regexs(2), regexs(3), regexs(4), raw_line))
	}


	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Match x.y.z AUTHOR 		(no date!) [synth_runner]
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (verbose) printf(`"{txt}   $$ trying to parse "<version> <author>"\n"')
	pat = START + NUM + DOT + NUM + DOT + NUM + AUTHOR + END
	if (regexm(line, pat)) {
		return(store_version(ado, regexs(1), regexs(2), regexs(3), "", "", "", raw_line))
	}
	pat = START + NUM + DOT + NUM + AUTHOR + END
	if (regexm(line, pat)) {
		return(store_version(ado, regexs(1), regexs(2), "0", "", "", "", raw_line))
	}
	pat = START + NUM + AUTHOR + END
	if (regexm(line, pat)) {
		return(store_version(ado, regexs(1), "0", "0", "", "", "", raw_line))
	}


	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Match x.y.z, mmm DD, YYYY		[asgen, unique]
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (verbose) printf(`"{txt}   $$ trying to parse "<version>, mmm DD, YYYY <author>"\n"')
	pat = START + NUM + DOT + NUM + DOT + NUM + ",? +"+ MON + " " + DAY + ",? +" + YEAR + AUTHOR + TIME + END
	if (regexm(line, pat)) {
		return(store_version(ado, regexs(1), regexs(2), regexs(3), regexs(5), regexs(4), regexs(6), raw_line))
	}
	pat = START + NUM + DOT + NUM + ",? +"+ MON + " " + DAY + ",? +" + YEAR + AUTHOR + TIME + END
	if (regexm(line, pat)) {
		return(store_version(ado, regexs(1), regexs(2), "0", regexs(4), regexs(3), regexs(5), raw_line))
	}
	pat = START + NUM + ",? +"+ MON + " " + DAY + ",? +" + YEAR + AUTHOR + TIME + END
	if (regexm(line, pat)) {
		return(store_version(ado, regexs(1), "0", "0", regexs(3), regexs(2), regexs(4), raw_line))
	}


	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Match help file: {* *! version x.y.z DDmmmYY}...
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (verbose) printf(`"{txt}   $$ trying to parse helpfile "<version> DDmmmYY"\n"')
	pat = HELPSTART + NUM + DOT + NUM + DOT + NUM + SPACE + DAY + DATESEP2 + MON + DATESEP2 + YEAR + AUTHOR + HELPEND
	if (regexm(line, pat)) {
		return(store_version(ado, regexs(1), regexs(2), regexs(3), regexs(4), regexs(5), regexs(6), raw_line))
	}
	pat = HELPSTART + NUM + DOT + NUM + SPACE + DAY + DATESEP2 + MON + DATESEP2 + YEAR + AUTHOR + HELPEND
	if (regexm(line, pat)) {
		return(store_version(ado, regexs(1), regexs(2), "0", regexs(3), regexs(4), regexs(5), raw_line))
	}
	pat = HELPSTART + NUM + SPACE + DAY + DATESEP2 + MON + DATESEP2 + YEAR + AUTHOR + HELPEND
	if (regexm(line, pat)) {
		return(store_version(ado, regexs(1), "0", "0", regexs(2), regexs(3), regexs(4), raw_line))
	}

	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Match x.y.z DDmmmYY (last resort when date is malformed)					[colrpalette]
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (verbose) printf(`"{txt}   $$ trying to parse "<version> <whatever>"\n"')
	pat = START + NUM + DOT + NUM + DOT + NUM + ",?[ ]+"
	if (regexm(line, pat)) {
		return(store_version(ado, regexs(1), regexs(2), regexs(3), "", "", "", raw_line))
	}
	pat = START + NUM + DOT + NUM + ",?[ ]+"
	if (regexm(line, pat)) {
		return(store_version(ado, regexs(1), regexs(2), "0", "", "", "", raw_line))
	}


	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Give up
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (verbose) printf("{txt}   $$ no version line found for %s\n", ado)
	return(0)
}

real scalar store_version(
	string scalar ado,
	string scalar str_major,
	string scalar str_minor,
	string scalar str_patch,
	string scalar str_day,
	string scalar month,
	string scalar str_year,
	string scalar raw_line)
{
	string scalar v, d
	real scalar major, minor, patch, day, year

	major = strtoreal(str_major)
	minor = strtoreal(str_minor)
	patch = strtoreal(str_patch)
	day = strtoreal(str_day)
	year = strtoreal(str_year)

	if (year<100) year = year + 2000
	
	v = sprintf("%f.%f.%f", major, minor, patch)
	d = sprintf("%f%s%f", day, month, year)
	d = strofreal(date(d, "DMY"), "%td") // standardize 1mar2020 into 01mar2020

	st_sclear()
	st_global("s(raw_line)", raw_line)
	st_global("s(version_date)", d)
	st_global("s(version_patch)", strofreal(patch))
	st_global("s(version_minor)", strofreal(minor))
	st_global("s(version_major)", strofreal(major))
	st_global("s(version)", v)
	st_global("s(package)", ado)

	return(1)
}


void ensure_version(string scalar ado, string scalar required_version, string scalar op)
{
	real scalar found_version
	real rowvector reqs
	string scalar msg

	found_version = 1e5 * strtoreal(st_global("s(version_major)")) + 1e3 * strtoreal(st_global("s(version_minor)")) + strtoreal(st_global("s(version_patch)"))
	
	reqs = strtoreal(tokens(subinstr(required_version, ".", " ")))
	if (cols(reqs)>3) {
		printf("{err}require: received invalid version string (too many elements): %s\n", required_version)
		exit(2224)
	}
	if (hasmissing(reqs)) {
		printf("{err}require: received invalid version string (non-numbers): %s\n", required_version)
		exit(2224)
	}


	reqs = reqs, 0, 0
	reqs = 1e5 * reqs[1] + 1e3 * reqs[2] + reqs[3]

	//reqs, ., found_version

	if (op == ">=") {
		if (found_version < reqs) {
			msg = sprintf("you are using version %s of %s, but require at least version %s", st_global("s(version)"), ado, required_version)
			printf("{err}%s\n", msg)
			exit(2225)
		}
	}
	else {
		if (found_version != reqs) {
			msg = sprintf("you are using version %s of %s, but require version %s", st_global("s(version)"), ado, required_version)
			printf("{err}%s\n", msg)
			exit(2226)
		}

	}
}

end
