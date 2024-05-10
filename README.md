# REQUIRE: Ensure that installed Stata packages have a minimum/exact version

![GitHub release (latest by date)](https://img.shields.io/github/v/release/sergiocorreia/stata-require?label=last%20version)
![GitHub Release Date](https://img.shields.io/github/release-date/sergiocorreia/stata-require)
![GitHub commits since latest release (by date)](https://img.shields.io/github/commits-since/sergiocorreia/stata-require/latest)
![StataMin](https://img.shields.io/badge/stata-%3E%3D%2015.0-blue)


Ensure all required Stata packages and their specific versions are installed; similar to Python's `requirements`. For a detailed guide and examples, see the related paper on [arXiv](https://arxiv.org/pdf/2309.11058.pdf).

-----------

## Recent Updates

- **version 1.4.0 10apr2024**:
    - Multiple requirements can now be specified in the same line ("require reghdfe>=6 ftools>=2")
    - `require using ...` will now list all failed requirements instead of just the first one.
    - `require, list` renamed to `require, setup`
    - `require, setup` now defaults to writing exact requirements ("reghdfe==1.2.3") instead of minimum requirements. Use the `minimum` option for minimum requirements ("reghdfe>=1.2.3")
    - Misc bugfixes and minor improvements
- **version 1.3.1 19sep2023**:
    - Misc. bugfixes.
    - Paper uploaded to [arXiv](https://arxiv.org/pdf/2309.11058.pdf).
- **version 1.3.0 01sep2023**:
    - Refactored code.
    - Added `list` option.
    - Better support for version strings in help files.
    - Added tests based on certification scripts.
- **version 1.0.0 27jun2023**:
    - First stable release.


## Install

To install from SSC (last updated for version 1.3.1):

```stata
ssc install require
```

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

Alternatively, the lines below will install the package only if needed:

```stata
cap which require
if (c(rc)) net install require, from("https://raw.githubusercontent.com/sergiocorreia/stata-require/master/src/")
```

## Usage

The most common usage is to use require to ensure that a minimum version is installed:

```stata
require ivreg2 >= 4.1.0
require ftools >= 2.48.0
require reghdfe>= 6.12.1
```

Or equivalently,


```stata
require ivreg2 >= 4.1.0  ftools >= 2.48.0  reghdfe>= 6.12.1
```

This will ensure that whoever runs the do-file is not using an outdated version of user packages.

You can also require exact versions:

```stata
require ivreg2 == 4.1.0
```

And install missing packages automatically if needed:

```stata
require ivreg2 >= 4.1.0  , install
require ftools >= 2.48.0 , install from("https://github.com/sergiocorreia/ftools/raw/master/src/")
require reghdfe>= 6.12.1 , install from(https://github.com/sergiocorreia/reghdfe/raw/master/src/)
```

Lastly, you can just use it to ensure the package is installed without specifying a version:

```stata
require ivreg2
```

### Advanced usage

Require an exact version, using Github tags (WIP):

```stata
require reghdfe == 6.12.1 , install from(https://github.com/sergiocorreia/reghdfe/releases)
```

For large projects, such as a research paper, the recommended usage is to first create a `requirements.txt` file:

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

And then add this line to the top of every do-file (or at the beginning of a master do-file):

```
require using "requirements.txt", install
```


## Related packages

We also encourage users to manage their folders with the [`setroot`](https://github.com/sergiocorreia/stata-setroot) package (based on [`here`](https://github.com/korenmiklos/here) by Miklós Koren).


## Coverage of user packages from SSC

As discussed in our [accompanying paper](https://arxiv.org/pdf/2309.11058.pdf), one of our key goals was to successfully match as many user-contributed as possible, particularly those user widely by researchers. Figure 2 from the paper (below) illustrates the package performance as of version 1.1.

![performance](benchmark/performance.png)

