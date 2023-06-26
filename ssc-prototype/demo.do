clear all
cls

cap ado uninstall fabplot
set trace off
set seed 1234

di as text "<<<<"

alt_ssc install fabplot, verbose
*which fabplot

exit
