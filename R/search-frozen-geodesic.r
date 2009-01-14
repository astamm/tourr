# frozen <- matrix(NA, nrow = 4, ncol = 2)
# frozen[3, ] <- .5
# animate_xy(flea[, 1:4], frozen_guided_tour(frozen, holes))
frozen_guided_tour <- function(frozen, index_f, d = 2, max.tries = 25, ...) {
  generator <- function(current, data) {
    if (is.null(current)) return(basis_init(ncol(data), d))    
    
    index <- function(proj) {
      index_f(as.matrix(data) %*% proj)
    }

    search_frozen_geodesic(current, index, max.tries, frozen = frozen)
  }
  
  new_tour_path("frozen-guided", generator, frozen = frozen)
}

search_frozen_geodesic <- function(current, index, max.tries = 5, n = 5, frozen) {
  cur_index <- index(thaw(current, frozen))
  
  try <- 1
  while(try < max.tries) {
    # Try 5 random directions and pick the one that has the highest
    # index after a small step in either direction
    direction <- find_best_frozen_dir(current, frozen, index, n)
    # Travel halfway round (pi / 4 radians) the sphere in that direction
    # looking for the best projection
    peak <- find_frozen_path_peak(current, direction, frozen, index)
    
    pdiff <- (peak$index - cur_index) / cur_index
    if (pdiff > 0.001) {
      cat("New index: ", peak$index, " (", peak$dist, " away)\n", sep="")
      return(peak$basis)
    }
    cat("Best was:  ", peak$index, " (", peak$dist, " away).  Trying again...\n", sep="")
    
    try <- try + 1
  }
  
  NULL  
}


find_best_frozen_dir <- function(old, frozen, index, dist = 0.01, tries = 5) {
  new_basis <- function() freeze(basis_random(nrow(old), ncol(old)), frozen)
  bases <- replicate(tries, new_basis(), simplify = FALSE)
  old <- freeze(old, frozen)
  
  score <- function(new) {
    interpolator <- geodesic_info(old, new)
    forward <- thaw(step_angle(interpolator, dist), frozen)
    backward <- thaw(step_angle(interpolator, -dist), frozen)

    max(index(forward), index(backward))
  }
  scores <- sapply(bases, score)
  thaw(bases[[which.max(scores)]], frozen)
}

find_frozen_path_peak <- function(old, new, frozen, index, max_dist = pi / 4) {
  interpolator <- geodesic_info(freeze(old, frozen), freeze(new, frozen))

  index_pos <- function(alpha) {
    index(thaw(step_angle(interpolator, alpha), frozen))
  }
  
  alpha <- optimize(index_pos, c(-max_dist, max_dist), maximum = TRUE, tol = 0.01)
  
  # xgrid <- seq(-max_dist, max_dist, length = 100)
  # index <- sapply(xgrid, index_pos)
  # plot(xgrid, index, type = "l")
  # browser()
    
  list(
    basis = thaw(step_angle(interpolator, alpha$maximum), frozen),
    index = alpha$objective,
    dist = alpha$maximum
  )
}
