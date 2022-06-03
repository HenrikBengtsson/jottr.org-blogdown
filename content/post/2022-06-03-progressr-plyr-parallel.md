---
title: "progressr 0.10.1: Plyr Now Supports Progress Updates also in Parallel"
slug: progressr-0.10.1
date: 2022-06-03 13:00:00 -0700
categories:
 - R
tags:
 - R
 - package
 - parallel
 - progressr
 - plyr
 - future
 - parallel-processing
---

<div style="padding: 2ex; float: right;"/>
 <center>
   <img src="/post/three_in_chinese.gif" alt="Three strokes writing three in Chinese"/>
 </center>
</div>


**[progressr]** 0.10.1 is on CRAN. I dedicate this release to all **[plyr]** users and developers out there.

The **progressr** package provides a minimal API for reporting progress updates in R. The design is to separate the representation of progress updates from how they are presented. What type of progress to signal is controlled by the developer. How these progress updates are rendered is controlled by the end user. For instance, some users may prefer visual feedback, such as a horizontal progress bar in the terminal, whereas others may prefer auditory feedback.  The **progressr** package works also when processing R in parallel or distributed using the **[future]** framework.

## **plyr** + **future** + **progressr** ⇒ parallel progress reporting

The major update in this release, is that **[plyr]** (>= 1.8.7) now has built-in support for the **progressr** package when running in parallel.  For example,

```r
library(plyr)

## Parallelize on the local machine
future::plan("multisession")
doFuture::registerDoFuture()

library(progressr)
handlers(global = TRUE)

y <- llply(1:100, function(x) {
  Sys.sleep(1)
  sqrt(x)
}, .progress = "progressr", .parallel = TRUE)

#>   |============                                  |  28%
```

Previously, **plyr** only had built-in support for progress reporting when running sequentially.  Note that the **progressr** is the only package that supports progress reporting when using `.parallel = TRUE` in **plyr**.

Also, whenever using **progressr**, the user has plenty of options for where and how progress is reported.  For example, `handlers("rstudio")` uses the progress bar in the RStudio job interface, `handlers("progress")` uses terminal progress bars of the **progress** package, and `handlers("beep")` reports on progress using sounds. It's also possible to report progress in the Shiny.  See my blog post ['progressr 0.8.0 - RStudio’s Progress Bar, Shiny Progress Updates, and Absolute Progress'](/2021/06/11/progressr-0.8.0/) for more information.


## There's actually a better way

I actually recommend another way for reporting on progress with **plyr** map-reduce functions, which is more in line with the design philosophy of **progressr**:

> The developer is responsible for providing progress updates, but it’s only the end user who decides if, when, and how progress should be presented. No exceptions will be allowed.

Please see Section 'plyr::llply(…, .parallel = TRUE) with doFuture' in the ['progressr: An Introduction'](https://progressr.futureverse.org/articles/progressr-intro.html) vignette for this alternative approach, which has worked for long time already.  But, of course, adding `.progress = "progressr"` to your already existing **plyr** `.parallel = TRUE` code is as simple as it gets.


Now, make some progress!



## Other posts on progress reporting

* [progressr 0.8.0 - RStudio's Progress Bar, Shiny Progress Updates, and Absolute Progress](/2021/06/11/progressr-0.8.0/), 2021-06-11
* [e-Rum 2020 Slides on Progressr](/2020/07/04/progressr-erum2020-slides/), 2020-07-04
* See also ['progressr'](/tags/#progressr-list) tag.


## Links

* **progressr** package: [CRAN](https://cran.r-project.org/package=progressr), [GitHub](https://github.com/HenrikBengtsson/progressr), [pkgdown](https://progressr.futureverse.org)
* **plyr** package: [CRAN](https://cran.r-project.org/package=plyr), [GitHub](https://github.com/hadley/plyr), [pkgdown-ish](http://plyr.had.co.nz/)
* **future** package: [CRAN](https://cran.r-project.org/package=future), [GitHub](https://github.com/HenrikBengtsson/future), [pkgdown](https://future.futureverse.org)


[future]: https://future.futureverse.org
[parallelly]: https://parallelly.futureverse.org
[progressr]: https://progressr.futureverse.org
[plyr]: https://cran.r-project.org/package=plyr
[NEWS]: https://progressr.futureverse.org/news/index.html
