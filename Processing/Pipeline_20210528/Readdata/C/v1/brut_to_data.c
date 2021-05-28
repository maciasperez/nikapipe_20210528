#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <assert.h>
//#include <omp.h>

#include "elvin_structure.h"
#include "a_memoire.h"
#include "def.h"
#include "def_nikel.h"
#include "def_opera.h"

#include "brut_to_data.h"
#include "rotation.h"
#include "bolo_unit.h"

#include "atan2_approx.h"
#define atan2 atan2_approx1	// Replace atan2 function with faster approximation or comment out to keep atan2

#include "unistd.h"

#define _interval(x,a,b)	((x)<(a) ? (a) : (x)>=(b) ? (b) : (x))

//#define debug 1
#undef printf

//#define _brut_to_data_kid_simplifie       // ne marche plus

#define _nb_matrices 3			//abprovisoire  pointage pour le calcul pointage, pour 3 matrices uniquement


#ifdef  modele_lecture_ecriture_variables
//================================================================================================================
//==========================           un modele de lecture ecriture           ===================================
//================================================================================================================
//================================================================================================================

void modele_lecture_ecriture_variables(Data_header_shared_memory *dhs,int4 *Br,double *Dd) {

	int phase,code,type,sample,time,II;
	double dsample,dtime,dII;
	int z=1,ndet=10,i=12;
	uint4 *reg;

	//lecture et ecriture  d'un parametre simple , par exemple  _p_phase_ds :
	if (_presence_param_c(dhs,_p_phase_ds))   phase  =  _param_c(dhs,_p_phase_ds);
	if (_presence_param_c(dhs,_p_phase_ds))  _param_c(dhs,_p_phase_ds) = phase ;

	//lecture et ecriture  d'un parametre box , par exemple  _pb_code_horloge  sur la boite  z :
	if (_presence_param_b(dhs,_pb_code_horloge,z))   code  =  _param_b(dhs,_pb_code_horloge,z);
	if (_presence_param_b(dhs,_pb_code_horloge,z))  _param_b(dhs,_pb_code_horloge,z) = code ;

	//lecture et ecriture  d'un parametre detecteur , par exemple  _pd_type  sur le detecteur ndet  :
	if (_presence_param_d(dhs,_pd_type))   type  =  _param_d(dhs,_pd_type,ndet);
	if (_presence_param_d(dhs,_pd_type))  _param_d(dhs,_pd_type,ndet) = type ;

	//lecture et ecriture  d'un reglage, par exemple   _r_mppsync  sur lea boite z   :
	reg = reglage_pointer(dhs,_r_mppsync,z);


	//lecture et ecriture  d'un brut  simple , par exemple  _d_sample   sur le point i du bloc (i=0 .. dhs->nb_pt_bloc:
	if (_presence_brut(dhs,_d_sample))   sample  =  _brut_pc(dhs,Br,_d_sample,i);
	if (_presence_brut(dhs,_d_sample))  _brut_pc(dhs,Br,_d_sample,i) = sample ;

	//lecture et ecriture  d'un brut  box , par exemple  _db_t_utc   sur le point i du bloc  pour la boite z :
	if (_presence_brutbox(dhs,_db_t_utc,z))   time  =  _brut_pb(dhs,Br,_db_t_utc,z,i);
	if (_presence_brutbox(dhs,_db_t_utc,z))  _brut_pb(dhs,Br,_db_t_utc,z,i) = time ;

	//lecture et ecriture  d'un brut  detecteur , par exemple  _dd_I   sur le point i du bloc  pour le detecteur ndet :
	if (_presence_brutdet(dhs,_dd_I))   II  =  _brut_pdd(dhs,Br,_dd_I,i)[ndet];
	if (_presence_brutdet(dhs,_dd_I))  _brut_pdd(dhs,Br,_dd_I,i)[ndet] = II ;


	//lecture et ecriture  d'un data  simple , par exemple  _d_sample   sur le point i du bloc (i=0 .. dhs->nb_pt_bloc:
	if (_presence_data(dhs,_d_sample))   dsample  =  _data_pc(dhs,Dd,_d_sample,i);
	if (_presence_data(dhs,_d_sample))  _data_pc(dhs,Dd,_d_sample,i) = dsample ;

	//lecture et ecriture  d'un data  box , par exemple  _db_t_utc   sur le point i du bloc  pour la boite z :
	if (_presence_databox(dhs,_db_t_utc,z))   dtime  =  _data_pb(dhs,Dd,_db_t_utc,z,i);
	if (_presence_databox(dhs,_db_t_utc,z))  _data_pb(dhs,Dd,_db_t_utc,z,i) = dtime ;

	//lecture et ecriture  d'un data  detecteur , par exemple  _dd_I   sur le point i du bloc  pour le detecteur ndet :
	if (_presence_datadet(dhs,_dd_I))   dII  =  _data_pdd(dhs,Dd,_dd_I,i)[ndet];
	if (_presence_datadet(dhs,_dd_I))  _data_pdd(dhs,Dd,_dd_I,i)[ndet] = dII ;

}
#endif
//================================================================================================================
//================================================================================================================


//================================================================================================================
//================================================================================================================
//=================		calcule les data utilisateur a partir des data brutes       ==============================
//================================================================================================================
//================================================================================================================

static void	brut_to_data_map(Data_header_shared_memory *dhs,int4 *Br,double *Dd);
static void	brut_to_data_antenna(Data_header_shared_memory *dhs,int4 *Br,double *Dd);
static void	brut_to_data_pointage(Data_header_shared_memory *dhs,double *Dd);
static void	brut_to_data_synchro(Data_header_shared_memory *dhs, double *Dd);
static void	brut_to_data_bolo(Data_header_shared_memory *dhs,int4 *Br,double *Dd);
static void	brut_to_data_kid(Data_header_shared_memory *dhs,int4 *Br,double *Dd,int4 *liste_det2,char *buf_btd);
static void	brut_to_data_mppsync(Data_header_shared_memory *dhs,int4 *Br,double *Dd,int z);
//static void brut_to_data_synthe(Data_header_shared_memory *dhs,double *Dd);
static void brut_to_data_sourceRF(Data_header_shared_memory *dhs,double *Dd);

static void	calcul_DS(Data_header_shared_memory *dhs,double *Dd,int nper);

//static void	calcul_kid_fast(Data_header_shared_memory *dhs,int4 *br,int4 *liste_det2,int nper,
//						double *ftone,double *tangle,int *flagkid,int *width);



//================================================================================================================

char *Buffer_temp=NULL;		// si on ne donne pas un buffer a brut to data, j'en alloue un que je garde ici
//---    a   part  ca , pas de global dans ce fichier    ------------


/****************************************************
*              BRUT  TO  DATA 					*
*****************************************************/
//  a partir de gg->dd _brute, fabrique les valeurs a tracer
//  dd _brute  contient des sommes et il faut calculer plus - moins dans le cas d'une MMLPA ou BEBO
//  pour le mux, il suffit de faire
//  donne la valeur brute en unite du convertisseur, non affectee du gain
//   comme j'ai divise par 2 les valeurs brutes, il faudra remultiplier par 2 pour trouver le bon resultat
//   la conversion en microvolt est faite a la fin de cette fonction avec    bol_micro_volt_2




void  brut_to_data(Data_header_shared_memory *dhs,int4 *Br,double *Dd,int4 *liste_det2,char *buf_btd,int print) {
//  calcule les data en double dans Dd a partir des data brut dans Br
// si je veux creer le buffer buf_btd a l'exterieur, je dois faire un   malloc(_total_length_buf_btd)
// si je ne veux pas me fatiguer, je passe un pointeur null
	int i,j,k,q,z;

	int free_liste_det2=0;
	if (liste_det2 == NULL) {
		liste_det2= malloc(sizeof(int4) * (dhs->nb_detecteurs+1) );
		//----  on ne calculera que les detecteurs dont le type est non null   -----
		k=0;
		for(i=0; i<dhs->nb_detecteurs; i++) if (_type_det(dhs,i) ) liste_det2[1+k++]=i;
		liste_det2[0]=k;
		free_liste_det2=1;
	}


	// printf("\n Starting brut_to_data \n");


	if (buf_btd == NULL) {
		if (Buffer_temp==NULL) {
			if (print) printf("\n\n***********    brut to_data() :  malloc  du buffer_temp");
			Buffer_temp = malloc(_total_length_buf_btd);

			// We SHOULD do the following trick, but since the array can also come from the function call, it's useless
			// This trick is because the doubles in the buffer follow an int and are thus NOT aligned on 8-byte boundaries
			// slowing down the computations
			// Note that malloc aligns on 8-byte boundaries
			// IMPORTANT: you CANNOT free(Buffer_temp) anymore, but free(Buffer_temp-sizeof(int))
			// Buffer_temp = (char*)malloc(_total_length_buf_btd+sizeof(double)) + sizeof(int);
			
			if (print) printf(  "\n***********    Buffertemp = %p  _total_length buf_btd = %lx (%4.1f mega )",
								   Buffer_temp,_total_length_buf_btd,(double)_total_length_buf_btd/1e6);
			Buffer_temp[0]=1;	// pour demander une initialisation des tableaux
		}
	} else Buffer_temp =  buf_btd;

	if (Buffer_temp[0]==1) {
		if (print) printf("\n***********    brut to_data() :  initialisation \n");
		*_pos_table_brut_retard = 0;
	}

	static int FirstTime=1;
	if (FirstTime) {
		// Verify that parts of the array are aligned on 8-byte boundaries
		#ifdef debug
		printf("Addresses: %p, %p, %p\n", Buffer_temp, &_data_ec(dhs,Dd,0,0), _data_ed(dhs,Dd,0,0));
		printf("Addresses: %p, %p, %p, %p, %p\n", _demande_raz_didq, _table_derive, _iqdidq, _table_brut_retard, _buffer_flag);
		printf("Addresses: %p, %p, %p, %p\n", _flagkid, _width, _ftone, _tangle);
		printf("Addresses: %p, %p, %p\n", _val_pre_bolo, _ds_bufi, _ds_bufd);
		#endif

		assert((long long)Buffer_temp%8==0);
		assert((long long)&_data_ec(dhs,Dd,0,0)%8==0);
		assert((long long) _data_ed(dhs,Dd,0,0)%8==0);
		FirstTime=0;
	}

	// This was the 4th slowest section of the code: too many cache misses when using loops
	// Note that putting zeros in 2 ints is the same as a 0. double
	//----------------------    efface data  --------------------------
	memset(&_data_ec(dhs,Dd,0,0), 0, dhs->nb_data_c*dhs->nb_pt_bloc                   *sizeof(double));
	memset( _data_ed(dhs,Dd,0,0), 0, dhs->nb_data_d*dhs->nb_pt_bloc*dhs->nb_detecteurs*sizeof(double));

	int retard=0;                   //-------------------  lecture retard dans le  param  ---------------
	if (_presence_param_c(dhs,_p_retard_data) )  retard = _param_c(dhs,_p_retard_data);


	//=========   avance la position dans la  table_brut_retard  et copie les brut en  pos..pos+35
	//---  ici on ecrit tous les brut presents dans le tableau Br
	int		pos = (*_pos_table_brut_retard + dhs->nb_pt_bloc )%_retard_brut_maxi;
	*_pos_table_brut_retard = pos;
	for(j=0; j<dhs->nb_pt_bloc; j++)
		for(q=0; q<dhs->nb_brut_c; q++)
			_brut_retarde_ind(q,(pos+j)%_retard_brut_maxi) = _brut_ec(dhs,Br,q,j);
	//======  pour lire les brut retarde dans une boucle   for (i=0;i<dhs->nb_pt_bloc;i++)
	//======  calculer  pos=_posrt(retard,i)  puis  lire : _brut_retarde(_d_xxx,pos);

	/*
	printf("\n  offx=%d  offy=%d   brut direct = %d,%d    el = %d",_ibr(dhs)[_d_ofs_X],_ibr(dhs)[_d_ofs_Y],
				_brut_ec(dhs,Br,_ibr(dhs)[_d_ofs_X],1),_brut_ec(dhs,Br,_ibr(dhs)[_d_ofs_Y],1),_brut_ec(dhs,Br,_ibr(dhs)[_d_El],1));
	printf("\n  brut retard  = %d,%d   -  %d,%d ",_brut_retarde_ind(_ibr(dhs)[_d_ofs_X],pos),_brut_retarde_ind(_ibr(dhs)[_d_ofs_Y],pos),
				_brut_retarde(_d_ofs_X,pos),_brut_retarde(_d_ofs_Y,pos));
	printf("\n  brut table   = %d,%d   ",
				_brut_retarde(_d_ofs_X,1),_brut_retarde(_d_ofs_Y,1));
	*/

	//printf("\n sample = ");  for (i=0;i<dhs->nb_pt_bloc;i++) printf("  %d ",_brut_pc(dhs,Br,k,i));


	_copy_brut_to_data(_d_sample,1.);
	_copy_brut_to_data(_d_t_mac,0.001);

	if (_presence_brut_data(dhs,_d_bras_mpi))
		for (i=0; i<dhs->nb_pt_bloc; i++) {
			int pos = _posrt(retard,i);
			//printf(" %d",_brut_retarde(_d_bras_mpi,pos));
			_data_pc(dhs,Dd,_d_bras_mpi,i)		=	_position_mpi(_brut_retarde(_d_bras_mpi,pos));
		}
	#ifdef debug
		// printf("\n bras mpi  %d  ->  %g  ",_brut_pc(dhs,Br,_d_bras_mpi,0),_data_pc(dhs,Dd,_d_bras_mpi,0) );
	#endif

	if (reglage_pointer(dhs,_r_o_rg1,0) )		brut_to_data_bolo(dhs,Br,Dd);

	if (_presence_brutdet(dhs,_dd_I) )			brut_to_data_kid(dhs,Br,Dd,liste_det2,Buffer_temp);

	if (_presence_brut(dhs,_d_Az) )				brut_to_data_pointage(dhs,Dd);
	if (_presence_brut(dhs,_d_antAz) )			brut_to_data_antenna(dhs,Br,Dd);
	if (_presence_brut(dhs,_d_map_tbm) )		brut_to_data_map(dhs,Br,Dd);

	if (_presence_brut(dhs,_d_synchro_rapide) )	brut_to_data_synchro(dhs,Dd);
	
    if (reglage_pointer(dhs,_r_sourceRF,-1) )		brut_to_data_sourceRF(dhs,Dd);

	z=first_box(dhs,_r_mppsync);
	if (z>=0)									brut_to_data_mppsync(dhs,Br,Dd,z);

	//Buffer_temp[0] vaut 1 au demarrage et passe a zero apres le premier appel de toutes les fonctions brut_to_data
	Buffer_temp[0] = 0;		// fin de l'initialisation apres appel de toutes les fonctions brut to data ....
	if (free_liste_det2) free(liste_det2);
}



//for(z=0;z<_nb_max_acqbox;z++)   if (_presence_brutbox(dhs,_db_position,z) )   brut_to_data_mppsync(dhs,Br,Dd,z);

// a faire apres les brut to_data_kid et bolo car la detection synchrone est calculee ici



/*
for(j=0;j<dhs->nb_pt_bloc;j++)
	{
	int pos = _posrt(retard,j);
	printf("\n synchro_rapide=%x  synchro_flag=%x ",_brut_pc(dhs,Br,_d_synchro_rapide,j),_brut_pc(dhs,Br,_d_synchro_flag,j));
	printf("retarde : synchro_rapide=%x  synchro_flag=%x ",_brut_retarde(_d_synchro_rapide,pos),_brut_retarde(_d_synchro_flag,pos));
	}
*/

//printf("\n fin de brut to_data  :  sample data = %g   ofset X = %g -- %g  ",_data_pc(dhs,Dd,_d_sample,0),_data_pc(dhs,Dd,_d_ofs_X,0),_data_pc(dhs,Dd,_d_ofs_X,dhs->nb_pt_bloc-1));
//		{int i;double valeur=0;for(i=0;i<dhs->nb_pt_bloc;i++)	valeur+=_data_pc(dhs,Dd,_d_ofs_X,i);//_data_ec(dhs,Dd,k,i);
//		printf(" moyenne=%g ; %g ",valeur/dhs->nb_pt_bloc ,moyenne_bloc_data_c(dhs,Dd,_idd(dhs)[_d_ofs_X]));
//		}

//printf("\n Ending brut_to_data \n");



/****************************************************
*               brut_to_data_synchro                *
****************************************************/
static void brut_to_data_synchro(Data_header_shared_memory *dhs,double *Dd) {

	int i;
	int synchro_rapide=0, synchro_flag;

	int retard=0;
	if (_presence_param_c(dhs,_p_retard_data) )  retard = _param_c(dhs,_p_retard_data);

	if (_presence_brut(dhs,_d_synchro_flag) && _presence_brut(dhs,_d_synchro_rapide) ) {
		for (i=0; i<dhs->nb_pt_bloc; i++) {
			int pos = _posrt(retard,i);

			synchro_rapide = _brut_retarde(_d_synchro_rapide,pos);  // la synchro rapide seule sur 8 bit de poid faible avec le max sur les 8 bit de poids plus fort
			synchro_flag   = _brut_retarde(_d_synchro_flag,pos);	//  les autres synchro suivant l'enum des synchros
			int syra = synchro_rapide & 0xff;
			int symax = synchro_rapide >>8;

			if (_presence_brut_data(dhs,_d_synchro_rapide))	_data_pc(dhs,Dd,_d_synchro_rapide,i)=  ( (double)syra ) / ( (double)symax );
			if (_presence_brut_data(dhs,_d_synchro_flag))	_data_pc(dhs,Dd,_d_synchro_flag,i)	=  (double) synchro_flag;


			//abprov rustine pour corriger la mauvaise qualite du capteur de position du polariseur tournat du mpi
			// je regarde _d_synchro_rapide  n point avant et je cherche une difference de (synchro_rapide>>8) qui est le maxi
			/*
					int synchro_flag1 = synchro_rapide - _brut_retarde(_d_synchro_rapide,(pos-6+_retard_brut_maxi)%_retard_brut_maxi) & 0xff;
					int synchro_flag2 = synchro_rapide - _brut_retarde(_d_synchro_rapide,(pos-5+_retard_brut_maxi)%_retard_brut_maxi) & 0xff;
					int synchro_flag3 = synchro_rapide - _brut_retarde(_d_synchro_rapide,(pos-4+_retard_brut_maxi)%_retard_brut_maxi) & 0xff;
					//printf("\n max=%d  synchro_flagx=%d , %d , %d  ",synchro_rapide>>8,synchro_flag1,synchro_flag2,synchro_flag3);
					if ((synchro_flag1==synchro_rapide>>8) && (synchro_flag2==synchro_rapide>>8) && (synchro_flag3==synchro_rapide>>8) )
							synchro_flag = 1;	else synchro_flag=0;
			*/
			//printf("\n %d  retard=%d  synchro_rapide=%d  synchro_flag=%d ",i,retard,_brut_retarde(_d_synchro_rapide,pos),_brut_retarde(_d_synchro_flag,pos));
			//synchro_rapide = retard_universel(retard, _brut_pc(dhs,Br,_d_synchro_rapide,i) , _d_synchro_rapide);
			//synchro_flag = retard_universel(retard, _brut_pc(dhs,Br,_d_synchro_flag,i) , _d_synchro_flag);

			//---------  calcul de la periode et de la phase pour la detection synchrone dans les data
			_DS_cpt++;
			if (_DS_cpt>_DS_periode+2) {
				_DS_periode=0;
				_DS_chercheper=10;
			}
			if (synchro_flag & 1) {		// le top synchro de la synchro rapide
				_DS_periode=_DS_cpt;
				_DS_cpt=0;
				int  nn= ( (synchro_rapide>>8) & 0xff);
				if (nn)	_phase_rapide = 0.5 -  ((double) (synchro_rapide & 0xff) / (double)nn );		
				// je change le signe pour que l'ajustement marche comme avant
				//printf("\n top avec  nn=%d   _DS_periode=%d   _DS_chercheper=%d    rapide=%d  _phase_rapide=%5.2f ",nn,_DS_oldper,_DS_chercheper,(synchro_rapide & 0xff),_phase_rapide);
			}

			//		if (_DS_periode%2 == 0) 	_DS_periode = _DS_periode/2;	// pour travailler a 2f uniquement si la _DS_periode est paire
			//		else _DS_periode=0;

			//---  ici j'ai tous les points qui se suivent et je connais la _DS_periode et le top

			// j'ai un static qui me dit que la _DS_periode est stable depuis assez longtemps
			if (_DS_periode != _DS_oldper) {
				if (!_DS_chercheper) printf("********  change periode : p=%d \n",_DS_periode);
				//				printf("   per=%d  old=%d ",_DS_periode,_DS_oldper);
				if (_DS_periode >= 4 ) {	// 4 points dans 1 __periodes  minimum
					_DS_oldper = _DS_periode;
					_DS_chercheper = _DS_periode*10;
				} else {
					_DS_oldper=0;
					_DS_chercheper = 2;
				}
			}
			if (_DS_chercheper && _DS_oldper)	_DS_chercheper--;

			#ifdef debug
				if (_DS_chercheper==1) printf("********  periode stable : p=%d \n",_DS_periode);
			#endif
			// ce n'est que quand   _DS_chercheper==0 que je peux calculer la detection synchrone

			//printf("  -->>  synchro_rapide=%d  synchro_flag=%d  top=%d ",synchro_rapide,synchro_flag,synchro_flag & 1);
			calcul_DS(dhs,Dd,i);

			if (_presence_data(dhs,_d_synchro_periode))	_data_pc(dhs,Dd,_d_synchro_periode,i)	=  (double) _DS_periode;
			if (_presence_data(dhs,_d_synchro_phase)  )	_data_pc(dhs,Dd,_d_synchro_phase,i)		=  _phase_rapide;
		}
#ifdef debug
		printf("\n synchro_rapide=%d   synchro_flag=%x  _DS_periode=%d   _DS_chercheper=%d  ",synchro_rapide,synchro_flag,_DS_oldper,_DS_chercheper);
#endif
	}
	//enum {_sync_roue,_sync_bras_av,_sync_bras_arr,_sync_butee_av,_sync_butee_arr,_sync_avance,_sync_recule,_sync_7,_sync_8,_sync_9,_sync_fichier,_sync_mpi,_sync_pointage,_sync_calage_kids,_sync_scans,_sync_subscans,_sync_16,_nb_synchros};
	//#define _def_noms_sychros	char noms_synchros[32][_nb_synchros]={"Roue","Bras en avant","Bras arriere","Butee avant","Butee arreire","Avance","Recule","Sy 7","Sy 8","Sy 9","Fichier","MPI","Pointage","Calage KIDs","Scans","Subscans","Sy 16"};

}



/****************************************************
*               calcul_DS							*
****************************************************/
//  appele successivement pour chaque valeur de nper
//  dans brut to data  :  calcul de la detection synchrone en cas de modulation
//----  je mets ces variables intermediaires de calcul en static dans ce fichier
// il faut prendre les variables de calcul dans  le buffer temporaire buf_btd



void	calcul_DS(Data_header_shared_memory *dhs,double *Dd,int nper) {
	int n_bol,j;
	double ss=0;
	double cs=0;
	double DS_sin,DS_cos;
	double phase;
	//--- _DS_cpt  est remis a zero a chaque top et il compte les mesures jusqu'a _DS_periode-1 avant de revenir a zero
	if ((!_presence_datadet(dhs,_dd_ds_pha))  && (!_presence_datadet(dhs,_dd_ds_qua))  ) return;

	for(n_bol=0; n_bol<dhs->nb_detecteurs; n_bol++)
		_data_pdd(dhs,Dd,_dd_ds_pha,nper)[n_bol]	=
		_data_pdd(dhs,Dd,_dd_ds_qua,nper)[n_bol]	=	0;

	_DS_periode = _interval(_DS_periode,0,_nb_max_periode_ds);
	_pos_table_ds = _interval(_pos_table_ds,0,_DS_periode);

	if (_DS_periode<4) return;
	if (_DS_chercheper>0) return;


	phase=0;
	if (_presence_param_c(dhs,_p_phase_ds) )  phase = 0.001* (double) _param_c(dhs,_p_phase_ds);

	//  je detecte a 2f  avec  4*PI
	cs = cos( 4 * PI * (double) _DS_cpt / _DS_periode + 2 * PI * phase );
	ss = sin( 4 * PI * (double) _DS_cpt / _DS_periode + 2 * PI * phase );
	//--- il faut ensuite sommer tous les points de la _DS_periode pour chaque bolo
	// j'ecris les data dans mes table au point _pos_table_ds Le resultat est la somme de la table normalisee
	if (_presence_datadet(dhs,_dd_RF_didq) )			// detection synchrone
		for(n_bol=0; n_bol<dhs->nb_detecteurs; n_bol++) {
			_table_ds_mesure_sin[n_bol*_nb_max_periode_ds + _pos_table_ds] = ss * _data_pdd(dhs,Dd,_dd_RF_didq,nper)[n_bol];
			_table_ds_mesure_cos[n_bol*_nb_max_periode_ds + _pos_table_ds] = cs * _data_pdd(dhs,Dd,_dd_RF_didq,nper)[n_bol];
		}

	if (_presence_datadet(dhs,_dd_V_bolo) )			// detection synchrone
		for(n_bol=0; n_bol<dhs->nb_detecteurs; n_bol++) {
			_table_ds_mesure_sin[n_bol*_nb_max_periode_ds + _pos_table_ds]  = ss * _data_pdd(dhs,Dd,_dd_V_bolo,nper)[n_bol];
			_table_ds_mesure_cos[n_bol*_nb_max_periode_ds + _pos_table_ds]  = cs * _data_pdd(dhs,Dd,_dd_V_bolo,nper)[n_bol];
		}


	for(n_bol=0; n_bol<dhs->nb_detecteurs; n_bol++) {
		DS_sin =0;
		DS_cos =0;
		if (!_DS_chercheper)   
			for(j=0; j<_DS_periode; j++) {
				DS_sin += _table_ds_mesure_sin[n_bol*_nb_max_periode_ds + j] ;
				DS_cos += _table_ds_mesure_cos[n_bol*_nb_max_periode_ds + j] ;
			}
		_data_pdd(dhs,Dd,_dd_ds_pha,nper)[n_bol] = DS_cos/ (double) _DS_periode;
		_data_pdd(dhs,Dd,_dd_ds_qua,nper)[n_bol] = DS_sin/ (double) _DS_periode;
	}
	_pos_table_ds = (_pos_table_ds +1) % _DS_periode;
}


/****************************************************
*                 CALCULE_DATA_MPPSYNC             *
****************************************************/
static void brut_to_data_mppsync(Data_header_shared_memory *dhs,int4 *Br,double *Dd,int z) {
	(void) (Br);
	int i;
	int retard=0;
	if (_presence_param_c(dhs,_p_retard_data) )  retard = _param_c(dhs,_p_retard_data);

	for (i=0; i<dhs->nb_pt_bloc; i++) {
		int pos = _posrt(retard, i);
		if (_presence_brut_databox(dhs,_db_status  ,z)) _data_pb(dhs,Dd,_db_status,  z,i) = (double)_brut_retarde_box(_db_status,pos,z);
		if (_presence_brut_databox(dhs,_db_position,z)) _data_pb(dhs,Dd,_db_position,z,i) = (double)_brut_retarde_box(_db_position,pos,z);
		if (_presence_brut_databox(dhs,_db_synchro ,z)) _data_pb(dhs,Dd,_db_synchro, z,i) = (double)_brut_retarde_box(_db_synchro,pos,z);
	}
}

/****************************************************
*                 brut_to_data_antenna             *
****************************************************/
static void brut_to_data_antenna(Data_header_shared_memory *dhs,int4 *Br,double *Dd) {
	//---------------   je copie les donnees antenna en ajustant les unitees  et sans retard    -------------

	_copy_brut_to_data(_d_antMJD_int,1.);
	_copy_brut_to_data(_d_antMJD_dec,1e-9);
	_copy_brut_to_data(_d_antLST,1e-8);
	_copy_brut_to_data(_d_antxoffset,1e-8);
	_copy_brut_to_data(_d_antyoffset,1e-8);
	_copy_brut_to_data(_d_antAz,1e-8);
	_copy_brut_to_data(_d_antEl,1e-8);
	_copy_brut_to_data(_d_antMJDf_int,1.);
	_copy_brut_to_data(_d_antMJDf_dec,1e-9);
	_copy_brut_to_data(_d_antactualAz,PI/180/3600*9./1024.);
	_copy_brut_to_data(_d_antactualEl,PI/180/3600*9./1024.);
	_copy_brut_to_data(_d_anttrackAz, PI/180/3600*9./1024.);
	_copy_brut_to_data(_d_anttrackEl, PI/180/3600*9./1024.);
}


/***********************************************
*                 brut_to_data_map             *
************************************************/
static void brut_to_data_map(Data_header_shared_memory *dhs,int4 *Br,double *Dd) {
	//---------------   je copie les donnees antenna en ajustant les unitees  et sans retard    -------------
	_copy_brut_to_data(_d_map_tbm,1e-5);
	_copy_brut_to_data(_d_map_t4k,1e-5);
	_copy_brut_to_data(_d_map_pinj,1e-5);
}

/***********************************************
*                 brut_to_data_sourceRF          *
************************************************/
static void brut_to_data_sourceRF(Data_header_shared_memory *dhs,double *Dd)
{
/*
int z;
for(z=0; z<dhs->nb_boites_mesure; z++)
    {
    uint4 *RG_sourceRF=reglage_pointer(dhs,_r_sourceRF,z);
    if(RG_sourceRF)
        {
            uint4 freq=RG_sourceRF[_freq_sourceRF];//RG_sourceRF[_freq_sourceRF]
            int4 ampl=RG_sourceRF[_ampli_sourceRF];//en mdBm pour avoir des entiers negatifs    
        int ii;
        for (ii=0;ii<dhs->nb_pt_bloc;ii++)
            _data_pb(dhs,Dd,_db_freq,z,ii) = freq;
        for (ii=0;ii<dhs->nb_pt_bloc;ii++)
                _data_pb(dhs,Dd,_db_freq,z,ii) = freq;
        }
    }
*/
}


/****************************************************
*                 CALCULE_DATA_POINTAGE             *
****************************************************/
// tout le pointage et les messages est retarde en utilisant le retard du param :   _prm(dhs)[_p_retard_data][0];

static void brut_to_data_pointage(Data_header_shared_memory *dhs,double *Dd) {	
	//  calcul dUser et dUser_moyenne pour tout le bloc (36 points)
	int z,i,j;
	int n_bol;
	Chg_coor chc[_nb_matrices]={{0.0, {0.0,0.0,0.0}, 0.0, {0.0,0.0}}};
	int retard=0;
	Etalon_optique_matrice matrice_etalon[_nb_matrices];


	if (! _presence_brut(dhs,_d_speed))	return;
	if (! _presence_brut(dhs,_d_Az) )	return;

	if (_presence_param_c(dhs,_p_retard_data) )  retard = _param_c(dhs,_p_retard_data);


	//-----  Etalon_optique_matrice  est une structure compose d'une suite de 4 int4
	/*
	for(z=0;z<_nb_matrices;z++)   matrice_etalon[z].g=0;

	if (_prm(dhs)[_p_matriceA_g])
		{
		matrice_etalon[0].alpha =   _prm(dhs)[_p_matriceA_alpha][0];
		matrice_etalon[0].x0 =   _prm(dhs)[_p_matriceA_x0][0];
		matrice_etalon[0].y0 =   _prm(dhs)[_p_matriceA_y0][0];
		matrice_etalon[0].g  =   _prm(dhs)[_p_matriceA_g][0];
		}
	if (_prm(dhs)[_p_matriceB_g])
		{
		matrice_etalon[1].alpha =   _prm(dhs)[_p_matriceB_alpha][0];
		matrice_etalon[1].x0	=   _prm(dhs)[_p_matriceB_x0][0];
		matrice_etalon[1].y0	=   _prm(dhs)[_p_matriceB_y0][0];
		matrice_etalon[1].g		=   _prm(dhs)[_p_matriceB_g][0];
		}
	*/
	for(z=0; z<_nb_matrices; z++) {
		matrice_etalon[z].alpha	= 0;
		matrice_etalon[z].x0	= 0;
		matrice_etalon[z].y0	= 0;
		matrice_etalon[z].g		= 1000;
	}




	for(z=0; z<_nb_matrices-1; z++)	init_chc(&chc[z],matrice_etalon+z);

	//printf("\n matrice 0 : chc.g = %g   chc.alpha=%g ",chc[0].grossissement,chc[0].dalpha);

	//--------------  ici on a les pointage brut retarde et en double dans  _brut_retarde(p,i)  -----------------------------

	//---------------   je copie les pointage en ajustant les unitees     -----------------------------
	for (i=0; i<dhs->nb_pt_bloc; i++) {
		Point pointage;
		Point pointage_matrice;
		Point pointage_azel;
		Point pointage_radec;
		double rotazel;
		double paralactic;

		int pos = _posrt(retard, i);

		if (_brut_retarde(_d_El,pos) ==0 ) {									// elevation toujours nulle pour table xy
			if (_presence_data(dhs,_d_ofs_X ))  _data_pc(dhs,Dd,_d_ofs_X,i) = 1e-1*(_brut_retarde(_d_ofs_X,pos)); // ce sont des diziemes de mm co,vertis en mm
			if (_presence_data(dhs,_d_ofs_Y ))  _data_pc(dhs,Dd,_d_ofs_Y,i) = 1e-1*(_brut_retarde(_d_ofs_Y,pos)); // ce sont des diziemes de mm co,vertis en mm
		} else {                                                                //  pour le telescope a l'IRAM  en micro radians
			if (_presence_data(dhs,_d_ofs_X ))  _data_pc(dhs,Dd,_d_ofs_X,i) = 1e-6*(_brut_retarde(_d_ofs_X,pos)); // ce sont des mircroradians convertis en radians
			if (_presence_data(dhs,_d_ofs_Y ))  _data_pc(dhs,Dd,_d_ofs_Y,i) = 1e-6*(_brut_retarde(_d_ofs_Y,pos)); // ce sont des mircroradians convertis en radians
		}
		if (_presence_data(dhs,_d_Az ))   _data_pc(dhs,Dd,_d_Az,i)  = _d2ra(_brut_retarde(_d_Az,pos)); // ce sont des mircrodegres convertis en radians
		if (_presence_data(dhs,_d_El ))   _data_pc(dhs,Dd,_d_El,i)  = _d2ra(_brut_retarde(_d_El,pos)); // ce sont des mircrodegres convertis en radians
		if (_presence_data(dhs,_d_Ra ))   _data_pc(dhs,Dd,_d_Ra,i)  = _r2ra(_brut_retarde(_d_Ra,pos)); // ce sont des mircroradians convertis en radians
		if (_presence_data(dhs,_d_Dec ))  _data_pc(dhs,Dd,_d_Dec,i) = _r2ra(_brut_retarde(_d_Dec,pos));	// ce sont des mircroradians convertis en radians
		if (_presence_data(dhs,_d_LST ) ) _data_pc(dhs,Dd,_d_LST,i) = _r2ra(_brut_retarde(_d_LST,pos));	// ce sont des mircroradians convertis en radians
		if (_presence_data(dhs,_d_tau ))  _data_pc(dhs,Dd,_d_tau,i) = 0.0001*(_brut_retarde(_d_tau,pos));	// conversion de tau par division par 1e4
		//decimale MJD   :  calcul uniquement la decimale
		if (_presence_data(dhs,_d_MJD ))  _data_pc(dhs,Dd,_d_MJD,i) = _brut_retarde(_d_MJD_int,pos) + 1e-8*_brut_retarde(_d_MJD_deci,pos);
		//if (_presence_data(dhs,_d_MJD ))  _data_pc(dhs,Dd,_d_MJD,i) = 1e-8*_brut_retarde(_d_MJD_deci,pos);

		rotazel		=	_d2ra(_brut_retarde(_d_El,pos))+PI/2;			// ce sont des mircroradians convertis en radians
		paralactic	=	_r2ra(_brut_retarde(_d_Paral,pos));				// ce sont des mircroradians convertis en radians

		if (_presence_data(dhs,_d_rotazel )) _data_pc(dhs,Dd,_d_rotazel,i)= rotazel;
		if (_presence_data(dhs,_d_Paral ))	_data_pc(dhs,Dd,_d_Paral,i)	 = paralactic;

		//--------------    je copie tous les messages qui sont identiques en brut et en data	 de _d_year a  _d_speed    --------------------
		for(j=0; j<=_d_speed-_d_year; j++)	 
			if (_presence_data(dhs,_d_year+j )) 
				_data_pc(dhs,Dd,_d_year+j,i)	=  _brut_retarde(_d_year+j,pos)	;

		//--------------    POINTAGE BRUT  en  mm pour la table xy et en arc sec  pour le telescope IRAM    ----------------------------------------------

		if (_brut_retarde(_d_El,pos) ==0 ) {									// elevation toujours nulle pour table xy
			pointage.x = 0.1*_brut_retarde(_d_ofs_X,pos);		// pour table xy
			pointage.y = 0.1*_brut_retarde(_d_ofs_Y,pos);
			rotazel=0;          // on a alors  ofs_X , ofs_Y   ==   ofs_Az , _ofs_El
		} else {	// elevation toujours non nulle a l'IRAM
			//pointage.x =  _r2mr(_brut_retarde(_d_ofs_X,pos));
			// attention: _d_El est en microdegre et je le passe en radian
			pointage.x =	cos(_d2ra(_brut_retarde(_d_El,pos))) * _r2mr(_brut_retarde(_d_ofs_X,pos));
			pointage.y =	_r2mr(_brut_retarde(_d_ofs_Y,pos));			// passe de microrad en seconde d'arc
		}

		//if (i==1)  printf("\n  brut table2  = %d,%d   ",_brut_retarde(_d_ofs_X,1),_brut_retarde(_d_ofs_Y,1));
		//if (i==1)  printf("\n el=%d    brut xy = %d , %d    pointage xy = %g,%g",
		//		_brut_retarde(_d_El,pos),_brut_retarde(_d_ofs_X,pos),_brut_retarde(_d_ofs_Y,pos),pointage.x,pointage.y);

		//--------------    je calcule les offset dans les differents systemes de coordonnees    ----------------------------------------------


		pointage_matrice = pointage;														//  pointage ofset  matrice
		_rotation(pointage_matrice,  -1.0 * rotazel);

		if (_presence_data(dhs,_d_ofs_Mx )   && _presence_data(dhs,_d_ofs_My) ) {
			_data_pc(dhs,Dd,_d_ofs_Mx,i) = pointage_matrice.x;
			_data_pc(dhs,Dd,_d_ofs_My,i) = pointage_matrice.y;
			//			if (i==1) printf("\n pointage datapc ofset X = %g ",_data_pc(dhs,Dd,_d_ofs_X,i));
		}

		if (_presence_datadet(dhs,_dd_X_det )   && _presence_datadet(dhs,_dd_Y_det) )				//  pointage ofset matrice corrigee detecteurs
			for(n_bol=0; n_bol<dhs->nb_detecteurs; n_bol++) {
				Point xy;
				xy.x = _Xpix(dhs,n_bol);
				xy.y = _Ypix(dhs,n_bol);
				z=_array(dhs,n_bol);
				_data_pdd(dhs,Dd,_dd_X_det,i)[n_bol] = _X_ciel_def(xy,chc[z],pointage_matrice);
				_data_pdd(dhs,Dd,_dd_Y_det,i)[n_bol] = _Y_ciel_def(xy,chc[z],pointage_matrice);
			}

		pointage_azel = pointage;															//  pointage ofset azel

		if (_presence_data(dhs,_d_ofs_Az )   && _presence_data(dhs,_d_ofs_El) ) {
			_data_pc(dhs,Dd,_d_ofs_Az,i) = pointage_azel.x;
			_data_pc(dhs,Dd,_d_ofs_El,i) = pointage_azel.y;
		}

		if (_presence_datadet(dhs,_dd_Az_det )   && _presence_datadet(dhs,_dd_El_det) ) {			//  pointage ofset azel corrigee detecteurs
			for(z=0; z<_nb_matrices; z++) {
				init_chc(&chc[z],matrice_etalon+z);
				prepare_chc_azel(&chc[z],_decalage_rotation(matrice_etalon+z), rotazel );
			}

			for(n_bol=0; n_bol<dhs->nb_detecteurs; n_bol++) {
				Point xy;
				xy.x = _Xpix(dhs,n_bol);
				xy.y = _Ypix(dhs,n_bol);
				z=_array(dhs,n_bol);
				_data_pdd(dhs,Dd,_dd_Az_det,i)[n_bol] =	_X_ciel_def(xy,chc[z],pointage_azel);
				_data_pdd(dhs,Dd,_dd_El_det,i)[n_bol] =	_Y_ciel_def(xy,chc[z],pointage_azel);
				//if (i==3) printf("\n i=%d  n_bol=%d z=%d x,y=%g,%g az=%g  azth=%g  ",i,n_bol,z,xy.x,xy.y,_data_pd(dhs,Dd,_X_dd_pointage_azel][i][n_bol],_data_pd(dhs,Dd,_X_dd_pointage_azel_th][i][n_bol]);
			}
		}

		pointage_radec = pointage;															//  pointage ofset  radec
		_rotation((pointage_radec), -1* paralactic);

		if (_presence_data(dhs,_d_ofs_Ra )   && _presence_data(dhs,_d_ofs_Dec) ) {
			_data_pc(dhs,Dd,_d_ofs_Ra,i)  = pointage_radec.x;
			_data_pc(dhs,Dd,_d_ofs_Dec,i) = pointage_radec.y;
		}


		if (_presence_datadet(dhs,_dd_Ra_det )   && _presence_datadet(dhs,_dd_Dec_det) ) {		//  pointage ofset radec corrigee detecteurs
			for(z=0; z<_nb_matrices; z++) {
				init_chc(&chc[z],matrice_etalon+z);
				prepare_chc_radec(&chc[z],_decalage_rotation(matrice_etalon+z),rotazel,paralactic);
			}


			for(n_bol=0; n_bol<dhs->nb_detecteurs; n_bol++) {
				Point xy;
				xy.x = _Xpix(dhs,n_bol);
				xy.y = _Ypix(dhs,n_bol);
				z=_array(dhs,n_bol);
				_data_pdd(dhs,Dd,_dd_Ra_det, i)[n_bol] = _X_ciel_def(xy,chc[z],pointage_radec);
				_data_pdd(dhs,Dd,_dd_Dec_det,i)[n_bol] = _Y_ciel_def(xy,chc[z],pointage_radec);
			}
		}
	}

	//i=0;if (_presence_data(dhs,_d_MJD )) printf("\n MJDint=%d  mjd deci=%d  mjd double=%10.6f ",_brut_retarde(_d_MJD_int,pos),_brut_retarde(_d_MJD_deci,pos),_data_pc(dhs,Dd,_d_MJD,i));				// ce sont des jours

	//printf("\n pointage ofset(5)  brut= %g,%g        data = %g,%g ",_brut_retarde(_d_ofs_X,5),_brut_retarde(_d_ofs_Y,5),_data_pc(dhs,Dd,_d_ofs_X,5),_data_pc(dhs,Dd,_d_ofs_Y,5));

	//{int i;double valeur=0;for(i=0;i<dhs->nb_pt_bloc;i++)	valeur+=_data_pc(dhs,Dd,_d_ofs_X,i);
	///_data_ec(dhs,Dd,k,i);
	//		printf(" moyenne=%g ; %g ",valeur/dhs->nb_pt_bloc ,moyenne_bloc_data_c(dhs,Dd,_idd(dhs)[_d_ofs_X])); }


}



//===============================================================================================================================
//======																												=========
//======	data_table_bolo.c		le calcul des db->dUser a  partir  des   db->dBrut		pour les bolos				=========
//======																												=========
//===============================================================================================================================


/*
static void brut_to_data_bediff(    Data_header_shared_memory *dhs, int4 *Br,double *Dd, int n_bol, double *val,double nb_coups_mlpa);
static void brut_to_data_mupa(      Data_header_shared_memory *dhs, int4 *Br,double *Dd, int n_bol, double *val_pre, double *filtre, int option,double muxfiltre);   //  calcule les valeurs de gg_dd data  a partir de db->dd _brute
static void brut_to_data_bemux(     Data_header_shared_memory *dhs, int4 *Br,double *Dd, int n_bol, double *val_pre, double *filtre, int option,double muxfiltre);   //  calcule les valeurs de gg_dd data  a partir de db->dd _brute
static void brut_to_data_bemux_gene(Data_header_shared_memory *dhs, int4 *Br,double *Dd, int n_bol, double *val_pre, double *filtre, double muxfiltre);
static void brut_to_data_bemux_bolo(Data_header_shared_memory *dhs, int4 *Br,double *Dd, int n_bol, double *val_pre, double *filtre, int option,double muxfiltre);
*/

extern char *Buffer_temp;


/****************************************************
*                  CALCUL  DATA   BOLO 					*
*****************************************************/
//  a partir de gg->dd _brute, fabrique les data en double a tracer
//  dd _brute  contient des sommes et il faut calculer plus - moins dans le cas d'une MMLPA ou BEBO
//  donne la valeur brute en unite du convertisseur, non affectee du gain
//   comme j'ai divise par 2 les valeurs brutes, il faudra remultiplier par 2 pour trouver le bon resultat
//   la conversion en microvolt est faite a la fin de cette fonction avec    bol_micro_volt_2
static void brut_to_data_bolo(Data_header_shared_memory *dhs, int4 *Br,double *Dd) {
	int n_bol,p;
	uint4 *RG_opera = reglage_pointer(dhs,_r_opera,-1);
	uint4 *RG1_opera = reglage_pointer(dhs,_r_o_rg1,-1);
	if (!RG_opera) return;
	def_gains

	//-------------------------------  d'abord les courbes periode converties en doubles --------------------------------
	int nb_per=_nb_mes_per(RG_opera);
	for(n_bol=0; n_bol<dhs->nb_detecteurs; n_bol++)
		//for(p=0;p<dhs->nb_brut_periode;p++)
	{
		#ifdef debug
			if (n_bol==4) printf("\n brut to data periode bolo%d  nb_per=%d : \n",n_bol,nb_per);
		#endif
		for(p=0; p<nb_per; p++) {
			_data_periode(dhs,Dd,n_bol)[p] = (double) (0xffff & _brut_periode(dhs,Br,n_bol)[p]);
			#ifdef debug
				if (n_bol==4) printf(" p=%d %x ",p,0xffff & (int)_data_periode(dhs,Dd,n_bol)[p]);
			#endif
		}
	}

	//-------------------------------  ensuite les donnees des bolo calcul du + -       --------------------------------
	for(n_bol=0; n_bol<dhs->nb_detecteurs; n_bol++) {
		#ifdef debug
			if (n_bol==1) printf("\n _nb_coups_MLPA=%d ",_nb_coups_MLPA(RG_opera));
		#endif
		int j;
		//if (n_bol==2) printf(" nb coupsMLPA=%g ",nb_coups_MLPA);
		for (j=0; j<dhs->nb_pt_bloc; j++) {
			int j2 = j%2;		// la parite 1 ou 0
			int sg=((j2*2)-1);	// le signe de la detection synchrone = +1 ou -1
			int nbc = _nb_coups_MLPA(RG_opera);		// le nombre de coups dans chaque demiperiode valide
			double valeur_ds = (double)_brut_pdd(dhs,Br,_dd_boloA,j)[n_bol];		// la valeur dans le bloc bolo convertie en double
			if ((nbc>1) && _presence_datadet(dhs,_dd_V_bolo) )
				_data_pdd(dhs,Dd,_dd_V_bolo,j)[n_bol]=sg*(valeur_ds-_val_pre_bolo[n_bol])/(2*nbc);	// _dd_V_bolo : la tension demodulee +-(Vpair - V impair)

			//---  je rajoute le 15 novembre 2015
			if (_presence_datadet(dhs,_dd_boloA) ) _data_pdd(dhs,Dd,_dd_boloA,j)[n_bol]=(double)_brut_pdd(dhs,Br,_dd_boloA,j)[n_bol];
			if (_presence_datadet(dhs,_dd_boloB) ) _data_pdd(dhs,Dd,_dd_boloB,j)[n_bol]=(double)_brut_pdd(dhs,Br,_dd_boloB,j)[n_bol];

			//if (j<4) if (n_bol==2) printf("type=%x  j=%d  val_pre[n_bol] = %g   valeur_ds = %g  datapd= %g \n ",_type_det(dhs,n_bol),j,val_pre[n_bol],valeur_ds,_data_pdd(dhs,Dd,_dd_V_bolo,j)[n_bol]);
			_val_pre_bolo[n_bol]=valeur_ds;
			if ((nbc>1) && _presence_datadet(dhs,_dd_V_brut) ) _data_pdd(dhs,Dd,_dd_V_brut,j)[n_bol]=valeur_ds/(nbc);		// _dd_V_brut  valeur brut normalisee par nbc

			// correction du gain sur _d_V_bolo  et sur  _d_V_brut
			if (_presence_datadet(dhs,_dd_V_bolo) )  _data_pdd(dhs,Dd,_dd_V_bolo,j)[n_bol] = bol_micro_volt_2(dhs,_data_pdd(dhs,Dd,_dd_V_bolo,j)[n_bol],n_bol);
			if (_presence_datadet(dhs,_dd_V_brut) )  _data_pdd(dhs,Dd,_dd_V_brut,j)[n_bol] = bol_micro_volt_2(dhs,_data_pdd(dhs,Dd,_dd_V_brut,j)[n_bol],n_bol);    	// _dd_V_brut


			//if (_presence_datadet(dhs,_dd_V_dac) )  _data_pdd(dhs,Dd,_dd_V_dac,j)[n_bol]=DAC_muV(dhs,n_bol);		//	V en microVolts	pris dans le reglage
			//if (_presence_datadet(dhs,_dd_I_dac) )  _data_pdd(dhs,Dd,_dd_I_dac,j)[n_bol]=DAC_muA(dhs,n_bol);		//	I en microA;

		}
	}
}





/****************************************************
*                  CALCUL  DATA   BOLO 					*
*****************************************************/
//  a partir de gg->dd _brute, fabrique les data en double a tracer
//  dd _brute  contient des sommes et il faut calculer plus - moins dans le cas d'une MMLPA ou BEBO
//  donne la valeur brute en unite du convertisseur, non affectee du gain
//   comme j'ai divise par 2 les valeurs brutes, il faudra remultiplier par 2 pour trouver le bon resultat
//   la conversion en microvolt est faite a la fin de cette fonction avec    bol_micro_volt_2
/*
void	brut_to_data_bolo(Data_header_shared_memory * dhs, int4 * Br,double * Dd)
{
	int n_bol,p,j;


	#define		_nb_max_bolo_provisoire 900	//abprovisoirement pour des dimensionnement de tabeaaux a  supprimer

	def_gains
//static double val_pre[_nb_max_bolo_provisoire];
//printf("\nbrutbolo_to_data()  ");
//printf(" %d detecteurs et %d pts periode ",dhs->nb_detecteurs,dhs->nb_brut_periode);

//printf(" nb MLPA=%d ",_nb_coups_MLPA(RG_opera));
//printf(" nper=%d ",nb_mesures_per);
//printf(" tm=%d ",_temp_mort(RG_opera));
	uint4* RG_opera = reglage_pointer(dhs,_r_opera,-1);
	uint4* RG1_opera = reglage_pointer(dhs,_r_o_rg1,-1);
	if (!RG_opera) return;
//-------------------------------------------------------------------------------------------------------------------
//-------------------------------  d'abord les courbes periode converties en doubles --------------------------------
	int nb_mesures_per=_nb_mes_per(RG_opera);
	for(n_bol=0;n_bol<dhs->nb_detecteurs;n_bol++)
		//for(p=0;p<dhs->nb_brut_periode;p++)
		for(p=0;p<nb_mesures_per;p++)
			_data_periode(dhs,Dd,n_bol)[p] = 0xffff & _brut_periode(dhs,Br,n_bol)[p];

// normalement, ici j'ai une valeur sur 15 bit et le signal de phase dans le bit 16
//n_bol=1; printf("\nbrutbolo_to_data%d : ",n_bol);for(j=0;j<_nb_mes_per(RG_opera)-1;j++) printf(" %x",0xffff & (int)_data_periode(dhs,Dd,n_bol)[j]);printf("\n");


//-------------------------------------------------------------------------------------------------------------------
//-------------------------------  ensuite les donnees des bolo calcul du + -       --------------------------------
for(n_bol=0;n_bol<dhs->nb_detecteurs;n_bol++)
		{
		//if (n_bol==2) printf(" MLPA2=%d ",_nb_coups_MLPA(RG_opera));

		switch(_type_det(dhs,n_bol) & 0x70)	// apelle les fonctions de calcul des data
			{
//			case _type_MLPA		:	break;
			case _type_BEDIFF	:	brut_to_data_bediff(dhs,Br,Dd,n_bol,_val_pre_bolo,_nb_coups_MLPA(RG_opera));							break;
//			case _type_MUPA		:	brut_to_data_mupa(dhs,Br,Dd,n_bol,_val_pre_bolo,filtre,Gr,di->mux_option,di->mux_filtre_ref);	break;
//			case _type_BEMUX	:	brut_to_data_bemux(dhs,Br,Dd,n_bol,_val_pre_bolo,filtre,Gr,di->mux_option,di->mux_filtre_ref);break;
			default				:	break;
			}

		for(j=0;j<dhs->nb_pt_bloc;j++)
			{
			// correction du gain sur _d_V_bolo  et sur  _d_V_brut
			if (_presence_datadet(dhs,_dd_V_brut) )
					//if (Idd[_d_V_bolo]>=0) _data_pdd(dhs,Dd,_dd_V_bolo,j)[n_bol] = bol_micro_volt_2(_data_pdd(dhs,Dd,_dd_V_bolo,j)[n_bol],n_bol);
			if (_presence_datadet(dhs,_dd_V_brut) )  _data_pdd(dhs,Dd,_dd_V_brut,j)[n_bol] = bol_micro_volt_2(dhs,_data_pdd(dhs,Dd,_dd_V_brut,j)[n_bol],n_bol);    	// _dd_V_brut


//            if (_presence_datadet(dhs,_dd_V_dac) )  _data_pdd(dhs,Dd,_dd_V_dac,j)[n_bol]=DAC_muV(dhs,n_bol);		//	V en microVolts	pris dans le reglage
//			if (_presence_datadet(dhs,_dd_I_dac) )  _data_pdd(dhs,Dd,_dd_I_dac,j)[n_bol]=DAC_muA(dhs,n_bol);		//	I en microA;

			}


		}

}
*/

/****************************************************
*               CALCULE_DATA_BEDIFF                 *
****************************************************/
/*
#define _signe_ds(j)	((j*2)-1)
static void brut_to_data_bediff(Data_header_shared_memory * dhs, int4 * Br,double * Dd, int n_bol,double *val_pre,double nb_coups_MLPA)
//  calcule les valeurs de _d_V_bolo  et  _d_V_brut
{
int j1,j2;
//if (n_bol==2) printf(" nb coupsMLPA=%g ",nb_coups_MLPA);
for (j1=0;j1<dhs->nb_pt_bloc;j1++)
		{
		j2 = j1%2;		// la parite
		double valeur_ds=(double)_brut_pdd(dhs,Br,_dd_boloA,j1)[n_bol];		// la valeur dans le bloc bolo convertie en double
		if ((nb_coups_MLPA>1) && _presence_datadet(dhs,_dd_V_bolo) ) _data_pdd(dhs,Dd,_dd_V_bolo,j1)[n_bol]=_signe_ds(j2)*(valeur_ds-val_pre[n_bol])/(2*nb_coups_MLPA);	// la 1ere data brute : la tension
		//if (j1<4) if (n_bol==2) printf("type=%x  j=%d  val_pre[n_bol] = %g   valeur_ds = %g  datapd= %g \n ",_type_det(dhs,n_bol),j1,val_pre[n_bol],valeur_ds,_data_pdd(dhs,Dd,_dd_V_bolo,j1)[n_bol]);
		val_pre[n_bol]=valeur_ds;
		if ((nb_coups_MLPA>1) && _presence_datadet(dhs,_dd_V_brut) ) _data_pdd(dhs,Dd,_dd_V_brut,j1)[n_bol]=valeur_ds/(nb_coups_MLPA);		// la data brute
		}
}
*/

/*
for (j1=0;j1<dhs->nb_pt_bloc;j1++)
	for (j2=0;j2<2;j2++)
		{
		double valeur_ds=(double)_brut_pdd(dhs,Br,_dd_boloA,2*j1+j2)[n_bol];		// la valeur dans le bloc bolo convertie en double
//		double valeur_ds=(double)db->dBrut[0][2*j1+j2][n_bol];		// la valeur dans le bloc bolo convertie en double
//		printf("type=%x  j=%d ancien_val_ds[n_bol] = %g   valeur_ds = %g \n ",_type_det(dhs,n_bol) & 0x70,j,ancien_val_ds[n_bol],valeur_ds);
		if (nb_coups_MLPA>1) _data_pdd(dhs,Dd,_dd_V_bolo,2*j1+j2)[n_bol]=_signe_ds(j2)*(valeur_ds-val_pre[n_bol])/(2*nb_coups_MLPA);	// la 1ere data brute : la tension
		val_pre[n_bol]=valeur_ds;
		if (nb_coups_MLPA>1) _data_pdd(dhs,Dd,_dd_V_brut,2*j1+j2)[n_bol]=valeur_ds/(nb_coups_MLPA);		// la data brute
		}
*/



/****************************************************
*                CALCULE_DATA_MUPA                  *
****************************************************/
/*
static void brut_to_data_mupa(Data_header_shared_memory * dhs, int4 * Br,double * Dd, int n_bol,double *val_pre,double *filtre, int option,double muxfiltre)//  calcule les valeurs de gg_dd data  a partir de db->dd _brute
{
//int option=_mux_option;
uint4 * RG_opera = reglage_pointer(dhs,_r_opera,-1);
double nb_coups_mux_general = _nb_coups_mux_general(RG_opera);
double nb_coups_mux_bolo = _nb_coups_mux_bolo(RG_opera);
//double muxfiltre=(double)_mux_filtre_zero;
//double muxfiltre=(double)_mux_filtre_ref;

int i,j2;
double valeur;
if ((nb_coups_mux_general<1) || (nb_coups_mux_bolo<1) ) return;

for (i=0;i<dhs->nb_pt_bloc;i++)	for (j2=0;j2<2;j2++)
	{
	j2 = i%2;
	valeur=(double)_brut_pdd(dhs,Br,_dd_boloA,i)[n_bol];
	//valeur=(double)db->dBrut[j2][i][n_bol];		// la valeur dans le bloc bolo convertie en double
	if (_type_det(dhs,n_bol)==_type_MUPA ) //  niveau zero du multiplexeur
				{
				if (!j2) 	// je calcule pour les valeurs paires
					{		// FILTRAGE de la valeur zero (indice pair)
					val_pre[n_bol]=(filtre[n_bol]*muxfiltre +(valeur/nb_coups_mux_general))/ (muxfiltre+1);
					val_pre[n_bol]	=	filtre[n_bol]-val_pre[n_bol];	// soustrait la valeur theorique
					_data_pdd(dhs,Dd,_dd_V_bolo,i)[n_bol]	=	val_pre[n_bol];
					}
				else	{	// valeur impaire = valeur theorique du zero
					_data_pdd(dhs,Dd,_dd_V_bolo,i)[n_bol] =	val_pre[n_bol];
					val_pre[n_bol]	=	valeur/nb_coups_mux_general;	// la valeure theorique du zero
					}
				}
	else
				{
				if (!j2)	// FILTRAGE de la valeur zero (indice pair)
						filtre[n_bol]=(filtre[n_bol]*muxfiltre +(valeur/nb_coups_mux_general))/ (muxfiltre+1);

				else		// mesure du bolo sur les indices impairs
						{
						val_pre[n_bol] = valeur/nb_coups_mux_bolo;
						if (option>1)  val_pre[n_bol] -= filtre[n_bol];
						//  pour test idem mux0 val_pre[n_bol] = filtre_val_ds[n_bol];
						}
	//			if (j==10) printf("  muxfiltre=%g   valeur paire= %g valeur filtre du zero =  %g  mesuree %g \n",muxfiltre,valeur/nb_coups_mux_general ,filtre_val_ds[n_bol],val_pre[n_bol]);
				_data_pdd(dhs,Dd,_dd_V_bolo,i)[n_bol]=val_pre[n_bol];		// 2 fois le meme point
	//			if (j==2) printf(" ,%d ",ancien_val_ds[n_bol]);
				}
			break;
	}
}
*/
/****************************************************
*               CALCULE_DATA_BEMUX                  *
****************************************************/
/*
#define  debug_camadia_blocks 0
static void brut_to_data_bemux(Data_header_shared_memory * dhs, int4 * Br,double * Dd, int n_bol,double *val_pre,double *filtre, int option,double muxfiltre)//  calcule les valeurs de gg_dd data  a partir de db->dd _brute
{
uint4* RG_opera=reglage_pointer(Dhs,_r_opera,-1);

if ((debug_camadia_blocks)&&(n_bol==0))	// pour le mux gene
	{
	printf("\nTmort : %d",_temp_mort(RG_opera));
	printf("\nTref : %d",_dur_ref(RG_opera));
	printf("\nNb coups mux gene : %d",_nb_coups_mux_general(RG_opera));
	printf("\nNb coups mux bolo : %d",_nb_coups_mux_bolo(RG_opera));
	}

if ((_nb_coups_mux_general(RG_opera)<1) || (_nb_coups_mux_bolo(RG_opera)<1) ) return;

#ifdef _avec_mux

if (__est_un_MUX_gene(Gp,n_bol))	brut_to_data_bemux_gene(db,n_bol, val_pre, filtre,Gr,muxfiltre);
else							brut_to_data_bemux_bolo(db,n_bol, val_pre, filtre,Gr,option,muxfiltre);
#endif
}
*/
/****************************************************
*             CALCULE_DATA_BEMUX_GENE               *
****************************************************/
/*
#define _jref	0	// valeur paire - pour mux gene et mux bolo
#define _jth	1	// valeur impaire - pour mux gene
#define _jbolo	1	// valeur impaire - pour mux bolo
static void brut_to_data_bemux_gene(Data_header_shared_memory * dhs, int4 * Br,double * Dd, int n_bol, double *val_pre, double *filtre,double muxfiltre)
{

int j1;
double valeur, val_pre_pre;
double nb_coups_mux_general = _nb_coups_mux_general(RG_opera);


for (j1=0;j1<dhs->nb_pt_bloc;j1++)
	{
	// mesure de la ref
	valeur=(double)db->dBrut[_jref][j1][n_bol];		// la valeur dans le bloc bolo convertie en double
														// pour la ref, c'est la somme sur tous les temps de mesure de la ref

	filtre[n_bol]=(filtre[n_bol]*muxfiltre + (valeur/nb_coups_mux_general)) / (muxfiltre+1);	// FILTRAGE de la valeur zero (indice pair)

	// valeur theorique du zero
	valeur=(double)db->dBrut[_jth][j1][n_bol];		// la valeur dans le bloc bolo convertie en double
														// pour la ref, c'est la somme sur tous les temps de mesure de la ref

	val_pre_pre=val_pre[n_bol];	// sauvegarde de la valeur avant de la remplacer
	val_pre[n_bol]	=	filtre[n_bol]-(valeur/nb_coups_mux_general);											// soustrait la valeur theorique du zero (valeur/_nb_coups_mux_general)

	_data_pd(dhs,Dd,0][2*j1][n_bol]		=	(val_pre[n_bol]+val_pre_pre)/2.;		// AUB, 11/03/2011 - valeur interpolee, plutot que de repeter deux fois le meme point
	_data_pd(dhs,Dd,0][2*j1+1][n_bol]	=	val_pre[n_bol];							//
	}

// AUB DEBUG : la valeur brute de brute
}
*/
/****************************************************
*             CALCULE_DATA_BEMUX_BOLO               *
****************************************************/
/*
void brut_to_data_bemux_bolo(Data_header_shared_memory * dhs, int4 * Br,double * Dd, int n_bol, double *val_pre, double *filtre, int option,double muxfiltre)
{
int j1;
double valeur,val_pre_pre;
double nb_coups_mux_general = _nb_coups_mux_general(RG_opera);
double nb_coups_mux_bolo = _nb_coups_mux_bolo(RG_opera);


for (j1=0;j1<dhs->nb_pt_bloc;j1++)
	{
	// mesure de la ref
	valeur=(double)db->dBrut[_jref][j1][n_bol];		// la valeur dans le bloc bolo convertie en double
														// pour les bolos, c'est la somme sur tous les temps de mesure du bolo


	filtre[n_bol]=(filtre[n_bol]*muxfiltre + (valeur/nb_coups_mux_general)) / (muxfiltre+1);	// FILTRAGE de la valeur zero (indice pair)

	// mesure du bolo sur les indices impairs
	valeur=(double)db->dBrut[_jbolo][j1][n_bol];		// la valeur dans le bloc bolo convertie en double
														// pour les bolos, c'est la somme sur tous les temps de mesure du bolo

	val_pre_pre=val_pre[n_bol];	// sauvegarde de la valeur avant de la remplacer
	val_pre[n_bol] = valeur/nb_coups_mux_bolo;

	if ((option==_mux_option_soustrait_ref)||(option==_mux_option_soustrait_ref_filtre))	val_pre[n_bol] -= filtre[n_bol];
	else																				val_pre[n_bol] = val_pre[n_bol]-0x8000;		// car l'ADC est bipolaire : ca c'est juste

	_data_pd(dhs,Dd,0][2*j1][n_bol]		=	(val_pre[n_bol]+val_pre_pre)/2.;	// AUB, 11/03/2011 - valeur interpolee, plutot que de repeter deux fois le meme point
	_data_pd(dhs,Dd,0][2*j1+1][n_bol]	=	val_pre[n_bol];						//
//	if ((j1==5)&&(n_bol==1))	printf("\n%g",_data_pd(dhs,Dd,0][2*j1][n_bol]);

// AUB DEBUG : la valeur brute de brute
//	valeur=(double)db->dBrut[_jbolo][j1][n_bol]/(double)_nb_coups_mux_bolo-0x8000;		// la valeur dans le bloc bolo convertie en double
//	_data_pd(dhs,Dd,0][2*j1][n_bol]		=	valeur;						// AUB, 11/03/2011 - valeur interpolee, plutot que de repeter deux fois le meme point
//	_data_pd(dhs,Dd,0][2*j1+1][n_bol]	=	valeur;						//
	}
}
*/


//===============================================================================================
//======																				=========
//======	       		 brut to  data 		pour les kid								=========
//======																				=========
//===============================================================================================


//  on a un element par boite de kid
// la demande de raz est commandee 1 sec apres un balayage  (  _brut_ec(dhs,Br,Ibr[_d_msq_A]+z,i)) est non nul )
// c'est pas tres propre mais au moins, ca marchera a la relecture des fichiers
char *Buffer_temp;

//----  je mets ces variables intermediaires dans le buffer temporaire

#define   _I   _iqdidq[4*n_bol + 0]
#define   _Q   _iqdidq[4*n_bol + 1]
#define   _dI  _iqdidq[4*n_bol + 2]
#define   _dQ  _iqdidq[4*n_bol + 3]

#define Table_derive(k,nbol,pos)	_table_derive[(k) + 5*((pos) + _interval_derive_dIdQ * (nbol))]
#define _mini_amplitude_dIdQ 10

static void duplique_bord_de_bande   (Data_header_shared_memory *dhs,int4 *Br);
static void brut_to_data_un_point_kid(Data_header_shared_memory *dhs,int4 *Br,double *Dd,int4 *liste_det2,int nper,int masque);
static void decorelle_un_point_kid   (Data_header_shared_memory *dhs,double *Dd,int nper);
static void    calcul_temps_pps(Data_header_shared_memory *dhs,int z,int4 *Br,double *Dd);

static void brut_to_data_un_point_kid_simple(Data_header_shared_memory *dhs,int4 *Br,double *Dd,int i);


/****************************************************
*                 calcul temps pps                  *
****************************************************/

void    calcul_temps_pps(Data_header_shared_memory *dhs,int z,int4 *Br,double *Dd)
{
// le temps pps precedent est dans          _table_temps_pps[z];
// la duree d'un sample est dans            _table_temps_pps[2*_nb_max_acqbox +  z];
// le numero de sample du pps precedent     _table_temps_pps[_nb_max_acqbox +  z];
double *t_pps_old     =   _table_temps_pps+z;
double *t_sample_old =   _table_temps_pps+ 1*_nb_max_acqbox +  z;
double *ecart_pps     =   _table_temps_pps +2*_nb_max_acqbox +  z;
int *pps_old       =   ((int*) (_table_temps_pps +3*_nb_max_acqbox)) +  z;
int    *sample_old   =  ((int*)  ( _table_temps_pps + 4*_nb_max_acqbox ))  + z;
int ii;
double tpps;
double ecpps;
int ecsample;

if(_presence_brut_databox(dhs,_db_o_pps,z))
    {
    for (ii=0;ii<dhs->nb_pt_bloc;ii++)
        {
        _data_pb(dhs,Dd,_db_o_pps,z,ii)=0;
        int pps= _brut_pb(dhs,Br,_db_pps,z,ii);
        int sample = _brut_pc(dhs,Dd,_d_sample,ii);
        
        if(pps) {
                tpps = _data_pb(dhs,Dd,_db_t_utc,z,ii);
            
                tpps = (double)( (int)(tpps+0.5) ) - 1e-6 * pps;
                tpps += _diviseur_kid(dhs) * 262144. / 500000000.;
				
                //ecpps= tpps - *t_pps_old;
                ecpps= 1 - 1e-6 * pps  + 1e-6  * (double) (*pps_old) ;
            
                if(ecpps < 0) ecpps += 86400.;
            
 
            
                ecsample = sample - *sample_old;
                if(ecsample<=0)  ecsample=1;

                ecpps /= ecsample;

                //if(z==1) printf("\n------  tpps=%8.3f  old tpps=%8.3f pps=%d  sample=%d  ecpps=%6.6f   ecsample=%d --------",
                //                    tpps,*t_pps_old,pps,sample,ecpps,ecsample);
                //if(z==1) usleep(100000);
            
                *ecart_pps    = ecpps;
                *sample_old = sample;
            
                *t_pps_old  = tpps;
                *pps_old    = pps;

            
                }
        else    {
                //if(z==1) printf("\n------   sample= %d  ecartsample=%d   ecpps=%8.6f --------",sample,sample - *sample_old,*ecart_pps);
                tpps = *t_pps_old  +  *ecart_pps * (sample - *sample_old);
                }
        _data_pb(dhs,Dd,_db_o_pps,z,ii) = tpps;
        }
    }
}


/****************************************************
*                 brut to_data_kid                  *
****************************************************/


static void brut_to_data_kid(Data_header_shared_memory *dhs,int4 *Br,double *Dd,int4 *liste_det2,char *buf_btd) {	
	//  calcule les valeurs de gg_dd data  a partir de gg->dd _brute
	int nper,z;
	int masque_calcul=0;
	Buffer_temp = buf_btd;

	if (buf_btd[0]==1) {     // initialisation
		((int *)(_buffer_flag))[0]=-1;	// demande initialisation des tableaux flag kid
		*_pos_table_derive = 0;
		for(z=0; z<dhs->nb_boites_mesure; z++)
			_demande_raz_didq[z]=_interval_derive_dIdQ+2 ;		// une demande de raz du didq
	}


	//-------------------------      copie des brut dans les data     ---------------------------------------------------
	//printf(" brut to_data_kid() ");

	for(z=0; z<dhs->nb_boites_mesure; z++) {            //  ici: copie des bruts de la 'box' (z) dans les data
		_copy_brut_to_databox(_db_t_utc,z,86400/1e9);   //  transforme les brut en mjd9 en secondes
		_copy_brut_to_databox(_db_pps,z,1);   			//  le retard du pps
		//_copy_brut_to_databox(_db_o_pps,z,1);   		//  l'ofset pps ne marche pas
		calcul_temps_pps(dhs,z,Br,Dd);
        


		_copy_brut_to_databox(_db_freq,z,0.01);
		_copy_brut_to_databox(_db_masq,z,1.0);
		_copy_brut_to_databox(_db_n_inj,z,1.0);
		_copy_brut_to_databox(_db_n_mes,z,1.0);
        _copy_brut_to_databox(_db_fRF,z,1.0);           // frequence sourceRF
		_copy_brut_to_databox(_db_pRF,z,1.0);           // puissance sourceRF
        
	}

	//duplique_bord_de_bande(dhs,Br);


	if (	(_presence_datadet(dhs,_dd_I))
		||  (_presence_datadet(dhs,_dd_Q))
		||	(_presence_datadet(dhs,_dd_dI))
		||	(_presence_datadet(dhs,_dd_dQ))
		||	(_presence_datadet(dhs,_dd_pI))
		||  (_presence_datadet(dhs,_dd_pQ))		) masque_calcul|=1;

	if (	(_presence_datadet(dhs,_dd_amplitude))
		||  (_presence_datadet(dhs,_dd_log_amplitude))
		||	(_presence_datadet(dhs,_dd_phase_IQ))
		||  (_presence_datadet(dhs,_dd_ph_rel)  )
		||	(_presence_datadet(dhs,_dd_amp_pIQ) )) masque_calcul|=3;

	if (	(_presence_datadet(dhs,_dd_F_tone)  )
		||	(_presence_datadet(dhs,_dd_dF_tone) )
		||  (_presence_datadet(dhs,_dd_k_angle) )
		||  (_presence_datadet(dhs,_dd_k_width) )
		||  (_presence_datadet(dhs,_dd_k_flag)  )) masque_calcul|=5;


	if (	(_presence_datadet(dhs,_dd_RF_deco) )
		||  (_presence_datadet(dhs,_dd_RF_didq) )
		||	(_presence_datadet(dhs,_dd_ds_pha)  )
		||	(_presence_datadet(dhs,_dd_ds_qua)  )
		||	(_presence_datadet(dhs,_dd_ap_dIdQ) )) masque_calcul|=9;


	//masque_calcul=0xff;		pour faire tous les calculs toujours !!

	if (!masque_calcul)	return;

	//printf("\nbrut_to_data_kid :  masque_calcul = %x     _demande_raz_didq[0]=%d   *_pos_table_derive=%d ",masque_calcul,_demande_raz_didq[0],*_pos_table_derive);


	for (nper=0; nper<dhs->nb_pt_bloc; nper++) {
		//	if (nper==0) printf("OPENMP: Mx=%d, Cur=%d\n", omp_get_max_threads(), omp_get_num_threads());
		brut_to_data_un_point_kid	(dhs,Br,Dd,liste_det2,nper,masque_calcul);
	}

}



/*
static void duplique_bord_de_bande(Data_header_shared_memory * dhs,int4 * Br)
{
int n_bande=_prm(dhs)[_p_nb_bande][0];
int bin_bande_total= _nb_kid_par_boite(dhs)/n_bande;
int bin_bande= _prm(dhs)[_p_tone_bande][0];
int n_mort=(bin_bande_total - bin_bande) /2;
int n,b,i,k,nbol1,nbol2,nper;
if (_presence_brut_data(dhs,_d_I) )
	for(n=0;n<_nb_boite_kid(dhs);n++) {
		for(b=1;b<n_bande;b++)
			for(i=0;i<2*n_mort;i++)
				{
				k = n * _nb_kid_par_boite(dhs) + b * bin_bande_total + i;	// le bin du debut de bande
				if (_prm(dhs)[_p_type][k])		{nbol1=k;nbol2=k-2*n_mort;}
					else						{nbol2=k;nbol1=k-2*n_mort;}
				for (nper=0;nper<dhs->nb_pt_bloc;nper++)
					{
					_brut_pdd(dhs,Br,_dd_I,nper)[nbol1] = _brut_pdd(dhs,Br,_dd_I,nper)[nbol2];
					_brut_pdd(dhs,Br,_dd_Q,nper)[nbol1] = _brut_pdd(dhs,Br,_dd_Q,nper)[nbol2];
					_brut_pdd(dhs,Br,_dd_dI,nper)[nbol1] = _brut_pdd(dhs,Br,_dd_dI,nper)[nbol2];
					_brut_pdd(dhs,Br,_dd_dQ,nper)[nbol1] = _brut_pdd(dhs,Br,_dd_dQ,nper)[nbol2];
					}
				}
	}
}
*/



/****************************************************
*                 CALCULE_DATA_UN_POINT_KID                  *
****************************************************/
static void brut_to_data_un_point_kid(Data_header_shared_memory *dhs,int4 *Br,double *Dd,int4 *liste_det2,int nper,int masque) {	//  pour 1 point dans le bloc
	int z;
	int kl;
	double deviation_modulation=0;

	double IIrel;
	double QQrel;
	double amp=0;    //,amp_rel;					// l'amplitude brute
	double phi0=0;
	//double phi;
	int p,pp,k;
	int n_bol;
	int old_reglage_nikel=0;		// mis a 1 pour les reglages anciens avec la deviation modulation en kHz

	double ddI,ddQ;
	double VI,VQ,MF,Ampdidq;
	// ce sont des kid et je suppose avoir dans les data, a la suite,   I,Q,dI,dQ

	*_pos_table_derive = ( *_pos_table_derive + 1 )  % _interval_derive_dIdQ;


	// je cherche a savoir si c'est un ancien format de reglage nikel
	//printf("\n");
	for(z=0; z<dhs->nb_boites_mesure; z++) {
		int nr = reglage_champ(dhs,_r_nikel,z);
		if (nr>=0) {
			int long_reglage= _longueur_champ_reglage(dhs,nr);
			if (long_reglage !=_nb_elements_reglage_kid)  old_reglage_nikel=1;
			//      printf(" z=%d  long_reglage = %d ",z,long_reglage);
		}
	}

	/*
	printf("\n ibr  (%d elements) = ",_nb_data_c_b_possibles+_nb_data_detecteur_possibles);
	for(i=0;i<_nb_data_c_b_possibles+_nb_data_detecteur_possibles;i++) if (_ibr(dhs)[i]!=-1) printf(" %d->%d  ",i,_ibr(dhs)[i]);
	printf("\n fin de lecture ibr \n");
	printf("\n idd  (%d elements) = ",_nb_data_c_b_possibles+_nb_data_detecteur_possibles);
	for(i=0;i<_nb_data_c_b_possibles+_nb_data_detecteur_possibles;i++) if (_idd(dhs)[i]!=-1) printf(" %d->%d  ",i,_idd(dhs)[i]);
	printf("\n fin de lecture idd \n");
	printf("\n ibx  (%d elements) = ",_nb_max_acqbox);
	for(i=0;i<_nb_max_acqbox;i++) printf(" %d->%d  ",i,_ibx(dhs)[i]);
	printf("\n fin de lecture ibx \n");
	*/

	#ifdef debug
		if (nper==0) printf("\n  brut to data kid avec masque = %d  et %d detecteurs actifs  ",masque,liste_det2[0]);
	#endif
	if (masque & 1) {
		for(kl=0; kl<liste_det2[0]; kl++) {
			//for(n_bol=0;n_bol<dhs->nb_detecteurs;n_bol++)
		
			n_bol=liste_det2[kl+1];
			//-------------------------   dans les data, les  I , Q , dI , dQ  sans retirer les undef    --------------------
			if (_presence_datadet(dhs,_dd_I))  _data_pdd(dhs,Dd,_dd_I ,nper)[n_bol] = (double)_brut_pdd(dhs,Br,_dd_I ,nper)[n_bol];
			if (_presence_datadet(dhs,_dd_Q))  _data_pdd(dhs,Dd,_dd_Q ,nper)[n_bol] = (double)_brut_pdd(dhs,Br,_dd_Q ,nper)[n_bol];
			if (_presence_datadet(dhs,_dd_dI)) _data_pdd(dhs,Dd,_dd_dI,nper)[n_bol] = (double)_brut_pdd(dhs,Br,_dd_dI,nper)[n_bol];
			if (_presence_datadet(dhs,_dd_dQ)) _data_pdd(dhs,Dd,_dd_dQ,nper)[n_bol] = (double)_brut_pdd(dhs,Br,_dd_dQ,nper)[n_bol];
			if (_presence_datadet(dhs,_dd_pI)) _data_pdd(dhs,Dd,_dd_pI,nper)[n_bol] = (double)_brut_pdd(dhs,Br,_dd_pI,nper)[n_bol];
			if (_presence_datadet(dhs,_dd_pQ)) _data_pdd(dhs,Dd,_dd_pQ,nper)[n_bol] = (double)_brut_pdd(dhs,Br,_dd_pQ,nper)[n_bol];
		}
	}

	//#define _test_det 11

#ifdef _test_det
	if (nper==2) {
		z=_acqbox(dhs,_test_det);
		printf("\n\n*********  _first_det_box(dhs,z)=%d ",_first_det_box(dhs,z));
	}
#endif



	if (masque & 0x4) {
		int zold=-1;
		uint4 *RG_nikel=NULL, *RG_freq=NULL, *RG_width=NULL;
		double freq_base=0;
		int nn1=0, nn2;
		int masq=0;
		// les 4 tableau suivant sont des pointeurs sur les donnees I,Q,dI,dQ dans le bloc brut br
		int4 *I  = _brut_pdd(dhs,Br,_dd_I, nper);
		int4 *Q  = _brut_pdd(dhs,Br,_dd_Q, nper);
		int4 *dI = _brut_pdd(dhs,Br,_dd_dI,nper);
		int4 *dQ = _brut_pdd(dhs,Br,_dd_dQ,nper);

		for(kl=0; kl<liste_det2[0]; kl++) {
			//for(n_bol=0;n_bol<dhs->nb_detecteurs;n_bol++)

			n_bol=liste_det2[kl+1];
			z=_acqbox(dhs,n_bol);
			if (z!=zold) {
				zold=z;					// je change de boite de mesure : recalcule ce qui depend des boites
				RG_nikel = reglage_pointer_nikel_amc(dhs,z);
				RG_freq=reglage_pointer(dhs,_r_k_freq,z);
				RG_width=reglage_pointer(dhs,_r_k_width,z);

				if (RG_nikel && RG_freq) {
					//f_bin= kid_balayage_freq_par_binX(RG_nikel);
					nn1 = _first_det_box(dhs,z);
					nn2 = _last_det_box(dhs,z);
					freq_base = 0.01*_brut_pb(dhs,Br,_db_freq,z,nper);
					if (_presence_brutbox(dhs,_db_masq,z)) masq=_brut_pb(dhs,Br,_db_masq,z,nper);
				}
			}

			// ici je fais le calcul pour chaque detecteur  n_bol
			int nk=n_bol-nn1;	// la place du detecteur dans sa boite
			int tangle=0;
			
			// This line is the slowest one of the entire program if you do not optimize the atan2 hidden inside the macro
			if (_presence_datadet(dhs,_dd_k_angle) || _presence_datadet(dhs,_dd_dF_tone))
				tangle= _dangleIQdIdQ(Q[n_bol],dQ[n_bol],I[n_bol],dI[n_bol]);		// radian
			
			if (_presence_datadet(dhs,_dd_F_tone))   _data_pdd(dhs,Dd,_dd_F_tone,nper)[n_bol]	= freq_base +(double)RG_freq[nk] *_f_bin;		// kHz
			if (_presence_datadet(dhs,_dd_k_width))	 _data_pdd(dhs,Dd,_dd_k_width,nper)[n_bol]	=  _width_du_reglage(RG_width,nk)*_f_bin;		// kHz
			if (_presence_datadet(dhs,_dd_k_angle))  _data_pdd(dhs,Dd,_dd_k_angle,nper)[n_bol]	=  tangle;										// radian
			if (_presence_datadet(dhs,_dd_k_flag))	 _data_pdd(dhs,Dd,_dd_k_flag,nper)[n_bol]	=
					(masq&_flags_du_masque) | (_flag_du_reglage(RG_width,nk)&_flags_du_reglage) ;	// flag entier
			if (_presence_datadet(dhs,_dd_dF_tone))  _data_pdd(dhs,Dd,_dd_dF_tone,nper)[n_bol]	=  tangle*_width_du_reglage(RG_width,nk)*_f_bin;	// kHz

#ifdef _test_det
			if ((nper==2) && (n_bol-_first_det_box(dhs,z) ==11) && (_type_det(dhs,n_bol)==__kid_pixel) ) {
				printf("\n _brut_pdd(dhs,Br,_dd_I,nper)[_test_det]=%d  _data_pdd(dhs,Dd,_dd_I,nper)[_test_det]=%g ",
					   _brut_pdd(dhs,Br,_dd_I,nper)[_test_det],_data_pdd(dhs,Dd,_dd_I,nper)[_test_det]);
			}
#endif
		}
	}


	int zold2=-1;
	uint4 *RG_nikel;
	int masq=0;
	double I,Q;

	for(kl=0; kl<liste_det2[0]; kl++) {
		n_bol=liste_det2[kl+1];
		z=_acqbox(dhs,n_bol);
		if (z>dhs->nb_boites_mesure) {
			printf("\n  ERREUR  kid %d avec boite = %d  ",n_bol,z);
			z=0;
		}
		if (z!=zold2) {
			zold2=z;
			RG_nikel = reglage_pointer_nikel_amc(dhs,z);
			if (RG_nikel) {
				if (!_presence_brutbox(dhs,_db_t_utc,z) )	{
					printf("\nboite %d bolo %d *****  erreur  pas de  %c t_utc dans les brut",z,n_bol,'A'+z);
					return;
				}

				if (old_reglage_nikel)   deviation_modulation = _regl_ampl_mod (RG_nikel) * 1000; // pour avoir des hertz au lieu des khertz
				else    deviation_modulation = RG_nikel[_kid_f_modul] ; // je change et je mets des hertz dans le reglage
				//-----------------   pour chaque boite, demander un raz_rf_didq  sur un flag ------------------------------
				if (_demande_raz_didq[z]>0) _demande_raz_didq[z]--;
				if (_presence_brutbox(dhs,_db_masq,z)) masq=_brut_pb(dhs,Br,_db_masq,z,nper);
				if ((masq & _flag_balayage_en_cours )  || (masq & _flag_blanking_synthe ) || (masq & _flag_fpga_change_frequence ) )
					_demande_raz_didq[z] = _interval_derive_dIdQ+ 2;     // delai 100 sample + 2 sample par securite
			}

		}

		//-------------------------   calcul  I , Q , dI , dQ  en retirant les points undef avant de fabriquer les data  --------------------

		if (_brut_pdd(dhs,Br,_dd_I, nper)[n_bol]!=undef_int4) _I =_brut_pdd(dhs,Br,_dd_I ,nper)[n_bol];	//I
		if (_brut_pdd(dhs,Br,_dd_Q, nper)[n_bol]!=undef_int4) _Q =_brut_pdd(dhs,Br,_dd_Q ,nper)[n_bol];	//Q
		if (_brut_pdd(dhs,Br,_dd_dI,nper)[n_bol]!=undef_int4) _dI=_brut_pdd(dhs,Br,_dd_dI,nper)[n_bol];
		if (_brut_pdd(dhs,Br,_dd_dQ,nper)[n_bol]!=undef_int4) _dQ=_brut_pdd(dhs,Br,_dd_dQ,nper)[n_bol];

		I=_I;
		Q=_Q; //dI=_dI; dQ=_dQ;        // pour se rapeller la valeur precedente dans le cas d'un undef
		//-------------------------      calcul  phase et amplitude brutes    ---------------------------------------------------
		if (masque & 2) {
			//			phi=atan2(Q,I);	// AUB Debug

			if (_presence_datadet(dhs,_dd_amplitude) || _presence_datadet(dhs,_dd_log_amplitude)) 
				amp = _amplitude(I, Q) ;						// l'amplitude brute

			//-----  pour test, je rmets le flag dans  l'amplitude du bolo 13 avec un facteur 1000
			//		if (n_bol==13) amp = 1000 * flagres;
			// je trouve que tout est propre 5 pt avant le flag et tout est revenu 30 pt apres
			// je prend 10 et 40 par precaution

			//		amp_rel = _facteur_amplitude*(amp);

			if (_presence_datadet(dhs,_dd_phase_IQ))		_data_pdd(dhs,Dd,_dd_phase_IQ,nper)[n_bol]		= atan2(Q,I)/_phase_en_rad;		// la phase brute (en degres ou milli-radians)
			if (_presence_datadet(dhs,_dd_amplitude))		_data_pdd(dhs,Dd,_dd_amplitude,nper)[n_bol]		= amp	;
			if (_presence_datadet(dhs,_dd_log_amplitude))  	_data_pdd(dhs,Dd,_dd_log_amplitude,nper)[n_bol]	= 20 * log(amp)/log(10) ;
			if (_presence_datadet(dhs,_dd_ph_rel))		{	IIrel =  I*cos(phi0)+Q*sin(phi0);					// pour eviter les sautes de phase, on applique une rotation avant de calculer la phase
															QQrel = -I*sin(phi0)+Q*cos(phi0);					//
															_data_pdd(dhs,Dd,_dd_ph_rel,nper)[n_bol]		= atan2(QQrel,IIrel)/_phase_en_rad;// la phase relative en degres ou milli-radians
			}
			double amp_dIQ,amp_pIQ;

			if (_presence_datadet(dhs,_dd_ap_dIdQ)) 
					{
					amp_dIQ =  (double)_brut_pdd(dhs,Br,_dd_dI,nper)[n_bol]*(double)_brut_pdd(dhs,Br,_dd_dI,nper)[n_bol]
									+(double)_brut_pdd(dhs,Br,_dd_dQ,nper)[n_bol]*(double)_brut_pdd(dhs,Br,_dd_dQ,nper)[n_bol];
					if (amp_dIQ>0) amp_dIQ=sqrt(amp_dIQ);
					_data_pdd(dhs,Dd,_dd_ap_dIdQ,nper)[n_bol]	=	amp_dIQ	;
					}
			if (_presence_datadet(dhs,_dd_amp_pIQ) && _presence_datadet(dhs,_dd_pI)  && _presence_datadet(dhs,_dd_pQ) ) 
					{
					amp_pIQ =  (double)_brut_pdd(dhs,Br,_dd_pI,nper)[n_bol]*(double)_brut_pdd(dhs,Br,_dd_pI,nper)[n_bol]
									+(double)_brut_pdd(dhs,Br,_dd_pQ,nper)[n_bol]*(double)_brut_pdd(dhs,Br,_dd_pQ,nper)[n_bol];
					if (amp_pIQ>0) amp_pIQ=sqrt(amp_pIQ);
					_data_pdd(dhs,Dd,_dd_amp_pIQ,nper)[n_bol]	=	amp_pIQ	;
					if (_presence_datadet(dhs,_dd_rap_pIQdIQ) && _presence_datadet(dhs,_dd_ap_dIdQ) )
						{
						_data_pdd(dhs,Dd,_dd_rap_pIQdIQ,nper)[n_bol]	=	amp_pIQ / amp_dIQ	;
						// je calcule le pIQ  projete sur le  dIQ  :  produit scalaire des 2 divise par amp_dIQ au carre
						double a =  (double)_brut_pdd(dhs,Br,_dd_dI,nper)[n_bol]*(double)_brut_pdd(dhs,Br,_dd_pI,nper)[n_bol]
									+(double)_brut_pdd(dhs,Br,_dd_pQ,nper)[n_bol]*(double)_brut_pdd(dhs,Br,_dd_dQ,nper)[n_bol];
						_data_pdd(dhs,Dd,_dd_rap_pIQdIQ,nper)[n_bol]	=  a / (amp_dIQ * amp_dIQ);
						}
					
					}
			#ifdef debug
				if ((nper==0) && (n_bol==25)  ) printf(" ndet=%d   I=%f  amp=%f  ",n_bol,I,amp);
			#endif
		}



		//-----------------   calcul  derive avec  _dI et _dQ  ----------------------------------------------------------
		//--------------------------------------   nouvelle methode avec derivee moyenne interval et mesure retardee de  interval/2  ---------------------------
		// les tableaux  Table_derive  permettent de memoriser les valeures lues sur un interval de largeur  _interval_derive_dIdQ

		if (masque & 0x8) {
			if (_type_det(dhs,n_bol)==__kid_null  )         {
				MF		=	0;
				Ampdidq	=   0;
			} else {
				// ----  calcul  RfdIdQ  uniquement pour les detecteurs de la liste avec type !=0  ------
				p=*_pos_table_derive;
				Table_derive(0,n_bol,p)	=	_I ;
				Table_derive(1,n_bol,p)	=	_Q ;
				Table_derive(2,n_bol,p)	=	_dI ;
				Table_derive(3,n_bol,p)	=	_dQ ;

				#ifdef debug
					static int FirstTime=1;
					if (FirstTime) printf("%d %p\n", n_bol, &Table_derive(2,n_bol,0)); FirstTime=0;
				#endif

				// si je moyenne le tableau derive pour ddI et ddQ   j'ai la moyenne des derivees sur les _interval_derive_dIdQ points precedents
				ddI=0;
				ddQ=0;

                                // This loop is the 2nd slowest part of the program: too many cache misses and monster macro
/*                                for(k=0; k< _interval_derive_dIdQ; k++ ) {
					#pragma Loop_Optimize Unroll No_Vector
                                        ddI += Table_derive(2,n_bol,k);
                                        ddQ += Table_derive(3,n_bol,k);
                                }
*/
				typedef double aligned_double __attribute__((aligned(8)));
				typedef const aligned_double* SSE_PTR;
				SSE_PTR TD=(SSE_PTR)&Table_derive(2,n_bol,0);	// We KNOW the alignement is correct because we force it (see assert()...)

				// This loop is the 2nd slowest part of the program: too many cache misses and monster macro
				for(k=0; k< _interval_derive_dIdQ; k++, TD+=5) {
					#pragma Loop_Optimize Unroll No_Vector
					ddI += TD[0];
					ddQ += TD[1];
				}

				ddI /= _interval_derive_dIdQ;
				ddQ /= _interval_derive_dIdQ;

				Ampdidq =  _amplitude(ddI, ddQ);			// l'amplitude didq  moyennee sur le tableau autour du point nper

				pp =( p + _interval_derive_dIdQ/2 ) % _interval_derive_dIdQ;		// le point qui a calculer (retarde de _interval_derive_dIdQ/2 )
				if (_demande_raz_didq[z]>0) 
					MF=0;
				else {
					//  calcul de l'ecart entre 2 points consecutifs au bon endroit retarde de _interval_derive_dIdQ/2
					VI = Table_derive(0,n_bol,(pp+1)%_interval_derive_dIdQ) - Table_derive(0,n_bol,pp) ;
					VQ = Table_derive(1,n_bol,(pp+1)%_interval_derive_dIdQ) - Table_derive(1,n_bol,pp) ;
					MF = Table_derive(4,n_bol,pp);
					//				if (Ampdidq > _mini_amplitude_dIdQ ) MF += deviation_modulation / 2. * (VI*ddI + VQ * ddQ) / ( ddI*ddI + ddQ*ddQ ) ;
					//              le /2 est correct pour tenir compte de l'absence de normalisation de I,Q,dI et dQ) !!
					//              j'enleve le 2 car la deviation modulation est deja la moitie de la deviation totale car je module en + et - deviation modulation !!
					if (Ampdidq > _mini_amplitude_dIdQ ) 
						MF += deviation_modulation  * (VI*ddI + VQ*ddQ) / ( ddI*ddI + ddQ*ddQ ) ;

					if (MF>1e9 || MF<-1e9) MF=0;
				}				
				//if ((n_bol==10) && (_demande_raz_didq[z]>0) ) printf("\n %d ",_demande_raz_didq[z]);
				Table_derive(4,n_bol,(pp+1)%_interval_derive_dIdQ) = MF;
			}
			//      copie des valeurs moyennees et retardees de MF et Amplitude didq
			if (_presence_datadet(dhs,_dd_RF_didq))  _data_pdd(dhs,Dd,_dd_RF_didq,nper)[n_bol]	= MF;
			//if (_presence_datadet(dhs,_dd_ap_dIdQ))  _data_pdd(dhs,Dd,_dd_ap_dIdQ,nper)[n_bol]	= Ampdidq;
		}

		//  if (n_bol==10)	{static int cc=0;if (cc++==200) {cc=0;printf("\n deviation_modulation=%g  MF =  %g", deviation_modulation, MF);}}

	}   // fin de la boucle  for(kl=0;kl<liste_det2[0];kl++)

}



/****************************************************
*                 decorelle_DATA_UN_POINT_KID       *
****************************************************/
// fonction  non utilisee pour l'instant
void	decorelle_un_point_kid(Data_header_shared_memory *dhs,double *Dd,int nper) {
	int z,i,n_bol;
	double np;
	double moy;
	static double *f1;
	static double *f2;
	static double *coef;
	static double *ff1p;
	static double *ff2p;
	static double *ff1m;
	static double *ff2m;
	static double *coefpm;
	static double *datap;
	static double *datam;
	static int nb_detec=0;
	double rms,rmsp,rmsm;

	if (dhs->nb_detecteurs != nb_detec) {
		nb_detec = dhs->nb_detecteurs;
		f1    = malloc(sizeof(double) * nb_detec);
		f2    = malloc(sizeof(double) * nb_detec);
		coef  = malloc(sizeof(double) * nb_detec);

		ff1p  = malloc(sizeof(double) * nb_detec);
		ff2p  = malloc(sizeof(double) * nb_detec);
		ff1m  = malloc(sizeof(double) * nb_detec);
		ff2m  = malloc(sizeof(double) * nb_detec);
		coefpm= malloc(sizeof(double) * nb_detec);
		datap = malloc(sizeof(double) * nb_detec);
		datam = malloc(sizeof(double) * nb_detec);

		for(i=0; i<nb_detec; i++) {
			coef[i]=1.;
			f1[i]=0.;
			f2[i]=0.;
			ff1p[i]=0.;
			ff2p[i]=0.;
			ff1m[i]=0.;
			ff2m[i]=0.;
			coefpm[i]=1.;
			datap[i]=0.;
			datam[i]=0.;
		}
	}
	// decorelle par boite
	for(z=0; z<dhs->nb_boites_mesure; z++)
		if (_nb_det_box(dhs,z)) {
			np=0;
			moy=0;
			// calcul de la somme de tous les bolos actifs, pondere par 1/ leur rms a 4 Hz (filtrage 4Hz - 2Hz
			for(n_bol=_first_det_box(dhs, z); n_bol<_last_det_box(dhs, z); n_bol++) {
				if (_type_det(dhs,n_bol)== __kid_pixel ) {
					f1[n_bol] = f1[n_bol]*0.8 + _data_pdd(dhs,Dd,_dd_RF_didq,nper)[n_bol] *0.2;	//	filtre sur 5 pts
					f2[n_bol] = f2[n_bol]*0.9 + _data_pdd(dhs,Dd,_dd_RF_didq,nper)[n_bol] *0.1;	//	filtre sur 10 pts
					rms = f2[n_bol] - f1[n_bol];
					rms = rms*rms;
					coef[n_bol] = rms * 0.001 + coef[n_bol]*0.999;			// coef filtre sur 1000 points(50 sec)
					if (coef[n_bol]>1) {
						moy+=_data_pdd(dhs,Dd,_dd_RF_didq,nper)[n_bol]/coef[n_bol];
						np+= 1/coef[n_bol];
					}
				}
			}
			if (np>0) {
				moy /= np;
				for(n_bol=_first_det_box(dhs, z); n_bol<_last_det_box(dhs, z); n_bol++) {
					if (_type_det(dhs,n_bol)==__kid_pixel) {
						datap[n_bol] = _data_pdd(dhs,Dd,_dd_RF_didq,nper)[n_bol] - moy*coefpm[n_bol]*1.1;
						datam[n_bol] = _data_pdd(dhs,Dd,_dd_RF_didq,nper)[n_bol] - moy*coefpm[n_bol]*0.9;

						ff1p[n_bol] = ff1p[n_bol]*0.98 + datap[n_bol] *0.02;	//	filtre sur 100 pts
						ff2p[n_bol] = ff2p[n_bol]*0.99 + datap[n_bol] *0.01;	//	filtre sur 200 pts

						ff1m[n_bol] = ff1m[n_bol]*0.98 + datam[n_bol] *0.02;	//	filtre sur 100 pts
						ff2m[n_bol] = ff2m[n_bol]*0.99 + datam[n_bol] *0.01;	//	filtre sur 200 pts

						rmsp = (ff2p[n_bol] - ff1p[n_bol])*(ff2p[n_bol] - ff1p[n_bol]);
						rmsm = (ff2m[n_bol] - ff1m[n_bol])*(ff2m[n_bol] - ff1m[n_bol]);
						rms = (rmsp - rmsm ) / (rmsp + rmsm);
						coefpm[n_bol]	*= (1-rms/1000);
						//if (rmsp-rmsm>0)	coefpm[n_bol]	*=0.9999;	else coefpm[n_bol]	*=1.0001;		// calcul sur 10000 pts soit 500 sec

						_data_pdd(dhs,Dd,_dd_RF_deco,nper)[n_bol] =  (datap[n_bol]+datam[n_bol])/2;
					}
				}

			}
		}
	//{static int cc=0; cc=(cc+1)%5; if (cc==0) if (nper==5) printf("\n coef(410..413) = %g , %g , %g , %g ",coefpm[410],coefpm[411],coefpm[412],coefpm[413]);}
}



/********************************************************************
*               moyenne_bloc_data  commun et detecteurs             *
********************************************************************/

double	moyenne_bloc_data_c(Data_header_shared_memory *dhs,double *Dd,int k) {
	double valeur=0;
	int i;
	for(i=0; i<dhs->nb_pt_bloc; i++)	valeur+=_data_ec(dhs,Dd,k,i);
	return valeur/dhs->nb_pt_bloc;
}

double	moyenne_bloc_data_d(Data_header_shared_memory *dhs,double *Dd,int k,int n_bol) {
	double valeur=0;
	int i;
	for(i=0; i<dhs->nb_pt_bloc; i++)	valeur+=_data_ed(dhs,Dd,k,i)[n_bol];
	//printf("\n calcul valeur moyenne detecteur  ( k=%d   det=%d )  -> %g",k,n_bol,valeur/dhs->nb_pt_bloc);
	return valeur/dhs->nb_pt_bloc;
}



/************************************************
*					calcul_kid					*
************************************************/

// calcul  des tableaux (ftone,tangle,flagkid,width) pour tous les kid
// si un tableau est null, il ne sera pas rempli
void	calcul_kid(Data_header_shared_memory *dhs,int4 *br,int nper,
				   double *ftone,double *tangle,int *flagkid,int *width) {
	int z;
	for(z=0; z<dhs->nb_boites_mesure; z++) {
		uint4 *RG_nikel = reglage_pointer_nikel_amc(dhs,z);
		if (RG_nikel) {
			double freq = 0.01*_brut_pb(dhs,br,_db_freq,z,nper);
			int msq= _brut_pb(dhs,br,_db_masq,z,nper);
			int nn1 = _first_det_box(dhs,z);
			// les 4 tableau suivant sont des pointeurs sur les donnees de la boite dans le bloc  brut br
			int4 *I = _brut_pdd(dhs,br,_dd_I,nper) + nn1;
			int4 *Q = _brut_pdd(dhs,br,_dd_Q,nper) + nn1;
			int4 *dI = _brut_pdd(dhs,br,_dd_dI,nper) + nn1;
			int4 *dQ = _brut_pdd(dhs,br,_dd_dQ,nper) + nn1;
			calcul_kid_boite(dhs,z,freq,msq,I,Q,dI,dQ,ftone,tangle,flagkid,width);
		}
	}
}



