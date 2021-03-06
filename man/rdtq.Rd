% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/RcppExports.R
\name{rdtq}
\alias{rdtq}
\title{Density Tracking by Quadrature (DTQ)}
\usage{
rdtq(h, k = NULL, bigm, a = NULL, b = NULL, init, fT, drift = NULL,
  diffusion = NULL, driftR = NULL, diffusionR = NULL, method = "cpp")
}
\arguments{
\item{h}{Time step size, a positive numeric scalar.}

\item{k}{Spatial grid spacing, a positive numeric scalar.
(Must be specified if \code{a} and \code{b} are not specified.)}

\item{bigm}{If k is specified, then bigm is a positive integer such that
-\code{bigm*k} and \code{bigm*k} are, respectively, the minimum and maximum
grid points.  If \code{a} and \code{b} are specified, then \code{bigm} is
the total number of grid points.  Note that the fractional part of
\code{bigm} is ignored, and that \code{floor(bigm)} must be at least 2.}

\item{a}{Left boundary, a numeric scalar.
(Must be specified if \code{k} is not specified.)}

\item{b}{Right boundary, a numeric scalar.
(Must be specified if \code{k} is not specified.)}

\item{init}{A numeric scalar indicating either a fixed initial condition of
the form \eqn{X(0)}=\code{init}, or a numeric vector giving the PDF at time
\eqn{t=0}. In the latter case, the vector must have the same size as the
spatial grid.}

\item{fT}{The final time, a positive numeric scalar. The computation
assumes an initial time of \eqn{t}=0 and then computes the PDF at time
\eqn{t}=\code{fT}.}

\item{drift}{This is required for the \code{method="cpp"} algorithm.
A pointer to a drift function.  In our C++ code, we define the
type \code{funcPtr} using the following code:

\code{typedef double (*funcPtr)(const double& x);}

We expect the drift function to be a C++ function, implemented using Rcpp, of
type \code{XPtr<funcPtr>}.  See the first example below.}

\item{diffusion}{This is required for the \code{method="cpp"} algorithm.
A pointer to the diffusion function.  The type is the same as for
the drift function.  See the first example below.}

\item{driftR}{This is required for the \code{method="sparse"} algorithm.
This should be a function that takes as input a numeric vector of values.
The function should return as output a numeric vector containing the drift
function evaluated at each element of the input vector.
See the second example below.}

\item{diffusionR}{This is required for the \code{method="cpp"} algorithm.
This should be a function that takes as input a numeric vector of values.
The function should return as output a numeric vector containing the drift
function evaluated at each element of the input vector.
See the second example below.}

\item{method}{A string that indicates which DTQ algorithm to use.
There are two choices:
\describe{
  \item{\code{"cpp"}}{This DTQ method is implemented in C++.  No matrices are formed;
  the method is highly conservative in its usage of memory.  For sufficiently small \code{h} and \code{k},
  it is necessary to use this method.}
  \item{\code{"sparse"}}{This DTQ method is implemented in R using sparse matrices from
  the Matrix package.  The method uses more memory than the \code{"cpp"} method, but may be
  faster for larger values of \code{h} and \code{k}.}
}}
}
\value{
The output consists of a list with two elements:
\describe{
  \item{\code{xvec}}{a numeric vector that contains the spatial grid}
  \item{\code{pdf}}{a numeric vector that contains the PDF evaluated at the grid points}
}
}
\description{
\code{rdtq} implements DTQ algorithms to compute the probability density
function of a stochastic differential equation with
user-specified drift and diffusion functions.
}
\details{
Consider the stochastic differential equation (SDE)

\deqn{ dX(t) = f(X(t)) dt + g(X(t)) dW(t) }

where \eqn{W(t)} is standard Brownian motion, \eqn{f} is the drift
function, and \eqn{g} is the diffusion function. Let \eqn{p(x,t)}
denote the time-dependent probability density function (PDF) of \eqn{X(t)};
then \code{rdtq} computes \eqn{p(x,T)} for a fixed time \eqn{T}.

Note that the PDF is computed on a spatial grid that can be specified in
one of two ways:
\enumerate{
 \item Specify a real, positive value \eqn{k} and a positive integer
\eqn{M} = \code{bigm}. In this case, the PDF will be computed on the grid
\eqn{x_j = j k} where \eqn{j = -M, -M+1, ..., M-1, M}. In total,
there will be \eqn{2M+1} grid points.
 \item Specify a real, positive integer \eqn{M} and a computational domain
\eqn{[a,b]}. In this case, there will be exactly \eqn{M} equispaced grid
points. The grid spacing will be \eqn{k = (b-a)/(M-1)}.
}
}
\examples{
# Example 1:
# Define the drift function f(x) = -x and diffusion function g(x) = 1
# using C++ code:
require(Rcpp)
sourceCpp(code = '#include <Rcpp.h>
using namespace Rcpp;
double drift(double& x)
{
  return(-x);
}
double diff(double& x)
{
  return(1.0);
}
typedef double (*funcPtr)(double& x);
// [[Rcpp::export]]
XPtr<funcPtr> driftXPtr()
{
  return(XPtr<funcPtr>(new funcPtr(&drift)));
}
// [[Rcpp::export]]
XPtr<funcPtr> diffXPtr()
{
  return(XPtr<funcPtr>(new funcPtr(&diff)));
}')
# Solve for the PDF (at final time fT=1) of the SDE with drift f,
# diffusion g, and deterministic initial condition X(0) = 0.
# First we solve using the grid specified by k and bigm.
# Then we solve using the grid specified by a, b, and bigm.
# We then check that we get the same PDF either way.
k = 0.01
M = 250
test1 = rdtq(h=0.1,k,bigm=M,init=0,fT=1,
             drift=driftXPtr(),diffusion=diffXPtr())
test2 = rdtq(h=0.1,a=-2.5,b=2.5,bigm=501,init=0,fT=1,
             drift=driftXPtr(),diffusion=diffXPtr())
print(k*sum(abs(test1$pdf-test2$pdf)))

# Example 2:
# We again use the drift function f(x) = -x and diffusion function g(x) = 1.
# This time, we use the method="sparse" version of DTQ.
# This requires us to define the drift and diffusion functions in R:
mydrift = function(x) { -x }
mydiff = function(x) { rep(1,length(x)) }
test = rdtq(h=0.1,k=0.01,bigm=250,init=0,fT=1,
            driftR=mydrift,diffusionR=mydiff,method="sparse")
plot(test$xvec,test$pdf,type='l')
}

