#ifndef __BLOC_H
#define __BLOC_H

// ne connait que les blocs dont le header precede ce header

//include "bloc_kid.h"
//include "bloc_opera.h"
//include "bloc_elvin.h"
//include "bloc_comprime.h"

// tous les blocs inconnus ont par defaut la longueur d'un bloc vide

//======================================================================================================================================
//===================    je mets ici les definitions permettant l'utilisation des blocs standards     ==================================
//======================================================================================================================================

typedef struct {		/*	La structure de transfert transputer vers mac	*/
	int4 debut;			/*	code de reconnaissance de debut de block	*/
	int4 code_longueur;	/*	longueur du block					*/
	int4 code2;			/*	code2 du block					*/
	int4 data[100000];
//	int4 fin;			/* code de reconnaissance de fin de block		*/
}
Bloc_standard;

typedef struct {		/*	La structure de transfert transputer vers mac	*/
	int4 debut;			/*	code de reconnaissance de debut de block	*/
	int4 code_longueur;	/*	longueur du block					*/
	int4 code2;			/*	code2 du block					*/
	int4 data[0];
	int4 fin;			/* code de reconnaissance de fin de block		*/
}
Bloc_vide;


typedef struct {
	int box_enable;		// acquiition take enable of this box only if box_enable==1
	int type_eth;
	int slave;
	int reception;
	int fenetre;
	int cmd_ip;
	int cmd_port;
	int data_ip;
	int data_port;

	FILE 	*fichier_intermediaire;
	char	nom_fichier_intermediaire[1000];
	long 	position_fichier_intermediaire;

	Bloc_standard *dbloc;
	int dtype;
	int posbloc;
	int finbloc;
    int erreur_boite;
} Datain;


#define  _enable_simule     0x2
#define  _enable_acqui      0x4
// box_enable =0 boite non active
// box_enable =1 boite active normale
// box_enable =2 ou 3 : boite en simulation
//pour tester si une boite est geree par l'acquisition tester     box_enable&_enable_acqui
// pour mettre une boite en acquisition   faire  ( box_enable |= _enable_acqui )


#define nb_type_blocks 63	// 32 blocs + 32 blocs reglages

// bloc 7 devient bloc_comprime8
// bloc 9 devient bloc_comprime10
// bloc 23 devient bloc_pkid  (bloc kid avec 6 parametres : I,Q,dI,dQ,pI,pQ
// bloc 24 devient bloc_rfkid  bloc kid avec entete plus longue
enum	{bloc_vide,bloc_brut,bloc_modele,bloc_mppsync,bloc_zero,bloc_periode,bloc_synchro,bloc_comprime8,
		 bloc_bolo,bloc_comprime10,bloc_pointage,bloc_antenna,bloc_map,bloc_mini,bloc_comprime10d,bloc_15,
		 bloc_brut_opera,bloc_17,bloc_18,bloc_info,bloc_kid,bloc_header,bloc_param,bloc_pkid,
         bloc_rfkid,bloc_rfpkid,
		 bloc_fin=30,bloc_reglage=32
	 };

#define	Def_nom_block	char nom_block[nb_type_blocks][64]={"vide","brut","modele","mppsync",\
		"zero","periode","synchro","comp8",\
		"bolo","comp10","elvin","ant",\
		"map","mini","cp10d","?",\
		"opera","k_opera","actif","info",\
		"k","header","param","k",\
		"rf","rfp","s7","s8",\
		"b0","b1","fin","...",\
		"gA","gB","gC","gD","gE","gF","gG","gH",\
		"gI","gJ","gK","gL","gM","gN","gO","gP",\
		"gQ","gR","gS","gT","gU","gV","gW","gX",\
		"gY","gZ"};

//====================================================================================================================================
//========================					taille des blocs instruments et leur contenu               ==============================
//====================================================================================================================================

#define	_size_bloc_vide			(sizeof(Bloc_vide))		/*	taille d'un block vide	*/

//-------------------------------    bloc_comprime   (bloc_comprime.h) --------------------------------
#define	_size_data_comprime8(dhs)	sizeof(int4) * 10 * (dhs->nb_brut_c + dhs->nb_brut_d * dhs->nb_detecteurs)
#define	_size_bloc_comprime8(dhs)	(_size_data_comprime8(dhs) + _size_bloc_vide)

#define _nb_mot10n(dhs)	(dhs->nb_pt_bloc/3+1)
#define	_size_data_comprime10(dhs)	sizeof(int4) * _nb_mot10n(dhs) * (dhs->nb_brut_c + dhs->nb_brut_d * dhs->nb_detecteurs)
#define	_size_bloc_comprime10(dhs)	(_size_data_comprime10(dhs) + _size_bloc_vide)

#define	_size_data_comprime10d(dhs)	(sizeof(int4) * ( dhs->nb_pt_bloc * dhs->nb_brut_c + _nb_mot10n(dhs) * dhs->nb_brut_d * dhs->nb_detecteurs))
#define	_size_bloc_comprime10d(dhs)	(_size_data_comprime10d(dhs) + _size_bloc_vide)

// le bloc mini contient: le nb de det mini, la liste de leur rawnum, les brut_c les brut_d  comprimes
#define			_len_brut_mini(dhs)		(sizeof(int4) * (  1 +  (dhs)->nb_det_mini + _nb_mot10n(dhs) * (dhs)->nb_brut_c + \
		_nb_mot10n(dhs) * (dhs)->nb_det_mini * (dhs)->nb_brut_d ) )


//-------------------------------    bloc_antenna    --------------------------------
#ifndef	_size_bloc_antenna
#define _size_bloc_antenna(dhs)			_size_bloc_vide
#endif

//-------------------------------    bloc_elvin    --------------------------------

#ifndef _size_bloc_elvin
#define _size_bloc_elvin(npb)			_size_bloc_vide
#endif

//-------------------------------    bloc_nikel    --------------------------------

#ifndef	_size_bloc_kid
#define _size_bloc_kid(dhs)				_size_bloc_vide
#define _size_bloc_pkid(dhs)			_size_bloc_vide
#define _size_bloc_rfkid(dhs)			_size_bloc_vide
#define _size_bloc_rfpkid(dhs)			_size_bloc_vide
#endif

#ifndef	_nb_max_IQ
#define _nb_max_IQ	6
#endif


//-------------------------------    bloc_mppsync    --------------------------------
#ifndef	_size_bloc_mppsync
#define _size_bloc_mppsync(dhs)			_size_bloc_vide
#endif

//-------------------------------    bloc_opera    --------------------------------
#ifndef	_size_bloc_brut_opera
#define _size_bloc_brut_opera(dhs)		_size_bloc_vide
#define _size_bloc_bolo(dhs)			_size_bloc_vide
#define _size_bloc_periode(dhs)			_size_bloc_vide
#define _size_bloc_synchro(dhs)			_size_bloc_vide
#endif


//-------------------------------------------------------------------------------------


#define _size_bloc_brut(dhs)			(_size_bloc_vide + _len_brut_bloc_shared_memory(dhs))
#define _size_bloc_mini(dhs)			(_size_bloc_vide + _len_brut_mini(dhs))
#define _size_bloc_map(dhs)				(_size_bloc_vide + sizeof(int4)* 3)		// dans map on a 3 valeurs dans le bloc
#define _size_bloc_fin					(_size_bloc_vide + 1000)
#define _size_bloc_info					(_size_bloc_vide + 1000)



//====================================================================================================================================
//====================================================================================================================================
//====================================================================================================================================
//========================					quelques definitions pour les blocs generaux                ==============================
//====================================================================================================================================
//====================================================================================================================================
//====================================================================================================================================



enum	{block_correct,block_type_inconnu,block_longueur_erreur,block_debut_erreur,block_fin_erreur};

#define	_size_bloc_modele(dhs)			(_size_bloc_vide + sizeof(int4) *	\
		(_nb_max_IQ*dhs->nb_detecteurs + dhs->nb_detecteurs + dhs->nb_brut_periode ) + _size_bloc_brut(dhs) + _size_bloc_header(dhs) )

#define _size_bloc_header(dhs)		(_size_bloc_vide + dhs->lg_header_util)

#define _size_bloc_param(dhs)		(_size_bloc_vide + _len_param_shared_memory(dhs))

// pour un bloc reglage, le type est donne par bloc_reglage + le numero de la boite
#define _size_bloc_reglage(dhs,type)	(_size_bloc_vide + sizeof(int4) * nb_elements_reglage_partiel(dhs,type-bloc_reglage))


#define _size_bloc(dhs,type)			\
	((type)==bloc_vide		? _size_bloc_vide :				\
	 (type)==bloc_modele	? _size_bloc_modele(dhs) :		\
	 (type)==bloc_brut		? _size_bloc_brut(dhs) :		\
	 (type)==bloc_mini		? _size_bloc_mini(dhs) :		\
	 (type)==bloc_comprime8	? _size_bloc_comprime8(dhs) :	\
	 (type)==bloc_comprime10? _size_bloc_comprime10(dhs) :	\
	 (type)==bloc_comprime10d?_size_bloc_comprime10d(dhs) :	\
	 (type)==bloc_periode	? _size_bloc_periode(dhs) :		\
	 (type)==bloc_synchro	? _size_bloc_synchro(dhs) :		\
	 (type)==bloc_mppsync	? _size_bloc_mppsync(dhs) :		\
	 (type)==bloc_bolo		? _size_bloc_bolo(dhs) :		\
	 (type)==bloc_map		? _size_bloc_map(dhs) :			\
	 (type)==bloc_kid		? _size_bloc_kid(dhs):			\
	 (type)==bloc_pkid		? _size_bloc_pkid(dhs):			\
	 (type)==bloc_rfkid		? _size_bloc_rfkid(dhs):		\
	 (type)==bloc_rfpkid	? _size_bloc_rfpkid(dhs):		\
	 (type)==bloc_modele	? _size_bloc_modele(dhs) :		\
	 (type)==bloc_pointage	? _size_bloc_elvin(dhs->nb_pt_bloc) :	\
	 (type)==bloc_antenna	? _size_bloc_antenna(dhs->nb_pt_bloc) :	\
	 (type)==bloc_brut_opera? _size_bloc_brut_opera(dhs) :	\
	 (type)==bloc_header	? _size_bloc_header(dhs) :		\
	 (type)==bloc_param		? _size_bloc_param(dhs) :		\
	 (type)==bloc_info		? _size_bloc_info :				\
	 (type)==bloc_fin		? _size_bloc_fin :				\
	 (type)>=bloc_reglage-1	? _size_bloc_reglage(dhs,type) :\
	 _size_bloc_vide)


#define _valide_bloc(dhs,blk,type,num)	{\
			if(_size_bloc(dhs,type)==_size_bloc_vide) printf("\nERROR  valide bloc vide \n");\
			blk->debut	= debut_block_mesure;\
			blk->code_longueur = _size_bloc(dhs,type);\
			blk->code2 = (num & 0x00ffffffl ) | ( (((long)type)<<24)&0xff000000l );\
			((Bloc_standard*)blk)->data[ blk->code_longueur/4-4 ] = fin_block_mesure;\
		}


#define _verifie_bloc(dhs,blk) \
			(blk->debut != debut_block_mesure ? block_debut_erreur : \
			 type_bloc(blk)<0                 ? block_type_inconnu : \
			 type_bloc(blk)>=nb_type_blocks   ? block_type_inconnu : \
			 (int)_size_bloc(dhs,type_bloc(blk)) != (int)longueur_bloc(blk) ? block_longueur_erreur : \
			 /*blk->mot[(lg/4)-4]  !=	(int4)fin_block_mesure)	? block_fin_erreur  :  */ \
			                                    block_correct)


#define		debut_block_mesure		0x45627491l
#define		fin_block_mesure		0x83260432l


#define type_bloc(_bk)			( (int) (((_bk)->code2>>24)	& 0x000000ffl ))
#define longueur_bloc(_bk)		( (_bk)->code_longueur )
#define numero_bloc(_bk)		( (int) ( (_bk)->code2		& 0x00ffffffl ))


#endif  // __BLOC_H
