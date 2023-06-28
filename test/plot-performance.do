* ===========================================================================
* Plot performance against packages (using data generated by test-groundtruth.do)
* ===========================================================================

	clear all
	cls
	use "performance"
	replace y = 100 * y
	format %8.2f y
	gen i = _n

	* Font: Franklin Gothic Book
	graph hbar (asis) y, over(x, relabel(1 "Unweighted" 2 "By SSC downloads" 3 "By publication" 4 "By publ. intensity") sort(i)) blabel(bar, color(white) position(inside) format(%8.1f)) ytitle(Correct matches (%)) yscale(nofextend) title(Performance against SSC packages, span margin(medium)) caption(Publication data based on analysis of journal replication files by Kranz (2023), span margin(medsmall)) scheme(sergio) xsize(16) ysize(10) scale(1.2)
	graph export "performance.png", replace
	graph export "performance.pdf", replace
	graph export "performance.eps", replace

	graph hbar (asis) y, over(x, relabel(1 "Unweighted" 2 "By SSC downloads" 3 "By publication" 4 "By publ. intensity") sort(i)) blabel(bar, color(white) position(inside) format(%8.1f)) ytitle(Correct matches (%)) yscale(nofextend) scheme(sergio) xsize(16) ysize(10) scale(1.2)
	graph export "performance-untitled.png", replace
	graph export "performance-untitled.pdf", replace
	graph export "performance-untitled.eps", replace
