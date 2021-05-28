#ifndef __DEF__
#define __DEF__

#include "name_list.h"


#ifndef int4
	#define int4 int
	#define uint4 unsigned int4
	#define undef_int4		0x7fffffff
#endif


//==========================================================================================================================================
//==========================================================================================================================================

#ifndef _ech
	#define _ech (1e-9*(double)Dhs->echantillonnage_nano)
#endif




//==========================================================================================================================================
//===================     je mets ici les definitions permettant l'utilisation des reglages et param      ==================================
//==========================================================================================================================================

//Ces definitions necessitent la definition des variables globales suivantes
// Pour le param , on a des pointeurs de int4  d'obtenir les parametres pour chaque detecteurs
// ces pointeurs sont definis avec la fonction    cherche_pointeur_param(Dhs,"xxxx");  ou xxxx est le nom du parametre
// Pour le reglage , on a des pointeurs de uint4  sur les champs du reglage
//  reglage_pointer(Dhs,_r_opera,-1) , RG1_opera , RG2_opera



//=============================    en  mode  kid   le type    ==================================
/*
#define	 __kid_null			0
#define  __kid_pixel		1
#define  __kid_off			2
#define  __kid_blind		3
#define  __kid_nb_types		4
*/
enum {__kid_null,__kid_pixel,__kid_off,__kid_blind,__kid_nb_types};


#define _def_lettre_type	char type_lettre[__kid_nb_types][2]={"N","K","O","B"};
#define _def_couleur_type	int  type_couleur[__kid_nb_types]={_magenta,_cyan,_jaune,_orange};
#define _lettre_to_type(typ_char,typ)   {_def_lettre_type typ=__kid_nb_types-1; \
                                        while (strcmp(typ_char,type_lettre[typ]) && (typ>0) )  {typ--;}}
#define _det_couleur(dhs,ndet,coul) {_def_couleur_type;coul=_noir; if(_type_det(dhs,ndet)<__kid_nb_types) coul=type_couleur[_type_det(dhs,ndet)];}

//   le type contient  le type  , le masque ,  le numero de boite (acqbox)  et  le numero de la matrice (array)
#define _type_det(dhs,ndet)	(  _param_d((dhs), _pd_type, (ndet))  &0x0ff )
#define _masq_det(dhs,ndet)	( ( _param_d((dhs), _pd_type, (ndet))>>8)  &0x0ff )
#define   _acqbox(dhs,ndet)	( (_param_d((dhs), _pd_type, (ndet))>>16) & 0xff)
#define    _array(dhs,ndet)	( (_param_d((dhs), _pd_type, (ndet))>>24) & 0x0f)

#define _change_type(dhs, ndet, typ)  _param_d((dhs), _pd_type, (ndet))= ( ( _param_d((dhs), _pd_type, (ndet)) & 0xfffff000) | (typ) )
#define _masque_type(dhs, ndet, typ)  _param_d((dhs), _pd_type, (ndet))= ( ( _param_d((dhs), _pd_type, (ndet)) & 0xffff00ff) | ((typ)<<8) )

#define	_kid_pixel(ndet)		(_type_det(Dhs,  (ndet))==__kid_pixel)
#define	_kid_reson(ndet)		( (_type_det(Dhs,  (ndet))==__kid_pixel) || (_type_det(Dhs,  (ndet))==__kid_blind) )
#define	_kid_off(ndet)			(_type_det(Dhs,(ndet))==__kid_off)
#define	_kid_null(ndet)		(_type_det(Dhs,  (ndet))==__kid_null)

//#define _kid_couleur(n_kid)		(_kid_pixel(n_kid) ? _rouge : _vert )


//==========================================================================================================================================
//=====================//----------------------------------   code_util  des bolos et des kids  -------------------------------------------

#define		_bolo_actif			1				//=====================    en  mode  bolo  le code_util  ====
#define		_bolo_transmis_une_periode	4

#define		_bolo_est_actif(n_bol)	(_param_d(Dhs,_pd_codeutil, (n_bol))&_bolo_actif)
#define		_bolo_est_inactif(n_bol)	(!_bolo_est_actif(n_bol))

#define  __bolo_pixel       32
#define _det_pixel(dhs,ndet)  ( (_type_det(Dhs,ndet)==__kid_pixel) || (_type_det(Dhs,ndet)==__bolo_pixel) )

//================================================================================================================================
//===================							les definitions pour les kid						==============================
//================================================================================================================================



#define _maxi_bin_num(dhs,z)			(_presence_param_b(dhs,_pb_maxbin,z)? _param_b(dhs,_pb_maxbin,z):131000)
#define _diviseur_kid(dhs)				(_presence_param_c(dhs,_p_div_kid)? _param_c(dhs,_p_div_kid):80)

#define	_kid_frequence(dhs,n_bol)		(_presence_param_d(dhs,_pd_frequency)? (0.01 * (double)_param_d(dhs,_pd_frequency,n_bol)):			\
		(_presence_param_d(dhs,_pd_res_frq)? (0.01 * (double)_param_d(dhs,_pd_res_frq,n_bol)) : 0 ))// en KHz	(elle est en unite de 10Hz dans le param)


//#define _flag_du_paramd(dhs,n_bol)		(_presence_param_d(dhs,_pd_flag)? _param_d(dhs,_pd_flag,n_bol):0)
//#define _width_du_paramd(dhs,n_bol)		(_presence_param_d(dhs,_pd_width)? _param_d(dhs,_pd_width,n_bol):0)


//-----   chaque code reglage en fonction des parametres   --------------------

//  la freq_par_bin est un double en KHz  et le pas est un entier de 0 a 16 codant :
//			int pas = 5;  // 5 -> *5    6 -> *10    7 -> *20
// je remplace le mac_auto obsolete par le type_balayage : sert pour passer en mode_regulier
#define _code_kid_balayage1(freq_par_bin,pas)									((((int)(100000.*freq_par_bin))&0xffffff) | ((((int)(pas))<<24)&0x0f000000) )
#define	_code_kid_balayage2(nb_pas,temps_mort,duree,action,type_balayage)		((((int)(nb_pas))&0x0fff)  | ((((int)(temps_mort))<<12)&0x0000f000)  | ((((int)(duree))<<16)&0x00ff0000) | ((((int)(action))<<24)&0x03000000)  | ((((unsigned int)(type_balayage))<<26)&0x3c000000) )
#define	send_kid_balayage_mot1(z,freq_par_bin,pas)								commande_synthe_enum(Dhs,z ,_kid_balayage1,_code_kid_balayage1(freq_par_bin,pas))
#define	send_kid_balayage_mot2(z,nb_pas,temps_mort,duree,action,type_balayage)	commande_synthe_enum(Dhs,z ,_kid_balayage2,_code_kid_balayage2(nb_pas,temps_mort,duree,action,type_balayage))

//------   retrouver les parametres a partir du reglage  kid_X = _reglage_box(dhs,_r_nikel,z);


//#define	kid_balayage_freq_par_binX_brut(kid_X)	(0.00001*(double)(kid_X[_kid_balayage1]&0xffffff))	// en kHz		(elle est en 1/100 Hz dans le reglage)
//#define	_kid_freq_par_bin                           (0.953674)	// en kHz
#define	_f_bin                                      (0.953674)	// en kHz
//#define	kid_balayage_freq_par_binX_brut(kid_X)		(0.953674)	// en kHz
//#define	kid_balayage_freq_par_binX(kid_X)			(kid_balayage_freq_par_binX_brut(kid_X)>0.5?kid_balayage_freq_par_binX_brut(kid_X):0.5)

#define	kid_balayage_freq_baseX(kid_X)				(0.01*(double)kid_X[_kid_f_base])				// en kHz		(elle est en unite de 10Hz dans le reglage)
#define _regl_ampl_mod(kid_X)                       ((kid_X[_kid_f_modul]>>16)&0xff)		// pour relire les anciens fichiers run 5 et 6 en kHz de 1 a 250 kHz
#define	kid_balayage_pas(kid_X)			(int)((kid_X[_kid_balayage1]>>24)&0xf)				// codage pas en fonction du bin (indice dans _pas_synthe)
// ici on a le pas du balayage en bin de 0.1  a 10 ou 20
#define	kid_balayage_val_pas(kid_X)		(((kid_balayage_pas(kid_X)>=0)&&(kid_balayage_pas(kid_X)<_nb_pas_synthe_possibles))?_pas_synthe[kid_balayage_pas(kid_X)]:1)		// pas du balayage en bin (double)

#define	kid_balayage_nb_pas(kid_X)		(int)(kid_X[_kid_balayage2]&0xfff)				// nombre de pas en frequence par demi-scan
#define	kid_balayage_temps_mort(kid_X)	(int)(kid_X[_kid_balayage2]>>12&0xf)				// duree du temps mort, en nb de mesures
#define	kid_balayage_duree(kid_X)		(int)((kid_X[_kid_balayage2]>>16)&0xff)			// duree de chaque pas (en nb de mesures)
#define	kid_balayage_action(kid_X)		(int)((kid_X[_kid_balayage2]>>24)&0x3)			// action de balayage sur 2 bit
//#define	kid_balayage_mac_auto(kid_X)	(int)((kid_X[_kid_balayage2]>>26)&0xf)			// obsolete : remplace par auto_tune dans le param
#define	kid_balayage_mode_mesure(kid_X)	(int)((kid_X[_kid_balayage2]>>26)&0xf)			// a la place de l'ancien mac_auto

enum {_arret_balayage,_demarre_balayage,_balayage_en_cours};
#define fixe_action_balayage(kid_X,action)	kid_X[_kid_balayage2] = (kid_X[_kid_balayage2] & 0x1cffffff ) | ((((int)(action))<<24)&0x03000000)


#define _echantillonnage_kid(kid_X)				(1/(_f_bin*1000./(double)_diviseur_kid(Dhs)) )			// ce sont des secondes
#define _echantillonnage_nano_kid(dhs,kid_X)	(_diviseur_kid(dhs) * 1000000/ _f_bin )			// ce sont des nano secondes car  freq_par_bin est en Khz


#define _nb_pas_synthe_possibles	13
#define _def_pas_synthe	double _pas_synthe[_nb_pas_synthe_possibles]={0.1,0.2,0.5,1,2,5,10,20,50,100,200,500,1000};

//------ tous les flags apparaissent dans les data  "k_flag" de chaque detecteur   ---------------------

//-1-  les flags particulies lies aux boite de mesure  nikel  ou AMC :
//		ces flags sont dans les brut  sous le nom     A_masq  B_masq  ...
//      --- il n' pas change depuis les run 5 et 6
//      --- sauf le _flag_tuning_en_cours qui apparait apres le run14

// les flags ici sont echantillonés pour chaque sample
#define		_flag_balayage_en_cours				0x01		// flag0 ecrit lors du balayage du synthe
#define		_flag_blanking_synthe				0x02		// flag1 ecrit lors du balayage du synthe
#define		_flag_fpga_change_frequence			0x04		// flag3 indique le chargement des tones
#define		_flag_tuning_en_cours				0x08		// flag4 indique un decalage ou tuning en cours
#define		_flag_data_manquante				0x10		// flag5 indique une data absente
#define		_flag_bin_hors_bande				0x10		// flag5 indique une data absente
#define     _flag_cmd_chg_freq                  0x10        // idem flag data manquante
#define     _flags_du_masque                    0x1f        // les flags du masque bien echantillonés


//-2-   les flags lies aux detecteurs et apparaissant dans le reglage pour chaque detecteur :
//       ils sont ensuite recopié dans les "k_flag"  par la fonction brut_to_data

#define		_flag_mauvais_tuning				0x20		// flag6 fixe par le prg  calcul_tuning_2
#define		_flag_resonnance_mal_placee			0x40        // flag7 les resonnances qui semblent avoir bougées
#define		_flag_resonnance_perdue				0x80		// ecrit par le calcul apres un balayage
#define     _flags_du_reglage                   0xE0        // les flags du reglage mal echantillonés


#define     _flag_to_string(flag,ss)  {char * code_flag[8] =  {"b","s","f","t","h","m","p","u"};\
            int u;strcpy(ss,""); \
            for(u=0;u<8;u++)    { if((flag>>u)&1) strcat(ss,code_flag[u]);  }}

#define     _string_to_flag(flag,ss) {char * code_flag[8] =  {"b","s","f","t","h","m","p","u"};\
            int i,j;flag=0;\
            for(i=0;i<(int)strlen(ss);i++) for(j=0;j<8;j++) { if(code_flag[j][0]==ss[i]) flag|= 1<<j; }}



#define _phase_en_rad			0.001					// pour que la phase soit en radian (nouvelle version ou la phase brute est en milli-radians)


#endif	//  #ifndef __DEF__

