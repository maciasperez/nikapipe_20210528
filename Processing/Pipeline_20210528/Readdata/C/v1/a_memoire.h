#ifndef __A_MEMOIRE_H
#define __A_MEMOIRE_H

//------    pour connaitre la memoire partagee disponible dans le mac :

//				sysctl -A | grep shm

//------    pour la modifier, creer le fichier      /etc/sysctl.conf   et rebooter
//		kern.sysv.shmmax=134217728
//		kern.sysv.shmmin=4
//		kern.sysv.shmmni=512
//		kern.sysv.shmseg=128
//		kern.sysv.shmall=16384

//  le fichier est dans Camera/programme/kani  :  il suffit de le copier :
//  aller dans /etc  et faire    sudo cp /Users/archeops/Camera/programmes/kani/sysctl.conf  sysctl.conf
//                              sudo cp /Users/archeops/ManipQt/bin/sysctl.conf sysctl.conf
// puis rebooter


//==========================================================================================================================================
//========================     je mets ici les definitions de la memoire partagee        ====================================
//==========================================================================================================================================

#include "name_list.h"

#define __A_MEMOIRE__

#ifndef int4
	#define int4 int
	#define uint4 unsigned int4
	#define undef_int4		0x7fffffff
#endif



//----------  le nombre de reglage, param et data possibles a partir des enum de  name_list.h -----------
#define _nb_reglage_possibles 	(_nb_type_reglage_possibles*_nb_max_acqbox)
#define _nb_param_c_b_possibles	(_nb_param_simple_possibles+ _nb_max_acqbox*_nb_param_box_possibles)
#define _nb_param_possibles		(_nb_param_c_b_possibles   + _nb_param_detecteur_possibles)
#define _nb_data_c_b_possibles	(_nb_data_simple_possibles + _nb_data_box_possibles*_nb_max_acqbox)
#define _nb_data_possibles		(_nb_data_c_b_possibles    + _nb_data_detecteur_possibles)


// structure donnant la position de tous les elements contenu dans le header
// les positions sont comptées en int4 a partir du debut du header
// on obtient le pointeur sur un element par int4* ptxx = (((int4*)dhs) + dhp->elementxx);
typedef struct {
	int	P_tableau_reglage;
	int	P_nom_reglage;
	int	P_nom_param_c;
	int	P_nom_param_d;
	int P_val_reglage;
	int P_val_param_c;
	int P_val_param_d;
	int	P_nom_brut_c;
	int	P_nom_brut_d;
	int	P_nom_unite_data_c;
	int	P_nom_unite_data_d;
	int fin_header;

	int table_param_possibles;
	int table_brut_possibles;
	int table_data_possibles;
	int fin_header_complet;

	int L_brut_c;
	int L_brut_d;
	int L_brut_periode;
	int L_brut_total;

	int L_data_c;
	int L_data_d;
	int L_data_periode;
	int L_data_total;

	int		reglage_possibles[_nb_reglage_possibles];
	int4	*param_possibles[_nb_param_possibles];
	int		brut_possibles[_nb_data_possibles];
	int		data_possibles[_nb_data_possibles];

} Data_header_position;



typedef struct {
	// attention, le 2 premiers int sont utilise comme long dans read nika_suite  pour se rappeler la position dans le fichier
	// les 2 donnees suivantes sont utilise pour fixer le nombre de detecteurs demande lors de la relecture dans read_nika_suite
	//	int4	num_param;					// doit etre au debut pour l'ecriture conditionnelle du param
	//	int4	num_bloc_brut;				// n'est plus utilise !!
	//	int4	num_bloc_data;				// n'est plus utilise !!
	//	int4	num_reglage;				// incremente chaque fois que l'on recoit un nouveau reglage pour mise a jour des fenetres

	int4	libre0;						//0 emplacement utilise a la lecture du fichier par READ_NIKA_SUITE
	//	pour stocker la position dans le fichier (entier long en libre0 et libre1)
	int4	libre1;						//1 emplacement libre

	Data_header_position*pointeur_dhp;	// ca ne marche que si c'est bien un pointeur sur 8 octets
	//int4	pointeur_dhp;				//2 emplacement utilise pour sstocker le pointeur dhp
	//int4	libre3;						//3 emplacement libre pour le pointeur dhp (8 octets)  par cast sur (void*)

	int4	boite_num;					//4 permet d'attribuer un numero de boite lors de l'initialisation d'un instrument
	// dans la memoire partagee, donne le numero du array traite par lecture
	int4	echantillonnage_nano;		// l'echantillonage en nano sec (sera modifie si l'on change l'horloge d'acquisition
	int4	nb_boites_mesure;			// le nb de boites de mesure
	int4	nb_detecteurs;				//7 le nb total de detecteurs

	int4	nb_pt_bloc;					//8 le nb de points de mesures dans un bloc:  36 ou 72
	int4	nb_sample_fichier;			// utilisee par la fonction read_header() en relecture de fichier
	// utilisee aussi par acqui pour demander un nouveau fichier
	int4	nb_det_mini;				// le nombre de detetcteurs dans le bloc mini
	int4	futur3;

	//int4	nb_blocs_shared_mem;
	int4	version_header;				//12 le nb_blocs_shared_mem n'est plus utilise pour autre chose que la version du header

	int4	nb_param_c;					// le nombre de parametres communs (en nombre d'entier 32bit int4 ) incluant le nom d'experience
	int4	nb_param_d;					// lle nombre de parametres detecteurs (le nombre total sera  nb_param_d * nb_detecteurs )
	int4	lg_header_util;				// longueur totale du bloc Dhs util (listes de noms, reglages et parametres sans le tableau final)

	int4	nb_brut_c;                  //16 le nombre de brut communs  :    pour chaque point de mesure, on a   nb_brut_c   brut
	int4	nb_brut_d;                  // le nombre de brut detecteurs  : pour chaque point de mesure, on a   (nb_brut_d * nb_detecteurs)   brut
	int4	nb_brut_periode;			// pour les brut et les data periode, le nb de points maxi par periode pour chaque detecteur  :
	//					dans chaque bloc de brut, on a  (nb_brut_periode * nb_detecteurs)  brut periode

	int4	nb_data_c;					// le nombre de data communs  :    pour chaque point de mesure, on a   nb_data_c   data
	int4	nb_data_d;					//20 le nombre de data detecteurs  : pour chaque point de mesure, on a   (nb_data_d * nb_detecteurs)   data
	int4	nb_champ_reglage;			// le nomdre de champs du reglage
	int4	champ_reglage[0];			//22	en fait on aura ici 3*nb_champ_reglage ou 6*nb_champ_reglage  entiers  (suivant la version du header)
} Data_header_shared_memory;


#define  _DHP(dhs)  (* ((Data_header_position**)  & (dhs->pointeur_dhp)) )
#define  _free_dhs(dhs)	{if(_DHP(dhs)) free(_DHP(dhs)); free(dhs);}

#define _version_courante_header(dhs)		((((dhs)->version_header) >>16)&0Xff)



#define _nouveau_reglage	1
#define	_nouvelles_data		2
#define	_nouveau_brut		4



/// dans la memoire partagee, ce header est suivit de la liste des champs du reglage,
//										pour chaque champ, la longueur, l'indice d'acces en entiers  et le numero de boite associe
// ensuite, on a la liste des noms des champs du reglage  (nb_champ_reglage noms)
// puis la liste des noms des parametres, noms des elements communs puis noms des elemets detecteurs
// ensuite, on n'aura que des entiers int4 avec
// d'abord le reglage compose de nb_champ_reglage
// puis  les parametres communs 	(nb_param_c)
// puis les parametres detecteurs			(nb_detecteurs * nb_param_d)
// pour finir le header, la liste des noms de brut communs et detecteurs
// puis   la liste des noms et unite des data communs et des data detecteurs

// la taille du header ne depend pas de dhs->nb_pt_bloc


//=============  longueur des differentes parties de Data_header_shared_memory (en octets)
#define	_len_header_shared_memory(dhs)				(sizeof(Data_header_shared_memory)+(sizeof(int4) * (dhs)->nb_champ_reglage) * ( _version_courante_header(dhs)? 6 : 3 ))
//remplacer par   4 * _DHP(dhs)->P_nom_reglage

#define	_len_noms_champ_reglage_shared_memory(dhs)	( (dhs)->nb_champ_reglage * ( _version_courante_header(dhs)? 16 : 8 ) )
#define	_len_noms_param_shared_memory(dhs)			( ((dhs)->nb_param_c+(dhs)->nb_param_d) * ( _version_courante_header(dhs)? 16 : 8 ) )
#define	_len_noms_brut_shared_memory(dhs)			( ((dhs)->nb_brut_c+(dhs)->nb_brut_d) * ( _version_courante_header(dhs)? 16 : 8 )  )
#define	_len_noms_data_shared_memory(dhs)			(2 * ((dhs)->nb_data_c+(dhs)->nb_data_d) * ( _version_courante_header(dhs)? 16 : 8 )  )

//   longueur du reglage complet en octets
#define	_len_reglage_shared_memory(dhs)				( sizeof(int4)*(_position_champ_reglage(dhs,(dhs)->nb_champ_reglage-1)+_longueur_champ_reglage(dhs,(dhs)->nb_champ_reglage-1)) )

//  longueur du param complet en octets
#define	_len_param_shared_memory(dhs)				( sizeof(int4)* ((dhs)->nb_param_c + (dhs)->nb_detecteurs * (dhs)->nb_param_d ))


//==================   la longueur d'un bloc de brut dans la shared_memory   ===================================
#define	_len_brut_bloc_shared_memory(dhs)		(sizeof(int4) * ( (dhs)->nb_pt_bloc * (dhs)->nb_brut_c + \
		(dhs)->nb_pt_bloc * (dhs)->nb_detecteurs * (dhs)->nb_brut_d + (dhs)->nb_brut_periode * (dhs)->nb_detecteurs ) )
//==================   la longueur d'un bloc de data   ===================================
#define	_len_data_bloc_shared_memory(dhs)		(sizeof(double) * ( (dhs)->nb_pt_bloc * (dhs)->nb_data_c + \
		(dhs)->nb_pt_bloc * (dhs)->nb_detecteurs * (dhs)->nb_data_d + (dhs)->nb_brut_periode * (dhs)->nb_detecteurs ) )
//remplacer  par  4 * _DHP(dhs)->L_data_total
//==================   calcul de longueur globales    ===================================
#define	_len_infos_reglage_param_shared_memory(Dhs)		( _len_header_shared_memory(Dhs) + _len_noms_champ_reglage_shared_memory(Dhs) + _len_noms_param_shared_memory(Dhs) )
//remplacer par   4 * _DHP(dhs)->P_val_reglage
#define	_len_total_reglage_shared_memory(Dhs)			(_len_infos_reglage_param_shared_memory(Dhs)+ _len_reglage_shared_memory(Dhs))
//remplacer par   4 * _DHP(dhs)->P_val_param_c
#define	_len_total_reglage_param_shared_memory(Dhs)		(_len_infos_reglage_param_shared_memory(Dhs)+ _len_reglage_shared_memory(Dhs) + _len_param_shared_memory(Dhs))
//remplacer par   4 * _DHP(dhs)->P_nom_brut_c

#define	_len_header_util_shared_memory(Dhs)				(_len_total_reglage_param_shared_memory(Dhs) + _len_noms_brut_shared_memory(Dhs)  + _len_noms_data_shared_memory(Dhs) )
//remplacer par   4 * _DHP(dhs)->fin_header


// je vais supprimer ce define
// je renome  lg_header_util    en    lg_header_malloc
#define	_len_header_complet(dhs)                ((dhs)->lg_header_util)



// pour faire un header complet, je rajoute dans Dhp les tableaux permettant de trouver plus rapidement les variable
//					en utilisant les enum de tous les noms possibles
// cette liste comprend a la suite :
//---  la liste des params		:  param_c  //  param_b * _nb_max_acqbox   //  param_d
//---  la liste des reglages	:   type_reglage_possibles * _nb_max_acqbox
//---  la liste des brut		:  brut_c  //  brut_b * _nb_max_acqbox   //  brut_d
//---  la liste des data		:  data_c  //  data_b * _nb_max_acqbox   //  data_d

#define _ppo(dhs)	( _DHP(dhs)->param_possibles )				// tableau donnant le pointeurs sur les elements du param
#define _rpo(dhs)	( _DHP(dhs)->reglage_possibles )			// tableau donnant l'indice du reglage
#define _bpo(dhs)	( _DHP(dhs)->brut_possibles )				// tableau donnant l'indice des brut dans le loc de brut
#define _dpo(dhs)	( _DHP(dhs)->data_possibles )				// tableau donnant l'indice des data dans le bloc de data


//-----------    Les blocs de brut et de data seront ranges a la suite  du header util dans la memoire partagee   --------------
//								(int4 pour les brut et double pour les data)
//-------  on a ensuite les brutes et les datas pour un premier bloc
// puis les brut communs du 1er bloc		nb_pt_bloc * nb_brut_c
// puis les brut detecteurs du 1er bloc		nb_pt_bloc * nb_detecteurs * nb_brut_d
// puis les brut periode bolo				nb_brut_periode * nb_detecteurs
// puis les data communs du 1er bloc		nb_pt_bloc * nb_data_c
// puis les data detecteurs du 1er bloc		nb_pt_bloc * nb_detecteurs * nb_data_d
// puis les data periode bolo				nb_brut_periode * nb_detecteurs
//-------  on a ensuite les brutes et les datas pour des blocs suivant (typiquement un buffer de 10 blocs ? )
// lorsque lon lit la memoire, on lit le header d'une part avec les noms et unites
// on lit ensuite eventuellement les brut (tableau int4) ou les data (tableau de double)



// pour etre plus complet et rester compatible,  je complete ces donnees de la facon suivante:
//  le tableau reglage est en ancienne version avec 3 elements par champ reglage  (actuellement 6 elements)
//#define			_rg3(dhs)	(!_version_courante_header(dhs))
//#define			_rg3(dhs)	1		//  il n'y a que 3 elements par champ dans le tableau reglage
//#define			_rg3(dhs)	0		//  il y a 6 elements par champ dans le tableau reglage

//	les noms sont en ancienne version sur 8 octets au lieu de 16 actuellement
//#define			_ch8(dhs)	(!_version_courante_header(dhs))

//#define			__nbmrg(dhs)	( _rg3(dhs)? 3 : 6 )        // nombre d'elements pour chaque champ dans le tableau reglage
//#define			__nbch(dhs)	( _ch8(dhs)? 8 : 16 )           // nombre de caracteres dans les noms de parametres, reglages, brut et data

#define	__nbch(dhs)	( _version_courante_header(dhs) ? 16 : 8 )           // nombre de caracteres dans les noms de parametres, reglages, brut et data
// les noms de detecteurs restent toujours sur 8 caracteres

//#define	_position_champ_reglage(dhs,i)	( _version_courante_header(dhs) ? (dhs)->champ_reglage[6*(i)]   : ((dhs)->champ_reglage[3*(i)]&0xffff) )				//  la position du debut du champ dans le header  (compte en entiers 32bit a partir du 1er champ)
#define	_longueur_champ_reglage(dhs,i)	( _version_courante_header(dhs) ? (dhs)->champ_reglage[6*(i)+1] : ((dhs)->champ_reglage[3*(i)+1]&0xffff) )			//  le nombre d'elements de ce champ de reglage
#define	_acqbox_champ_reglage(dhs,i)	( _version_courante_header(dhs) ? (dhs)->champ_reglage[6*(i)+2] : ((dhs)->champ_reglage[3*(i)+2]&0xff)   )			//	le numero de la boite qui gere ce champ de reglage
#define	_array_champ_reglage(dhs,i)		( _version_courante_header(dhs) ? (dhs)->champ_reglage[6*(i)+3] : (((dhs)->champ_reglage[3*(i)+2]>>8)&0x0ff) )		//	le numero de la matrice assocee
#define	_first_det_champ_reglage(dhs,i)	( i<0 ? 0 : ( _version_courante_header(dhs) ? (dhs)->champ_reglage[6*(i)+4] : (((dhs)->champ_reglage[3*(i)]>>16)&0xffff) )	)	//  le numdet du premier detecteur
#define	_nb_det_champ_reglage(dhs,i)	( i<0 ? 0 : ( _version_courante_header(dhs) ? (dhs)->champ_reglage[6*(i)+5] : (((dhs)->champ_reglage[3*(i)+1]>>16)&0xffff) ) )	//  le nb de detecteurs de la boite

int _position_champ_reglage(Data_header_shared_memory *dhs, int i);


//=============  pointeurs en char* pour lire les noms et unites des reglages, param, brut et data  dans la Data_header_shared_memory
#define _sm_nom_champ_reglage(dhs,i)	(((char*)(dhs)) + _len_header_shared_memory(dhs)  + __nbch(dhs) * (i))
#define _sm_nom_param_c(dhs,i)			(_sm_nom_champ_reglage(dhs,(dhs)->nb_champ_reglage) + __nbch(dhs) * (i))
#define _sm_nom_param_d(dhs,i)			(_sm_nom_param_c(dhs,(dhs)->nb_param_c) + __nbch(dhs) * (i))

#define _sm_nom_brut_c(dhs,i)			(((char*)(dhs)) + _len_total_reglage_param_shared_memory(dhs)  + __nbch(dhs) * (i))	// nom seul sans unite
#define _sm_nom_brut_d(dhs,i)			(_sm_nom_brut_c(dhs,(dhs)->nb_brut_c) + __nbch(dhs) * (i))

#define _sm_nom_data_c(dhs,i)			(_sm_nom_brut_d(dhs,(dhs)->nb_brut_d) + 2 * __nbch(dhs) * (i))	// nom et unites
#define _sm_nom_data_d(dhs,i)			(_sm_nom_data_c(dhs,(dhs)->nb_data_c) + 2 * __nbch(dhs) * (i))
#define _sm_nom_unit_c(dhs,i)			(_sm_nom_data_c(dhs,i) + __nbch(dhs) )	//  unites
#define _sm_nom_unit_d(dhs,i)			(_sm_nom_data_d(dhs,i) + __nbch(dhs) )

//=============  pointeurs en int4* pour lire le reglage et param et en  char* pour lire les noms experience et noms detecteurs  =========================
//#define Param_nom                      (((char*)(dhs)) + _len_infos_reglage_param_shared_memory(dhs) + _len_reglage_shared_memory(dhs) )     // obsolete
#define _sm_nom_experiment(dhs)             (((char*)(dhs)) + _len_infos_reglage_param_shared_memory(dhs) + _len_reglage_shared_memory(dhs) )
#define _sm_param_c(dhs,i)				(((int4*)(dhs)) + _len_infos_reglage_param_shared_memory(dhs)/4 + _len_reglage_shared_memory(dhs)/4 + (i)  )
//---- pour le param detecteur : d'abord les noms a la suite puis les tables pour les indices 2 a (dhs)->nb_param_d-1
//#define _sm_bolo_nom(dhs,ndet)		((char*)(dhs) + _len_infos_reglage_param_shared_memory(dhs) + _len_reglage_shared_memory(dhs) + sizeof(int4) * (dhs)->nb_param_c +  8*(ndet)  )	// obsolete
#define _nom_detecteur(dhs,ndet)			((char*)(dhs) + _len_infos_reglage_param_shared_memory(dhs) + _len_reglage_shared_memory(dhs) + sizeof(int4) * (dhs)->nb_param_c +  8*(ndet)  )
#define _sm_param_d(dhs,i)				(_sm_param_c(dhs,(dhs)->nb_param_c) +  (i) * (dhs)->nb_detecteurs )

//=============  pointeurs en uint4* pour lire le  reglage
#define _sm_champ_reglage(dhs,i)		(((uint4*)(dhs)) + _len_infos_reglage_param_shared_memory(dhs)/4 + _position_champ_reglage(dhs,i)  )



//===================================================================================================================
//=====================		  Generation des listes completes de noms possibles			    =========================
//===================== 		les reglage que l'on accede par champ (uint4*)				=========================
//===================================================================================================================

//   Utiliser les fonctions  reglage_champ()  et  reglage_pointer()

// pour une boite donnee, on retrouve le numero du premier champ de reglage avec  _nchamp_acqbox(dhs,z)
//#define _nchamp_acqbox(dhs,z)			( (z>=0) ? (_ibx(dhs)[z]) : 0 )
// remplacer par  reglage_champ(dhs,-1,z);

// le nom de la boite est donne par  :
//#define _nom_acqbox(dhs,z)		(((z)<0)?"@commun":_sm_nom_champ_reglage(dhs,_nchamp_acqbox(dhs,z)))
//#define _nom_acqbox(dhs,z)		_sm_nom_champ_reglage(dhs,_nchamp_acqbox(dhs,z))
// la table _ibx  est obsolete : on utilise la fonction  reglage_champ(dhs,-1,z)
//#define _nom_acqbox(dhs,z)		_sm_nom_champ_reglage(dhs,_ibx(dhs)[z])
// utiliser plutot  _sm_nom_champ_reglage(dhs,p)  avec  p=reglage_champ(dhs,-1,z)
#define _nom_acqbox(dhs,z)		_sm_nom_champ_reglage(dhs,reglage_champ(dhs,-1,z))


//  retrouver le numero du champ d'un reglage  par son nom de type (p) et le numero de boite z
//#define _nreglage(dhs,p,z)		((z<0)?p:(_irg(dhs)[_nb_type_reglage_possibles*(z)+(p)]))		//achanger : mettre -1 au lieu de p si z<0
// a remplacer par la fonction  reglage_champ(dhs,type_reglage,z)

// le pointeur sur le champ :    (NULL s'il n'existe pas  )
// a remplacer par la fonction    int4* reglage_pointer(dhs,p,z)
//#define reglage_pointer(dhs,p,z)  ( _nreglage(dhs,p,z)>=0 ? _sm_champ_reglage(dhs,_nreglage(dhs,p,z)): NULL )
// a remplacer par la fonction  reglage_pointer(dhs,type_reglage,z)

// pour avoir les numero de detecteurs associes a une boite: ca marche toujours mais peut donner zero
//#define _first_det_box(dhs,z)   _first_det_champ_reglage(dhs,_nchamp_acqbox(dhs,z))
//#define _first_det_box(dhs,z)   _first_det_champ_reglage(dhs,_ibx(dhs)[z])
// ici il faut utiliser  p=reglage_champ(dhs,-1,z) puis  _first_det_champ_reglage(dhs,p)
#define _first_det_box(dhs,z)   _first_det_champ_reglage(dhs,reglage_champ(dhs,-1,z))


#define _nb_det_box(dhs,z)		_nb_det_champ_reglage(dhs,reglage_champ(dhs,-1,z))
#define _array_box(dhs,z)		_array_champ_reglage(dhs,reglage_champ(dhs,-1,z))
#define _last_det_box(dhs,z)   (_first_det_box(dhs,z)+_nb_det_box(dhs,z))
// a remplacer par le calcul suivant :
// int p=reglage_champ(dhs,-1,z)		_first_det_reglage(dhs,p)		_nb_det_reglage(dhs,p)


//===================================================================================================================
//==================		Generation des listes completes de variables possibles			=========================
//========  on a les param simples, puis tous les param box pour chaque box et enfin les param detecteurs	=========
//===================================================================================================================
// les param box sont transforme en param simple en les faisant preceder de la lettre de la box
//  dans les possibles, chaque param box apparait autant de fois qu'il y a de boites de mesure possibles
// par contre les param detecteurs n'apparaissent qu'une fois

// je cherche mes brut dans la meme liste que les data meme s'il y en a moins, cela ne gene pas
//-------------------  la liste des data  et brut possibles pour le tableau brut int4  et  data en doubles ----------
//  le enum de elvin_structure doit etre identique a celui-ci  de _mg_year .. _mg_tau  correspond a _d_year .. _d_tau
// ATTENTION STRUCTURE DOIT ETRE IDENTIQUE DANS L'ORDRE QUE CELLE DE ELVIN_STRUCTURE.H
// de meme pour les elements de antenna qui doivent respecter l'ordre


//=====================================================================================================================
// ==============================   pour savoir si un param , un brut ou un data existe 	===========================
//=====================================================================================================================

// p est un element de l'enum des type de reglages possibles et z le numero de la boite
//#define		_presence_reglage(dhs,p,z)	(_nreglage(dhs,p,z)>=0)

//--------------------  p est un element de l'enum des param possibles   -------------------
#define	_presence_param_c(dhs,p)	(_ppo(dhs)[p])
#define	_presence_param_b(dhs,p,z)	(_ppo(dhs)[_nb_param_simple_possibles + _nb_param_box_possibles * (z)  + (p) ])
#define	_presence_param_d(dhs,p)	(_ppo(dhs)[_nb_param_c_b_possibles + (p) ])

// je change _ibr en _bpo
#define	_presence_brut(dhs,p)		((p>=0) && (_bpo(dhs)[p]>=0) )
#define	_presence_brutbox(dhs,p,z)	((p>=0) && (_bpo(dhs)[_nb_data_simple_possibles + _nb_data_box_possibles * (z)  + (p) ]>=0) )
#define	_presence_brutdet(dhs,p)	((p>=0) && (_bpo(dhs)[_nb_data_c_b_possibles+(p)]>=0) )

// je change _idd en _dpo
#define	_presence_data(dhs,p)		((p>=0) && (_dpo(dhs)[p]>=0) )
#define	_presence_databox(dhs,p,z)	((p>=0) && (_dpo(dhs)[_nb_data_simple_possibles + _nb_data_box_possibles * (z)  + (p) ]>=0) )
#define	_presence_datadet(dhs,p)	((p>=0) && (_dpo(dhs)[_nb_data_c_b_possibles + (p)]>=0) )

#define	_presence_brut_data(dhs,p)		( _presence_brut(dhs,p) && _presence_data(dhs,p) )
#define	_presence_brut_databox(dhs,p,z)	( _presence_brutbox(dhs,p,z) && _presence_databox(dhs,p,z) )
#define	_presence_brut_datadet(dhs,p)	( _presence_brutdet(dhs,p) && _presence_datadet(dhs,p) )


//=====================================================================================================================
//===================   pour lire un param, un reglage, un brut ou un data   ==========================================
//=====================================================================================================================

//========================    les param dont on lit la valeur  (int4)			===============================
#define _param_c(dhs,p)			((_ppo(dhs)[p])[0])
#define _param_b(dhs,p,z)		((_ppo(dhs)[_nb_param_simple_possibles + _nb_param_box_possibles * (z)  + (p) ])[0] )
#define _param_d(dhs,p,ndet)	((_ppo(dhs)[_nb_param_c_b_possibles + (p) ])[ndet])


//=====================================================================================================================
//=====================    les bruts lues dans le bloc  br		(en int4)						=======================
//=====================================================================================================================
//  les brut donnes par leur indice p de l'enum des possible  (i est le point dans le bloc de 0 a Dhs->npt_bloc)
// je change _ibr en _bpo
#define	_brut_pc(dhs,br,p,i)		_brut_ec(dhs,br,_bpo(dhs)[p],i)
#define	_brut_pb(dhs,br,p,z,i)		_brut_ec(dhs,br,_bpo(dhs)[_nb_data_simple_possibles + _nb_data_box_possibles * (z)  + (p) ],i)
#define	_brut_pdd(dhs,br,p,i)		_brut_ed(dhs,br,_bpo(dhs)[_nb_data_c_b_possibles+(p)],i)

//  les brut donnes par leur indice k dans la liste des brut existants dans le header  (i est le point dans le bloc de 0 a Dhs->npt_bloc)
#define	_brut_ec(dhs,br,k,i)		(br)[ (k)*(dhs)->nb_pt_bloc + (i) ]
#define	_brut_ed(dhs,br,k,i)		( (int4*)(br) + ( (dhs)->nb_brut_c * (dhs)->nb_pt_bloc + (k)*(dhs)->nb_pt_bloc*(dhs)->nb_detecteurs  + (dhs)->nb_detecteurs * (i) )  )

#define	_brut_periode(dhs,br,n_bol)		( (int4*)(br) + ( (dhs)->nb_brut_c * (dhs)->nb_pt_bloc + \
		(dhs)->nb_brut_d * (dhs)->nb_pt_bloc * (dhs)->nb_detecteurs  + (dhs)->nb_brut_periode  * (n_bol) ) )


//=====================================================================================================================
//==================    les data lues dans un bloc  dd			(en double)						=======================
//=====================================================================================================================
//  les data donnes par leur indice p de l'enum des possible  (i est le point dans le bloc de 0 a Dhs->npt_bloc)
// _idd table d'indice indiquant position variable (si pas present -1 )
// je change _idd en _dpo

#define	_data_pc(dhs,dd,p,i)		_data_ec(dhs,dd,_dpo(dhs)[p],i)
#define	_data_pb(dhs,dd,p,z,i)		_data_ec(dhs,dd,_dpo(dhs)[_nb_data_simple_possibles + _nb_data_box_possibles * (z)  + (p) ],i)
// attention,  data_pdd retourne un pointeur sur le tableau contenant la data de tous les detecteur
#define	_data_pdd(dhs,dd,p,i)		_data_ed(dhs,dd,_dpo(dhs)[_nb_data_c_b_possibles+(p)],i)

//  les data donnes par leur indice k  dans la liste des data communs existants dans le header  (i est le point dans le bloc de 0 a Dhs->npt_bloc)
#define	_data_ec(dhs,dd,k,i)		(dd)[ (k)*(dhs)->nb_pt_bloc + (i) ]
//  les data donnes par leur indice k  dans la liste des data detecteur  existants dans le header  (i est le point dans le bloc de 0 a Dhs->npt_bloc)
//  avec data_ed  on obtient un pointeur sur le tableau des valeurs de chaque detecteurs : utiliser _data_ed(dhs,dd,k,i)[n_bol]
#define	_data_ed(dhs,dd,k,i)		( ((double*)(dd)) + ( (dhs)->nb_data_c * (dhs)->nb_pt_bloc + (k)*(dhs)->nb_pt_bloc*(dhs)->nb_detecteurs  + (dhs)->nb_detecteurs * (i) )  )

//  avec data_periode  on obtient un pointeur sur le tableau periode du detecteur  ndet
#define	_data_periode(dhs,dd,ndet)		( (double*)(dd) + ( (dhs)->nb_data_c * (dhs)->nb_pt_bloc + \
		(dhs)->nb_data_d * (dhs)->nb_pt_bloc * (dhs)->nb_detecteurs  + (dhs)->nb_brut_periode  * (ndet) ) )




//=====================================================================================================================
//=====================================================================================================================
//--------------------  p est un element de l'enum des param possibles   -------------------
//=====================================================================================================================
//=====================================================================================================================

//============================   le  param   ======================================
/*
//--------------------  la valeur lue dans le tableau de recherche rapide    ---------------------------------
#define	_a_paramc(dhs,p)	_prm(dhs)[p]
#define	_a_paramb(dhs,p,z)	_prm(dhs)[_nb_param_simple_possibles + _nb_param_box_possibles * (z)  + (p) ]
#define	_a_paramd(dhs,p)	_prm(dhs)[_nb_param_c_b_possibles + (p) ]
//--------------------  test presence  des variables  ---------------------------------
#define	_p_paramc(dhs,p)	_a_paramc(dhs,p)
#define	_p_paramb(dhs,p,z)	_a_paramb(dhs,p,z)
#define	_p_paramd(dhs,p)	_a_paramd(dhs,p)
//--------------------  lecture des variables  ---------------------------------
#define	_l_paramc(dhs,p)		(_p_paramc(dhs,p)?_a_paramc(dhs,p)[0]:0)
#define	_l_paramb(dhs,p,z)		(_p_paramb(dhs,p,z)?_a_paramb(dhs,p,z)[0]:0)
#define	_l_paramd(dhs,p,det)	(_p_paramd(dhs,p)? _a_paramd(dhs,p)[det])
//--------------------  ecriture des variables  ---------------------------------
#define	_e_paramc(dhs,p,val)		{if(_p_paramc(dhs,p)  ) _a_paramc(dhs,p)[0]=val);}
#define	_e_paramb(dhs,p,z,val)		{if(_p_paramb(dhs,p,z)) _a_paramb(dhs,p,z)[0]=val);}
#define	_e_paramd(dhs,p,det,val)	{if(_p_paramd(dhs,p)  ) _a_paramd(dhs,p)[det]=val);}

//============================   le  reglage   ======================================
#define	_a_reglage(dhs,p,z)	_nreglage(dhs,p,z)
#define	_p_reglage(dhs,p,z)	(_a_reglage(dhs,p,z)>=0)
#define	_l_reglage(dhs,p,z)		(_p_reglage(dhs,p,z)?_sm_champ_reglage(dhs,_a_reglage(dhs,p,z)) :0)
#define	_e_reglage(dhs,p,z,val)		{if(_p_reglage(dhs,p,z)) _sm_champ_reglage(dhs,_a_reglage(dhs,p,z)=val;}
*/

//============================   le  brut   ======================================
/*
//--------------------  la valeur lue dans le tableau de recherche rapide    ---------------------------------
#define	_a_brutc(dhs,p)		(_ibr(dhs)[p])
#define	_a_brutb(dhs,p,z)	(_ibr(dhs)[_nb_data_simple_possibles + _nb_data_box_possibles * (z)  + (p) ])
#define	_a_brutd(dhs,p)		(_ibr(dhs)[_nb_data_c_b_possibles+(p)])
//  les brut donnes par leur indice k dans la liste des brut existants dans le header  (i est le point dans le bloc de 0 a Dhs->npt_bloc)
#define	_k_brutc(dhs,br,k,i)		(br)[ (k)*(dhs)->nb_pt_bloc + (i) ]
#define	_k_brutd(dhs,br,k,i)		( (int4*)(br) + ( (dhs)->nb_brutc * (dhs)->nb_pt_bloc + (k)*(dhs)->nb_pt_bloc*(dhs)->nb_detecteurs  + (dhs)->nb_detecteurs * (i) )  )
#define	_k_brutp(dhs,br,n_bol)		( (int4*)(br) + ( (dhs)->nb_brutc * (dhs)->nb_pt_bloc + \
//--------------------  test presence  des variables  ---------------------------------
#define	_p_brutc(dhs,p)		((p>=0) && (_a_brutc(dhs,p)>=0) )
#define	_p_brutb(dhs,p,z)	((p>=0) && (_a_brutb(dhs,p,z)>=0) )
#define	_p_brutd(dhs,p)		((p>=0) && (_a_brutd(dhs,p)>=0) )
//--------------------  lecture des variables  ---------------------------------

#define	_l_brutc(dhs,dd,p,i)		(_p_brutc(dhs,p)?_k_brut_c(dhs,br,_a_brutc(dhs,p),i):0)
#define	_l_brutb(dhs,dd,p,z,i)		(_p_brutb(dhs,p,z)?_k_brut_c(dhs,br,_a_brutb(dhs,p,z),i):0)
// attention,  _k_brut_d  et_l_brutp   retourne un pointeur sur le tableau contenant la data de chaque detecteur
#define	_l_brutd(dhs,dd,p,i)		(_k_brutp(dhs,br,n_bol)?_k_brut_d(dhs,br,_a_brutd(dhs,p),i):NULL)

//--------------------  ecriture des variables  ---------------------------------
#define	_e_brutc(dhs,dd,p,i,val)		{if(_p_brutc(dhs,p) )	_k_brut_c(dhs,br,_a_brutc(dhs,p),i)	= val;}
#define	_e_brutb(dhs,dd,p,z,i,val)		{if(_p_brutb(dhs,p,z))	_k_brut_c(dhs,br,_a_brutb(dhs,p,z),i)=val;}

//============================   les  data   ======================================
//--------------------  la valeur lue dans le tableau de recherche rapide    ---------------------------------
#define	_a_datac(dhs,p)		(_idd(dhs)[p])
#define	_a_datab(dhs,p,z)	(_idd(dhs)[_nb_data_simple_possibles + _nb_data_box_possibles * (z)  + (p) ])
#define	_a_datad(dhs,p)		(_idd(dhs)[_nb_data_c_b_possibles + (p)])
//  les data donnes par leur indice k dans la liste des brut existants dans le header  (i est le point dans le bloc de 0 a Dhs->npt_bloc)
#define	_k_datac(dhs,dd,k,i)		(dd)[ (k)*(dhs)->nb_pt_bloc + (i) ]
#define	_k_datad(dhs,dd,k,i)		( (double*)(dd) + ( (dhs)->nb_datac * (dhs)->nb_pt_bloc + (k)*(dhs)->nb_pt_bloc*(dhs)->nb_detecteurs  + (dhs)->nb_detecteurs * (i) )  )
#define	_k_datap(dhs,dd,n_bol)		( (double*)(dd) + ( (dhs)->nb_datac * (dhs)->nb_pt_bloc + \
				(dhs)->nb_data_d * (dhs)->nb_pt_bloc * (dhs)->nb_detecteurs  + (dhs)->nb_brut_periode  * (ndet) ) )
//--------------------  test presence  des variables  ---------------------------------
#define	_p_datac(dhs,p)		((p>=0) && (_a_datac(dhs,p)>=0) )
#define	_p_datab(dhs,p,z)	((p>=0) && (_a_datab(dhs,p,z)>=0) )
#define	_p_datad(dhs,p)	((p>=0) && (_a_datad(dhs,p)>=0) )

#define	_p_brutdatac(dhs,p)		( _p_brutc(dhs,p) && _p_datac(dhs,p) )
#define	_p_brutdatab(dhs,p,z)	( _p_brutb(dhs,p,z) && _p_datab(dhs,p,z) )
#define	_p_brutdatad(dhs,p)	( _p_brutd(dhs,p) && _p_datad(dhs,p) )
//--------------------  lecture des variables  ---------------------------------
#define	_l_datac(dhs,dd,p,i)		(_p_datac(dhs,p)?_k_data_c(dhs,br,_a_datac(dhs,p),i):0)
#define	_l_datab(dhs,dd,p,z,i)		(_p_datab(dhs,p,z)?_k_data_c(dhs,br,_a_datab(dhs,p,z),i):0)
// attention,  _k_data_d  et_l_datap   retourne un pointeur sur le tableau contenant la data de chaque detecteur
#define	_l_datad(dhs,dd,p,i)		(_k_datap(dhs,br,n_bol)?_k_data_d(dhs,br,_a_datad(dhs,p),i):NULL)

//--------------------  ecriture des variables  ---------------------------------
#define	_e_datac(dhs,dd,p,i,val)		{if(_p_datac(dhs,p) )	_k_data_c(dhs,br,_a_datac(dhs,p),i)	= val;}
#define	_e_datab(dhs,dd,p,z,i,val)		{if(_p_datab(dhs,p,z))	_k_data_c(dhs,br,_a_datab(dhs,p,z),i)=val;}

*/
//=====================================================================================================================
//=====================================================================================================================
//=====================================================================================================================
//=====================================================================================================================



//=================================================================================================================
//========================     prototypes des fonctions de  a_memoire.c        ====================================
//=================================================================================================================

extern void		print_noms_presents(Data_header_shared_memory *dhs);  // affiche les noms des variables presentes
extern void		print_reglages(Data_header_shared_memory *dhs);       // affiche les valeures des reglages

extern void		position_header(Data_header_shared_memory *dhs,int print);
extern Data_header_shared_memory* change_liste_data(Data_header_shared_memory* dhs,char* liste_data,int print);

enum {header_identiques,header_dif_reglage,header_dif_param_d,header_dif_param_c,header_dif_noms_reglage_param,header_dif_longueur,header_dif_nom};
extern int		compare_header(Data_header_shared_memory   *dhs1,Data_header_shared_memory   *dhs2);


//---   reglages		---
extern int		reglage_champ(Data_header_shared_memory *dhs,int type_reglage,int z);
extern int      reglage_type(Data_header_shared_memory *dhs,int nc);
extern int      reglage_parambox_associe(int rtype);
extern uint4	*reglage_pointer(Data_header_shared_memory *dhs,int type_reglage,int z);
extern uint4	*reglage_pointer_nikel_amc(Data_header_shared_memory *dhs,int z);

extern int		first_box(Data_header_shared_memory *dhs,int type_reglage);
extern int		first_box_nikel_amc_active(Data_header_shared_memory *dhs);

extern int		cherche_indice_champ_reglage(Data_header_shared_memory *dhs,char *nom_champ,int print);
extern int		nb_elements_reglage_partiel(Data_header_shared_memory *dhs,int z);


//---   params		---

extern int		cherche_indice_enum_parambox(char *nom);


extern int4	*cherche_pointeur_param_communs(Data_header_shared_memory *dhs,char *nom_indice,int print);
extern int4	*cherche_pointeur_param_detecteurs(Data_header_shared_memory *dhs,char *nom_indice,int print);
extern int4	*cherche_pointeur_param(Data_header_shared_memory *dhs,char *nom_indice,int print);


//---   brut		---
extern int		cherche_indice_brut(Data_header_shared_memory *dhs,char *nom_indice,int print);
extern int		cherche_indice_brut_commun(Data_header_shared_memory *dhs,char *nom_indice,int print);
extern int		cherche_indice_brut_detecteur(Data_header_shared_memory *dhs,char *nom_indice,int print);

//---   data		---
extern int		cherche_indice_data(Data_header_shared_memory *dhs,char *nom_indice,int print);
extern int		cherche_indice_data_commun(Data_header_shared_memory *dhs,char *nom_indice,int print);
extern int		cherche_indice_data_detecteur(Data_header_shared_memory *dhs,char *nom_indice,int print);




//=================================================================================================================
//========================     le calcul pour les  kids							====================================
//=================================================================================================================


#define	_amplitude(a,b)			(sqrt((a)*(a)+(b)*(b)))
//#define	_amplitude(a,b)			hypot((a), (b))	// C99 - But slower than sqrt by at best 15%

#ifndef _DEF_PA
#define _DEF_PA
// Note: as a macro this is slow because it does too many evaluations
static inline double petit_angle(double a)	{
	return	(a> PI) ? (a-2*PI) : 
			(a<-PI) ? (a+2*PI) :
			           a;
}
#endif


// on y va pas a pas :
#define	_dangleIQdIdQbrut(x2,x1,y2,y1)	petit_angle(atan2((x1),(y1)) - atan2((x2),(y2)))
#define	_dangleIQdIdQ(x2,x1,y2,y1)		petit_angle( -PI/2 - _dangleIQdIdQbrut(x2,x1,y2,y1))		// je veux une courbe croissante

// ancienne definition de dphase
#define _dphase(x2,x1,y2,y1)	(petit_angle(atan2(x1,y1)-atan2(x2,y2)))
// je remplace  sin(dphase)  par  -cos(dangle)
//  dangle = -PI/2 - dphase  ==>  cos(dangle) = cos(PI/2 + phase) = -sin(dphase)

extern void	calcul_kid_boite(Data_header_shared_memory *dhs,int z,double freq,int msq,int4 *I,int4 *Q,int4 *dI,int4 *dQ,
							 double *ftone,double *tangle,int *flagkid,int *width);



//=================================================================================================================
//=================================================================================================================
#endif // __A_MEMOIRE_H

