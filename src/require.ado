*! version 1.1.1 14aug2023

program require
	version 14
	
	* Intercept "require [using], list"
	*syntax [using/]	, list [exact] [path(string)] [replace] [date] [stata]
	cap syntax [anything(everything)], list [*]
	if (!c(rc)) {
		List `0'
		exit
	}

	* Intercept "require using ..."
	* syntax using, [INSTALL STRICT]
	cap syntax using, [INSTALL STRICT]
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
	* Process requirements.txt
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
		if (strpos(`"`line'"', "*")==1) continue

		loc 0 `line'
		syntax anything(name=ado_extra equalok), [FROM(string)]
		loc cmd `"require `ado_extra', from(`from') `install' `strict'"'
		di as text `"`cmd'"' 
		`cmd'
	}
	file close `fh'
end


program	GetVersion, sclass
	syntax anything(name=package), [PATH(string) STRICT VERBOSE DEBUG(string)]
	sreturn clear

	* If we are debugging, we just try to parse a given line
	if (`"`debug'"' != "") {
		mata: exit(inner_get_version(`"`debug'"', "`package'", "`package'.ado", 1) ? 0 : 2222)
		exit
	}
	
	* Workaround for bug in Stata:
	* mata findfile() uses filexists() which uses _fopen()
	* however, instead of only checking for error code -601 (file not found), it checks for all error codes
	* which includes: "fopen():  3611  too many open files"
	* which is sometimes returned if a previous fopen() was not followed by fclose()
	cap mata: fclose(1)
	cap // we must reset the error code to zero else it might get used outside this program (unsure why)

	* Which filename to search
	GetFilename `package' , path("`path'") `strict'
	if ("`filename'" == "") {
		if ("`strict'" != "") {
			di as error `"require: unsure what file to search (package `package')"'
			error 2227
		}
		else {
			exit
		}
	}

	* Search the filename
	mata: get_version("`package'", "`filename'", "`path'", "`strict'"!="", "`verbose'"!="")
end



program GetFilename
	syntax anything(name=package), [PATH(string) STRICT]

	* Search for an .ado by default
	loc fn "`package'.ado"

	* Except for packages containing schemes where we search for .scheme
	* We allow for "scheme-*" and "scheme_*" prefixes (former is preferred though)
	if (strpos("`package'", "scheme")==1) {
		loc fn = subinstr("`package'", "scheme_", "scheme-", 1)
		loc fn "`fn'.scheme"
	}

	* If the .ado doesn't exist, try .sthlp (but only if it does exist!)
	cap findfile "`fn'", path("`path'")
	if (c(rc)) {
		loc candidate "`package'.sthlp"
		cap findfile "`candidate'", path("`path'")
		if (!c(rc)) loc fn "`candidate'"
	}

	* Ad-hoc workarounds for SJ packages (TODO: improve)
	if ("`package'" == "gr0070.ado") loc fn = "scheme-plottig.scheme"
	if ("`package'" == "pr0062_2.ado") loc fn = "texdoc.ado"

	* Ad-hoc workarounds for SSC packages
	if ("`package'" == "brewscheme") loc fn = "brewscheme.sthlp" // the starbang line on the .ado is malformed
	if ("`package'" == "binscatter2") loc fn = "binscatter2.sthlp" // the starbang line on the .ado is malformed
	if ("`package'" == "palettes") loc fn = "colorpalette.ado"
	if ("`package'" == "colrspace") loc fn = "colrspace_source.sthlp"
	if ("`package'" == "g538schemes") loc fn = "scheme-538.scheme"
	if ("`package'" == "moremata") loc fn = "moremata11_source.hlp" // moremata; not perfect b/c other files might have different versions
	if ("`package'" == "rdmulti") loc fn = "rdmc.ado"  // RDMC: analysis of Regression Discontinuity Designs with multiple cutoffs
	if ("`package'" == "labutil") loc fn = "labmask.ado"  // 'LABUTIL': modules for managing value and variable labels
	if ("`package'" == "scheme-burd") loc fn = "scheme_burd.sthlp"
	if ("`package'" == "fastcd") loc fn = "c.ado"

	* Autogenerated based on package .pkg files
	if ("`package'" == "lassopack") loc fn = "cvlasso.ado"
	if ("`package'" == "tab_chi") loc fn = "chitest.ado"
	if ("`package'" == "sppack") loc fn = "spmat.ado"
	if ("`package'" == "mediation") loc fn = "medeff.ado"
	if ("`package'" == "apc") loc fn = "apc_cglim.ado"
	if ("`package'" == "cltest") loc fn = "clchi2.ado"
	if ("`package'" == "ivprob-ivtobit") loc fn = "divprob.ado"
	if ("`package'" == "spellutil") loc fn = "spell2panel.ado"
	if ("`package'" == "clemao_io") loc fn = "clemao1.ado"
	if ("`package'" == "std_beta") loc fn = "stdbeta.ado"
	if ("`package'" == "_peers") loc fn = "_gpeers.ado"
	if ("`package'" == "percom") loc fn = "combin.ado"
	if ("`package'" == "panelauto") loc fn = "ac2.ado"
	if ("`package'" == "tictoc") loc fn = "tic.ado"
	if ("`package'" == "clipgeo") loc fn = "clipline.ado"
	if ("`package'" == "electool") loc fn = "electind.ado"
	if ("`package'" == "piaactools") loc fn = "piaacdes.ado"
	if ("`package'" == "qpfit") loc fn = "pdagum.ado"
	if ("`package'" == "pisatools") loc fn = "pisacmd.ado"
	if ("`package'" == "mvtnorm") loc fn = "invmvnormal.ado"
	if ("`package'" == "meta_analysis") loc fn = "_matau2.ado"
	if ("`package'" == "effects") loc fn = "effects1.ado"
	if ("`package'" == "probexog-tobexog") loc fn = "probexog.ado"
	if ("`package'" == "concindex") loc fn = "concindexg.ado"
	if ("`package'" == "panelunit") loc fn = "dfgls2.ado"
	if ("`package'" == "forec_instab") loc fn = "giacross.ado"
	if ("`package'" == "mcl") loc fn = "mclest.ado"
	if ("`package'" == "subsim") loc fn = "_subsim_inst.ado"
	if ("`package'" == "kaputil") loc fn = "kappaci.ado"
	if ("`package'" == "matin4-matout4") loc fn = "matin4.ado"
	if ("`package'" == "fpro") loc fn = "fpcata.ado"
	if ("`package'" == "matodd") loc fn = "matcfa.ado"
	if ("`package'" == "svygei_svyatk") loc fn = "svyatk.ado"
	if ("`package'" == "panelhetero") loc fn = "phecdf.ado"
	if ("`package'" == "cquad") loc fn = "cquadbasic.ado"
	if ("`package'" == "cquadr") loc fn = "cquadbasicr.ado"
	if ("`package'" == "mict") loc fn = "mict_impute.ado"
	if ("`package'" == "groupseq") loc fn = "doubletriangular.ado"
	if ("`package'" == "desma") loc fn = "des_dtl.ado"
	if ("`package'" == "mcmclinear") loc fn = "mcmcmixed.ado"
	if ("`package'" == "mcmcstats") loc fn = "mcmcconverge.ado"
	if ("`package'" == "digits") loc fn = "_gdigit.ado"
	if ("`package'" == "miparallel") loc fn = "mipllest.ado"
	if ("`package'" == "odkexport") loc fn = "odk2doc.ado"
	if ("`package'" == "hallt-skewt") loc fn = "hallt.ado"
	if ("`package'" == "qenv") loc fn = "qenvF.ado"
	if ("`package'" == "groupcl") loc fn = "dirmul.ado"
	if ("`package'" == "hful_hlim") loc fn = "hful.ado"
	if ("`package'" == "more_clarify") loc fn = "postsim.ado"
	if ("`package'" == "charutil") loc fn = "charcopy.ado"
	if ("`package'" == "valcuofon") loc fn = "valcuofon_afc.ado"
	if ("`package'" == "efetch_tools") loc fn = "genefetch.ado"
	if ("`package'" == "kit_livingincome") loc fn = "kitli_compare2bm.ado"
	if ("`package'" == "pmanage") loc fn = "pexit.ado"
	if ("`package'" == "simuped") loc fn = "simuped2.ado"
	if ("`package'" == "pobrezaecu") loc fn = "pobrezaECU.ado"
	if ("`package'" == "m_stats") loc fn = "Fhat.ado"
	if ("`package'" == "posw_posis") loc fn = "isis.ado"
	if ("`package'" == "postrcspline") loc fn = "adjustrcspline.ado"

	c_local filename "`fn'"
end


cap program drop List
program define List
	syntax [using/]	, list [exact] [path(string)] [replace] [date] [stata]
	
	if ("`path'" == "") loc path = c(sysdir_plus)
	loc trk_file = "`path'" + "stata.trk" // c(dirsep) ?
	confirm file "`trk_file'"

	* Stata line
	if ("`stata'" != "") {
		loc stata_line "    stata >= `c(stata_version)'"
		di as text "`stata_line'"
	}

	loc symbol = cond("`exact'"=="", ">=", "==")

	tempname fh
	file open `fh' using `"`trk_file'"', read
	file read `fh' line
	loc i 0
	while (r(eof)==0) {
		*display %4.0f `linenum' _asis `"  `macval(line)'"'
		loc line `"`macval(line)'"'
		loc first_char = substr(`"`line'"', 1, 1)
		if ("`first_char'" == "N") {
			loc n = strlen(`"`line'"')
			loc pkg = substr(`"`line'"', 3, `n' - 6)

			* Custom replacements for SJ-based packages (TODO: Improve/move to another program)
			if (strpos("`pkg'", "gr41_")==1) loc pkg "distplot" // type: findit distplot
			if (strpos("`pkg'", "st0610")==1) loc pkg "pwlaw"

			cap require `pkg'
			if (c(rc)) {
				loc color "{err}"
				loc version "."
			}
			else {
				loc color "{txt}"
				loc version = s(version)
			}



			if ("`version'" == ".") {
				loc line "    `pkg'"
			}
			else {
				loc line "    `pkg' `symbol' `version'"
			}
			loc ++i
			loc line`i' `"`line'"'
			di as text "`color'`line'"
		}
		file read `fh' line
	}
	file close `fh'
	di as text

	* Save to file if needed
	if ("`using'" != "") {
		loc n `i'
		file open `fh' using `"`using'"', write text `replace'
		if ("`stata'"!="") file write `fh' "`stata_line'" _n
		forval i = 1/`n' {
			file write `fh' "`line`i''" _n
		}
		file close `fh'
		di as text "file {browse `using'} saved"
	}
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



local M ustrregexm
local G ustrregexs

mata:
mata set matastrict on
void get_version(string scalar package, string scalar filename, string scalar path, real scalar strict, real scalar verbose)
{
	real scalar fh, ok, i, j
	string scalar full_fn, line, first_char, url

	ok = 0 // default values if we exit early (e.g. if there are no starbang lines)
	first_line = ""
	assert(filename != "")

	// Load file
	if (path == "") {
		full_fn = findfile(filename, c("adopath"))
	}
	else {
		full_fn = findfile(filename, path)
	}

	if (full_fn == "") {
		printf("{err}package {bf:%s} file {bf:%s} not found", package, filename)
		url = sprintf("ssc install %s", package)
		printf("{err} (try to install from {stata %s:SSC}", url)
		url = sprintf("https://github.com/search?q=filename:%s.pkg", package)
		printf(`"{err}; search on {browse "%s":Github})\n"', url)
		exit(601)
	}

	if (verbose) printf("{txt}Parsing ADO {res}%s:\n", package)

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

		first_char = substr(line, 1, 1)
		if (anyof( ("{", "#") , first_char)) {
			if (verbose) printf("{txt}   $$ non-code string found, continuing\n")
			continue
		}
		//if (strpos(line, "version ")==1) {
		//	if (verbose) printf("{txt}   $$ non-code string found, continuing\n")
		//	continue
		//}

		if (line == "/*") {
			// examples: carryforward
			if (verbose) printf("{txt}   $$ multiline comment found; skipping section\n")
			for (j=1; j<=50; j++) {
				line = fget(fh)
				line = strtrim(line)
				if (line == "*/") break
				if (line == "*! Author: Roger Newson") break
			}
			if (verbose) printf("{txt}   $$ multiline comment ended; continuing\n")
			continue
		}

		if (regexm(line, "^(cap|capt|captu|captur|capture)? *pr")) {
			if (verbose) printf("{txt}   $$ program definition found, continuing\n")
			continue
		}

		first_char = substr(line, 1, 1)
		if (!anyof( ("*", "!") , first_char)) {
			if (verbose) printf("{txt}   $$ non-comment line found, breaking\n")
			continue // break
		}

		if (first_line == "") first_line = line
		ok = inner_get_version(line, package, filename, verbose)
		
		if (ok) break
	}

	if (strict & !ok) {
		printf(`"{err}require could not parse starbang line of "%s" for version string\n"', package)
		st_sclear()
		st_global("s(filename)", filename)
		st_global("s(raw_line)", first_line)
		exit(2223)
	}
	fclose(fh)
}


real scalar inner_get_version(string scalar line, string scalar package, string scalar filename, real scalar verbose)
{
	// There are two REGEX engines in Stata
	// 1) The old one documented here: https://www.stata.com/support/faqs/data-management/regular-expressions/
	//    - Used up to require 0.9
	//    - Quite limited
	// 2) The new one (ICU REGEX) documented in:
	//	  - https://www.statalist.org/forums/forum/general-stata-discussion/general/1327564-new-program-for-regular-expressions/page2
	//	  - https://unicode-org.github.io/icu/userguide/strings/regexp.html
	//	  - https://huapeng01016.github.io/blogs/
	//	  - https://jamesthomas.uk/pdf/Regular_expressions_cheat_sheet.pdf
	//    - Used in newer versions of require
	//  New features:
	// \b	word boundary (\B not a boundary)
	// \d	digit (\D not a digit)
	// \s 	match whitespace, defined as [\t\n\f\r\p{Z}]
	// \w   word, defined as [\p{Alphabetic}\p{Mark}\p{Decimal_Number}\p{Connector_Punctuation}\u200c\u200d] (\W nonword)
	// \#	backreference to #th capturing group
	// (?: ...)		noncapturing group (useful!!!)
	// (?= ...) Look-ahead assertion
	// (?! ...)	Negative look-ahead assertion.
	// (?<= ...)	Look-behind assertion.
	// (?<! ...)	Negative Look-behind assertion
	// (?<name>...)	Named capture group --> DONT WORK!!
	// Note that {,10} doesn't work but {1,10} does


	string scalar raw_line, text
	string scalar START, VERSION, YEAR, MON, SHORT_MON, DAY, SPACE
	string scalar NUM, END, DOT, DATESEP1, DATESEP2, AUTHOR
	string scalar all_months, pat, month

	raw_line = line // backup

	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Constants
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
	START = "^[*]! +version +"
	VERSION = "[v]?(\d{1,2})\.(\d{1,3})\.(\d{1,3})[,]?"
	SPACE = " +"
	YEAR = "(?:19|20)([0-39][0-9])"
	MON = "(jan|feb|ma[ry]|apr|ju[nl]|aug|sep|oct|nov|dec)"
	SHORT_MON = "(0?[1-9]|1[012])"
	DAY = "(0?[1-9]|[12][0-9]|3[01])"
	AUTHOR_MID = "(?:[a-z, ]{2,} )?" // most authors have 3+ letters but fsum has 2
	AUTHOR_END = "(?:[a-z ]{2,}$)?"  // most authors have 3+ letters but fsum has 2

	//NUM = "([0-9]+)"
	//END = "$"
	//HELPSTART = "^[{][*] *[*]! +version +"
	//HELPEND = "[}]" // does not need to end the string
	//DOT = "[.]"
	//AUTHOR = "(?:[ ,]+[a-z @<>,._'&-]+)?" // must be at the end; also handles <e_mail@addresses.com>, lists (via commas), explanations (&' as ineqdeco)
	//TIME = "( +[0-9][0-9]:[0-9][0-9]:[0-9][0-9])?" // used by unique.ado
	//DATESEP1 = "[./-]"
	//DATESEP2 = "[ -]?"

	all_months = ("jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec")


	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Simple (non-regex) standardization of starbang string
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (verbose) printf(`"{txt}   $$ before standardizing, line is:{col 44}{res}%s\n"', line)

	
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

	// Replace "* !version " with "*! version " (rdmulti)
	line = subinstr(line, "* !version ", "*! version ")

	// Replace "* <package> " with "*! version " [rd]
	pat = "^* " + package + " (?=\d)(.*)$"
	if (`M'(line, pat)>0) line = "*! version " + `G'(1)

	// Replace "*! <package> version" with "!* version"
	// Allow "*!package" (no space) [revrs]
	// Allow "*! package.ado" [xtvar]
	pat = "^\*! ?" + package + "(?:\.ado)?" + ",? (?:version )?(.+)$"
	if (`M'(line, pat)>0) line = "*! version " + `G'(1)
	// Now use filename instead of package
	text = subinstr(filename, ".ado", "", 1)
	pat = "^\*! " + text + ",? (?:version )?(.+)$"
	if (`M'(line, pat)>0) line = "*! version " + `G'(1)
	// Now custom case for hdfe.ado
	pat = "^\*! ?" + "reghdfe" + "(?:\.ado)?" + ",? (?:version )?(.+)$"
	if (`M'(line, pat)>0) line = "*! version " + `G'(1)

	// Remove author names that come before "version"
	// IE: "*! John Smith version 1.2.3" --> "*! version 1.2.3"
	pat = "^\*! ([a-z, ]{3,20}) version " + VERSION + "(| .*)$"
	if (`M'(line, pat)>0) line = "*! version " + `G'(2) + "." + `G'(3) + "." + `G'(4) + `G'(5) + " " + `G'(1)

	// Add version string if it's missing after starbang
	if (!strpos(line, "*! version ")) {
		line = subinstr(line, "*! ", "*! version ")
	}


	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Standardization/preprocessing of strings using regex
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (verbose) printf(`"{txt}   $$ before regex preprocessing, line is:{col 44}{res}%s\n"', line)


	// Sometimes packages are listed as "v1.0" or "version v1.0" instead of "version 1.0"
	pat = "^*! v(?=[0-2])(.*)$"
	if (`M'(line, pat)>0) line = "*! version " + `G'(1)
	pat = "^*! version v ?(?=[0-5])(.*)$"
	if (`M'(line, pat)>0) line = "*! version " + `G'(1)


	// Convert "version 1 " and "version 1.0 " to "version 1.0.0 "
	// [asgen] *! version 2.0, jul 29, 2020
	pat = "^(\*! +version +\d+\.\d+),? +(.*)$"
	if (`M'(line, pat)>0) line = `G'(1) + ".0 " + `G'(2)
	pat = "^(\*! +version +\d+\.\d+) +(.*)$"
	if (`M'(line, pat)>0) line = `G'(1) + ".0 " + `G'(2)
	// Same but without date or author
	pat = "^(\*! +version +\d+\.\d+)$"
	if (`M'(line, pat)>0) line = `G'(1) + ".0"
	pat = "^(\*! +version +\d+\.\d+)$"
	if (`M'(line, pat)>0) line = `G'(1) + ".0"

	// Sometimes packages have FOUR version components (1.2.3.4)
	// As a workaround, we'll convert them to "1.2.34"
	// EG: asdoc (2.3.9.5), parallel (1.15.8.19)
	pat = "^(\*! +version(?: .*)? +)(\d{1,2})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})(| +.*)$"
	if (`M'(line, pat)>0) line = `G'(1) + `G'(2) + "." + `G'(3) + "." + `G'(4) + `G'(5) + `G'(6)

	// Convert "Dec 31, 2022" to "31dec2022"
	pat = "^(\*! +version .*) +" + MON + " " + DAY + ", (19|20)([0-39][0-9])(| +.*)$"
	if (`M'(line, pat)>0) line = `G'(1) + " " + `G'(3) + `G'(2) + `G'(4) + `G'(5) + " " + `G'(6)

	// Convert "31 dec 2022" to "31dec2022"
	pat = "^(\*! +version .*) +" + DAY + " " + MON + " (19|20)([0-39][0-9])(| +.*)$"
	if (`M'(line, pat)>0) {
		line = `G'(1) + " " + `G'(2) + `G'(3) + `G'(4) + `G'(5) + " " + `G'(6)
	}

	// Convert "31-12-2022" to "31dec2022"
	// Also deal with "31/12/2022"
	pat = "^(\*! +version .*) +" + DAY + "[-/]" + SHORT_MON + "[-/](19|20)([0-39][0-9])(| +.*)$"
	if (`M'(line, pat)>0) {
		month = all_months[strtoreal(`G'(3))]
		line = `G'(1) + " " + `G'(2) + month + "20" + `G'(4) + `G'(5) + " " + `G'(6)
	}

	// Convert "2022-12-31" to "31dec2022"
	pat = "^(\*! +version .*) +" + "(19|20)([0-39][0-9])-" + SHORT_MON + "-" + DAY + "(| +.*)$"
	if (`M'(line, pat)>0) {
		month = all_months[strtoreal(`G'(4))]
		line = `G'(1) + " " + `G'(5) + month + `G'(2) + `G'(3) + " " + `G'(6)
	}

	// Convert "2022dec31" to "31dec2022" [carryforward]
	pat = "^(\*! +version .*) +" + "20([0-3][0-9])" + MON + DAY + "(| +.*)$"
	if (`M'(line, pat)>0) {
		line = `G'(1) + " " + `G'(4) + `G'(3) + "20" + `G'(2) + " " + `G'(5)
	}

	// Convert "12/31/2022" to "31dec2022"
	pat = "^(\*! +version .*) +" + SHORT_MON + "/" + DAY + "/20([0-3][0-9])(| +.*)$"
	if (`M'(line, pat)>0) {
		month = all_months[strtoreal(`G'(2))]
		line = `G'(1) + " " + `G'(3) + month + "20" + `G'(4) + " " + `G'(5)
	}


	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Start main regex matching
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (verbose) printf(`"{txt}   $$ before regex parsing, line is:{col 44}{res}%s\n"', line)


	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Match x.y.z DDmmmYY					[reghdfe ftools]
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (verbose) printf(`"{txt}   $$ trying to parse {col 44}{txt}*! version <version> <author> <date>\n"')
	pat = START + VERSION + SPACE + AUTHOR_MID + DAY + MON + YEAR
	if (`M'(line, pat)>0) {
		return(store_version(package, filename, raw_line, `G'(1), `G'(2), `G'(3), `G'(4), `G'(5), `G'(6)))
	}


	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Match x.y.z AUTHOR 		(no date!) [synth_runner]
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (verbose) printf(`"{txt}   $$ trying to parse {col 44}{txt}*! version <version> <author>\n"')
	pat = START + VERSION + SPACE + AUTHOR_END
	if (`M'(line, pat)>0) {
		return(store_version(package, filename, raw_line, `G'(1), `G'(2), `G'(3), "", "", ""))
	}



	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Match x.y.z (no date or author [xtbalance]
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (verbose) printf(`"{txt}   $$ trying to parse {col 44}{txt}*! version <version>\n"')
	pat = START + VERSION + "$"
	if (`M'(line, pat)>0) {
		return(store_version(package, filename, raw_line, `G'(1), `G'(2), `G'(3), "", "", ""))
	}


	// Rare cases start here...

	// "*! version dec 2020 (1.1.0)" [acreg]
	if (verbose) printf(`"{txt}   $$ trying to parse {col 44}{txt}*! version <mm> <YY> (<version>)\n"')
	pat = "^\*! version [a-z0-9 ]{1,10} \(" + VERSION + "\)$"
	if (`M'(line, pat)>0) {
		return(store_version(package, filename, raw_line, `G'(1), `G'(2), `G'(3), "", "", ""))
	}

	// Custom cases for Roger Newson's ADO files
	// No version number but starbang string has format:
	// 		*!Author: Roger Newson
	// 		*!Date: 06 October 2016 -> standardized as "*! version date: ..."
	pat = "^\*! version date: " + DAY + MON + YEAR + " *$"
	if (`M'(line, pat)>0) {
		return(store_version(package, filename, raw_line, "", "", "", `G'(1), `G'(2), `G'(3) ))
	}




	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Give up
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (verbose) printf("{txt}   $$ no version line found for %s\n", package)
	return(0)
}

real scalar store_version(
	string scalar package,
	string scalar filename,
	string scalar raw_line,
	string scalar str_major,
	string scalar str_minor,
	string scalar str_patch,
	string scalar str_day,
	string scalar month,
	string scalar str_year)
{
	string scalar v, d
	real scalar major, minor, patch, day, year

	major = strtoreal(str_major)
	minor = strtoreal(str_minor)
	patch = strtoreal(str_patch)
	day = strtoreal(str_day)
	year = strtoreal(str_year)

	if (year<30) {
		year = year + 2000
	}
	else if (90<year & year <=99) {
		year = year + 1900
	}
	
	v = sprintf("%f.%f.%f", major, minor, patch)
	if (subinstr(v, ".", "")=="") {
		v = "."
	}

	d = sprintf("%f%s%f", day, month, year)
	d = strofreal(date(d, "DMY"), "%td") // standardize 1mar2020 into 01mar2020

	st_sclear()
	st_global("s(filename)", filename)
	st_global("s(raw_line)", raw_line)
	st_global("s(version_date)", d)
	st_global("s(version_patch)", strofreal(patch))
	st_global("s(version_minor)", strofreal(minor))
	st_global("s(version_major)", strofreal(major))
	st_global("s(version)", v)
	st_global("s(package)", package)

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
