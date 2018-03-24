---
title: "Force R Help HTML Server to Always Use the Same URL Port"
slug: "config-help-start"
aliases: [/2012/10/force-r-help-html-server-to-always-use.html]
date: 2012-10-22
categories:
 - R
tags:
 - R
 - startup
 - Rprofile
 - configuration
 - options
 - help
 - port
---

The below code shows how to configure the `help.ports` option in R such that the built-in R help server always uses the same URL port. Just add it to the `.Rprofile` file in your home directory (iff missing, create it). For more details, see `help("Startup")`.

```r
# Force the URL of the help to http://127.0.0.1:21510
options(help.ports = 21510)
```

A slighter fancier version is to use a environment variable to set the port(s):
```r
local({
  ports <- Sys.getenv("R_HELP_PORTS", 21510)
  ports <- as.integer(unlist(strsplit(ports, ",")))
  options(help.ports = ports)
})
```

However, if you launch multiple R sessions in parallel, this means that they will all try to use the same port, but it's only the first one that will success and all other will fail.  An alternative is then to provide R with a set of ports to choose from (see `help("startDynamicHelp", package = "tools")`). To set the ports to 21510-21519 if you run R v2.15.1, to 21520-21529 if you run R v2.15.2, to 21600-21609 if you run R v2.16.0 ("devel") and so on, do:

```r
local(
  port <- sum(c(1e4, 100) * as.double(R.version[c("major", "minor")]))
  options(help.ports = port + 0:9)
})
```
With this it will be easy from the URL to identify for which version of R the displayed help is for. Finally, if you wish the R help server to start automatically in the background when you start R, add:

```r
# Try to start HTML help server
if (interactive()) {
  try(tools::startDynamicHelp())
}
```
