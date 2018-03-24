---
title: "How to: Package Vignettes in Plain LaTeX"
slug: "how-to-plain-latex-vignettes"
aliases: [/2015/02/latex-vignettes.html]
date: 2015-02-21
categories:
 - R
tags:
 - R
 - package
 - R.rsp
 - vignette
 - LaTeX
 - PDF
 - CRAN
---

Ever wanted to include a plain-LaTeX vignette in your package and have it compiled into a PDF?  The [R.rsp] package provides a four-line solution for this.

_But, first, what's R.rsp?_  R.rsp is an R package that implements a compiler for the RSP markup language.  RSP can be used to embed dynamic R code in _any_ text-based source document to be compiled into a final document, e.g. RSP-embedded LaTeX into PDF, RSP-embedded Markdown into HTML, RSP-embedded HTML into HTML and so on.  The package provides a set of _vignette engines_ making it straightforward to use RSP in vignettes and there are also other vignette engines to, for instance, include static PDF vignettes.  Starting with R.rsp v0.20.0 (on CRAN), a vignette engine for including plain LaTeX-based vignettes is also available.  The R.rsp package installs out-of-the-box on all common operating systems, including Linux, OS X and Windows.  Its source code is available on [GitHub](https://github.com/HenrikBengtsson/R.rsp).

![A Hansen writing ball - a keyboard invented by Rasmus Malling-Hansen in 1865](/post/Writing_ball_keyboard_3.jpg)


## Steps to include a LaTeX vignettes in your package

1. Place your LaTeX file in the `vignettes/` directory of your package.  If it needs other files such as image files, place those under this directory too.

2. Rename the file to have filename extension *.ltx, e.g. vignettes/UsingYadayada.ltx(\*)

3. Add the following meta directives at the top of the LaTeX file:  
   `%\VignetteIndexEntry{Using Yadayada}`  
   `%\VignetteEngine{R.rsp::tex}`

4. Add the following to your `DESCRIPTION` file:  
   `Suggests: R.rsp`  
   `VignetteBuilder: R.rsp`

That's all!

When you run `R CMD build`, the `R.rsp::tex` vignette engine will compile your LaTeX vignette into a PDF and make it part of your package's *.tar.gz file.  As for any vignette engine, the PDF will be placed in the `inst/doc/` directory of the *.tar.gz file, ready to be installed together with your package.  Users installing your package will _not_ have to install R.rsp.

If this is your first package vignette ever, you should know that you are now only baby steps away from writing your first "dynamic" vignette using Sweave, [knitr] or RSP.  For RSP-embedded LaTeX vignettes, change the engine to `R.rsp::rsp`, rename the file to `*.ltx.rsp` (or `*.tex.rsp`) and start embedding R code in the LaTeX file, e.g. 'The p-value is <%= signif(p, 2) %>`.


_Footnote:_ (\*) If one uses filename extension `*.tex`, then `R CMD check` will give a _false_ NOTE about the file "should probably not be installed".  Using extension `*.ltx`, which is an official LaTeX extension, avoids this issue.



### Why not use Sweave?
It has always been possible to "hijack" the Sweave vignette engine to achieve the same thing by renaming the filename extension to `*.Rnw` and including the proper `\VignetteIndexEntry` markup.  This would trick R to compile it as an Sweave vignette (without Sweave markup) resulting in a PDF, which in practice would work as a plain LaTeX-to-PDF compiler.  The `R.rsp::tex` engine achieves the same without the "hack" and without the Sweave machinery.


### Static PDFs?
If you want to use a "static" pre-generated PDF as a package vignette that can also be achieved in a few step using the `R.rsp::asis` vignette engine.   There is an R.rsp [vignette](http://cran.r-project.org/package=R.rsp) explaining how to do this, but please consider alternatives that compile from source before doing this.  Also, vignettes without full source may not be accepted by CRAN.  A LaTeX vignette does not have this problem.



## Links
* CRAN page: http://cran.r-project.org/package=R.rsp
* GitHub page: https://github.com/HenrikBengtsson/R.rsp



[knitr]: http://cran.r-project.org/package=knitr
[R.rsp]: http://cran.r-project.org/package=R.rsp
