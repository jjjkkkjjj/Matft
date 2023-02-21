#ifndef POCKETFFT_H
#define POCKETFFT_H

#include <math.h>
#include <string.h>
#include <stdlib.h>

#define RALLOC(type,num) \
  ((type *)malloc((num)*sizeof(type)))
#define DEALLOC(ptr) \
  do { free(ptr); (ptr)=NULL; } while(0)

#define SWAP(a,b,type) \
  do { type tmp_=(a); (a)=(b); (b)=tmp_; } while(0)

#ifdef __GNUC__
#define NOINLINE __attribute__((noinline))
#define WARN_UNUSED_RESULT __attribute__ ((warn_unused_result))
#else
#define NOINLINE
#define WARN_UNUSED_RESULT
#endif

struct cfft_plan_i;
typedef struct cfft_plan_i * cfft_plan;
struct rfft_plan_i;
typedef struct rfft_plan_i * rfft_plan;

typedef struct cmplx {
  double r,i;
} cmplx;

#define NFCT 25
typedef struct cfftp_fctdata
  {
  size_t fct;
  cmplx *tw, *tws;
  } cfftp_fctdata;

typedef struct cfftp_plan_i
  {
  size_t length, nfct;
  cmplx *mem;
  cfftp_fctdata fct[NFCT];
  } cfftp_plan_i;
typedef struct cfftp_plan_i * cfftp_plan;


typedef struct rfftp_fctdata
  {
  size_t fct;
  double *tw, *tws;
  } rfftp_fctdata;

typedef struct rfftp_plan_i
  {
  size_t length, nfct;
  double *mem;
  rfftp_fctdata fct[NFCT];
  } rfftp_plan_i;
typedef struct rfftp_plan_i * rfftp_plan;

typedef struct fftblue_plan_i
  {
  size_t n, n2;
  cfftp_plan plan;
  double *mem;
  double *bk, *bkf;
  } fftblue_plan_i;
typedef struct fftblue_plan_i * fftblue_plan;

typedef struct cfft_plan_i
  {
  cfftp_plan packplan;
  fftblue_plan blueplan;
  } cfft_plan_i;

typedef struct rfft_plan_i
  {
  rfftp_plan packplan;
  fftblue_plan blueplan;
  } rfft_plan_i;

static cfft_plan make_cfft_plan (size_t length);

rfft_plan make_rfft_plan (size_t length);

static void destroy_cfft_plan (cfft_plan plan);

void destroy_rfft_plan (rfft_plan plan);

WARN_UNUSED_RESULT static int cfft_backward(cfft_plan plan, double c[], double fct);

WARN_UNUSED_RESULT static int cfft_forward(cfft_plan plan, double c[], double fct);

WARN_UNUSED_RESULT static int rfft_backward(rfft_plan plan, double c[], double fct);

WARN_UNUSED_RESULT int rfft_forward(rfft_plan plan, double c[], double fct);


#endif
