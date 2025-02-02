#' Render frames of animation to disk
#'
#' @param data matrix, or data frame containing numeric columns
#' @param tour_path tour path generator
#' @param display the method used to render the projected data,
#'   e.g. \code{\link{display_xy}}, \code{\link{display_pcp}}
#' @param dev name of output device to use (e.g. \code{\link{png}},
#'   \code{\link{pdf}})
#' @param ... other options passed to output device
#' @param apf angle (in radians) per frame
#' @param frames number of frames in output
#' @param rescale if true, rescale all variables to range [0,1]
#' @param sphere if true, sphere all variables
#' @param start starting projection.  If \code{NULL}, uses path default.
#' @keywords hplot
#' @export
#' @references Hadley Wickham, Dianne Cook, Heike Hofmann, Andreas Buja
#'   (2011). tourr: An R Package for Exploring Multivariate Data with
#'   Projections. Journal of Statistical Software, 40(2), 1-18.
#'   \url{http://www.jstatsoft.org/v40/i02/}.
#' @examples
#' render(flea[, 1:4], grand_tour(), display_xy(), "pdf", "test.pdf")
#' render(flea[, 1:4], grand_tour(), display_xy(), "png", "test-%03d.png")
render <- function(data, tour_path, display, dev, ..., apf = 1/10, frames = 50, rescale = TRUE, sphere = FALSE, start = NULL) {
  if (!is.matrix(data)) {
    message("Converting input data to the required matrix format.")
    data <- as.matrix(data)
  }
  if (rescale) data <- rescale(data)
  if (sphere) data  <- sphere_data(data)

  dev <- match.fun(dev)
  dev(...)
  on.exit(dev.off())

  tour <- new_tour(data, tour_path, start)
  step <- tour(0)

  display$init(data)

  i <- 0
  stop_next <- FALSE
  while(i < frames) {
    display$render_frame()
    display$render_data(data, step$proj, step$target)

    if (stop_next) return(invisible())
    i <- i + 1
    step <- tour(apf)
    if (step$step < 0) stop_next <- TRUE
  }
  invisible()
}


#' Render frames of animation to a gif file
#'
#' @param data matrix, or data frame containing numeric columns
#' @param tour_path tour path generator
#' @param display the method used to render the projected data,
#'   e.g. \code{\link{display_xy}}, \code{\link{display_pcp}}
#' @param gif_file Name of gif file (default = "animation.gif")
#' @param ... other options passed to \code{\link{png}}
#' @param apf angle (in radians) per frame
#' @param frames number of frames in output
#' @param rescale if true, rescale all variables to range [0,1]
#' @param sphere if true, sphere all variables
#' @param start starting projection.  If \code{NULL}, uses path default.
#'
#' @examples
#' gif_file <- file.path(tempdir(), "test.gif")
#' render_gif(flea[, 1:4], grand_tour(), display_xy(), gif_file )
#' utils::browseURL(gif_file)
#'
#' @export
render_gif <- function(data, tour_path, display, gif_file = "animation.gif", ..., apf = 1/10, frames = 50, rescale = TRUE, sphere = FALSE, start = NULL) {

  if (!requireNamespace("gifski", quietly = TRUE)) {
    stop("To use this function please install the 'gifski' package", quietly = TRUE)
  }

  # temp png files
  dir <- tempdir()
  png_path <- file.path(dir, "frame%03d.png")

  render(data= data,
         tour_path = tour_path,
         display = display,
         dev = "png",
         png_path,
         ...,
         apf = apf,
         frames = frames,
         rescale = rescale,
         sphere = sphere,
         start = start
  )

  png_files <- sprintf(png_path, 1:frames)
  on.exit(unlink(png_files))

  gifski::gifski(png_files, gif_file, delay = apf, progress = TRUE)
}
