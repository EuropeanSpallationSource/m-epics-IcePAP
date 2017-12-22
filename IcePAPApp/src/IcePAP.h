/*
FILENAME...   IcePAP.h
*/

#include "asynAxisController.h"
#include "asynAxisAxis.h"

#define AMPLIFIER_ON_FLAG_CREATE_AXIS  (1)
#define AMPLIFIER_ON_FLAG_WHEN_HOMING  (1<<1)
#define AMPLIFIER_ON_FLAG_USING_CNEN   (1<<2)

#define EthercatMCErrString                  "MCUErr"
#define EthercatMCErrRstString               "ErrRst"
#define EthercatMCVelActString               "VelAct"
#define EthercatMCVel_RBString               "Vel-RB"
#define EthercatMCAcc_RBString               "Acc-RB"
#define EthercatMCDec_RBString               "Dec-RB"
#define EthercatMCScalRDBD_RBString          "SCALRDBD-RB"
#define EthercatMCCHLMString                 "ECHLM"
#define EthercatMCCLLMString                 "ECLLM"
#define EthercatMCCHLM_EnString              "ECHLM-En"
#define EthercatMCCLLM_EnString              "ECLLM-En"

extern "C" {
  int IcePAPCreateAxis(const char *IcePAPName, int axisNo,
                       int axisFlags, const char *axisOptionsStr);
}

typedef struct {
  unsigned int status;
  int          motorPosition;
  char         errbuf[256];
} st_axis_status_type;

class epicsShareClass IcePAPAxis : public asynAxisAxis
{
public:
  /* These are the methods we override from the base class */
  IcePAPAxis(class IcePAPController *pC, int axisNo,
                   int axisFlags, const char *axisOptionsStr);
  void report(FILE *fp, int level);
  asynStatus move(double position, int relative, double min_velocity, double max_velocity, double acceleration);
  asynStatus moveVelocity(double min_velocity, double max_velocity, double acceleration);
  asynStatus home(double min_velocity, double max_velocity, double acceleration, int forwards);
  asynStatus stop(double acceleration);
  asynStatus poll(bool *moving);

private:
  IcePAPController *pC_;          /**< Pointer to the asynAxisController to which this axis belongs.
                                   *   Abbreviated because it is used very frequently */
  struct {
    st_axis_status_type lastpoll;
    struct {
      unsigned int dummy   :1;
    }  dirty;

    struct {
      const char *externalEncoderStr;
      int axisFlags;
    } cfg;
    char errbuf[256];
  } drvlocal;

  void handleStatusChange(asynStatus status);

  asynStatus writeReadACK(void);
  asynStatus setValueOnAxis(const char* var);
  asynStatus setValueOnAxis(const char* var, const char *value);
  asynStatus setValueOnAxis(const char* var, int value);

  asynStatus getValueFromAxis(const char* var, unsigned, char *value);
  asynStatus getValueFromAxis(const char* var, int *value);
  asynStatus getVconfigFromAxis(const char* var, int *valid, int *value);
  asynStatus getValueFromAxis(const char* var, double *value);
  asynStatus readBackVelAcc(void);
  asynStatus readBackConfig(void);
  asynStatus readBackSoftLimits(void);
  asynStatus initialPoll(void);
  asynStatus getFastValueFromAxis(const char* var, const char *extra, int *value);

  asynStatus resetAxis(void);
  asynStatus enableAmplifier(int);
  asynStatus setIntegerParam(int function, int value);
  asynStatus setStringParam(int function, const char *value);
  asynStatus stopAxisInternal(const char *function_name, double acceleration);

  friend class IcePAPController;
};

class epicsShareClass IcePAPController : public asynAxisController {
public:
  IcePAPController(const char *portName, const char *IcePAPPortName, int numAxes, double movingPollPeriod, double idlePollPeriod);

  void report(FILE *fp, int level);
  asynStatus writeReadOnErrorDisconnect(void);
  asynStatus writeOnErrorDisconnect(void);
  asynStatus getConfigFromAxis(int axisNo, const char* var, char *buf, size_t buflen);

  IcePAPAxis* getAxis(asynUser *pasynUser);
  IcePAPAxis* getAxis(int axisNo);
  protected:
  void handleStatusChange(asynStatus status);
  asynStatus writeInt32(asynUser *pasynUser, epicsInt32 value);



  /* First parameter */
  int EthercatMCErr_;

  /* Add parameters here */

  int EthercatMCVelAct_;
  int EthercatMCVel_RB_;
  int EthercatMCAcc_RB_;
  int EthercatMCDec_RB_;
  int EthercatMCScalRDBD_RB_;
  int EthercatMCCHLM_;
  int EthercatMCCLLM_;
  int EthercatMCCHLM_En_;
  int EthercatMCCLLM_En_;
  /* Last parameter */
  int EthercatMCErrRst_;

  #define FIRST_VIRTUAL_PARAM EthercatMCErr_
  #define LAST_VIRTUAL_PARAM EthercatMCErrRst_
  #define NUM_VIRTUAL_MOTOR_PARAMS ((int) (&LAST_VIRTUAL_PARAM - &FIRST_VIRTUAL_PARAM + 1))

  friend class IcePAPAxis;
};
