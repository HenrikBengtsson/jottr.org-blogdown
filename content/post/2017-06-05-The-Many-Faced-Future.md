---
title: "The Many-Faced Future"
slug: "many-faced-future"
aliases: [/2017/06/the-many-faced-future.html]
date: 2017-06-05
categories:
- R
tags:
- R
- package
- future
- doFuture
- foreach
- plyr
- purr
- lapply
- parallel
- HPC
- asynchronous
- compute clusters
- cloud
---


The [future] package defines the Future API, which is a unified, generic, friendly API for parallel processing.  The Future API follows the principle of **write code once and run anywhere** - the developer chooses what to parallelize and the user how and where.

The nature of a future is such that it lends itself to be used with several of the existing map-reduce frameworks already available in R.  In this post, I'll give an example of how to apply a function over a set of elements concurrently using plain sequential R, the parallel package, the [future] package alone, as well as future in combination of the [foreach], the [plyr], and the [purrr] packages.

![Julia Set animation](/post/julia_sets.gif)
_You can choose your own future and what you want to do with it._


## Example: Multiple Julia sets


The [Julia] package provides the `JuliaImage()` function for generating a [Julia set] for a given set of start parameters `(centre, L, C)` where `centre` specify the center point in the complex plane, `L` specify the width and height of the square region around this location, and `C` is a complex coefficient controlling the "shape" of the generated Julia set.  For example, to generate one of the above Julia set images (1000-by-1000 pixels), you can use:

```r
library("Julia")
set <- JuliaImage(1000, centre = 0 + 0i, L = 3.5, C = -0.4 + 0.6i)
plot_julia(set)
```
with
```r
plot_julia <- function(img, col = topo.colors(16)) {
  par(mar = c(0, 0, 0, 0))
  image(img, col = col, axes = FALSE)
}
```
  
For the purpose of illustrating how to calculate different Julia sets in parallel, I will use the same `(centre, L) = (0 + 0i, 3.5)` region as above with the following ten complex coeffients (from [Julia set]):
```r
Cs <- c(
  a = -0.618,
  b = -0.4     + 0.6i,
  c =  0.285   + 0i,
  d =  0.285   + 0.01i,
  e =  0.45    + 0.1428i,
  f = -0.70176 - 0.3842i,
  g =  0.835   - 0.2321i,
  h = -0.8     + 0.156i,
  i = -0.7269  + 0.1889i,
  j =          - 0.8i
)
```

Now we're ready to see how we can use futures in combination of different map-reduce implementations in R for generating these ten sets in parallel.  Note that all approaches will generate the exact same ten Julia sets.  So, feel free to pick your favorite approach.


## Sequential

To process the above ten regions sequentially, we can use the `lapply()` function:
```r
library("Julia")
sets <- lapply(Cs, function(C) {
  JuliaImage(1000, centre = 0 + 0i, L = 3.5, C = C)
})
```

## Parallel
```r
library("parallel")
ncores <- future::availableCores() ## a friendly version of detectCores()
cl <- makeCluster(ncores)

clusterEvalQ(cl, library("Julia"))
sets <- parLapply(cl, Cs, function(C) {
  JuliaImage(1000, centre = 0 + 0i, L = 3.5, C = C)
})
```

## Futures (in parallel)
```r
library("future")
plan(multisession)  ## defaults to availableCores() workers

library("Julia")
sets <- future_lapply(Cs, function(C) {
  JuliaImage(1000, centre = 0 + 0i, L = 3.5, C = C)
})
```

We could also have used the more explicit setup `plan(cluster, workers = makeCluster(availableCores()))`, which is identical to `plan(multisession)`.


## Futures with foreach
```r
library("doFuture")
registerDoFuture()  ## tells foreach futures should be used
plan(multisession)  ## specifies what type of futures

sets <- foreach(C = Cs) %dopar% {
  JuliaImage(1000, centre = 0 + 0i, L = 3.5, C = C)
}
```

Note that I didn't pass `.packages = "Julia"` to `foreach()` because the doFuture backend will do that automatically for us - that's one of the treats of using futures.  If we would have used `doParallel::registerDoParallel(cl)` or similar, we would have had to worry about that.


## Futures with plyr

The plyr package will utilize foreach internally if we pass `.parallel = TRUE`.  Because of this, we can use `plyr::llply()` to parallelize via futures as follows:
```r
library("plyr")
library("doFuture")
registerDoFuture()  ## tells foreach futures should be used
plan(multisession)  ## specifies what type of futures

library("Julia")
sets <- llply(Cs, function(C) {
  JuliaImage(1000, centre = 0 + 0i, L = 3.5, C = C)
}, .parallel = TRUE)
```

For the same reason as above, we also here don't have to worry about global variables and making sure needed packages are attached; that's all handles by the future packages.


## Futures with purrr (= furrr)

As a final example, here is how you can use futures to parallelize your `purrr::map()` calls:
```r
library("purrr")
library("future")
plan(multisession)

library("Julia")
sets <- Cs %>%
        map(~ future(JuliaImage(1000, centre = 0 + 0i, L = 3.5, C = .x))) %>%
        values
```



# Got compute?

If you have access to one or more machines with R installed (e.g. a local or remote cluster, or a [Google Compute Engine cluster]), and you've got direct SSH access to those machines, you can have those machines to calculate the above Julia sets; just change future plan, e.g.
```r
plan(cluster, workers = c("machine1", "machine2", "machine3.remote.org"))
```

If you have access to a high-performance compute (HPC) cluster with a HPC scheduler (e.g. Slurm, TORQUE / PBS, LSF, and SGE), then you can harness its power by switching to:
```r
library("future.batchtools")
plan(batchtools_sge)
```
For more details, see the vignettes of the [future.batchtools] and [batchtools] packages.


Happy futuring!


## Links
* future package:
  - CRAN page: https://cran.r-project.org/package=future
  - GitHub page: https://github.com/HenrikBengtsson/future
* future.batchtools package:
  - CRAN page: https://cran.r-project.org/package=future.batchtools
  - GitHub page: https://github.com/HenrikBengtsson/future.batchtools
* doFuture package (an [foreach] adaptor):
  - CRAN page: https://cran.r-project.org/package=doFuture
  - GitHub page: https://github.com/HenrikBengtsson/doFuture

## See also
* [A Future for R: Slides from useR 2016](/2016/07/a-future-for-r-slides-from-user-2016.html), 2016-07-02
* [Remote Processing Using Futures](/2016/10/remote-processing-using-futures.html), 2016-10-21
* [future: Reproducible RNGs, future_lapply() and more](/2017/02/future-reproducible-rngs-futurelapply.html), 2017-02-19
* [doFuture: A universal foreach adaptor ready to be used by 1,000+ packages](/2017/03/dofuture-universal-foreach-adapator.html), 2017-03-18

[future]: https://cran.r-project.org/package=future
[purrr]: https://cran.r-project.org/package=purrr
[plyr]: https://cran.r-project.org/package=plyr
[Julia]: https://cran.r-project.org/package=Julia
[Julia Set]: https://en.wikipedia.org/wiki/Julia_set
[foreach]: https://cran.r-project.org/package=foreach
[future.BatchJobs]: https://cran.r-project.org/package=future.BatchJobs
[future.batchtools]: https://cran.r-project.org/package=future.batchtools
[globals]: https://cran.r-project.org/package=globals
[BatchJobs]: https://cran.r-project.org/package=BatchJobs
[batchtools]: https://cran.r-project.org/package=batchtools
[googleComputeEngineR]: https://cran.r-project.org/package=googleComputeEngineR
[Google Compute Engine cluster]: https://cran.r-project.org/package=googleComputeEngineR
