---
title: "matrixStats: Consistent Support for Name Attributes via GSoC Project"
slug: "matrixstats-gsoc-2021"
date: 2021-08-23 00:10:00 +0200
categories:
 - R
tags:
 - R
 - package
 - matrixStats
 - project
 - GSoC
 - performance
 - memory
 - matrix
 - name attributes
---

_Author: Angelina Panagopoulou, GSoC student developer, undergraduate in the Department of Informatics & Telecommunications (DIT), University of Athens, Greece_

<center>
<img src="/post/2048px-GSoC_logo.svg.png" alt="Google Summer of Code logo" style="width: 40%"/>
<!-- Image source: https://commons.wikimedia.org/wiki/File:GSoC_logo.svg -->
</center>

We are glad to announce recent CRAN releases of **[matrixStats]** with support for handling and returning name attributes.  This feature is added to make **matrixStats** functions handle names in the same manner as the corresponding base R functions. In particular, the behavior of **matrixStats** functions is now the same as `apply` function in R, resolving previous lack of, or inconsistent, handling of row and column names. The added support for `names` and `dimnames` attributes has already reached a wide, active user base, while at the same time we expect to attract users and developers who lack this feature and therefore could not use **matrixStats** package for their needs.

The **matrixStats** package provides high-performing functions operating on rows and columns of matrices. These functions are optimized such that both memory use and processing time are minimized. In order to minimize the overhead of handling name attributes, the naming support is implemented in native \(C\) code, where possible. In **matrixStats** (>= 0.60.0), handling of row and column names is optional.  This is done to allow for maximum performance where needed.  In addition, in order to avoid breaking some scripts and packages that rely on the previous semi-inconsistent behavior of functions, special care has been taken to ensure backward compatibility by default for the time being. We have validated the correctness of these newly implemented features by extending existing package tests to check name attributes, measuring the code coverage with the **[covr]** package, and checking all 358 reverse-dependency packages using the **[revdepcheck]** package.


## Example

`useNames` is an argument added to each of the **matrixStats** functions that gained support naming. It takes values `TRUE`, `FALSE`, or `NA`. For backward compatible reasons, the default value of `useNames` is `NA`, meaning the default behavior from earlier versions of **matrixStats** is preserved. If `TRUE`, `names` or `dimnames` attribute of result is set, otherwise, if `FALSE`, the results do not have name attributes set. For example, consider the following 5-by-3 matrix with row and column names:

```r
> x <- matrix(rnorm(5 * 3), nrow = 5, ncol = 3, dimnames = list(letters[1:5], LETTERS[1:3]))
> x
            A          B          C
a  0.30292612  1.3825644 -0.2125219
b  0.15812229  2.7719647  1.6237263
c -0.09881700 -0.6468119 -0.6481911
d  0.38520941 -0.8466505 -0.4779964
e -0.01599926 -0.8907434  0.6334347
```

If we use the base R method to calculate row medians, we see that the names attribute of the results reflects the row names of the input matrix:

```r
> library(stats)
> apply(x, MARGIN = 1, FUN = median)
          a           b           c           d           e 
 0.30292612  1.62372626 -0.64681187 -0.47799635 -0.01599926 
```

If we use **matrixStats** function `rowMedians` with argument `useNames = TRUE` set, we get the same result as above:

```r
> library(matrixStats)
> rowMedians(x, useNames = TRUE)
          a           b           c           d           e 
 0.30292612  1.62372626 -0.64681187 -0.47799635 -0.01599926
```

If the name attributes are not of interest, we can use `useNames = FALSE` as in:

```r
> rowMedians(x, useNames = FALSE)
[1]  0.30292612  1.62372626 -0.64681187 -0.47799635 -0.01599926
```

Doing so will also avoid the overhead, time and memory, that otherwise comes from processing name attributes.

If we don't specify `useNames` explicitly, the default is currently `useNames = NA`, which corresponds to the non-documented behavior that existed in **matrixStats** (< 0.60.0).  For several functions, that corresponded to setting `useNames = FALSE`, however for other functions it corresponds to setting `useNames = TRUE`, and for others it might have set, say, row names but not column names.  In our example, the default happens to be the same as `useNames = FALSE`:

```r
> rowMedians(x) # default as in matrixStats (< 0.60.0)
[1]  0.30292612  1.62372626 -0.64681187 -0.47799635 -0.01599926
```


## Future Plan

The future plan is to change the default value of `useNames` to `TRUE` or `FALSE` and eventually deprecate the backward-compatible behavior of `useNames = NA`. The default value of `useNames` is a design choice that requires further investigation. On the one hand, `useNames = TRUE` as the default is more convenient, but creates an additional performance and memory overhead when name attributes are not needed. On the other hand, make `FALSE` the default is appropriate for users and packages that rely on the maximum performance.  Whatever the new default will become, we will make sure to work with package maintainers to minimize the risk for breaking existing code.


## Google Summer of Code 2021

The project that introduces the consistent support for name attributes on the **matrixStats** package is a part of the [R Project's participation in the Google Summer of Code 2021](https://github.com/rstats-gsoc/gsoc2021/wiki).


### Links

* [The matrixStats GSoC 2021 project](https://github.com/rstats-gsoc/gsoc2021/wiki/matrixStats)
* [matrixStats CRAN page](https://cran.r-project.org/web/packages/matrixStats/index.html)
* [matrixStats GitHub page](https://github.com/HenrikBengtsson/matrixStats)
* [All commits during GSoC 2021 - author Angelina Panagopoulou](https://github.com/HenrikBengtsson/matrixStats/commits?author=AngelPn)

### Authors

* [Angelina Panagopoulou](https://github.com/AngelPn) - _Student Developer_: I am an undergraduate in the
  Department of Informatics & Telecommunications (DIT) in University of Athens.
* [Jakob Peder Pettersen](https://github.com/yaccos) - _Mentor_: PhD Student, Department of Biotechnology and Food Science, Norwegian University of Science and Technology (NTNU). Jakob is a part of the [Almaas Lab](https://almaaslab.nt.ntnu.no/) and does research on genome-scale metabolic modeling and behavior of microbial communities.
* [Henrik Bengtsson](https://github.com/HenrikBengtsson/) - _Co-Mentor_: Associate Professor, Department of Epidemiology and Biostatistics, University of California San Francisco (UCSF). He is the author and maintainer of a large number of CRAN and Bioconductor packages including the **matrixStats**.

### Contributions

**Phase I**

* All functions implements `useNames = NA/FALSE/TRUE` using R code and tests are written.
* Identify reverse dependency packages that rely on `useNames = NA/FALSE/TRUE`.
* New release on CRAN with `useNames = NA`. This allow useRs and package maintainers to complain if anything breaks.

**Phase II**

* Changed C code structure such that `validateIndices()` always return `R_xlen_t*`. Clean up unnecessary macros.
   - Outcome: shorter compile times, smaller compiled package/library, fewer exported symbols.
* Simplify C API for `setNames()/setDimnames()`.
* Implemented `useNames = NA/FALSE/TRUE` in C code where possible and cleanup work too.


### Summary

We have completed all goals that we had initially planned. The release 0.60.0 of **matrixStats** on CRAN included the contributions of GSoC Phase I ("implementation in R") and a new release of version 0.60.1 includes the contributions of Phase II ("implementation in C").


### Experience

When I first heard about the Google Summer of Code, I really wanted to participate in it, but I thought that maybe I do not have the prerequisite knowledge yet. And it was true. It was difficult for me to find a project that I had at least half of the mentioned prerequisites. So, I started looking for a project based on what I would be interested in doing during the summer. This project was an opportunity for me to learn a new programming language, the R, and also to get in touch with advanced R. I am grateful for all the learning opportunities: programming in R, developing an R package, using a variety of tools that make developing R packages easier and more productive, working with GitHub tools, interacting with the open source community. My mentors had an understanding of the lack of experience and really helped me achieve this. Participating in Google Summer of Code 2021 as student developer is definitely worth it and I recommend every student who wants to open source contribute to give it a try.


## Acknowledgements

* The Google Summer of Code program for bringing more student developers into open source software development.
* Jacob Pettersen for being a great project leader and for providing guidance and willingness to impart his knowledge. Henrik Bengtsson whose insight and knowledge into the subject matter steered me through R package development. I am very grateful for the immense amount of useful discussions and valuable feedback.
* The members of the R community for building this warming community.

[matrixStats]: https://cran.r-project.org/package=matrixStats
[covr]: https://cran.r-project.org/package=covr
[revdepcheck]: https://github.com/r-lib/revdepcheck
