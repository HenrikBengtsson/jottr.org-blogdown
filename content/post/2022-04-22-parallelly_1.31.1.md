---
title: "parallelly 1.31.1: Better at Inferring Number of CPU Cores with Cgroups and Linux Containers"
slug: parallelly-1.31.1
date: 2022-04-20 21:00:00 -0700
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
 - cgroups
 - linux-containers
---

<div style="padding: 2ex; float: right;"/>
 <center>
   <img src="/post/parallelly-logo.png" alt="The 'parallelly' hexlogo"/>
 </center>
</div>


**[parallelly]** 1.31.1 is on CRAN.  The **parallelly** package enhances the **parallel** package - our built-in R package for parallel processing - by improving on existing features and by adding new ones.  Somewhat simplified, **parallelly** provides the things that you would otherwise expect to find in the **parallel** package.  The **[future]** package rely on the **parallelly** package internally for local and remote parallelization.

Since my [previous post on **parallelly**](/2021/11/22/parallelly-1.29.0/) in November 2021, I've fixed a few bugs and added some new features to the package;

 * `availableCores()` detects more cgroups settings, e.g. it now detects the number of CPUs available to your RStudio Cloud session

 * `makeClusterPSOCK()` gained argument `default_packages` to control which packages to attach at startup on the R workers
 
 * `makeClusterPSOCK()` gained `rscript_sh` to explicitly control what type of shell quotes to use on the R workers
 
 * Argument `rscript_args` of `makeClusterPSOCK()` now supports `"*"` values

Some of the additions and bug fixes were added to version 1.30.0, while others to versions 1.31.0 and 1.31.1. Below is a detailed description of these new features.


##  availableCores() detects more cgroups settings

_[Cgroups]_, short for control groups, is a low-level feature in Linux to control which and how much resources a process is allowed to use. This prevents individual processes from taking up all resources.  For example, an R process can be limited to use at most four CPU cores, even if the underlying hardware has 48 CPU cores. Imagine we parallelize with `parallel::detectCores()` background workers, e.g.

```r
library(future)
plan(multisession, workers = parallel::detectCores())
```

This will spawn 48 background R processes.  Without cgroups, these 48 parallel R workers will run across all 48 CPU cores on the machine, competing with all other software and all other users running on the same machine.  With cgroups limiting us to, say, four CPU cores, there will still be 48 parallel R workers running, but they will now run isolated on only four CPU cores, leaving the other 44 CPU cores alone.

Of course, running 48 parallel workers on four CPU cores is not very efficient. There will be a lot of wasted CPU cycles due to context switching.  The problem is that we use `parallel::detectCores()` here, which is what gives us 48 workers.  If we instead use [`availableCores()`] of **parallelly**;

```r
library(future)
plan(multisession, workers = parallelly::availableCores())
```

we get four parallel workers, which reflects the four CPU cores that cgroups gives us.  Basic support for this was introduced in **parallelly** 1.22.0 (2020-12-12), by querying `nproc`.  This required that `nproc` was installed on the system, and although it worked in many cases, it did not work for all cgroups configurations.  Specifically, it would not work when cgroups was _throttling_ the CPU usage rather than limiting the process to a specific set of CPU cores.  To illustrate this, assume we run R via Docker using [Rocker]:

```sh
$ docker run --cpuset-cpus=0-2,8 rocker/r-base
```

then cgroups will isolate the Linux container to run on CPU cores 0, 1, 2, and 8 of the host.  In this case `nproc`, e.g. `system("nproc")` from with R, returns four (4), and therefore also `parallelly::availableCores()`.  Starting with **parallelly** 1.31.0, `parallelly::availableCores()` detects this also when `nproc` is not installed on the system.
An alternative to limit the CPU resources, is to throttle the average CPU load. Using Docker, this can be done as:

```sh
$ docker run --cpus=3.5 rocker/r-base
```

In this case cgroups will throttle our R process to consume at most 350% worth of CPU on the host, where 100% corresponds to a single CPU.  In this case, `nproc` is of no use and simply give the number of CPUs on the host (e.g. 48).  Starting with **parallelly** 1.31.0, `parallelly::availableCores()` can detect that cgroups throttles R to an average load of 3.5 CPUs. Since we cannot run 3.5 parallel workers, `parallelly::availableCores()` rounds down to the nearest integer and return three (3).  The [RStudio Cloud] is one example where CPU throttling is used, so if you work in RStudio Cloud, use `parallelly::availableCores()` and you will be good.

While talking about RStudio Cloud, if you use a free account, you have only access to a single CPU core ("nCPUs = 1").  In this case, `plan(multisession, workers = parallelly::availableCores())`, or equivalently, `plan(multisession)`, will fall back to sequential processing, because there is no point in running in parallel on a single core.  If you still want to _prototype_ parallel processing in a single-core environment, say with two cores, you can set option `parallelly.availableCores.min = 2`.  This makes `availableCores()` return two (2).



## makeClusterPSOCK() gained more skills

Since **parallelly** 1.29.0, [`makeClusterPSOCK()`] has gained arguments `default_packages` and `rscript_sh`.


### New argument `default_packages`

Argument `default_packages` controls which R packages are attached on each worker during startup.  Previously, it was only possible, via logical argument `methods` to control whether or not the **methods** package should be attached - an argument that stems from `parallel::makePSOCKcluster()`.  With the new `default_packages` argument we have full control of which packages are attached.  For instance, if we want to go minimal, we can do:

```r
cl <- parallelly::makeClusterPSOCK(1, default_packages = "base")
```

This will result in one R worker with only the **base** package _attached_;

```r
> parallel::clusterEvalQ(cl, { search() })
[[1]]
[1] ".GlobalEnv"   "Autoloads"    "package:base"
```

But, note that more packages are _loaded_;

```r
> parallel::clusterEvalQ(cl, { loadedNamespaces() })
[[1]]
[1] "compiler" "parallel" "utils"    "base"    
```

Like **base**, **compiler** is a package that R always loads. The **parallel** package is loaded because it provides the code for background R workers. The **utils** package is loaded because `makeClusterPSOCK()` validates that the workers are functional by collecting extra information from the R workers that later may be useful when reporting on errors. To skip this, pass argument `validate = FALSE`.


### New argument `rscript_sh`

The new argument `rscript_sh` can be used in the rare case where one launches remote R workers on non-Unix machines from a Unix-like machine.  For example, if we from a Linux machine launch remote MS Windows workers, we need to use `rscript_sh = "cmd"`.



That covers the most important additions to **parallelly**. For bug fixes and minor updates, please see [NEWS].

Over and out!


## Links

* **parallelly** package: [CRAN](https://cran.r-project.org/package=parallelly), [GitHub](https://github.com/HenrikBengtsson/parallelly), [pkgdown](https://parallelly.futureverse.org)
* **future** package: [CRAN](https://cran.r-project.org/package=future), [GitHub](https://github.com/HenrikBengtsson/future), [pkgdown](https://future.futureverse.org)
* **future.apply** package: [CRAN](https://cran.r-project.org/package=future.apply), [GitHub](https://github.com/HenrikBengtsson/future.apply), [pkgdown](https://future.apply.futureverse.org)

[Cgroups]: https://www.wikipedia.org/wiki/Cgroups
[Rocker]: https://www.rocker-project.org/
[RStudio Cloud]: https://rstudio.cloud/
[future]: https://future.futureverse.org
[parallelly]: https://parallelly.futureverse.org
[`availableCores()`]: https://parallelly.futureverse.org/reference/availableCores.html
[`makeClusterPSOCK()`]: https://parallelly.futureverse.org/reference/makeClusterPSOCK.html
[NEWS]: https://parallelly.futureverse.org/news/index.html

