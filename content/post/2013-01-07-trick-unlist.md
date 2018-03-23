---
title: "Speed Trick: unlist(..., use.names=FALSE) is Heaps Faster!"
slug: "trick-unlist"
aliases: [2013/01/speed-trick-unlist-usenamesfalse-is.html]
date: 2013-01-07
categories: ["R"]
tags: ["R", "names", "performance", "unlist"]
---

Sometimes a minor change to your R code can make a big difference in processing time. Here is an example showing that if you're don't care about the names attribute when `unlist()`:ing a list, specifying argument `use.names = FALSE` can speed up the processing lots!

```r
> x <- split(sample(1000, size = 1e6, rep = TRUE), rep(1:1e5, times = 10))
> t1 <- system.time(y1 <- unlist(x))
> t2 <- system.time(y2 <- unlist(x, use.names = FALSE))
> stopifnot(identical(y2, unname(y1)))
> t1/t2
user  system elapsed
 103     NaN     104
 ```
 
That's more than a 100 times speedup.

So, check your code to see to which `unlist()` statements you can add an `use.names = FALSE`.

