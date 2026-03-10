/*
 * File: R2021a_PEM_Canceller_v4_goc_types.h
 *
 * Code generated for Simulink model 'R2021a_PEM_Canceller_v4_goc'.
 *
 * Model version                  : 21.25
 * Simulink Coder version         : 24.1 (R2024a) 19-Nov-2023
 * C/C++ source code generated on : Sun Feb  8 02:56:55 2026
 *
 * Target selection: ert.tlc
 * Embedded hardware selection: 32-bit Generic
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#ifndef R2021a_PEM_Canceller_v4_goc_types_h_
#define R2021a_PEM_Canceller_v4_goc_types_h_
#include "rtwtypes.h"

/* Custom Type definition for MATLAB Function: '<Root>/Adaptive_Filter' */
#ifndef struct_tag_sNrdkIdWgltdvrJr4R5yRFH
#define struct_tag_sNrdkIdWgltdvrJr4R5yRFH

struct tag_sNrdkIdWgltdvrJr4R5yRFH
{
  real_T N;
  real_T w[20];
  real_T framelength;
  real_T frameindex;
  real_T TDLMicdelay[161];
  real_T TDLLsdelay[161];
  real_T TDLMicwh[20];
  real_T TDLLswh[20];
  real_T frame[160];
};

#endif                                 /* struct_tag_sNrdkIdWgltdvrJr4R5yRFH */

#ifndef typedef_sNrdkIdWgltdvrJr4R5yRFH_R2021_T
#define typedef_sNrdkIdWgltdvrJr4R5yRFH_R2021_T

typedef struct tag_sNrdkIdWgltdvrJr4R5yRFH sNrdkIdWgltdvrJr4R5yRFH_R2021_T;

#endif                             /* typedef_sNrdkIdWgltdvrJr4R5yRFH_R2021_T */

#ifndef struct_tag_s03vbnB58wVaDS4iGNamMUF
#define struct_tag_s03vbnB58wVaDS4iGNamMUF

struct tag_s03vbnB58wVaDS4iGNamMUF
{
  real_T gTD[22];
  real_T N;
  real_T mu;
  real_T delta;
  real_T TDLLs[22];
  real_T TDLLswh[22];
  real_T P;
  real_T TDLLswh_d[31];
  real_T TDLMicwh[10];
  real_T Lswh_ap[220];
  real_T delta_IPAPA;
  real_T mu1;
  real_T mu2;
};

#endif                                 /* struct_tag_s03vbnB58wVaDS4iGNamMUF */

#ifndef typedef_s03vbnB58wVaDS4iGNamMUF_R2021_T
#define typedef_s03vbnB58wVaDS4iGNamMUF_R2021_T

typedef struct tag_s03vbnB58wVaDS4iGNamMUF s03vbnB58wVaDS4iGNamMUF_R2021_T;

#endif                             /* typedef_s03vbnB58wVaDS4iGNamMUF_R2021_T */

/* Forward declaration for rtModel */
typedef struct tag_RTM_R2021a_PEM_Canceller__T RT_MODEL_R2021a_PEM_Canceller_T;

#endif                                /* R2021a_PEM_Canceller_v4_goc_types_h_ */

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
