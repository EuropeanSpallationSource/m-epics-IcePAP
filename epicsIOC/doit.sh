#!/bin/sh
APPXX=IcePAP
export APPXX
uname_s=$(uname -s 2>/dev/null || echo unknown)
uname_m=$(uname -m 2>/dev/null || echo unknown)

BASH_ALIAS_EPICS=../../.epics.$(hostname).$uname_s.$uname_m

if ! test -r $BASH_ALIAS_EPICS; then
    echo >&2 "Can not read $BASH_ALIAS_EPICS"
    exit 1
else 
    echo >&2 "Using $BASH_ALIAS_EPICS"
fi

. $BASH_ALIAS_EPICS

if test -z "$EPICS_BASE";then
  echo >&2 "EPICS_BASE" is not set
  exit 1
fi

if ping -c 2 192.168.11.10 >/dev/null; then
  MOTORIP=192.168.11.10
  MOTORPORT=5000
else
  MOTORIP=127.0.0.1
  MOTORPORT=5024
fi

if test -n "$1"; then
  # allow doit.sh host:port
  PORT=${1##*:}
  HOST=${1%:*}
  echo HOST=$HOST PORT=$PORT
  if test "$PORT" != "$HOST"; then
    MOTORPORT=$PORT
  fi
  echo HOST=$HOST MOTORPORT=$MOTORPORT
  echo MOTORIP=$MOTORIP
fi
export MOTORIP MOTORPORT
uname_m=$(uname -m)
uname_s=$(uname -s)
set | grep EPICS_ | sort >.set_${uname_s}_${uname_m}.txt
if ! test -f .set_${uname_s}_${uname_m}.old.txt; then
  make_clean_uninstall=y
  cp .set_${uname_s}_${uname_m}.txt .set_${uname_s}_${uname_m}.old.txt
else
 if ! diff .set_${uname_s}_${uname_m}.old.txt .set_${uname_s}_${uname_m}.txt ; then
   rm -f .set_${uname_s}_${uname_m}.old.txt
 fi
fi

if ! test -d ${APPXX}App; then
  makeBaseApp.pl -t ioc $APPXX
fi &&
if ! test -d iocBoot; then
  makeBaseApp.pl -i -t ioc $APPXX
fi &&

if test -z "$EPICS_HOST_ARCH"; then
  echo >&2 EPICS_HOST_ARCH is not set
  exit 1
fi &&
TOP=$PWD &&
if test -d $EPICS_BASE/../modules/motor/Db; then
  EPICS_MOTOR_DB=$EPICS_BASE/../modules/motor/Db
elif test -d $EPICS_BASE/../modules/motor/db; then
  EPICS_MOTOR_DB=$EPICS_BASE/../modules/motor/db
elif test -d $EPICS_BASE/../modules/motor/dbd; then
  EPICS_MOTOR_DB=$EPICS_BASE/../modules/motor/dbd
else
   echo >&2 Not found: $EPICS_BASE/../modules/motor/[dD]b
   echo >&2 Unsupported EPICS_BASE:$EPICS_BASE
  exit 1
fi &&
if ! test -d "$EPICS_MOTOR_DB"; then
  echo >&2 $EPICS_MOTOR_DB does not exist
  exit 1
fi
(
  cd ${APPXX}App/Db &&
  if test -r ${APPXX}.substitutions.$MOTORIP; then
    substitutionsMOTORIP=${APPXX}.substitutions.$MOTORIP
  else
    substitutionsMOTORIP=${APPXX}.substitutions.default
  fi &&
  touch ${APPXX}.substitutions &&
  chmod +w ${APPXX}.substitutions &&
  echo "#Do not edit: auto-generated from ${APPXX}.substitutions.default" >${APPXX}.substitutions &&
  sed <$substitutionsMOTORIP >>${APPXX}.substitutions \
  -e "s%/usr/local/epics/modules/motor/Db%$EPICS_MOTOR_DB%" &&
  chmod -w ${APPXX}.substitutions
) &&
(
  cd configure &&
  if ! test -f RELEASE_usr_local; then
    git mv RELEASE RELEASE_usr_local
  fi &&
  sed <RELEASE_usr_local >RELEASE \
  -e "s%^EPICS_BASE=.*$%EPICS_BASE=$EPICS_BASE%" &&
  if  test -f MASTER_RELEASE; then
    if ! test -f MASTER_RELEASE_usr_local; then
      git mv MASTER_RELEASE MASTER_RELEASE_usr_local
    fi &&
    sed <MASTER_RELEASE_usr_local >MASTER_RELEASE \
      -e "s%^EPICS_BASE=.*$%EPICS_BASE=$EPICS_BASE%"
  fi
) &&
if test "$make_clean_uninstall" = y; then
  make clean
  make uninstall
  make clean || :
fi &&

make || {
    rm -f .set_${uname_s}_${uname_m}.old.txt
    make clean && make ||  exit 1
}
(
  envPathssrc=./envPaths.empty &&
  envPathsdst=./envPaths.$EPICS_HOST_ARCH &&
  stcmdsrc=./st.cmd &&
  stcmddst=./st.cmd.$EPICS_HOST_ARCH &&
  cd ./iocBoot/ioc${APPXX}/ &&
  if ! test -s "$envPathssrc"; then
    echo PWD=$PWD generating: "$envPathssrc"
    cat >"$envPathssrc" <<-EOF
        #Do not edit, autogenerated from doit.sh
        epicsEnvSet("ARCH","__EPICS_HOST_ARCH")
        epicsEnvSet("IOC","ioc${APPXX}")
        epicsEnvSet("TOP","__TOP")
        epicsEnvSet("EPICS_BASE","__EPICS_BASE")
EOF
  else
    echo PWD=$PWD does exist: "$envPathssrc"
  fi &&
  rm -f $envPathsdst &&
  sed <$envPathssrc >$envPathsdst \
    -e "s/__EPICS_HOST_ARCH/$EPICS_HOST_ARCH/" \
    -e "s!__TOP!$TOP!" \
    -e "s!__EPICS_BASE!$EPICS_BASE!" \
    -e "s/__EPICS_HOST_ARCH/$EPICS_HOST_ARCH/"  &&
  rm -f $stcmddst &&
  sed <$stcmdsrc \
    -e "s/__EPICS_HOST_ARCH/$EPICS_HOST_ARCH/" \
    -e "s/[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*:[0-9]*/$MOTORIP:$MOTORPORT/" \
      | grep -v '^  *#' >$stcmddst &&
  chmod -w $stcmddst &&
  chmod +x $stcmddst &&
  cp $envPathsdst st.gdb.$EPICS_HOST_ARCH &&
  egrep -v "envPaths|APPXX" $stcmddst >> st.gdb.$EPICS_HOST_ARCH
  egrep -v "^ *#" st.gdb.$EPICS_HOST_ARCH >xx

  echo PWD=$PWD $stcmddst
  $stcmddst
)
