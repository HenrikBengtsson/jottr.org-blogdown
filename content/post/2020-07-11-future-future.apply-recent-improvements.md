---
title: "future and future.apply - Some Recent Improvements"
slug: "future-future.apply-recent-improvements"
date: 2020-07-11 22:15:00 -0700
categories:
 - R
tags:
 - R
 - package
 - future
 - future.apply
 - foreach
 - progressr
 - parallel
 - HPC
 - asynchronous
 - compute clusters
---

There are new versions of **[future]** and **[future.apply]** - your friends in the parallelization business - on CRAN.  These updates are mostly maintenance updates with bug fixes, some improvements, and preparations for upcoming changes.  It's been some time since I blogged about these packages, so here is the summary of the main updates this far since early 2020:

* **future**:

  - `values()` for lists and other containers was renamed to `value()` to simplify the API [future 1.17.0]

  - When future results in an evaluation error, the `result()` object of the future holds also the session information when the error occurred [future 1.17.0]
  
  - `value()` can now detect and warn if a `future(..., seed=FALSE)` call generated random numbers, which then might give unreliable results because non-parallel safe, non-statistically sound random number generation (RNG) was used [future 1.16.0]

  - Progress updates by **[progressr]** are relayed in a near-live fashion for multisession and cluster futures [future 1.16.0]

  - `makeClusterPSOCK()` gained argument `rscript_envs` for setting or copying environment variables _during_ the startup of each worker, e.g. `rscript_envs=c(FOO="hello world", "BAR")` [future 1.17.0].  In addition, on Linux and macOS, it also possible to set environment variables _prior_ to launching the workers, e.g. `rscript=c("TMPDIR=/tmp/foo", "FOO='hello world'", "Rscript")` [future 1.18.0]

  - Error messages of severe cluster future failures are more informative and include details on the affected worker include hostname and R version [future 1.17.0 and 1.18.0]

* **future.apply**:

  - `future_apply()` gained argument `simplify`, which has been added to `base::apply()` R-devel (to become R 4.1.0) [future.apply 1.6.0]

  - Added `future_.mapply()` corresponding to `base::.mapply()` [future.apply 1.5.0]

  - `future_lapply()` and friends set a label on each future that reflects the
    name of the function and the index of the chunk, e.g. 'future_lapply-3' [future.apply 1.4.0]

  - The assertion of the maximum size of globals per chunk is significantly faster for `future_apply()` [future.apply 1.4.0]
   
There have also been updates to **[doFuture]** and **[future.batchtools]**.  Please see their NEWS files for the details.


## What's next?

I'm working on cleaning up and harmonization the Future API even further.  This is necessary so I can add some powerful features later on.  One example of this cleanup is making sure that all types of futures are resolved in a local environment, which means that the `local` argument can be deprecated and eventually removed.  Another example is to deprecate argument `persistent` for cluster futures, which is an "outlier" and remnant from the past.  I'm aware that some of you use `plan(cluster, persistent=TRUE)`, which, as far as I understand, is because you need to keep persistent variables around throughout the lifetime of the workers.  I've got a prototype of "sticky globals" that solves this problem differently, without the need for `persistent=FALSE`.  I'll try my best to make sure everyone's needs are met.

I've also worked with the maintainers of **[foreach]** to harmonize the end-user and developer experience of **foreach** with that of the **future** framework.  For example, in `y <- foreach(...) %dopar% { ... }`, the `{ ... }` expression is now always evaluated in a local environment, just like futures.  This helps avoid some quite common beginner mistakes that happen when moving from sequential to parallel processing.  You can read about this change in the ['foreach 1.5.0 now available on CRAN'](https://blog.revolutionanalytics.com/2020/03/foreach-150-released.html) blog post by Hong Ooi.  There is also [a discussion](https://github.com/RevolutionAnalytics/foreach/issues/2) on updating how **foreach** identifies global variables and packages so that it works the same as the **future** framework.


Happy futuring!


## Links
* **future** package: [CRAN](https://cran.r-project.org/package=future), [GitHub](https://github.com/HenrikBengtsson/future)
* **future.apply** package: [CRAN](https://cran.r-project.org/package=future.apply), [GitHub](https://github.com/HenrikBengtsson/future.apply)
* **doFuture** package: [CRAN](https://cran.r-project.org/package=doFuture), [GitHub](https://github.com/HenrikBengtsson/doFuture) (a **[foreach]** adapter)
* **future.batchtools** package: [CRAN](https://cran.r-project.org/package=future.batchtools), [GitHub](https://github.com/HenrikBengtsson/future.batchtools)
* **future.callr** package: [CRAN](https://cran.r-project.org/package=future.callr), [GitHub](https://github.com/HenrikBengtsson/future.callr)
* **future.tests** package: [CRAN](https://cran.r-project.org/package=future.tests), [GitHub](https://github.com/HenrikBengtsson/future.tests)
* **progressr** package: [GitHub](https://github.com/HenrikBengtsson/progressr)

[future]: https://cran.r-project.org/package=future
[future.apply]: https://cran.r-project.org/package=future.apply
[future.batchtools]: https://cran.r-project.org/package=future.batchtools
[future.callr]: https://cran.r-project.org/package=future.callr
[future.tests]: https://cran.r-project.org/package=future.tests
[globals]: https://cran.r-project.org/package=globals
[batchtools]: https://cran.r-project.org/package=batchtools
[doFuture]: https://cran.r-project.org/package=doFuture
[progressr]: https://github.com/HenrikBengtsson/progressr
[foreach]: https://cran.r-project.org/package=foreach
[furrr]: https://cran.r-project.org/package=furrr
[purrr]: https://cran.r-project.org/package=purrr
[plyr]: https://cran.r-project.org/package=plyr

[GitHub]: https://github.com/HenrikBengtsson/future
[Twitter]: https://twitter.com/henrikbengtsson
