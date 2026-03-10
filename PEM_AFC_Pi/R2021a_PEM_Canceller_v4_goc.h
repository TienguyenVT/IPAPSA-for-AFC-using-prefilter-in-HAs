/*
 * File: R2021a_PEM_Canceller_v4_goc.h
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

#ifndef R2021a_PEM_Canceller_v4_goc_h_
#define R2021a_PEM_Canceller_v4_goc_h_
#ifndef R2021a_PEM_Canceller_v4_goc_COMMON_INCLUDES_
#define R2021a_PEM_Canceller_v4_goc_COMMON_INCLUDES_
#include "rtwtypes.h"
#include "HostLib_Audio.h"
#endif                        /* R2021a_PEM_Canceller_v4_goc_COMMON_INCLUDES_ */

#include "R2021a_PEM_Canceller_v4_goc_types.h"
#include <math.h>
#include "rt_nonfinite.h"
#include "rtGetInf.h"
#include "rtGetNaN.h"
#include "zero_crossing_types.h"

/* Macros for accessing real-time model data structure */
#ifndef rtmGetErrorStatus
#define rtmGetErrorStatus(rtm)         ((rtm)->errorStatus)
#endif

#ifndef rtmSetErrorStatus
#define rtmSetErrorStatus(rtm, val)    ((rtm)->errorStatus = (val))
#endif

#ifndef rtmGetStopRequested
#define rtmGetStopRequested(rtm)       ((rtm)->Timing.stopRequestedFlag)
#endif

#ifndef rtmSetStopRequested
#define rtmSetStopRequested(rtm, val)  ((rtm)->Timing.stopRequestedFlag = (val))
#endif

#ifndef rtmGetStopRequestedPtr
#define rtmGetStopRequestedPtr(rtm)    (&((rtm)->Timing.stopRequestedFlag))
#endif

/* Block signals (default storage) */
typedef struct {
  real_T Sum2;                         /* '<Root>/Sum2' */
  real_T LevinsonDurbin[21];           /* '<S3>/Levinson-Durbin' */
  real_T e;                            /* '<Root>/Adaptive_Filter' */
  real_T W[22];                        /* '<Root>/Adaptive_Filter' */
  real_T dg_hat;                       /* '<Root>/dg_hat' */
  real_T Sum;                          /* '<Root>/Sum' */
} B_R2021a_PEM_Canceller_v4_goc_T;

/* Block states (default storage) for system '<Root>' */
typedef struct {
  sNrdkIdWgltdvrJr4R5yRFH_R2021_T AR;  /* '<Root>/Adaptive_Filter' */
  s03vbnB58wVaDS4iGNamMUF_R2021_T AF;  /* '<Root>/Adaptive_Filter' */
  real_T dk_DSTATE[32];                /* '<Root>/dk' */
  real_T ErrorDelayLine_Buff[21];      /* '<Root>/Error Delay Line' */
  real_T dg_hat_DSTATE[16];            /* '<Root>/dg_hat' */
  real_T A_FILT_STATES[21];            /* '<Root>/A' */
  real_T dg_DSTATE[16];                /* '<Root>/dg' */
  real_T FeedbackPath_FILT_STATES[22]; /* '<Root>/Feedback Path ' */
  real_T A1_FILT_STATES[21];           /* '<Root>/A1' */
  real_T FeedbackCanceller_FILT_STATES[22];/* '<Root>/Feedback Canceller' */
  real_T sample_counter;               /* '<Root>/Adaptive_Filter' */
  real_T current_feedback_path;        /* '<Root>/Adaptive_Filter' */
  real_T sumMIS;                       /* '<Root>/AFC_Performance_Monitor' */
  real_T sumASG;                       /* '<Root>/AFC_Performance_Monitor' */
  real_T nSamples;                     /* '<Root>/AFC_Performance_Monitor' */
  struct {
    void *TimePtr;
    void *DataPtr;
    void *RSimInfoPtr;
  } FromWorkspace_PWORK;               /* '<S6>/From Workspace' */

  int32_T ErrorDelayLine_BUFF_OFFSET;  /* '<Root>/Error Delay Line' */
  int32_T A_CIRCBUFFIDX;               /* '<Root>/A' */
  int32_T FeedbackPath_CIRCBUFFIDX;    /* '<Root>/Feedback Path ' */
  int32_T A1_CIRCBUFFIDX;              /* '<Root>/A1' */
  int32_T FeedbackCanceller_CIRCBUFFIDX;/* '<Root>/Feedback Canceller' */
  struct {
    int_T PrevIndex;
  } FromWorkspace_IWORK;               /* '<S6>/From Workspace' */

  uint8_T ToAudioDevice_AudioDeviceLib[1096];/* '<Root>/To Audio Device' */
  uint8_T Counter_Count;               /* '<Root>/Counter' */
  boolean_T AF_not_empty;              /* '<Root>/Adaptive_Filter' */
  boolean_T feedback_path_changed;     /* '<Root>/Adaptive_Filter' */
} DW_R2021a_PEM_Canceller_v4_go_T;

/* Zero-crossing (trigger) state */
typedef struct {
  ZCSigState UpdateARModel_Trig_ZCE;   /* '<Root>/Update AR Model' */
} PrevZCX_R2021a_PEM_Canceller__T;

/* Constant parameters (default storage) */
typedef struct {
  /* Expression: g4
   * Referenced by: '<Root>/Constant9'
   */
  real_T Constant9_Value[22];

  /* Pooled Parameter (Mixed Expressions)
   * Referenced by:
   *   '<Root>/Constant6'
   *   '<Root>/Feedback Path '
   */
  real_T pooled3[22];
} ConstP_R2021a_PEM_Canceller_v_T;

/* Real-time Model Data Structure */
struct tag_RTM_R2021a_PEM_Canceller__T {
  const char_T * volatile errorStatus;

  /*
   * Timing:
   * The following substructure contains information regarding
   * the timing information for the model.
   */
  struct {
    uint32_T clockTick0;
    boolean_T stopRequestedFlag;
  } Timing;
};

/* Block signals (default storage) */
extern B_R2021a_PEM_Canceller_v4_goc_T R2021a_PEM_Canceller_v4_goc_B;

/* Block states (default storage) */
extern DW_R2021a_PEM_Canceller_v4_go_T R2021a_PEM_Canceller_v4_goc_DW;

/* Zero-crossing (trigger) state */
extern PrevZCX_R2021a_PEM_Canceller__T R2021a_PEM_Canceller_v4_PrevZCX;

/* Constant parameters (default storage) */
extern const ConstP_R2021a_PEM_Canceller_v_T R2021a_PEM_Canceller_v4__ConstP;

/* Model entry point functions */
extern void R2021a_PEM_Canceller_v4_goc_initialize(void);
extern void R2021a_PEM_Canceller_v4_goc_step(void);
extern void R2021a_PEM_Canceller_v4_goc_terminate(void);

/* Real-time Model object */
extern RT_MODEL_R2021a_PEM_Canceller_T *const R2021a_PEM_Canceller_v4_goc_M;

/*-
 * These blocks were eliminated from the model due to optimizations:
 *
 * Block '<Root>/Scope' : Unused code path elimination
 * Block '<Root>/Scope1' : Unused code path elimination
 * Block '<Root>/Scope2' : Unused code path elimination
 * Block '<Root>/Scope3' : Unused code path elimination
 * Block '<Root>/Scope4' : Unused code path elimination
 * Block '<Root>/Scope5' : Unused code path elimination
 * Block '<Root>/To File' : Unused code path elimination
 * Block '<Root>/To Workspace' : Unused code path elimination
 * Block '<Root>/To Workspace1' : Unused code path elimination
 * Block '<Root>/To Workspace2' : Unused code path elimination
 * Block '<Root>/To Workspace3' : Unused code path elimination
 * Block '<Root>/Manual Switch' : Eliminated due to constant selection input
 * Block '<Root>/Manual Switch1' : Eliminated due to constant selection input
 * Block '<Root>/Manual Switch2' : Eliminated due to constant selection input
 * Block '<Root>/Manual Switch3' : Eliminated due to constant selection input
 * Block '<Root>/2' : Unused code path elimination
 * Block '<Root>/3' : Unused code path elimination
 * Block '<Root>/Random Source' : Unused code path elimination
 * Block '<S5>/From Workspace' : Unused code path elimination
 */

/*-
 * The generated code includes comments that allow you to trace directly
 * back to the appropriate location in the model.  The basic format
 * is <system>/block_name, where system is the system number (uniquely
 * assigned by Simulink) and block_name is the name of the block.
 *
 * Use the MATLAB hilite_system command to trace the generated code back
 * to the model.  For example,
 *
 * hilite_system('<S3>')    - opens system 3
 * hilite_system('<S3>/Kp') - opens and selects block Kp which resides in S3
 *
 * Here is the system hierarchy for this model
 *
 * '<Root>' : 'R2021a_PEM_Canceller_v4_goc'
 * '<S1>'   : 'R2021a_PEM_Canceller_v4_goc/AFC_Performance_Monitor'
 * '<S2>'   : 'R2021a_PEM_Canceller_v4_goc/Adaptive_Filter'
 * '<S3>'   : 'R2021a_PEM_Canceller_v4_goc/Update AR Model'
 * '<S4>'   : 'R2021a_PEM_Canceller_v4_goc/dB Gain'
 * '<S5>'   : 'R2021a_PEM_Canceller_v4_goc/u(n)_Music'
 * '<S6>'   : 'R2021a_PEM_Canceller_v4_goc/u(n)_Speech'
 */
#endif                                 /* R2021a_PEM_Canceller_v4_goc_h_ */

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
