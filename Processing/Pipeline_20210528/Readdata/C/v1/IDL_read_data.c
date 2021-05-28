/********************************************************************************
* File:          IDL_read_data.c
* Purpose:       Read camera data
*                Updated from main_read_data.c from A. Benoit, et Aurelien.
* Author:        Juan Francisco Macias-Perez
* Date:          01/10/2010
* Last Modified: 31/01/2016	A.Benoit
*********************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "readdata.h"
//#include "../export.h"


//Double * data=0;

int nb_sample = 0;
int status = 0;
int verbose = 0;


//==============================================================================================================================
//==============================================================================================================================
//==============================   READ A RAW NIKA FILE  ================================
//

//  1) allocate a buffer  of typical length_buf_data 1 M byte
//  2) prepare the list of the data you want to read
//          - the list is a caractere string with all the names separated by space
//          - if you want all the data present in the file, put in the list the keyword  all
//			- if you want the raw data present in the fil without calculation, put the keyword  raw
//	3) prepare a detector list with in the first element the maximum number of detector you want (max_nb_det=listdet[0])
//		the following elements contain the detector number you want read or anything if you ask the code to generate the list
//		The length of listdet buffer  is listdet[0]+1  (the table will never be filled with more that this max)
//		the code to generate automaticaly the list is in the file "name_list.h" :
//						enum	{_liste_detecteurs_all=1,_liste_detecteurs_not_zero,_liste_detecteurs_kid_pixel,
//									_liste_detecteurs_kid_pixel_array1,_liste_detecteurs_kid_pixel_array2,_liste_detecteurs_kid_pixel_array3};
//			if you want to gives the list yourself, just put 0 in the code.
//					The list wil be cut if you put in the list some detectors not present in the file

//  4)  CALL THE FUNCTION   IDL_read_start()  with :
//          - fichier			:   the name with full path of the file to read
//          - length_buf_header :   the length of the buffer (number of 4byte words) or length in byte/4
//          - buffer_header		:   a pointer on your buffer
//          - liste_data		:   the list of the data you want
//          - code_listdet		:   the code to generate the detector list
//          - listdet			:   the buffer to store the detector list.
//          - silent			:   if 1 you suppress all printf on the console
//
//  the function return the number of data sample in the file
//  if the function return -2  that mean that the int4 type is not 4 byte long : change the definition of int4 type)
//  if the function return -1 that mean that your buffer is not large enough  : try with a larger buffer
//  after return of the function, the buffer contain all informations about the datas in the file
//  the buffer contain the structure   Data_header_shared_memory

//	5)  CALL THE FUNCTION    IDL_read_infos()  with :   int *buffer_header = (int *) argv[idxinvar++];
//          - buffer_header		:   a pointer on your buffer
//			- idx_param_c			:	return the index of param_c in the buffer_header;
//			- buffer_temp_length	:	return the length of the temporary buffer needed by IDL_read_data
//			- nom_var_all			:	return the index of the place of the data names in the  buffer_header
//			- nb_char_nom			:	return the length of the names (nb of ASCII char)
//          - silent				:   if 1 you suppress all printf on the console

//  6)  CALL RECURSIVELY   THE FUNCTION    IDL_read_data()  until it return  0
//          - fichier			:   the name with full path of the file to read
//          - buffer_header		:   the buffer header returned by the read_nika_start() function
//          - listdet			:   the list of detectors as returned from read_nika_start
//          - buffer_data		:   a pointer to the data buffer
//          - length			:   the length of the data buffer (number of double  words)
//          - buffer_data_periode   :    NULL
//          - buffer_temp		:   for c program use  NULL;
//									for python or IDL gives a buffer with length given by read_nika_length_temp_buffer()
//          - silent			:   if 1 you suppress all printf on the console
//  the function return the number of data sample read in the file before filling the buffer
//  the function return 0  at the end of the file



int IDL_read_start(int argc, char *argv[]) {


	long nb_detecteurs, nb_boites_mesure, nb_pt_bloc, nb_param_c, nb_param_d,nb_data_communs, nb_data_detecteurs,nb_champ_reglage;
	long nb_total_sample,nb_sample_fichier;


	char *fichier = (char *)  argv[0];
	int *length_header = (int *) argv[1];
	int *buffer_header = (int *) argv[2];
	char *liste_data = (char *) argv[3];
	int *code_listdet = (int *) argv[4];
	int *listdet = (int *) argv[5];
	int *silent = (int *) argv[6];

	//printf("\n IDL_read_start() avec silent = %d ",*silent);
	if (!*silent) printf("\n FICHIER:  %s \n",fichier);
	if (!*silent) printf("\n LISTEDATA:  %s \n",liste_data);
	//  printf("\n idl_read_start avant read_nika_start\n");
	nb_total_sample=read_nika_start(fichier,*length_header,buffer_header,liste_data,*code_listdet,listdet,*silent);	//  ======  READ_NIKA_START()  =====

	//  printf("\n idl_read_start passe read_nika_start\n");

	nb_boites_mesure = buffer_header[6];
	nb_detecteurs = buffer_header[7];
	nb_pt_bloc = buffer_header[8];
	nb_sample_fichier = buffer_header[9];
	nb_param_c = buffer_header[13];
	nb_param_d = buffer_header[14];
	nb_data_communs = buffer_header[19];
	nb_data_detecteurs = buffer_header[20];
	nb_champ_reglage = buffer_header[21];


	if (!*silent) printf("\n\n nb_sample_fichier = %ld \n", nb_sample_fichier);

	return nb_total_sample;
};

//==============================================================================================================================
//==============================================================================================================================


int IDL_read_infos(int argc, char *argv[]) {
	long idx;

	int nb_detecteurs, nb_boites_mesure, nb_pt_bloc, nb_param_c, nb_param_d,nb_data_communs, nb_data_detecteurs,nb_champ_reglage;

	int idxinvar = 0;
	// char *fichier = (char *)  argv[];
	int *buffer_header = (int *) argv[idxinvar++];
	int *idx_param_c = (int *) argv[idxinvar++];
	//int *idx_param_d = (int *) argv[idxinvar++];
	int *buffer_temp_length = (int *) argv[idxinvar++];
	char *nom_var_all = (char *)  argv[idxinvar++];
	int  *nb_char_nom = (int *) argv[idxinvar++];
	int  *silent = (int *) argv[idxinvar++];
	int version_header;
	int char_nb;

	//    printf("\n starting\n");

	nb_boites_mesure = buffer_header[6];
	nb_detecteurs = buffer_header[7];
	nb_pt_bloc = buffer_header[8];
	nb_param_c = buffer_header[13];
	nb_param_d = buffer_header[14];
	nb_data_communs = buffer_header[19];
	nb_data_detecteurs = buffer_header[20];
	nb_champ_reglage = buffer_header[21];
	version_header  = buffer_header[12]/65536;
	if(version_header) char_nb=16;
	else char_nb=8;
	*nb_char_nom = char_nb;

	if (!*silent) printf("\n Version header  **** %d **** soit %d char par noms ", version_header,char_nb);
	if (!*silent) printf("\n nb_data_communs = %d ", nb_data_communs);
	if (!*silent) printf("  nb_data_detecteurs = %d \n", nb_data_detecteurs);

	*idx_param_c = read_nika_indice_param_c(buffer_header);							//  ======  READ_NIKA_INDICE_PARAMC()  =====
	*buffer_temp_length = read_nika_length_temp_buffer(buffer_header);				//  ======  READ_NIKA_LENGTH_TEMP_BUFFER()  =====

	//  printf( "coucou\n");

	read_nika_noms_var_all(buffer_header,nom_var_all);								//  ======  READ_NIKA_NOM_VAR_ALL()  =====

	//  printf( "ciao\n");

	if (!*silent) {
		printf ("\n PARAM COMMUNS: \t");
		for (idx=0; idx<nb_param_c; idx++) printf("%s\t", nom_var_all+idx*char_nb);
		printf("\n ");
	}
	nom_var_all += char_nb * nb_param_c;


	if (!*silent) {
		printf ("\n PARAM DETECTEURS: \t");
		for (idx=0; idx<nb_param_d; idx++) printf("%s\t", nom_var_all+idx*char_nb);
	}
	nom_var_all += char_nb*nb_param_d;


	if (nb_data_communs > 0) {
		if (!*silent) {
			printf ("\n\n DATA COMMUNS:       \t");
			for (idx=0; idx < nb_data_communs; idx ++) printf("%s\t",nom_var_all+idx*char_nb);
		}
		nom_var_all += char_nb*nb_data_communs;
		if (!*silent) {
			printf ("\n UNITES DATA COMMUNS: \t");
			for (idx=0; idx < nb_data_communs; idx ++) printf("%s\t",nom_var_all+idx*char_nb);
		}
		nom_var_all += char_nb*nb_data_communs;
	}


	if (nb_data_detecteurs > 0) {
		if (!*silent) {
			printf ("\n\n DATA DETECTEURS:       \t");
			for (idx=0; idx < nb_data_detecteurs; idx ++) printf("%s\t",nom_var_all+idx*char_nb);
		}
		nom_var_all += char_nb*nb_data_detecteurs;
		if (!*silent) {
			printf ("\n UNITES DATA DETECTEURS: \t");
			for (idx=0; idx < nb_data_detecteurs; idx ++) printf("%s\t",nom_var_all+idx*char_nb);
		}
		nom_var_all += char_nb*nb_data_detecteurs;

	}

	if (!*silent) {
		printf ("\n\n NOMS DETECTEURS: \t");
		for (idx=0; (idx< nb_detecteurs) && (idx < 10 ); idx++) {
			//if (idx % 10 == 0) printf("\n");
			printf("%s\t", nom_var_all+idx*8);
		}
	}


	if (!*silent) printf("\n \n");
	return(0);
};


//==============================================================================================================================
//==============================================================================================================================


int IDL_read_data(int argc, char *argv[]) {
//	long idx;
//	int nb_detecteurs, nb_boites_mesure, nb_pt_bloc, nb_param_c, nb_param_d,nb_data_communs, nb_data_detecteurs,nb_champ_reglage;

	int idxvar=0;
	char *fichier = (char *)  argv[idxvar++];
	int *buffer_header = (int *) argv[idxvar++];
	//int *nb_detecteurs_lut = (int *) argv[idxvar++];
	int *liste_detecteur = (int *) argv[idxvar++];

	int *length_data =  (int *) argv[idxvar++];
	double *buffer_data = (double *) argv[idxvar++];
	int *buffer_periode = (int *) argv[idxvar++];
	char  *buffer_temp = (char *) argv[idxvar++];
	int  *silent = (int *) argv[idxvar++];


	// Ici  il faut tenir compte du nombre de detecteurs lu.
	// buffer_data, pour chaque echantillon, tous les parametres commun et puis les
	// parametre detecteurs pour chaque detecteur. NBcommun1 , NBcommun n , NBdata1 _1 .... NBdata1_ndectlu, ....
	// a nombre de samples qui ont ete vraiment lu

	//printf("\n DANS IDL_read_data : nb_detecteurs_lut=%d  ",*nb_detecteurs_lut);
	//printf("\n liste=%d,%d,%d,%d,%d ...",aa[0],aa[1],aa[2],aa[3],aa[4]);
	//printf("\n listedetecteur =%d,%d,%d,%d,%d ...",liste_detecteur[0],liste_detecteur[1],liste_detecteur[2],liste_detecteur[3],liste_detecteur[4]);
	//printf("\n DANS IDL_read_data : length_data=%d   silent=%d.",*length_data,*silent);
	//  ======  READ_NIKA_SUITE()  =====
	int nb_samples_lu =read_nika_suite(fichier,buffer_header,liste_detecteur,buffer_data,*length_data,buffer_periode,buffer_temp,*silent);

	//printf("\n read_nika_suite()  retourne %d sample ",nb_samples_lu);
	//printf("\n ");
	return(nb_samples_lu);
};



//==============================================================================================================================
//==============================================================================================================================


int IDL_geo_bcast(int argc, char *argv[]) {
	int idxvar=0;
	int i;
	int *nb_detecteurs_lu = (int *) argv[idxvar++];
	int *raw_number  =  (int *) argv[idxvar++];
	int *x_pix  =  (int *) argv[idxvar++];
	int *y_pix  =  (int *) argv[idxvar++];
	printf("\n geo broadcast  %d  elements  \n",*nb_detecteurs_lu);
	for(i=0; i<*nb_detecteurs_lu; i++) {
		printf("\n  raw num=%d \t xy = %d \t %d ",raw_number[i],x_pix[i],y_pix[i]);
	}
	printf("\n \n");
	send_nika_geometrie(* nb_detecteurs_lu,raw_number,x_pix,y_pix);
	return 0;
};

