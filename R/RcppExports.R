.integrandmat <- function(xvec,yvec,h,driftfun,difffun)
{
  drifty = driftfun(yvec)
  diffy = difffun(yvec)
  mysd = diffy*sqrt(h)
  myvar = diffy*diffy*h

  c0 = 1/sqrt(2*pi)
  c0mod = c0/mysd
  dx = xvec[2] - xvec[1]
  bign = length(xvec)

  kvec = c(0)
  mydiags = list(NULL)

  # main diagonal
  maindiag = exp(-(h/2)*(drifty*drifty)/(diffy*diffy))*c0mod
  refsum = sum(abs(maindiag))*dx
  mydiags[[1]] = maindiag

  # super diagonals
  done = 0
  nk = 1
  mytol = 2.2e-16
  while (done==0)
  {
    curdiag = kvec[nk] + 1
    mymean = curdiag*dx + drifty*h
    thisdiag = exp(-mymean*mymean/(2*myvar))*c0mod
    thisdiag = thisdiag[-c(1:curdiag)]
    if ((nk==1) || (sum(abs(thisdiag)) > mytol*refsum))
    {
      mydiags[[nk+1]] = thisdiag
      kvec = c(kvec,curdiag)
      nk = nk + 1
    }
    else
    {
      done = 1
    }
  }
  kvec = c(kvec,-kvec[2:nk])
  # sub diagonals
  for (i in c((nk+1):length(kvec)))
  {
    curdiag = kvec[i]
    mymean = curdiag*dx + drifty*h
    thisdiag = exp(-mymean*mymean/(2*myvar))*c0mod
    thisdiag = thisdiag[-c((bign+curdiag+1):bign)]
    mydiags[[i]] = thisdiag
  }
  out = Matrix::bandSparse(bign,k=kvec,diagonals=mydiags)
  return(out)
}

.dtqsparse <- function(h, k=NULL, a=NULL, b=NULL, bigm, init, fT, drift, diffusion)
{
  numsteps = ceiling(T/h)

  if (is.null(k))
    xvec = seq(from=a,to=b,length.out=bigm)
  else
    xvec = k*c(-bigm:bigm)

  if (length(init)==1)
  {
    driftinit = drift(init)
    diffinit2 = diffusion(init)^2
    fs = exp(-(xvec-init-driftinit*h)^2/(2*diffinit2*h))/sqrt(2*pi*diffinit2*h)
    approxpdf = Matrix::Matrix(fs,ncol=1)
    startnum = 2
  }
  else
  {
    approxpdf = Matrix::Matrix(init,ncol=1)
    startnum = 1
  }
  A = k*(.integrandmat(xvec,xvec,h,driftfun=drift,difffun=diffusion))
  for (i in c(startnum:numsteps)) approxpdf = A %*% approxpdf
  return(list(xvec=xvec,pdf=as.numeric(approxpdf)))
}

#' Density Tracking by Quadrature (DTQ)
#'
#' \code{rdtq} implements DTQ algorithms to compute the probability density
#' function of a stochastic differential equation with
#' user-specified drift and diffusion functions.
#'
#' Consider the stochastic differential equation (SDE)
#'
#' \deqn{ dX(t) = f(X(t)) dt + g(X(t)) dW(t) }
#'
#' where \eqn{W(t)} is standard Brownian motion, \eqn{f} is the drift
#' function, and \eqn{g} is the diffusion function. Let \eqn{p(x,t)}
#' denote the time-dependent probability density function (PDF) of \eqn{X(t)};
#' then \code{rdtq} computes \eqn{p(x,T)} for a fixed time \eqn{T}.
#'
#' Note that the PDF is computed on a spatial grid that can be specified in
#' one of two ways:
#' \enumerate{
#'  \item Specify a real, positive value \eqn{k} and a positive integer
#' \eqn{M} = \code{bigm}. In this case, the PDF will be computed on the grid
#' \eqn{x_j = j k} where \eqn{j = -M, -M+1, ..., M-1, M}. In total,
#' there will be \eqn{2M+1} grid points.
#'  \item Specify a real, positive integer \eqn{M} and a computational domain
#' \eqn{[a,b]}. In this case, there will be exactly \eqn{M} equispaced grid
#' points. The grid spacing will be \eqn{k = (b-a)/(M-1)}.
#' }
#'
#' @param h Time step size, a positive numeric scalar.
#' @param k Spatial grid spacing, a positive numeric scalar.
#'  (Must be specified if \code{a} and \code{b} are not specified.)
#' @param bigm If k is specified, then bigm is a positive integer such that
#'  -\code{bigm*k} and \code{bigm*k} are, respectively, the minimum and maximum
#'  grid points.  If \code{a} and \code{b} are specified, then \code{bigm} is
#'  the total number of grid points.  Note that the fractional part of
#'  \code{bigm} is ignored, and that \code{floor(bigm)} must be at least 2.
#' @param a Left boundary, a numeric scalar.
#'  (Must be specified if \code{k} is not specified.)
#' @param b Right boundary, a numeric scalar.
#'  (Must be specified if \code{k} is not specified.)
#' @param init A numeric scalar indicating either a fixed initial condition of
#'  the form \eqn{X(0)}=\code{init}, or a numeric vector giving the PDF at time
#'  \eqn{t=0}. In the latter case, the vector must have the same size as the
#'  spatial grid.
#' @param fT The final time, a positive numeric scalar. The computation
#'  assumes an initial time of \eqn{t}=0 and then computes the PDF at time
#'  \eqn{t}=\code{fT}.
#' @param drift This is required for the \code{method="cpp"} algorithm.
#' A pointer to a drift function.  In our C++ code, we define the
#' type \code{funcPtr} using the following code:
#'
#' \code{typedef double (*funcPtr)(const double& x);}
#'
#' We expect the drift function to be a C++ function, implemented using Rcpp, of
#' type \code{XPtr<funcPtr>}.  See the first example below.
#'
#' @param diffusion This is required for the \code{method="cpp"} algorithm.
#' A pointer to the diffusion function.  The type is the same as for
#' the drift function.  See the first example below.
#' @param driftR This is required for the \code{method="sparse"} algorithm.
#' This should be a function that takes as input a numeric vector of values.
#' The function should return as output a numeric vector containing the drift
#' function evaluated at each element of the input vector.
#' See the second example below.
#' @param diffusionR This is required for the \code{method="cpp"} algorithm.
#' This should be a function that takes as input a numeric vector of values.
#' The function should return as output a numeric vector containing the drift
#' function evaluated at each element of the input vector.
#' See the second example below.
#' @param method A string that indicates which DTQ algorithm to use.
#' There are two choices:
#' \describe{
#'   \item{\code{"cpp"}}{This DTQ method is implemented in C++.  No matrices are formed;
#'   the method is highly conservative in its usage of memory.  For sufficiently small \code{h} and \code{k},
#'   it is necessary to use this method.}
#'   \item{\code{"sparse"}}{This DTQ method is implemented in R using sparse matrices from
#'   the Matrix package.  The method uses more memory than the \code{"cpp"} method, but may be
#'   faster for larger values of \code{h} and \code{k}.}
#' }
#' @return The output consists of a list with two elements:
#' \describe{
#'   \item{\code{xvec}}{a numeric vector that contains the spatial grid}
#'   \item{\code{pdf}}{a numeric vector that contains the PDF evaluated at the grid points}
#' }
#' @examples
#' # Example 1:
#' # Define the drift function f(x) = -x and diffusion function g(x) = 1
#' # using C++ code:
#' require(Rcpp)
#' sourceCpp(code = '#include <Rcpp.h>
#' using namespace Rcpp;
#' double drift(double& x)
#' {
#'   return(-x);
#' }
#' double diff(double& x)
#' {
#'   return(1.0);
#' }
#' typedef double (*funcPtr)(double& x);
#' // [[Rcpp::export]]
#' XPtr<funcPtr> driftXPtr()
#' {
#'   return(XPtr<funcPtr>(new funcPtr(&drift)));
#' }
#' // [[Rcpp::export]]
#' XPtr<funcPtr> diffXPtr()
#' {
#'   return(XPtr<funcPtr>(new funcPtr(&diff)));
#' }')
#' # Solve for the PDF (at final time fT=1) of the SDE with drift f,
#' # diffusion g, and deterministic initial condition X(0) = 0.
#' # First we solve using the grid specified by k and bigm.
#' # Then we solve using the grid specified by a, b, and bigm.
#' # We then check that we get the same PDF either way.
#' k = 0.01
#' M = 250
#' test1 = rdtq(h=0.1,k,bigm=M,init=0,fT=1,
#'              drift=driftXPtr(),diffusion=diffXPtr())
#' test2 = rdtq(h=0.1,a=-2.5,b=2.5,bigm=501,init=0,fT=1,
#'              drift=driftXPtr(),diffusion=diffXPtr())
#' print(k*sum(abs(test1$pdf-test2$pdf)))
#'
#' # Example 2:
#' # We again use the drift function f(x) = -x and diffusion function g(x) = 1.
#' # This time, we use the method="sparse" version of DTQ.
#' # This requires us to define the drift and diffusion functions in R:
#' mydrift = function(x) { -x }
#' mydiff = function(x) { rep(1,length(x)) }
#' test = rdtq(h=0.1,k=0.01,bigm=250,init=0,fT=1,
#'             driftR=mydrift,diffusionR=mydiff,method="sparse")
#' plot(test$xvec,test$pdf,type='l')
rdtq <- function(h, k=NULL, bigm, a=NULL, b=NULL, init, fT,
                 drift=NULL, diffusion=NULL,
                 driftR=NULL, diffusionR=NULL, method="cpp") {
  if ((method != "cpp") && (method != "sparse"))
    stop("Invalid method.")
  if ((method == "cpp") && (is.null(drift) || is.null(diffusion)))
    stop("The cpp method requires non-NULL drift and diffusion.")
  if ((method == "sparse") && (is.null(driftR) || is.null(diffusionR)))
    stop("The sparse method requires non-NULL driftR and diffusionR.")
  if ((! is.numeric(h)) || (h <= 0))
    stop("Step size h must be numeric and positive.")
  if ((! is.numeric(fT)) || (fT <= 0))
    stop("Final time T must be numeric and positive.")
  if (! is.numeric(bigm))
    stop("Detected non-numeric value of bigm.")
  if (!is.numeric(init))
    stop("Deteched non-numeric value of init.")
  bigmout = floor(bigm)
  if (bigmout <= 1)
    stop("floor(bigm) must be at least 2.")

  if (is.null(a) || is.null(b))
  {
    print("Calling dtq with grid specified via k and bigm.")
    if ((! is.numeric(k)) || (k <= 0))
      stop("Grid spacing k must be numeric and positive.")
    linit = length(init)
    if ((linit != 1) && (linit != (bigmout+1)))
      stop("Initial condition init must either be a scalar or a vector with the size (bigm+1), the same size as the spatial grid.")
    if (method=="cpp")
    {
      print("Using cpp method.")
      return(.Call('Rdtq_rdtq', PACKAGE = 'Rdtq', h, k, bigmout, init, fT, drift, diffusion))
    }
    if (method=="sparse")
    {
      print("Using sparse method.")
      return(.dtqsparse(h=h, k=k, bigm=bigmout, init=init, fT=fT, drift=driftR, diffusion=diffusionR))
    }
  }
  else
  {
    print("Calling dtq with grid specified via a, b, and bigm.")
    if (! is.numeric(a))
      stop("Left boundary a must be numeric.")
    if (! is.numeric(b))
      stop("Right boundary b must be numeric.")
    linit = length(init)
    if ((linit != 1) && (linit != bigmout))
      stop("Initial condition init must either be a scalar or a vector with the size bigm, the same size as the spatial grid.")
    if (method=="cpp")
    {
      print("Using cpp method.")
      return(.Call('Rdtq_rdtqgrid', PACKAGE = 'Rdtq', h, a, b, bigmout, init, fT, drift, diffusion))
    }
    if (method=="sparse")
    {
      print("Using sparse method.")
      return(.dtqsparse(h=h, a=a, b=b, bigm=bigmout, init=init, fT=fT, drift=driftR, diffusion=diffusionR))
    }
  }
}

