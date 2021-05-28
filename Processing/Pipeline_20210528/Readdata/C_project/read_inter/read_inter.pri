######################################################################
# ! ! ! ! ! !    read_file.pri    !  !  !  !  !  !  !  
######################################################################


DEFINES += _READ_FILE_

DEPENDPATH +=	../../C    \
		../../../Acquisition/Library/kani_lib		\
		../../../Acquisition/Library/utilitaires


INCLUDEPATH +=	../../C    \
		../../../Acquisition/Library/kani_lib		\
		../../../Acquisition/Library/utilitaires


SOURCES +=	../../C/a_memoire.c \
            	../../C/rotation.c	\
             	../../C/readbloc.c	\
        	../../../Acquisition/Library/utilitaires/utilitaires.c \
          	../../../Acquisition/Library/utilitaires/file_util.cpp \
             	../../C/bloc_comprime.c \


HEADERS += 	../../C/a_memoire.h \
            	../../C/name_list.h \
            	../../C/def.h \
            	../../C/rotation.h \
         	../../C/readbloc.h	 \
            	../../C/elvin_structure.h \
         	../../../Acquisition/Library/utilitaires/utilitaires.h \
          	../../../Acquisition/Library/utilitaires/file_util.h \
		../../../Acquisition/Library/kani_lib/bloc_nikel.h \
		../../C/bloc_comprime.h \
          	../../C/bloc_nikel.h \
          	../../C/bloc.h \
 
