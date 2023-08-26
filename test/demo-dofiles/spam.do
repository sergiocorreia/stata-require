clear all
cls

sysuse auto
gegen maxprice = max(price), by(foreign)
reghdfe price, a(turn)
mdesc _all

exit
