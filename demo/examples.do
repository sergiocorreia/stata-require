clear all
cls
cap ado uninstall require
net install require, from("c:\git\stata-require\src")

require stata>=16
require reghdfe>=6
require ftools>=2.47

cap noi require rdrobust>=122, verbose
assert c(rc)

cap noi require reghdfe==5
assert c(rc)

require reghdfe
require reghdfe>=6
require gtools=1.7.5
require ftools>=2.43

exit

require fastxtile, from(...)


/download/2.48.0/ftools-2.48.0.zip


require fastxtile, from(https://github.com/sergiocorreia/ftools/releases)
require fastxtile, from(https://github.com/sergiocorreia/ftools/tree/master/src)


require fastxtille, install
require fastxtille, install from(ssc)
require fastxtille, install from("https://github.com/sergiocorreia/ftools/tree/master/src")
require fastxtille, install from("https://github.com/sergiocorreia/ftools/releases")

require fastxtille, install

require fastxtille>=5, install from("https://github.com/sergiocorreia/ftools/tree/master/src")
require fastxtille>=5, install from("https://github.com/sergiocorreia/ftools/releases")


require stata>=16
require reghdfe=5.85.0
require ftools>=5.1
