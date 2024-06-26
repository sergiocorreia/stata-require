{smcl}
{* *! version 1.4.0 10apr2024}{...}
{vieweralsosee "which" "help which"}{...}
{vieweralsosee "ssc" "help ssc"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "setroot" "setroot"}{...}
{vieweralsosee "packagesearch" "packagesearch"}{...}
{vieweralsosee "repkit" "repkit"}{...}
{viewerjumpto "Syntax" "require##syntax"}{...}
{viewerjumpto "Advanced syntax" "require##advanced_syntax"}{...}
{viewerjumpto "Description" "require##description"}{...}
{viewerjumpto "Options" "require##options"}{...}
{viewerjumpto "Examples" "require##examples"}{...}
{viewerjumpto "Stored results" "require##results"}{...}
{viewerjumpto "Author" "require##contact"}{...}
{viewerjumpto "Acknowledgements" "require##acknowledgements"}{...}
{title:Title}

{p2colset 5 16 18 2}{...}
{p2col :{cmd:require} {hline 2}}Enforce exact/minimum versions of community-contributed packages.{p_end}
{p2col:}(View {browse "https://arxiv.org/pdf/2309.11058.pdf":PDF} article; {browse "https://ar5iv.labs.arxiv.org/html/2309.11058":HTML} version){p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{pstd}
Require that an exact version of a package is installed:

{p 8 15 2}
{cmd:require} {it:package} {cmd:==} {it:version}
[{cmd:,}
{opt install}
{opt from(location)}
{opt adopath(dirname)}
{help require##dev_options:dev_options}]
{p_end}

{pstd}
Require that a minimum version of a package is installed:

{p 8 15 2}
{cmd:require} {it:package} {cmd:>=} {it:version}
[{cmd:,}
{opt install}
{opt from(location)}
{opt adopath(dirname)}
{help require##dev_options:dev_options}]
{p_end}

{pstd}
Require that a package is installed; don't inspect its version:

{p2colset 9 35 15 2}{...}
{p2col:{cmd:require} {it:package}}
[{cmd:,}
{opt install}
{opt from(location)}
{opt adopath(dirname)}
{help require##dev_options:dev_options}]
{p_end}
{p2colreset}{...}


{marker advanced_syntax}{...}
{title:Advanced syntax}

{pstd}
Require multiple packages in a single line:

{p 8 15 2}
{cmd:require} [{it:package} | {it:package} {cmd:==} {it:version} | {it:package} {cmd:>=} {it:version}] ...
[{cmd:,}
{opt install}
{opt adopath(dirname)}
{help require##dev_options:dev_options}]
{p_end}

{pstd}
Require multiple packages through a requirements file (recommended):

{p 8 15 2}
{cmd:require} {cmd:using} {it:requirements.txt}
[{cmd:,}
{opt install}
{opt adopath(dirname)}]
{p_end}

{pstd}
Set up a requirements file from currently installed packages:

{p 8 15 2}
{cmd:require} [{cmd:using} {it:requirements.txt}] {cmd:,}
{opt setup} [{opt adopath(dirname)}
{help require##setup_options:setup_options}]
{p_end}


{marker options_table}{...}
{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{marker main_options}{...}
{syntab:Main}
{synopt: {opt install}}install package if not present or if version requirements are not met{p_end}
{synopt: {opt from(location)}}location of the installable package; either a URL, a directory, or "SSC" (default){p_end}
{synopt: {opt adopath(dirname)}}use alternative directory when searching/installing packages. Also accepts keywords "PLUS" , "SITE", and "PERSONAL". Searches c(adopath) by default; installs based on "net query".{p_end}

{marker setup_options}{...}
{syntab:Set up a requirements file or list it on screen}
{p2coldent:* {opt setup}}create file with list of requirements{p_end}
{synopt: {opt save}}alternative to {it:using}; saves requirements file with default filename ({it:requirements.txt}){p_end}
{synopt: {opt replace}}replace using file if it already exists{p_end}
{synopt: {opt min:imum}}use minimum requirements (>=) instead of exact requirements (==; default){p_end}
{synopt: {opt stata}}add a line requiring the currently-installed Stata version{p_end}

{syntab:Developer options}
{synopt: {opt strict}}raise an error if the version string couldn't be parsed even when not checking versions{p_end}
{synopt: {opt verbose}}show each regex attempt{p_end}
{synopt: {opt debug(str)}}instead of parsing the file, treat the provided string as the starbang line{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* {opt setup} is required when creating requirement files.{p_end}


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
{opt from(location)} Alternative installation path.


{marker examples}{...}
{title:Examples}

{pstd}Ensure that the the last major versions of reghdfe and ftools are installed:{p_end}

{phang2}{cmd:require reghdfe >= 6.0}{p_end}
{phang2}{cmd:require ftools >= 2.47}{p_end}


{pstd}You can also combine these requirements into a single line:{p_end}

{phang2}{cmd:require reghdfe>=6.0 ftools>=2.47}{p_end}


{pstd}You can also use require with a text file.
This is very useful for projects with multiple do-files and dependencies.
First, you should create a text file such as:{p_end}

{phang2}{hline 12} requirements.txt {hline 12}{p_end}
{phang2}{cmd:reghdfe>=6}{p_end}
{phang2}{cmd:ftools>=2.47}{p_end}
{phang2}{cmd:something>=1, from(someurl)}{p_end}
{phang2}{hline 42}{p_end}

{pstd}Then, at the beginning of every do-file:{p_end}

{phang2}{cmd:require using requirements.txt, install}{p_end}

{pstd}To facilitate using a requirements file, you can display the currently installed packages
with:{p_end}

{phang2}{cmd:require, setup}{p_end}

{pstd}And can also save this list to a file with:{p_end}

{phang2}{cmd:require using requirements.txt, setup}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:require} stores the following in {cmd:s()}:

{synoptset 24 tabbed}{...}
{syntab:Macros}
{synopt:{cmd:s(package)}}name of package{p_end}
{synopt:{cmd:s(version)}}version string "x.y.z" (equivalent to major.minor.patch in semantic versioning){p_end}
{synopt:{cmd:s(version_major)}}major version "x"{p_end}
{synopt:{cmd:s(version_minor)}}sub version "y"{p_end}
{synopt:{cmd:s(version_patch)}}patch version "z"{p_end}
{synopt:{cmd:s(version_date)}}version date, if available, in the %td format (e.g. "31dec2022"){p_end}
{synopt:{cmd:s(filename)}}filename used to determine version (typically an .ado file){p_end}
{synopt:{cmd:s(raw_line)}}starbang line used to determine version{p_end}


{marker contact}{...}
{title:Authors}

{pstd}Sergio Correia{break}
Board of Governors of the Federal Reserve{break}
Email: {browse "mailto:sergio.correia@gmail.com":sergio.correia@gmail.com}
{p_end}


{pstd}Matthew P. Seay{break}
Board of Governors of the Federal Reserve{break}
Email: {browse "mailto:matt.seay@frb.gov":matt.seay@frb.gov}
{p_end}


{marker support}{...}
{title:Support and updates}

{pstd}Links to online documentation & code:{p_end}

{p2colset 8 10 10 2}{...}
{p2col: -}{browse "https://arxiv.org/pdf/2309.11058.pdf":PDF article} for more examples and in-depth explanations{p_end}
{p2col: -}{browse "https://github.com/sergiocorreia/stata-require":Github page} for the code repository, to report issues, etc.{p_end}
{p2colreset}{...}

{marker acknowledgements}{...}
{title:Acknowledgements}

{pstd}
We thank Sebastian Kranz for helping us access the Stata code contained in the replication packages published by the {it:American Economic Association} journals,
{it:the Review of Economic Studies}, and {it:the Review of Economics and Statistics}.{p_end}

{pstd}
We are also grateful to Stephen P. Jenkins (editor), Benjamin Daniels, Paulo Guimarães, Miklós Koren, Julian Reif, Luis Eduardo San Martin, Lars Vilhuber,
and seminar participants at the 2023 Stata Conference for their valuable suggestions.{p_end}

