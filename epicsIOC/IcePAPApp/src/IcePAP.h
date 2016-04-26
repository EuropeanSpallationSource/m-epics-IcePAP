/*
  FILENAME...   IcePAP.h
*/

#include "asynMotorController.h"
#include "asynMotorAxis.h"

// No controller-specific parameters yet
#define NUM_VIRTUAL_MOTOR_PARAMS 0

#define AMPLIFIER_ON_FLAG_CREATE_AXIS  (1)
#define AMPLIFIER_ON_FLAG_WHEN_HOMING  (1<<1)
#define AMPLIFIER_ON_FLAG_USING_CNEN   (1<<2)

extern "C" {
  int IcePAPCreateAxis(const char *IcePAPName, int axisNo,
                       int axisFlags, const char *axisOptionsStr);
}

typedef struct {
  unsigned int status;
  int          motorPosition;
} st_axis_status_type;

class epicsShareClass IcePAPAxis : public asynMotorAxis
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
  IcePAPController *pC_;          /**< Pointer to the asynMotorController to which this axis belongs.
                                   *   Abbreviated because it is used very frequently */
  struct {
    st_axis_status_type lastpoll;
    struct {
      const char *externalEncoderStr;
      int axisFlags;
    } cfg;
  } drvlocal;

  void handleStatusChange(asynStatus status);

  asynStatus writeReadACK(void);
  asynStatus setValueOnAxis(const char* var);
  asynStatus setValueOnAxis(const char* var, const char *value);
  asynStatus setValueOnAxis(const char* var, int value);

  asynStatus getValueFromAxis(const char* var, unsigned, char *value);
  asynStatus getValueFromAxis(const char* var, int *value);
  asynStatus getFastValueFromAxis(const char* var, const char *extra, int *value);

  asynStatus enableAmplifier(int);
  asynStatus setIntegerParam(int function, int value);
  asynStatus stopAxisInternal(const char *function_name, double acceleration);

  friend class IcePAPController;
};

class epicsShareClass IcePAPController : public asynMotorController {
  public:
  IcePAPController(const char *portName, const char *IcePAPPortName, int numAxes, double movingPollPeriod, double idlePollPeriod);

  void report(FILE *fp, int level);
  asynStatus writeReadOnErrorDisconnect(void);
  asynStatus writeOnErrorDisconnect(void);

  IcePAPAxis* getAxis(asynUser *pasynUser);
  IcePAPAxis* getAxis(int axisNo);
  protected:
  void handleStatusChange(asynStatus status);
  asynStatus writeInt32(asynUser *pasynUser, epicsInt32 value);

  friend class IcePAPAxis;
};
