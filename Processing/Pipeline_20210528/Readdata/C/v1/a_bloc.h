#ifndef __A_BLOC_H
#define __A_BLOC_H

/*==============================================================================================*/
/*==============================================================================================*/
/*  ----- je mets dans ce fichier tout ce qui concerne les blocs  (remplace archeops.h) ------  */
//===               il  n'y a pas de fichier  a_bloc.c associe 
// ATTENTION :  si elvin n'est pas connu, la taille des blocs pointage n'est pas correcte   !!!===
// on a ici tous les type de blocs avec leur tailles
// on a aussi la structure   Global_bloc   utilisee pour lire les blocs sur ethernet 
/*==============================================================================================*/

//======================================================================================================================================
//===================    je mets ici les definitions permettant l'utilisation des blocs standards     ==================================
//======================================================================================================================================
//#include "kid_flag.h"           // pour connaitre la taille des blocs comprimes

#ifndef _BLOC_STANDARD_
#define _BLOC_STANDARD_

typedef struct				/*	La structure de transfert transputer vers mac	*/  
{
	int4		debut;		/*	code de reconnaissance de debut de block	*/
	int4		code_longueur;		/*	longueur du block					*/
	int4		code2;		/*	code2 du block					*/
	int4		data[0];		
	int4		fin;		/* code de reconnaissance de fin de block		*/
}
Bloc_standard;


typedef struct
	{
	int care;		// acquiition take care of this box only if care==1
	int type_eth;
	int reception;
	int fenetre;
	int ip;
	int port;

	FILE* 	fichier_intermediaire;
	char	nom_fichier_intermediaire[1000];
	long 	position_fichier_intermediaire;	

	
	
	Bloc_standard * dbloc;
	int dtype;
	int posbloc;
	int finbloc;
	} Datain;
	


#define	_size_bloc_vide			(sizeof(int4)*4)		/*	taille d'un block vide	*/

#define nb_type_blocks 48

// bloc 7 devient bloc_comprime8
// bloc 9 devient bloc_comprime10
// bloc 23 devient bloc_pkid  (bloc kid avec 6 parametres : I,Q,dI,dQ,pI,pQ
enum	{bloc_vide,bloc_brut,bloc_modele,bloc_mppsync,bloc_4,bloc_periode,bloc_synchro,bloc_comprime8,
		bloc_bolo,bloc_comprime10,bloc_pointage,bloc_antenna,bloc_map,bloc_13,bloc_14,bloc_15,
		bloc_brut_opera,bloc_17,bloc_18,bloc_info,bloc_kid,bloc_header,bloc_param,bloc_pkid,
		bloc_fin=30,bloc_reglage=32};
// le bloc 31 est un bloc reglage commun (z=-1)

#define	Def_nom_block	char nom_block[nb_type_blocks][32]={"vide","brut","modele","mppsync",\
					"bloc4","periode","synchro","comprime8",\
					"bolo","comprime10","elvin","ant",\
					"map","synthe","kid","--",\
					"opera","k_opera","actif","info",\
					"k","header","param","k",\
					"s5","s6","s7","s8",\
					"b0","b1","fin","...",\
					"rgA","rgB","rgC","rgD","rgE","rgF","rgG","rgH","rgI","rgJ"};

//====================================================================================================================================
//========================					taille des blocs instruments et leur contenu               ==============================
//====================================================================================================================================

//====================================================================================================================================
//--------   boite  opera  -------------------------------------
#ifdef _nb_canaux_mesure
   #define _size_bloc_brut_opera(dhs)	(_size_bloc_vide + sizeof(int4) *	\
			(_nb_canaux_mesure(dhs) * _nb_mes_per(dhs) + 2 ))
    //#define _size_bloc_brut_opera(dhs)	(_size_bloc_vide + sizeof(int4) * (( 4 * 36) + 2 ))
#else
    sdqsdfqfdsqfdffddfsqdfsq        on ne doit jamais arriver ici
    #define _size_bloc_brut_opera(dhs)  _size_bloc_modele(dhs)
#endif


#define _size_bloc_brut(dhs)				(_size_bloc_vide + _len_brut_bloc_shared_memory(dhs))
#define _size_bloc_bolo(dhs)			(_size_bloc_vide + sizeof(int4)* (dhs->nb_detecteurs * dhs->nb_pt_bloc))
#define _size_bloc_map(dhs)				(_size_bloc_vide + sizeof(int4)* 3)		// dans map on a 3 valeurs dans le bloc
#define _size_bloc_periode(dhs)			(_size_bloc_vide + sizeof(int4) *(1 + dhs->nb_detecteurs* dhs->nb_brut_periode ))
#define _size_bloc_synchro(dhs)			(_size_bloc_vide + sizeof(int4) *  ( 1 + 3 * dhs->nb_pt_bloc )) 
#define _size_bloc_fin					(_size_bloc_vide + 1000)
#define _size_bloc_info					(_size_bloc_vide + 1000)


// contenu des data du bloc synchro  ou p est l'index dans le bloc de 0 a 36 (ou 72 ??? )
#define _bs_max_synchro0(bk)        bk->data[0]
#define _bs_position_pup(bk,p)      bk->data[1+p]
#define _bs_temps_utc(dhs,bk,p)     bk->data[1+dhs->nb_pt_bloc+p]
#define _bs_mot_synchro(dhs,bk,p)   bk->data[1+2*dhs->nb_pt_bloc+p]





//====================================================================================================================================
//---------  boite nikel  ---------------------------------------
#define _nb_kid_nikel	400
#define _nb_max_IQ	6			// verifier que ca correspond dans name_list.h  avec les variables I,Q,dI,dQ,pI,pQ
#define _nb_IQ_kid	4			// ici on mets toujours 4
#define _nb_IQ_pkid	6			// pour les blocs avec I , Q , dI , dQ , pI , pQ
#define _size_bloc_kid(dhs)			(_size_bloc_vide + sizeof(int4)* (7 +  _nb_IQ_kid * _nb_kid_nikel))
#define _size_bloc_pkid(dhs)		(_size_bloc_vide + sizeof(int4)* (7 +  _nb_IQ_pkid * _nb_kid_nikel))

#define _bk_boite(bk)				bk->data[0]
#define _bk_indice(bk)				bk->data[1]
#define _bk_niveaudac(bk)			bk->data[2]
#define _bk_niveauadc(bk)			bk->data[3]
#define _bk_temps_ut(bk)			bk->data[4]
#define _bk_frequence_synthe(bk)	bk->data[5]
#define _bk_flag(bk)				bk->data[6]
//#define _bk_iqdidqpipq(bk,nn,n_bol,i)	bk->data[7 + (n_bol) * nn + i]	// pour les blocs kid et pkid
#define _bk_IQ(bk,nn,n_bol,i)		bk->data[7 + (n_bol) * (nn) + (i)]	// pour les blocs kid et pkid


//====================================================================================================================================
//---------  boite mppsync  ---------------------------------------

#define _size_bloc_mppsync(dhs)			(_size_bloc_vide + sizeof(int4) *  ( 1 + 4 * dhs->nb_pt_bloc ))

// contenu des data du bloc mppsync
#define _bm_boite(bk)				bk->data[0]
#define _bm_temps_utc(bk,p)			bk->data[1+p]
#define _bm_status(dhs,bk,p)		bk->data[1+dhs->nb_pt_bloc+p]
#define _bm_position(dhs,bk,p)		bk->data[1+2*dhs->nb_pt_bloc+p]
#define _bm_phase(dhs,bk,p)			bk->data[1+3*dhs->nb_pt_bloc+p]




//====================================================================================================================================
//---------  bloc en provenance d'elvin et  antenna   ---------------------------------------


#define _antenna_nb_param_lent      7
#define _antenna_nb_param_rapide	6
#define _antenna_nb_param_total     (_antenna_nb_param_lent+_antenna_nb_param_rapide)

// p= position dans la periode,   j= choix du pointage ou du message
#define _bpe_pointage(npb,bk,p,j)   bk->data[(npb) *(j) + (p)]
#define _bpe_message(npb,bk,p,j)    bk->data[(npb) *((j)+_pt_nb_params) + (p)]
#define _bpe_antenna(npb,bk,p,j)	bk->data[(npb) *(j) + (p)]
// dans le bloc  _bpe_pointage  j'ai (_pt_nb_params) elements   de    _pt_id    a    _pt_time_elvin:

#ifndef _pt_nb_params   // pour les boites nikel et opera qui ne connsissent pas elvin
    //#define _pt_nb_params 50
    //#define _mg_nb_params 50
#endif


#ifdef _pt_nb_params
    #define _size_bloc_elvin(npb)		(_size_bloc_vide + sizeof(int4) * (npb *(_pt_nb_params+_mg_nb_params +2 )))
        // +2 parceque _nb_total_parametres_de_pointage ne prend pas en compte _pt_id et _mg_id qui sont dans le bloc
#else		// n'importe quoi si je ne connais pas elvin   
    #define _size_bloc_elvin(npb)		(_size_bloc_vide + sizeof(int4) * 100 * npb)
#endif

#define _size_bloc_antenna(npb)		(_size_bloc_vide + sizeof(int4) * npb *_antenna_nb_param_total+100)	// +100 pour voir




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


#ifndef _SANS_COMPRESSION_

#define _size_bloc_comprime8(dhs)			(_size_bloc_vide + _size_data_comprime8(dhs))
#define _size_bloc_comprime10(dhs)			(_size_bloc_vide + _size_data_comprime10(dhs))

#define _size_bloc(dhs,type)			\
		(type==bloc_vide		? _size_bloc_vide :				\
		type==bloc_modele		? _size_bloc_modele(dhs) :			\
		type==bloc_brut			? _size_bloc_brut(dhs) :			\
		type==bloc_comprime8	? _size_bloc_comprime8(dhs) :			\
		type==bloc_comprime10	? _size_bloc_comprime10(dhs) :			\
		type==bloc_periode		? _size_bloc_periode(dhs) :			\
		type==bloc_synchro		? _size_bloc_synchro(dhs) :			\
		type==bloc_mppsync		? _size_bloc_mppsync(dhs) :			\
		type==bloc_bolo			? _size_bloc_bolo(dhs) :			\
		type==bloc_map			? _size_bloc_map(dhs) :			\
		type==bloc_kid			? _size_bloc_kid(dhs):			\
		type==bloc_pkid			? _size_bloc_pkid(dhs):			\
		type==bloc_modele		? _size_bloc_modele(dhs) :			\
		type==bloc_pointage		? _size_bloc_elvin(dhs->nb_pt_bloc) :			\
		type==bloc_antenna		? _size_bloc_antenna(dhs->nb_pt_bloc) :			\
		type==bloc_brut_opera	? _size_bloc_brut_opera(dhs) :			\
		type==bloc_header		? _size_bloc_header(dhs) :			\
		type==bloc_param		? _size_bloc_param(dhs) :			\
		type==bloc_info			? _size_bloc_info :				\
		type==bloc_fin			? _size_bloc_fin :				\
		type>=bloc_reglage-1	? _size_bloc_reglage(dhs,type) :			\
		_size_bloc_vide)

#else


#define _size_bloc(dhs,type)			\
		(type==bloc_vide		? _size_bloc_vide :				\
		type==bloc_modele		? _size_bloc_modele(dhs) :			\
		type==bloc_brut			? _size_bloc_brut(dhs) :			\
		type==bloc_periode		? _size_bloc_periode(dhs) :			\
		type==bloc_synchro		? _size_bloc_synchro(dhs) :			\
		type==bloc_mppsync		? _size_bloc_mppsync(dhs) :			\
		type==bloc_bolo			? _size_bloc_bolo(dhs) :			\
		type==bloc_map			? _size_bloc_map(dhs) :			\
		type==bloc_kid			? _size_bloc_kid(dhs):			\
		type==bloc_pkid			? _size_bloc_pkid(dhs):			\
		type==bloc_modele		? _size_bloc_modele(dhs) :			\
		type==bloc_pointage		? _size_bloc_elvin(dhs->nb_pt_bloc) :			\
		type==bloc_antenna		? _size_bloc_antenna(dhs->nb_pt_bloc) :			\
		type==bloc_brut_opera	? _size_bloc_brut_opera(dhs) :			\
		type==bloc_header		? _size_bloc_header(dhs) :			\
		type==bloc_param		? _size_bloc_param(dhs) :			\
		type==bloc_info			? _size_bloc_info :				\
		type==bloc_fin			? _size_bloc_fin :				\
		type>=bloc_reglage-1	? _size_bloc_reglage(dhs,type) :			\
		_size_bloc_vide)

#endif	//	#ifndef _SANS_COMPRESSION_


#define _valide_bloc(dhs,blk,type,num)	{blk->debut	= debut_block_mesure;blk->code_longueur = _size_bloc(dhs,type);\
	blk->code2		=	(num & 0x00ffffffl ) | ( (((long)type)<<24)&0xff000000l );\
	((Bloc_standard*)blk)->data[ blk->code_longueur/4-4 ] = fin_block_mesure;}


#define _verifie_bloc(dhs,blk) (blk->debut != debut_block_mesure ? 	block_debut_erreur  : \
		type_bloc(blk)<0 ? block_type_inconnu : type_bloc(blk)>=nb_type_blocks ? block_type_inconnu : \
		_size_bloc(dhs,type_bloc(blk)) != longueur_bloc(blk) ? block_longueur_erreur : \
		/*blk->mot[(lg/4)-4]  !=	(int4)fin_block_mesure)			return(block_fin_erreur)*/ \
		block_correct)


#define		debut_block_mesure		0x45627491l
#define		fin_block_mesure		0x83260432l

//#define longueur_bloc(_bk)		( (_bk)->code_longueur )			// ici c'est la longueur en byte du bloc
//#define type_bloc(_bk)			( (int) (((_bk)->code2>>24)	& 0x000000ffl ))
//#define numero_bloc(_bk)		( (int) ( (_bk)->code2		& 0x00ffffffl ))

#define type_bloc(_bk)			( (int) (((_bk)->code2>>24)	& 0x000000ffl ))
#define longueur_bloc(_bk)		( (_bk)->code_longueur ) 	
#define numero_bloc(_bk)		( (int) ( (_bk)->code2		& 0x00ffffffl ))


#endif  // _BLOC_STANDARD_



/*==============================================================================================*/
/*==============================================================================================*/
/*  --------  fichier a supprimer mais verifier que rien n'est utile au bolos ou au mpi ------  */
/*==============================================================================================*/
/*==============================================================================================*/

#if 0

//---------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------------------

/*----------------------------------   type  des bolos --------------------------------------------------*/

/*  ---  le type contient le type<<4  suivit d'un nombre de 0 a 15			*/
/*  on peu tester   le (type&0x30)  pour avoir  les 4 types			*/
/*  tester le (type&0x10) permet de savoir si c'est multiplexe			*/
/*  tester le (type&0x20) permet de savoir si c'est une BEBO		*/

/*
#define _type_MLPA			0x00
#define _type_MLPA16bit		0x01
#define _type_MUPA			0x10		// obsolete 
#define _type_BEDIFF		0x20		// programme en bedif si le type ==  _type_BEDIFF
#define _type_BEMUX			0x30


#define	_pas_un_MUX(type)		((type&0x10)==0)
#define	_est_un_MUX(type)		(type&0x10)
#define	_est_un_MUX_gene(type)	( (type&0x1f)  == 0x10 )
#define	_est_un_MUX_bolo(type)	( (type&0x10) && (type&0xf) )
#define	_est_une_BEDIF(type)	(type&_type_BEDIFF)
#define	_est_une_BEMUX(type)	(type&_type_BEMUX)
#define	_est_une_BEBO(type)		(type&0x20)

#define	__est_une_MLPA(n_bol)		((G_param.bolo[(n_bol)][__bolo_type]&0x10)==0)
#define	__pas_un_MUX(n_bol)			((G_param.bolo[(n_bol)][__bolo_type]&0x10)==0)
#define	__est_un_MUX(n_bol)			(G_param.bolo[(n_bol)][__bolo_type]&0x10)
#define	__est_un_MUX_gene(Gp,n_bol)	( (Gp->bolo[(n_bol)][__bolo_type]&0x1f)  == 0x10 )
#define	__est_un_MUX_bolo(Gp,n_bol)	( (Gp->bolo[(n_bol)][__bolo_type]&0x10) && (G_param.bolo[(n_bol)][__bolo_type]&0xf) )
#define	__est_une_BEBO(n_bol)		(G_param.bolo[(n_bol)][__bolo_type]&0x20)
*/

/*  variante au type MLPA :   +1   MLPA16bit			*/
/* variante au type  MUPA ou BEMUX :    +0 = general  //  +1..n  =  bolo_ligne   */





/*  type mux_bolo reservee 21 a  36  pour jusqu'a 16 bolos par ligne	*/
/*  les bolo individuels ont pour type  _type_mux_bolo + Numero dans la ligne (de 0 a 11 )	*/
/*  Le mux general ainsi que tous les bolos de la ligne ont le meme numero bolo num		*/
/*	 bolo num  =  adresse de l'ampli ligne  =  numero de la MLPA utilisee pour le mux)	*/
/*	 bolo num  est limite en principe a 128	 pour les commandes				*/

/* --------------------------------   pour  la BEMUX    -------------------------------		*/
/*  type bmux_bolo reservee 41 a  56  pour jusqu'a 16 bolos par ligne	*/
/*  les bolo individuels ont pour type  _type_bmux_bolo + Numero dans la ligne (de 0 a 11 )	*/
/*  Le mux general ainsi que tous les bolos de la ligne ont le meme numero bolo num		*/
/*	 bolo num  =  adresse de l'ampli ligne  =  numero de la BEBO + indice de carte  utilisee pour le mux)	*/
/*	 bolo num  est limite en principe a 128	 pour les commandes				*/


/*

// les definitions suvantes s'appliquen a un numero de bolo  n_bol
#define		_gainbrut(Gr,n_bol)			((int)(((Gr).bolo_rg1[n_bol]&0x1f)))	
#define		_phase_bolo(Gr,n_bol)		((int)(((Gr).bolo_rg1[n_bol]&0x60)>>5))				
#define		_comm(Gr,n_bol)				((int)(((Gr).bolo_rg1[n_bol]&0x80)>>7))				
#define		_dac_V(Gr,n_bol)			((int)(((Gr).bolo_rg1[n_bol]&0x000fff00l)>>8)	)		
#define		_dac_I(Gr,n_bol)			((int)(((Gr).bolo_rg1[n_bol]&0xfff00000l)>>20))			
//#define		_debloque_voie(Gr,n_bol)	((Gr).bolo_rg2[n_bol] = (Gr).bolo_rg2[n_bol] &0xfffffff7l)		
//#define		_bloque_voie(Gr,n_bol)		((Gr).bolo_rg2[n_bol] = (Gr).bolo_rg2[n_bol] |0x00000008l)		
#define		_dac_T(Gr,n_bol)			((int)(((Gr).bolo_rg2[n_bol]&0x000fff00l)>>8))		
#define		_dac_L(Gr,n_bol)			((int)(((Gr).bolo_rg2[n_bol]&0xfff00000l)>>20))		
//eq #define		_voie_reglage(Gr,n_bol)	((int)(((Gr).bolo_rg2[n_bol] & 0xff )))					

//==================  Je remplace la voie par un code equi (8 bit) dont le bit zero indique s'il faut faire un equilibrage continu dans opera
#define		_equi(Gr,n_bol)		((int)(((Gr).bolo_rg2[n_bol] & 0xff )))

// AUB DEBUG - les champs ont ete melanges !!!
#define		_rgl_bolo_mot1(dacV,dacI,gainbrut,phase,comm)	(((uint4)(gainbrut))&0x1f) | ((((uint4)(phase))&3)<<5) | ((((uint4)(comm))&1)<<7) | ((((uint4)(dacV))&0xfff)<<8) | ((((uint4)(dacI))&0xfff)<<20) 
#define		_rgl_bolo_mot2(dacT,dacL,equi)					(((uint4)(equi))&0xff) 	  | ((((uint4)(dacT))&0xfff)<<8) | ((((uint4)(dacL))&0xfff)<<20)
*/

/* ------------      pour le multiplexeur, avec bemux, je change tout !!!!! ----- */
//  je ne garde que la voie au mem endroit  (8 bit poid faible de mot2)
// dans reglage1 je mets 4 bit de gain, 12bit de capa et 16 bit de reference
// dans reglage2 on 8 bit de decalage 8 bit de delai  8 bit pour Q et 8 bit pour I 
// le gain ne va que de 0 a 7 avec les memes gains que MLPA

/*

#define		_gain_mux(Gr,n_bol)			((int)(((Gr).bolo_rg1[n_bol] & 0x0000000f )))						
#define		_capa_mux(Gr,n_bol)			((int)(((Gr).bolo_rg1[n_bol] & 0x0000fff0 )>>4))				
//#define		_ref_mux(Gr,n_bol)		(-2048+(int)(((Gr).bolo_rg1[n_bol] & 0xffff0000 )>>16))			
#define		_ref_mux(Gr,n_bol)			(2048-(int)(((Gr).bolo_rg1[n_bol] & 0xffff0000 )>>16))				
#define		_ref_mux_en_V(Gr,n_bol)		(_ref_mux(Gr,n_bol) * 0.01/2048)
#define		_voie_mux(Gr,n_bol)			((int)(((Gr).bolo_rg2[n_bol]&0xff)))					
#define		_decale_mux(Gr,n_bol)		((int)(((Gr).bolo_rg2[n_bol] & 0x00000700)>>8))					
#define		_retard_mux(Gr,n_bol)		((int)(((Gr).bolo_rg2[n_bol] & 0x0000f800)>>11))				
#define		_Q_mux(Gr,n_bol)			((int)(char)(((Gr).bolo_rg2[n_bol] & 0x00ff0000)>>16))				
#define		_I_mux(Gr,n_bol)			((int)(char)(((Gr).bolo_rg2[n_bol] & 0xff000000)>>24))			

//#define		_rgl_mux_mot1(gain,capa,ref)	(((uint4)(gain))&0x0f) | ((((uint4)(capa))&0xfff)<<4) | ((((uint4)(ref+2048))&0xffff)<<16) 
#define		_rgl_mux_mot1(gain,capa,ref)	(((uint4)(gain))&0x0f) | ((((uint4)(capa))&0xfff)<<4) | ((((uint4)(2048-ref))&0xffff)<<16) 
#define		_rgl_mux_mot2(voie,decale,retard,Q,I)	(((uint4)(voie))&0xff) 	 |  ((((uint4)(decale))&0x07)<<8) | ((((uint4)(retard))&0x1f)<<11)	 |  ((((uint4)(Q))&0xff)<<16) | ((((uint4)(I))&0xff)<<24)

// _rgl_mux_mot1(_gain_mux(G_reglag,n_bol),_capa_mux(G_reglag,n_bol),_ref_mux(G_reglag,n_bol))
// _rgl_mux_mot2(_voie_mux(G_reglag,n_bol),_decale_mux(G_reglag,n_bol),_retard_mux(G_reglag,n_bol),_Q_mux(G_reglag,n_bol),_I_mux(G_reglag,n_bol))

*/

// rappel des----  definitions des champs de  mux    --------------------------------
//enum {_mux_polar, _mux_DS,_mux_t_mort_grille,_mux_grille1,_mux_grille2};

// mot 0 :   _mux_polar		pilotage des dacs de la boite cmd_grille
#define		_dac_off			((int)((Rgl[_r_mux][_mux_polar]&0x00000fffl)))		
#define		_dac_on		((int)((Rgl[_r_mux][_mux_polar]&0x00fff000l)>>12))		
#define		_code_relai		((int)((Rgl[_r_mux][_mux_polar]&0xff000000l)>>24))		
#define		_rgl_mux_polar(dacon,dacoff,relai)	((((long)(dacoff))&0xfff) | ((((long)(dacon))&0xfff)<<12) | ((((long)(relai))&0xff)<<24) )

// mot 1 :   _mux_DS			 obsolete : a passer en local _mux_filtre_zero et _mux_option
#define		_mux_zero_min		((int)(((Rgl[_r_mux][_mux_DS])&0xfc000000l)>>26))
#define		_mux_zero_max		((int)(((Rgl[_r_mux][_mux_DS])&0x03f00000l)>>20))
#define		_mux_bolo_min		((int)(((Rgl[_r_mux][_mux_DS])&0x000ff000l)>>12))

#define		_mux_option(di)			(di)->mux_option
#define		_mux_filtre_ref(di)		(di)->mux_filtre_ref

// le code suivant sert a coder  Rgl[_r_mux][_mux_DS]
#define		_code_mot_mux(aa,bb,cc,dd,ee)  ((((uint4)(aa))&0x3f) << 26) | ((((uint4)(bb))&0x3f) << 20) | ((((uint4)(cc))&0xff) << 12) | ((((uint4)(dd))&0xff) << 4) | ((((uint4)(ee))&0x0f) ) ;


// mot 2	_mux_t_mort_grille		pilotage des temps mort  aqmx_tm_sw_ref  et  aqmx_tm_sw_bol
#define		_sw_ref				((int)(((Rgl[_r_mux][_mux_t_mort_grille])&0x000000ffl)))
#define		_sw_bol				((int)(((Rgl[_r_mux][_mux_t_mort_grille])&0x0000ff00l)>>8 ))
#define		_rgl_mux_tm_grille(sw_ref,sw_bol)	((((long)(sw_ref))&0xff) | (((long)(sw_bol))&0xff)<<8) 

// mots 3 et 4  pour le masque de grille

/* dans  Rgl[_r_mux]_grille[0]  je code sur 4 bit la valeur de grille pour phase				*/	
/*  la premiere phase est en poid faible (4 derniers bit) et ainsi de suite			 	*/
/* le mux general contient le gain dans  rgl_mot1 et la voie dans  rgl_mot2				*/
/* je met les valeur off et on et la polar dans 		Rgl[_r_mux]_polar			*/
/*  On a maintenant 2* 12 bit soit 24 bit utiles							*/
#define		_val_grille(n_phase)	((n_phase<8)?(char)((Rgl[_r_mux][_mux_grille1]>>(n_phase*4) )&0x0f):(char)((Rgl[_r_mux][_mux_grille2]>>((n_phase-8)*4) )&0x0f))		

#define		_rgl_mux_grille1(g)	(g[0]|(g[1]<<4)|(g[2]<<8)|(g[3]<<12)|(g[4]<<16)|(g[5]<<20)|(g[6]<<24)|(g[7]<<28))
#define		_rgl_mux_grille2(g)	(g[8]|(g[9]<<4)|(g[10]<<8)|(g[11]<<12)|(g[12]<<16)|(g[13]<<20)|(g[14]<<24)|(g[15]<<28))



//---------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------------------



//---------------------    pour l'equilibrage automatique    --------------------------------------------

/*
#define		_cmd_equi(voie)		((RG_opera[voie]&0x0000000f))
#define		_mode_equi(voie)	((RG_opera[voie]&0x000000f0)>>4)
#define		_gain_equi(voie)	((RG_opera[voie]&0x0000ff00)>>8)
#define		_courant_equi(voie)	((RG_opera[voie]&0x00ff0000)>>16)
#define		_delai_equi(voie)	((RG_opera[voie]&0xff000000)>>24)

#define		_cmd_equi_st		((st->ma_commande&0x0000000f))
#define		_mode_equi_st		((st->ma_commande&0x000000f0)>>4)
#define		_gain_equi_st		((st->ma_commande&0x0000ff00)>>8)
#define		_courant_equi_st	((st->ma_commande&0x00ff0000)>>16)
#define		_delai_equi_st		((st->ma_commande&0xff000000)>>24)
*/

enum{_cmd_equi_inactif,_cmd_equi_equilibrage,_cmd_equi_chg_mode,_cmd_equi_chg_gain,_cmd_equi_chg_courant,_cmd_equi_chg_delai};					/* code de commande pour change un parametre d'equilibrage : */
enum{_mode_equi_rien,_mode_equi_1fois,_mode_equi_auto,_mode_equi_continu,_mode_equi_transitoire,_mode_equi_total,_nb_mode_equi};		/* mode d'equilibrage : valeur de  mode_equi	*/
#define		_fabrique_code_equi(cmd_equi,mode_equi,gain_equi,courant_equi,delai_equi) (((int4)((int)cmd_equi&0xf))+(((int4)((int)mode_equi&0xf))<<4)+(((int4)((int)gain_equi&0xff))<<8)+(((int4)((int)courant_equi&0xff))<<16)+(((int4)((int)delai_equi&0xff))<<24))

/* mode de regulation : valeur de  mode_reg	*/
enum{regul_stop,regul_chauffage_null,regul_sans_deglitch,regul_avec_deglitch,arret_total,stop_moteur,moteur_direct_p,moteur_regul_p,moteur_direct_m,moteur_regul_m};


//--------------------------------------------------------------------------------------------------------------------------------------------
	//--------------------------------------
	//       Define pour bolometres       --
	//--------------------------------------
	
	//-----    pour le mux, definition des options    
enum{_mux_option_val_brute=0,_mux_option_soustrait_ref,_mux_option_soustrait_ref_filtre,_nb_options_mux};
#define _define_noms_options_mux	char noms_options_mux[_nb_options_mux][32]={"Valeur brute","Soustrait Ref","Soustrait Ref filtree"};



#endif		//		#ifdef azertyuiopp

#endif  // __A_BLOC_H
