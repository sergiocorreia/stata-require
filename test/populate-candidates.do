	clear all
	cls
	cd "C:\Git\stata-require\test"
	
	insheet  using "ground-truth.tsv", clear tab names double
	gsort -weight
	keep in 1/100
	keep if mi(version)
	
	cd "C:\Git\stata-require\test\cache"

	cls	
	forval i = 1/`c(N)' {
		loc package = package[`i']
		which `package'
	}
	
	cd "C:\Git\stata-require\test"
	exit
