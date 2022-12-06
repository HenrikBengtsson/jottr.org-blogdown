---
title: "Please Avoid detectCores() in your R Packages"
slug: "avoid-detectCores"
date: 2022-12-05 17:00:00 -0800
categories:
 - R
tags:
 - R
 - package
 - parallel
 - parallelly
 - detectCores
 - availableCores
 - parallel processing
 - compute clusters
 - hpc
 
---

# Please Avoid detectCores() in your R Packages

The `detectCores()` function of the **parallel** package is probably
one of the most used functions when it comes to setting the number of
parallel workers to use in R.  In this blog post, I'll try to explain
why using it is not always a good idea.  I am already now going to
make a bold request and ask you to:

> Please do *avoid* using `parallel::detectCores()` in your package!

By reading this blog post, I hope that you become more aware of the
different problems that arise from using `detectCores()` and how they
might affect you and your users of your code.


<figure style="margin-top: 3ex;">
<img src="/post/detectCores_bad_vs_good.png" alt="TODO" style="width: 100%; margin: 0; margin-bottom: 2ex;"/>
<figcaption style="font-style: italic">
Figure&nbsp;1: Using <code>detectCores()</code> risks overloading the
machine where R runs, even more so if there are other things already
running.  The machine to the left is heavily loaded due to too many
parallel processes competing for the 24 CPU cores available, which
results in a very large amount of kernel context switching (red),
which is big waste of CPU resource.  The machine to the right is
near-perfectly loaded at 100%, where none of the processes use more
than they are allowed to use (mostly green), with very little context
switching.
</figcaption>
</figure>



## TL;DR

If you don't have time to read everything, but are willing to take my
word on `detectCores()` should be avoided, then the quick version is
that you basically have two choices for the number of parallel workers
to use by default;

1. Have your code run with a single core by default
   (i.e. sequentially), or
   
2. replace all `parallel::detectCores()` with
   [`parallelly::availableCores()`].

I'm in the conservative camp and recommend the first alternative.
Using sequential processing by default, where the user has to make an
explicit choice to run in parallel, significantly lowers the risk for
clogging up the CPUs (left panel in Figure&nbsp;1), especially when
there are other things running on the same machine.

The second alternative is useful if you're not ready to make the move
to run sequentially by default.  The `availableCores()` function of
the **[parallelly]** package is fully backward compatible with
`detectCores()`, while it avoids some of the problems with
`detectCores()`, plus it is agile to a lot more CPU-related settings,
including settings that the end-user, the systems administrator, job
schedulers and Linux containers control.  It is design to take care of
common overuse issues without you having to worry about them.


## Background

There are several problems with using `detectCores()` from the
**parallel** package for deciding how many parallel workers to use.
But before we get there, I want you to know that it is very commonly
used in the R community.  You find it in R packages, in R scripts, and
in tutorials on how to run R in parallel.

If we scan the code of the R packages on CRAN (e.g. by [searching
GitHub]<sup>1</sup>), or on Bioconductor (e.g. by [searching Bioc::CodeSearch])
we find many cases where `detectCores()` is used.  Here are some of
the variants we see in the wild:

```r
cl <- makeCluster(detectCores())
cl <- makeCluster(detectCores() - 1)
y <- mclapply(..., mc.cores = detectCores())
registerDoParallel(detectCores())
```

We also find functions that let the user choose the number of workers
via some argument, which defaults to `detectCores()`.  Sometimes the
default is explicit, as in:

```r
fast_fcn <- function(x, ncores = parallel::detectCores()) {
  if (ncores > 1) {
    cl <- makeCluster(ncores)
    ...
  }
}
```

and sometimes it's implicit, as in:

```r
fast_fcn <- function(x, ncores = NULL) {
  if (is.null(ncores)) 
    ncores <- parallel::detectCores() - 1
  if (ncores > 1) {
    cl <- makeCluster(ncores)
    ...
  }
}
```

As we will see next, all of the above examples are potentially buggy
and might results in run-time errors.


## Common mistakes when using detectCores()

### Issue 1: detectCores() may return a missing value

A small, but important details about `detectCores()` that is often
missed is the following section in `help("detectCores", package =
"parallel")`:

> **Value**
>
> An integer, **NA if the answer is unknown**.

Because of this, we cannot rely on:

```r
ncores <- detectCores()
```

to always work, i.e. we might end up with errors like:

```r
ncores <- detectCores()
workers <- parallel::makeCluster(ncores)
Error in makePSOCKcluster(names = spec, ...) : 
  numeric 'names' must be >= 1
```
  
We need to account for this, especially as package developers.  One
way to handle it is simply by using:

```r
ncores <- detectCores()
if (is.na(ncores)) ncores <- 1L
```

or, by using the following shorter, but also harder to understand,
one-liner:

```r
ncores <- max(1L, detectCores(), na.rm = TRUE)
```

This is guaranteed to always return at least one.


_Shameless advertisement for the **[parallelly]** package_: In
contrast to `detectCores()`, `parallelly::availableCores()` handles
the above case automatically, and it is guaranteed to always return at
least one core.


### Issue 2: detectCores() may return one

Although it's rare to run into hardware with single-core CPUs these
days, you might run into a virtual machine (VM) configured to have a
single core.  Because of this, you cannot reliably use:

```r
ncores <- detectCores() - 1L
```

or

```r
ncores <- detectCores() - 2L
```

in your code.  If you do, a user of your code might end up with zero
or a negative number of cores here, which also result in an error
downstream.  We need to account also for this case, which neatly can
be done tweaking the above `max()` solution, e.g.

```r
ncores <- max(1L, detectCores() - 2L, na.rm = TRUE)
```

This is also guaranteed to always return at least one.


_Shameless advertisement for the **[parallelly]** package_: In
contrast, `parallelly::availableCores()` handles this case via
argument `omit`, which makes it easier to understand the code, e.g.

```r
ncores <- availableCores(omit = 2L)
```

Also this is guaranteed to always return at least one core, i.e. if
there are one, two, or three CPU cores on this machine, `ncores` will
be one in all three cases.



## Issue 3: detectCores() does not give the number of "allowed" cores

There's a note in `help("detectCores", package = "parallel")` that
touches on the above problem, but also on other, important limitations
that we should be aware of:

> **Note**
> 
> This is not suitable for use directly for the `mc.cores` argument of
> `mclapply` nor specifying the number of cores in
> `makeCluster`. First because it may return `NA`, second because it
> does not give the number of _allowed_ cores, and third because on
> Sparc Solaris and some Windows boxes it is not reasonable to try to
> use all the logical CPUs at once.

**When is this relevant?  The answer is: Always!**  This is because as
package developers, we cannot really know when this occurs, because we
never know on what type of hardware and system our code will run on.
So, we have to account for these unknowns too.

Let's look at some real-world case where using `detectCores()` can be
a real issues.


### 3a. Using all cores assumes nothing else runs on the machine

The user might want to run other software tools at the same time while
running the R analysis.  A very common pattern we find in R code, is
to save one core for other purposes, browsing the web, e.g.

```r
ncores <- detectCores() - 1L
```

This is a good start.  It is the first step toward your software
acknowledging that there might be other things running on the same
machine.  However, contrary to the end-user deciding on the number of
cores to use, it is important to understand that we as package
developers cannot know how many cores the user needs, or wishes, to
set aside.

A related scenario is when the user wants to run two concurrent R
sessions on the same machine, both using your code.  If your code
assumes it can use all cores on the machine (i.e. `detectCores()`
cores), the user will end up running the machine at 200% of its
capacity.  Whenever we use more than 100% of the available CPU
resources, we will be penalized and waste our computational cycles on
overhead from context switching, suboptional memory access, and more.
This is where we end up with the situation illustrated in the left
part of Figure&nbsp;1.

Note also that users might known that they use an R function that runs
on all cores by default.  That is, they might not even be aware that
this is a problem in the first place.  Now, imagine if the user
decides to run three or four such R sessions, resulting in a 300-400%
CPU load.  This is when things are starting to run very slowly, the
computer will be sluggish, maybe unresponsive, and mostly likely going
to get very hot ("we're frying the computer").  By the time the four
concurrent R processes complete, the user might have been able to
finish six to eight similar processes if they would not have been
fighting each other for the limited CPU resources.

<!--
If this happens on a shared system, the user might get an email from
the systems adminstrator asking you why they are "trying to fry the
computer".  The user gets blamed for something that is our fault - it
is us that decided to run on `detectCores()` CPU cores by default.

This leads us to another scenario where a user might run into a case
where the CPUs are overwhelmed because a software tool assumes it has
exclusive right to all cores.  
-->

#### A shared computer

<div style="width: 35%; float: right;">
<figure style="margin-top: 3ex;">
<img src="/post/detectCores_bad.png" alt="TODO" style="width: 100%; margin: 0; margin-bottom: 2ex;"/>
<figcaption>
Figure 2: Overusing the CPU cores brings everything to a halt.
</figcaption>
</figure>
</div>

In the academia and the industry it is common that several users share
the same compute server och set of compute nodes.  It might be as
simple as they SSH into a shared machine with many cores and large
amounts of memory to run their analysis there.  On such setups, load
balancing between users is often based on an honor system, where each
user checks how much resources are available before launching their
analysis to make sure they don't end up using too many cores or to
much memory slowing down the computer for everyone else.

Now, imagine they run a software tool that uses all CPU cores by
default.  In that case, there is a great risk they will step on the
other users' processes, slowing everything down, especially if there
is already a big load on the machine.  From my experience in academia,
this happens frequently.  The user is often not even aware, because
they just launch it with the default settings, leave it running, with
a plan to coming back to it a few hours or a few days later.  In the
meanwhile, other users might wondering why their command-line prompts
become sluggish or even non-responsive, and their analyses all of a
sudden take forever to complete.  Eventually, the systems
administrators will be alerted and will have to drop everything else
and start troubleshooting. They might have to terminate the
wild-running processes and reach out to the user who runs the
problematic software.  This leads to a large amounts of time and
resources being wasted among users and administrators - and only
because we designed our R package to use all cores by default.  This
is not a made-up toy story; it is a very real scenario on shared
servers if you make `detectCores()` the default in your R code.


_Shameless advertisement for the **[parallelly]** package_: In
contrast to `detectCores()`, if you use `parallelly::availableCores()`
the user, or the systems adminstrator, can limit the default number of
CPU cores returned by setting environment variable
`R_PARALLELLY_AVAILABLECORES_FALLBACK`.  For instance, by setting it
to `R_PARALLELLY_AVAILABLECORES_FALLBACK=2` centrally,
`availableCores()` will, unless there are other settings that allows
the process to use more, return two cores regardless how many CPU
cores the machine has.  This will lower the damage any single process
can inflict on the system.  It will take many such processes running
at the same time in order for them to have an overall a negative
impact.  The risk for that to happen by mistake, is much lower than
when using `detectCores()` by default.


#### A shared compute cluster with many machines

Other, larger compute systems, often referred to as high-performance
compute (HPC) cluster, have a job scheduler for running scripts in
batches distributed across multiple machines.  When users submit their
scripts to the scheduler's job queue, they request how many cores and
how much memory each job requires.  For example, a user on a Slurm
cluster can request that their `run_my_rscript.sh` script gets to run
with 48 CPU cores and 256 GiB of RAM by submitting it to the scheduler
as:

```sh
sbatch --cpus-per-task=48 --mem=256G run_my_rscript.sh
```

The scheduler keeps track of all running and queued jobs, and when
enough compute slots are freed up as other jobs finishes, it will
launch the next job in the queue giving it the compute resources it
requested.  This is a very convenient and efficient way to batch
process a large amount of analyses coming from many users.

However, just like with a shared server, it is important that the
software tools running this way respect the compute resources that has
been allocated to it by the job scheduler.  The `detectCores()`
function is _not_ capable of doing this - all it does is returning the
number of CPU cores on the current machine regardless how many cores
the job has been allotted by the scheduler.  So, if your R package
uses `detectCores()` cores by default, then it will overuse the CPUs
and slow things down for everyone running on the same compute node.
Again, when this happens, it often triggers lots of wasted user and
admin efforts spent on troubleshooting and communication back and
forth.

_Shameless advertisement for the **[parallelly]** package_: In
contrast, `parallelly::availableCores()` respects the number of CPU
slots that the job scheduler has given to the job.  It recognizes
environment variables set by our most common HPC schedulers, including
Fujitsu Technical Computing Suite (PJM), Grid Engine (SGE), Load
Sharing Facility (LSF), PBS/Torque, and Simple Linux Utility for
Resource Management (Slurm).


#### Running R via CGroups on in a Linux container

This far we have been concerned about an overuse of the CPU cores
affecting other processes and other users running on the same machine.
Some systems are configured to protect against misbehaving software
from affecting other users.  In Linux, this is often done with so
called control groups ("cgroups"), where a process get allotted a
certain amount of CPU cores.  If the process uses too many parallel
workers, they will not be able to break out from the sandbox set up by
cgroups. From the outside, it will look like the process uses its
maximum amount of allocated CPU cores.  Some HPC job schedulers have
this feature enabled, but not all of them.  You find the same feature
for Linux containers, e.g. we can limit the number of CPU cores, or
throttle the CPU load, using command-line options when you launch a
Docker or an Apptainer container.

So, if you are a user on a system where compute resources are
compartmentalized this way, you run a much lower risk for wreaking
havoc on a shared system.  However, if you run too many parallel
workers, that is, try to use more cores that you have available, then
you will clog up your own analysis.  The behavior would be same as if
you request 96 parallel workers on your local eight-core notebook (the
scenario in the left panel of Figure&nbsp;1), with the exception that
you will not overhead the computer.

The problem with `detectCores()` is that it returns the number of CPU
cores on the hardware, regardless of the cgroups settings.  So, your R
process is limited to eight cores by cgroups, and you use `ncores =
detectCores()` on a 96-core machine, you will end up running 96
parallel workers fighting for the resources on eight cores.

_Shameless advertisement for the **[parallelly]** package_: In
contrast to `detectCores()`, `parallelly::availableCores()` respects
cgroups, and will return eight cores instead of 96 in the above
example.


## My opinionated recommendation

As developers, I think we should be aware of these problems, and
acknowledge they exist and are real problem "out there".  We should
also accept that we cannot predict on what type of compute environment
our R code will run on.  Unfortunately, I don't have a magic solution
that addresses all the problems reported here.  That said, I think the
best we can do is to be conservative and don't make hard-code decision
on parallelization in our R packages and R scripts.

Because of this, I argue that **the safest is to design your R package
to run sequentially by default (e.g. `ncores = 1L`), and leave it to
the user to set the number of parallel workers to use.**

The second best alternative that I can come up with, is to replace
`detectCores()` with `availableCores()` from the **parallelly**
package, e.g. `ncores = parallelly::availableCores()`.  Note that this
still uses all cores by default, but it _will_ respect common system
and R settings controlling the number of allocated CPU cores.  It is
designed to respect our most common job schedulers, e.g. Slurm, SGE,
and Torque/PBS.  It also respects R options and environment variables
commonly used to control CPU usage.  On top of this, it allows the
user or their systems administrator to control the default number of
cores, if nothing else is set.  For example, if environment variable
`R_PARALLELLY_AVAILABLECORES_FALLBACK` is set to `2`, then
`availableCores()` returns two cores by default, unless other settings
allowing more are available.  A conservative systems administrator may
want to set `export R_PARALLELLY_AVAILABLECORES_FALLBACK=1` in
`/etc/profile.d/single-core-by-default.sh`.

<sup>1</sup> The CRAN-search link, requires logging into GitHub.


[`parallelly::availableCores()`]: https://parallelly.futureverse.org/reference/availableCores.html
[parallelly]: https://parallelly.futureverse.org

[searching GitHub]: https://github.com/search?q=org%3Acran+language%3Ar+%22detectCores%28%29%22&type=code
[searching Bioc::CodeSearch]: https://code.bioconductor.org/search/search?q=detectCores%28%29)
