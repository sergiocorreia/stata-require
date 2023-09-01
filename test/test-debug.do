noi cscript "require, debug(...)" adofile require

* No testing, only parsing
require fakepackage, debug("*! version 1.2.3 16jun2011")
sreturn list
assert s(package) == "fakepackage"
assert s(filename) == "fakepackage.ado"
assert s(raw_line) == "*! version 1.2.3 16jun2011"
assert s(version) == "1.2.3"
assert s(version_major) == "1"
assert s(version_minor) == "2"
assert s(version_patch) == "3"
assert s(version_date) == "16jun2011"


* Parse and test (no error)
require fakepackage >= 1.2.3, debug("*! version 1.2.3 16jun2011")
require fakepackage >= 1.2.2, debug("*! version 1.2.3 16jun2011")
require fakepackage >= 1.2.1, debug("*! version 1.2.3 16jun2011")
require fakepackage >= 1.2  , debug("*! version 1.2.3 16jun2011")
require fakepackage >= 1    , debug("*! version 1.2.3 16jun2011")
require fakepackage == 1.2.3, debug("*! version 1.2.3 16jun2011")

* Parse and test (error)
cap require fakepackage >= 1.2.4, debug("*! version 1.2.3 16jun2011")
assert c(rc)==2226
cap require fakepackage == 1, debug("*! version 1.2.3 16jun2011")
assert c(rc)==2227

* Parse misc. additional cases
require gr0070==1.2.5, debug("*!  version 1.2.5   16jun2011") // multiple spacing
assert s(version) == "1.2.5"

require scheme_scientific==1, debug("*!  version 1.0  01aug2018") // multiple spacing
assert s(version) == "1.0.0"

require rdmulti==0.6, debug("* !version 0.6 2021-01-04") // star split from bang
assert s(version) == "0.6.0"

* Special case; .sthlp files
require egenmisc, debug(`"{* *! version 1.2.14  02feb2013}{...}"')
require egenmisc==1.2.14, debug("{* *! version 1.2.14  02feb2013}{...}") // sthlp file
assert s(version) == "1.2.14"

exit
