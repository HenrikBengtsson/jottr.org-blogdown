---
title: "Start Me Up"
slug: "startup"
aliases: [/2016/12/start-me-up.html]
date: 2016-12-22
categories:
- R
tags:
- R
- package
- startup
- Rprofile
- Renviron
- configuration
- environment variables
- options
---

The [startup] package makes it easy to control your R startup processes and to share part of your startup settings with others (e.g. as a public Git repository) while keeping secret parts to yourself.  Instead of having long and windy `.Renviron` and `.Rprofile` startup files, you can split them up into short specific files under corresponding `.Renviron.d/` and `.Rprofile.d/` directories.  For example,

```
# Environment variables
# (one name=value per line)
.Renviron.d/
 +- lang                   # language settings
 +- libs                   # library settings
 +- r_cmd_check            # R CMD check settings
 +- secrets                # secret access keys (don't share!)
 
# Configuration scripts
# (regular R scripts)
.Rprofile.d/ 
 +- interactive=TRUE/      # Used in interactive-mode only:
 |  +- help.start.R        # - launch the help server on fixed port
 |  +- misc.R              # - TAB completions and more
 |  +- package=fortunes.R  # - show a random fortune (iff installed)
 +- package=devtools.R     # devtools-specific options
 +- os=windows.R           # Windows-specific settings
 +- repos.R                # set up the CRAN repository
```

All you need to for this to work is to have a line:
```r
startup::startup()
```
in your `~/.Rprofile` file (you may use it in any of the other locations that R supports).   As an alternative to manually edit this file, just call `startup::install()` and this line will be appended if missing and if the file is missing that will also be created.  Don't worry, your old file will be backed up with a timestamp.

The startup package is extremely lightweight, has no external dependencies and depends only on the 'base' R package.  It can be installed from CRAN using `install.packages("startup")`.  _Note, startup 0.4.0 was released on CRAN on 2016-12-22 - until macOS and Windows binaries are available you can install it via `install.packages("startup", type = "source")`._

For more information on what's possible to do with the startup package, see the [README](https://cran.r-project.org/web/packages/startup/README.html) file of the package.


## Links
* startup package:
  - CRAN page: https://cran.r-project.org/package=startup
  - GitHub page: https://github.com/HenrikBengtsson/startup


[startup]: https://cran.r-project.org/package=startup
