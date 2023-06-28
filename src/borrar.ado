mata:

real scalar old_inner_get_version(string scalar line, string scalar package, string scalar filename, real scalar verbose)
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
	line = subinstr(line, sprintf("*! %s version ", package), "*! version ")

	// Replace "*! <package>" with "!* version"
	line = subinstr(line, sprintf("*! %s ", package), "*! version ")

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
		return(store_version(package, filename, regexs(1), regexs(2), regexs(3), regexs(4), regexs(5), regexs(6), raw_line))
	}
	pat = START + NUM + DOT + NUM + SPACE + DAY + DATESEP2 + MON + DATESEP2 + YEAR + AUTHOR + END
	if (regexm(line, pat)) {
		return(store_version(package, filename, regexs(1), regexs(2), "0", regexs(3), regexs(4), regexs(5), raw_line))
	}
	pat = START + NUM + SPACE + DAY + DATESEP2 + MON + DATESEP2 + YEAR + AUTHOR + END
	if (regexm(line, pat)) {
		return(store_version(package, filename, regexs(1), "0", "0", regexs(2), regexs(3), regexs(4), raw_line))
	}
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ "2021-05-18" = "YYYY-MM-DD"
	pat = START + NUM + DOT + NUM + DOT + NUM + SPACE + YEAR + DATESEP1 + SHORT_MON + DATESEP1 + DAY + AUTHOR + END
	if (regexm(line, pat)) {
		month = all_months[strtoreal(regexs(5))]
		return(store_version(package, filename, regexs(1), regexs(2), regexs(3), regexs(6), month, regexs(4), raw_line))
	}
	pat = START + NUM + DOT + NUM + SPACE + YEAR + DATESEP1 + SHORT_MON + DATESEP1 + DAY + AUTHOR + END
	if (regexm(line, pat)) {
		month = all_months[strtoreal(regexs(4))]
		return(store_version(package, filename, regexs(1), regexs(2), "0", regexs(5), month, regexs(3), raw_line))
	}
	pat = START + NUM + SPACE + YEAR + DATESEP1 + SHORT_MON + DATESEP1 + DAY + AUTHOR + END
	if (regexm(line, pat)) {
		month = all_months[strtoreal(regexs(3))]
		return(store_version(package, filename, regexs(1), "0", "0", regexs(4), month, regexs(2), raw_line))
	}


	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Match x.y.z AUTHOR DDmmmYYYY		[distinct, stripplot]
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (verbose) printf(`"{txt}   $$ trying to parse "<version> <author> DDmmmYYYY"\n"')
	pat = START + NUM + DOT + NUM + DOT + NUM + AUTHOR + SPACE + DAY + " ?" + MON + " ?" + YEAR + END
	if (regexm(line, pat)) {
		return(store_version(package, filename, regexs(1), regexs(2), regexs(3), regexs(4), regexs(5), regexs(6), raw_line))
	}
	pat = START + NUM + DOT + NUM + AUTHOR + SPACE + DAY + " ?" + MON + " ?" + YEAR + END
	if (regexm(line, pat)) {
		return(store_version(package, filename, regexs(1), regexs(2), "0", regexs(3), regexs(4), regexs(5), raw_line))
	}
	pat = START + NUM + AUTHOR + SPACE + DAY + " ?" + MON + " ?" + YEAR + END
	if (regexm(line, pat)) {
		return(store_version(package, filename, regexs(1), "0", "0", regexs(2), regexs(3), regexs(4), raw_line))
	}


	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Match x.y.z AUTHOR 		(no date!) [synth_runner]
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (verbose) printf(`"{txt}   $$ trying to parse "<version> <author>"\n"')
	pat = START + NUM + DOT + NUM + DOT + NUM + AUTHOR + END
	if (regexm(line, pat)) {
		return(store_version(package, filename, regexs(1), regexs(2), regexs(3), "", "", "", raw_line))
	}
	pat = START + NUM + DOT + NUM + AUTHOR + END
	if (regexm(line, pat)) {
		return(store_version(package, filename, regexs(1), regexs(2), "0", "", "", "", raw_line))
	}
	pat = START + NUM + AUTHOR + END
	if (regexm(line, pat)) {
		return(store_version(package, filename, regexs(1), "0", "0", "", "", "", raw_line))
	}


	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Match x.y.z, mmm DD, YYYY		[asgen, unique]
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (verbose) printf(`"{txt}   $$ trying to parse "<version>, mmm DD, YYYY <author>"\n"')
	pat = START + NUM + DOT + NUM + DOT + NUM + ",? +"+ MON + " " + DAY + ",? +" + YEAR + AUTHOR + TIME + END
	if (regexm(line, pat)) {
		return(store_version(package, filename, regexs(1), regexs(2), regexs(3), regexs(5), regexs(4), regexs(6), raw_line))
	}
	pat = START + NUM + DOT + NUM + ",? +"+ MON + " " + DAY + ",? +" + YEAR + AUTHOR + TIME + END
	if (regexm(line, pat)) {
		return(store_version(package, filename, regexs(1), regexs(2), "0", regexs(4), regexs(3), regexs(5), raw_line))
	}
	pat = START + NUM + ",? +"+ MON + " " + DAY + ",? +" + YEAR + AUTHOR + TIME + END
	if (regexm(line, pat)) {
		return(store_version(package, filename, regexs(1), "0", "0", regexs(3), regexs(2), regexs(4), raw_line))
	}


	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Match help file: {* *! version x.y.z DDmmmYY}...
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (verbose) printf(`"{txt}   $$ trying to parse helpfile "<version> DDmmmYY"\n"')
	pat = HELPSTART + NUM + DOT + NUM + DOT + NUM + SPACE + DAY + DATESEP2 + MON + DATESEP2 + YEAR + AUTHOR + HELPEND
	if (regexm(line, pat)) {
		return(store_version(package, filename, regexs(1), regexs(2), regexs(3), regexs(4), regexs(5), regexs(6), raw_line))
	}
	pat = HELPSTART + NUM + DOT + NUM + SPACE + DAY + DATESEP2 + MON + DATESEP2 + YEAR + AUTHOR + HELPEND
	if (regexm(line, pat)) {
		return(store_version(package, filename, regexs(1), regexs(2), "0", regexs(3), regexs(4), regexs(5), raw_line))
	}
	pat = HELPSTART + NUM + SPACE + DAY + DATESEP2 + MON + DATESEP2 + YEAR + AUTHOR + HELPEND
	if (regexm(line, pat)) {
		return(store_version(package, filename, regexs(1), "0", "0", regexs(2), regexs(3), regexs(4), raw_line))
	}

	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Match x.y.z DDmmmYY (last resort when date is malformed)					[colrpalette]
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (verbose) printf(`"{txt}   $$ trying to parse "<version> <whatever>"\n"')
	pat = START + NUM + DOT + NUM + DOT + NUM + ",?[ ]+"
	if (regexm(line, pat)) {
		return(store_version(package, filename, regexs(1), regexs(2), regexs(3), "", "", "", raw_line))
	}
	pat = START + NUM + DOT + NUM + ",?[ ]+"
	if (regexm(line, pat)) {
		return(store_version(package, filename, regexs(1), regexs(2), "0", "", "", "", raw_line))
	}


	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Give up
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (verbose) printf("{txt}   $$ no version line found for %s\n", package)
	return(0)
}

end
