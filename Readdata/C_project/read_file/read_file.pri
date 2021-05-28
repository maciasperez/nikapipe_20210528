######################################################################
# ! ! ! ! ! !    read_file.pri    !  !  !  !  !  !  !  
######################################################################


DEFINES += _READ_FILE_

DEPENDPATH +=	../../C    \
		../../../Acquisition/Library/utilitaires	


INCLUDEPATH +=	../../C    \
		../../../Acquisition/Library/utilitaires	


SOURCES +=	../../C/a_memoire.c \
            	../../C/brut_to_data.c \
            	../../C/rotation.c	\
            	../../C/readdata.c	\
            	../../C/readbloc.c	\
        	../../../Acquisition/Library/utilitaires/utilitaires.c \
          	../../../Acquisition/Library/utilitaires/file_util.cpp \
              	../../C/bloc_comprime.c \


#		../../C/bolo_unit.c	\
            	

HEADERS += 	../../C/a_memoire.h \
            	../../C/name_list.h \
            	../../C/def.h \
            	../../C/brut_to_data.h \
          	../../C/rotation.h \
         	../../C/readdata.h	 \
         	../../C/readbloc.h	 \
            	../../C/elvin_structure.h \
         	../../../Acquisition/Library/utilitaires/utilitaires.h \
          	../../../Acquisition/Library/utilitaires/file_util.h \
             	../../C/bloc_comprime.h \
          	../../C/bloc.h \
 

#		../../C/bolo_unit.h	\
            	
