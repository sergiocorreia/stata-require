clear all
cls
cap ado uninstall require
net install require, from("c:\git\stata-require\src")

require rddensity>=1, debug("*!version 1.0 14-Jul-2019")
require erepost>=1.0.2, debug("*! version 1.0.2, Ben Jann, 15jun2015")
exit

require foobar>=3.1, debug("ASDASD")


require stripplot>=2.9, verbose

exit

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

require using requirements.txt, install

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



/*
      net install ddtiming, from(https://tgoldring.com/code/)


*/
