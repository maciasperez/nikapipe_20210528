#include <mq_manip.h>

#include "a_memoire.h"
#include "def.h"
#include "bloc_nikel.h"
#include "bloc_elvin.h"
#include "bloc.h"
#include "readbloc.h"
#include "file_util.h"


#define debug 1
#undef printf

#define _dossier_depart   _dossier_data_interne

extern char Argv1[500];

/*
char inter_file[500] = "/Users/archeops/Desktop/test_run13all/@_2015_11_04_16h00m00_A";
char raw_file[500] = "/Users/archeops/Desktop/test_run13all/X_2015_11_04_16h01m21_A0_0129_O_Saturn";
#define	_z		0
#define _det	10
#define	_I		0
*/

/*
char inter_file[500] = "/Users/archeops/Desktop/test_run13all/@_2015_11_06_01h00m00_A";
char raw_file[500] = "/Users/archeops/Desktop/test_run13all/X_2015_11_06_01h07m11_A0_0008_O_Uranus";
#define	_z		0
#define _det	10
#define	_I		0
*/


#define  _inter_seule
//#define		_d_elvin_message  _d_scan
//#define  _d_elvin_message  _d_subscan
//#define  _d_elvin_pointage  _d_ofs_X
//#define  _d_elvin_pointage  _d_ofs_Y
#define  _d_elvin_message  _d_scan_st
//#define  _d_elvin_message  _d_obs_st

#ifdef _d_elvin_message
#define _d_elvin _d_elvin_message
#endif
#ifdef _d_elvin_pointage
#define _d_elvin _d_elvin_pointage
#endif


#define	_z		0
//char inter_file[500] = "/Users/archeops/Desktop/test_run13all/@_2015_11_08_13h00m00_P";
//char raw_file[500] = "/Users/archeops/Desktop/test_run13all/X_2015_11_08_13h05m03_A0_0148_L_3C286";
char inter_file[500] = "/Users/archeops/Desktop/test_run13all/@_2015_11_08_14h00m00_P";
char raw_file[500] = "/Users/archeops/Desktop/test_run13all/X_2015_11_08_14h05m21_A0_0152_L_3C286";



//#define _max_sample  (600*23)		//  600 sec a 23 Hz
#define _max_sample  (1800*23)		//  600 sec a 23 Hz
//#define _start_time  (16*3600+60)		// en secondes   16h + 1min
//#define _start_time  (16*3600+120+60)		// 16h + 1min

#ifdef _inter_seule
#define _nb_traces	1
#else
#define _nb_traces	2
#endif


Data_header_shared_memory  *Dhs;
Bloc_standard* blk;
double start_time=0;
long pos=0;
double * tablenXnY[2*_nb_traces];

void exec_gra(int fen,int item,double valeur,...);
int	read_inter(void);
int	read_raw(void);

/****************************************************
*                     DEMARRAGE                     *
****************************************************/
void demarrage(void)
{
int i;
// 30 minute a 23 Hz = 4.5e4
printf("\n**********   read inter     ********************\n");

for(i=0;i<2*_nb_traces;i++)  tablenXnY[i] = (double*) malloc(sizeof(double)*_max_sample);

	
#ifdef debug
	Dhs = read_nom_file_header (inter_file,debug);
#else
	Dhs = read_nom_file_header (inter_file,0);
#endif


if(Dhs)
	{
	int max_len = _size_bloc_modele(Dhs);
	blk = (Bloc_standard*)malloc(max_len);
	nouveauD(1,mgraphicType,"-----",exec_gra);	// Ouverture de la fenetre de menu graphic
	}

printf("\n--------------------------------------------   fin de  read inter    ------------- \n ");
}




void exec_gra(int fen,int item,double valeur,...)
{
if(item==construction)
	{
	int max = _max_sample;
	int a;
#ifndef _inter_seule
	a=read_raw();
	printf("\n----  raw data  %d  sample",a);
	if(a<max)  max=a;
#endif
	a=read_inter();
	printf("\n----  inter data  %d  sample",a);
	if(a<max)  max=a;
	printf("\n  plot  %d traces avec %d  sample  \n",_nb_traces,max);
	plot_table_nX_nY(1,_premier_item,_nb_traces,max,tablenXnY);
	autoxy(1);
	}
}


int	read_raw(void)
{
int type,num;
int sample;
int indice=0;
int i;
double x,y;
int max_len = _size_bloc_modele(Dhs);
Def_nom_block
pos=0;
while(read_nom_file_bloc(Dhs,raw_file,blk,&pos,max_len)>0)
		{
		int4* Br=blk->data;
		type=type_bloc(blk);			// type du bloc
		num= numero_bloc(blk);
		if( type==1)	// type brut
			{
			if( (num%10==0) )
			printf("\nraw_file  bloc n=%d  type %d ( %s ) ",num,type,nom_block[type_bloc(blk)]);
			
			for(i=0;i<36;i++)
				{
				sample = num*36+i;
				x=(double)_brut_pb(Dhs,Br,_db_t_utc,_z,i);
				x = x * (86400./1e9);   //  transforme les brut en mjd9 en secondes
				if(start_time==0)
					{
					start_time = x;
					printf("\n start time = %g ",start_time);
					int h=start_time/3600;
					int m =(start_time-h*3600)/60;
					int s =(start_time-h*3600-m*60);
					printf(" soit  %d h  %d min  %d sec",h,m,s);
					}
				x = x - start_time ;  // secondes a partir de 16Hz
				//printf(" t=%g ",x);
				if (x>=0)
					{
					#ifdef _I
					y=_brut_pdd(Dhs,Br,_dd_I+_I,i)[_det+_z*400];
					#endif
					#ifdef _d_elvin
					y=_brut_pc(Dhs,Br,_d_elvin,i);
					#endif
					tablenXnY[2][indice]=x;
					tablenXnY[3][indice]=y;
					//printf(" \n indice=%d  x=%g  y=%g  ",indice,x,y);
				
					indice++;
					if(indice>= _max_sample )  break;
					}
				
				
				
				}
			}
		}
return indice;
}



int	read_inter(void)
{
int type,num;
int sample;
int indice=0;
int j;
double x,y;
int max_len = _size_bloc_modele(Dhs);
Def_nom_block
pos=0;
while(read_nom_file_bloc(Dhs,inter_file,blk,&pos,max_len)>0)
		{
		type=type_bloc(blk);			// type du bloc
		num= numero_bloc(blk);
		#ifdef _I
		if( type==20)
			{
			if( (_bk_indice(blk)==0) && (num%50==0) ) printf("\ninter_file  bloc n=%d  type %d ( %s ) ",num,type,nom_block[type_bloc(blk)]);
			sample = num*36+_bk_indice(blk);
			x=_bk_temps_ut(blk);
			x = x * 86400./1e9 ;   //  transforme les brut en mjd9 en secondes
			if(start_time==0)
					{
					start_time = x;
					printf("\n start time = %g ",start_time);
					int h=start_time/3600;
					int m =(start_time-h*3600)/60;
					int s =(start_time-h*3600-m*60);
					printf(" soit  %d h  %d min  %d sec",h,m,s);
					}
			x = x - start_time ;  // secondes a partir de
			if (x>0)
				{
				tablenXnY[0][indice]=x;
				y=_bk_IQ(blk,4,_det,_I);;
				tablenXnY[1][indice]=y;
				indice++;
				if(indice>= _max_sample )  break;
				}
			}
		#endif
		#ifdef _d_elvin
		if( type==10)		// bloc elvin
			{
			if( (num%40==0) )
				{
				x=_bpe_pointage(Dhs->nb_pt_bloc,blk,0,_d_MJD_deci-_d_ofs_X+1);
				x = x * 86400./1e8 ;   //  transforme les brut en mjd9 en secondes
				x = x - start_time ;  // secondes a partir du debut du raw file
				printf("\ninter_file  bloc n=%d  type %d ( %s )  t=%d ",num,type,nom_block[type_bloc(blk)],(int)x);
				}

			for(j=0;j<Dhs->nb_pt_bloc;j++)
				{
				sample = num*36+j;
				x=_bpe_pointage(Dhs->nb_pt_bloc,blk,j,_d_MJD_deci-_d_ofs_X+1);
				x = x * 86400./1e8 ;   //  transforme les brut en mjd9 en secondes
				if(start_time==0)
					{
					start_time = x;
					printf("\n start time = %g ",start_time);
					int h=start_time/3600;
					int m =(start_time-h*3600)/60;
					int s =(start_time-h*3600-m*60);
					printf(" soit  %d h  %d min  %d sec",h,m,s);
					}
				x = x - start_time ;  // secondes a partir de 16Hz
				if(x>0)
					{
					#ifdef _d_elvin_pointage
					y=_bpe_pointage(Dhs->nb_pt_bloc,blk,j,_d_elvin_pointage-_d_ofs_X+1);
					#endif
					#ifdef _d_elvin_message
					y=_bpe_message(Dhs->nb_pt_bloc,blk,j,_d_elvin_message-_d_year+1);
					#endif
					
					
					//if(indice<100) printf("\n interfile  x=%g  y=%g  ",x,y);
					tablenXnY[0][indice]=x;
					tablenXnY[1][indice]=y;
					indice++;
					if(indice>= _max_sample )  break;
					}
				}
			}
		#endif
		}
return indice;
}





/*
if(item==tache_de_fond)
	{
	if(read_nom_file_bloc(Dhs,file,blk,&pos,max_len)>0)
		{
		type=type_bloc(blk);			// type du bloc
		num= numero_bloc(blk);
		if( (_bk_indice(blk)==0) && (num%10==0) ) printf("\nbloc n=%d  type %d ( %s ) ",num,type,nom_block[type_bloc(blk)]);
		if( type==20)
			{
			sample = num*36+_bk_indice(blk);
			x=_bk_temps_ut(blk);
			x = (double)_bk_temps_ut(blk) * (86400./1e9);   //  transforme les brut en mjd9 en secondes
			x = x - 3600*16 ;  // secondes a partir de 16Hz
			i=0;	//  soit I
			for(q=0;q<3;q++)
					{
					y[q]=_bk_IQ(blk,4,q+10,i);
					}
			tracen(1,3,x,y);
			}
		}
	}
*/







