
class: huge

# Future: Parallel & Distributed Processing in R for Everyone


<img src="imgs/formula_one_pitstop_724x412.gif" alt="Animation: Formula 1 pitstop parallel team work" style="margin-top: 0.6ex; width: 58%; float: right;"></a>

<span id="author">
  <strong>Henrik Bengtsson</strong><br>
  <div style="line-height: 1.0; margin-top: -1.5ex; font-size: 105%">
    University of California<br>
    <div style="line-height: 1.4; margin-top: 2ex; margin-bottom: 2ex;">
      <!-- simpleicons.org -->
      <img src="imgs/twitter.svg" style="width: 2.2ex;margin-bottom: -0.2ex;">
      <a href="https://twitter.com/henrikbengtsson">@HenrikBengtsson</a><br>
      <img src="imgs/github.svg" style="width: 2.2ex; margin-bottom: -0.2ex;">
      <a href="https://github.com/HenrikBengtsson/future">HenrikBengtsson/future</a><br>
      <img src="imgs/rss.svg" style="width: 2.0ex;margin-bottom: -0.2ex;">
      <a href="https://jottr.org">jottr.org</a><br>
    </div>
  <small>
  </div>
  </small>
</span>

<div style="line-height: 1.5; margin-top: 2ex; font-size: 120%">
<strong>Acknowledgments</strong><br>
- <a href="http://2018.erum.io/">eRum 2018</a><br>
- <a href="https://www.r-consortium.org/projects">R Consortium</a><br>
- R Core, CRAN, devels & users!<br>
</div>


---
layout: false
class: Huge

# Why do we parallelize software?

Parallel & distributed processing can be used to:

1. **speed up processing** (wall time)

2. **decrease memory footprint** (per machine)

3. **avoid data transfers**


<p class="footnote-small">
Comment: I'll focuses on the first two in this talk.
</p>



---
layout: false
class: Huge

# Definition: Future 

* A **future** is an abstraction for a **value** that will be **available later**
* The value is the **result of an evaluated expression**
* The **state of a future** is **unevaluated** or **evaluated**

<br>

<p class="footnote-small">
Friedman & Wise (1976, 1977), Hibbard (1976),  Baker & Hewitt (1977)
</p>

---
layout: false
class: Huge
count: false

# Definition: Future 

* A **future** is an abstraction for a **value** that will be **available later**
* The value is the **result of an evaluated expression**
* The **state of a future** is **unevaluated** or **evaluated**

<div style="margin-top: 3ex; font-size: 130%; margin-left: 2ex;">
<div style="float: left;">
Standard R:
<pre style="font-size: 130%;">
v <- expr
</pre>
</div>
--
<div style="float: right; margin-right: 3ex;">
Future API:
<pre style="font-size: 130%;">
f <- future(expr)
v <- value(f)
</pre>
</div>
</div>


---
class: huge no-flat

# Example: Sum of 1:50 and 51:100 in parallel


```r
> library(future)
> plan(multiprocess)
```

---
class: huge no-flat
count: false
    
# Example: Sum of 1:50 and 51:100 in parallel


```r
> library(future)
> plan(multiprocess)

> fa <- future( slow_sum( 1:50 ) )
>
```
    
---
class: huge no-flat
count: false

# Example: Sum of 1:50 and 51:100 in parallel


```r
> library(future)
> plan(multiprocess)

> fa <- future( slow_sum( 1:50 ) )
> fb <- future( slow_sum(51:100) )
>   
```


---
class: huge no-flat
count: false

# Example: Sum of 1:50 and 51:100 in parallel


```r
> library(future)
> plan(multiprocess)

> fa <- future( slow_sum( 1:50 ) )
> fb <- future( slow_sum(51:100) )
> 1:3
[1] 1 2 3
	
>
```
     
---
class: huge no-flat
count: false
      
# Example: Sum of 1:50 and 51:100 in parallel


```r
> library(future)
> plan(multiprocess)

> fa <- future( slow_sum( 1:50 ) )
> fb <- future( slow_sum(51:100) )
> 1:3
[1] 1 2 3

> value(fa)
```

---
class: huge no-flat
count: false
      
# Example: Sum of 1:50 and 51:100 in parallel


```r
> library(future)
> plan(multiprocess)

> fa <- future( slow_sum( 1:50 ) )
> fb <- future( slow_sum(51:100) )
> 1:3
[1] 1 2 3

> value(fa)
[1] 1275
```
		  

---
class: huge no-flat
count: false
      
# Example: Sum of 1:50 and 51:100 in parallel


```r
> library(future)
> plan(multiprocess)

> fa <- future( slow_sum( 1:50 ) )
> fb <- future( slow_sum(51:100) )
> 1:3
[1] 1 2 3

> value(fa)
[1] 1275
> value(fb)
[1] 3775
```

---
class: huge
count: false
      
# Example: Sum of 1:50 and 51:100 in parallel


```r
> library(future)
> plan(multiprocess)

> fa <- future( slow_sum( 1:50 ) )
> fb <- future( slow_sum(51:100) )
> 1:3
[1] 1 2 3

> value(fa)
[1] 1275
> value(fb)
[1] 3775
		  
> value(fa) + value(fb)
[1] 5050
```
		      

---
layout: false
class: Huge

# Definition: Future 

<div style="margin-top: 4ex; font-size: 130%; margin-left: 2ex;">
<div style="float: left;">
Standard R:
<pre style="font-size: 130%;">
v <- expr
</pre>
</div>

<div style="float: right; margin-right: 5ex;">
Future API (implicit):
<pre style="font-size: 130%;">
v %<-% expr
</pre>
</div>
</div>

		    
---
class: Huge
      
# Example: Sum of 1:50 and 51:100 in parallel <span style="float: right;">(implicit API)</span>

```r
> library(future)
> plan(multiprocess)

> a %<-% slow_sum( 1:50 )
> b %<-% slow_sum(51:100)
> 1:3
[1] 1 2 3

> a + b
[1] 5050
```

		
---
class: Huge

# Many ways to resolve futures

```r
plan(sequential)
plan(multiprocess)
plan(cluster, workers = c("n1", "n2", "n3"))
plan(cluster, workers = c("remote1.org", "remote2.org"))
...		    
```

--
		
```r
> a %<-% slow_sum( 1:50 )
> b %<-% slow_sum(51:100)
> a + b
[1] 5050
```


---
class: Large
			
# R package: future <span class="badges-small right"><a href="https://cran.r-project.org/package=future"><img src="imgs/future_cran.svg" alt="CRAN version: 1.4.0"></a> <img src="imgs/future_codecov.svg" alt="Codecov: 95%"></span>

* "Write once, run anywhere"
* A simple **unified API** ("interface of interfaces")
* **100% cross platform**
* **Easy to install** (~0.4 MiB total)
* **Very well tested, lots of CPU mileage, production ready**
		
<pre>
╔════════════════════════════════════════════════════════╗
║                     < Future API >                     ║
║                                                        ║
║              future(), value(), %<-%, ...              ║
╠════════════════════════════════════════════════════════╣
║                         future                         ║
╠════════════════════════════════╦═══════════╦═══════════╣
║            parallel            ║  globals  ║ (listenv) ║
╠══════════╦══════════╦══════════╬═══════════╬═══════════╝
║   snow   ║   Rmpi   ║   nws    ║ codetools ║
╚══════════╩══════════╩══════════╩═══════════╝
</pre>


---
class: huge code_normal

# Why a Future API? <span style="float: right;">Problem: heterogeneity</span>

* Different parallel backends ⇔ different APIs
* Choosing API/backend, limits user's options


```r
x <- list(a = 1:50, b = 51:100)
y <- lapply(x, FUN = slow_sum)
```
--
```r
y <- parallel::mclapply(x, FUN = slow_sum)
```
--
```r
library(parallel)
cluster <- makeCluster(4)
y <- parLapply(cluster, x, fun = slow_sum)
stopCluster(cluster)
```

---
class: huge

# Why a Future API? <span style="float: right;">Solution: "interface of interfaces"</span>

* The Future API encapsulates heterogeneity
<div style="margin-top: -1.5ex;"/>     
  - fever decisions for developer to make
  - more power to the end user
     
* Philosophy:
<div style="margin-top: -1.5ex;"/>     
  - **developer decides what to parallelize** - **user decides how to**
  
* Provides **atomic building blocks** for richer parallel constructs,
  e.g. '<a href="https://cran.r-project.org/package=foreach">foreach</a>' and '<a href="https://cran.r-project.org/package=future.apply">future.apply</a>'

* Easy to implement new backends, e.g.
  '<a href="https://cran.r-project.org/package=future.batchtools">future.batchtools</a>' and '<a href="https://cran.r-project.org/package=future.callr">future.callr</a>'


---
class: huge

# Why a Future API? <span style="float: right;">99% Worry Free</span>

* **Globals**: automatically **identified & exported**
* **Packages**: automatically **identified & exported**
* **Static-code inspection** by walking the AST


```r
x <- rnorm(n = 100)
y <- future({ slow_sum(x) })
```
--

Globals identified and exported:
1. `slow_sum()` - a function (also searched recursively)
--

2. `x` - a numeric vector of length 100


--

<div style="font-size: 110%; font-weight: bold;">Globals & packages can be specified manually too</div>


---
count: false

# High Performance Compute (HPC) clusters

<img src="imgs/future_mainframe_red.jpg" alt="Future Art: Mainframe computer room" class="chapter-art"></a>


---
class: huge

# Backend: future.batchtools <span class="badges-small right"><a href="https://cran.r-project.org/package=future.batchtools"><img src="imgs/future.batchtools_cran.svg" alt="CRAN version: 0.14.0"></a> <img src="imgs/future.batchtools_codecov.svg" alt="Codecov: 91%"></span>

* **<a href="https://cran.r-project.org/package=batchtools">batchtools</a>**: Map-Reduce API for **HPC schedulers**,<br>
  e.g. LSF, OpenLava, SGE, Slurm, and TORQUE / PBS
* **<a href="https://cran.r-project.org/package=future.batchtools">future.batchtools</a>**: **Future API** on top of **<a href="https://cran.r-project.org/package=batchtools">batchtools</a>**

<pre style="font-size: 115%; margin-left: 1.5ex;">
╔═══════════════════════════════════════════════════╗
║                   < Future API >                  ║
╠═══════════════════════════════════════════════════╣
║          future        <->   future.batchtools    ║
╠═════════════════════════╦═════════════════════════╣
║         parallel        ║        batchtools       ║
╚═════════════════════════╬═════════════════════════╣
                          ║ SGE, Slurm, TORQUE, ... ║
                          ╚═════════════════════════╝
</pre>


---
class: Huge

# Backend: future.batchtools <span class="badges-small right"><a href="https://cran.r-project.org/package=future.batchtools"><img src="imgs/future.batchtools_cran.svg" alt="CRAN version: 0.14.0"></a> <img src="imgs/future.batchtools_codecov.svg" alt="Codecov: 91%"></span>


```r
> library(future.batchtools)
> plan(batchtools_sge)

> a %<-% slow_sum(1:50)
> b %<-% slow_sum(51:100)
> a + b
[1] 5050
```

---
class: Large
     
# Real Example: DNA Sequence Analysis

* DNA sequences from 100 cancer patients
* 200 GiB data / patient (~ 10 hours)

```r
raw <- dir(pattern = "[.]fq$")
aligned <- listenv()
for (i in seq_along(raw)) {
  aligned[[i]] %<-% DNAseq::align(raw[i])
}
aligned <- as.list(aligned)
```
--
* `plan(multiprocess)`
* `plan(cluster, workers = c("n1", "n2", "n3"))`
* `plan(batchtools_sge)`



<p class="footnote-small">
Comment: The use of `listenv` is non-critical and only needed for implicit futures when assigning them by index (instead of by name).
</p>


---
count: false

# Building on top of Future API

<img src="imgs/funny_car_magnet_animated.gif" alt="Funny car" class="chapter-art"></a>


---
class: huge
layout: true

# Frontend: future.apply <span class="badges-small right"><a href="https://cran.r-project.org/package=future.apply"><img src="imgs/future.apply_cran.svg" alt="CRAN version: 0.2.0"></a> <img src="imgs/future.apply_codecov.svg" alt="Codecov: 91%"></span>

* Futurized version of base R's `lapply()`, `vapply()`, `replicate()`, ...
* ... on **all future-compatible backends**

<pre style="font-size: 80%; margin-top: -1ex; margin-bottom: -1ex;">
╔═══════════════════════════════════════════════════════════╗
║ future_lapply(), future_vapply(), future_replicate(), ... ║
╠═══════════════════════════════════════════════════════════╣
║                       < Future API >                      ║
╠═══════════════════════════════════════════════════════════╣
║                         "wherever"                        ║
╚═══════════════════════════════════════════════════════════╝
</pre>

---

```r
aligned <- lapply(raw, DNAseq::align)
```
---

```r
aligned <- future_lapply(raw, DNAseq::align)
```

--
* `plan(multiprocess)`
* `plan(cluster, workers = c("n1", "n2", "n3"))`
* `plan(batchtools_sge)`

	   

---
class: huge
layout: false

# Frontend: doFuture <span class="badges-small right"><a href="https://cran.r-project.org/package=doFuture"><img src="imgs/doFuture_cran.svg" alt="CRAN version: 0.14.0"></a> <img src="imgs/doFuture_codecov.svg" alt="Codecov: 91%"></span>

* A **<a href="https://cran.r-project.org/package=foreach">foreach</a>** adapter on top of the Future API
* Foreach on **all future-compatible backends**


<pre style="font-size: 80%; margin-left: 1ex; margin-top: -1ex; margin-bottom: -1ex;">
╔═══════════════════════════════════════════════════════╗
║                      foreach API                      ║
╠════════════╦══════╦════════╦═══════╦══════════════════╣
║ doParallel ║ doMC ║ doSNOW ║ doMPI ║     doFuture     ║
╠════════════╩══╦═══╩════════╬═══════╬══════════════════╣
║   parallel    ║    snow    ║ Rmpi  ║  < Future API >  ║
╚═══════════════╩════════════╩═══════╬══════════════════╣
                                     ║    "wherever"    ║
                                     ╚══════════════════╝
</pre>

```r
doFuture::registerDoFuture()
plan(batchtools_sge)
aligned <- foreach(x = raw) %dopar% {
  DNAseq::align(x)
}
```

---
class: huge

# 1,200+ packages can now parallelize on HPC

<pre style="font-size: 75%; margin-left: 1ex;">
┌───────────────────────────────────────────────────────┐
│                                                       │
│      caret, gam, glmnet, plyr, ... (1,200 pkgs)       │
│                                                       │
╠═══════════════════════════════════════════════════════╣
║                      foreach API                      ║
╠══════╦════════════╦════════╦═══════╦══════════════════╣
║ doMC ║ doParallel ║ doSNOW ║ doMPI ║     doFuture     ║
╠══════╩════════╦═══╩════════╬═══════╬══════════════════╣
║   parallel    ║    snow    ║ Rmpi  ║  < Future API >  ║
╚═══════════════╩════════════╩═══════╬══════════════════╣
                                     ║    "wherever"    ║
                                     ╚══════════════════╝
</pre>
```r     
doFuture::registerDoFuture()
plan(future.batchtools::batchtools_sge)

library(caret)
model <- train(y ~ ., data = training)
```

???
```r
## 2018-05-12
> db <- utils::available.packages()
> direct <- tools::dependsOnPkgs("foreach", recursive=FALSE, installed=db)
> str(direct)
 chr [1:443] "adabag" "admixturegraph" "ADMMsigma" "Arothron" "ashr" ...
> all <- tools::dependsOnPkgs("foreach", recursive=TRUE, installed=db)
> str(all)
 chr [1:1200] "adabag" "admixturegraph" "ADMMsigma" "Arothron" "ashr" ...
```


   

---
count: false
  
# Futures in the Wild


---
class: large

# Frontend: _drake_ - A Workflow Manager <a href="https://cran.r-project.org/package=drake"><img src="imgs/drake.svg" alt="drake logo" class="package-logo"></a><br>

<div style="height: 2ex;">&nbsp;</div>

```r
tasks <- drake_plan(
  raw_data = readxl::read_xlsx(file_in("raw-data.xlsx")),

  data = raw_data %>% mutate(Species =
         forcats::fct_inorder(Species)) %>% select(-X__1),
  
  hist = ggplot(data, aes(x = Petal.Width, fill = Species))
         + geom_histogram(),
  
  fit = lm(Sepal.Width ~ Petal.Width + Species, data),
  
  rmarkdown::render(knitr_in("report.Rmd"),
                    output_file = file_out("report.pdf"))
)

future::plan("multiprocess")
make(tasks, parallelism = "future")
```


---

<img src="imgs/drake_workflow_graph.png" alt="Screenshot of drake workflow graph" class="screenshot-center" style="border: 1px solid black; width: 70%; margin-left: 14%;"/>



---
class: huge

# _shiny_ - Now with Asynchronous UI <a href="https://cran.r-project.org/package=shiny"><img src="imgs/shiny-600x695.png" alt="shiny logo" class="package-logo"></a>

<a href="https://twitter.com/jcheng/status/994980498605621248"><img src="imgs/jcheng_tweet_994980498605621248.jpg" alt="Screenshot of drake workflow graph" class="screenshot-center" style="margin-top: -1ex; border: 1px solid black; width: 60%"/></a>

```r
library(shiny)
future::plan("multiprocess")
...
```
	  

---
class: Large

# Summary of features

* **Unified API**

* **Portable code**

* **Worry-free**

* **Developer decides what to parallelize - user decides how to**

* For beginners as well as advanced users

* Nested parallelism on nested heterogeneous backends

* Protects against recursive parallelism

* Easy to add new backends

* Easy to build new frontends



---
class: Huge

# In the near future ...
   
* Capturing standard output
* Benchmarking (time and memory)
* Killing futures


---
class: large
count: false
     
# Building a better future

<br>
<center style="font-size: 180%; margin-top: -1ex;">
I <span style="color:red;">💜</span> feedback,<br> bug reports,<br>and suggestions
<br>
<br>
<span style="font-size: 70%">
      <!-- simpleicons.org -->
      <img src="imgs/twitter.svg" style="width: 2.2ex;margin-bottom: -0.2ex;">
      <a href="https://twitter.com/henrikbengtsson">@HenrikBengtsson</a><br>
      <img src="imgs/github.svg" style="width: 2.2ex; margin-bottom: -0.2ex;">
      <a href="https://github.com/HenrikBengtsson/future">HenrikBengtsson/future</a><br>
      <img src="imgs/rss.svg" style="width: 2.0ex;margin-bottom: -0.2ex;">
      <a href="https://jottr.org">jottr.org</a><br>
</span>
<br>
Thank you!
</center>

---
count: false
     
# Appendix




---
count: false
  
# A1. Features - more details



---
class: large
count: false

# A1.1 Well Tested

* Large number of unit tests
* System tests
* High code coverage (union of all platform near 100%)
* Cross platform testing
* CI testing
* Testing several R versions (many generations back)
* Reverse package dependency tests
* All backends highly tested
* Large of tests via doFuture across backends on `example()`:s
  from foreach, NMF, TSP, glmnet, plyr, caret, etc.
  ([example link](https://travis-ci.org/HenrikBengtsson/doFuture))


# R Consortium Infrastructure Steering Committee (ISC) Support Project

* **<a href="https://www.r-consortium.org/projects/awarded-projects">Backend Conformance Test Suite</a>** - an effort to formalizing and standardizing the above tests into a unified go-to test environment.

---
class: Large
count: false

# A1.2 Nested futures

```r
raw <- dir(pattern = "[.]fq$")

aligned <- listenv()
for (i in seq_along(raw)) {
  aligned[[i]] %<-% {  
    chrs <- listenv()
    for (j in 1:24) {
      chrs[[j]] %<-% DNAseq::align(raw[i], chr = j)
    }
    merge_chromosomes(chrs)
  }
}
```
--

* `plan(batchtools_sge)`

--
* `plan(list(batchtools_sge, sequential))`

--
* `plan(list(batchtools_sge, multiprocess))`



---
class: Huge
count: false
      
# A1.3 Lazy evaluation

By default all futures are resolved using eager evaluation, but the _developer_ has the option to use lazy evaluation.

Explicit API:
```r
f <- future(..., lazy = TRUE)
v <- value(f)
```

Implicit API:
```r
v %<-% { ... } %lazy% TRUE
```



---
class: Large
count: false
       
# A1.4 False-negative & false-positive globals

Identification of globals from static-code inspection has limitations
(but defaults cover a large number of use cases):

* False negatives, e.g. `my_fcn` is not found in `do.call("my_fcn", x)`. Avoid by using `do.call(my_fcn, x)`.

* False positives - non-existing variables, 
  e.g. NSE and variables in formulas.  Ignore and leave it to run-time.


```r
x <- "this FP will be exported"

data <- data.frame(x = rnorm(1000), y = rnorm(1000))

fit %<-% lm(x ~ y, data = data)
```

<p class="footnote-small">
Comment: ... so, the above works.
</p>       

---
class: large	 
count: false
      
# A1.5 Full control of globals (explicit API)

Automatic (default):
```r
x <- rnorm(n = 100)
y <- future({ slow_sum(x) }, globals = TRUE)
```

By names:
```r
y <- future({ slow_sum(x) }, globals = c("slow_sum", "x"))
```

As name-value pairs:
```r
y <- future({ slow_sum(x) }, globals =
                                 list(slow_sum = slow_sum, x = rnorm(n = 100)))
```

Disable:
```r
y <- future({ slow_sum(x) }, globals = FALSE)
```

---
class: large	 
count: false

# A1.5 Full control of globals (implicit API)

Automatic (default):
```r
x <- rnorm(n = 100)
y %<-% { slow_sum(x) } %globals% TRUE
```

By names:
```r
y %<-% { slow_sum(x) } %globals% c("slow_sum", "x")
```

As name-value pairs:
```r
y %<-% { slow_sum(x) } %globals% list(slow_sum = slow_sum, x = rnorm(n = 100))
```

Disable:
```r
y %<-% { slow_sum(x) } %globals% FALSE
```
       

---
class: large	 
count: false

# A1.6 Protection: Exporting too large objects

```r
x <- lapply(1:100, FUN = function(i) rnorm(1024 ^ 2))
y <- list()
for (i in seq_along(x)) {
  y[[i]] <- future( mean(x[[i]]) )
}
```
<span style="font-size: 100%">
gives error: "The total size of the 2 globals that need to be exported for the future expression ('mean(x[[i]])') is **800.00 MiB. This exceeds the maximum allowed size of 500.00 MiB (option 'future.globals.maxSize')**. There are two globals: 'x' (800.00 MiB of class 'list') and 'i' (48 bytes of class 'numeric')."
</span>
--

```r
for (i in seq_along(x)) {
  x_i <- x[[i]]  ## Fix: subset before creating future
  y[[i]] <- future( mean(x_i) )
}
```

<p class="footnote-small">
Comment: Interesting research project to automate via code inspection.
</p>


---
class: large	 
count: false

# A1.7 Free futures are resolved

Implicit futures are always resolved:
```r
a %<-% sum(1:10)
b %<-% { 2 * a }
print(b)
## [1] 110
```
--
Explicit futures require care by developer:
```r
fa <- future( sum(1:10) )
a <- value(fa)
fb <- future( 2 * a )
```
--
For the lazy developer - not recommended (may be expensive):
```r
options(future.globals.resolve = TRUE)
fa <- future( sum(1:10) )
fb <- future( 2 * value(fa) )
```


---
class: Large	 
count: false

# A1.8 What's under the hood?

* **Future class** and corresponding methods:

  - abstract S3 class with common parts implemented, <br>e.g.
    globals and protection
  
  - new backends extend this class and implement core methods,<br>
    e.g. `value()` and `resolved()`
  
  - built-in classes implement backends on top the parallel package



---
class: large
count: false

# A1.9 Universal union of parallel frameworks

 _ _                  | <a href="https://cran.r-project.org/package=future">future</a> | parallel | <a href="https://cran.r-project.org/package=foreach">foreach</a> | <a href="https://cran.r-project.org/package=batchtools">batchtools</a> | <a href="https://cran.r-project.org/package=BiocParallel">BiocParallel</a> 
:---------------------|:------------|:----------|:------------|:-----------|:-------------
Synchronous           |** ✓      **| ✓        |  ✓         | ✓         | ✓            
Asynchronous          |** ✓      **| ✓        |  ✓         | ✓         | ✓
Uniform API           |** ✓      **|           |  ✓         | ✓         | ✓       
Extendable API        |** ✓      **|           |  ✓         | ✓         | ✓
Globals               |** ✓      **|           | (✓)        |            |               
Packages              |** ✓      **|           |             |            |               
Map-reduce ("lapply") |** ✓      **| ✓        | `foreach()` | ✓         | ✓
Load&nbsp;balancing   |** ✓      **| ✓        | ✓          | ✓         | ✓
For loops             |** ✓      **|           |             |            |
While loops           |** ✓      **|           |             |            |              
Nested config         |** ✓      **|           |             |            | 
Recursive protection  |** ✓      **| mc        | mc          | mc         | mc
RNG stream            |** ✓+     **| ✓        | <a href="https://cran.r-project.org/package=doRNG">doRNG</a>       | (soon)     | SNOW
Early stopping        |** ✓      **|           |             |            | ✓
Traceback             |** ✓      **|           |             |            | ✓



---
count: false
  
# A2 Bells & whistles


---
class: large	 
count: false

# A2.1 availableCores() & availableWorkers()

* `availableCores()` is a "nicer" version of `parallel::detectCores()` that returns the number of cores allotted to the process by acknowledging known settings, e.g.

  - `getOption("mc.cores")`
  - HPC environment variables, e.g. `NSLOTS`, `PBS_NUM_PPN`, `SLURM_CPUS_PER_TASK`, ...
  - `_R_CHECK_LIMIT_CORES_`


* `availableWorkers()` returns a vector of hostnames based on:

  - HPC environment information, e.g. `PE_HOSTFILE`, `PBS_NODEFILE`, ...
  - Fallback to `rep("localhost", availableCores())`

Provide safe defaults to for instance
```r
plan(multiprocess)
plan(cluster)
```

      
---
class: Large
count: false
  
# A2.2: makeClusterPSOCK()

`makeClusterPSOCK()`:

* Improves upon `parallel::makePSOCKcluster()`

* Simplifies cluster setup, especially remote ones

* Avoids common issues when workers connect back to master:
  - uses SSH reverse tunneling
  - no need for port-forwarding / firewall configuration
  - no need for DNS lookup

* Makes option `-l <user>` optional (such that `~/.ssh/config` is respected)

		     
---
class: huge      
count: false

# A2.3 HPC resource parameters

With '<a href="https://cran.r-project.org/package=future.batchtools">future.batchtools</a>' one can also specify computational resources, e.g. cores per node and memory needs.

```r
plan(batchtools_sge, resources = list(mem = "128gb"))
y %<-% { large_memory_method(x) }
```


**Specific to scheduler**: `resources` is passed to the job-script template 
where the parameters are interpreted and passed to the scheduler.

--

Each future needs one node with 24 cores and 128 GiB of RAM:       
```r
resources = list(l = "nodes=1:ppn=24", mem = "128gb")
```



---
count: false
  
# A3. More Examples



---
class: huge
count: false

# A3.1 Plot remotely - display locally

```r
> library(future)
> plan(cluster, workers = "remote.org")
```
--

```r
## Plot remotely
> g %<-% R.devices::capturePlot({
    filled.contour(volcano, color.palette = terrain.colors)
    title("volcano data: filled contour map")
 })
```
--

```r
## Display locally
> g
```

--
<img src="imgs/volcano_heatmap.png" alt="Screenshot of example(volcano) plot" class="screenshot-large"></a>

???
* R (>= 3.3.0)
* `recordPlot()` + `replayPlot()`
* Replotted using local R plot routines
* X11 and similar is _not_ in play here!


---
class: Large
count: false

# A3.2 Profile code remotely - display locally

```r
> plan(cluster, workers = "remote.org")

> dat <- data.frame(
+   x = rnorm(50e3),
+   y = rnorm(50e3)
+ )

## Profile remotely
> p %<-% profvis::profvis({
+   plot(x ~ y, data = dat)
+   m <- lm(x ~ y, data = dat)
+   abline(m, col = "red")
+ })
```
--

```r
## Browse locally
> p 
```

--
<img src="imgs/profvis.png" alt="Screenshot of profvis HTML report" class="screenshot-large"></a>


---
class: Large
count: false

# A3.3 _fiery_ - flexible lightweight web server <img src="imgs/fiery-logo.png" alt="fiery logo" class="package-logo">

> "... **framework for building web servers in R. ... from serving static  
> content to full-blown dynamic web-apps**"

<center>
  <img src="imgs/fiery_example.png" alt="Screenshot of fiery web server and R terminal" class="screenshot-center-medium"></a>
</center>

	 
---
class: huge
count: false

# A3.4 "It kinda just works" (furrr = future + purrr)


```r
plan(multisession)
mtcars %>%
  split(.$cyl) %>%
  map(~ future(lm(mpg ~ wt, data = .x))) %>% values %>%
  map(summary) %>%
  map_dbl("r.squared")
##         4         6         8 
## 0.5086326 0.4645102 0.4229655 
```

<p class="footnote-small">
Comment: This approach not do load balancing.  I have a few ideas how support for this may be implemented in future framework, which would be beneficial here and elsewhere.
</p>    

---
class: huge
count: false

# <span style="float: left;">A3.5 Backend: Google Cloud Engine Cluster</span><a href="https://cran.r-project.org/package=googleComputeEngineR"><img src="imgs/googleComputeEngineR-logo.png" alt="googleComputeEngineR logo" class="package-logo"></a>

<div style="height: 4.5ex;">&nbsp;</div>

```r
library(googleComputeEngineR)
vms <- lapply(paste0("node", 1:10),
              FUN = gce_vm, template = "r-base")
cl <- as.cluster(lapply(vms, FUN = gce_ssh_setup),
               docker_image = "henrikbengtsson/r-base-future")
	    
plan(cluster, workers = cl)
```
--

```r
data <- future_lapply(1:100, montecarlo_pi, B = 10e3)
pi_hat <- Reduce(calculate_pi, data)

print(pi_hat)
## 3.1415		  
```


---
count: false

# A4. Future Work

       
---
class: huge
count: false
      
# A4.1 Standard resource types(?)

For any type of futures, the develop may wish to control:

* memory requirements, e.g. `future(..., memory = 8e9)`
* local machine only, e.g. `remote = FALSE`
* dependencies, e.g. `dependencies = c("R (>= 3.5.0)", "rio"))`
* file-system availability, e.g. `mounts = "/share/lab/files"`
* data locality, e.g. `vars = c("gene_db", "mtcars")`
* containers, e.g. `container = "docker://rocker/r-base"`
* generic resources, e.g. `tokens = c("a", "b")`
* ...?

<p class="footnote-small">
Risk for bloating the Future API:  Which need to be included?  Don't want to reinvent the HPC scheduler and Spark.
</p>
						    


