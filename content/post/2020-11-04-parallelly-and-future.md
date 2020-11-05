---
title: "parallelly, future - Cleaning Up Around the House"
date: 2020-11-04 18:00:00 -0800
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
 - hpc
 - compute-clusters
 - asynchronous
---


<blockquote cite="https://www.merriam-webster.com/dictionary/parallelly" style="font-size: 150%">
<strong>parallelly</strong> adverb<br>
par·​al·​lel·​ly | \  ˈpa-rə-le(l)li \ <br> 
Definition: in a parallel manner
</blockquote>

<blockquote cite="https://www.merriam-webster.com/dictionary/future" style="font-size: 150%">
<strong>future</strong> noun<br>
fu·​ture | \ ˈfyü-chər \ <br> 
Definition: existing or occurring at a later time
</blockquote>


I've cleaned up around the house - with the recent release of **[future]** 1.20.1, the package gained a dependency on the new **[parallelly]** package.  Now, if you're like me and concerned about bloating package dependencies, I'm sure you immediately wondered why I chose to introduce a new dependency.  I'll try to explain this below, but let me be start by clarifying a few things:

* The functions in the **parallelly** package used to be part of the **future** package

* The functions have been removed from the **future** making that package smaller while its total installation "weight" remains about the same when adding the **parallelly**

* The **future** package re-exports these functions, i.e. for the time being, everything works as before


Specifically, I’ve moved the following functions from the **future** package to the **parallelly** package:

* `as.cluster()` - Coerce an object to a 'cluster' object
* `c(...)` - Combine multiple 'cluster' objects into a single, large cluster
* `autoStopCluster()` - Automatically stop a 'cluster' when garbage collected
* `availableCores()` - Get number of available cores on the current machine; a better, safer alternative to `parallel::detectCores()`
* `availableWorkers()` - Get set of available workers
* `makeClusterPSOCK()` - Create a PSOCK cluster of R workers for parallel processing; a more powerful alternative to `parallel::makePSOCKcluster()`
* `makeClusterMPI()` - Create a message passing interface (MPI) cluster of R workers for parallel processing; a tweaked version of `parallel::makeMPIcluster()`
* `supportsMulticore()` - Check if forked processing ("multicore") is supported


Because these are re-exported as-is, you can still use them as if they were part of the **future** package.  For example, you may now use `availableCores()` as

```r
ncores <- parallelly::availableCores()
```

or keep using it as

```r
ncores <- future::availableCores()
```



One reason for moving these functions to a separate package is to make them readily available also outside of the future framework.  For instance, using `parallelly::availableCores()` for decided on the number of parallel workers is a _much_ better and safer alternative than using `parallel::detectCores()` - see `help("availableCores", package = "parallelly")` for why.  Making these functions available in a lightweight package will attract additional users and developers that are not using futures.  More users means more real-world validation, more vetting, and more feedback, which will improve these functions further and indirectly also the future framework.

Another reason is that several of the functions in **parallelly** are bug fixes and improvements to functions in the **parallel** package.  By extracting these functions from the **future** package and putting them in a standalone package, it should be more clear what these improvements are.  At the same time, it should lower the threshold of getting these improvements into the **parallel** package, where I hope they will end up one day.  _The **parallelly** package comes with an open invitation to the R Core to incorporate **parallelly**'s implementation or ideas into **parallel**._

For users of the future framework, maybe the most important reason for this migration is _speedier implementation of improvements and feature requests for the **future** package and the future ecosystem_.  Over the years, many discussions around enhancing **future** came down to enhancing the functions that are now part of the **parallelly** package, especially for adding new features to `makeClusterPSOCK()`, which is the internal work horse for setting up 'multisession' parallel workers but also used explicitly by many when setting up other types of 'cluster' workers.
The roles and responsibility of the **parallelly** and **future** packages are well separated, which should make it straightforward to further improve on these functions.  For example, if we want to introduce a new argument to `makeClusterPSOCK()`, or change one of its defaults (e.g. use the faster `useXDR = FALSE`), we can now discuss and test them quicker and often without having to bring in futures into the discussion.  Don't worry - **parallelly** will undergo the same, [strict validation process as the **future** package](/2020/11/04/trust-the-future/) does to avoid introducing breaking changes to the future framework.  For example, reverse-dependency checks will be run on first (e.g. **future**), and second (e.g. **future.apply**, **furrr**, **doFuture**, **drake**, **mlr3**, **plumber**, **promises**,and  **Seurat**) generation dependencies.


Happy parallelly futuring!


<small>
<sup>*</sup> I'll try to make another post in a couple of days covering the new features that comes with **future** 1.20.1. Stay tuned.
</small>


## Links

* **future** package: [CRAN](https://cran.r-project.org/package=future), [GitHub](https://github.com/HenrikBengtsson/future)
* **parallelly** package: [CRAN](https://cran.r-project.org/package=parallelly), [GitHub](https://github.com/HenrikBengtsson/parallelly)


[future]: https://cran.r-project.org/package=future
[parallelly]: https://cran.r-project.org/package=parallelly
[Merriam-Webster]: https://www.merriam-webster.com/dictionary/parallelly

[Twitter]: https://twitter.com/henrikbengtsson
