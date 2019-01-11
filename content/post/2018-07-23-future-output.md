---
title: "future 1.9.0 - Output from The Future"
slug: "output-from-the-future"
date: 2018-07-23
categories:
 - R
tags:
 - R
 - package
 - future
 - output
 - standard output
 - stdout
 - asynchronous
 - parallel processing
 - compute clusters
 - HPC

---


**[future]** 1.9.0 - _Unified Parallel and Distributed Processing in R for Everyone_ - is on CRAN.  This is a milestone release:

**Standard output is now relayed from futures back to the master R session -
regardless of where the futures are processed!**


_Disclaimer:_ A future's output is relayed only after it is resolved and when its value is retrieved by the master R process.  In other words, the output is not streamed back in a "live" fashion as it is produced.  Also, it is only the standard output that is relayed.  See below, for why the standard error cannot be relayed.


![Illustration of communication by mechanical semaphore in 1800s France. Lines of towers supporting semaphore masts were built within visual distance of each other. The arms of the semaphore were moved to different positions, to spell out text messages. The operators in the next tower would read the message and pass it on. Invented by Claude Chappee in 1792, semaphore was a popular communication technology in the early 19th century until the telegraph replaced it. (source: wikipedia.org)](/post/Signaling_by_Napoleonic_semaphore_line.jpg)
_Relaying standard output from far away_


## Examples

Assume we have access to three machines with R installed on our local network.  We can distribute our R processing to these machines using futures by:

```r
> library(future)
> plan(cluster, workers = c("n1", "n2", "n3"))
> nbrOfWorkers()
[1] 3
```

With the above, future expressions will now be processed across those three machines.  To see which machine a future ends up being resolved by, we can output the hostname, e.g.

```r
> printf <- function(...) cat(sprintf(...))

> f <- future({
+   printf("Hostname: %s\n", Sys.info()[["nodename"]])
+   42
+ })
> v <- value(f)
Hostname: n1
> v
[1] 42
```
We see that this particular future was resolved on the _n1_ machine.  Note how _the output is relayed when we call `value()`_.  This means that if we call `value()` multiple times, the output will also be relayed multiple times, e.g.
```r
> v <- value(f)
Hostname: n1
> value(f)
Hostname: n1
[1] 42
```

This is intended and by design.  In case you are new to futures, note that _a future is only evaluated once_.  In other words, calling `value()` multiple times will not re-evaluate the future expression.

The output is also relayed when using future assignments (`%<-%`).  For example,
```r
> v %<-% {
+   printf("Hostname: %s\n", Sys.info()[["nodename"]])
+   42
+ }
> v
Hostname: n1
[1] 42
> v
[1] 42
```
In this case, the output is only relayed the first time we print `v`.  The reason for this is because when first set up, `v` is a promise (delayed assignment), and as soon as we "touch" (here print) it, it will internally call `value()` on the underlying future and then be resolved to a regular variable `v`.  This is also intended and by design.

In the spirit of the Future API, any _output behaves exactly the same way regardless of future backend used_.  In the above, we see that output can be relayed from three external machines back to our local R session.  We would get the exact same if we run our futures in parallel, or sequentially, on our local machine, e.g.

```r
> plan(sequential)
 v %<-% {
   printf("Hostname: %s\n", Sys.info()[["nodename"]])
   42
 }
> v
Hostname: my-laptop
[1] 42
```

This also works when we use nested futures wherever the workers are located (local or remote), e.g.
```r
> plan(list(sequential, multiprocess))
> a %<-% {
+   printf("PID: %d\n", Sys.getpid())
+   b %<-% {
+     printf("PID: %d\n", Sys.getpid())
+     42
+   }
+   b	
+ }
> a
PID: 360547
PID: 484252
[1] 42
```


## Higher-Level Future Frontends

The core Future API, that is, the explicit `future()`-`value()` functions and the implicit future-assignment operator `%<-%` function, provides the foundation for all of the future ecosystem.  Because of this, _relaying of output will work out of the box wherever futures are used_.  For example, when using **future.apply** we get:

```
> library(future.apply)
> plan(cluster, workers = c("n1", "n2", "n3"))
> printf <- function(...) cat(sprintf(...))

> y <- future_lapply(1:5, FUN = function(x) {
+   printf("Hostname: %s (x = %g)\n", Sys.info()[["nodename"]], x)
+   sqrt(x)
+ })
Hostname: n1 (x = 1)
Hostname: n1 (x = 2)
Hostname: n2 (x = 3)
Hostname: n3 (x = 4)
Hostname: n3 (x = 5)
> unlist(y)
[1] 1.000000 1.414214 1.732051 2.000000 2.236068
```

and similarly when, for example, using **foreach**:

```r
> library(doFuture)
> registerDoFuture()
> plan(cluster, workers = c("n1", "n2", "n3"))
> printf <- function(...) cat(sprintf(...))

> y <- foreach(x = 1:5) %dopar% {
+   printf("Hostname: %s (x = %g)\n", Sys.info()[["nodename"]], x)
+   sqrt(x)
+ }
Hostname: n1 (x = 1)
Hostname: n1 (x = 2)
Hostname: n2 (x = 3)
Hostname: n3 (x = 4)
Hostname: n3 (x = 5)
> unlist(y)
[1] 1.000000 1.414214 1.732051 2.000000 2.236068
```


## What about standard error?

Unfortunately, it is _not possible_ to relay output sent to the standard error (stderr), that is, output by `message()`, `cat(..., file = stderr())`, and so on, is not taken care of.  This is due to a [limitation in R](https://github.com/HenrikBengtsson/Wishlist-for-R/issues/55), preventing us from capturing stderr in a reliable way.  The gist of the problem is that, contrary to stdout ("output"), there can only be a single stderr ("message") sink active in R at any time.  What really is the show stopper is that if we allocate such a message sink, it will be stolen from us the moment other code/functions request the message sink.  In other words, message sinks cannot be used reliably in R unless one fully controls the whole software stack.  As long as this is the case, it is not possible to collect and relay stderr in a consistent fashion across _all_ future backends (*).  But, of course, I'll keep on trying to find a solution to this problem.  If anyone has a suggestion for a workaround or a patch to R, please let me know.

(*) The **[callr]** package captures stdout and stderr in a consistent manner, so for the **[future.callr]** backend, we could indeed already now relay stderr.  We could probably also find a solution for **[future.batchtools]** backends, which targets HPC job schedulers by utilizing the **[batchtools]** package.  However, if code becomes dependent on using specific future backends, it will limit the end users' options - we want to avoid that as far as ever possible.  Having said this, it is possible that we'll start out supporting stderr by making it an [optional feature of the Future API](https://github.com/HenrikBengtsson/future/issues/172).


## Poor Man's debugging

Because the output is also relayed when there is an error, e.g.

```r
> x <- "42"
> f <- future({
+   str(list(x = x))
+   log(x)
+ })
> value(f)
List of 1
 $ x: chr "42"
Error in log(x) : non-numeric argument to mathematical function
```

it can be used for simple troubleshooting and narrowing down errors.  For example,

```r
> library(doFuture)
> registerDoFuture()
> plan(multiprocess)
> nbrOfWorkers()
[1] 2
> x <- list(1, "2", 3, 4, 5)
> y <- foreach(x = x) %dopar% {
+   str(list(x = x))
+   log(x)
+ }
List of 1
 $ x: num 1
List of 1
 $ x: chr "2"
List of 1
 $ x: num 3
List of 1
 $ x: num 4
List of 1
 $ x: num 5
Error in { : 
  task 2 failed - "non-numeric argument to mathematical function"
> 
```

From the error message, we get that there was an "non-numeric argument" (element) passed to a function.  By adding the `str()`, we can also see that it is of type character and what its value is.  This will help us go back to the data source (`x`) and continue the troubleshooting there.


## What's next?

Progress bar information is one of several frequently [requested features](https://github.com/HenrikBengtsson/future/labels/feature%20request) in the future framework.  I hope to attack the problem of progress bars and progress messages in higher-level future frontends such as **[future.apply]**.  Ideally, this can be done in a uniform and generic fashion to meet all needs.  A possible implementation that has been discussed, is to provide a set of basic hook functions (e.g. on-start, on-resolved, on-value) that any ProgressBar API (e.g. **[jobstatus]**) can build upon.  This could help avoid tie-in to a particular progress-bar implementation.

Another feature I'd like to get going is (optional) [benchmarking of processing time and memory consumption](https://github.com/HenrikBengtsson/future/issues/59).  This type of information will help optimize parallel and distributed processing by identifying and understand the various sources of overhead involved in parallelizing a particular piece of code in a particular compute environment.  This information will also help any efforts trying to automate load balancing.  It may even be used for progress bars that try to estimate the remaining processing time ("ETA").

So, lots of work ahead.  Oh well ...


_Happy futuring!_



## See also

* About [Semaphore Telegraphs](https://www.wikipedia.org/wiki/Semaphore_line), Wikipedia

* [future.apply - Parallelize Any Base R Apply Function](/2018/06/23/future.apply_1.0.0/), 2018-06-23
* [Delayed Future(Slides from eRum 2018)](/2018/06/18/future-erum2018-slides/), 2018-06-19
* [future 1.8.0: Preparing for a Shiny Future](/2018/04/12/future-results/), 2018-04-12
* [The Many-Faced Future](/2017/06/05/many-faced-future/), 2017-06-05
* [future 1.3.0 Reproducible RNGs, future&#95;lapply() and More](/2017/02/19/future-rng/), 2017-02-19
* [High-Performance Compute in R Using Futures](/2016/10/22/future-hpc/), 2016-10-22
* [Remote Processing Using Futures](/2016/10/11/future-remotes/), 2016-10-11


## Links

* future - _Unified Parallel and Distributed Processing in R for Everyone_
  - CRAN page: https://cran.r-project.org/package=future
  - GitHub page: https://github.com/HenrikBengtsson/future
* future.apply - _Apply Function to Elements in Parallel using Futures_
  - CRAN page: https://cran.r-project.org/package=future.apply
  - GitHub page: https://github.com/HenrikBengtsson/future.apply
* doFuture - _A Universal Foreach Parallel Adaptor using the Future API of the 'future' Package_
  - CRAN page: https://cran.r-project.org/package=doFuture
  - GitHub page: https://github.com/HenrikBengtsson/doFuture
* future.batchtools - _A Future API for Parallel and Distributed Processing using 'batchtools'_
  - CRAN page: https://cran.r-project.org/package=future.batchtools
  - GitHub page: https://github.com/HenrikBengtsson/future.batchtools
* future.callr - _A Future API for Parallel Processing using 'callr'_
  - CRAN page: https://cran.r-project.org/package=future.callr
  - GitHub page: https://github.com/HenrikBengtsson/future.callr


[future]: https://cran.r-project.org/package=future
[future.apply]: https://cran.r-project.org/package=future.apply
[future.batchtools]: https://cran.r-project.org/package=future.batchtools
[batchtools]: https://cran.r-project.org/package=batchtools
[callr]: https://cran.r-project.org/package=callr
[future.callr]: https://cran.r-project.org/package=future.callr
[jobstatus]: https://github.com/ropenscilabs/jobstatus
