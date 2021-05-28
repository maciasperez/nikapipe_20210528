
LIB_PATH = ../../C/
LIB_INCLUDE_PATH = ../../C/



# ------------------------------ global variables --------------------------

ALL     = prog_all

CLEAN   = clean

RM	= rm -f

# ------------------------------ variables for F90 --------------------------
GCC	= gcc -fPIC -g
GCC_FLAGS	= 


THIS_PATH = ./
ALL_INCLUDE_PATH = -I${THIS_PATH} -I${LIB_INCLUDE_PATH} 


all: $(ALL)


# ------------------------------- F90 rules ----------------------------



prog_all: base_library main_prog main_exec

base_library: 
	$(GCC) -c ${LIB_PATH}a_memoire.c  ${ALL_INCLUDE_PATH}
	$(GCC) -c ${LIB_PATH}readdata.c  ${ALL_INCLUDE_PATH}
	$(GCC) -c ${LIB_PATH}/brut_to_data.c  ${ALL_INCLUDE_PATH}
	$(GCC) -c ${LIB_PATH}/bolo_unit.c  ${ALL_INCLUDE_PATH}
	#$(GCC) -c ${LIB_PATH}/kid_flag.c  ${ALL_INCLUDE_PATH}
	$(GCC) -c ${LIB_PATH}/rotation.c  ${ALL_INCLUDE_PATH}

main_prog: 
	$(GCC) -c ${THIS_PATH}/comprime10.c  ${ALL_INCLUDE_PATH}

main_exec: base_library main_prog
	$(GCC) -o comprime10.exe *.o ${ALL_LIBRARY} ${ALL_INCLUDE_PATH} -lm

clean:
	$(RM) *.o
	$(RM) comprime10.exe


