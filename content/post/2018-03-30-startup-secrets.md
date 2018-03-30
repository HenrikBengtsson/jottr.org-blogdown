---
title: "Startup with Secrets - A Poor Man's Approach"
slug: "startup-secrets"
date: 2018-03-30
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
 - secrets
---

New release: **[startup]** 0.10.0 is on CRAN.

If your R startup files (`.Renviron` and `.Rprofile`) get long and windy, or if you want to make parts of them public and other parts private, then you can use the **[startup]** package to split them up in separate files and directories under `.Renviron.d/` and `.Rprofile.d/`.  For instance, the `.Rprofile.d/repos.R` file can be solely dedicated to setting in the `repos` option, which specifies from which web servers R packages are installed from. This makes it easy to find and easy to share with others (e.g. on GitHub).  To make use of **startup**, install the package and then call `startup::install()` once.  For an introduction, see [Start Me Up].

![ZX Spectrum animation](/post/startup_0.10.0-zxspectrum.gif)
_startup::startup() is cross platform._


Several R packages provide APIs for easier access to online services such as GitHub, GitLab, Twitter, Amazon AWS, Google GCE, etc.  These packages often rely on R options or environment variables to hold your secret credentials or tokens in order to provide more or less automatic, batch-friendly access to those services.  For convenience, it is common to set these secret options in `~/.Rprofile` or secret environment variables in `~/.Renviron` - or if you use the **[startup]** package, in separate files.  For instance, by adding a file `~/.Renviron.d/private/github` containing:

```
## GitHub token used by devtools
GITHUB_PAT=db80a925a60ee5b57f323c7b3719bbaaf9f96b26
```

then, when you start R, environment variable `GITHUB_PAT` will be accessible from within R as:

```r
> Sys.getenv("GITHUB_PAT")
[1] "db80a925a60ee5b57f323c7b3719bbaaf9f96b26"
```

which means that also **devtools** can make use of it.

**IMPORTANT**: If you're on a shared file system or a computer with multiple users, you want to make sure no one else can access your files holding "secrets".  If you're on Linux or macOS, this can be done by:

```sh
$ chmod -R go-rwx ~/.Renviron.d/private/
```

Also, _keeping "secrets" in options or environment variables is **not** super secure_.  For instance, _if your script or a third-party package dumps `Sys.getenv()` to a log file, that log file will contain your "secrets" too_.  Depending on your default settings on the machine / file system, that log file might be readable by others in your group or even by anyone on the file system.  And if you're not careful, you might even end up sharing that file with the public, e.g. on GitHub.

Having said this, with the above setup we at least know that the secret token is only loaded when we run R and only when we run R as ourselves.  **Starting with startup 0.10.0** (\*), we can customize the startup further such that secrets are only loaded conditionally on a certain environment variable.  For instance, if we instead of putting our secret files in a folder named:
```
~/.Renviron.d/private/SECRET=develop/
```
because then (i) that folder will not be visible to anyone else because we already restricted access to `~/.Renviron.d/private/` and (ii) the secrets defined by files of that folder will _only be loaded_ during the R startup _if and only if_ environment variable `SECRET` has value `develop`.  For example,

```r
$ SECRET=develop Rscript -e "Sys.getenv('GITHUB_PAT')"
[1] "db80a925a60ee5b57f323c7b3719bbaaf9f96b26"
```

will load the secrets, but none of:

```r
$ Rscript -e "Sys.getenv('GITHUB_PAT')"
[1] ""

$ SECRET=runtime Rscript -e "Sys.getenv('GITHUB_PAT')"
[1] ""
```

In other words, with the above approach, you can avoid loading secrets by default and only load them when you really need them.  This lowers the risk of exposing them by mistake in log files or to R code you're not in control of.  Furthermore, if you only need `GITHUB_PAT` in _interactive_ devtools sessions, name the folder:
```
~/.Renviron.d/private/interactive=TRUE,SECRET=develop/
```
and it will only be loaded in an interactive session, e.g.
```r
$ SECRET=develop Rscript -e "Sys.getenv('GITHUB_PAT')"
[1] ""
```
and
```r
$ SECRET=develop R --quiet

> Sys.getenv('GITHUB_PAT')
[1] "db80a925a60ee5b57f323c7b3719bbaaf9f96b26"
```


To repeat what already been said above, _storing secrets in environment variables or R variables provides only very limited security_.  The above approach is meant to provide you with a bit more control if you are already storing credentials in `~/.Renviron` or `~/.Rprofile`.  For a more secure approach to store secrets, see the **[keyring]** package, which makes it easy to "access the system credential store from R" in a cross-platform fashion, provides a better alternative.


## What's new in startup 0.10.0?

* Renviron and Rprofile startup files that use `<key>=<value>` filters with non-declared keys are now(\*) skipped (which makes the above possible).

* `startup(debug = TRUE)` report on more details.

* A startup script can use `startup::is_debug_on()` to output message during the startup process conditionally on whether the user chooses to display debug message or not.

* Added `sysinfo()` flags `microsoftr`, `pqr`, `rstudioterm`, and `rtichoke`, which can be used in directory and file names to process them depending on in which environment R is running.

* `restart()` works also in the RStudio Terminal.


## Links

* **startup** package:
  - CRAN page: https://cran.r-project.org/package=startup ([NEWS](https://cran.r-project.org/web/packages/startup/NEWS), [vignette](https://cran.r-project.org/web/packages/startup/vignettes/startup-intro.html))
  - GitHub page: https://github.com/HenrikBengtsson/startup

* Blog post [Start Me Up] on 2016-12-22.


(\*) In **startup** (< 0.10.0), `~/.Renviron.d/private/SECRET=develop/` would be processed not only when `SECRET` had value `develop` but also when it was _undefined_.  In **startup** (>= 0.10.0), files with such `<key>=<value>` tags will now be skipped when that key variable is undefined.


[startup]: https://cran.r-project.org/package=startup
[keyring]: https://cran.r-project.org/package=keyring
[Start Me Up]: /2016/12/22/startup/
