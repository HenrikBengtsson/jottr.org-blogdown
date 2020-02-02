---
title: "rstudio::conf 2020 Slides on Futures"
slug: "future-rstudioconf2020-slides"
date: 2020-02-01 19:30:00 -0800
categories:
 - R
tags:
 - R
 - package
 - future
 - progressr
 - rstudio::conf 2020
 - talk
 - presentation
 - slides
 - asynchronous
 - parallel processing
 - remote evaluation
 - compute clusters
 - hpc
 - progress updates
 
---


<div style="width: 25%; margin: 2ex; float: right;"/>
 <center>
   <img src="/post/future-logo.png" alt="The future logo"/>
   <span style="font-size: 80%; font-style: italic;">Design: <a href="https://twitter.com/embiggenData">Dan LaBar</a></span>
 </center>
</div>

I presented _Future: Simple Async, Parallel & Distributed Processing in R Why and What’s New?_ at [rstudio::conf 2020](https://rstudio.com/conference/) in San Francisco, USA, on January 29, 2020.  Below are the slides for my talk (17 slides; ~18+2 minutes):

* [HTML](https://docs.google.com/presentation/d/1Wn5S91UGIOrc4IyXoV074ij5vGF8I0Km0tCfintyIa4/present?includes_info_params=1&eisi=CM2mhIXwsecCFQyuJgodBQAJ8A#slide=id.p) (incremental Google Slides; requires online access)
* [PDF](https://www.jottr.org/presentations/rstudioconf2020/BengtssonH_20200129-future-rstudioconf2020.pdf) (flat slides)

First of all, a big thank you goes out to Dan LaBar (<a href="https://twitter.com/embiggenData">@embiggenData</a>) for proposing and contributing the original design of the future hex sticker. All credits to Dan. (You can blame me for the tweaked background.)

This was my first rstudio::conf and it was such a pleasure to be part of it.  I'd like to thank [RStudio, PBC](https://blog.rstudio.com/2020/01/29/rstudio-pbc) for the invitation to speak and everyone who contributed to the conference - organizers, staff, speakers, poster presenters, and last but not the least, all the wonderful participants.  Each one of you makes our R community what it is today.

_Happy futuring!_

\- Henrik


## Links

* rstudio::conf 2020:
  - Conference site: https://rstudio.com/conference/
  - Conference material: TBA
* Packages essential to the understanding of this talk (in order of appearance):
  * **future** package: [CRAN](https://cran.r-project.org/package=future), [GitHub](https://github.com/HenrikBengtsson/future)
  * **future.apply** package: [CRAN](https://cran.r-project.org/package=future.apply), [GitHub](https://github.com/HenrikBengtsson/future.apply)
  * **purrr** package: [CRAN](https://cran.r-project.org/package=purrr), [GitHub](https://github.com/tidyverse/purrr)
  * **furrr** package: [CRAN](https://cran.r-project.org/package=furrr), [GitHub](https://github.com/DavisVaughan/furrr)
  * **foreach** package: [CRAN](https://cran.r-project.org/package=foreach), [GitHub](https://github.com/RevolutionAnalytics/foreach)
  * **doFuture** package: [CRAN](https://cran.r-project.org/package=doFuture), [GitHub](https://github.com/HenrikBengtsson/doFuture)
  * **future.batchtools** package: [CRAN](https://cran.r-project.org/package=future.batchtools), [GitHub](https://github.com/HenrikBengtsson/future.batchtools)
  * **batchtools** package: [CRAN](https://cran.r-project.org/package=batchtools), [GitHub](https://github.com/mllg/batchtools)
  * **shiny** package: [CRAN](https://cran.r-project.org/package=shiny), [GitHub](https://github.com/rstudio/shiny/issues)
  * **future.tests** package: ~~CRAN~~, [GitHub](https://github.com/HenrikBengtsson/future.tests)
  * **progressr** package: [CRAN](https://cran.r-project.org/package=progressr), [GitHub](https://github.com/HenrikBengtsson/progressr)
  * **progress** package: [CRAN](https://cran.r-project.org/package=progress), [GitHub](https://github.com/r-lib/progress)
  * **beepr** package: [CRAN](https://cran.r-project.org/package=beepr), [GitHub](https://github.com/rasmusab/beepr)
