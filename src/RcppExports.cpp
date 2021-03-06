// Generated by using Rcpp::compileAttributes() -> do not edit by hand
// Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

#include "Rdtq_types.h"
#include <Rcpp.h>

using namespace Rcpp;

// rdtq
List rdtq(double h, double k, int bigm, NumericVector init, double T, SEXP drift, SEXP diffusion);
RcppExport SEXP Rdtq_rdtq(SEXP hSEXP, SEXP kSEXP, SEXP bigmSEXP, SEXP initSEXP, SEXP TSEXP, SEXP driftSEXP, SEXP diffusionSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< double >::type h(hSEXP);
    Rcpp::traits::input_parameter< double >::type k(kSEXP);
    Rcpp::traits::input_parameter< int >::type bigm(bigmSEXP);
    Rcpp::traits::input_parameter< NumericVector >::type init(initSEXP);
    Rcpp::traits::input_parameter< double >::type T(TSEXP);
    Rcpp::traits::input_parameter< SEXP >::type drift(driftSEXP);
    Rcpp::traits::input_parameter< SEXP >::type diffusion(diffusionSEXP);
    rcpp_result_gen = Rcpp::wrap(rdtq(h, k, bigm, init, T, drift, diffusion));
    return rcpp_result_gen;
END_RCPP
}
// rdtqgrid
List rdtqgrid(double h, double a, double b, unsigned int veclen, NumericVector init, double T, SEXP drift, SEXP diffusion);
RcppExport SEXP Rdtq_rdtqgrid(SEXP hSEXP, SEXP aSEXP, SEXP bSEXP, SEXP veclenSEXP, SEXP initSEXP, SEXP TSEXP, SEXP driftSEXP, SEXP diffusionSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< double >::type h(hSEXP);
    Rcpp::traits::input_parameter< double >::type a(aSEXP);
    Rcpp::traits::input_parameter< double >::type b(bSEXP);
    Rcpp::traits::input_parameter< unsigned int >::type veclen(veclenSEXP);
    Rcpp::traits::input_parameter< NumericVector >::type init(initSEXP);
    Rcpp::traits::input_parameter< double >::type T(TSEXP);
    Rcpp::traits::input_parameter< SEXP >::type drift(driftSEXP);
    Rcpp::traits::input_parameter< SEXP >::type diffusion(diffusionSEXP);
    rcpp_result_gen = Rcpp::wrap(rdtqgrid(h, a, b, veclen, init, T, drift, diffusion));
    return rcpp_result_gen;
END_RCPP
}
