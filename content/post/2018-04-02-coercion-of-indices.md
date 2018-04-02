---
title: "Performance: Avoid Coercing Indices To Doubles"
slug: "coercion-of-indices"
date: 2018-04-02
categories:
 - R
tags:
 - R
 - matrixStats
 - microbenchmark
 - performance
 - memory
 - garbage collection
 - coercion
---

!["1 or 1L?"](/post/1or1L.png)

`x[idxs + 1]` or `x[idxs + 1L]`?  That is the question.


Assume that we have a vector $x$ of $n = 100,000$ random values, e.g.

```r
> n <- 100000
> x <- rnorm(n)
```

and that we wish to calculate the $n-1$ first-order differences $y=(y_1, y_2, ..., y\_{n-1})$ where $y_i=x\_{i+1} - x_i$.  In R, we can calculate this using the following vectorized form:

```r
> idxs <- seq_len(n - 1)
> y <- x[idxs + 1] - x[idxs]
```

We can certainly do better if we turn to native code, but is there a more efficient way to implement this using plain R code?  It turns out there is (\*).  The following **calculation is ~15-20% faster**:
```r
> y <- x[idxs + 1L] - x[idxs]
```

The reason for this is because the index calculation:

```r
idxs + 1
```

is **inefficient due to a coercion of integers to doubles**.  We have that `idxs` is an integer vector but `idxs + 1` becomes a double vector because `1` is a double:

```r
> typeof(idxs)
[1] "integer"
> typeof(idxs + 1)
[1] "double"
> typeof(1)
[1] "double"
```

Note also that doubles (aka "numerics" in R) take up **twice the amount of memory**:

```r
> object.size(idxs)
400040 bytes
> object.size(idxs + 1)
800032 bytes
```
which is because integers are stored as 4 bytes and doubles as 8 bytes.

By using `1L` instead, we can avoid this coercion from integers to doubles:

```r
> typeof(idxs)
[1] "integer"
> typeof(idxs + 1L)
[1] "integer"
> typeof(1L)
[1] "integer"
```

and we save some, otherwise wasted, memory;

```r
> object.size(idxs + 1L)
400040 bytes
```

**Does it really matter for the overall performance?**  It should because **less memory is allocated** which always comes with some overhead.  Possibly more importantly, by using objects that are smaller in memory, the more likely it is that elements can be found in the memory cache rather than in the RAM itself, i.e. the **chance for _cache hits_ increases**.  Accessing data in the cache is orders of magnitute faster than in RAM.  Furthermore, we also **avoid coercion/casting** of doubles to integers when R adds one to each element, which may add some extra CPU overhead.

The performance gain is confirmed by running **[microbenchmark]** on the two alternatives:

```r
> microbenchmark::microbenchmark(
+   y <- x[idxs + 1 ] - x[idxs],
+   y <- x[idxs + 1L] - x[idxs]
+ )
Unit: milliseconds
                        expr  min   lq mean median   uq  max neval cld
  y <- x[idxs + 1] - x[idxs] 1.27 1.58 3.71   2.27 2.62 80.6   100   a
 y <- x[idxs + 1L] - x[idxs] 1.04 1.25 2.38   1.34 2.20 76.5   100   a
```

From the median (which is the most informative here), we see that using `idxs + 1L` is ~15-20% faster than `idxs + 1` in this case (it depends on $n$ and the overall calculation performed).

**Is it worth it?** Although it is "only" an absolute difference of ~1 ms, it adds up if we do these calculations a large number times, e.g. in a bootstrap algorithm.  And if there are many places in the code that result in coercions from index calculations like these, that also adds up.  Some may argue it's not worth it, but at least now you know it does indeed improve the performance a bit if you specify index constants as integers, i.e. by appending an `L`.


To wrap it up, here is look at the cost of subsetting all of the $1,000,000$ elements in a vector using various types of integer and double index vectors:

```r
> n <- 1000000
> x <- rnorm(n)
> idxs <- seq_len(n)          ## integer indices
> idxs_dbl <- as.double(idxs) ## double indices

> microbenchmark::microbenchmark(unit = "ms",
+   x[],
+   x[idxs],
+   x[idxs + 0L],
+   x[idxs_dbl],
+   x[idxs_dbl + 0],
+   x[idxs_dbl + 0L],
+   x[idxs + 0]
+ )
Unit: milliseconds
             expr    min     lq   mean median     uq    max neval  cld
              x[] 0.7056 0.7481 1.6563 0.7632 0.8351 74.682   100 a   
          x[idxs] 3.9647 4.0638 5.1735 4.2020 4.7311 78.038   100  b  
     x[idxs + 0L] 5.7553 5.8724 6.2694 6.0810 6.6447  7.845   100  bc 
      x[idxs_dbl] 6.6355 6.7799 7.9916 7.1305 7.6349 77.696   100   cd
  x[idxs_dbl + 0] 7.7081 7.9441 8.6044 8.3321 8.9432 12.171   100    d
 x[idxs_dbl + 0L] 8.0770 8.3050 8.8973 8.7669 9.1682 12.578   100    d
      x[idxs + 0] 7.9980 8.2586 8.8544 8.8924 9.2197 12.345   100    d
```
(I ordered the entries by their 'median' processing times.)

In all cases, we are extracting the complete vector of `x`.  We see that

  1. subsetting using an integer vector is faster than using a double vector,
  2. `x[idxs + 0L]` is faster than `x[idxs + 0]` (as seen previously),
  3. `x[idxs + 0L]` is still faster than `x[idxs_dbl]` despite also involving an addition, and
  4. `x[]` is whoppingly fast (probably because it does not have to iterate over an index vector) and serves as a lower-bound reference for the best we can hope for.


(\*): There already exists a highly efficient implementation for calculating the first-order differences, namely `y <- diff(x)`.  But for the sake of the take-home message of this blog post, let's ignore that.


**Bonus**: Did you know that `sd(y) / sqrt(2)` is an estimator of the standard deviation of the above `x`:s (von Neumann et al., 1941)?  It's actually not too hard to derive this - give it a try by deriving the variance when `x` is independent, identically distributed Gaussian random variables.  This property is useful in cases where we are interested in the noise level of `x` and `x` has a piecewise constant mean level which changes at a small number of locations, e.g. a DNA copy-number profile of a tumor.  In such cases we cannot use `sd(x)`, because the estimate would be biased due to the different mean levels.  Instead, by taking the first-order differences `y`, changes in mean levels of `x` become sporadic outliers in `y`.  If we could trim off these outliers, `sd(y) / sqrt(2)` would be a good estimate of the standard deviation of `x` after subtracting the mean levels.  Even better, by using a robust estimator, such as the median absolute deviation (MAD) - `mad(y) / sqrt(2)` - we do not have to worry about have to identify the outliers.  Efficient implementations of `sd(diff(x)) / sqrt(2))` and `mad(diff(x)) / sqrt(2))` are `sdDiff(x)` and `madDiff(x)` of the **[matrixStats]** package.


# References

J. von Neumann et al., The mean square successive difference. _Annals of Mathematical Statistics_, 1941, 12, 153-162.



# Session information

<details>
```r
> sessionInfo()
R version 3.4.4 (2018-03-15)
Platform: x86_64-pc-linux-gnu (64-bit)
Running under: Ubuntu 16.04.4 LTS

Matrix products: default
BLAS: /usr/lib/atlas-base/atlas/libblas.so.3.0
LAPACK: /usr/lib/atlas-base/atlas/liblapack.so.3.0

locale:
 [1] LC_CTYPE=en_US.UTF-8       LC_NUMERIC=C              
 [3] LC_TIME=en_US.UTF-8        LC_COLLATE=en_US.UTF-8    
 [5] LC_MONETARY=en_US.UTF-8    LC_MESSAGES=en_US.UTF-8   
 [7] LC_PAPER=en_US.UTF-8       LC_NAME=C                 
 [9] LC_ADDRESS=C               LC_TELEPHONE=C            
[11] LC_MEASUREMENT=en_US.UTF-8 LC_IDENTIFICATION=C       

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base     

loaded via a namespace (and not attached):
[1] compiler_3.4.4
```
</details>

[matrixStats]: https://cran.r-project.org/package=matrixStats
[microbenchmark]: https://cran.r-project.org/package=microbenchmark
