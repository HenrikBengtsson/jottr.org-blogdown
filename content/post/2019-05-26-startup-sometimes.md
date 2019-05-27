---
title: "startup - run R startup files once per hour, day, week, ..."
slug: "startup-sometimes"
date: 2019-05-26 21:00:00 -0700
categories:
 - R
tags:
 - R
 - package
 - startup
 - Rprofile
 - Renviron
 - configuration
 - anacron
---

New release: **[startup]** 0.12.0 is now on CRAN.  This version introduces support for processing some of the R startup files with a certain frequency, e.g. once per day, once per week, or once per month.  See below for two examples.

![ZX Spectrum animation](/post/startup_0.10.0-zxspectrum.gif)
_startup::startup() is cross platform._

The [startup] package makes it easy to split up a long, complicated `.Rprofile` startup file into multiple, smaller files in a `.Rprofile.d/` folder.  For instance, setting R option `repos` in a separate file `~/.Rprofile.d/repos.R` makes it easy to find and update the option.  Analogously, environment variables can be configured by using multiple `.Renviron.d/` files.  To make use of this, install the **startup** package, and then call `startup::install()` once, which will tweak your `~/.Rprofile` file and create `~/.Renviron.d/` and `~/.Rprofile.d/` folders, if missing.  For an introduction, see [Start Me Up].


## Example: Show a fortune once per hour

The [**fortunes**](https://cran.r-project.org/package=fortunes) package is a collection of quotes and wisdom related to the R language.  By adding
```r
if (interactive()) print(fortunes::fortune())
```
to our `~/.Rprofile` file, a random fortune will be displayed each time we start R, e.g.
```
$ R --quiet

I think, therefore I R.
   -- William B. King (in his R tutorials)
      http://ww2.coastal.edu/kingw/statistics/R-tutorials/ (July 2010)

>
```

Now, if we're launching R frequently, it might be too much to see a new fortune each time R is started.  With **startup** (>= 0.12.0), we can limit how often a certain startup file should be processed via `when=<frequency>` declarations.  Currently supported values are `when=once`, `when=hourly`, `when=daily`, `when=weekly`, `when=fortnighly`, and `when=monthly`.  See the package vignette for more details.

For instance, we can limit ourselves to one fortune per hour, by creating a file `~/.Rprofile.d/interactive=TRUE/when=hourly/package=fortunes.R` containing:
```r
print(fortunes::fortune())
```
The `interactive=TRUE` part declares that the file should only be processed in an interactive session, the `when=hourly` part that it should be processed at most once per hour, and the `package=fortunes` part that it should be processed only if the **fortunes** package is installed.  It not all of these declarations are fulfilled, then the file will _not_ be processed.


## Example: Check the status of your CRAN packages once per day

If you are a developer with one or more packages on CRAN, the [**foghorn**](https://cran.r-project.org/package=foghorn) package provides `foghorn::summary_cran_results()` which is a neat way to get a summary of the CRAN statuses of your packages.  I use the following two files to display the summary of my CRAN packages once per day:

File `~/.Rprofile.d/interactive=TRUE/when=daily/package=foghorn.R`:
```r
try(local({
  if (nzchar(email <- Sys.getenv("MY_CRAN_EMAIL"))) {
    foghorn::summary_cran_results(email)
  }
}), silent = TRUE)
```

File `~/.Renviron.d/private/me`:
```
MY_CRAN_EMAIL=alice@example.org
```




## Links

* **startup** package:
  - CRAN page: https://cran.r-project.org/package=startup ([NEWS](https://cran.r-project.org/web/packages/startup/NEWS), [vignette](https://cran.r-project.org/web/packages/startup/vignettes/startup-intro.html))
  - GitHub page: https://github.com/HenrikBengtsson/startup


## Related

* [Start Me Up] on 2016-12-22.
* [Startup with Secrets - A Poor Man's Approach](/2018/03/30/startup-secrets/) on 2018-03-30.


[Start Me Up]: /2016/12/22/startup/
[startup]: https://cran.r-project.org/package=startup
