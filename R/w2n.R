
#' Scaling function: working to natural parameters
#'
#' Scales each parameter from the set of real numbers, back to its natural interval.
#' Used during the optimization of the log-likelihood.
#'
#' @param wpar Vector of working parameters.
#' @param bounds Named list of 2-column matrices specifying bounds on the natural (i.e, real) scale of the probability 
#' distribution parameters for each data stream.
#' @param parSize Named list indicating the number of natural parameters of the data stream probability distributions
#' @param nbStates The number of states of the HMM.
#' @param nbCovs The number of beta covariates.
#' @param estAngleMean Named list indicating whether or not to estimate the angle mean for data streams with angular 
#' distributions ('vm' and 'wrpcauchy').
#' @param circularAngleMean Named list indicating whether to use circular-linear (FALSE) or circular-circular (TRUE) 
#' regression on the mean of circular distributions ('vm' and 'wrpcauchy') for turning angles.  
#' @param stationary \code{FALSE} if there are covariates. If TRUE, the initial distribution is considered
#' equal to the stationary distribution. Default: \code{FALSE}.
#' @param cons Named list of vectors specifying a power to raise parameters corresponding to each column of the design matrix 
#' for each data stream. 
#' @param fullDM Named list containing the full (i.e. not shorthand) design matrix for each data stream.
#' @param DMind Named list indicating whether \code{fullDM} includes individual- and/or temporal-covariates for each data stream
#' specifies (-1,1) bounds for the concentration parameters instead of the default [0,1) bounds.
#' @param workcons Named list of vectors specifying constants to add to the regression coefficients on the working scale for 
#' each data stream. 
#' @param nbObs Number of observations in the data.
#' @param dist Named list indicating the probability distributions of the data streams. 
#' @param Bndind Named list indicating whether \code{DM} is NULL with default parameter bounds for each data stream.
#' @param nc indicator for zeros in fullDM
#' @param meanind index for circular-circular regression mean angles with at least one non-zero entry in fullDM
#' @param covsDelta data frame containing the delta model covariates (if any)
#' 
#' @return A list of:
#' \item{...}{Matrices containing the natural parameters for each data stream (e.g., 'step', 'angle', etc.)}
#' \item{beta}{Matrix of regression coefficients of the transition probabilities}
#' \item{delta}{Initial distribution}
#'
#' @examples
#' \dontrun{
#' m<-example$m
#' nbStates <- 2
#' nbCovs <- 2
#' parSize <- list(step=2,angle=2)
#' par <- list(step=c(t(m$mle$step)),angle=c(t(m$mle$angle)))
#' bounds <- m$conditions$bounds
#' beta <- matrix(rnorm(6),ncol=2,nrow=3)
#' delta <- c(0.6,0.4)
#' 
#' #working parameters
#' wpar <- momentuHMM:::n2w(par,bounds,beta,log(delta[-1]/delta[1]),nbStates,
#' m$conditions$estAngleMean,NULL,m$conditions$cons,m$conditions$workcons,m$conditions$Bndind)
#' 
#' #natural parameter
#' p <-   momentuHMM:::w2n(wpar,bounds,parSize,nbStates,nbCovs,m$conditions$estAngleMean,
#' m$conditions$circularAngleMean,m$conditions$stationary,m$conditions$cons,m$conditions$fullDM,
#' m$conditions$DMind,m$conditions$workcons,1,m$conditions$dist,m$conditions$Bndind,
#' matrix(1,nrow=length(unique(m$data$ID)),ncol=1),covsDelta=m$covsDelta)
#' }
#'
#'
#' @importFrom boot inv.logit
#' @importFrom Brobdingnag as.brob sum

w2n <- function(wpar,bounds,parSize,nbStates,nbCovs,estAngleMean,circularAngleMean,stationary,cons,fullDM,DMind,workcons,nbObs,dist,Bndind,nc,meanind,covsDelta)
{

  # identify initial distribution parameters
  if(!stationary & nbStates>1){
    nbCovsDelta <- ncol(covsDelta)-1 # substract intercept column
    
    foo <- length(wpar)-(nbCovsDelta+1)*(nbStates-1)+1
    delta <- c(rep(0,nbCovsDelta+1),wpar[foo:length(wpar)])
    deltaXB <- covsDelta%*%matrix(delta,nrow=nbCovsDelta+1)
    expdelta <- exp(deltaXB)
    delta <- expdelta/rowSums(expdelta)
    for(i in which(!is.finite(rowSums(delta)))){
      tmp <- exp(Brobdingnag::as.brob(deltaXB[i,]))
      delta[i,] <- as.numeric(tmp/Brobdingnag::sum(tmp))
    }
    wpar <- wpar[-(foo:length(wpar))]
  }
  else delta <- NULL

  # identify regression coefficients for the transition probabilities
  if(nbStates>1) {
    foo <- length(wpar)-(nbCovs+1)*nbStates*(nbStates-1)+1
    beta <- wpar[foo:length(wpar)]
    beta <- matrix(beta,nrow=nbCovs+1)
    wpar <- wpar[-(foo:length(wpar))]
  }
  else beta <- NULL
  
  distnames <- names(dist)
  parindex <- c(0,cumsum(unlist(lapply(fullDM,ncol)))[-length(fullDM)])
  names(parindex) <- names(fullDM)

  parlist<-list()
  
  for(i in distnames){
    tmpwpar<-wpar[parindex[[i]]+1:ncol(fullDM[[i]])]
    if(estAngleMean[[i]] & Bndind[[i]]){ 
      bounds[[i]][,1] <- -Inf
      bounds[[i]][which(bounds[[i]][,2]!=1),2] <- Inf

      foo <- length(tmpwpar) - nbStates + 1
      x <- tmpwpar[(foo - nbStates):(foo - 1)]
      y <- tmpwpar[foo:length(tmpwpar)]
      angleMean <- Arg(x + (0+1i) * y)
      kappa <- sqrt(x^2 + y^2)
      tmpwpar[(foo - nbStates):(foo - 1)] <- angleMean
      tmpwpar[foo:length(tmpwpar)] <- kappa
    }
    parlist[[i]]<-w2nDM(tmpwpar,bounds[[i]],fullDM[[i]],DMind[[i]],cons[[i]],workcons[[i]],nbObs,circularAngleMean[[i]],nbStates,0,nc[[i]],meanind[[i]])

    if((dist[[i]] %in% angledists) & !estAngleMean[[i]]){
      tmp<-matrix(0,nrow=(parSize[[i]]+1)*nbStates,ncol=nbObs)
      tmp[nbStates+1:nbStates,]<-parlist[[i]]
      parlist[[i]] <- tmp
    }
    
  }

  parlist[["beta"]]<-beta
  parlist[["delta"]]<-delta

  return(parlist)
}

w2nDM<-function(wpar,bounds,DM,DMind,cons,workcons,nbObs,circularAngleMean,nbStates,k=0,nc,meanind){
  
  a<-bounds[,1]
  b<-bounds[,2]
  
  zeroInflation <- any(grepl("zeromass",rownames(bounds)))
  oneInflation <- any(grepl("onemass",rownames(bounds)))
  
  piInd<-(abs(a- -pi)<1.e-6 & abs(b - pi)<1.e-6)
  ind1<-which(piInd)
  zoInd <- as.logical((grepl("zeromass",rownames(bounds)) | grepl("onemass",rownames(bounds)))*(zeroInflation*oneInflation))
  ind2<-which(zoInd)
  ind3<-which(!piInd & !zoInd)
  
  XB <- p <- getXB(DM,nbObs,wpar,cons,workcons,DMind,circularAngleMean,nbStates,nc,meanind)
  
  if(length(ind1) & !circularAngleMean)
    p[ind1,] <- (2*atan(XB[ind1,]))
  
  if(length(ind2)){
    for(j in 1:nbStates){
      zoParInd <- which(grepl(paste0("zeromass_",j),rownames(bounds)) | grepl(paste0("onemass_",j),rownames(bounds)))
      zoPar <- rbind(XB[zoParInd,,drop=FALSE],rep(0,ncol(XB)))
      expzo <- exp(zoPar)
      zo <- expzo/rep(colSums(expzo),each=3)
      for(i in which(!is.finite(colSums(zo)))){
        tmp <- exp(Brobdingnag::as.brob(zoPar[,i]))
        zo[,i] <- as.numeric(tmp/Brobdingnag::sum(tmp))
      }
      p[zoParInd,] <- zo[-3,]
    }
  }
  
  ind31<-ind3[which(is.finite(a[ind3]) & is.infinite(b[ind3]))]
  ind32<-ind3[which(is.finite(a[ind3]) & is.finite(b[ind3]))]
  ind33<-ind3[which(is.infinite(a[ind3]) & is.finite(b[ind3]))]
  
  p[ind31,] <- (exp(XB[ind31,,drop=FALSE])+a[ind31])
  p[ind32,] <- ((b[ind32]-a[ind32])*boot::inv.logit(XB[ind32,,drop=FALSE])+a[ind32])
  p[ind33,] <- -(exp(-XB[ind33,,drop=FALSE]) - b[ind33])
  
  if(any(p<a | p>b))
    stop("Scaling error. Check initial values and bounds.")
  
  if(k) {
    p <- p[k]
  } else if(DMind) {
    p <- matrix(p,length(ind1)+length(ind2)+length(ind3),nbObs)
  }
  return(p)
}   
