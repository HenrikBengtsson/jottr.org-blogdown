---
title: "parallelly 1.34.0: Support for CGroups v2, Killing Parallel Workers, and more"
date: 2023-01-18 14:00:00 -0800
categories:
 - R
tags:
 - R
 - package
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


With the recent releases of **[parallelly]** 1.33.0 (2022-12-13) and
1.34.0 (2023-01-13), [`availableCores()`] and [`availableWorkers()`]
gained better support for Linux CGroups, options for avoiding running
out of R connections when setting up **parallel**-style clusters, and
`killNode()` for forcefully terminating one or more parallel workers.
I summarize these updates below.  For other updates, please see
the [NEWS].


## Added support for CGroups v2

[`availableCores()`] and [`availableWorkers()`] gained support for
Linux Control Groups v2 (CGroups v2), besides CGroups v1, which has
been supported since **[parallelly]** 1.31.0 (2022-04-07) and
partially since 1.22.0 (2020-12-12).  This means that if you use
`availableCores()` and `availableWorkers()` in your R code, it will
better respect the number of CPU cores that the Linux system has made
available to you.  Not all systems use CGroups, but it is becoming
more popular, so if the Linux system you run on does not use it right
now, it is likely it will at some point.


## Avoid running out of R connections

If you run parallel code on a machine with a many CPU cores, there's a
risk that you run out of available R connections, which are needed
when setting up **parallel** cluster nodes.  This is because R has a
limit of a maximum 125 connections being used at the same time(\*) and
each cluster node consumes one R connection.  If you try to set up
more parallel workers than this, you will get an error.  The
**parallelly** package already has built-in protection against this,
e.g.

```r
> cl <- parallelly::makeClusterPSOCK(192)
Error: Cannot create 192 parallel PSOCK nodes. Each node needs
one connection, but there are only 124 connections left out of
the maximum 128 available on this R installation
```

This error is _instant_ and with no parallel workers being launched.
In contrast, if you use **parallel**, you will only get an error after
R has launched the first 124 cluster nodes and fails to launch the
125:th one, e.g.

```r
> cl <- parallel::makePSOCKcluster(192)
Error in socketAccept(socket = socket, blocking = TRUE, open = "a+b",  : 
  all connections are in use
```

Now, assume you use:

```r
> library(parallelly)
> nworkers <- availableCores()
> cl <- makeClusterPSOCK(ncores)
```

to set up a maximum-sized cluster on the current machine.  This works
as long as `availableCores()` returns something less than 125.
However, if you are on machine with, say, 192 CPU cores, you will get
the above error.  You could do something like:

```r
> nworkers <- availableCores()
> nworkers <- max(nworkers, 125L)
```

to work around this problem.  Or, if you want to be more agile to what
R supports, you could do:

```r
> nworkers <- availableCores()
> nworkers <- max(nworkers, freeConnections())
```

With the latest versions of **parallelly**, you can simplify this to:

```r
> nworkers <- availableCores(constraints = "connections")
```

The `availableWorkers()` function also supports `constraints =
"connections"`.

(\*) The only way to increase this limit is to change the R source
code and build R from source, cf. [`freeConnections()`].


## Forcefully terminate PSOCK cluster nodes

The `parallel::stopCluster()` should be used for stopping a parallel
cluster.  This works by asking the clusters node to shut themselves
down.  However, a parallel worker will only shut down this way when it
receives the message, which can only happen when the worker is done
processing any parallel tasks.  So, if a worker runs a very
long-running task, which can take minutes, hours, or even days, it
will not shut down until after that completes.

This far, we had to turn to special operating-system tools to kill the
R process for that cluster worker.  With **parallelly** 1.33.0, you
can now use `killNode()` to kill any parallel worker that runs on the
local machine and that was launched by [`makeClusterPSOCK()`].  For
example,

```r
> library(parallelly)
> cl <- makeClusterPSOCK(10)
> cl
Socket cluster with 10 nodes where 10 nodes are on host 'localhost'
(R version 4.2.2 (2022-10-31), platform x86_64-pc-linux-gnu)
> which(isNodeAlive(cl))
 [1]  1  2  3  4  5  6  7  8  9 10
 
> success <- killNode(cl[1:3])
> success
[1] TRUE TRUE TRUE
> which(isNodeAlive(cl))
[1]  4  5  6  7  8  9 10
> cl <- cl[isNodeAlive(cl)]
Socket cluster with 7 nodes where 7 nodes are on host 'localhost'
(R version 4.2.2 (2022-10-31), platform x86_64-pc-linux-gnu)
```

Over and out,

Henrik


## Links

* **parallelly** package: [CRAN](https://cran.r-project.org/package=parallelly), [GitHub](https://github.com/HenrikBengtsson/parallelly), [pkgdown](https://parallelly.futureverse.org)


[Cgroups]: https://www.wikipedia.org/wiki/Cgroups
[parallelly]: https://parallelly.futureverse.org
[NEWS]: https://parallelly.futureverse.org/news/index.html
[`availableCores()`]: https://parallelly.futureverse.org/reference/availableCores.html
[`availableWorkers()`]: https://parallelly.futureverse.org/reference/availableWorkers.html
[`freeConnections()`]: https://parallelly.futureverse.org/reference/availableConnections.html
[`makeClusterPSOCK()`]: https://parallelly.futureverse.org/reference/makeClusterPSOCK.html
