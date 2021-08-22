---
title: "parallelly 1.25.0: availableCores(omit=n) and, finally, built-in SSH support for MS Windows 10 users"
slug: parallelly-1.25.0
date: 2021-04-30 15:00:00 -0700
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
 - remote-parallel-processing
 - SSH
 - MS Windows
---

<center>
<img src="/post/nasa-climate-ice-core-small.jpg" alt="A 25-cm long ice core is held in front of the camera on a sunny day. The background is an endless snow-covered flat landscape and a bright blue sky." style="width: 65%;"/><br/>
<small><em>A piece of an ice core - more pleasing to look at than yet another illustration of a CPU core<br/>
<small>(Image credit: Ludovic Brucker, NASA's Goddard Space Flight Center)</small>
</em></small>
</center>

**[parallelly]** 1.25.0 is on CRAN.  It comes with two major improvements:

* You can now use `availableCores(omit = n)` to ask for all but `n` CPU cores

* `makeClusterPSOCK()` can finally use the built-in SSH client on MS Windows 10 to set up remote workers


# availableCores(omit = n) is your new friend

When running R code in parallel, many choose to parallelize on as many CPU cores as possible, e.g.

```r
ncores <- parallel::detectCores()
```

It's also common to leave out a few cores so that we can still use the computer for other basic tasks, e.g. checking email, editing files, and browsing the web.  This is often done by something like:

```r
ncores <- parallel::detectCores() - 1
```

which will return seven on a machine with eight CPU cores.  If you look around, you also find that some leave two cores aside for other tasks;

```r
ncores <- parallel::detectCores() - 2
```

I'm sorry to be the party killer, but _none of the above is guaranteed to work everywhere_.  It might work on your computer but not on your collaborator's computer, or in the cloud, or on continuous integration (CI) services, etc.  There are two problems with the above approaches.  The help page of `parallel::detectCores()` describes the first problem:

> **Value**  
> An integer, `NA` if the answer is unknown.

Yup, `detectCores()` might return `NA`. Ouf!

The second problem is that your code might run on a machine that has only one or two CPU cores.  That means that `parallel::detectCores() - 1` may return zero, and `parallel::detectCores() - 2` may even return a negative one.  You might think such machines no longer exists, but they do.  The most common cases these days are virtual machines (VMs) running in the cloud.  Note, if you're a package developer, GitHub Actions, Travis CI, and AppVeyor CI are all running in VMs with two cores.

So, to make sure your code will run everywhere, you need to do something like:

```r
ncores <- max(parallel::detectCores() - 1, 1, na.rm = TRUE)
```

With that approach, we know that `ncores` is at least one and never a missing value.  I don't know about you, but I often do thinkos where I mix up `min()` and `max()`, which I'm sure we don't want. So, let me introduce you to your new friend:

```r
ncores <- parallelly::availableCores(omit = 1)
```

Just use that and you'll be fine everywhere - it'll always give you a value of one or greater.  It's neater and less error prone.  Also, in contrast to `parallel::detectCores()`, `parallelly::availableCores()` respects various CPU settings and configurations that the system wants your to follow.



# makeClusterPSOCK() to remote machines works out-of-the-box also MS Windows 10

If you're into parallelizing across multiple machines, either on your local network, or remotely, say in the cloud, you can use:

```r
workers <- parallelly::makeClusterPSOCK(c("n1.example.org", "n2.example.org"))
```

to spawn two R workers running in the background on those two machines.  We can use these workers with different R parallel backends, e.g. with bare-bone **parallel**

```r
y <- parallel::parLapply(workers, X, slow_fcn)
```

with **foreach** and the classical **doParallel** adapter,

```r
library(foreach)
doParallel::registerDoParallel(workers)
y <- foreach(x = X) %dopar% slow_fcn(x)
```

and, obviously, my favorite, the **future** framework, which comes with lots of alternatives, e.g.

```r
library(future)
plan(cluster, workers = workers)

y <- future.apply::future_lapply(X, slow_fcn)

y <- furrr::future_map(X, slow_fcn)

library(foreach)
doFuture::registerDoFuture()
y <- foreach(x = X) %dopar% slow_fcn(x)

y <- BiocParallel::bplapply(X, slow_fcn)
```



Now, in order to set up remote workers out of the box as shown above, you need to make sure you can do the following from the terminal:

```r
{local}$ ssh n1.example.org Rscript --version
R scripting front-end version 4.0.4 (2021-02-15)
```

If you can get to that point, you can also use those two remote machines to parallel from your local computer, which, at least I think, is pretty cool.  To get to that point, you basically need to configure SSH locally and remotely so that you can log in without having to enter a password, which you do by using SSH keys.  It does _not_ require admin rights, and it's not that hard to do when you know how to do it. Search the web for "SSH key authentication" for instructions, but the gist is that you create a public-private key pair locally and you copy the public one to the remote machine.  The setup is the same for Linux, macOS, and MS Windows 10.


What's new in **parallelly** 1.25.0 is that _MS Windows 10 users no longer have to install the PuTTY SSH client_ - the Unix-compatible `ssh` client that comes with all MS Windows 10 installations works out of the box.

The reason why we couldn't use the built-in Windows 10 client before is that it has an [bug preventing us from using it for reverse tunneling](https://github.com/PowerShell/Win32-OpenSSH/issues/1265), which is needed for remote, parallel processing.  However, someone found a workaround, so that bug is no longer a blocker. for this bug, so thinow everything works as we want it to.


## Take-homes

* Use `parallelly::availableCores()`

* Remote parallelization from MS Windows 10 is now as easy as from Linux and macOS

For all updates, including what bugs have been fixed, see the [NEWS](https://parallelly.futureverse.org/news/index.html) of **parallelly**.

Over and out!


## Links

* **parallelly** package: [CRAN](https://cran.r-project.org/package=parallelly), [GitHub](https://github.com/HenrikBengtsson/parallelly), [pkgdown](https://parallelly.futureverse.org)

* **future** package: [CRAN](https://cran.r-project.org/package=future), [GitHub](https://github.com/HenrikBengtsson/future), [pkgdown](https://future.futureverse.org)

* **future.apply** package: [CRAN](https://cran.r-project.org/package=future.apply), [GitHub](https://github.com/HenrikBengtsson/future.apply), [pkgdown](https://future.apply.futureverse.org)

* **furrr** package: [CRAN](https://cran.r-project.org/package=furrr), [GitHub](https://github.com/HenrikBengtsson/furrr), [pkgdown](https://furrr.futureverse.org)


PS. If you're interested in learning more about ice cores and how they are used to track changes in our atmosphere and climate, see [Core questions: An introduction to ice cores](https://climate.nasa.gov/news/2616/core-questions-an-introduction-to-ice-cores/) by Jessica Stoller-Conrad, NASA's Jet Propulsion Laboratory.



[parallelly]: https://cran.r-project.org/package=parallelly
