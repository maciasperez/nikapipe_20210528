// List of possible commun data
/* #define _chaines_data_simple  {"sample","t_mac","synchro","sy_flag","sy_per","sy_pha","Bra_mpi", \
		"ofs_X","ofs_Y", "Paral", "Az","El", "MJD_int","MJD_dec","LST","Ra","Dec","t_elvin",\
		"ofs_Az", "ofs_El","ofs_Ra","ofs_Dec","MJD","rotazel", \
		"year","month","day","scan","subscan","scan_st","obs_st","size_x","size_y","nb_sbsc","step_y","speed","tau"}
and adding A, B, C, ..... in front of:
#define _chaines_data_box {"_t_utc","_freq","_masq","_n_inj","_n_mes","_status","_position","_synchro"}
*/

// List of possible detector data
/*
#define _chaines_data_detecteur {"I" , "Q" , "dI" , "dQ"  ,\
        "RF_deco","RF_didq","F_tone","dF_tone",  "amplit", "logampl",	"ap_dIdQ" ,	"ph_IQ",	"ph_rel",	"amp_rel",\
		"k_flag","lg_res",\
		"boloA","boloB","V_bolo","V_brute","V_dac","I_dac",\
		"ds_pha","ds_qua",\
		"X_det",	"Y_det",  "Az_det",	"El_det", "Ra_det",	"Dec_det"}
*/

#include "read_nika_data.h"

int main(int argc, char *argv[])
{
  char *filename;
  char myfile[500];
  char list_data[500]="sample subscan mjd  A_t_utc B_t_utc  I Q dI dQ RF_didq retard 0";
  //char list_data[500]="all";
  filename = (char *)  argv[1];
  sprintf(myfile,"%s",filename);
  printf("\nReading file  : %s ",filename);
 
  //int silent =1;
  int silent =0;
  int length_header=30000;
  int *buffer_header;
  int nb_total_sample;
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
  
  nb_boites_mesure = buffer_header[6];
  nb_detecteurs = buffer_header[7];
  nb_pt_bloc = buffer_header[8];
  nb_param_c = buffer_header[13];
  nb_param_d = buffer_header[14];
  nb_brut_periode =  buffer_header[18];

  nb_data_communs = buffer_header[19];
  nb_data_detecteurs = buffer_header[20];
  nb_champ_reglage = buffer_header[21];
  version_header  = buffer_header[12]/65536;
  if(version_header) char_nb=16;    else char_nb=8;
  nb_char_nom = char_nb;

  int nb_detecteurs_lu = nb_detecteurs;
  int indexdetecteurdebut = 0;
  buffer_header[2]= indexdetecteurdebut  ; // indice du premier detecteur
  buffer_header[3]= nb_detecteurs_lu     ; // Nombre de detecteurs que l'on voudrait lire

  

  //if (!silent) printf("\n Version header  **** %d **** soit %d char par noms ", version_header,char_nb);
//  if (!silent) printf("");	// ???
  if (!silent) printf("\n nb_data_communs = %d   nb_data_detecteurs = %d  nombre_detecteurs:  %d ", nb_data_communs, nb_data_detecteurs,nb_detecteurs_lu);
  printf("nb_sample = %d \n",nb_total_sample);
  if(nb_total_sample<1) {printf("\n ERROR in Read Nika start "); return;}
  idx_param_c = read_nika_indice_param_c(buffer_header);
  buffer_temp_length = read_nika_length_temp_buffer(buffer_header);
 
 
 //=========================   read the name of all the params and data includes in the file    ============================
 
  nom_var_all = (char *) malloc(sizeof(char)*16*(nb_param_c+nb_param_d+nb_data_communs*2+nb_data_detecteurs*2+nb_detecteurs));
	
  read_nika_noms_var_all(buffer_header,nom_var_all);
	nom_var = nom_var_all;

  if (!silent) {
    printf ("\n PARAM COMMUNS: \t");
//start with idx=4 as the 4 firt param contains the name of the experiment
	printf("\nnom experiment : %s",(char*)(buffer_header+idx_param_c));
  for (idx=4; idx<nb_param_c; idx++) printf("\n%s \t=  %d  ", nom_var+idx*char_nb,buffer_header[idx_param_c+idx] );
  printf("\n ");
  }
  nom_var += char_nb * nb_param_c;
  

  if (!silent) {
    printf ("\n PARAM DETECTEURS: \t");
	// I start at idx =2 as the 2 first parametre are used to store the detector name
    printf("\n nom :       type,acqbox,array ");
	for (idx=3; idx<nb_param_d; idx++) printf("%s\t", nom_var+idx*char_nb);
  
	for (idet=0; idet< nb_detecteurs_lu; idet++)
			{
			if(idet>20) break;	// print only the 20 first detectors
			printf("\n%s :  ", nom_var_all + char_nb * ( nb_param_c + nb_param_d + 2*nb_data_communs + 2*nb_data_detecteurs) + 8*idet);
			// the first parameter after the name is always the type that contain :
			idx=2;
			int type = buffer_header[idx_param_c+nb_param_c + idet + idx * nb_detecteurs_lu];
			int typedet =  type &0xffff;
			int acqbox  =  (type>>16) & 0xff;
			int	array	=  (type>>24) & 0x0f;
			printf(" \t%d  ,  %d  , %d ",typedet,acqbox,array);
			for (idx=3; idx<nb_param_d; idx++)	printf("\t %d",buffer_header[idx_param_c+nb_param_c + idet + idx * nb_detecteurs_lu] );
			}

  }
    nom_var += char_nb*nb_param_d;
  
 
  if (nb_data_communs > 0){
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
 

  if (nb_data_detecteurs > 0){
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


  if (!silent) printf("\n \n");

 
 
//==========================================   READ DATA    ===============================================
 

  int nb_samples_lu;
  int length_bufferdata = 5000000;

  double *buffer_data;
  int *buffer_periode;
  char *buffer_temp;
  int  buffer_periode_length;

  int maxsample;
  int length_data_per_sample;

  length_data_per_sample = nb_data_communs + nb_data_detecteurs*nb_detecteurs_lu;
  maxsample = length_bufferdata / length_data_per_sample;

  buffer_periode_length =  (2 + maxsample/nb_pt_bloc) * nb_brut_periode*nb_detecteurs_lu;
 
  buffer_data = (double *) malloc(sizeof(double)*length_bufferdata);
  buffer_periode = (int *) malloc(sizeof(int)*buffer_periode_length);
  buffer_temp = (char *) malloc(sizeof(char)*buffer_temp_length);

  if (!silent) printf("Buffer data : %d samples   -->  %d Megabytes \n",length_bufferdata/length_data_per_sample,length_bufferdata*8/1000000);
  if (!silent) printf("Buffer temp : %d kbytes    --> ",buffer_temp_length/1000);
  
  nb_samples_lu = 1;
  
  // WE READ THE DATA BY CHUNCKS AND STORE THEM INTO AN STRUCTURE
  struct nika_data{
    // Common data
    double * sample;
    double * subscan;
    double * mjd;
    double * A_t_utc;
    double * B_t_utc;

    // Per detector data
    double **I;
    double **Q;
    double **dI;
    double **dQ;
    double **RF_didq;
  } myowndata;


  
  // Common data
  myowndata.sample = (double *) malloc(sizeof(double)*nb_total_sample);
  myowndata.subscan = (double *) malloc(sizeof(double)*nb_total_sample);
  myowndata.mjd = (double *) malloc(sizeof(double)*nb_total_sample);
  myowndata.A_t_utc = (double *) malloc(sizeof(double)*nb_total_sample);
  myowndata.B_t_utc = (double *) malloc(sizeof(double)*nb_total_sample);

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
    
  if (!silent) printf("Allocating memory OK \n");
  

long isample =0;
int ikiddata;
while(nb_samples_lu > 0)
	{
 
//======================================================================================================================
//==========						READ  NIKA  SUITE													================
     nb_samples_lu =read_nika_suite(myfile,buffer_header,buffer_data,length_bufferdata,buffer_periode,buffer_temp,1);
//==========																							================
//======================================================================================================================
 
	if (!silent)     printf("\nNika_suite : Reading %d  sample  ",nb_samples_lu);
	if(!nb_samples_lu)	break;
	if (!silent) 	  printf(" sample %d  subscan %d   mjd=%12.8f  A_t_utc=%8.3f B_t_utc=%8.3f ",(int)buffer_data[0],(int)buffer_data[1],buffer_data[2],buffer_data[3],buffer_data[4]);
	for (idx=0; idx < nb_samples_lu; idx++)
			{
			// here are the data_commun in the order where they appears in the list
			ikiddata = 0;
			(myowndata.sample)[idx+isample]  =  buffer_data[idx*length_data_per_sample + ikiddata];
			ikiddata++;
			(myowndata.subscan)[idx+isample] =  buffer_data[idx*length_data_per_sample + ikiddata];
			ikiddata++;
			(myowndata.mjd)[idx+isample] =  buffer_data[idx*length_data_per_sample + ikiddata];
			ikiddata++;
			(myowndata.A_t_utc)[idx+isample] =  buffer_data[idx*length_data_per_sample + ikiddata];
			ikiddata++;
			(myowndata.B_t_utc)[idx+isample] =  buffer_data[idx*length_data_per_sample + ikiddata];
       
			for (idet=0; idet< nb_detecteurs_lu; idet++)
					{
					// and here the data detector in the order where they appears in the list
					ikiddata = 0;
					myowndata.I[idet][idx+isample]  =  buffer_data[idx*length_data_per_sample + nb_data_communs + nb_detecteurs_lu * ikiddata+ idet];
					ikiddata++;
					myowndata.Q[idet][idx+isample]  =  buffer_data[idx*length_data_per_sample + nb_data_communs + nb_detecteurs_lu * ikiddata+ idet];
					ikiddata++;
					myowndata.dI[idet][idx+isample]  =  buffer_data[idx*length_data_per_sample + nb_data_communs + nb_detecteurs_lu * ikiddata+ idet];
					ikiddata++;
					myowndata.dQ[idet][idx+isample]  =  buffer_data[idx*length_data_per_sample + nb_data_communs + nb_detecteurs_lu * ikiddata+ idet];
					ikiddata++;
					//-- for  RF_dIdQ  we have a delay of 49 poit in the calculation. This shift will take account of this delay --------
					if(idx+isample>=49) myowndata.RF_didq[idet][idx+isample-49]  =  buffer_data[idx*length_data_per_sample + nb_data_communs + nb_detecteurs_lu * ikiddata+ idet];
					ikiddata++;
					}
			}
     
	isample += nb_samples_lu;
	}
if (!silent) printf("  :  end of file   with  %ld  sample  \n\n",isample);
return isample;
}
