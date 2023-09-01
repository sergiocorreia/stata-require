* ===========================================================================
* Test require.ado against list of prechecked packages
* ===========================================================================
	clear all
	cls
	cap ado uninstall require
	net install require, from("c:\git\stata-require\src")


* Quick tests on Github packages
	require synth_runner>=1.6, verbose
	require parallel>=1.20, // install from("https://raw.github.com/gvegayon/parallel/stable/")
	require gtools>=1.7.5, // install from("https://raw.githubusercontent.com/mcaceresb/stata-gtools/master/build/")
	require scheme-sergio>=0.1, // install from("https://raw.githubusercontent.com/sergiocorreia/stata-schemes/main")
	*require stripplot>=2.9, verbose
	*require tabout>=2.0.8
	*require mdesc>=2.1

exit


Cases not handled:

1) RCALL:

// documentation written for markdoc

/***
[Version: 3.0.5](https://github.com/haghish/rcall/tags) 

cite: [Haghish, E. F. (2019). Seamless interactive language interfacing between R and Stata. The Stata Journal, 19(1), 61-82.](https://journals.sagepub.com/doi/full/10.1177/1536867X19830891)

-----

2) moremata: no version history, should be enough to do "require moremata"

----

3) diff.ado has month and year but no day


