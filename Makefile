include ${EPICS_ENV_PATH}/module.Makefile

EXCLUDE_ARCHS += eldk


HEADERS += epicsIOC/IcePAPApp/src/IcePAP.h

SOURCES +=  epicsIOC/IcePAPApp/src/IcePAPAxis.cpp
SOURCES +=  epicsIOC/IcePAPApp/src/IcePAPController.cpp
SOURCES +=  epicsIOC/IcePAPApp/src/IcePAPMain.cpp
