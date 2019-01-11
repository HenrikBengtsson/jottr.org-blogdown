---
title: "Maintenance Updates of Future Backends and doFuture"
date: 2019-01-07
categories:
 - R
tags:
 - R
 - package
 - future
 - future.batchtools
 - future.BatchJobs
 - future.callr
 - doFuture
 - future.apply
 - asynchronous
 - parallel processing
 - compute clusters
 - HPC

---

New versions of the following future backends are available on CRAN:

* **[future.callr]** - parallelization via **[callr]**, i.e. on the local machine
* **[future.batchtools]** - parallelization via **[batchtools]**, i.e. on a compute cluster with job schedulers (SLURM, SGE, Torque/PBS, etc.) but also on the local machine
* **[future.BatchJobs]** - (maintained for legacy reasons) parallelization via **[BatchJobs]**, which is the predecessor of batchtools

These releases fix a few small bugs and inconsistencies that were identified with help of the **[future.tests]** framework that is being developed with [support from the R Consortium](https://www.r-consortium.org/projects/awarded-projects).


I also released a new version of:

* **[doFuture]** - use _any_ future backend for `foreach()` parallelization

which comes with a few improvements and bug fixes.


![An old TV screen struggling to display the text "THE FUTURE IS NOW"](/post/the-future-is-now.gif)
_The future is now._


## The future is ... what?

If you never heard of the future framework before, here is a simple example.  Assume that you want to run
```r
y <- lapply(X, FUN = my_slow_function)
```
in parallel on your local computer.  The most straightforward way to achieve this is to use:
```r
library(future.apply)
plan(multiprocess)
y <- future_lapply(X, FUN = my_slow_function)
```
If you have SSH access to a few machines here and there with R installed, you can use:
```r
library(future.apply)
plan(cluster, workers = c("localhost", "gandalf.remote.edu", "server.cloud.org"))
y <- future_lapply(X, FUN = my_slow_function)
```
Even better, if you have access to compute cluster with an SGE job scheduler, you could use:
```r
library(future.apply)
plan(future.batchtools::batchtools_sge)
y <- future_lapply(X, FUN = my_slow_function)
```


## The future is ... why?

The **[future]** package provides a simple, cross-platform, and lightweight API for parallel processing in R.  At its core, there are three core building blocks for doing parallel processing - `future()`, `resolved()` and `value()`- which are used for creating the asynchronous evaluation of an R expression, querying whether it's done or not, and collecting the results.  With these fundamental building blocks, a large variety of parallel tasks can be performed, either by using these functions directly or indirectly via more feature rich higher-level parallelization APIs such as **[future.apply]**, **[foreach]**, **[BiocParallel]** or **[plyr]** with **[doFuture]**, and **[furrr]**.  In all cases, how and where future R expressions are evaluated, that is, how and where the parallelization is performed, depends solely on which _future backend_ is currently used, which is controlled by the `plan()` function.

One advantage of the Future API, whether it is used directly as is or via one of the higher-level APIs, is that it encapsulates the details on _how_ and _where_ the code is parallelized allowing the developer to instead focus on _what_ to parallelize.  Another advantage is that the end user will have control over which future backend to use.  For instance, one user may choose to run an analysis in parallel on their notebook or in the cloud, whereas another may want to run it via a job scheduler in a high-performance compute (HPC) environment.


## What’s next?

I've spent a fair bit of time working on **[future.tests]**, which is a single framework for testing future backends.  It will allow developers of future backends to validate that they fully conform to the Future API.  This will lower the barrier for creating a new backend (e.g. [future.clustermq] on top of **[clustermq]** or [one on top Redis](https://github.com/HenrikBengtsson/future/issues/151)) and it will add trust for existing ones such that end users can reliably switch between backends without having to worry about the results being different or even corrupted.
So, backed by **[future.tests]**, I feel more comfortable attacking some of the feature requests - and there are [quite a few of them](https://github.com/HenrikBengtsson/future/issues?q=is%3Aissue+is%3Aopen+label%3A%22feature+request%22).  Indeed, I've already implemented one of them.  More news coming soon ...


_Happy futuring!_


## See also

* [future 1.9.0 - Output from The Future](/2018/07/23/output-from-the-future/), 2018-07-23
* [future.apply - Parallelize Any Base R Apply Function](/2018/06/23/future.apply_1.0.0/), 2018-06-23
* [Delayed Future(Slides from eRum 2018)](/2018/06/18/future-erum2018-slides/), 2018-06-19
* [future 1.8.0: Preparing for a Shiny Future](/2018/04/12/future-results/), 2018-04-12
* [The Many-Faced Future](/2017/06/05/many-faced-future/), 2017-06-05
* [future 1.3.0 Reproducible RNGs, future&#95;lapply() and More](/2017/02/19/future-rng/), 2017-02-19
* [High-Performance Compute in R Using Futures](/2016/10/22/future-hpc/), 2016-10-22
* [Remote Processing Using Futures](/2016/10/11/future-remotes/), 2016-10-11
* [A Future for R: Slides from useR 2016](http://127.0.0.1:4321/2016/07/02/future-user2016-slides/), 2016-07-02



[future]: https://cran.r-project.org/package=future

[future.batchtools]: https://cran.r-project.org/package=future.batchtools
[batchtools]: https://cran.r-project.org/package=batchtools
[future.BatchJobs]: https://cran.r-project.org/package=future.BatchJobs
[BatchJobs]: https://cran.r-project.org/package=BatchJobs
[future.callr]: https://cran.r-project.org/package=future.callr
[callr]: https://cran.r-project.org/package=callr

[future.apply]: https://cran.r-project.org/package=future.apply
[furrr]: https://cran.r-project.org/package=furrr
[doFuture]: https://cran.r-project.org/package=doFuture
[foreach]: https://cran.r-project.org/package=foreach
[BiocParallel]: https://bioconductor.org/packages/release/bioc/html/BiocParallel.html
[plyr]: https://cran.r-project.org/package=plyr

[future.tests]: https://github.com/HenrikBengtsson/future.tests
[future.clustermq]: https://github.com/HenrikBengtsson/future/issues/204
[clustermq]: https://cran.r-project.org/package=clustermq
