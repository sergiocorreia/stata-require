# stata-require
Ensure package requirements are met


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



--------


Misc: `here` notes:

1) Maybe `$here` should exclude the trailing `/`? Otherwise we end up with repeated slashes in:

```stata
use "$here/path/dataset"
```

