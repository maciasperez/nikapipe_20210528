#ifndef _BRUT_TO_DATA_H
#define _BRUT_TO_DATA_H

#define _copy_brut_to_data(k,coef) \
			if(_presence_brut_data(dhs,k)) \
				{int ii;for (ii=0;ii<dhs->nb_pt_bloc;ii++)  \
					_data_pc(dhs,Dd,k,ii) = (coef) * (double)_brut_pc(dhs,Br,k,ii);}

#define _copy_brut_to_databox(p,z,coef) \
			if(_presence_brut_databox(dhs,p,z)) \
				{int ii;for (ii=0;ii<dhs->nb_pt_bloc;ii++) \
					_data_pb(dhs,Dd,p,z,ii) = (coef) * (double)_brut_pb(dhs,Br,p,z,ii);}


/*
#define _synchro_scan_manuel(i)			db->dBrut_synchro[i][13]
#define _synchro_scan_pointage(i)		db->dBrut_synchro[i][11]	// pour l'IRAM
#define _synchro_num_subscan(i)			db->dBrut_synchro[i][14]	// pour l'IRAM
*/


//==============================================================================================================================
//==============================	Le buffer buffer_temporaire pour le traitement des donnes brut    ==========================
//======================================  attention:   Buffer_temp  est un pointeur de char  ===================================

// brut to data fait le malloc si le programme appelant donne un pointeur null
// sinon, le programme appelant doit allouer un buffer et renvoyer chaque fois le meme buffer
//----  taille typique : 100 * 5 * nb_detecteurs * 8 = 300k ou 600k pour 1 ou 2 boites de 400
//Je reserve :  buf_btd[0] pour l'initialisation  (vaut 1 pour le premier bloc, zero ensuite)

#define ALdrq						sizeof(int)			// to align _demande_raz_didq on 8-byte boundary
#define _demande_raz_didq_length	(sizeof(int)*dhs->nb_boites_mesure + ALdrq)	// Potential align problem if uneven
#define	_demande_raz_didq			((int*)(Buffer_temp + 4 + ALdrq))	// Why +4 ?!?


//===========================================================================================================================================
//===========================               variables temporaires pour calcul  RFdIdQ         ===============================================
//===========================================================================================================================================
#define _interval_derive_dIdQ   100
//#define _interval_derive_dIdQ   20
#define _table_derive_length		(sizeof(double) * dhs->nb_detecteurs * 5 * _interval_derive_dIdQ  + sizeof(int))	// Align problem
#define _pos_table_derive			(   (int*)(Buffer_temp + 4 + _demande_raz_didq_length))
#define _table_derive				((double*)(Buffer_temp + 4 + _demande_raz_didq_length + sizeof(int)))

#define _iqdidq_length				(sizeof(int) * dhs->nb_detecteurs * 4 )
#define _iqdidq						((int*)(Buffer_temp + 4 + _demande_raz_didq_length + _table_derive_length))

//===========================================================================================================================================
//===========================            variables temporaires pour buffer brut retarde       ===============================================
//===========================================================================================================================================
#define _retard_brut_maxi	200		// le retard maxi est celui-ci  le tableau permet de retarder tous les brut communs
                                    // il doit etre pair pour preserver l'alignement sur 8 octets
#define ALtbr						sizeof(int)			// to align _table_brut_retard on 8-byte boundary
#define _table_brut_retard_length	(sizeof(int) * dhs->nb_brut_c * _retard_brut_maxi + sizeof(int) + ALtbr)	// Align problem
#define _pos_table_brut_retard		((int*)(Buffer_temp + 4 + _demande_raz_didq_length + _table_derive_length + _iqdidq_length))
#define _table_brut_retard			((int*)(Buffer_temp + 4 + _demande_raz_didq_length + _table_derive_length + _iqdidq_length + sizeof(int) + ALtbr))
#define _posrt(retard,i)			(((*_pos_table_brut_retard)-(retard)+(i)+_retard_brut_maxi)%_retard_brut_maxi)

//=============================================================================================================================================
//===========================    variables temporaires pour calcul  ftone tangle et flagkid     ===============================================
//=============================================================================================================================================
#define _buffer_flag				(Buffer_temp + 4 + _demande_raz_didq_length + _table_derive_length \
									 + _iqdidq_length + _table_brut_retard_length )
// _buffer_flag	est un pointerur de char
// il y a 2 tableaux d'entier et  2  tableaux de double
#define _buffer_flag_length			( 2 * sizeof(int) * dhs->nb_detecteurs + 2 * sizeof(double) * dhs->nb_detecteurs )

#define	_flagkid	((int*)(_buffer_flag ))
#define	_width		((int*)(_buffer_flag +  sizeof(int)*dhs->nb_detecteurs))
#define	_ftone		((double*)(_buffer_flag +  2 * sizeof(int)*dhs->nb_detecteurs ))
#define	_tangle		((double*)(_buffer_flag +  2 * sizeof(int)*dhs->nb_detecteurs + sizeof(double)*dhs->nb_detecteurs ))


//	le buffer pour le calcul des bolo
#define _val_pre_bolo_length	(sizeof(double) * dhs->nb_detecteurs )
#define _val_pre_bolo			((double*)(Buffer_temp + 4 + _demande_raz_didq_length + _table_derive_length \
									 + _iqdidq_length + _table_brut_retard_length  + _buffer_flag_length))


//===============================================================================================================================================
//================ variables temporaires pour    calcul detection synchrone dans brut to data   ===============================================
//===============================================================================================================================================
//	le buffer pour la detection synchrone
#define _nb_max_periode_ds 500

#define ALbd		1			// One dummy int - to align _ds_bufd on 8-byte boundary
#define _ds_length	( sizeof(int) * (5 + ALbd) + sizeof(double) * ( 1 + 2 * dhs->nb_detecteurs*_nb_max_periode_ds) )	// Align problem

#define _ds_bufi	( (int*)(Buffer_temp + 4 + _demande_raz_didq_length + _table_derive_length \
		+ _iqdidq_length + _table_brut_retard_length  + _buffer_flag_length \
		+ _val_pre_bolo_length	) )

#define _ds_bufd	( (double*) (_ds_bufi +  5 + ALbd) )

#define _DS_cpt			_ds_bufi[0]
#define _DS_periode		_ds_bufi[1]
#define _DS_oldper		_ds_bufi[2]
#define _DS_chercheper	_ds_bufi[3]
#define _pos_table_ds	_ds_bufi[4]

#define _phase_rapide	_ds_bufd[0]
#define _table_ds_mesure_sin  (_ds_bufd+1)
#define _table_ds_mesure_cos  (_table_ds_mesure_sin + dhs->nb_detecteurs * _nb_max_periode_ds)

//===========================================================================================================================================
//===========================            variables temporaires pour le calcul du temps pps       ===============================================
//===========================================================================================================================================

// il y a 3 tables de double et 2 table d'entier: je reserve la place pour 6 tables de double
#define _t_pps_length	( 6 * sizeof(double) * _nb_max_acqbox  )
#define _table_temps_pps	\
        ( (double*)(Buffer_temp + 4 + _demande_raz_didq_length + _table_derive_length \
		+ _iqdidq_length + _table_brut_retard_length  + _buffer_flag_length \
		+ _val_pre_bolo_length	+ _ds_length ) )


//===============================================================================================================================
//================ variables temporaires longueur totale du buffer necessaire     ===============================================
//===============================================================================================================================

#define _total_length_buf_btd		( 2 * (4 + _demande_raz_didq_length + _table_derive_length \
									  + _iqdidq_length + _table_brut_retard_length + _buffer_flag_length \
									  + _val_pre_bolo_length + _ds_length + _t_pps_length) )	// Potential align problem

//ab  je double le buffer temporaire de brut to data  pourquoi ? est-ce utile (le 2 avril 2017)

//========================================================================================================================
//  je retarde retarde tous les brut a la demande en les rangeant dans un tableau et en cherchant un element decale
//  j'utile les elements suivant, convertis en double
// attention, p est la valeur de l'enum des pointages brut possible, l'indice dans le tableau brut est _ibr(dhs)[p]-_ibr(dhs)[_d_ofs_X]
// le tableau est range dans  _table_brut_retard[i] a une dimmension et on accede par les define suivants
//#define _brut_retarde_ind(q,pos)	(_table_brut_retard[0])

//--- utiliser  _brut_retarde_ind(q,pos)   si q est l'indice des brut dans la table des brut presents
#define _brut_retarde_ind(q,pos)	(_table_brut_retard[(q) * _retard_brut_maxi + (pos)])

//--- utiliser  _brut_retarde(p,pos)   si p est l'indice des brut dans la table des possibles
//#define _brut_retarde(p,pos)		_brut_retarde_ind(_ibr(dhs)[p], pos)
#define _brut_retarde(p,pos)		_brut_retarde_ind(_bpo(dhs)[p], pos)
// relire les data retardees avec  pos = _posrt(retard,i)

#define _brut_retarde_box(p,pos,z)		_brut_retarde(_nb_data_simple_possibles+(z)*_nb_data_box_possibles + (p), pos)



//---------------------------------------------------------------------------------------------------------------
//------------------------------------    les  prototypes de fonctions    ---------------------------------------
//---------------------------------------------------------------------------------------------------------------

//  calcule les data en double dans Dd a partir des data brut dans Br  en utilisant le buffer temporaire  buf_btd
extern	void 	brut_to_data(Data_header_shared_memory *dhs,int4 *Br,double *Dd,int4 *liste_detecteurs,char *buf_btd,int print);

extern double	moyenne_bloc_data_c(Data_header_shared_memory *dhs,double *Dd,int k);
extern double	moyenne_bloc_data_d(Data_header_shared_memory *dhs,double *Dd,int k,int ndet);

extern	void	calcul_kid(Data_header_shared_memory *dhs,int4 *br,int nper,
						   double *ftone,double *tangle,int *flagkid,int *width);

#endif

