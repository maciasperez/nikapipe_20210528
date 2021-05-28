#ifndef _READ_BLOC_H
#define _READ_BLOC_H

//=============================================================================================
//==============	Les prototypes internes qui necessitent a_memoire.h			===============
//=============================================================================================

#include "a_memoire.h"

extern Data_header_shared_memory 	*read_file_header(FILE *file,int print);
extern Data_header_shared_memory 	*read_nom_file_header(char *nom_fich,int print);
extern int		read_file_bloc(Data_header_shared_memory   *dhs,FILE *file,Bloc_standard *blk,long *pos,int max_len,int convert);		// retourne le type du bloc lut (-1 a la fin)
extern int		read_nom_file_bloc(Data_header_shared_memory   *dhs,char *nomfich,Bloc_standard *blk,long *pos,int max_len);		// retourne le type du bloc lut (-1 a la fin)


extern FILE 	*read_header(char *fichier_data,char *liste_data,Data_header_shared_memory   **pt_dhs,int print);
extern Data_header_shared_memory   *cherche_header_fichier(FILE *fich,int print);

extern int		nombre_data_fichier(char *fichier,int type_listdet,int4 *listdet,int print);


#endif
