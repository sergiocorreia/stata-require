*! version 1.4.0 10apr2024

program require, sclass
	version 14

	* Intercept "require [using], [setup|list]"
	cap syntax [using], setup [*]
	if (!c(rc)) {
		Setup `using', `options'
		exit
	}
	cap syntax [using], list [*]
	if (!c(rc)) {
		Setup `using', `options'
		exit
	}

	* Intercept "require using ..."
	cap syntax using, [*]
	if (!c(rc)) {
		RequireFile `0'
		exit
	}

	* Main syntax
	syntax anything(name=requirement equalok), [INSTALL ADOPATH(string) FROM(string)] [DEBUG(string) VERBOSE STRICT]

	* Parse options and set defaults
	if (inlist(`"`from'"', "SSC", "")) loc from ssc // Ensure SSC is default and there is only one variant

	* -adopath- accepts certain keywords (see "sysdir")
	* - BASE is where the original official ado-files that were shipped with Stata and any updated official ado-files...
	* - SITE is relevant only on networked computers. It is where administrators may place ado-files for sitewide use on networked computer...
	* - PLUS is relevant on all systems. It is where ado-files written by other people that you obtain using the net command are installed
	* - PERSONAL is where you are to copy ado-files that you write and that you wish to use regardless of your current directory when you use Stata
	if (strlower("`adopath'") == "plus") loc adopath = c(sysdir_plus)
	if (strlower("`adopath'") == "site") loc adopath = c(sysdir_site)
	if (strlower("`adopath'") == "personal") loc adopath = c(sysdir_personal)

	* Verify -adopath- folder exists (unless string is empty, in which case we'll use c(adopath))
	if ("`adopath'" != "") {
		mata: st_local("exists", strofreal(direxists("`adopath'")))
		if (!`exists') {
			di as error `"require: adopath() directory "`adopath'" not found"'
			exit 692
		}
	}


	* Intercept "require, debug": receive a string and parse it as a starbang line
	if (`"`debug'"' != "") {
		GetNextRequirement `requirement' // updates locals: `package' `op' `required_version' `rest'
		loc has_requirements = ("`op'" != "")
		_assert "`rest'"=="", msg(`"Extra text in requirement: "`rest'""')
		* Note: -debug- turns on -verbose- as well
		loc verbose verbose
		
		* Note: we call GetFilename because inner_get_version behaves differently for .sthlp files
		GetFilename `package' , adopath("`adopath'") `verbose' // outputs data in `filename'

		mata: store_rc(inner_get_version(`"`debug'"', "`package'", "`filename'", "<fake-file>", "`verbose'"!="")) // write s()
		RaiseMataError, rc(`rc') req("`required_version'")

		if (`has_requirements') mata: store_rc(ensure_version("`required_version'", "`op'")) // reads s(), writes `rc'
		RaiseMataError, rc(`rc') req("`required_version'")
		
		exit
	}


	* Iterate over multiple requirements
	loc rest `requirement'
	while ("`rest'"!="") {
		GetNextRequirement `rest'
		*di as text `"package: [{res}`package'{txt}]"'
		*di as text "op: [{res}`op'{txt}]"
		*di as text "version: [{res}`required_version'{txt}]"
		*di as text "rest=[{res}`rest'{txt}]"
		*di
		RequireOne, package(`package') op(`op') required_version(`required_version') ///
			`install' adopath("`adopath'") from("`from'") `verbose' `strict'
	}
end


program RequireOne, sclass
	syntax, package(string) [op(string) required_version(string)] [INSTALL ADOPATH(string) FROM(string)] [DEBUG(string) VERBOSE STRICT]

	_assert inlist("`op'", ">=", "==", "")
	loc required_version `required_version' // remove leading spaces (we don't need this anymore?)
	loc has_requirements = ("`op'" != "")
	loc can_install = ("`install'" != "")
	local requirement `package' `op' `required_version'
	local requirement `requirement' // remove spaces

	* Support for "require stata>=16"
	if ("`package'"=="stata") {
		version `required_version': qui
		exit
	}

	* Which filename will we search? usually <package>.ado but there are exceptions...
	GetFilename `package' , adopath("`adopath'") `verbose' // outputs data in `filename'

	* From this point onward, there are three possible errors that can trigger failed requirements:
	*
	*  a) package is not installed
	*  b) version string couldn't be parsed
	*  c) version is incompatible with requirements
	*
	* We'll test each condition sequentially, and if one fails then
	*
	*  a) if we can install, we will i) install, ii) rerun require without -install- option (to test it worked), and iii) exit
	*  b) if we can't install, we will stop with error.
	*
	* Note that if there is no required version and strict=False, we will run step (b) but don't raise an error on failure
	* Further, if there is no required version we won't run step (c)

	* Step A - Is the package/file already installed?
	cap findfile `filename', path("`adopath'")
	loc not_installed = c(rc)>0
	
	if (`not_installed') {
		if (`can_install') {
			cap // clear out error codes
			Install `package', adopath(`adopath') from(`from')
			RequireOne, package(`package') op(`op') required_version(`required_version') adopath("`adopath'") `verbose' `strict'
			exit
		}
		else {
			loc adopath_str = cond(`"`adopath'"'=="", "adopath", `"`adopath'"')
			if ("`from'"!="ssc") {
				loc cmd `"net install `package', from("`from'")"'
				di as error `"{bf:require}: package "{bf:`package'}" not found in `adopath_str'; {stata `"`cmd'"':install from "`from'"}"'
			}
			else {
				di as error `"{bf:require}: package "{bf:`package'}" not found in `adopath_str';"'
				* Raise error if file doesn't exist and we are not installing
				loc url `"https://github.com/search?q=`package'+language%3AStata+language%3AStata&type=repositories"'
				*loc url `"https://github.com/search?q=filename:`package'.pkg"'
				di as error " - {stata ssc install `package':install from SSC}"
				di as error " - {stata search `package':search online documentation}"
				di as error `" - {browse "`url'":search on Github}"'
			}
			sreturn clear
			sreturn local package "`package'"
			sreturn local filename "`filename'"
			exit 601
		}
	}

	* Workaround for bug in Stata:
	* mata findfile() uses filexists() which uses _fopen()
	* however, instead of only checking for error code -601 (file not found), it checks for all error codes
	* which includes: "fopen():  3611  too many open files"
	* which is sometimes returned if a previous fopen() was not followed by fclose()
	cap mata: fclose(1)
	cap // we must reset the error code to zero else it might get used outside this program (unsure why)
	
	* Step B - Can we parse the version string?
	mata: store_rc(get_version("`package'", "`filename'", "`r(fn)'", "`verbose'"!="")) // writes s() and `rc'

	* Stop if we don't need to go further (no version requirements and no strict option)
	if (!`has_requirements' & "`strict'"=="") exit

	if (`rc') {
		if (`can_install') {
			Install `package', adopath(`adopath') from(`from')
			RequireOne, package(`package') op(`op') required_version(`required_version') adopath("`adopath'") `verbose' `strict'
			exit
		}
		else {
			RaiseMataError, rc(`rc') req("`required_version'")
		}
	}

	* Stop if we don't need to go further (no version requirements and no strict option)
	if (!`has_requirements') exit

	* Step C - Does the version meet the requirements?
	mata: store_rc(ensure_version("`required_version'", "`op'")) // reads s(), writes `rc'
	if (`rc') {
		if (`can_install') {
			Install `package', adopath(`adopath') from(`from')
			RequireOne, package(`package') op(`op') required_version(`required_version') adopath("`adopath'") `verbose' `strict'
			exit
		}
		else {
			RaiseMataError, rc(`rc') req("`required_version'")
		}
	}
end


program GetNextRequirement
	* Extract package and minimum/required version names
	gettoken package rest1: 0, parse(">= ")
	gettoken op rest2: rest1, parse(">= ")
	gettoken required_version rest3: rest2, parse(" ")

	* allow "=" instead of "=="
	if ("`op'" == "=") loc op "=="

	if (inlist("`op'", "==", ">=")) {
		local rest `rest3'
	}
	else {
		local rest `rest1'
		local op
		local required_version
	}

	c_local package "`package'"
	c_local op "`op'"
	c_local required_version "`required_version'"
	c_local rest "`rest'"

end


program RequireFile
	* Process requirements.txt
	syntax using, [ADOPATH(string) INSTALL STRICT]
	tempname fh
	loc missing_packages 0
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
		loc from_opt // Need to clear it every time!
		syntax anything(name=ado_extra equalok), [FROM(string)]
		if (`"`adopath'"'!="") loc adopath_opt `"adopath(`adopath')"'
		if (`"`from'"'!="") loc from_opt `"from(`from')"'
		if (`"`adopath_opt'`from_opt'`install'`strict'"'!="") loc comma ","
		loc cmd `"require `ado_extra' `comma' `adopath_opt' `from_opt' `install' `strict'"'
		di as text `"  ... `cmd'"' 
		cap noi `cmd'
		if (c(rc)) loc ++missing_packages
	}
	file close `fh'
	
	if (`missing_packages') {
		di as error "{bf:require}: `missing_packages' packages are failing requirements"
		exit 601
	}
end


program Setup
	syntax [using/]	, [adopath(string)] [replace save] [exact MINimum] [date] [stata]
	if ("`adopath'" == "") loc adopath = c(sysdir_plus)
	loc has_dirsep = inlist(substr("`adopath'", strlen("`adopath'"), 1), "\", "/")
	loc dirsep = cond(`has_dirsep', "", c(dirsep))
	loc trk_file = "`adopath'" + "`dirsep'" + "stata.trk"
	cap confirm file "`trk_file'"
	if (c(rc)) {
		di as error "`adopath' is not a valid adopath; file stata.trk is missing"
		exit 601
	}

	di as text "(listing installed packages based on file `trk_file')" _n
	
	* Default using
	if ("`save'" != "" & "`using'" == "") {
		loc using "requirements.txt"
	}

	* Stata line
	if ("`stata'" != "") {
		loc stata_line "    stata >= `c(stata_version)'"
		di as text "`stata_line'"
	}

	opts_exclusive "`exact' `minimum'"
	loc symbol = cond("`minimum'"!="", ">=", "==")

	loc header1 `"* Created on `c(current_date)' by `c(username)' @ `c(hostname)' on `c(os)'-`c(osdtl)'"'
	loc header2 `"* Edit this file to remove redundant lines"'
	loc header3 `"* And save as "requirements.txt""'

	di as text `"`header1'"'
	di as text `"`header2'"'
	di as text `"`header3'"'
	
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

			cap require `pkg', adopath("`adopath'")
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

		file write `fh' `"`header1'"' _n
		file write `fh' `"`header2'"' _n
		file write `fh' `"* Then, include this line in your do-file:"' _n
		file write `fh' `"* require using `using', install"' _n _n
		if ("`stata'"!="") file write `fh' "`stata_line'" _n

		forval i = 1/`n' {
			file write `fh' "`line`i''" _n
		}
		file close `fh'
		di as text "file {browse `using'} saved"
	}
end




program Install
	syntax anything(name=ado), [ADOPATH(string) FROM(string)]

	if ("`adopath'" != "") {
		di as text "  ~~~ current package install path:"
		net query
		di as text `"  ~~~ changing install path to {inp}`adopath'{txt}"'
		loc cmd `"net set ado `adopath'"'
		`cmd'
		di as text "  ~~~ to change back adopath you must do e.g. {inp}net set ado {c 'g}c(sysdir_plus)'"
	}
	else {
		di as text `"require: installing package {it:`ado'} in {stata "net query":default} directory ("`c(adopath)'")"'
	}

	cap ado uninstall `ado', from("`adopath'")
	*cap which `ado'
	*cap findfile `fn', path("`adopath'")
	*_assert c(rc), msg(`"Could not install, "`ado'" still exists"')

	di as text "(installing `ado')"
	if ("`from'" =="ssc") {
		ssc install `ado'
	}
	else {
		net install `ado', from("`from'") replace
		// replace should be redundant given our previous "ado uninstall", but might be useful in case of conflicts (multiple installs)
		
		* For packages that require it, update mata library index
		if inlist("`ado'", "parallel", "moremata") {
			mata mata mlib index
		}
	}
end


program RaiseMataError
	* Error codes internal to -require-
	* 0: all ok
	* 1: inner_get_version() couldn't find version in a starbang line
	* 2: get_version() couldn't find file
	* 3: get_version() couldn't find version in any of the starbang lines
	* 4: ensure_version() received an invalid version string (too many elements)
	* 5: ensure_version() received an invalid version string (non-numbers)
	* 6: ensure_version() installed version doesn't meet >= requirements
	* 7: ensure_version() installed version doesn't meet == requirements
	syntax, rc(integer) [REQuirement(string)]

	* Escape SMCL comments
	mata: st_local("raw_line", escape_line(`"`s(raw_line)'"'))
	
	if (`rc'==0) {
		exit // No errors
	}
	else if (`rc'==1) {
		di as error `"require parsing error: couldn't find version in starbang line "`raw_line'""'
		exit 2221
	}
	else if (`rc'==2) {
		di as error `"require parsing error: couldn't find file "`s(filename)'""'
		exit 2222
	}
	else if (`rc'==3) {
		di as error `"require parsing error: couldn't find version in any starbang line"'
		exit 2223
	}
	else if (`rc'==4) {
		di as error `"require parsing error: version string has too many elements: `s(raw_line)'"'
		exit 2224
	}
	else if (`rc'==5) {
		di as error `"require parsing error: version string has non-numbers: `s(raw_line)'"'
		exit 2225
	}
	else if (`rc'==6) {
		di as error `"require error: you are using version `s(version)' of `s(package)', but require at least version `requirement'"'
		exit 2226
	}
	else if (`rc'==7) {
		di as error `"require error: you are using version `s(version)' of `s(package)', but require version `requirement'"'
		exit 2227
	}
	else {
		di as error `"require: unknown error"'
		exit 2229
	}
end



program GetFilename
	syntax anything(name=package), [ADOPATH(string) VERBOSE]

	* Search for an .ado by default
	loc fn "`package'.ado"

	* Except for packages containing schemes where we search for .scheme
	* We allow for "scheme-*" and "scheme_*" prefixes (former is preferred though)
	if (strpos("`package'", "scheme")==1) {
		loc fn = subinstr("`package'", "scheme_", "scheme-", 1)
		loc fn "`fn'.scheme"
	}

	* If the .ado doesn't exist, try .sthlp (but only if it does exist!)
	cap findfile "`fn'", path("`adopath'")
	if (c(rc)) {
		loc candidate "`package'.sthlp"
		cap findfile "`candidate'", path("`adopath'")
		if (!c(rc)) loc fn "`candidate'"
	}
	cap // we must reset the error code to zero else it might get used outside this program

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

	if ("`verbose'" != "") di as text `"   $$ GetFilename selected file "`fn'""'

	c_local filename "`fn'"
end


// --------------------------------------------------------------------------
// Mata code:
// --------------------------------------------------------------------------

local M ustrregexm
local G ustrregexs

mata:
mata set matastrict on


// Convenience function for st_local("rc", strofreal(...)) which saves a return code into a local
void store_rc(real scalar rc)
{
	st_local("rc", strofreal(rc))
}


real scalar get_version(string scalar package, string scalar filename, string scalar full_fn, real scalar verbose)
{
	real scalar fh, rc, i, j, is_helpfile
	string scalar line, first_char, first_line

	rc = 1 // default values if we exit early (e.g. if there are no starbang lines)
	first_line = ""

	if (verbose) printf("{txt}Inspecting package {res}%s{txt}:\n", package)
	if (verbose) printf("{txt}Parsing file {res}%s:\n", full_fn)
	is_helpfile = strpos(filename, ".sthlp") | strpos(filename, ".hlp")

	fh = fopen(full_fn, "r")
	// scheme-plottig.scheme -> starbang on line 24
	for (i=1; i<=25; i++) {
		line = fget(fh)
		line = strtrim(line)
		if (verbose) printf("\n{txt} @@ line %f: {res}%s\n", i, escape_line(line))

		if (!strlen(line)) {
			if (verbose) printf("{txt}   $$ empty line found, continuing\n")
			continue
		}

		first_char = substr(line, 1, 1)
		
		if (!is_helpfile) {
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
		}

		if (first_line == "") first_line = line
		rc = inner_get_version(line, package, filename, full_fn, verbose)
		
		if (!rc) break // stop if all ok
	}

	// Couldn't get version
	if (rc) {
		store_version(package, filename, full_fn, first_line, "", "", "", "", "", "")
		return(3)
	}
	
	fclose(fh)
	return(0)
}

string scalar escape_line(string scalar line)
{
	string scalar escaped_line

	// Need to escape "{* ...}" strings or they won't be displayed (treated as smcl comments)
	// Also escape "{...}" or the next carriage return will be ignored
	// escaped_line = subinstr(line, "{*", "{c -(}*")
	// escaped_line = subinstr(escaped_line, "{...}", "{c -(}...}")	
	
	// Best just to escape everything...
	escaped_line = subinstr(line, "{", "{c -(}")

	return(escaped_line)
}


real scalar inner_get_version(string scalar line, string scalar package, string scalar filename, string scalar full_fn, real scalar verbose)
{
	// This function contains the core parsing function that extract a version from the starbang line
	//
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
	string scalar AUTHOR_MID, AUTHOR_END, EMAIL // NUM, END, DOT, DATESEP1, DATESEP2
	string scalar all_months, pat, month

	raw_line = line // backup

	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Constants
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
	START = "^[*]! +version +"
	VERSION = "[v]?(\d{1,2})\.(\d{1,3})\.(\d{1,3})[,]?"
	SPACE = " +"
	YEAR = "(199[0-9]|20[0-3][0-9]|9[6-9])" // 199x 200x 201x 202x 203x 96-99
	MON = "(jan|feb|ma[ry]|apr|ju[nl]|aug|sep|oct|nov|dec)"
	SHORT_MON = "(0?[1-9]|1[012])"
	DAY = "(0?[1-9]|[12][0-9]|3[01])"
	AUTHOR_MID = "(?:[a-z@, ]{2,} )?" // most authors have 3+ letters but fsum has 2
	EMAIL = "[a-z0-9._+-]{3,}@(?:[a-z0-9][a-z0-9-]*\.)+[a-z.]{2,} " // xyz@xyz.xyz abc@xy.co.uk foo+xyz@gmail.com
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

	if (verbose) printf(`"{txt}   $$ before standardizing, line is:{col 44}{res}%s\n"', escape_line(line))

	// Custom case for help files
	if (strpos(filename, ".sthlp") | strpos(filename, ".hlp")) {
		pat = "^\{\*([^}]+)\}" // extract "{* ...}" where ... cannot be "}"
		if (`M'(line, pat)>0) line = `G'(1)
		if (verbose) printf("{txt}   $$ help file detected, line is:{col 44}{res}%s\n", escape_line(line))
	}
	
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
	if (verbose) printf(`"{txt}   $$ before regex preprocessing, line is:{col 44}{res}%s\n"', escape_line(line))

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

	// Convert "12/31/22" to "31dec22"
	pat = "^(\*! +version .*) +" + SHORT_MON + "/" + DAY + "/([0-3][0-9])(| +.*)$"
	if (`M'(line, pat)>0) {
		month = all_months[strtoreal(`G'(2))]
		line = `G'(1) + " " + `G'(3) + month + "20" + `G'(4) + " " + `G'(5)
	}


	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Start main regex matching
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (verbose) printf(`"{txt}   $$ before regex parsing, line is:{col 44}{res}%s\n"', escape_line(line))


	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Match x.y.z DDmmmYY					[reghdfe ftools]
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (verbose) printf(`"{txt}   $$ trying to parse {col 44}{txt}*! version <version> <author> <date>\n"')
	pat = START + VERSION + SPACE + AUTHOR_MID + DAY + MON + YEAR
	if (`M'(line, pat)>0) {
		store_version(package, filename, full_fn, raw_line, `G'(1), `G'(2), `G'(3), `G'(4), `G'(5), `G'(6))
		return(0)
	}

	if (verbose) printf(`"{txt}   $$ trying to parse {col 44}{txt}*! version <version> <email> <date>\n"')
	pat = START + VERSION + SPACE + EMAIL + DAY + MON + YEAR
	if (`M'(line, pat)>0) {
		store_version(package, filename, full_fn, raw_line, `G'(1), `G'(2), `G'(3), `G'(4), `G'(5), `G'(6))
		return(0)
	}


	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Match x.y.z AUTHOR 		(no date!) [synth_runner]
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (verbose) printf(`"{txt}   $$ trying to parse {col 44}{txt}*! version <version> <author>\n"')
	pat = START + VERSION + SPACE + AUTHOR_END
	if (`M'(line, pat)>0) {
		store_version(package, filename, full_fn, raw_line, `G'(1), `G'(2), `G'(3), "", "", "")
		return(0)
	}



	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Match x.y.z (no date or author [xtbalance]
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (verbose) printf(`"{txt}   $$ trying to parse {col 44}{txt}*! version <version>\n"')
	pat = START + VERSION + "$"
	if (`M'(line, pat)>0) {
		store_version(package, filename, full_fn, raw_line, `G'(1), `G'(2), `G'(3), "", "", "")
		return(0)
	}


	// Rare cases start here...

	// "*! version dec 2020 (1.1.0)" [acreg]
	if (verbose) printf(`"{txt}   $$ trying to parse {col 44}{txt}*! version <mm> <YY> (<version>)\n"')
	pat = "^\*! version [a-z0-9 ]{1,10} \(" + VERSION + "\)$"
	if (`M'(line, pat)>0) {
		store_version(package, filename, full_fn, raw_line, `G'(1), `G'(2), `G'(3), "", "", "")
		return(0)
	}

	// Custom cases for Roger Newson's ADO files
	// No version number but starbang string has format:
	// 		*!Author: Roger Newson
	// 		*!Date: 06 October 2016 -> standardized as "*! version date: ..."
	pat = "^\*! version date: " + DAY + MON + YEAR + " *$"
	if (`M'(line, pat)>0) {
		store_version(package, filename, full_fn, raw_line, "", "", "", `G'(1), `G'(2), `G'(3) )
		return(0)
	}


	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Give up
	// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	if (verbose) printf("{txt}   $$ no version line found for %s\n", package)
	store_version(package, filename, full_fn, raw_line, "", "", "", "", "", "")
	return(1) // 1: inner_get_version() couldn't find version in a starbang line
}


void store_version(
	string scalar package,
	string scalar filename,
	string scalar full_fn,
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
	real scalar has_version, has_date

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
	has_version = subinstr(v, ".", "") !=""

	d = sprintf("%f%s%f", day, month, year)
	d = strofreal(date(d, "DMY"), "%td") // standardize 1mar2020 into 01mar2020
	has_date = d != "."

	st_sclear()
	st_global("s(package)", package)
	st_global("s(filename)", filename)
	st_global("s(full_fn)", full_fn)
	st_global("s(raw_line)", raw_line)
	if (has_version) {
		st_global("s(version_patch)", strofreal(patch))
		st_global("s(version_minor)", strofreal(minor))
		st_global("s(version_major)", strofreal(major))
		st_global("s(version)", v)
	}
	if (has_date) {
		st_global("s(version_date)", d)
	}
}


real scalar ensure_version(string scalar required_version, string scalar op)
{
	real scalar found_version
	real rowvector reqs

	found_version = 1e5 * strtoreal(st_global("s(version_major)")) + 1e3 * strtoreal(st_global("s(version_minor)")) + strtoreal(st_global("s(version_patch)"))
	
	reqs = strtoreal(tokens(subinstr(required_version, ".", " ")))
	if (cols(reqs)>3) return(4)
	if (hasmissing(reqs)) return(5)

	reqs = reqs, 0, 0
	reqs = 1e5 * reqs[1] + 1e3 * reqs[2] + reqs[3]

	if ((op == ">=") & (found_version < reqs)) return(6)
	if ((op == "==") & (found_version != reqs)) return(7)
	return(0)
}

end
