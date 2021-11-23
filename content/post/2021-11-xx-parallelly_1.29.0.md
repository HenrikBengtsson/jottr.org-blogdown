---
title: "parallelly 1.29.0: New skills and less communication latency on Linux"
slug: parallelly-1.29.0
date: 2021-11-20 15:00:00 -0800
categories:
 - R
tags:
 - R
 - package
 - future
 - parallel
 - parallelly
 - HPC
 - parallel-processing
---

<div style="padding: 2ex; float: right;"/>
 <center>
   <img src="/post/parallelly-logo.png" alt="The 'parallelly' hexlogo"/>
 </center>
</div>


**[parallelly]** 1.29.0 is on CRAN.  The **parallelly** package enhances the **parallel** package - our built-in R package for parallel processing - by improving on existing features and by adding new ones.  Somewhat simplified, **parallelly** provides the things that you would otherwise expect to find in the **parallel** package.  Also, the **parallelly** package provides the fundamental, low-level parts that the **[future]** package needs for local and remote parallelization.

Since my [previous post on **parallelly**](/2021/06/10/parallelly-1.26.0/) five months ago, the **parallelly** package had some bugs fixed, and it gained a few new features;

* new `isForkedChild()` to test if R runs in a forked process,

* new `isNodeAlive()` to test if one or more cluster-node processes are running,

* `availableCores()` now respects also Bioconductor settings,

* `makeClusterPSOCK(..., rscript = "*")` automatically expands to the proper Rscript executable,

* `makeClusterPSOCK(…, rscript_envs = c(UNSET_ME = NA_character_))` unsets environment variables on cluster nodes, and

* `makeClusterPSOCK()` sets up clusters with less communication latency on Unix.


Below is a detailed description of these new features.


## New function isForkedChild()

If you run R on Unix and macOS, you can parallelize code using so called _forked_ parallel processing.  It is a very convenient way of parallelizing code, especially since forking is implemented at the core of the operating system and there is very little extra you have to do at the R level to get it to work.  Compared with other parallelization solutions, forked processing has often less overhead, resulting in shorter turnaround times.  To date, the most famous method for parallelizing using forks is `mclapply()` of the **parallel** package.  For example,

```r
library(parallel)
y <- mclapply(X, some_slow_fcn, mc.cores = 4)
```

works just like `lapply(X, some_slow_fcn)` but will perform the same tasks in parallel using four (4) CPU cores.  MS Windows does not support [forked processing]; any attempt to use `mclapply()` there will cause it to silently fall back to a sequential `lapply()` call.

In the **future** ecosystem, you get forked parallelization with the `multicore` backend, e.g.

```r
library(future.apply)
plan(multicore, workers = 4)
y <- future_lapply(X, some_slow_fcn)
```

Unfortunately, we cannot parallelize all types of code using forks.  If done, you might get an error, but in the worst case you crash (segmentation fault) your R process.  For example, some graphical user interfaces (GUIs) do not play well with forked processing, e.g. the RStudio Console, but also other GUIs.  Multi-threaded parallelization has also been reported to cause problems when run within forked parallelization.  We sometime talk about _non-fork-safe code_, in contrast to _fork-safe_ code, to refer to code that risks crashing the software if run in forked processes.

Here is what R-core developer Simon Urbanek and author of `mclapply()` wrote in the R-devel thread ['mclapply returns NULLs on MacOS when running GAM'](https://stat.ethz.ch/pipermail/r-devel/2020-April/079384.html) on 2020-04-28:

> Do NOT use `mcparallel()` in packages except as a non-default option that user can set for the reasons ... explained [above]. Multicore is intended for HPC applications that need to use many cores for computing-heavy jobs, but it does not play well with RStudio and more importantly you don't know the resource available so only the user can tell you when it is safe to use. Multi-core machines are often shared so using all detected cores is a very bad idea. The user should be able to explicitly enable it, but it should not be enabled by default.

It is not always obvious to know whether a certain function call in R is fork safe, especially not if we haven't written all the code ourselves.  Because of this, it is more of a trial and error so see if works.  However, when we know that a certain function call is _not_ fork safe, it is useful to protect against using it in forked parallelization.  In **parallelly** (>= 1.28.0), we can use function [`isForkedChild()`] test whether or not R runs in a forked child process.  For example, the author of `some_slow_fcn()` above, could protect against mistakes by:

```r
some_slow_fcn <- function(x) {
  if (parallelly::isForkedChild()) {
    stop("This function must not be used in *forked* parallel processing")
  }
  
  y <- non_fork_safe_code(x)
  ...
}
```

or, if they have an alternative, less preferred, fork-safe implementation, they could run that conditionally on R being executed in a forked child process:

```r
some_slow_fcn <- function(x) {
  if (parallelly::isForkedChild()) {
    y <- fork_safe_code(x)
  } else {
    y <- alternative_code(x)
  }
  ...
}
```


## New function isNodeAlive()

The new function [`isNodeAlive()`] checks whether one or more nodes are alive.  For instance,

```r
library(parallelly)
cl <- makeClusterPSOCK(3)
isNodeAlive(cl)
#> [1] TRUE TRUE TRUE
```

Imagine the second parallel worker crashes, which we can emulate with

```r
clusterEvalQ(cl[2], tools::pskill(Sys.getpid()))
#> Error in unserialize(node$con) : error reading from connection
```

then we get:

```r
isNodeAlive(cl)
#> [1]  TRUE FALSE  TRUE
```

The `isNodeAlive()` function works by getting the process IDs (PIDs)
for the parallel workers and query the operating system to see if
those processes are still running.  If the workers' PIDs are unknown,
then `NA` is returned instead.  For instance, contrary to
`parallelly::makeClusterPSOCK()`, `parallel::makeCluster()` does not
record the PIDs and we get missing values as the result;

```r
library(parallelly)
cl <- parallel::makeCluster(3)
isNodeAlive(cl)
#> [1] NA NA NA
```

Similarly, if one of the parallel workers runs on a remote machine, we
cannot easily query the remote machine for the PID existing or not.
In such cases, `NA` is returned.  Maybe we will be
able to query also remote machines in a future version of
**parallelly**, but for now, it is not possible.


## availableCores() respects Bioconductor settings

Function [`availableCores()`] queries the hardware and the system
environment to find out how many CPU cores it may run on.  It does
this by checking system settings, environment variables, and R options
that may be set by the end-user, the system administrator, the parent
R process, the operating system, a job scheduler, and so on.  When you
use `availableCores()`, you don't have to worry about using more CPU
resources than you were assigned, which helps guarantee that it
runs nicely together with everything else on the same machine.

In **parallelly** (>= 1.29.0), `availableCores()` is now also agile to
Bioconductor-specific settings.  For example, **[BiocParallel]**
1.27.2 introduced environment variable `BIOCPARALLEL_WORKER_NUMBER`,
which sets the default number of parallel workers when using
**BiocParallel** for parallelization.  Similarly, on Bioconductor
check servers, they set environment variable `BBS_HOME`, which
**BiocParallel** uses to limit the number of cores to four (4).  Now
`availableCores()` reflects also those settings, which, in turn, means
that **future** settings like `plan(multisession)` will also
automatically respect the Bioconductor settings.

Function [`availableWorkers()`], which relies on `availableCores()` as a
fallback, is therefore also agile to these Bioconductor environment
variables.


<!--
## Improvements to makeClusterPSOCK() arguments 'rscript' and 'rscript_envs'


Three improvements to [`makeClusterPSOCK()`] has been made:

 * A `*` value in argument `rscript` to `makeClusterPSOCK()` expands to
   the corrent `Rscript` executable
 
 * Argument `rscript_envs` of `makeClusterPSOCK()` can be used to unset
   environment variables onthe parallel workers
 
 * On Unix, the _communication latency_ between the main R session and
   the parallel workers is not much smaller when using
   `makeClusterPSOCK()`
-->

## makeClusterPSOCK(..., rscript = "*")

Argument `rscript` of `makeClusterPSOCK()` can be used to control
exactly which `Rscript` executable is used to launch the parallel
workers, and also how that executable is launched.  The default
settings is often sufficient, but if you want to launch a worker, say,
within a Linux container you can do so by adjusting `rscript`.  The
help page for [`makeClusterPSOCK()`] has several examples of this.  It
may also be used for other setups.  For example, to launch two
parallel workers on a remote Linux machine, such that their CPU
priority is less than other processing running on that machine, we can
use (*):

```r
workers <- rep("remote.example.org", times = 2)
cl <- makeClusterPSOCK(workers, rscript = c("nice", "Rscript"))
```

This causes the two R workers to be launched using `nice Rscript ...`.
The Unix command `nice` is what makes `Rscript` to run with a lower
CPU priority.  By running at a lower priority, we decrease the risk
for our parallel tasks to have a negative impact on other software
running on that machine, e.g. someone might use that machine for
interactive work without us knowing.  We can do the same thing on our
local machine via:

```r
cl <- makeClusterPSOCK(2L,
        rscript = c("nice", file.path(R.home("bin"), "Rscript")))
```

Here we specified the absolute path to `Rscript` to make sure we run
the same version of R as the main R session, and not another
`Rscript` that may be on the system `PATH`.

Starting with **parallelly** 1.29.0, we can replace the Rscript
specification in the above two examples with `"*"`, as in:

```r
workers <- rep("remote-machine.example.org, times = 2L)
cl <- makeClusterPSOCK(workers, rscript = c("nice", "*"))
```

and

```r
cl <- makeClusterPSOCK(2L, rscript = c("nice", "*"))
```

When used, `makeClusterPSOCK()` will expand `"*"` to the proper
Rscript specification depending on running remotely or not.

Note that, when using **[future]**, we can pass `rscript` to
`plan(multisession)` and `plan(cluster)` to achieve the same thing, as
in

```r
plan(cluster, workers = workers, rscript = c("nice", "*"))
```

and

```r
plan(multisession, workers = 2L, rscript = c("nice", "*"))
```

(*) Here we use `nice` as an example, because it is a simple way to
illustrate how `rscript` can be used.  As a matter of fact, there is
already an [argument
`renice`](https://parallelly.futureverse.org/reference/makeClusterPSOCK.html),
which we can use to achieve the same without using the `rscript`
argument.


## makeClusterPSOCK(..., rscript_envs = c(UNSET_ME = NA\_character\_))

Argument `rscript_envs` of `makeClusterPSOCK()` can be used to set
environment variables on cluster nodes, or copy existing ones from the
main R session to the cluster nodes.  For example,

```r
cl <- makeClusterPSOCK(2, rscript_envs = c(PI = "3.14", "MY_EMAIL"))
```

will, during startup, set environment variable `PI` on each of the two
cluster nodes to have value `3.14`.  It will also set `MY_EMAIL` on
them to the value of `Sys.getenv("MY_EMAIL")` in the current R
session.

Starting with **parallelly** 1.29.0, we can now also _unset_
environment variables, in case they are set on the cluster nodes.  Any
named element with value `NA_character_` will be unset, e.g.

```r
cl <- makeClusterPSOCK(2, rscript_envs = c(_R_CHECK_LENGTH_1_CONDITION_ = NA_character_))
```

This results in passing `-e
'Sys.unsetenv("_R_CHECK_LENGTH_1_CONDITION_")'` to `Rscript` when
launching each worker.



## makeClusterPSOCK() sets up clusters with less communication latency on Unix

It turns out that, in R _on Unix_, there is [a significant _latency_ in
the communication between the parallel workers and the main R
session](https://stat.ethz.ch/pipermail/r-devel/2020-November/080060.html)
(**).  Starting in R (>= 4.1.0), it is possible to decrease this
latency by setting a dedicated R option _on each of the workers_, e.g.

```r
rscript_args <- c("-e", shQuote("options(socketOptions = 'no-delay')")
cl <- parallel::makeCluster(workers, rscript_args = rscript_args))
```

This is quite verbose, so I've made this the new default in
**parallelly** (>= 1.29.0), i.e. you can keep using:

```r
cl <- parallelly::makeClusterPSOCK(workers)
```

to benefit from the above.  See help for [`makeClusterPSOCK()`] for options on how to change this new default.

Here is an example that illustrates the difference in latency with and without the new settings;

```r
cl_parallel   <- parallel::makeCluster(1)
cl_parallelly <- parallelly::makeClusterPSOCK(1)

res <- bench::mark(iterations = 1000L,
    parallel = parallel::clusterEvalQ(cl_parallel, iris),
  parallelly = parallel::clusterEvalQ(cl_parallelly, iris)
)

res[, c(1:4,9)]
#> # A tibble: 2 × 5
#>   expression      min   median `itr/sec` total_time
#>   <bch:expr> <bch:tm> <bch:tm>     <dbl>   <bch:tm>
#> 1 parallel      277µs     44ms      22.5      44.4s
#> 2 parallelly    380µs    582µs    1670.     598.3ms
```

From this, we see that the total latency overhead for 1,000 parallel
tasks went from 44 seconds down to 0.60 seconds, which is ~75 times
less on average.  Does this mean your parallel code will run faster?
No, it is just the communication _latency_ that has decreased.  But,
why waste time on _waiting_ on your results when you don't have to?
This is why we changed the defaults in **parallelly**.  It will also
bring the experience on Unix on par with MS Windows and macOS.

Note that the relatively high latency affects only Unix.  MS Windows
and macOS do not suffer from this extra latency.  For example, on MS
Windows 10 that runs in a virtual machine on the same Linux computer
as above, I get:

```r
#> # A tibble: 2 × 5
#>   expression      min   median `itr/sec` total_time
#>   <bch:expr> <bch:tm> <bch:tm>     <dbl>   <bch:tm>
#> 1 parallel      191us    314us     2993.      333ms
#> 2 parallelly    164us    311us     3227.      310ms
```

If you're using **[future]** with `plan(multisession)` or
`plan(cluster)`, you're already benefitting from the performance gain,
because those rely on `parallelly::makeClusterPSOCK()` internally.


<!--
avoid a quite large latency in the communication between parallel workers and the main R session
 
```r
gg <- plot(res) + labs(x = element_blank()) + theme(text = element_text(size = 20)) + theme(legend.position = "none")
ggsave("parallelly_faster_turnarounds-figure.png", plot = gg, width = 7.0, height = 5.0)
```

<center>
<img src="/post/parallelly_faster_turnarounds-figure.png" alt="..." style="width: 65%;"/><br/>
</center>
<small><em>Figure: ...<br/></em></small>
-->


(**) _Technical details_: Options `socketOptions` sets the default
value of argument `options` of `base::socketConnection()`.  The
default is `NULL`, but if we set it to `"no-delay"`, the created TCP
socket connections are configured to use the `TCP_NODELAY` flag.  When
using `TCP_NODELAY`, a TCP connection will no longer use the so called
[Nagle's algorithm], which otherwise is used to reduces the number of
TCP packets needed to be sent over the network by making sure TCP
fills up each packet before sending it off. When using the new
`"no-delay"`, this buffering is disabled and packets are sent as soon
as data come in.  Credits for this improvement should go to Jeff
Keller, who identified and [reported the problem to
R-devel](https://stat.ethz.ch/pipermail/r-devel/2020-November/080060.html),
to Iñaki Úcar who pitched in, and to Simon Urbanek, who implemented
[support for `socketConnection(..., options =
"no-delay")`](https://github.com/wch/r-source/commit/82369f73fc297981e64cac8c9a696d05116f0797)
for R 4.1.0.


## Bug fixes

Finally, the most important bug fixes since **parallelly** 1.26.0 are:

 * `availableCores()` would produce an error on Linux systems without
   `nproc` installed.

 * `makeClusterPSOCK()` failed with "Error in freePort(port) : Unknown value
   on argument ‘port’: 'auto'" if environment variable `R_PARALLEL_PORT` was
   set to a port number.

 * In R environments not supporting `setup_strategy = "parallel"`,
   `makeClusterPSOCK()` failed to fall back to `setup_strategy = "sequential"`.

For all other bug fixes and updates, please see [NEWS].


<!--
<center>
<img src="/post/parallelly_faster_turnarounds.png" alt="..." style="width: 65%;"/><br/>
</center>
<small><em>Figure: Our parallel results are now turned around much faster on Linux than before.<br/></em></small>
-->




Over and out!


## Links

* **parallelly** package: [CRAN](https://cran.r-project.org/package=parallelly), [GitHub](https://github.com/HenrikBengtsson/parallelly), [pkgdown](https://parallelly.futureverse.org)
* **future** package: [CRAN](https://cran.r-project.org/package=future), [GitHub](https://github.com/HenrikBengtsson/future), [pkgdown](https://future.futureverse.org)
* **future.apply** package: [CRAN](https://cran.r-project.org/package=future.apply), [GitHub](https://github.com/HenrikBengtsson/future.apply), [pkgdown](https://future.apply.futureverse.org)

[BiocParallel]: https://bioconductor.org/packages/BiocParallel
[future]: https://future.futureverse.org
[parallelly]: https://parallelly.futureverse.org
[`availableCores()`]: https://parallelly.futureverse.org/reference/availableCores.html
[`availableWorkers()`]: https://parallelly.futureverse.org/reference/availableWorkers.html
[`isForkedChild()`]: https://parallelly.futureverse.org/reference/isForkedChild.html
[`isNodeAlive()`]: https://parallelly.futureverse.org/reference/isNodeAlive.html
[`makeClusterPSOCK()`]: https://parallelly.futureverse.org/reference/makeClusterPSOCK.html
[NEWS]: https://parallelly.futureverse.org/news/index.html
[Nagle's algorithm]: https://www.wikipedia.org/wiki/Nagle%27s_algorithm
[forked processing]: https://en.wikipedia.org/wiki/Fork_(system_call)

<!--
nworkers <- 4L
cl_parallel   <- parallel::makeCluster(nworkers)
cl_parallelly <- parallelly::makeClusterPSOCK(nworkers)

plan(cluster, workers = cl_parallel)
stats <- bench::mark(iterations = 100L,
    parallel = { f <- cluster(iris, workers = cl_parallel); value(f) },
  parallelly = { f <- cluster(iris, workers = cl_parallelly); value(f) }
)

plan(cluster, workers = cl_parallelly)
stats2 <- bench::mark(iterations = 10L,
  parallelly = { f <- future(iris); value(f) }
)

stats <- rbind(stats1, stats2)
-->

