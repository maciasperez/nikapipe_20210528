#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include "read_nika_data.h"
#include "readdata.h"
//#include "cpgplot.h"

int main(int argc, char *argv[]) {
	char *filename;
	char myfile[500];
	//  char list_data[500]="sample subscan I Q dI dQ RF_didq retard 9 F_TONE DF_TONE";
	char list_data[500]="subscan scan el retard 0 ofs_az ofs_el az paral scan_st MJD LST SAMPLE I Q dI dQ RF_didq F_TONE DF_TONE a_masq b_masq k_flag c_position c_synchro A_T_UTC B_T_UTC antxoffset antyoffset anttrackaz anttrackel";
	//char list_data[500]="subscan scan el RF_didq retard 9 ofs_az ofs_el az paral scan_st F_TONE DF_TONE MJD LST SAMPLE B_T_UTC I Q dI dQ a_t_utc";
	//  char list_data[500]="subscan scan el RF_didq retard 9 ofs_az ofs_el az paral scan_st F_TONE DF_TONE MJD LST SAMPLE B_T_UTC I Q dI dQ a_t_utc";
	filename = (char *)  argv[1];
	sprintf(myfile,"%s",filename);
	printf("Reading file  : %s \n",filename);

	int silent =0;
	int length_header=130000;
	int *buffer_header;
	int nb_total_sample=0;
	// READ HEADER CONTAINING INFORMATION FROM THE DATA
	buffer_header = (int *) malloc(sizeof(int) * length_header);

	//============================================================================================
	//==========						READ  NIKA  START							================
	nb_total_sample = read_nika_start(filename,list_data,buffer_header,length_header, silent);
	//==========																	================
	//============================================================================================


	// GET INFOS DATA FROM HEADER

	long idx;

	int nb_detecteurs, nb_boites_mesure, nb_pt_bloc, nb_param_c;
	int nb_param_d,nb_data_communs, nb_data_detecteurs,nb_champ_reglage;
	int nb_brut_periode;
	int idxinvar = 0;

	int idx_param_c;
	//int *idx_param_d = (int *) argv[idxinvar++];
	int buffer_temp_length;
	// char *nom_var_all = (char *)  argv[idxinvar++];

	char *nom_var_all;
	char  *nom_var;


	int  nb_char_nom;
	int version_header;
	int char_nb;
	int idet;

	nb_boites_mesure	= buffer_header[6];
	nb_detecteurs		= buffer_header[7];
	nb_pt_bloc			= buffer_header[8];
	nb_param_c			= buffer_header[13];
	nb_param_d			= buffer_header[14];
	nb_brut_periode		= buffer_header[18];

	nb_data_communs		= buffer_header[19];
	nb_data_detecteurs	= buffer_header[20];
	nb_champ_reglage	= buffer_header[21];
	version_header		= buffer_header[12]/65536;
	if(version_header) char_nb=16;
	else char_nb=8;
	nb_char_nom = char_nb;

	int nb_detecteurs_lu = nb_detecteurs;
	int indexdetecteurdebut = 0;
	buffer_header[2]= indexdetecteurdebut  ; // indice du premier detecteur
	buffer_header[3]= nb_detecteurs_lu     ; // Nombre de detecteurs que l'on voudrait lire



	if (!silent) printf("\n Version header  **** %d **** soit %d char par noms ", version_header,char_nb);
	if (!silent) printf("\n nb_data_communs = %d ", nb_data_communs);
	if (!silent) printf("  nb_data_detecteurs = %d   nsample = %d \n", nb_data_detecteurs, nb_total_sample);
	if(nb_total_sample<1) {
		printf("\n ERROR in Read Nika start ");
		return 1;
	}

	idx_param_c = read_nika_indice_param_c(buffer_header);
	buffer_temp_length = read_nika_length_temp_buffer(buffer_header);


	//=========================   read the name of all the params and data includes in the file    ============================

	nom_var_all = (char *) malloc(sizeof(char)*16*(nb_param_c+nb_param_d+nb_data_communs*2+nb_data_detecteurs*2+nb_detecteurs));

	read_nika_noms_var_all(buffer_header,nom_var_all);
	nom_var = nom_var_all;

	if (!silent) {
		printf ("\n PARAM COMMUNS: \t");
		for (idx=0; idx<nb_param_c; idx++) printf("\n %s = %d \t", nom_var+idx*char_nb,buffer_header[idx_param_c+idx] );
		printf("\n ");
	}
	nom_var += char_nb * nb_param_c;


	if (!silent) {
		printf ("\n PARAM DETECTEURS: \t");
		for (idx=0; idx<nb_param_d; idx++) printf("%s\t", nom_var+idx*char_nb);

		for (idet=0; idet< nb_detecteurs_lu; idet++) {
			printf("\n %s : ", nom_var_all + char_nb * ( nb_param_c + nb_param_d + 2*nb_data_communs + 2*nb_data_detecteurs) + 8*idet);
			for (idx=0; idx<nb_param_d; idx++)	printf(" %d \t",buffer_header[idx_param_c+nb_param_c + idet + idx*nb_detecteurs_lu] );
		}

	}
	nom_var += char_nb*nb_param_d;


	if (nb_data_communs > 0) {
		if (!silent) {
			printf ("\n\n DATA COMMUNS:       \t");
			for (idx=0; idx < nb_data_communs; idx ++) printf("%s\t",nom_var+idx*char_nb);
		}
		nom_var += char_nb*nb_data_communs;
		if (!silent) {
			printf ("\n UNITES DATA COMMUNS: \t");
			for (idx=0; idx < nb_data_communs; idx ++) printf("%s\t",nom_var+idx*char_nb);
		}
		nom_var += char_nb*nb_data_communs;
	}


	if (nb_data_detecteurs > 0) {
		if (!silent) {
			printf ("\n\n DATA DETECTEURS:       \t");
			for (idx=0; idx < nb_data_detecteurs; idx ++) printf("%s\t",nom_var+idx*char_nb);
		}
		nom_var += char_nb*nb_data_detecteurs;
		if (!silent) {
			printf ("\n UNITES DATA DETECTEURS: \t");
			for (idx=0; idx < nb_data_detecteurs; idx ++) printf("%s\t",nom_var+idx*char_nb);
		}
		nom_var += char_nb*nb_data_detecteurs;

	}

	/*
	if (!silent) {
	printf ("\n\n NOMS DETECTEURS: \t");
	 for (idx=0; (idx< nb_detecteurs) && (idx < 10 ); idx++) {
	 //if (idx % 10 == 0) printf("\n");
	 printf("%s\t", nom_var+8*idx);
	 }

	}
	*/

	if (!silent) printf("\n \n");



	//==========================================   READ DATA    ===============================================


	int nb_samples_lu;
	int length_bufferdata = 100000000;

	double *buffer_data;
	int *buffer_periode;
	char *buffer_temp;
	int  buffer_periode_length;

	int maxsample;
	int length_data_per_sample;

	length_data_per_sample = nb_data_communs + nb_data_detecteurs*nb_detecteurs_lu;
	printf("length data per sample:  %d \n",length_data_per_sample);
	maxsample = length_bufferdata / length_data_per_sample;

	buffer_periode_length =  (2 + maxsample/nb_pt_bloc) * nb_brut_periode*nb_detecteurs_lu;

	buffer_data = (double *) malloc(sizeof(double)*length_bufferdata);
	buffer_periode = (int *) malloc(sizeof(int)*buffer_periode_length);
	buffer_temp = (char *) malloc(sizeof(char)*buffer_temp_length);

	if (!silent) printf(" Lecture buffer data : %d kbytes \n",length_bufferdata*8/1000);
	if (!silent) printf(" Lecture buffer temp : %d kbytes \n",buffer_temp_length/1000);
	if (!silent) printf(" Lecture buffer data : %d samples \n",length_bufferdata/length_data_per_sample);

	nb_samples_lu = 1;

	// WE READ THE DATA BY CHUNCKS AND STORE THEM INTO AN STRUCTURE
	struct nika_data {
		// Common data
		double *sample;
		double *subscan;

		// Per detector data
		double **I;
		double **Q;
		double **dI;
		double **dQ;
		double **RF_didq;
	} myowndata={NULL, NULL, NULL, NULL, NULL, NULL, NULL};



	// Common data
	myowndata.sample  = (double *) malloc(sizeof(double)*nb_total_sample);
	myowndata.subscan = (double *) malloc(sizeof(double)*nb_total_sample);

	// Per detector data
	int i;
	myowndata.I = (double ** ) malloc(sizeof(double)*nb_detecteurs_lu);
	for( i = 0; i < nb_detecteurs_lu; i++) (myowndata.I)[i] = (double *) malloc(sizeof(double)*nb_total_sample);

	myowndata.Q = (double ** ) malloc(sizeof(double)*nb_detecteurs_lu);
	for( i = 0; i < nb_detecteurs_lu; i++) (myowndata.Q)[i] = (double *) malloc(sizeof(double)*nb_total_sample);

	myowndata.dI = (double ** ) malloc(sizeof(double)*nb_detecteurs_lu);
	for( i = 0; i < nb_detecteurs_lu; i++) (myowndata.dI)[i] = (double *) malloc(sizeof(double)*nb_total_sample);


	myowndata.dQ = (double ** ) malloc(sizeof(double)*nb_detecteurs_lu);
	for( i = 0; i < nb_detecteurs_lu; i++) (myowndata.dQ)[i] = (double *) malloc(sizeof(double)*nb_total_sample);

	myowndata.RF_didq = (double ** ) malloc(sizeof(double)*nb_detecteurs_lu);
	for( i = 0; i < nb_detecteurs_lu; i++) (myowndata.RF_didq)[i] = (double *) malloc(sizeof(double)*nb_total_sample);

	printf("Allocating memory OK \n");


	long isample =0;
	int ikiddata;
	int4 *liste_detecteur;
	liste_detecteur = (int4 *) malloc(nb_detecteurs_lu*sizeof(int4));
	for (i=0; i < nb_detecteurs_lu; i++) liste_detecteur[i] = (int4) i;
	while(nb_samples_lu > 0) {
		//length_data_per_sample = nb_data_communs + nb_data_detecteurs*nb_detecteurs_lu;

		//   printf("nb_detecteurs_lu: %d \n \n",nb_detecteurs_lu);


		//======================================================================================================================
		//==========						READ  NIKA  SUITE													================
		nb_samples_lu =read_nika_suite(myfile,buffer_header, nb_detecteurs_lu,liste_detecteur,buffer_data,length_bufferdata,buffer_periode,buffer_temp,silent);
		//==========																							================
		//======================================================================================================================

		printf("   Reading %d  sample \n \n",nb_samples_lu);
		for (idx=0; idx < nb_samples_lu; idx++) {

			(myowndata.sample)[idx+isample]  =  buffer_data[idx*length_data_per_sample];

			(myowndata.subscan)[idx+isample] =  buffer_data[idx*length_data_per_sample+1];

			for (idet=0; idet< nb_detecteurs_lu; idet++) {
				ikiddata = 0;
				myowndata.I[idet][idx+isample]  =  buffer_data[idx*length_data_per_sample + nb_data_communs + nb_detecteurs_lu * ikiddata+ idet];
				ikiddata++;
				myowndata.Q[idet][idx+isample]  =  buffer_data[idx*length_data_per_sample + nb_data_communs + nb_detecteurs_lu * ikiddata+ idet];
				ikiddata++;
				myowndata.dI[idet][idx+isample]  =  buffer_data[idx*length_data_per_sample + nb_data_communs + nb_detecteurs_lu * ikiddata+ idet];
				ikiddata++;
				myowndata.dQ[idet][idx+isample]  =  buffer_data[idx*length_data_per_sample + nb_data_communs + nb_detecteurs_lu * ikiddata+ idet];
				ikiddata++;
				myowndata.RF_didq[idet][idx+isample]  =  buffer_data[idx*length_data_per_sample + nb_data_communs + nb_detecteurs_lu * ikiddata+ idet];
				ikiddata++;
			}
		}

		isample += nb_samples_lu;
	}


	// Doing some plots with pgplot!!!

	/*  cpgopen("/XSERVE"); */


	/*  printf("Number of samples lu  : %d \n",isample); */
	/*  printf("First sample %e \n", myowndata.sample[0]); */
	/*  printf("Last sample %e \n", myowndata.sample[1]); */

	/* /\* Label the axes (note use of \\u and \\d for raising exponent). *\/ */

	/*  cpglab("x", "y", "PGPLOT Graph:"); */

	/* /\*  Plot the line graph. *\/ */

	/*  //  cpgline(101, xr, yr); */

	/* /\* Plot symbols at selected points. *\/ */
	/*  float *xdata, *ydata; */
	/*  xdata = (float *) malloc(sizeof(float)*isample); */
	/*  ydata = (float *) malloc(sizeof(float)*isample); */
	/*  int index =0; */


	/*  //  for (idet=0; idet < nb_detecteurs_lu; idet++) { */
	/*  idet=15; */
	/*  for (index=0;index < isample; index++){ */
	/*    xdata[index]=  (float ) (myowndata.sample)[index]; */
	/*    ydata[index]=  (float)  myowndata.RF_didq[idet][index]; */
	/*    //  printf("%f \t %f \n",xdata[index],ydata[index]); */
	/* } */
	/*    // for (index=0;index < isample; index++) xdata[index]=  (float) myowndata.I[idet][index]; */
	/*    // for (index=0;index < isample; index++) ydata[index]=  (float)  myowndata.Q[idet][index]; */

	/*   /\* get min max *\/ */
	/*    double mymin=1e34, mymax=-1e34; */
	/*    for (index=0; index < isample; index++){ */
	/*      if (mymin > ydata[index])  mymin = ydata[index];  */
	/*      if (mymax < ydata[index])  mymax = ydata[index];  */
	/*    } */

	/*    //if (idet==15) cpgenv(myowndata.sample[0], myowndata.sample[isample-1], mymin, mymax, 0, 0); */
	/*    cpgline(isample, xdata, ydata); */
	/*    //}  */
	/* /\* Close the graphics device *\/ */

	/* cpgclos(); */

	//printf("\n end of file   with  %d  sample  \n",isample);
	return isample;
}
