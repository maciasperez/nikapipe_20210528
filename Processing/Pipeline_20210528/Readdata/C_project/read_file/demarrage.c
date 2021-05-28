#include <mq_manip.h>

#include "a_memoire.h"
#include "def.h"
#include "bloc.h"
#include "readdata.h"
#include "file_util.h"

#define _avec_trace_mac


//--   ---   comment rapatrier les fichiers de l'IRAM   avec  scp   --------
//  cd    /Users/archeops/NIKA/Data/test
//  scp -P 2222  nika2@localhost:NIKA/Data/run22_X/X36_2017_04_01/X_2017_04_01_23h57m23_AA_0442_I_4c39.25 ./
char * list_data = "sample  A_t_utc  B_t_utc  E_t_utc  F_t_utc  K_t_utc L_t_utc  A_pps  B_pps  E_pps F_pps  K_pps  L_pps  \
		A_o_pps  B_o_pps  E_o_pps  F_o_pps  K_o_pps  L_o_pps  A_freq B_freq";
//char file[500] = "/Users/archeops/NIKA/Data/test/X_2017_04_01_23h53m55_AA_0440_P_4c39.25";
char file[500] = "/Users/archeops/NIKA/Data/test/X_2017_04_01_23h53m55_AA_0440_P_4c39.25";



void lecture_des_data_pps(Data_header_shared_memory * dhs,double * Data_completes,int4* listdet,int a);
void lecture_des_data_det(Data_header_shared_memory * dhs,double * Data_completes,int4* listdet,int a);
void lecture_des_offset_pps(Data_header_shared_memory * dhs,double * Data_completes,int4* listdet,int a);

void	print_param(Data_header_shared_memory * dhs);
char* header_to_ini(Data_header_shared_memory *dhs,int print_defaut_values);

//#define _lecture_en_une_fois
//#define _cree_fichier_comprime

//#define debug 1
#undef printf

#define _dossier_depart   _dossier_data_interne

// chercher dans la branche 4 :
	//  readdata.c
	//	namelist
	//	read_nika.pro
	//	compile_read_nika

#define	nb_max_fichiers 1000

extern char Argv1[500];


int		readfile(char* fichier,char* liste_data,int type_liste_detecteur);

#define  _max_nbdet 10000

//int		type_liste_detecteur = _liste_detecteurs_kid_pixel;
int		type_liste_detecteur = _liste_detecteurs_not_zero;
//int		type_liste_detecteur = _liste_detecteurs_kid_pixel;

//char * list_data = "sample  ofs_X  ofs_Y  I  Q  dI  dQ  pI pQ   ";
//char * list_data = "sample  A_t_utc  B_t_utc  I  Q  dI  dQ      RF_didq   F_tone    dF_tone    ";
//char * list_data = "sample  A_t_utc  B_t_utc  E_t_utc  F_t_utc  M_t_utc  N_t_utc  O_t_utc  \
		A_pps  B_pps  E_pps  F_pps  M_pps  N_pps  O_pps ";
//        H_pps  I_pps  J_pps  K_pps  L_pps  M_pps  N_pps O_pps  P_pps  Q_pps  R_pps  S_pps  T_pps ";
//char * list_data = "raw ";

//char * list_data = "sample  MJD Az El  ofs_X  ofs_Y  I  q  dI  DQ  F_tone    dF_tone ";
//char * list_data = "sample  MJD  antmjd_dec  antmjdf_dec  C_t_utc D_t_utc ";
//char * list_data = " all ";
//char * list_data = "sample  t_kidA  I   retard 99 ";
//char * list_data = "sample  synchro  Bra_mpi  RF_didq  V_bolo   V_brute                 ";
//char * list_data = "MULTI  sample  t_kidA  msq_A synchro  scan_st  Bra_mpi  V_bolo   V_brute  ofs_X  ofs_Y  I  Q  dI dQ  RF_didq  k_flag retard  20   phaseds  0               ";
//char * list_data = "MULTI sample  t_kidA  t_kidB  freq_A  freq_B  msq_A  msq_B nv_dacA nv_dacB nv_adcA nv_adcB synchro  scan_st scan subscan obs_st size_x size_y nb_sbsc step_y speed Bra_mpi  V_bolo   V_brute  ofs_X  ofs_Y ofs_Az ofs_El ofs_Ra ofs_Dec Az El Ra Dec Paral LST MJD rotazel  I  Q  dI dQ  RF_didq F_tone dF_tone RF_cplx retard  49   phaseds  0 ";

//char * file = "/Users/archeops/NIKA/Data/Y9_2013_11_14_comp10/Y_d013_11_14_05h47m39_0023_O_Mars";
//char * file = "";
//char * file = "/Users/archeops/NIKA/Data/X_2013_12_19_16h32m44_0000_T";
//char * file = "/Users/archeops/NIKA/Data/X_2013_12_20_06h30m18_0000_T";
//char *file = "/Users/archeops/NIKA/Data/X_2013_12_22_09h58m57_0148_O_I20126+4104";
//char *file = "/Users/archeops/NIKA/Data/Y_2013_11_14_22h24m38_0231_O_Uranus";
//char *file = "/Users/archeops/NIKA/Data/X9_2013_11_14/Y_2013_11_14_05h47m39_0023_O_Mars";
//char *file = "/Users/archeops/NIKA/Data/Y_2013_11_14_22h24m38_0231_O_Uranus";
//char *file = "/Users/archeops/NIKA/Data/SampleErreurElvin/reprocessed_files/X_2015_01_28_16h53m29_0129_T_Uranus";
//char *file = "/Users/archeops/NIKA/Data/raw_x27/X27_2015_03_02/X_2015_03_02_12h27m31_man";

//----  fichiers du mac 5   le fichier Y est OK
//char *file = "/Users/archeops/NIKA/Data/raw_XY5/X_2015_03_02_11h12m51_man";
//char *file = "/Users/archeops/NIKA/Data/raw_XY5/Y_2015_03_02_11h27m11_man";

//---- fichier du mac 27		oK pour le fichier Y
//char *file = "/Users/archeops/NIKA/Data/raw_X27/X27_2015_03_02/X_2015_03_02_14h32m09_man";
//char *file = "/Users/archeops/NIKA/Data/raw_Y27/Y27_2015_03_02/Y_2015_03_02_14h32m09_man";
//char file[500] = "/Users/archeops/NIKA/Data/Z_2012_11_19_22h13m53_0196_Crab_t";


//char file[500] = "/Users/archeops/NIKA/Data/W_2016_01_27_17h45m46_A0_0138_L_1803+784";	
		// lecture all det : 31 sec  only 1600 det : 27 sec
//char file[500] = "/Users/archeops/NIKA/Data/test/X_2016_02_01_08h27m10_AA_0090_I_Saturn";	
//char file[500] = "/home/nika2/NIKA/Data/run15_X/X24_2016_01_25/X_2016_01_25_06h52m53_A0_0076_O_Mars";
// lecture all det : 77 sec  only 1600 det : 51 sec
//char file[500] = "/Users/archeops/NIKA/Data/test/X_2016_01_25_06h02m38_A0_0070_O_Mars";
//char file[500] = "/Users/archeops/NIKA/Data/test/X_2016_12_09_05h14m03_AA_0048_P_3C273";
//char file[500] = "/Users/archeops/NIKA/Data/test/X_2014_02_24_14h03m06_0012_L_Uranus";
// test avec 1600 premiers detecteur
// fichier complet sans conversion   4.5 sec	+convert 11 sec   + brut_to_data  42 sec
// fichier mini sans conversion      1.9 sec	+convert 1.9 sec  + brut_to_data  27 sec

// test avec limite le calcul de brut_to_data aux detecteurs de la liste
// fichier complet 1600 det			34 sec
// fichier mini    1600 det			19 sec

// avec calcul du rfdidq
// fichier complet 800 det		35->22 sec   8000 det :  66->82 sec 
// fichier mini    800			20->12 sec   8000 det :	 49->63 sec
/****************************************************
*                     DEMARRAGE                     *
****************************************************/
void demarrage(void)
{ 
char dossier_depart[4024];
char  filtre[50];
char** noms_fichiers;
int nb_fichiers;
int i;
//FILE * log;
printf("\n**********   read file     ********************\n");
ReadDefaultPaths(NIKA_INI);

#ifdef _avec_trace_mac
nouveauD(5,mgraphicType,"test_data_brutes",0);	// ouvre une fenetre graphique pour
printf("\n  ouverture fenetre de trace ");
#endif

if(strlen(Argv1)>10) strcpy(file,Argv1);
if(strlen(file)>1)	{readfile(file,list_data,type_liste_detecteur);	return;}

fe_tailles(main_ref,10,10);
//-------------------  test   divers   --------------------------------------
//for(i=0;i<255;i++) {if(i%16==0) printf("\n");printf("%x:%c   ",i,i);}//return;
//printf (" %ld",undef_int4);return;


//--------------------   malloc  -------------------------------------------------

noms_fichiers = (char**) malloc (nb_max_fichiers * sizeof(char*) );
for(i=0;i< nb_max_fichiers;i++)		noms_fichiers[i] = (char*) malloc(1024);

//--------------------   demande du nom de dossier et de fichier a relire   ------------------------

//retourne_dossier_app(dossier_depart);
//strcat (dossier_depart,_dossier_depart);			//printf("dossier depart  = %s ",dossier_depart);

strcpy(dossier_depart,_dossier_depart);

sprintf(filtre,"W_* X_* Y_* Z_*");	// cherche les fichiers type  Y (sans les zero) ou type z
printf("\n recherche de fichier dans le dossier %s ",dossier_depart);
nb_fichiers = select_liste_fichiers(dossier_depart,filtre, noms_fichiers,nb_max_fichiers) ;

for(i=0;i<nb_fichiers;i++)	printf("\n  fichier : %s ",noms_fichiers[i]);
printf("\n fin de la liste des fichiers   \n");
 

for(i=0;i<nb_fichiers;i++)	readfile(noms_fichiers[i],list_data,type_liste_detecteur);

printf("\n\n***********************  fin de lecture des fichiers  **********************\n\n");
for(i=0;i< nb_max_fichiers;i++)		free(noms_fichiers[i]);
free(noms_fichiers);

}


int Tm=0;
int	readfile(char* fichier,char* liste_data,int code_listdet)  // read a raw nika file
{
double * Data_completes;

int length = 200000;
int4 * buffer_header = malloc(length*sizeof(int4));
int silent=1;	
#ifdef debug
	silent=0;
#endif
Tm=millisec_utc();
printf("\n readfile avec le fichier : %s ",fichier);

int4* listdet=malloc(sizeof(int4)*_max_nbdet+1);listdet[0]=_max_nbdet;
int nsample= read_nika_start(fichier,length,buffer_header,liste_data,code_listdet,listdet,silent);


if(nsample<1) {printf("\n error in reading the file %s ",fichier);return 0;}

printf("\n read_nika_start   %d  sample   liste det = %d ",nsample,listdet[0]);



Data_header_shared_memory * dhs = (Data_header_shared_memory * ) buffer_header ;

#ifdef debug
	//print_param(dhs);
#endif

//position_header(dhs,1);	// si l'on veut afficher le header


int length_data_par_sample = dhs->nb_data_c + dhs->nb_data_d * listdet[0] ;

int memoire_demandee=length_data_par_sample * nsample;

printf("\n  nb_detecteurs_lut=%d   data commun=%d  data_detecteur=%d   length_data_par_sample=%d  \n",listdet[0],dhs->nb_data_c,dhs->nb_data_d,length_data_par_sample);

#ifdef _lecture_en_une_fois

memoire_demandee = memoire_demandee*12/10;	// + 20% !!
Data_completes = malloc( sizeof(double)* memoire_demandee);

nsample=read_nika_suite(fichier,(int4*)dhs,listdet, Data_completes, memoire_demandee,0,0,1);

printf("\nlecture de    %d  sample  ", nsample );

#else


memoire_demandee = memoire_demandee/3;
printf("\n memoire demandee = %d ",memoire_demandee);
Data_completes = malloc( sizeof(double)* memoire_demandee);

nsample=0;
int a=1;
while (a>0)
		{
		//printf("\n read_nika_suite %d detecteurs ",listdet[0]);
		a=read_nika_suite(fichier,(int4*)dhs,listdet, Data_completes, memoire_demandee,0,0,silent);
		nsample+=a;
		//printf(" : %d detecteurs  %d sample (total=%d)  :",listdet[0],a,nsample);
		
        //lecture_des_data_pps(dhs,Data_completes,listdet,a);
        lecture_des_offset_pps(dhs,Data_completes,listdet,a);

//        lecture_des_data_det(dhs,Data_completes,listdet,a);
		//printf("\t %d  : data =  %g , %g , %g , %g , %g ",(int)Data_completes[0]
		//			,Data_completes[1],Data_completes[2],Data_completes[3],Data_completes[4],Data_completes[5] );
//--- ici on affiche les elements de la liste demandee dans l'ordre de la liste

//--- affichage des temps en millisecondes
		//int debut=(int)Data_completes[1]*86400.*1e3;
/*		printf("\t %d  : data =  %d , %d , %d , %d , %d ",(int)Data_completes[0],
					(int)Data_completes[1],
					(int)Data_completes[2],
					(int)Data_completes[3],
					(int)Data_completes[4],
					(int)Data_completes[5] );
*/
//					(int)(Data_completes[1]*86400.*1e3)-debut,
//					(int)(Data_completes[2]*864.*1e-4)-debut,
//					(int)(Data_completes[3]*864.*1e-4)-debut,
//					(int)(Data_completes[4]*1000)-debut,
//					(int)(Data_completes[5]*1000)-debut  );
		}
//	le tableau Data_completes contient pour chaque sample, les data communs
//	suivit des data du premier data detecteur pour chaque detecteur lut,
//	puis le data dectecteur suivant, ainsi de suite

#endif
Tm=millisec_utc()-Tm;

printf("\n\n----------------   duree =  %6.3f  --------------- \n\n",0.001*(double)Tm);

free(dhs);
free(Data_completes);

printf("\n--------------------------------------------   fin de  readfile()    ------------- \n ");

return nsample;		// le nb d'echantillons du fichier fits ou le code d'erreur de read_file (negatif)
}


void lecture_des_data_det(Data_header_shared_memory * dhs,double * Data_completes,int4* listdet,int a)
{
int i,j;
double* datac=malloc(1000);
double* datad=malloc(dhs->nb_data_d * listdet[0]*sizeof(double));
// ici les donnees sont rangees par sample
// pour chaque sample on a  les datac (nb_data_c) puis les datad de chaque detecteur (dhs->nb_data_d * listdet[0])
// dans chaque bloc, les data commune sont ecrites en :
int length_data_par_sample = dhs->nb_data_c + dhs->nb_data_d * listdet[0] ;

//printf("\n -----   listdet(0) = %d  dhs->nb_data_c=%d dhs->nb_data_d=%d   ",listdet[0],dhs->nb_data_c,dhs->nb_data_d);
// lecture des data_detecteurs
int ndet = 6;   // attention c'est le 5 dans la liste des detecteurs de type non nul
double y[5];
ndet=10;
for(i=1;i<a-1;i++)
				{
				for(j=0;j<dhs->nb_data_c;j++)
						{
						datac[j] = Data_completes[i*length_data_par_sample + j];
                        }
				for(j=0;j<dhs->nb_data_d * listdet[0];j++)
						{
						datad[j] = Data_completes[i*length_data_par_sample + dhs->nb_data_c + j];
                        }
                if(i==1) printf("\n sample=%d : I=%d Q=%d dI=%d dQ=%d pI=%d pQ=%d  ",(int)datac[0],
                                (int)datad[ndet],(int)datad[ndet+listdet[0]],
                                (int)datad[ndet+2*listdet[0]],(int)datad[ndet+3*listdet[0]],
                                (int)datad[ndet+4*listdet[0]],(int)datad[ndet+5*listdet[0]]);
                // trace les ofset X et Y
                y[0] = datac[1];
                y[1] = datac[2];
                //y[0] = datad[ndet+1*listdet[0]];
                //y[1] = datad[ndet+2*listdet[0]];
                tracen(5,2,datac[0],y);
				}
free(datac);
free(datad);
}


// calculer   temps_ut*864/10 + offset_pps en long pour avoir des microsecondes
void lecture_des_offset_pps(Data_header_shared_memory * dhs,double * Data_completes,int4* listdet,int a)
{
int i,j;
double datac[100];
// dans chaque bloc, les data commune sont ecrites en :
double ofg=86035;   // ofset de depart en secondes
int osp=882972;   // sample de depart
//double ech =  41.94304;   // echantillonage en millisec:  1000/(500e6/2^19/40):41.943
double ech = 40. * 262144. * 2.  / 500000.;
double y[20];  

#define _nb_utc 6
#define nb_board 6
printf("\n  dhs->nb_data_c = %d ",dhs->nb_data_c);

int length_data_par_sample = dhs->nb_data_c + dhs->nb_data_d * listdet[0] ;

	for(i=0;i<a-1;i++)
				{
				int nul=0;
				for(j=0;j<dhs->nb_data_c;j++)
						{
						datac[j] = Data_completes[i*length_data_par_sample + j];
						//if( (j>8) && (datac[j]<100) )  nul=1;
						}
							
				
				if(nul==0)
					{
					//printf("\nsample=%7.0f  A_t_utc=%8.3f : A_o_pps1=%6.3f  t_pps= %6.3f -> ",datac[0],
                    //                    (datac[1]-ofg)*1000,datac[8]/1000, (datac[1]-ofg)*1000+datac[8]/1000);
                    int smp=datac[0]-osp;
                    double tsp = (double)smp*ech-450;       // en millisecondes
					//printf("\nsample=%d  --> ",smp);
					//if(datac[nb_board+1]&&datac[nb_board+2]&&datac[nb_board+3]&&datac[nb_board+4])
						{
						printf("\nsample=%d  utc=%8.0f sec --> ",smp,datac[1]);
						for(j=0;j<_nb_utc;j++)
							{
							double utc=datac[1+j]-ofg;		// utc en seconde
                            double topps = datac[2*nb_board+1+j]-ofg;		// _o_pps  en seconde
							printf("    tutc=%6.3f  opps=%6.3f     ",utc*1000-tsp,topps*1000-tsp  );
							
                            y[2*j]=utc*1000-tsp;
							y[2*j+1]=topps*1000-tsp;
							}
						if( (y[2*j]<100) &&  (y[2*j]>-100) &&  (y[2*j+1]<100) &&  (y[2*j+1]>-100) )
                        tracen(5,2*_nb_utc,(double)smp,y);
                        }
						

                    }
					
				}

}


char* header_to_ini(Data_header_shared_memory *dhs,int print_defaut_values) 
{
char * ss = malloc(4e6);
int p,pp;
sprintf(ss,"\n  print  param  ");
for(p=4; p<dhs->nb_param_c; p++) 		// je saute le nom de l'experience qui est sur 4 mots de 4 octets soit 16 octets total
			{
			char *nom = _sm_nom_param_c(dhs,p);
			int val = _sm_param_c(dhs,p)[0];
			if( (nom[0]<'A') || (nom[0]>'Z') )  sprintf(ss+strlen(ss),"\n  %s  :  %d ",nom,val);
			}

		int z=-1, ndet,array;
//		_defaut_value_param_box;
		for (p=0; p<dhs->nb_champ_reglage; p++)         // les boites dans l'ordre ou elles sont rangees
			{
			if(z != _acqbox_champ_reglage(dhs,p))  // chaque fois que j'aborde une nouvelle boite
				{
				z = _acqbox_champ_reglage(dhs,p);
				//printf("\nBox%c - Champ %d", z+'A', p);
				sprintf(ss+strlen(ss),"\n Box%c", z+'A');
				ndet=_nb_det_box(dhs,z);
				array=_array_box(dhs,z);
				// n'affiche le nombre de detecteurs que pour opera !!!
				if(!strcmp("opera",_sm_nom_champ_reglage(dhs,p)+1)) sprintf(ss+strlen(ss),"\n _nb_detector= %d ", ndet);
				sprintf(ss+strlen(ss),"\n_array = %d ", array);
				//----  ecriture des parambox en n'affichant pas ceux qui contiennet les defaut_values
				for (pp=4; pp<dhs->nb_param_c; pp++)	// je cherche les param de ma boite
 //                   if( (_sm_nom_param_c(dhs,pp)[0]=='A'+z) && (_sm_nom_param_c(dhs,pp)[1]=='_') )
					{
					char* nom=_sm_nom_param_c(dhs,pp);
					//if('A'+z == 'D')  printf("\n pp=%d nom=%s ",pp,nom);
					if(nom[0]=='A'+z)
						{
 						int val = _sm_param_c(dhs,pp)[0];
						//if('A'+z == 'D')  printf("dans la boite indiceenum=%d ",indice_enum);
						sprintf(ss+strlen(ss),"\n    %s  %d  ",nom+1,val);
						}
					}
				}
			}

		char Name[100];
		const int ColWidth[20]={6,1,2,9,1,6,2,4,1,1,1,1,1,1,1,1,1,1,1,1}; // Number of characters in each written column. At least 1
		char Frmt[20]; // Format string for printf

		sprintf(ss+strlen(ss), "nom %s", _sm_nom_param_d(dhs,2));
		for(p=3; p<dhs->nb_param_d; p++)
			sprintf(ss+strlen(ss), "%c%s", ' ', _sm_nom_param_d(dhs,p));
 

		for(ndet=0;ndet<dhs->nb_detecteurs;ndet++) {
			//-----   le numero et le nom du detecteur    -----------------
			sprintf(Name,"pd%04d", ndet);
			sprintf(Frmt, "\n%%-%ds", ColWidth[0]);   // Left align the detector name
		   sprintf(ss+strlen(ss), Frmt, _nom_detecteur(dhs,ndet));
			//-----   le type  du detecteur    -----------------
			sprintf(Frmt, "%%c%%%dd", ColWidth[1]); // Generate %c%1d or other number
			sprintf(ss+strlen(ss)," type=%d", _type_det(dhs,ndet));
			//guillaume  sprintf(Str+strlen(Str),Frmt, SEP, _type_det(dhs,ndet));
			//-----   les autres param_d  du detecteur    -----------------
			for (p=3; p<dhs->nb_param_d; p++) {
				sprintf(Frmt, "%%c%%%dd", ColWidth[p-1]); // Generate %c%1d or other number
				sprintf(ss+strlen(ss), Frmt, ' ', _sm_param_d(dhs,p)[ndet]);
			}
		}
	sprintf(ss+strlen(ss),"\n");

	
	return ss;


}


void	print_param(Data_header_shared_memory * dhs)
{
	int param=nouveauD(0, mtexteType, "parametre", 0);
	char s2[1000];
	fe_tailles(param,1000,800);
	fe_positions(param,20,20);
	fe_couleur(param,_rouge);
//    sprintf(s2,  "\n  dhs-> echantillonnage_nano  = %d",    dhs->echantillonnage_nano);      ecritT(param,1,s2);
	sprintf(s2,  "\n  dhs-> nb_boites_mesure      = %d",    dhs->nb_boites_mesure);          ecritT(param,1,s2);
	sprintf(s2,  "\n  dhs-> nb_detecteurs         = %d",    dhs->nb_detecteurs);             ecritT(param,1,s2);
//    sprintf(s2,  "\n  dhs-> nb_champ_reglage      = %d",    dhs->nb_champ_reglage);          ecritT(param,1,s2);
//    sprintf(s2,  "\n  dhs-> nb_pt_bloc            = %d",    dhs->nb_pt_bloc);                ecritT(param,1,s2);
//    sprintf(s2,  "\n  dhs-> nb_brut_periode       = %d",    dhs->nb_brut_periode);           ecritT(param,1,s2);
//    sprintf(s2,"\n\n  dhs-> nb_param_c, nb_param_d= %d, %d",dhs->nb_param_c,dhs->nb_param_d);ecritT(param,1,s2);
//    sprintf(s2,  "\n  dhs-> nb_brut_c, nb_brut_d  = %d, %d",dhs->nb_brut_c, dhs->nb_brut_d); ecritT(param,1,s2);
//    sprintf(s2,  "\n  dhs-> nb_data_c, nb_data_d  = %d, %d",dhs->nb_data_c, dhs->nb_data_d); ecritT(param,1,s2);
	sprintf(s2,"\n ");                                                                     ecritT(param,1,s2);
	printf("\n ----------  header to ini  :  ---------- \n  "); char* ss = header_to_ini(dhs,1);   ecritT(param,1,ss);
	free(ss);
	return;
}









