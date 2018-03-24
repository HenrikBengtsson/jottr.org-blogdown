---
title: "Pitfall: Did You Really Mean to Use matrix(nrow, ncol)?"
slug: "matrixNA-wrong-way"
date: 2014-06-17
aliases: [/2014/06/matrixNA-wrong-way.html]
categories:
 - R
tags:
 - R
 - performance
 - memory
 - matrix
 - garbage collection
 - coercion
---

![Road sign reading "Wrong Way"](/post/wrong_way_035.jpg)


Are you a good R citizen and preallocates your matrices?  **If you are allocating a numeric matrix in one of the following two ways, then you are doing it the wrong way!**
```r
x <- matrix(nrow = 500, ncol = 100)
```
or
```r
x <- matrix(NA, nrow = 500, ncol = 100)
```
Why?  Because it is counter productive.  And why is that?  In the above, `x` becomes a **logical** matrix, and **not a numeric** matrix as intended.  This is because the default value of the `data` argument of `matrix()` is `NA`, which is a **logical** value, i.e.
```r
> x <- matrix(nrow = 500, ncol = 100)
> mode(x)
[1] "logical"
> str(x)
 logi [1:500, 1:100] NA NA NA NA NA NA ...
```
Why is that bad?  Because, as soon as you assign a numeric value to any of the cells in `x`, the matrix will first have to be coerced to numeric when the new value is assigned.  **The originally allocated logical matrix was allocated in vain and just adds an unnecessary memory footprint and extra work for the garbage collector**.

Instead allocate it using `NA_real_` (or `NA_integer_` for integers):
```r
x <- matrix(NA_real_, nrow = 500, ncol = 100)
```
Of course, if you wish to allocate a matrix with all zeros, use `0` instead of `NA_real_` (or `0L` for integers).

The exact same thing happens with `array()` and also because the default value is `NA`, e.g.
```r
> x <- array(dim = c(500, 100))
> mode(x)
[1] "logical"
```

Similarly, be careful when you setup vectors using `rep()`, e.g. compare
```r
x <- rep(NA, times = 500)
```
to
```r
x <- rep(NA_real_, times = 500)
```
Note, if all you want is an empty vector with all zeros, you may as well use
```r
x <- double(500)
```
for doubles and
```r
x <- integer(500)
```
for integers.


## Details
In the 'base' package there is a neat little function called `tracemem()` that can be used to trace the internal copying of objects.  We can use it to show how the two cases differ. Lets start by doing it the wrong way:
```r
> x <- matrix(nrow = 500, ncol = 100)
> tracemem(x)
[1] "<0x00000000100a0040>"
> x[1,1] <- 3.14
tracemem[0x00000000100a0040 -> 0x000007ffffba0010]:
> x[1,2] <- 2.71
>
```
That 'tracemem' output message basically tells us that `x` is copied, or more precisely that a new internal object (0x000007ffffba0010) is allocated and that `x` now refers to that instead of the original one (0x00000000100a0040).  This happens because `x` needs to be coerced from logical to numerical before assigning cell (1,1) the (numerical) value 3.14.  Note that there is no need for R to create a copy in the second assignment to `x`, because at this point it is already of a numeric type.

To avoid the above, lets make sure to allocate a numeric matrix from the start and there will be no extra copies created:
```r
> x <- matrix(NA_real_, nrow = 500, ncol = 100)
> tracemem(x)
[1] "<0x000007ffffd70010>"
> x[1,1] <- 3.14
> x[1,2] <- 2.71
>
```


## Appendix

### Session information
```r
R version 3.1.0 Patched (2014-06-11 r65921)
Platform: x86_64-w64-mingw32/x64 (64-bit)

locale:
[1] LC_COLLATE=English_United States.1252 
[2] LC_CTYPE=English_United States.1252   
[3] LC_MONETARY=English_United States.1252
[4] LC_NUMERIC=C                          
[5] LC_TIME=English_United States.1252    

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base     

other attached packages:
[1] R.utils_1.32.5    R.oo_1.18.2       R.methodsS3_1.6.2

loaded via a namespace (and not attached):
[1] R.cache_0.10.0 R.rsp_0.19.0   tools_3.1.0   
```

### Reproducibility

This report was generated from an RSP-embedded Markdown [document](https://gist.github.com/HenrikBengtsson/854d13a11a33b3d43ec3/raw/matrixNA.md.rsp) using [R.rsp](http://cran.r-project.org/package=R.rsp) v0.19.0.
<!--
It can be recompiled as `R.rsp::rfile("https://gist.github.com/HenrikBengtsson/854d13a11a33b3d43ec3/raw/matrixNA.md.rsp")`.
-->
