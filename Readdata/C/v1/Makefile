
LIB_PATH = ./
LIB_INCLUDE_PATH = ./



# ------------------------------ global variables --------------------------

ALL     = prog_all

CLEAN   = clean

RM	= rm -f

# ------------------------------ variables for C compiler --------------------------
GCC	= gcc -fPIC -g
#GCC	= clang -fPIC -Ofast -march=native
GCC_FLAGS	= 


THIS_PATH = ./
ALL_INCLUDE_PATH =  -I${THIS_PATH} -I${LIB_INCLUDE_PATH}
EXTERNAL_LIBRARIES =  -lm
EXTERNAL_LIBRARIES_PATH = 
all: $(ALL)


# ------------------------------- F90 rules ----------------------------



prog_all: base_library  python_library lib_shared main_prog main_exec 


base_library: 
	$(GCC) -c ${LIB_PATH}/a_memoire.c  ${ALL_INCLUDE_PATH}
	$(GCC) -c ${LIB_PATH}/brut_to_data.c  ${ALL_INCLUDE_PATH}
	$(GCC) -c ${LIB_PATH}/bolo_unit.c  ${ALL_INCLUDE_PATH}
#	$(GCC) -c ${LIB_PATH}/kid_flag.c  ${ALL_INCLUDE_PATH}
	$(GCC) -c ${LIB_PATH}/rotation.c  ${ALL_INCLUDE_PATH}
	$(GCC) -c ${LIB_PATH}/readdata.c  ${ALL_INCLUDE_PATH}
	$(GCC) -c ${LIB_PATH}/readbloc.c  ${ALL_INCLUDE_PATH}
	$(GCC) -c ${LIB_PATH}/bloc_comprime.c  ${ALL_INCLUDE_PATH}

python_library: 
	$(GCC) -c ${LIB_PATH}/Py_read_data.c  ${ALL_INCLUDE_PATH}


main_prog: 
#	$(GCC) -fwhole-program -c ${LIB_PATH}/read_nika_data.c  ${ALL_INCLUDE_PATH} 

main_exec: base_library main_prog
#	$(GCC) -fwhole-program -o read_nika_data.exe *.o ${ALL_LIBRARY} ${ALL_INCLUDE_PATH} ${EXTERNAL_LIBRARIES_PATH}  ${EXTERNAL_LIBRARIES}
lib_shared: base_library python_library
	$(GCC) -shared -o libreadnikadata.so *.o -flto ${ALL_LIBRARY} ${ALL_INCLUDE_PATH} ${EXTERNAL_LIBRARIES_PATH} ${EXTERNAL_LIBRARIES} 
clean:
	$(RM) *.o
	$(RM) read_nika_data.exe
	$(RM) *.so



