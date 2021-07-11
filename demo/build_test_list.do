clear all
cls

use http://repec.org/docs/sschotPPPcur, clear
drop author
rename hits_cur weight
bys package: keep if _n==1
gsort -weight

su weight in 1/500, mean
loc num = r(sum)
su weight, mean
loc den = r(sum)
loc ratio = 100 * `num' / `den'
di as text "Including:"
di as text %10.1f `ratio'

keep in 1/500

replace package = strlower(package)
gen fl = substr(package, 1, 1)
gen url = "http://fmwww.bc.edu/repec/bocode/" + fl + "/" + package + ".ado"
replace weight = ceil(weight)
compress
format %10.0f weight
keep package url weight
order package url weight
outsheet using "../test/package-list.tsv", replace noquote
exit

