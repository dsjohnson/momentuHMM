% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/crawlMerge.R
\name{crawlMerge}
\alias{crawlMerge}
\title{Merge crwData object with additional data streams and/or covariates}
\usage{
crawlMerge(crwData, data, Time.name)
}
\arguments{
\item{crwData}{A \code{\link{crwData}} object}

\item{data}{A data frame containing required columns \code{ID} and \code{Time.name}, plus any additional data streams and/or covariates to merge with \code{crwData}.}

\item{Time.name}{Character string indicating name of the time column to be used for merging}
}
\value{
A \code{\link{crwData}} object
}
\description{
This function can be used to merge \code{\link{crwData}} objects (as returned by \code{\link{crawlWrap}}) with additional data streams
and/or covariates that are unrelated to location.
}
\details{
Specifically, the function merges the \code{crwData$crwPredict} data frame with \code{data}
based on the \code{ID} and \code{Time.name} columns.  Thus both \code{crwData$crwPredict} and \code{data} must contain \code{ID} and \code{Time.name} columns.

Only rows of \code{data} with \code{ID} and \code{Time.name} values that exactly match \code{crwData$crwPredict} are merged. Typically, the \code{Time.name} column
in \code{data} should match predicted times of locations in \code{crwData$crwPredict} (i.e. those corresponding to \code{crwData$crwPredict$locType=="p"})
}
\examples{
\dontrun{
# extract simulated obsData from example data
obsData <- miExample$obsData

# extract crwMLE inputs from example data
inits <- miExample$inits # initial state
err.model <- miExample$err.model # error ellipse model

# Fit crwMLE models to obsData and predict locations 
# at default intervals for both individuals
crwOut <- crawlWrap(obsData=obsData,ncores=1,
         theta=c(4,0),fixPar=c(1,1,NA,NA),
         initial.state=inits,
         err.model=err.model,attempts=100)
         
# create data frame with fake data stream
data <- data.frame(ID=rep(factor(c(1,2)),times=c(753,652)),
                   time=c(1:753,1:652),
                   fake=rpois(753+652,5))

# merge fake data stream with crwOut
crwOut <- crawlMerge(crwOut,data,"time")
}
}
