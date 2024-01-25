library(tidyverse)
library(sars)
Richness <- read.csv("Animals_plants_richness.csv") |>
  dplyr::filter(!is.na(N)) |>
  dplyr::select(Ha, N)

mm_Richness <- sar_average(data = Richness, verb = FALSE, confInt = F, normaTest = "lillie",
                           homoTest = "cor.fitted")

MySarsPlot <- function(x, type = "multi", allCurves = FALSE,
                       pch = 16, cex = 1.2, pcol = "dodgerblue2", ModTitle = NULL,
                       TiAdj = 0, TiLine = 0.5, cex.main = 1.5, cex.lab = 1.3, cex.axis = 1,
                       yRange = NULL, lwd = 2, lcol = "dodgerblue2", mmSep = FALSE,
                       lwd.Sep = 6, col.Sep = "black", pLeg = TRUE, modNames = NULL,
                       cex.names = 0.88, subset_weights = NULL, confInt = FALSE)
{
  if (confInt) {
    if (length(x$details$confInt) == 1)
      stop("No confidence interval information in the fit object")
    CI <- x$details$confInt
  }
  ic <- x[[2]]$ic
  dat <- x$details$fits
  dat2 <- dat
  df <- dat[[1]]$data
  xx <- df$A
  yy <- df$S
  nams <- vapply(dat2, function(x) x$model$name, FUN.VALUE = character(1))
  xx2 <- seq(min(xx), max(xx), length.out = 1000)
  mf <- lapply(dat2, function(y) {
    if (y$model$name == "Linear model") {
      c1 <- y$par[1]
      m <- y$par[2]
      ff <- c1 + (m * xx2)
    }
    else {
      ff <- y$model$mod.fun(xx2, y$par)
      if (anyNA(ff)) {
        stop("Error in plotting, contact package owner")
      }
    }
    ff
  })
  mf2 <- matrix(unlist(mf), ncol = length(dat2), byrow = FALSE)
  mf2 <- as.data.frame(mf2)
  colnames(mf2) <- nams
  icv <- vapply(dat2, function(x) unlist(x[[ic]]), FUN.VALUE = double(1))
  delt <- icv - min(icv)
  akaikesum <- sum(exp(-0.5 * (delt)))
  aw <- exp(-0.5 * delt)/akaikesum
  if (round(sum(aw), 0) != 1)
    stop("IC weights do not sum to 1")
  mf3 <- matrix(nrow = nrow(mf2), ncol = ncol(mf2))
  for (i in seq_along(aw)) mf3[, i] <- mf2[, i] * aw[i]
  wfv <- rowSums(mf3)

  nams2 <- nams
  DF2 <- data.frame(Richness = wfv, Area = xx2)
  CI$x <- df$A
  G <- ggplot(DF2, aes(x = Area, y = Richness)) + geom_path() + theme_bw()
  if(confInt){
    G <- G + geom_ribbon(data = CI, aes(x = x, ymax = U, ymin = L))
  }
  print(G)
  return(DF2)
}

Sum <-  summary(mm_Richness)$Model_table

Sum$CumWeight <- cumsum(Sum$Weight)

Sum <- Sum |> dplyr::mutate(ToFilter = lag(CumWeight)) |>
  dplyr::filter(is.na(ToFilter) | ToFilter < 0.99)

plot(mm_Richness, pLeg = TRUE, mmSep = TRUE, allCurves = F)
MySarsPlot(mm_Richness, pLeg = TRUE, mmSep = TRUE, allCurves = F)
selected_mm_Richness <- sar_average(obj = Sum$Model[1:2],data = Richness, verb = FALSE, confInt = T)



plot(selected_mm_Richness, pLeg = FALSE, mmSep = TRUE, allCurves = F, confInt = T)

MySarsPlot(mm_Richness, pLeg = TRUE, mmSep = TRUE, allCurves = F)
