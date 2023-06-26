program define alt_ssc
	gettoken cmd 0 : 0, parse(" ,")
	if ("`cmd'" == "install") {
		ssc_install `0'
	}
	else {
		di as err `"{bf:ssc `cmd'}: invalid subcommand"'
		exit 198
	}
end


program define ssc_install
	gettoken pkgname 0 : 0, parse(" ,")
	CheckPkgname "ssc install" `"`pkgname'"'
	local pkgname `"`s(pkgname)'"'
	syntax [, ALL REPLACE Verbose]
	loc verbose = ("`verbose'" != "")
	local ltr = bsubstr("`pkgname'",1,1)
	loc baseurl "C:/Git/ssc-mirror"
	loc url "`baseurl'/`ltr'"
	qui net from `url'
	capture net describe `pkgname'
	local rc = _rc
	if (_rc==601 | _rc==661) {
		di as err `"{bf:ssc install}: "{bf:`pkgname'}" not found at SSC, type {stata search `pkgname'}"'
		di as err "(To find all packages at SSC that start with `ltr', type {stata ssc describe `ltr'})"
		exit `rc'
	}
	if _rc {
		error `rc'
	}

	di as text ""

	* Change working directory and unzip files there
	loc wd "`c(pwd)'"
	tempfile path
	if (`verbose') di as text "- Temporary folder: `path'"
	mkdir "`path'"
	qui cd "`path'"
	loc zip_path "`baseurl'/`ltr'/`pkgname'.zip"
	qui confirm file "`zip_path'"
	if (`verbose') di as text "- Extracting files into temporary folder"
	qui unzipfile "`zip_path'"

	* Go back to previous working directory (TODO: make more robust to errors)
	qui cd "`wd'"

	* Install
	if (`verbose') di as text "- Installing package"
	capture noi net install `pkgname', `all' `replace' from("`path'")

	* Clear temp path
	if (`verbose') di as text "- Removing temporary files"
	loc fns : dir "`path'" files "*.*"
	foreach fn of local fns {
		erase "`path'/`fn'"
	}
	rmdir "`path'"

	* Fix stata.trk file (careful!)
	if (`verbose') di as text "- Fixing stata.trk"
	qui findfile stata.trk
	loc fn "`r(fn)'"
	loc fixed_path = subinstr(`"`path'"', "\", "\BS", .)
	filefilter "`fn'" "`fn'.tmp", from(`"`macval(fixed_path)'"') to("`baseurl'/`ltr'") replace
	copy "`fn'.tmp" "`fn'", replace
	rm "`fn'.tmp"

	local rc = _rc
	if _rc==601 | _rc==661 {
			di
			di as err `"{p}{bf:ssc install}: apparent error in package file for {bf:`pkgname'}; please notify {browse "mailto:repec@repec.org":repec@repec.org}, providing package name{p_end}"'
	}
	exit `rc'
end


program define CheckPkgname, sclass
		args id pkgname
		sret clear
		if `"`pkgname'"' == "" {
				di as err `"{bf:`id'}: nothing found where package name expected"'
				exit 198
		}
		if length(`"`pkgname'"')==1 {
				di as err `"{bf:`id'}: "{bf:`pkgname'}" invalid SSC package name"'
				exit 198
		}
		local pkgname = lower(`"`pkgname'"')
		if !index("abcdefghijklmnopqrstuvwxyz_",bsubstr(`"`pkgname'"',1,1)) {
				di as err `"{bf:`id'}: "{bf:`pkgname'}" invalid SSC package name"'
				exit 198
		}
		sret local pkgname `"`pkgname'"'
end

