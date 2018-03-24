---
title: "Set Package Repositories at Startup"
slug: "config-repos"
aliases: [/2012/09/set-package-repositories-at-startup.html]
date: 2012-09-27
categories:
 - R
tags:
 - R
 - startup
 - Rprofile
 - configuration
 - packages
 - repositories
 - CRAN
 - Bioconductor
 - options
---

The below code shows how to configure the `repos` option in R such that `install.packages()` etc. will locate the packages without having to explicitly specify the repository.  Just add it to the `.Rprofile` file in your home directory (iff missing, create it). For more details, see `help("Startup")`.

```r
local({
  repos <- getOption("repos")

  # http://cran.r-project.org/
  # For a list of CRAN mirrors, see getCRANmirrors().
  repos["CRAN"] <- "http://cran.stat.ucla.edu"

  # http://www.stats.ox.ac.uk/pub/RWin/ReadMe
  if (.Platform$OS.type == "windows") {
    repos["CRANextra"] <- "http://www.stats.ox.ac.uk/pub/RWin"
  }

  # http://r-forge.r-project.org/
  repos["R-Forge"] <- "http://R-Forge.R-project.org"

  # http://www.omegahat.org/
  repos["Omegahat"] <- "http://www.omegahat.org/R"

  options(repos = repos)
})
```
