---
title: "parallelly 1.32.0: makeClusterPSOCK() Didn't Work with Chinese and Korean Locales"
date: 2022-06-08 14:00:00 -0700
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
 - locale
 - i18n
---

<div style="padding: 2ex; float: right;"/>
 <center>
   <img src="/post/parallelly-logo.png" alt="The 'parallelly' hexlogo"/>
 </center>
</div>


**[parallelly]** 1.32.0 is on CRAN.  This release fixes an important bug that affected users running with the Simplified Chinese, Traditional Chinese (Taiwan), or Korean locale. The bug caused `makeClusterPSOCK()`, and therefore also `future::plan("multisession")`, to fail with an error.  For other updates, please see [NEWS].

The **parallelly** package enhances the **parallel** package - our built-in R package for parallel processing - by improving on existing features and by adding new ones.  Somewhat simplified, **parallelly** provides the things that you would otherwise expect to find in the **parallel** package.  The **[future]** package relies on the **parallelly** package internally for local and remote parallelization.


## Important bug fix for Chinese and Korean users

It turns out that [`makeClusterPSOCK()`] has never<sup>[1]</sup> worked for users that have their computers set to use a Korean (`LANGUAGE=ko`), a Simplified Chinese (`LANGUAGE=zh_CN`), or a Traditional Chinese (Taiwan) (`LANGUAGE=zh_TW`) locale.  For example,

```r
Sys.setLanguage("zh_CN")
library(parallelly)
cl <- parallelly::makeClusterPSOCK(2)
#> 错误: ‘node$session_info$process$pid == pid’ is not TRUE
#> 此外: Warning message:
#> In add_cluster_session_info(cl[ii]) : 强制改变过程中产生了NA
```

The workaround was to pass `validate = FALSE`, e.g.

```r
cl <- parallelly::makeClusterPSOCK(2, validate = FALSE)
```

This bug was because of an internal assertion that made incorrect assumptions about what `print()` for `SOCK0node` and `SOCKnode` object would output. It worked with most locales, but not with the above three.  I have fixed this in the most recent release of **parallelly**.

Since the 'multisession' strategy of the **[future]** framework relies on `makeClusterPSOCK()`, this bug affected also the **future** package, e.g.

```r
Sys.setLanguage("ko")
library(future)
plan(multisession)
#> 에러: 'node$session_info$process$pid == pid' is not TRUE
#> 추가정보: 경고메시지(들): 
#> add_cluster_session_info(cl[ii])에서: 강제형변환에 의해 생성된 NA 입니다
```

So, if you run into these errors, upgrade to the latest version of **parallelly**, e.g. `update.packages()`, restart R, and it will work as you would expect.


<!--
Source: https://chinesefor.us/lessons/say-sorry-chinese-apologize-duibuqi/ and https://www.wikihow.com/Apologize-in-Korean
-->

To prevent this from happening again, I am now making sure to always check the package with also these locales, in addition to English.  CRAN already checks packages [with different English and German locales](https://cran.r-project.org/web/checks/check_flavors.html).

I am sorry, 对不起, 미안해요, about this.  Hopefully, it'll work smoother from now on.

Happy parallelization!


## Links

* **parallelly** package: [CRAN](https://cran.r-project.org/package=parallelly), [GitHub](https://github.com/HenrikBengtsson/parallelly), [pkgdown](https://parallelly.futureverse.org)
* **future** package: [CRAN](https://cran.r-project.org/package=future), [GitHub](https://github.com/HenrikBengtsson/future), [pkgdown](https://future.futureverse.org)


<sup>[1]</sup> The last time it worked was with **future** 1.4.0 (2017-03-13), when this function was still part of the **future** package.


[Cgroups]: https://www.wikipedia.org/wiki/Cgroups
[Rocker]: https://www.rocker-project.org/
[RStudio Cloud]: https://rstudio.cloud/
[future]: https://future.futureverse.org
[parallelly]: https://parallelly.futureverse.org
[`availableCores()`]: https://parallelly.futureverse.org/reference/availableCores.html
[`availableWorkers()`]: https://parallelly.futureverse.org/reference/availableWorkers.html
[`makeClusterPSOCK()`]: https://parallelly.futureverse.org/reference/makeClusterPSOCK.html
[NEWS]: https://parallelly.futureverse.org/news/index.html
