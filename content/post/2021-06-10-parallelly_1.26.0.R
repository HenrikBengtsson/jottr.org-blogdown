library(ggplot2)
library(tibble)
library(progressr)
handlers(global = TRUE)

library(parallel)
library(parallelly)
max_ncores <- 2*availableCores()
ncores <- 2^(0:log2(max_ncores))
#ncores <- 1:max_ncores
B <- 5L

fcns <- list(
  makeClusterPSOCK = makeClusterPSOCK,
  makePSOCKcluster = makePSOCKcluster
)
fcns <- fcns[c("makeClusterPSOCK")]

with_progress({
p <- progressor(B * length(fcns) * length(ncores) * 2L)
stats <- list()
for (bb in 1:B) {
  for (ii in seq_along(ncores)) {
    n <- ncores[ii]
    for (setup_strategy in c("sequential", "parallel")) {
      for (method in names(fcns)) {
        fcn <- fcns[[method]]
        dt <- system.time({
          cl <- fcn(n, setup_strategy = setup_strategy)
        })[["elapsed"]]
        parallel::stopCluster(cl)
        stats_t <- data.frame(cores = n, method = name, setup_strategy = setup_strategy, time = dt)
        stats <- c(stats, list(stats_t))
        p(sprintf("n=%d, method = %s, %s, iteration=%d", n, method, setup_strategy, bb))
        gc()
      } ## for (name ...)
    }
  }
}
})

stats <- do.call(rbind, stats)
stats$setup_strategy <- factor(stats$setup_strategy, levels = c("sequential", "parallel"))
stats <- as.tibble(stats)
print(stats)

gg <- ggplot(stats, aes(x=cores, y=time, color=setup_strategy))
gg <- gg + geom_smooth(size = 2, method = "loess", formula = y ~ x)
gg <- gg + xlab("Number of parallel workers")
gg <- gg + ylab("Total setup time (s)")
gg <- gg + labs(color = "Setup strategy")
print(gg)
ggsave(gg, filename = "makeClusterPSOCK_setup_time.png")


print(by(stats$time, INDICES = stats$setup_strategy, FUN = max))
## stats$setup_strategy: sequential
## [1] 51.971
## ------------------------------------------------------------ 
## stats$setup_strategy: parallel
## [1] 1.157

strategies <- levels(stats$setup_strategy)
coeffs <- lapply(strategies, FUN = function(strategy) {
  stats_t <- subset(stats, setup_strategy == strategy)
  fit <- lm(time ~ cores, data = stats_t)
  coefficients(fit)
})
names(coeffs) <- strategies
print(coeffs)
## $sequential
## (Intercept)       cores 
## -0.07208812  0.42562891
## 
## $parallel
## (Intercept)       cores 
##  0.39637113  0.00594509

message("Slope difference: ", coeffs$sequential[["cores"]] / coeffs$parallel[["cores"]])
## Slope difference: 71.5933558967621
