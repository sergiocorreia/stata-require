*! version 0.9.1 11jul2021

* require ftools
* require ftools>=1
* require ftools>=1.0.0
* require ftools >= 1.0.0
* require ftools == 1.0.0
* require ftools>=10jul2021
* require ftools>=20210710
* require ftools, install
* require ftools, install from(..)

program require
	* Intercept "require using ..."
	cap syntax using, [INSTALL FROM(string) STRICT] [*]
	if (!c(rc)) {
		RequireFile `using', `install' from(`from') `strict' `options'
		exit
	}


	syntax anything(name=ado_extra equalok), [INSTALL FROM(string) STRICT] [*]

	loc backup `"`ado_extra'"'
	gettoken ado ado_extra: ado_extra, parse(">= ")
	gettoken op required_version: ado_extra, parse(">= ")
	loc required_version `required_version' // remove leading spaces

	loc prefix = cond("`install'" == "", "", "cap noi")

	if ("`op'" == "=") loc op "=="

	_assert inlist("`op'", ">=", "==", "")

	if ("`ado'"=="stata") {
		version `required_version': qui
		exit
	}

	loc strict = cond("`strict'"=="" & "`required_version'"=="", "", "strict")
	`prefix' GetVersion `ado', `options' `strict'

	if (c(rc)) {
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
	syntax using, [INSTALL FROM(string) STRICT] [*]
	tempname fh
	file open `fh' `using', read
	while 1 {
		*display %4.0f `linenum' _asis `"  `macval(line)'"'
		file read `fh' line
		if (r(eof)) continue, break
		loc cmd "require `line', `install' `strict' `options'" // Can't allow from()!
		di as text `"`cmd'"' 
		`cmd'
	}
	file close `fh'
end


program	GetVersion, sclass
	syntax anything(name=ado), [PATH(string) STRICT VERBOSE]
	sreturn clear
	mata: get_version("`ado'", "`path'", "`strict'"!="", "`verbose'"!="")
end


program Install
	syntax anything(name=ado), [FROM(string)]
	cap ado uninstall `ado'
	cap which `ado'
	_assert c(rc), msg(`"Could not install, "`ado'" still exists"')

	di as text "(installing `ado')"
	if ("`from'" == "") {
		ssc install `ado'
	}
	else {
		net install `ado', from("`from'")
	}
end


mata:
mata set matastrict on
void get_version(string scalar ado, string scalar path, real scalar strict, real scalar verbose)
{
	real scalar fh, ok, i
	string scalar fn, line, first_char
	
	// Load file
	if (path == "") {
		fn = findfile(ado + ".ado", c("adopath"))
	}
	else {
		fn = findfile(ado + ".ado", path)
	}

	if (fn == "") {
		printf("{err}file not found: %s.ado\n", ado)
		exit(2222)
	}

	if (verbose) printf("{txt}Parsing ADO {res}%s:\n", ado)

	fh = fopen(fn, "r")
	for (i=1; i<=5; i++) {
		line = fget(fh)
		line = strtrim(line)
		if (verbose) printf("\n{txt} @@ line %f: {res}%s\n", i, line)

		if (!strlen(line)) {
			if (verbose) printf("{txt}   $$ empty line found, continuing\n")
			continue
		}

		first_char = substr(line, 1, 1)
		if (!anyof( ("*", "!") , first_char)) {
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
	string scalar MON, SHORT_MON, NUM, DAY, YEAR, START, END, DOT, SPACE, DATESEP, AUTHOR
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
	DOT = "[.]"
	SPACE = " +"
	AUTHOR = "( [a-z @,.-]+)?" // must be at the end
	DATESEP = "[./-]"

	all_months = ("jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec")
	
	line = strlower(line)
	line = subinstr(line, char(9), " ")

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

	// Replace "*!version " with "!* version "
	line = subinstr(line, "*!version ", "*! version ")

	// Replace "*! <package>" with "!* version"
	line = subinstr(line, sprintf("*! %s ", ado), "*! version ")

	// Add version string if it's missing after starbang
	if (!strpos(line, "*! version ")) {
		line = subinstr(line, "*! ", "*! version ")
	}

	if (verbose) printf(`"{txt}   $$ before parsing, line is: {res}%s\n"', line)


	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Match x.y.z DDmmmYY					[reghdfe ftools]
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (verbose) printf(`"{txt}   $$ trying to parse "<version> DDmmmYY"\n"')
	pat = START + NUM + DOT + NUM + DOT + NUM + SPACE + DAY + " ?" + MON + " ?" + YEAR + AUTHOR + END
	if (regexm(line, pat)) {
		return(store_version(ado, regexs(1), regexs(2), regexs(3), regexs(4), regexs(5), regexs(6), raw_line))
	}
	pat = START + NUM + DOT + NUM + SPACE + DAY + " ?" + MON + " ?" + YEAR + AUTHOR + END
	if (regexm(line, pat)) {
		return(store_version(ado, regexs(1), regexs(2), "0", regexs(3), regexs(4), regexs(5), raw_line))
	}
	pat = START + NUM + SPACE + DAY + " ?" + MON + " ?" + YEAR + AUTHOR + END
	if (regexm(line, pat)) {
		return(store_version(ado, regexs(1), "0", "0", regexs(2), regexs(3), regexs(4), raw_line))
	}
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ "2021-05-18" = "YYYY-MM-DD"
	pat = START + NUM + DOT + NUM + DOT + NUM + SPACE + YEAR + DATESEP + SHORT_MON + DATESEP + DAY + AUTHOR + END
	if (regexm(line, pat)) {
		month = all_months[strtoreal(regexs(5))]
		return(store_version(ado, regexs(1), regexs(2), regexs(3), regexs(6), month, regexs(4), raw_line))
	}
	pat = START + NUM + DOT + NUM + SPACE + YEAR + DATESEP + SHORT_MON + DATESEP + DAY + AUTHOR + END
	if (regexm(line, pat)) {
		month = all_months[strtoreal(regexs(4))]
		return(store_version(ado, regexs(1), regexs(2), "0", regexs(5), month, regexs(3), raw_line))
	}
	pat = START + NUM + SPACE + YEAR + DATESEP + SHORT_MON + DATESEP + DAY + AUTHOR + END
	if (regexm(line, pat)) {
		month = all_months[strtoreal(regexs(3))]
		return(store_version(ado, regexs(1), "0", "0", regexs(4), month, regexs(2), raw_line))
	}
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Match x.y.z AUTHOR DD mmm YYYY		[distinct]
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (verbose) printf(`"{txt}   $$ trying to parse "<version> AUTHOR DD mmm YYYY"\n"')
	pat = START + NUM + DOT + NUM + DOT + NUM + SPACE + AUTHOR + SPACE + DAY + " " + MON + " " + YEAR + END
	if (regexm(line, pat)) {
		return(store_version(ado, regexs(1), regexs(2), regexs(3), regexs(4), regexs(5), regexs(6), raw_line))
	}
	pat = START + NUM + DOT + NUM + SPACE + AUTHOR + SPACE + DAY + " " + MON + " " + YEAR + END
	if (regexm(line, pat)) {
		return(store_version(ado, regexs(1), regexs(2), "0", regexs(3), regexs(4), regexs(5), raw_line))
	}
	pat = START + NUM + SPACE + AUTHOR + SPACE + DAY + " " + MON + " " + YEAR + END
	if (regexm(line, pat)) {
		return(store_version(ado, regexs(1), "0", "0", regexs(2), regexs(3), regexs(4), raw_line))
	}


	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Match x.y.z, mmm DD, YYYY		[asgen]
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (verbose) printf(`"{txt}   $$ trying to parse "<version>, mmm DD, YYYY"\n"')
	pat = START + NUM + DOT + NUM + DOT + NUM + ",? +"+ MON + " " + DAY + ",? +" + YEAR + END
	if (regexm(line, pat)) {
		return(store_version(ado, regexs(1), regexs(2), regexs(3), regexs(5), regexs(4), regexs(6), raw_line))
	}
	pat = START + NUM + DOT + NUM + ",? +"+ MON + " " + DAY + ",? +" + YEAR + END
	if (regexm(line, pat)) {
		return(store_version(ado, regexs(1), regexs(2), "0", regexs(4), regexs(3), regexs(5), raw_line))
	}
	pat = START + NUM + ",? +"+ MON + " " + DAY + ",? +" + YEAR + END
	if (regexm(line, pat)) {
		return(store_version(ado, regexs(1), "0", "0", regexs(3), regexs(2), regexs(4), raw_line))
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
