{smcl}
{* *! version 0.9.1 11jul2021}{...}
{viewerjumpto "Syntax" "require##syntax"}{...}
{viewerjumpto "Description" "require##description"}{...}
{viewerjumpto "Options" "require##options"}{...}
{viewerjumpto "Examples" "require##examples"}{...}
{viewerjumpto "Stored results" "require##results"}{...}
{viewerjumpto "Author" "require##contact"}{...}
{viewerjumpto "Acknowledgements" "require##acknowledgements"}{...}
{title:Title}

{p2colset 5 16 18 2}{...}
{p2col :{cmd:require} {hline 2}} Ensure that a given package is installed and has a certain version.{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{pstd}
{bf:Simple usage:}

{p 8 15 2}
{cmd:require} {it:package}{cmd:,}
[{opt install}
{opt from(url)}]
{p_end}

{pstd}
{bf:Require minimum version:}

{p 8 15 2}
{cmd:require} {it:package}{cmd:>=}{it:version}{cmd:,}
[{opt install}
{opt from(url)}]
{p_end}

{pstd}
{bf:Require exact version:}

{p 8 15 2}
{cmd:require} {it:package}{cmd:==}{it:version}{cmd:,}
[{opt install}
{opt from(url)}]
{p_end}

{pstd}
{bf:Using requirements file:}

{p 8 15 2}
{cmd:require} {cmd:using} {it:requirements.txt}{cmd:,}
[{opt install}
{opt from(url)}]
{p_end}

{marker options_table}{...}
{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt: {opt install}}install package if not present or wrong version(from SSC by default){p_end}
{synopt: {opt from(url)}}location of the package (e.g.: a Github URL){p_end}


{marker description}{...}
{title:Description}

{pstd}
Use {cmd:require} to help the reproductibility of your research,
by ensuring that people that run your code are using compatible versions of the packages you use
(either minimum versions, of exact versions).

{pstd}
This is useful in these four settings:

{pmore}
1. To avoid problems if e.g. your coauthors have older versions of regression commands (rdrobust, reghdfe, ivreg2, etc.).
This is important because newer versions of these commands might change the results (either point estimates or standard errors).

{pmore}
2. To ensure journal data editors can reproduce your code.

{pmore}
3. To ensure other researchers can reproduce your code.


{pmore}
4. If you are writing programs, to ensure your dependencies are met.

{pstd}
{cmd:require} tries to convert user-created versions into {browse "https://semver.org/":semvers} (semantic versions).
Thus, "version 1" becomes "version 1.0.0", indicating the major version, minor version, and patch version.

{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt install} Will install if package does not exist or version requirements are not met. By default installs from SSC.

{phang}
{opt from(url)} Alternative installation path.

{marker examples}{...}
{title:Examples}

{pstd}Ensure that the the last major versions of reghdfe and ftools are installed:{p_end}

{phang2}{cmd:require reghdfe>=6.0}{p_end}
{phang2}{cmd:require ftools>=2.47}{p_end}


{pstd}Use require with a text file:{p_end}

{phang2}{cmd:require using requirements.txt, install}{p_end}

{phang2}{hline 12} requirements.txt {hline 12}{p_end}
{phang2}{cmd:reghdfe>=6}{p_end}
{phang2}{cmd:ftools>=2.47}{p_end}
{phang2}{cmd:something>=1, from(someurl)}{p_end}
{phang2}{hline 42}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:require} stores the following in {cmd:s()}:

{synoptset 24 tabbed}{...}
{syntab:Macros}
{synopt:{cmd:s(version)}}version string x.y.z (equivalent to major.minor.patch in semantic versioning){p_end}
{synopt:{cmd:s(version_major)}}major version "x"{p_end}
{synopt:{cmd:s(version_minor)}}sub version "y"{p_end}
{synopt:{cmd:s(version_patch)}}patch{p_end}
{synopt:{cmd:s(package)}}name of package{p_end}
{synopt:{cmd:s(raw_line)}}starbang line used to determine version{p_end}
{synopt:{cmd:s(version_date)}}version date, if available{p_end}


{marker contact}{...}
{title:Author}

{pstd}Sergio Correia{break}
Board of Governors of the Federal Reserve{break}
Email: {browse "mailto:sergio.correia@gmail.com":sergio.correia@gmail.com}
{p_end}


{marker support}{...}
{title:Support and updates}

{pstd}Links to online documentation & code:{p_end}

{p2colset 8 10 10 2}{...}
{p2col: -}{browse "https://github.com/sergiocorreia/stata-require":Github page}: code repository, issues, etc.{p_end}
{p2colreset}{...}

{marker acknowledgements}{...}
{title:Acknowledgements}

{pstd}
Thank you in advance for bug-spotting and feature suggestions.{p_end}
