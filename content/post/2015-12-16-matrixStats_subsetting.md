---
title: "matrixStats: Optimized Subsetted Matrix Calculations"
slug: "matrixstats-subsetting"
aliases: [/2015/12/matrixstats-subsetted-calculations.html]
date: 2015-12-16
categories:
 - R
tags:
 - R
 - performance
 - memory
 - matrix
 - matrixStats
 - garbage collection
 - GSoC
---


The [matrixStats] package provides highly optimized functions for computing [common summaries](https://cran.r-project.org/web/packages/matrixStats/vignettes/matrixStats-methods.html) over rows and columns of matrices.  In a [previous blog post](/2015/01/matrixStats-0.13.1.html), I showed that, instead of using `apply(X, MARGIN = 2, FUN = median)`, we can speed up  calculations dramatically by using `colMedians(X)`.  In the most recent release (version 0.50.0), matrixStats has been extended to perform **optimized calculations also on a subset of rows and/or columns** specified via new arguments `rows` and `cols`, e.g. `colMedians(X, cols = 1:50)`.

![Draster leaving team behind](/post/DragsterLeavingTeamBehind.gif)

For instance, assume we wish to find the median value of the first 50 columns of matrix `X` with 1,000,000 rows and 100 columns.  For simplicity, assume
```r
> X <- matrix(rnorm(1e6 * 100), nrow = 1e6, ncol = 100)
```
To get the median values without matrixStats, we would do
```r
> y <- apply(X[, 1:50], MARGIN = 2, FUN = median)
> str(y)
 num [1:50] -0.001059 0.00059 0.001316 0.00103 0.000814 ...
```
As in the past, we could use matrixStats to do
```r
> y <- colMedians(X[, 1:50])
```
which is [much faster](/2015/01/matrixStats-0.13.1.html) than `apply()` with `median()`.

However, both approaches require that `X` is subsetted before the actual calculations can be performed, i.e. the temporary object `X[, 1:50]` is created.  In this example, the size of the original matrix is ~760 MiB and the subsetted one is ~380 MiB;
```r
> object.size(X)
800000200 bytes
> object.size(X[, 1:50])
400000100 bytes
```
This temporary object is created by (i) R first allocating the size for it and then (ii) copying all its values over from `X`.  After the medians have been calculated this temporary object is automatically discarded and eventually (iii) R's garbage collector will deallocate its memory.  This introduces overhead in form of extra memory usage as well as processing time.

Starting with matrixStats 0.50.0, we can avoid this overhead by instead using
```r
> y <- colMedians(X, cols = 1:50)
```
**This uses less memory**, because no internal copy of `X[, 1:50]` has to be created.  Instead all calculations are performed directly on the source object `X`.  Because of this, the latter approach of subsetting is **also faster**.


## Bootstrapping example
Subsetted calculations occur naturally in bootstrap analysis.  Assume we want to calculate the median for each column of a 100-by-10,000 matrix `X` where **the rows are resampled with replacement** 1,000 times.  Without matrixStats, this can be done as
```r
B <- 1000
Y <- matrix(NA_real_, nrow = B, ncol = ncol(X))
for (b in seq_len(B)) {
  rows <- sample(seq_len(nrow(X)), replace = TRUE)
  Y[b,] <- apply(X[rows, ], MARGIN = 2, FUN = median)
}
```
However, powered with the new matrixStats we can do
```r
B <- 1000
Y <- matrix(NA_real_, nrow = B, ncol = ncol(X))
for (b in seq_len(B)) {
  rows <- sample(seq_len(nrow(X)), replace = TRUE)
  Y[b, ] <- colMedians(X, rows = rows)
}
```
In the first approach, with explicit subsetting (`X[rows, ]`), we are creating a large number of temporary objects - each of size `object.size(X[rows, ]) == object.size(X)` - that all need to be allocated, copied and deallocated.  Thus, if `X` is a 100-by-10,000 double matrix of size 8,000,200 bytes = 7.6 MiB we are allocating and deallocating a total of 7.5 GiB worth of RAM when using 1,000 bootstrap samples.  With a million bootstrap samples, we're consuming a total of 7.3 TiB RAM.  In other words, we are wasting lots of compute resources on memory allocation, copying, deallocation and garbage collection.
Instead, by using the optimized subsetted calculations available in matrixStats (>= 0.50.0), which is used in the second approach, we spare the computer all that overhead.

Not only does the peak memory requirement go down by roughly a half, but **the overall speedup is also substantial**; using a regular notebook the above 1,000 bootstrap samples took 660 seconds (= 11 minutes) to complete using `apply(X[rows, ])`, 85 seconds (8x speedup) using `colMedians(X[rows, ])` and 45 seconds (**15x speedup**) using `colMedians(X, rows = rows)`.


## Availability

The matrixStats package can be installed on all common operating systems as
```r
> install.packages("matrixStats")
```
The source code is available on [GitHub](https://github.com/HenrikBengtsson/matrixStats/).


## Credits
Support for optimized calculations on subsets was implemented by [Dongcan Jiang](https://www.linkedin.com/in/dongcanjiang).   Dongcan is a Master's student in Computer Science at Peking University and worked on [this project](https://github.com/rstats-gsoc/gsoc2015/wiki/matrixStats) from April to August 2015 through support by the [Google Summer of Code](https://developers.google.com/open-source/gsoc/) 2015 program.  This GSoC project was mentored jointly by me and Hector Corrada Bravo at University of Maryland.  We would like to thank Dongcan again for this valuable addition to the package and the community.  We would also like to thank Google and the [R Project in GSoC](https://github.com/rstats-gsoc/) for making this possible.

Any type of feedback, including [bug reports](https://github.com/HenrikBengtsson/matrixStats/issues/), is always appreciated!


## Links
* CRAN package: http://cran.r-project.org/package=matrixStats
* Source code and bug reports: https://github.com/HenrikBengtsson/matrixStats
* Google Summer of Code (GSoC): https://developers.google.com/open-source/gsoc/
* R Project in GSoC (R-GSoC): https://github.com/rstats-gsoc
* matrixStats in R-GSoC 2015: https://github.com/rstats-gsoc/gsoc2015/wiki/matrixStats

[matrixStats]: http://cran.r-project.org/package=matrixStats

