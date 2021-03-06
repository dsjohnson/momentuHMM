% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/logBeta.R
\name{logBeta}
\alias{logBeta}
\title{Backward log-probabilities}
\usage{
logBeta(m)
}
\arguments{
\item{m}{A \code{\link{momentuHMM}}, \code{\link{miHMM}}, or \code{\link{miSum}} object.}
}
\value{
The matrix of backward log-probabilities.
}
\description{
Used in \code{\link{stateProbs}}.
}
\examples{
\dontrun{
# m is a momentuHMM object (as returned by fitHMM), automatically loaded with the package
m <- example$m

lb <- momentuHMM:::logBeta(m)
}
}
