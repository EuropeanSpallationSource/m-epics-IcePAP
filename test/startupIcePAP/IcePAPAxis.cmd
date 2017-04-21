
IcePAPCreateAxis("$(MOTOR_PORT)", "$(AXIS_NO)", "$(AXIS_NO)", "encoder=MEASURE")

dbLoadRecords("IcePAP.template", "PREFIX=$(PREFIX), MOTOR_NAME=$(MOTOR_NAME), R=$(R), MOTOR_PORT=$(MOTOR_PORT), ASYN_PORT=$(ASYN_PORT), AXIS_NO=$(AXIS_NO), DESC=$(DESC), PREC=$(PREC), VELO=$(VELO), JVEL=$(JVEL), JAR=$(JAR), ACCL=$(ACCL), MRES=$(MRES), RDBD=$(RDBD), NTMF=$(NTMF), DLLM=$(DLLM), DHLM=$(DHLM), HOMEPROC=$(HOMEPROC)")
