* ===========================================================================
* Part 2 of keyword extraction
* ===========================================================================
* This must be run after extract-package-keywords.py


// --------------------------------------------------------------------------
// Load popularity ranking
// --------------------------------------------------------------------------

    use "http://repec.org/docs/sschotPPPcur", clear
    bys package: keep if _n==1
    keep package hits_cur
    replace package = strlower(package)
    compress
    tempfile ssc
    save "`ssc'"


// --------------------------------------------------------------------------
// Load keywords and deduplicate them
// --------------------------------------------------------------------------

    import delimited "C:\Git\stata-require\benchmark\package-keywords.tsv", varnames(1) clear 
    bys keyword: gen N = _N
    tab N // 7% of the keywords can't be unambiguously attributed to a single package!

    * We'll pick packages with the same name as the command
    * If that still doesn't resolve conflicts, we'll pick the most popular package
    gen byte is_match = package == keyword
    tab N is_match, m
    merge m:1 package using "`ssc'", keep(master match) keepus(hits_cur) nogen
    replace hits_cur = 0 if mi(hits_cur) // it seems SSC-whatshot doesn't get updated very often

    sort keyword is_match hits_cur
    br if N>1
    asd
    bys keyword (is_match hits_cur): keep if _n==_N
    gisid keyword

    keep  keyword package filename extension
    order keyword package filename extension
    compress
    save "./keyword-package-crosswalk", replace
