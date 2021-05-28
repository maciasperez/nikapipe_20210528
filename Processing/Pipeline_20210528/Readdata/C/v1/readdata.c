
//#if  defined(_ACQUI_) ||  defined(_TRACE_)	 ||  defined(_NIFITS_)		//-------   dans le mac pour acquisition ou client_trace
#ifdef _MANIPQT_

#include "mq_manip.h"			// pour acquisition et client_trace dans le MAC

#else							// pour les boitiers d'acquisition
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#endif

#include <assert.h>

#include "a_memoire.h"
#include "def.h"

#include "bloc.h"
#include "bloc_comprime.h"

#include "brut_to_data.h"

#include "readbloc.h"
#include "readdata.h"

//#define debug 1
#undef printf

#undef  __BIG_ENDIAN__			// probleme car dans trace, __BIG_ENDIAN__ est defini quelque part !!!!!!


#ifdef __BIG_ENDIAN__
#define  _int4_swap(mot)	{char * cc= (char*) (mot);char a=cc[0];cc[0]=cc[3];cc[3]=a;a=cc[1];cc[1]=cc[2];cc[2]=a;}
#define	 swap_bloc(i)		((i)^3)
#else
#define  _int4_swap(mot)	{}
#define	 swap_bloc(i)		(i)
#endif


//==============================   READ A RAW NIKA FILE  ================================
//
//  1) allocate a buffer  of typical length_buf_data 1 M byte
//  2) prepare the list of the data you want to read
//          - the list is a caractere string with all the names separated by space
//          - if you want all the data present in the file, put in the list the keyword  all
//  3) call the function read_nika_start()  with :
//          - fichier			:   the name with full path of the file to read
//          - length_buf_header :   the length of the buffer (number of 4byte words) or length in byte/4
//          - buffer_header		:   a pointer on your buffer
//          - liste_data		:   the list of the data you want
//          - code_listdet		:   the code to generate the detector list
//          - listdet			:   the buffer to store the detector list.
//											(the first element contain the max number of detectors in the list)
//											(the table will never be filled with more that this max)
//          - silent			:   if 1 you suppress all printf on the console
//
//  the function return the number of data sample in the file
//  if the function return -2  that mean that the int4 type is not 4 byte long : change the definition of int4 type)
//  if the function return -1 that mean that your buffer is not large enough  : try with a larger buffer
//  after return of the function, the buffer contain all informations about the datas in the file
//  the buffer contain the structure   Data_header_shared_memory

//  5) call recursively the function  read_nika_suite()  until it return  0
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



//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
//-------------------------       read_nika  start  et  suite     ------------------------------------
//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------



/************************************************
*            read_nika_start                    *
************************************************/

//  rajoute  type_listdet  pour demander une liste detecteur automatique
//		et  listdet si l'on veut donner la liste des detecteurs
//	le premier element de la liste donne le nombre d'emements de la liste
//    la liste sera retournee dans listdet
int read_nika_start(char *fichier, int length_buf, int4 *buffer_header,
					char *liste_data, int type_listdet, int4 *listdet, int silent) {
	Data_header_shared_memory  *dhs;
	int i,l,nn;


#ifdef debug
	silent=0;
#endif

	assert(sizeof(int4) == 4);
	nn=0;

	//file = read_header(fichier,liste_data,&dhs,!silent);        // this function allocate memory for  dhs
	//if(!file) return 0;
	//fclose(file);

	{
		//for(i=strlen(fichier);i>0;i--)	if(fichier[i]=='/') break;
		//int code_zero = (fichier[i+1]!='Z');
		dhs = read_nom_file_header (fichier,!silent);

		if(!silent) printf("\n\n------------------------------------------------------------------------------------------------------------------------");
		if(!silent) printf("\n|-| Read_file: %s   |-|",fichier);
		if(!silent) printf("\n------------------------------------------------------------------------------------------------------------------------\n");
		if(!dhs) {
			printf("file: %s  IS NOT A RAW NIKA DATA FILE \n",fichier);
			return 0;
		}

#ifdef debug
		printf("\n read_nika_start change_liste  avec liste = %s ",liste_data);
#endif
		dhs = change_liste_data(dhs,liste_data,!silent);						//  fait un realloc de dhs
		// attention: si je retrouve un header dans le fichier, il n'aura pas la bonne longueur   !!!!!!!!
	}

	//if(print) printf(" NB DE DETECTEURS : %d ",dhs->nb_detecteurs);

	//printf("\n read_nika_start  file OK ");
	l=_len_header_complet(dhs)/4;
	if(!silent) printf("\n longueur du header : %d mots de 4 bytes  j'ai reserve %d ",l,length_buf);
	if(length_buf < l) {
		printf("\n\n******  erreur tableau trop petit dans read_nika_start  ");
		printf("\n on a %d int4  alors qu'il en faut  %d ",length_buf,l);
		nn=-1;
	} else {
		//	nn = nombre_data_fichier(fichier,type_listdet,listdet,0) * dhs->nb_pt_bloc;

		//printf("type_listdet  %d \n",type_listdet);
		nn = nombre_data_fichier(fichier,type_listdet,listdet,0) * dhs->nb_pt_bloc;
		dhs->nb_sample_fichier= nn;
		if(!silent)  printf("NOMBRE ECHANTILLONS %d  nb detecteurs liste=%d  \n " , nn,listdet[0]);
		//printf("NOMBRE ECHANTILLONS %d  nb detecteurs liste=%d  \n" , nn,listdet[0]);
		for(i=0; i<l; i++) buffer_header[i] = ((int4 *)dhs)[i];	// copie de dhs dans le buffer donne par IDL

		((long *) buffer_header)[0]=0;		// POSITIONNEMENT AU DEBUT DU FICHIER AU PROCHAIN APPEL DE read nika_suite
	}
	free(_DHP(dhs));		// libere DHP  avant de sortir de read_nika suite
	free(dhs);

	return nn;
}



/************************************************
*            read_nika_suite                    *
************************************************/
// maintenant le parametre listdet[0] contient le nb de detecteurs de la liste des detecteurs

int read_nika_suite(char *fichier,int4 *buffer_header,int4 *listdet,double *buffer_data,int length_buf_data,int *buffer_data_periode,char *buffer_temp, int silent) {
	// ouvrir le fichier, voir s'il faut coder les zero  / se repositionner au bon endroit
	// la place ou il faut lire le fichier est stockee au debut du buffer_header
	// en effet les 4 premiers entiers sont inutilises  !!
	// utiliser   int	 fseek(FILE *, long, int);  et     long	 ftell(FILE *);
	Data_header_shared_memory   *dhs = (Data_header_shared_memory *) buffer_header;
	FILE *file = fopen(fichier,"rb");
	if (file==NULL) printf("BAD FILE \n");
	int n_bloc_lut;
	int i,j,k;
	double *db;
	int length_data_par_sample,sample;
	int size_bloc_standard;
	Bloc_standard *blk;
	int nb_bloc_data;
	int init = (((long *) buffer_header)[0]==0) ;	// init vrai en debut de fichier
	static char *buf_btd = NULL;		// ainsi c'est brut to data qui initialise le buffer
	int  bloc_debut=0;
	int bloc_fin=0;

	#ifdef debug
		position_header(dhs,debug);		// a refaire chaque fos car idl deplace les chses
	#else
		position_header(dhs,0);
	#endif

#ifdef debug
	printf("\n read nika suite %d detecteurs avec position en %ld ",listdet[0],( (long *) buffer_header) [0]);
#endif
	if(buffer_temp) buf_btd=buffer_temp;	// si on donne un buffer, on le prend a la place de celui cree par brut to data
	for(i=strlen(fichier); i>0; i--)	if(fichier[i]=='/') break;


	//----  au lieu de ca, je passe la position en clair a read_file bloc
	//code_zero = (fichier[i+1]!='Z');
	//fseek(file,( (long*) buffer_header) [0],SEEK_SET);		// ofset par rapport au debut du fichier
	long pos_fich = ((long *) buffer_header) [0] ;

	//  calculer le nombre de blocs pour ne pas depasser la longueur length_buf_data dans le tableau buffer_data
	// nb de doubles un bloc data :
	//			(Dhs)->nb_pt_bloc * (Dhs)->nb_data_c
	//		+	(Dhs)->nb_pt_bloc * (Dhs)->nb_detecteurs * (Dhs)->nb_data_d
	//		+	(Dhs)->nb_brut_periode * (Dhs)->nb_detecteurs ) )


	length_data_par_sample = dhs->nb_data_c + dhs->nb_data_d * listdet[0] ;
#ifdef debug
	printf("\nread_nika_suite:  %d data_c  %d data_d et %d detecteurs soit %d data/sample ",dhs->nb_data_c,dhs->nb_data_d,listdet[0],length_data_par_sample);
#endif

	nb_bloc_data  =  length_buf_data / (dhs->nb_pt_bloc * length_data_par_sample )   -1;
#ifdef debug
	printf("\n  memoire %d soit %d  blocs de data ",length_buf_data,nb_bloc_data);
	//printf("\n********* nb pt bolc=%d   nb data_c=%d  nb_data_d = %d  nb detecteurs=%d (lut %d a partir de %d ) ",
	//    dhs->nb_pt_bloc,dhs->nb_data_c,dhs->nb_data_d,dhs->nb_detecteurs,listdet[0],debut_detecteurs);
	//printf("\n********* je cherche a lire %d blocs de data en demarrant a l'ofset %ld  \n\n",nb_bloc_data,( (long*) buffer_header) [0]);
#endif

	db = (double *) malloc( sizeof(double) * _len_data_bloc_shared_memory(dhs)) ;		// reserve pour la lecture le db pour un bloc de data
	size_bloc_standard = _len_brut_bloc_shared_memory(dhs) + sizeof(Bloc_standard) ;
	// printf("size_bloc_standard %ld",size_bloc_standard);

	blk=(Bloc_standard *)malloc(size_bloc_standard);
	// printf("blk %x",blk);
#ifdef debug
	printf("\n  size  Bloc_standard  =  %d  ",size_bloc_standard);
#endif
	sample=0;
	for(n_bloc_lut=0; n_bloc_lut<nb_bloc_data;) {	//------------  boucle sur la lecture des blocs dans le fichier  ----------------------------
		//int type = read_file_bloc(dhs,file,blk,&pos_fich,size_bloc_standard,1);	// converti comp et mini en brut
		int type = read_file_bloc(dhs,file,blk,&pos_fich,size_bloc_standard,0); // sans conversion
		int num = numero_bloc(blk);

		//printf("type =  %d ,type);
		//if(type==block_header)				printf("\n block_header");

		if(type>=bloc_reglage ) {
			int		z	= type - bloc_reglage;
			uint4 *RG	= reglage_pointer(dhs,-1,z);
			if(RG) memcpy(RG,blk->data,nb_elements_reglage_partiel(dhs,z)*4);
		}


		if(type==bloc_comprime8 ) {	// converti le bloc comprime en bloc brut
			decomprime8(dhs,blk->data);
			_valide_bloc(dhs,blk,bloc_brut,numero_bloc(blk) );
			type=bloc_brut;
		}

		if(type==bloc_comprime10 ) {	// converti le bloc comprime en bloc brut sur place
			decomprime10(dhs,blk->data);
			_valide_bloc(dhs,blk,bloc_brut,numero_bloc(blk) );
			type=bloc_brut;
		}
		if(type==bloc_comprime10d ) {	// converti le bloc comprime en bloc brut sur place
			decomprime10d(dhs,blk->data);
			_valide_bloc(dhs,blk,bloc_brut,numero_bloc(blk) );
			type=bloc_brut;
		}
		if(type==bloc_mini ) {	// converti en bloc brut sur place
			int num=numero_bloc(blk);
#ifdef debug
			printf("\n bloc mini num=%d ",num);
#endif
			/*			if(liste_det2==NULL ) liste_det2=cree_list_det(dhs,liste_det2,type_liste_detecteur,liste_detecteurs,blk->data);
			*/			bloc_mini_to_bloc_brut(dhs,blk->data);
			_valide_bloc(dhs,blk,bloc_brut,num );
			type=bloc_brut;
		}

		//if( (type == bloc_brut) ||  (type == bloc_mini) ||   (type == bloc_comprime8) ||   (type == bloc_comprime10) ||   (type == bloc_comprime10d) )
		if(type == bloc_brut) {
			//printf("BLOC_BRUT \n");
#ifdef debug
			printf(" bloc  : NUM BLOC %d  datasample0=%d \n",num,blk->data[0]);
#endif
			/*		if(liste_det2==NULL) liste_det2=cree_list_det(dhs,liste_det2,type_liste_detecteur,liste_detecteurs,NULL);

			*/		if(!bloc_debut)		{
				bloc_debut=num;
				bloc_fin=num-1;
				//	  printf("bloc_Debut %d \n",bloc_debut);
			}
			if (num!=bloc_fin+1) {
				printf("\n erreur numerotation :   blocprecedent=%d   lut=%d    ====>  %d blocs manquants  \n",
					   bloc_fin,num,num-bloc_fin-1);
			}

			bloc_fin=num;
#ifdef debug
			if( (num%10)==0 )  printf("\n num=%d   ",num);
#endif
			init=0;
			n_bloc_lut++;

			if(type == bloc_brut) {
				brut_to_data(dhs,blk->data,db,listdet,buf_btd,!silent);		//  calcule les data en double dans db a partir des data brut dans Br
				//printf("\n brut_to_data finished \n");
				for(i=0; i<dhs->nb_pt_bloc; i++) {
					for(j=0; j<dhs->nb_data_c; j++)
						buffer_data[sample*length_data_par_sample + j]=  _data_ec(dhs,db,j,i);
					//	printf("\n Data commun OK \n");
					for(j=0; j<dhs->nb_data_d; j++)
						for(k=0; k<listdet[0]; k++) {
							//		  printf("\n %d - %d \n",j,k);
							// printf("\n buffer_data position:  %d",sample*length_data_par_sample + dhs->nb_data_c + j*listdet[0] + k);
							// printf("\n results : %f \n", _data_ed(dhs,db,j,i)[debut_detecteurs+k]);
							buffer_data[sample*length_data_par_sample + dhs->nb_data_c + j*listdet[0] + k]
								= _data_ed(dhs,db,j,i)[listdet[k+1]];
							//									= _data_ed(dhs,db,j,i)[listdet[k]];
							//if( (j==4) && (k==10) ) printf("  %g ",_data_ed(dhs,db,j,i)[debut_detecteurs+k]);//ab
							//if( (j==4) && (k==10) ) printf(" col=%d   det=%d ",j,debut_detecteurs+k);
						}
					//	printf("\n Data detectors OK \n");

					sample++;
				}

				// a la fin du buffer je rajoute les data periode si Dhs->nb_brut_periode >10
				// printf("\nDoing buffer periode \n ");
				if(buffer_data_periode) {
					for(k=0; k<listdet[0]; k++)
						for(j=0; j<dhs->nb_brut_periode; j++)
							buffer_data_periode[n_bloc_lut*listdet[0]*dhs->nb_brut_periode + k*dhs->nb_brut_periode + j]
							//						  = _data_periode(dhs, db, listdet[k])[j]; // MODIF JUAN
								= _data_periode(dhs, db, listdet[k+1])[j]; // MODIF JUAN
				}
			} else  sample += 36;
		}
		if(type<=0) break;
	}

	//if( !silent )  printf("\n nika suite bloc de %d  a %d  ",bloc_debut,bloc_fin);
	free(db);
	free(blk);
	free(_DHP(dhs));		// libere DHP  avant de sortir de read_nika suite

	// marquer la position courante du  fichier dans le header puis fermer le fichier
	//( (long*) buffer_header) [0]  =  ftell(file);
	((long *) buffer_header) [0]  =  pos_fich;
	fclose(file);

	/*
	if((!silent) && (!sample))
		{
		printf("\n\n FIN DE READ NIKA SUITE : JE SORT LE HEADER \n\n");
		position_header(dhs,1);
		free(_DHP(dhs));
		}
	*/
#ifdef debug
	printf("\n NIKA_SUITE  a  lut  %d  sample ",sample);
#endif
	return sample;
}



/************************************************
*            read_nika_divers  .....            *
************************************************/



int read_nika_length_temp_buffer(int4 *buffer_header) {
	Data_header_shared_memory  *dhs= (Data_header_shared_memory *) buffer_header;

	return _total_length_buf_btd;
}



int  read_nika_indice_param_c(int4 *buffer_header) {
	Data_header_shared_memory  *dhs= (Data_header_shared_memory *) buffer_header;
	return   (_len_infos_reglage_param_shared_memory(dhs) + _len_reglage_shared_memory(dhs)) /4 ;
}



/************************************************
*            read_nika_noms_....                *
************************************************/

void  read_nika_noms_var_all(int4 *buffer_header,char *nom) {
	Data_header_shared_memory  *dhs= (Data_header_shared_memory *) buffer_header;
	int j,i;
	int nb=__nbch(dhs);

	for(j=0; j<dhs->nb_param_c; j++)
		for(i=0; i<nb; i++)
			*(nom++) = _sm_nom_param_c(dhs,j)[i];


	for(j=0; j<dhs->nb_param_d; j++)
		for(i=0; i<nb; i++)
			*(nom++) = _sm_nom_param_d(dhs,j)[i];


	if(dhs->nb_data_c)
		for(j=0; j<dhs->nb_data_c; j++)
			for(i=0; i<nb; i++)
				*(nom++) = _sm_nom_data_c(dhs,j)[i];


	if(dhs->nb_data_c)
		for(j=0; j<dhs->nb_data_c; j++)
			for(i=0; i<nb; i++)
				*(nom++) = _sm_nom_data_c(dhs,j)[i+nb];

	//printf("\n BEFORE DETECTEURS  \n" );
	//printf(" \n number of detectors: %d \n",dhs->nb_data_d);

	if(dhs->nb_data_d)
		for(j=0; j<dhs->nb_data_d; j++)
			for(i=0; i<nb; i++)
				*(nom++) = _sm_nom_data_d(dhs,j)[i];

	//printf("\n after DETECTEURS  \n" );

	if(dhs->nb_data_d)
		for(j=0; j<dhs->nb_data_d; j++)
			for(i=0; i<nb; i++)
				*(nom++) = _sm_nom_data_d(dhs,j)[i+nb];

	for(j=0; j<dhs->nb_detecteurs; j++) {
		//    printf("\n j= %d  \n",j);
		for(i=0; i<8; i++) {     // ici ca reste toujours 8 characteres utiles meme si on stocke sur 16 dans nomvarall

			*(nom++) = _nom_detecteur(dhs,j)[i];
		}
	}
}




/************************************************
*            send_nika_geometrie                *
************************************************/
// fonction qui n'a jamais ete utilisee  !!!!!

void send_nika_geometrie(int nb_detecteurs_lu,int4 *raw_number,int4 *x_pix,int4 *y_pix) {
	(void) nb_detecteurs_lu;
	(void) raw_number;
	(void) x_pix;
	(void) y_pix;
	printf("\n\n*****  send_nika_geometrie()  ********\n");
}


/****************************************************
*           nombre   data_fichier                   *
****************************************************/
// cette fonction retourne le nombre total de blocs de data dans le fichier
// si on lui donne nb_det_liste = -1,-2 ou -3 elle ressort aussi le nb de detecteurs de la liste a lire

int	nombre_data_fichier(char *fichier,int code_listdet,int4 *listdet,int print) {
	int type;
	int debut,fin=0;

	static	int size_bloc_standard=0;;
	Bloc_standard *blk;
	Data_header_shared_memory *dhs;
	long pos_fich=0;


	FILE *file = fopen(fichier,"rb");
	if(!file) return 0;
#ifdef debug
	printf("\n  nombre_data_fichier()  print=%d  \n",print);
#endif
	dhs = read_file_header (file,print);

#ifdef debug
	printf("\n *********************************\n************************dans nombre_data_fichier read dhs avec _len_brut_bloc_shared_memory=%ld ",_len_brut_bloc_shared_memory(dhs));
#endif

	size_bloc_standard = _len_brut_bloc_shared_memory(dhs) + sizeof(Bloc_standard) ;
	blk=malloc(size_bloc_standard);

	fseek(file,0,SEEK_SET);		// remet au debut du fichier
	if(print) printf("\ncherche nombre data fichier   ");
	do {
		//type = lecture_bloc_fichier(file,code_zero,blk,size_bloc_standard,dhs);		// retourne le type du bloc lut (-1 a la fin)

		type = read_file_bloc(dhs,file,blk,&pos_fich,size_bloc_standard,0);	// sans conversion des blocs mini et comprimes
#ifdef debug
		Def_nom_block
		// printf("type=%d  ",type);
		printf(" %s", nom_block[type]);
#endif
		if(type<=0) return -1;
	} while( (type != bloc_brut ) &&  (type != bloc_mini ) &&  (type != bloc_comprime8 ) &&  (type != bloc_comprime10 )  &&  (type != bloc_comprime10d ) );

	debut = numero_bloc((Bloc_standard *)blk);	// Le premier numero de bloc dans le fichier

	if(listdet!= NULL) {
		if(type == bloc_mini )	cree_list_det(dhs,code_listdet,listdet, blk->data);
		else					cree_list_det(dhs,code_listdet,listdet, NULL);
	}


	fseek(file,-2*_size_bloc_brut(dhs),SEEK_END); // je recule suffisament pour etre sur de retrouver au moins un bloc brut

	do {
		type = read_file_bloc(dhs,file,blk,&pos_fich,size_bloc_standard,0);
		if( (type == bloc_brut) ||  (type == bloc_mini)  ||  (type == bloc_comprime8)  ||  (type == bloc_comprime10)  ||  (type == bloc_comprime10d) )
			fin = numero_bloc((Bloc_standard *)blk);
		//printf("type=%d  ",type);
	} while (type >0);
	if(fin<debut) {
		printf("\n erreur, je ne trouve pas la fin correctement : je relis tout le fichier ");
		fseek(file,0,SEEK_SET);
		do {
			type = read_file_bloc(dhs,file,blk,&pos_fich,size_bloc_standard,0);
			if( (type == bloc_brut) ||  (type == bloc_mini)  ||  (type == bloc_comprime8)  ||  (type == bloc_comprime10) ||  (type == bloc_comprime10d) )
				fin = numero_bloc((Bloc_standard *)blk);
			//printf("type=%d  ",type);
		} while (type >0);
	}
	//if(print) printf("  fin = %d  :   total %d blocs ",fin,fin-debut+1);
	//fseek(file,0,SEEK_SET);		// remet au debut du fichier
	fclose(file);
	free(dhs);
	free(blk);
	if(fin==0) return -1;
	return (fin-debut+1);
}





