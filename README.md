# stata-require

Ensure all required Stata packages and their specific versions are installed; similar to Python's `requirements`


## Install


To install from Github, type:

```stata
cap ado uninstall require
net install require, from("https://raw.githubusercontent.com/sergiocorreia/stata-require/master/src/")
```

To install locally, type:

```stata
cap ado uninstall require
net install require, from("c:\git\stata-require\src")
```


## Usage

Simple usage:

```stata
require ftools
require reghdfe
```

Use a specific location:

```stata
require ftools, from("https://github.com/sergiocorreia/ftools/raw/master/src/")
require reghdfe, from(https://github.com/sergiocorreia/reghdfe/raw/master/src/)
```

Require a minimum version, install if needed:

```stata
require ftools  >= 2.48.0 , install from("https://github.com/sergiocorreia/ftools/raw/master/src/")
require reghdfe >= 6.12.1 , install from(https://github.com/sergiocorreia/reghdfe/raw/master/src/)
```

Require an exact version, using Github tags (WIP):

```stata
require reghdfe == 6.12.1 , install from(https://github.com/sergiocorreia/reghdfe/releases)
```

Use a `requirements.txt` file, and install if needed

```
require using "$here/code/requirements.txt", install
```

```
<<< contents of requirements.txt <<<<
# SSC requirements

mdesc		>= 0.9.4	, from(ssc)
winsor2		>= 1.1		, from(ssc)
coefplot	>= 1.8.4	, from(ssc)

# Github/etc requirements

rdrobust	>= 8.1		, from(https://raw.githubusercontent.com/rdpackages/rdrobust/master/stata)
rddensity	>= 1.0		, from(https://raw.githubusercontent.com/rdpackages/rddensity/master/stata)
lpdensity	>= 1.0		, from(https://raw.githubusercontent.com/nppackages/lpdensity/master/stata)
>>>
```

## Misc. notes

We also recommend using the `here` command: https://github.com/korenmiklos/here

(Note that `$here` currently includes trailing `/` so we can't do `use $here/dataset` and instead must do `use ${here}dataset`.


## Packages not supported by `require` (lacking version numbers):

- `rtfutil`
- `sencode`
- `listtab`


