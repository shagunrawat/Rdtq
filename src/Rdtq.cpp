#include <Rcpp.h>
using namespace Rcpp;

#include <iostream>
#include <cmath>
#include "Rdtq_types.h"

double callViaXPtr(const double x, SEXP xpsexp)
{
  XPtr<funcPtr> xpfun(xpsexp);
  funcPtr fun = *xpfun;
  double y = fun(x);
  return(y);
}

// default/optional arguments!!!

// some things that we need to add to this function:
// 1) ability to specify arbitrary domain boundaries and k
// 2) ability to specify xvec itself!

// [[Rcpp::export]]
List rdtq(double h, double k, int bigm, NumericVector init, double T, SEXP drift, SEXP diffusion)
{
  XPtr<funcPtr> driftF(drift);
  XPtr<funcPtr> diffF(diffusion);
  funcPtr driftfun = *driftF;
  funcPtr difffun = *diffF;

  unsigned int veclen = 2*bigm+1;

  NumericVector oldphatn(veclen);
  NumericVector phatn(veclen);
  NumericVector phatnp1(veclen);
  NumericVector xvec(veclen);
  for (int i=-bigm;i<=bigm;i++) {
    xvec(i+bigm) = i*k;
  }

  if (init.size()==1)
  {
    double initval = init(0);
    // pdf after one time step
    // need to do this if initial condition is a fixed constant
    // in which case initial PDF is a Dirac delta, so we do one step manually
    double mydiff = std::abs(difffun(initval));
    double mydiff2 = pow(mydiff,2);
    for (int i=0;i<veclen;i++) {
      phatn(i) = exp(-pow(xvec(i)-initval-driftfun(initval)*h,2)/(2.0*mydiff2*h))/(mydiff*sqrt(2.0*M_PI*h));
    }
  }
  else
  {
    for (int i=0;i<veclen;i++) phatn(i) = init(i);
  }

  // iterate
  int bign = ceil(T/h);
  double thresh = 2.2e-16; // GSL_DBL_EPSILON;
  double lthresh = log(thresh);
  for (int n=1;n<bign;n++) {
    for (int i=-bigm;i<=bigm;i++) {
      bool keepgoing = true;
      int j = i;
      double tally = 0.0;
      while (keepgoing) {
        double thisdiff = pow(difffun(j*k),2);
        double lker = log(k) - pow(i*k - j*k - driftfun(j*k)*h,2)/(2.0*thisdiff*h) - 0.5*log(2.0*M_PI*thisdiff*h);
        if (lker < lthresh) keepgoing = false;
        if (phatn(j+bigm) >= thresh)
          tally += exp(lker + log(phatn(j+bigm)));
        j++;
        if (j > bigm) keepgoing = false;
      }
      if (i > -bigm) {
        keepgoing = true;
        j = i-1;
      }
      while (keepgoing) {
        double thisdiff = pow(difffun(j*k),2);
        double lker = log(k) - pow(i*k - j*k - driftfun(j*k)*h,2)/(2.0*thisdiff*h) - 0.5*log(2.0*M_PI*thisdiff*h);
        if (lker < lthresh) keepgoing = false;
        if (phatn(j+bigm) >= thresh)
          tally += exp(lker + log(phatn(j+bigm)));
        j--;
        if (j < -bigm) keepgoing = false;
      }
      phatnp1(i+bigm) = tally;
    }
    phatn = phatnp1;
  }

  List ret = List::create(_["xvec"]=xvec,_["pdf"]=phatn);
  return ret;
}

// version of rdtq in which user specifies the boundaries [a,b] of the spatial grid,
// together with the total number of grid points

// [[Rcpp::export]]
List rdtqgrid(double h, double a, double b, unsigned int veclen, NumericVector init, double T, SEXP drift, SEXP diffusion)
{
  XPtr<funcPtr> driftF(drift);
  XPtr<funcPtr> diffF(diffusion);
  funcPtr driftfun = *driftF;
  funcPtr difffun = *diffF;

  NumericVector oldphatn(veclen);
  NumericVector phatn(veclen);
  NumericVector phatnp1(veclen);
  NumericVector xvec(veclen);
  double k = (b-a)/(veclen-1);
  for (int i=0;i<(veclen-1);i++) {
    xvec(i) = a + i*k;
  }
  xvec(veclen-1) = b;

  if (init.size()==1)
  {
    double initval = init(0);
    // pdf after one time step
    // need to do this if initial condition is a fixed constant
    // in which case initial PDF is a Dirac delta, so we do one step manually
    double mydiff = std::abs(difffun(initval));
    double mydiff2 = pow(mydiff,2);
    for (int i=0;i<veclen;i++) {
      phatn(i) = exp(-pow(xvec(i)-initval-driftfun(initval)*h,2)/(2.0*mydiff2*h))/(mydiff*sqrt(2.0*M_PI*h));
    }
  }
  else
  {
    for (int i=0;i<veclen;i++) phatn(i) = init(i);
  }

  // iterate
  int bign = ceil(T/h);
  double thresh = 2.2e-16; // GSL_DBL_EPSILON;
  double lthresh = log(thresh);
  for (int n=1;n<bign;n++) {
    for (int i=0;i<veclen;i++) {
      bool keepgoing = true;
      int j = i;
      double tally = 0.0;
      while (keepgoing) {
        double thisdiff = pow(difffun(j*k),2);
        double lker = log(k) - pow(xvec(i) - xvec(j) - driftfun(xvec(j))*h,2)/(2.0*thisdiff*h) - 0.5*log(2.0*M_PI*thisdiff*h);
        if (lker < lthresh) keepgoing = false;
        if (phatn(j) >= thresh)
          tally += exp(lker + log(phatn(j)));
        j++;
        if (j > (veclen-1)) keepgoing = false;
      }
      if (i > 0) {
        keepgoing = true;
        j = i-1;
      }
      while (keepgoing) {
        double thisdiff = pow(difffun(j*k),2);
        double lker = log(k) - pow(xvec(i) - xvec(j) - driftfun(xvec(j))*h,2)/(2.0*thisdiff*h) - 0.5*log(2.0*M_PI*thisdiff*h);
        if (lker < lthresh) keepgoing = false;
        if (phatn(j) >= thresh)
          tally += exp(lker + log(phatn(j)));
        j--;
        if (j < 0) keepgoing = false;
      }
      phatnp1(i) = tally;
    }
    phatn = phatnp1;
  }

  List ret = List::create(_["xvec"]=xvec,_["pdf"]=phatn);
  return ret;
}

