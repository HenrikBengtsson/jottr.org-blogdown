---
title: "parallelly: Support for Fujitsu Technical Computing Suite High-Performance Compute (HPC) Environments"
date: 2022-06-09 13:00:00 -0700
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


**[parallelly]** 1.32.0 is now on CRAN. One of the major updates is that `availableCores()` and `availableWorkers()`, and therefore also the **future** framework, gained support for the 'Fujitsu Technical Computing Suite' job scheduler. For other updates, please see [NEWS].

The **parallelly** package enhances the **parallel** package - our built-in R package for parallel processing - by improving on existing features and by adding new ones.  Somewhat simplified, **parallelly** provides the things that you would otherwise expect to find in the **parallel** package.  The **[future]** package relies on the **parallelly** package internally for local and remote parallelization.



## Support for the Fujitsu Technical Computing Suite

Functions [`availableCores()`] and [`availableWorkers()`] now support the Fujitsu Technical Computing Suite.  Fujitsu Technical Computing Suite is a high-performance compute (HPC) job scheduler, which is popular in Japan among other places, e.g. at RIKEN and Kyushu University.

Specifically, these functions now recognize environment variables `PJM_VNODE_CORE`, `PJM_PROC_BY_NODE`, and `PJM_O_NODEINF` set by the Fujitsu Technical Computing Suite scheduler.  For example, if we submit a job script with:

```sh
$ pjsub -L vnode=4 -L vnode-core=10 script.sh
```

the scheduler will allocate four slots with ten cores each on one or more compute nodes.  For example, we might get:

```r
parallelly::availableCores()
#> [1] 10

parallelly::availableWorkers()
#>  [1] "node032" "node032" "node032" "node032" "node032"
#>  [6] "node032" "node032" "node032" "node032" "node032"
#> [11] "node032" "node032" "node032" "node032" "node032"
#> [16] "node032" "node032" "node032" "node032" "node032"
#> [21] "node032" "node032" "node032" "node032" "node032"
#> [26] "node032" "node032" "node032" "node032" "node032"
#> [31] "node109" "node109" "node109" "node109" "node109"
#> [36] "node109" "node109" "node109" "node109" "node109"
```

In this example, the scheduler allocated three 10-core slots on compute node `node032` and one 10-core slot on compute node `node109`, totalling 40 CPU cores, as requested.  Because of this, users on these systems can now use [`makeClusterPSOCK()`] to set up a parallel PSOCK cluster as:

```r
library(parallelly)
cl <- makeClusterPSOCK(availableWorkers(), rshcmd = "pjrsh")
```

As shown above, this code picks up whatever `vnode` and `vnode-core` configuration were requested via the `pjsub` submission, and launch 40 parallel R workers via the `pjrsh` tool part of the Fujitsu Technical Computing Suite.


This also means that we can use:

```r
library(future)
cl <- plan(cluster, rshcmd = "pjrsh")
```

when using the **future** framework, which uses `makeClusterPSOCK()` and `availableWorkers()` internally.


## Avoid having to specify rshcmd = "pjrsh"

To avoid having to manually specify argument `rshcmd = "pjrsh"` manually, we can set it via environment variable [`R_PARALLELLY_MAKENODEPSOCK_RSHCMD`] \(sic!) before launching R, e.g.

```sh
export R_PARALLELLY_MAKENODEPSOCK_RSHCMD=pjrsh
```

To make this persistent, the user can add this line to their `~/.bashrc` shell startup script.  Alternatively, the system administrator can add it to a `/etc/profile.d/*.sh` file of their choice.

With this environment variable set, it's sufficient to do:

```
library(parallelly)
cl <- makeClusterPSOCK(availableWorkers())
```

and

```r
library(future)
cl <- plan(cluster)
```


In addition to not having to remember using `rshcmd = "pjrsh"`, a major advantage of this approach is that the same R script works also on other systems, including the user's local machine and HPC environments such as Slurm and SGE.

Over and out, and welcome to all Fujitsu Technical Computing Suite users!


## Links

* **parallelly** package: [CRAN](https://cran.r-project.org/package=parallelly), [GitHub](https://github.com/HenrikBengtsson/parallelly), [pkgdown](https://parallelly.futureverse.org)
* **future** package: [CRAN](https://cran.r-project.org/package=future), [GitHub](https://github.com/HenrikBengtsson/future), [pkgdown](https://future.futureverse.org)


[Cgroups]: https://www.wikipedia.org/wiki/Cgroups
[Rocker]: https://www.rocker-project.org/
[RStudio Cloud]: https://rstudio.cloud/
[future]: https://future.futureverse.org
[parallelly]: https://parallelly.futureverse.org
[`availableCores()`]: https://parallelly.futureverse.org/reference/availableCores.html
[`availableWorkers()`]: https://parallelly.futureverse.org/reference/availableWorkers.html
[`makeClusterPSOCK()`]: https://parallelly.futureverse.org/reference/makeClusterPSOCK.html
[`R_PARALLELLY_MAKENODEPSOCK_RSHCMD`]: https://parallelly.futureverse.org/reference/parallelly.options.html
[NEWS]: https://parallelly.futureverse.org/news/index.html
