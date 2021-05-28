/********************************************************************************
* File:          Py_read_data.c
* Purpose:       Read nika data
*                Updated from  IDL_read_data.c for Python interface
* Author:        Juan Francisco Macias-Perez
* Date:          28/11/2013
* Last Modified:
*********************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "readdata.h"



//Double * data=0;

int nb_sample = 0;
int status = 0;
int verbose = 0;


//==============================================================================================================================
//==============================================================================================================================

void Py_read_start(char *fichier, char *list_data, int length_header, long *buffer_header, int code_listdet, long *listdet, int *nb_total_sample, int silent) {


	int idx;
	int nmaxdet = 8001;

	if (!silent) printf("\n FICHIER:  %s \n",fichier);
	if (!silent) printf("\n LIST DATA:  %s \n",list_data);
	int4 *mybuffer_header,*mylistdet;
	mybuffer_header = (int4 *) malloc(sizeof(int4)*length_header);
	mylistdet = (int4 *) malloc(sizeof(int4)*nmaxdet);


      	(*nb_total_sample)=read_nika_start(fichier,length_header,mybuffer_header,list_data,code_listdet,mylistdet,silent);

	

	for (idx=0; idx<length_header; idx++) buffer_header[idx] = (long) mybuffer_header[idx];
	for (idx=0; idx<nmaxdet; idx++) {
	  listdet[idx] = (long) mylistdet[idx];
	}
	  //	  printf("%ld \t ",listdet[idx]);
		
	// printf("\n \n");
	//	free(mybuffer_header);
	//free(mylistdet);
	// printf("\n \n nb_boites_mesure: %d \n \n",buffer_header[6]);
	//  printf("\n --------- START OK----------- \n");
};

/* //============================================================================================================================== */
/* //============================================================================================================================== */


void Py_read_infos( int length_header,long *buffer_header,int *idx_param_c, int *buffer_temp_length, char *nom_var_all, int *nb_char_nom, int silent) {
	long idx;

	int nb_detecteurs, nb_boites_mesure, nb_pt_bloc, nb_param_c, nb_param_d,nb_data_communs, nb_data_detecteurs,nb_champ_reglage;

	int idxinvar = 0;
	// char *fichier = (char *)  argv[];
	/*  int *buffer_header = (int *) argv[idxinvar++]; */
	/* int *idx_param_c = (int *) argv[idxinvar++]; */
	/*  int *buffer_temp_length = (int *) argv[idxinvar++]; */
	/* char *nom_var_all = (char *)  argv[idxinvar++]; */
	/* int  *nb_char_nom = (int *) argv[idxinvar++]; */
	/*  int  *silent = (int *) argv[idxinvar++]; */
	int version_header;
	int char_nb;

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

	if (!silent) printf("\n Version header  **** %d **** soit %d char par noms ", version_header,char_nb);
	if (!silent) printf("\n nb_data_communs = %d ", nb_data_communs);
	if (!silent) printf("\n nb_data_detecteurs = %d \n", nb_data_detecteurs);
	if (!silent) printf("\n nb_detecteurs = %d \n", nb_detecteurs);

	int4 *mybuffer_header;
	mybuffer_header = (int4 *) malloc(sizeof(int4) * length_header);
	for (idx=0; idx< length_header; idx++) mybuffer_header[idx] = (int4) buffer_header[idx];

	*idx_param_c = read_nika_indice_param_c(mybuffer_header);
	*buffer_temp_length = read_nika_length_temp_buffer(mybuffer_header);

	//read_nika_noms_var_all(int4* buffer_header,char* nom)


	read_nika_noms_var_all(mybuffer_header,nom_var_all);

	// printf("\n  Finishing reading nom \n");

	if (!silent) {
		printf ("\n PARAM COMMUNS: \t");
		for (idx=0; idx<nb_param_c; idx++) printf("%s\t", nom_var_all+idx*char_nb);
		printf("\n ");
	}
	nom_var_all += char_nb * nb_param_c;


	if (!silent) {
		printf ("\n PARAM DETECTEURS: \t");
		for (idx=0; idx<nb_param_d; idx++) printf("%s\t", nom_var_all+idx*char_nb);
	}
	nom_var_all += char_nb*nb_param_d;


	if (nb_data_communs > 0) {
		if (!silent) {
			printf ("\n\n DATA COMMUNS:       \t");
			for (idx=0; idx < nb_data_communs; idx ++) printf("%s\t",nom_var_all+idx*char_nb);
		}
		nom_var_all += char_nb*nb_data_communs;
		if (!silent) {
			printf ("\n UNITES DATA COMMUNS: \t");
			for (idx=0; idx < nb_data_communs; idx ++) printf("%s\t",nom_var_all+idx*char_nb);
		}
		nom_var_all += char_nb*nb_data_communs;
	}


	if (nb_data_detecteurs > 0) {
		if (!silent) {
			printf ("\n\n DATA DETECTEURS:       \t");
			for (idx=0; idx < nb_data_detecteurs; idx ++) printf("%s\t",nom_var_all+idx*char_nb);
		}
		nom_var_all += char_nb*nb_data_detecteurs;
		if (!silent) {
			printf ("\n UNITES DATA DETECTEURS: \t");
			for (idx=0; idx < nb_data_detecteurs; idx ++) printf("%s\t",nom_var_all+idx*char_nb);
		}
		nom_var_all += char_nb*nb_data_detecteurs;

	}

	if (!silent) {
		printf ("\n\n NOMS DETECTEURS: \t");
		printf ("\n\n nombre dect: %d",nb_detecteurs);
		for (idx=0; (idx< nb_detecteurs) && (idx < 100 ); idx++) {
			//if (idx % 10 == 0) printf("\n");
			printf("%s\t", nom_var_all+idx*8);
		}
	}


	if (!silent) printf("\n \n");
	//	free(mybuffer_header);
};


/* //============================================================================================================================== */
/* //============================================================================================================================== */


//int Py_read_data(char *fichier, int length_header, long *buffer_header, long *liste_detecteur, int length_data, double *buffer_data, int *buffer_periode, char *buffer_temp, int silent) {
int Py_read_data(char *fichier, int length_header, long *buffer_header, long *liste_detecteur, int length_data, double *buffer_data, int *buffer_periode, char *buffer_temp, int silent) {
	long idx;


	int  nb_boites_mesure, nb_pt_bloc, nb_param_c, nb_param_d,nb_data_communs, nb_data_detecteurs,nb_champ_reglage;

	/* int idxvar=0; */
	/* char *fichier = (char *)  argv[idxvar++]; */
	/* int *buffer_header = (int *) argv[idxvar++]; */
	/* int *length_data =  (int *) argv[idxvar++]; */
	/* double *buffer_data = (double *) argv[idxvar++]; */
	/* int *buffer_periode = (int *) argv[idxvar++]; */
	/* char  *buffer_temp = (char *) argv[idxvar++]; */
	/* int  *silent = (int *) argv[idxvar++]; */


	// Obsolete
	// Ici  il faut tenir compte du nombre de detecteurs lu.
	// buffer_data, pour chaque echantillon, tous les parametres commun et puis les
	// parametre detecteurs pour chaque detecteur. NBcommun1 , NBcommun n , NBdata1 _1 .... NBdata1_ndectlu, ....
	// a nombre de samples qui ont ete vraiment lu

	// ENGLISH
	// Here we need to take into account the number of detectors read
	// buffer_data contains, for each sample, all common data and then all detector data for each detector
	// NBcommun1 , NBcommun n , NBdata1 _1 .... NBdata1_ndectlu, ....
	int nb_samples_lu;
	int4 *mybuffer_header;
	int nmaxdet = 8001;
	mybuffer_header = (int4 *) malloc(sizeof(int4)*length_header);
        int4 *mylistdet;
	mylistdet = (int4 *) malloc(sizeof(int4)*nmaxdet);

	for (idx=0; idx<length_header; idx++) mybuffer_header[idx]= (int4) buffer_header[idx];
	 for (idx=0; idx<nmaxdet; idx++){ 
	   mylistdet[idx]= (int4) liste_detecteur[idx]; 
	   //	  printf("%d  \t %ld \n",mylistdet[idx],liste_detecteur[idx]); */
	 } 
 
      	nb_samples_lu =read_nika_suite(fichier,mybuffer_header,mylistdet,buffer_data,length_data,buffer_periode,buffer_temp,silent);
	//printf("\n ");
	for (idx=0; idx<length_header; idx++) buffer_header[idx]= (long) mybuffer_header[idx];
	for (idx=0; idx<nmaxdet; idx++) liste_detecteur[idx]= (long) mylistdet[idx];

	return(nb_samples_lu);
};



/* //============================================================================================================================== */
/* //============================================================================================================================== */


/* int IDL_geo_bcast(int argc, char *argv[]) */
/* { */
/*   int idxvar=0; */
/* int i; */
/* int * nb_detecteurs_lu = (int *) argv[idxvar++]; */
/* int *raw_number  =  (int *) argv[idxvar++]; */
/* int *x_pix  =  (int *) argv[idxvar++]; */
/* int *y_pix  =  (int *) argv[idxvar++]; */
/* printf("\n geo broadcast  %d  elements  \n",*nb_detecteurs_lu); */
/* for(i=0;i<*nb_detecteurs_lu;i++) */
/*     { */
/*     printf("\n  raw num=%d \t xy = %d \t %d ",raw_number[i],x_pix[i],y_pix[i]); */
/*     } */
/* printf("\n \n"); */
/* send_nika_geometrie(* nb_detecteurs_lu,raw_number,x_pix,y_pix); */
/* return 0; */
/* }; */

