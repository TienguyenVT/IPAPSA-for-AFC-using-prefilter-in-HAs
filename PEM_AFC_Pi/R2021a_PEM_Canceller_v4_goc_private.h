/*
 * File: R2021a_PEM_Canceller_v4_goc_private.h
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

#ifndef R2021a_PEM_Canceller_v4_goc_private_h_
#define R2021a_PEM_Canceller_v4_goc_private_h_
#include "rtwtypes.h"
#include "zero_crossing_types.h"
#include "R2021a_PEM_Canceller_v4_goc_types.h"

/* Used by FromWorkspace Block: '<S6>/From Workspace' */
#ifndef rtInterpolate
# define rtInterpolate(v1,v2,f1,f2)    (((v1)==(v2))?((double)(v1)): (((f1)*((double)(v1)))+((f2)*((double)(v2)))))
#endif

#ifndef rtRound
# define rtRound(v)                    ( ((v) >= 0) ? floor((v) + 0.5) : ceil((v) - 0.5) )
#endif

extern real_T rt_hypotd_snf(real_T u0, real_T u1);

#endif                              /* R2021a_PEM_Canceller_v4_goc_private_h_ */

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
