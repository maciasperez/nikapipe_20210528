#ifndef __A_DEF__
#define __A_DEF__

#include "name_list.h"


#ifndef int4
    #define int4 int
    #define uint4 unsigned int4
    #define undef_int4		0x7fffffff
#endif


//#define     undef_double	-32768.5
//#ifndef pi
//    #define pi	3.1415926535897932384626433832795028841971L
//#endif

//==========================================================================================================================================
//==========================================================================================================================================

#ifndef _ech
    #define _ech (1e-9*(double)Dhs->echantillonnage_nano)
#endif

//==========================================================================================================================================
//=====================   le type contient  le type  ,  le numero de boite (acqbox)  et  le numero de la matrice (array)
#define _type_det(dhs,n_bol)	(  _param_d((dhs), _pd_type, (n_bol))  &0xffff )
#define   _acqbox(dhs,n_bol)	( (_param_d((dhs), _pd_type, (n_bol))>>16) & 0xff)
#define    _array(dhs,n_bol)	( (_param_d((dhs), _pd_type, (n_bol))>>24) & 0x0f)

#define _change_type(dhs, n_bol, typ)  _param_d((dhs), _pd_type, (n_bol))= ( _param_d((dhs), _pd_type, (n_bol)) & 0xffff0000) | (typ)

//#define	_premiere_boite_type(dhs,type, z) for (z=0; z<(dhs)->nb_boites_mesure; (z)++) if (_presence_reglage((dhs), type, (z))) break;
//#define _premiere_boite_nikel(dhs, z) _premiere_boite_type(dhs,_r_nikel, z)



//==========================================================================================================================================
//===================     je mets ici les definitions permettant l'utilisation des reglages et param      ==================================
//==========================================================================================================================================

//Ces definitions necessitent la definition des variables globales suivantes
// Pour le param , on a des pointeurs de int4  d'obtenir les parametres pour chaque detecteurs
// ces pointeurs sont definis avec la fonction    cherche_pointeur_param(Dhs,"xxxx");  ou xxxx est le nom du parametre  
// Pour le reglage , on a des pointeurs de uint4  sur les champs du reglage
//  _reglage(Dhs,_r_opera,0) , RG1_opera , RG2_opera


//----------------------------------   code_util  des bolos et des kids  -------------------------------------------

#define		_bolo_actif			1				//=====================    en  mode  bolo  le code_util  ====
#define		_bolo_transmis_une_periode	4

#define		_bolo_est_actif(n_bol)	(_param_d(Dhs,_pd_codeutil, (n_bol))&_bolo_actif)
#define		_bolo_est_inactif(n_bol)	(!_bolo_est_actif(n_bol))

#define  __bolo_inactif		0					//=====================    en  mode  kid   le type    ==========
#define	 __kid_null			0
#define  __kid_pixel		1
#define  __kid_off			2
#define  __kid_masque		3



//#define	_kid_actif(n_bol)		(_type_det(Dhs,n_bol)!=__bolo_inactif)
#define	_kid_pixel(n_bol)		(_type_det(Dhs,  (n_bol))==__kid_pixel)
#define	_kid_off(n_bol)			( (_type_det(Dhs,(n_bol))==__kid_off) || (_type_det(Dhs, (n_bol))==__kid_masque) )
#define	_kid_null(n_bol)		(_type_det(Dhs,  (n_bol))==__bolo_inactif)

#define _kid_couleur(n_kid)		(  _kid_pixel(n_kid) ? _rouge : _vert )	


// ---------------------------------   type  des bolos ----------------------------------------------
//  ----  je mets maintenant cette valeur dans le champ  bolo_acq  et je libere le champ type pour mettre l'ancien codeutil

//  ---  le type contient le type<<4  suivit d'un nombre de 0 a 15			*
//  on peu tester   le (type&0x30)  pour avoir  les 4 types			
//  tester le (type&0x10) permet de savoir si c'est multiplexe			
//  tester le (type&0x20) permet de savoir si c'est une BEBO		

#define _type_MLPA			0x00
#define _type_MLPA16bit		0x01
#define _type_MUPA			0x10		// obsolete 
#define _type_BEDIFF		0x20		// programme en bedif si le type ==  _type_BEDIFF
#define _type_BEMUX			0x30


#define	_pas_un_MUX(type)		((type & 0x10)==0)
#define	_est_un_MUX(type)		 (type & 0x10)
#define	_est_un_MUX_gene(type)	((type & 0x1f)  == 0x10 )
#define	_est_un_MUX_bolo(type)	((type & 0x10) && (type&0xf) )
#define	_est_une_BEDIF(type)	( type & _type_BEDIFF)
#define	_est_une_BEMUX(type)	( type & _type_BEMUX)
#define	_est_une_BEBO(type)		( type & 0x20)


#define	__est_une_MLPA(n_bol)		((_type_det(Dhs, (n_bol)) & 0x10)==0)
#define	__pas_un_MUX(n_bol)			((_type_det(Dhs, (n_bol)) & 0x10)==0)
#define	__est_un_MUX(n_bol)			 (_type_det(Dhs, (n_bol)) & 0x10)
#define	__est_un_MUX_gene(Gp,n_bol)	((_type_det(Dhs, (n_bol)) & 0x1f)  == 0x10 )
#define	__est_un_MUX_bolo(Gp,n_bol)	((_type_det(Dhs, (n_bol)) & 0x10) && (_type_det(Dhs,n_bol)&0xf) )
#define	__est_une_BEBO(n_bol)		 (_type_det(Dhs, (n_bol)) & 0x20)


//================================================================================================================================
//===================				les definitions du reglage  horloge  (boite opera)   		==================================
//================================================================================================================================
//  ces define s'appliquent a  une element  reg_horloge =  _reglage(Dhs,_r_opera,0)  ou   RG_opera
// Je deplace  _nb_canaux_mesure , mode_mlpa   et  _nb_mux dans les parametres
// je les nommes  "opera_canaux" , "opera_mlpa" et  "opera_nb_mux"

//#define		_mode_mlpa(reg_horloge)			((int)(((reg_horloge)[0]&0x80000000l)>>31))		// 1 bit	// dans les param
#define	_mode_mlpa(dhs)  (_presence_param_c(dhs,_p_opera_mlpa)? _param_c(dhs,_p_opera_mlpa):0)
#define		_synchro_kid(reg_horloge)		((int)(((reg_horloge)[0]&0x40000000l)>>30))		// 1 bit		// permet de retrouver le mode kid ou bolo dans le reglage
//#define		_nb_canaux_mesure(reg_horloge)	((int)(((reg_horloge)[0]&0x3f000000l)>>24))		// 6 bit	// dans les param
#define	_nb_canaux_mesure(dhs)  (_presence_param_c(dhs,_p_opera_canaux)? _param_c(dhs,_p_opera_canaux):2)
//#define		_nb_mux(reg_horloge)			((int)(((reg_horloge)[0]&0x00f00000l)>>20))		// 4 bit	// dans les param
#define	_nb_mux(dhs)  (_presence_param_c(dhs,_p_opera_nb_mux)? _param_c(dhs,_p_opera_nb_mux):0)

#define		_nb_mes_ph(reg_horloge)			((int)( ((reg_horloge)[0]&0x000ffc00l)>>10))		// 10bit
#define		_flag_bediff(reg_horloge)		((int)( ((reg_horloge)[0]&0x00000300l)>>8))		// 2 bit
#define		_nb_phase(reg_horloge)			((int)( ((reg_horloge)[0]&0x000000f0l)>>4))		// 4 bit
#define		_temp_mort(reg_horloge)			((int)  ((reg_horloge)[0]&0x0000000fl))			// 4 bit
#define		_dur_ref(reg_horloge)			((int)  ((reg_horloge)[1]&0x000000ffl))			// 8 bit		// sert aussi en mode kid a indiquer le numero du maxc qui fait la pll

#define		_dur_ref_reglage(reg_horloge)   ((int)  ((reg_horloge)[1]&0x000000ffl))			// 8 bit		// sert aussi en mode kid a indiquer le numero du maxc qui fait la pll
#define		_mac_pll_reglage(reg_horloge)   ((int)  ((reg_horloge)[1]&0x000000ffl))			// 8 bit		// sert aussi en mode kid a indiquer le numero du maxc qui fait la pll
#define		_freq_reglage(reg_horloge)		((int4)(((reg_horloge)[1]&0xffffff00l)>>8))		// 24 bit

#define	 _bitmot						24			/* nb de bit horloge dans un mot ADC				*/
#define _pas_freq_horloge				0.298023224				// pas d'increment de la frequence par le registre x (20mega/2^26)

#define _periode_horloge(reg_horloge)			(1000000./(_pas_freq_horloge*(double)_freq_reglage(reg_horloge)))		/* periode en microsec */
#define _echantillonnage_adc(reg_horloge)		((double)_bitmot/(_pas_freq_horloge*(double)_freq_reglage(reg_horloge)) )				/* en sec */
#define _echantillonnage_mux(reg_horloge)			((_echantillonnage_adc(reg_horloge))*(double)(_nb_mes_per(Dhs)))			/* temps total pour une mesure mux complete (tous bolos) en sec */
#define _temps_mesure_mux(reg_horloge)				((_echantillonnage_adc(reg_horloge))*(double)(_nb_mes_ph(reg_horloge) -  _dur_ref_reglage(reg_horloge)))					/* duree de la mesure d'un bolo mux en sec */
#define _temps_integration_mux(reg_horloge)			(_echantillonnage_mux(reg_horloge)-_temps_mesure_mux(reg_horloge))				/* integration d'un bolo entre 2 mesures  en sec */

#define _frequence_modulation_bolo(reg_horloge)		(1./_echantillonnage_mux(reg_horloge))						// en Hz
#define _frequence_echantillonage_opera(reg_horloge)	(1./_echantillonnage_adc(reg_horloge)/1000.)					// en kHz
#define _frequence_horloge_opera(reg_horloge)	(_pas_freq_horloge*(double)_freq_reglage(reg_horloge)/1000.)	// en kHz



//#define		_nb_mes_per(reg_horloge)		((int)_nb_mes_ph(reg_horloge)*(int)_nb_phase(reg_horloge))
#define		_nb_mes_per(dhs)				 (_presence_param_c(dhs,_p_opera_mes_per)? _param_c(dhs,_p_opera_mes_per):80)
//#define		_nb_mes_per(reg_horloge)				(80)

#define		_nb_coups_MLPA(dhs,reg_horloge)		((_nb_mes_per(dhs)/2) - _temp_mort(reg_horloge))

#define		_nb_coups_mux_general(reg_horloge)	((_dur_ref(reg_horloge)-_temp_mort(reg_horloge)-1) * _nb_phase(reg_horloge))
#define		_nb_coups_mux_bolo(reg_horloge)		(_nb_mes_ph(reg_horloge) - _dur_ref(reg_horloge) - _temp_mort(reg_horloge))


#define _avec_coax_synchro	0
#define _freq_stable		(_avec_coax_synchro? 1572864 : ((int) (23.842 * 40. * (double)_bitmot  /_pas_freq_horloge)))
#define _freq_derive_vite	(_freq_stable - _freq_stable/50)
#define _freq_derive_lent	(_freq_stable - _freq_stable/200)


//================================================================================================================================
//===================				les definitions du reglage rg1 et rg2 pour les bolos		==================================
//================================================================================================================================

// les definitions suvantes s'appliquent a un numero de bolo  n_bol  et necessite les glbals  RG1_opera et RG2_opera
#define		_gainbrut(dhs,n_bol)			((int)((RG1_opera[n_bol]&0x1f)))
#define		_phase_bolo(n_bol)		((int)((RG1_opera[n_bol]&0x60)>>5))
#define		_comm(n_bol)				((int)((RG1_opera[n_bol]&0x80)>>7))
#define		_dac_V(dhs,n_bol)			((int)((RG1_opera[n_bol]&0x000fff00l)>>8)	)
#define		_dac_I(dhs,n_bol)			((int)((RG1_opera[n_bol]&0xfff00000l)>>20))
#define		_dac_T(n_bol)			((int)((RG2_opera[n_bol]&0x000fff00l)>>8))
#define		_dac_L(n_bol)			((int)((RG2_opera[n_bol]&0xfff00000l)>>20))
//==================  Je remplace la voie par un code equi (8 bit) dont le bit zero indique s'il faut faire un equilibrage continu dans opera
#define		_equi(n_bol)		((int)((RG2_opera[n_bol] & 0xff )))

#define		_rgl_bolo_mot1(dacV,dacI,gainbrut,phase,comm)	(((uint4)(gainbrut))&0x1f) | ((((uint4)(phase))&3)<<5) | ((((uint4)(comm))&1)<<7) | ((((uint4)(dacV))&0xfff)<<8) | ((((uint4)(dacI))&0xfff)<<20) 
#define		_rgl_bolo_mot2(dacT,dacL,equi)					(((uint4)(equi))&0xff) 	  | ((((uint4)(dacT))&0xfff)<<8) | ((((uint4)(dacL))&0xfff)<<20)


//---  les gains sont ici car ils sont utilise par e_dUser et aussi par fabloc pour les corrections d'equilibrage  ---------------		
/* gains 0 .. 15 pour MLPA  ///   gain 16..19  pour BEBO   ///   gain 20..22  pour BEDIF   //   gain  23..27  pour beplanck	*/		
#define _gain_mlpa		0
#define _gain_bebo		16
#define _gain_bedif 	20
#define _gain_bemux		20
#define _gain_beplanck	23

#define	def_gains	double gains_reels[32]={1,2,4,8,10,20,40,80,100,200,400,800,1000,2000,4000,8000, \
											0.5,2.5,10,50, \
											0.93,3.777,18.974, \
											0,1,5,20,100};

		/*			gain bediff    10->9.3    40->37.77     200->189.74		*/
#define	bol_micro_volt_2(dhs,val,n_bol)	(bol_micro_volt((val),(double)_param_d((dhs),_pd_gain,n_bol)*gain_ampli((dhs),n_bol)))
#define	bol_micro_volt(val,gain_total)			((val==undef_double)?(undef_double):((1e7*(double)val)/(65536.*(gain_total))))
//#define bol_micro_volt_mux(val,n_bol,par,regl)	(bol_micro_volt(val,(double)(par).bolo[n_bol][_bolo_gain]))
#define	gain_ampli(dhs,n_bol)						gains_reels[_gainbrut((dhs),n_bol)]	/*  gainbrut  ne peut depasser 31  (&1f)   */

//---------------------    pour l'equilibrage automatique    --------------------------------------------

/*
#define		_cmd_equi(voie)		((_reglage(Dhs,_r_o_equi,0)[voie]&0x0000000f))
#define		_mode_equi(voie)	((_reglage(Dhs,_r_o_equi,0)[voie]&0x000000f0)>>4)
#define		_gain_equi(voie)	((_reglage(Dhs,_r_o_equi,0)[voie]&0x0000ff00)>>8)
#define		_courant_equi(voie)	((_reglage(Dhs,_r_o_equi,0)[voie]&0x00ff0000)>>16)
#define		_delai_equi(voie)	((_reglage(Dhs,_r_o_equi,0)[voie]&0xff000000)>>24)

#define		_cmd_equi_st		((st->ma_commande&0x0000000f))
#define		_mode_equi_st		((st->ma_commande&0x000000f0)>>4)
#define		_gain_equi_st		((st->ma_commande&0x0000ff00)>>8)
#define		_courant_equi_st	((st->ma_commande&0x00ff0000)>>16)
#define		_delai_equi_st		((st->ma_commande&0xff000000)>>24)
*/

enum{_cmd_equi_inactif,_cmd_equi_equilibrage,_cmd_equi_chg_mode,_cmd_equi_chg_gain,_cmd_equi_chg_courant,_cmd_equi_chg_delai};					/* code de commande pour change un parametre d'equilibrage : */
enum{_mode_equi_rien,_mode_equi_1fois,_mode_equi_auto,_mode_equi_continu,_mode_equi_transitoire,_mode_equi_total,_nb_mode_equi};		/* mode d'equilibrage : valeur de  mode_equi	*/
#define		_fabrique_code_equi(cmd_equi,mode_equi,gain_equi,courant_equi,delai_equi) (((int4)((int)cmd_equi&0xf))+(((int4)((int)mode_equi&0xf))<<4)+(((int4)((int)gain_equi&0xff))<<8)+(((int4)((int)courant_equi&0xff))<<16)+(((int4)((int)delai_equi&0xff))<<24))



//================================================================================================================================
//===================		les definitions du reglage rg1 et rg2 pour le multilexeur Bemux			==============================
//================================================================================================================================


#define		_gain_mux(n_bol)			((int)((RG1_opera[n_bol] & 0x0000000f )))					/*  4 bit */
#define		_capa_mux(n_bol)			((int)((RG1_opera[n_bol] & 0x0000fff0 )>>4))				/*  12 bit */
//#define		_ref_mux(n_bol)		(-2048+(int)((RG1_opera[n_bol] & 0xffff0000 )>>16))			/*  16 bit */
#define		_ref_mux(n_bol)			(2048-(int)((RG1_opera[n_bol] & 0xffff0000 )>>16))			/*  16 bit */
#define		_ref_mux_en_V(n_bol)		(_ref_mux(n_bol) * 0.01/2048)
#define		_voie_mux(n_bol)			((int)((RG2_opera[n_bol]&0xff)))					/* 8 bit  */
#define		_decale_mux(n_bol)		((int)((RG2_opera[n_bol] & 0x00000700)>>8))					/*  3 bit */
#define		_retard_mux(n_bol)		((int)((RG2_opera[n_bol] & 0x0000f800)>>11))				/*  5 bit */
#define		_Q_mux(n_bol)			((int)(char)((RG2_opera[n_bol] & 0x00ff0000)>>16))				/*  8 bit signe */
#define		_I_mux(n_bol)			((int)(char)((RG2_opera[n_bol] & 0xff000000)>>24))				/*  8 bit signe */

//#define		_rgl_mux_mot1(gain,capa,ref)	(((uint4)(gain))&0x0f) | ((((uint4)(capa))&0xfff)<<4) | ((((uint4)(ref+2048))&0xffff)<<16) 
#define		_rgl_mux_mot1(gain,capa,ref)	(((uint4)(gain))&0x0f) | ((((uint4)(capa))&0xfff)<<4) | ((((uint4)(2048-ref))&0xffff)<<16) 
#define		_rgl_mux_mot2(voie,decale,retard,Q,I)	(((uint4)(voie))&0xff) 	 |  ((((uint4)(decale))&0x07)<<8) | ((((uint4)(retard))&0x1f)<<11)	 |  ((((uint4)(Q))&0xff)<<16) | ((((uint4)(I))&0xff)<<24)


//================================================================================================================================
//===================							les definitions pour les kid						==============================
//================================================================================================================================

//-----  dans le param --------

#define _maxi_bin_num(dhs,z)			(_presence_param_b(dhs,_pb_max_bin,z)? _param_b(dhs,_pb_max_bin,z):131000)
#define _diviseur_kid(dhs)				(_presence_param_c(dhs,_p_div_kid)? _param_c(dhs,_p_div_kid):80)


#define	_kid_frequence(dhs,n_bol)		(_presence_param_d(dhs,_pd_frequency)? (0.01 * (double)_param_d(dhs,_pd_frequency,n_bol)):			\
			(_presence_param_d(dhs,_pd_res_frq)? (0.01 * (double)_param_d(dhs,_pd_res_frq,n_bol)) : 0 ))// en KHz	(elle est en unite de 10Hz dans le param)
#define _largeur_resonnance(dhs,n_bol)	(_presence_param_d(dhs,_pd_width)? (0.001*(double)_param_d(dhs,_pd_width,n_bol)):	\
			(_presence_param_d(dhs,_pd_res_lg)? (0.001*(double)_param_d(dhs,_pd_res_lg,n_bol)):0.))	// en kHz car on a des entiers en Hz
#define _flag_du_paramd(dhs,n_bol)		(_presence_param_d(dhs,_pd_flag)? _param_d(dhs,_pd_flag,n_bol):0)



#define _ecrit_largeur_resonnance(dhs,ndet,largeur) _param_d(dhs,_pd_width,ndet) = (int)(largeur*1000.);
#define _ecrit_flag_resonnance(dhs,ndet,flag)      _param_d(dhs,_pd_flag,ndet) = flag;





//-----   chaque code reglage en fonction des parametres   --------------------

//  la freq_par_bin est un double en KHz  et le pas est un entier de 0 a 16 codant : 
	//			int pas = 5;  // 5 -> *5    6 -> *10    7 -> *20
// je remplace le mac_auto obsolete par le type_balayage : sert pour passer en mode_regulier
#define _code_kid_balayage1(freq_par_bin,pas)									((((int)(100000.*freq_par_bin))&0xffffff) | ((((int)(pas))<<24)&0x0f000000) )
#define	_code_kid_balayage2(nb_pas,temps_mort,duree,action,type_balayage)			((((int)(nb_pas))&0x0fff)  | ((((int)(temps_mort))<<12)&0x0000f000)  | ((((int)(duree))<<16)&0x00ff0000) | ((((int)(action))<<24)&0x03000000)  | ((((unsigned int)(type_balayage))<<26)&0x3c000000) )
#define	send_kid_balayage_mot1(z,freq_par_bin,pas)								commande_synthe_enum(Dhs,z ,_kid_balayage1,_code_kid_balayage1(freq_par_bin,pas))
#define	send_kid_balayage_mot2(z,nb_pas,temps_mort,duree,action,type_balayage)		commande_synthe_enum(Dhs,z ,_kid_balayage2,_code_kid_balayage2(nb_pas,temps_mort,duree,action,type_balayage))

//------   retrouver les parametres a partir du reglage  kid_X = _reglage_box(dhs,_r_nikel,z);


#define _regl_ampl_mod(kid_X)                       ((kid_X[_kid_f_modul]>>16)&0xff)		// pour relire les anciens fichiers run 5 et 6 en kHz de 1 a 250 kHz
#define	kid_balayage_freq_baseX(kid_X)				(0.01*(double)kid_X[_kid_f_base])				// en kHz		(elle est en unite de 10Hz dans le reglage)
//#define	kid_balayage_freq_par_binX_brut(kid_X)		(0.00001*(double)(kid_X[_kid_balayage1]&0xffffff))	// en kHz		(elle est en 1/100 Hz dans le reglage)
#define	kid_balayage_freq_par_binX_brut(kid_X)		(0.953674)	// en kHz		
#define	kid_balayage_freq_par_binX(kid_X)			(kid_balayage_freq_par_binX_brut(kid_X)>0.5?kid_balayage_freq_par_binX_brut(kid_X):0.5)

#define	kid_balayage_pas(kid_X)			(int)((kid_X[_kid_balayage1]>>24)&0xf)				// codage pas en fonction du bin (indice dans _pas_synthe)
//#define	kid_balayage_code_synthe(kid_X)	(int)((kid_X[_kid_balayage1]>>28)&0xf)			// code synthe inutilise
#define	kid_balayage_val_pas(kid_X)		(((kid_balayage_pas(kid_X)>=0)&&(kid_balayage_pas(kid_X)<_nb_pas_synthe_possibles))?_pas_synthe[kid_balayage_pas(kid_X)]:1)		// pas du balayage en bin (double)

#define	kid_balayage_nb_pas(kid_X)		(int)(kid_X[_kid_balayage2]&0xfff)				// nombre de pas en frequence par demi-scan
#define	kid_balayage_temps_mort(kid_X)	(int)(kid_X[_kid_balayage2]>>12&0xf)				// duree du temps mort, en nb de mesures
#define	kid_balayage_duree(kid_X)		(int)((kid_X[_kid_balayage2]>>16)&0xff)			// duree de chaque pas (en nb de mesures)
#define	kid_balayage_action(kid_X)		(int)((kid_X[_kid_balayage2]>>24)&0x3)			// action de balayage sur 2 bit
//#define	kid_balayage_mac_auto(kid_X)	(int)((kid_X[_kid_balayage2]>>26)&0xf)			// obsolete : remplace par tuning_ip dans le param
#define	kid_balayage_mode_mesure(kid_X)	(int)((kid_X[_kid_balayage2]>>26)&0xf)			// a la place de l'ancien mac_auto

enum {_arret_balayage,_demarre_balayage,_balayage_en_cours};
#define fixe_action_balayage(kid_X,action)	kid_X[_kid_balayage2] = (kid_X[_kid_balayage2] & 0x1cffffff ) | ((((int)(action))<<24)&0x03000000)


#define _echantillonnage_kid(kid_X)				(1/(kid_balayage_freq_par_binX(kid_X)*1000./(double)_diviseur_kid(Dhs)) )			// ce sont des secondes
#define _echantillonnage_nano_kid(dhs,kid_X)		(_diviseur_kid(dhs) * 1000000/ kid_balayage_freq_par_binX(kid_X) )			// ce sont des nano secondes car  freq_par_bin est en Khz


#define _nb_pas_synthe_possibles	13
#define _def_pas_synthe	double _pas_synthe[_nb_pas_synthe_possibles]={0.1,0.2,0.5,1,2,5,10,20,50,100,200,500,1000};

//--- ce flag provient de la carte nikel et apparait dans les data par boite :    A_masq  B_masq  ...
//--- il n' pas change depuis les run 5 et 6

#define		_flag_balayage_en_cours				0x01		// flag ecrit lors du balayage du synthe
#define		_flag_blanking_synthe				0x02		// flag ecrit lors du balayage du synthe
#define		_flag_fpga_change_frequence			0x04		// indique le chargement des tones

//---  les flag suivants apparaissent dans le param pour chaque detecteur :  "flag"

#define		_flag_mauvais_tuning				0x20		// fixe par le prg  calcul_tuning_2
#define		_flag_resonnance_mal_placee			0x40        // les resonnances qui devient par rapport a leur place dans le param
#define		_flag_resonnance_perdue				0x80		// utilise par "retrouve resonnances

//---  enfin tous les flags apparaissent dans les data  "k_flag" de chaque detecteur 

// le parametre  mac_auto  contient le dernier chiffre du ip du mac charge de gerer le tunning auto)

//---------------------------------  lecture des donnees kid dans les brut et transformations vers data

#define _angle_brut(dhs,br,nper,ndet)  _dangleIQdIdQ(_brut_pdd(dhs,br,_dd_Q,nper)[ndet],_brut_pdd(dhs,br,_dd_dQ,nper)[ndet],_brut_pdd(dhs,br,_dd_I,nper)[ndet],_brut_pdd(dhs,br,_dd_dI,nper)[ndet]))

#define	_brut_to_angle_IQdIdQ(dhs,br,nper,ndet)				(double)(_type_det(dhs,ndet) != __kid_pixel ? 0 : _angle_brut(dhs,br,nper,ndet)
#define	_brut_to_ftone(dhs,br,z,nper,ndet,RG_nikel,tone)    (double)(0.01*_brut_pb(dhs,br,_db_freq,z,nper)    +   kid_balayage_freq_par_binX(RG_nikel) * (double)tone)
//#define	_brut_to_flag(dhs,br,z,nper,ndet)					(int) ((_brut_pb(dhs,br,_db_masq,z,nper)&0x0f)	|  (_flag_du_paramd(dhs,ndet)&0xf0) )

#define _flag_du_reglage(RG_w,nkid)						(RG_w[nkid]&0xf0)
#define _width_du_reglage(RG_w,nkid)					((RG_w[nkid]&0x8fffff00)>>8)



#define _phase_en_rad			0.001					// pour que la phase soit en radian (nouvelle version ou la phase brute est en milli-radians)


//================================================================================================================================
//===================				les definitions pour le calcul du pointage matrice				==============================
//================================================================================================================================

// ------  les defines suivants s'applique a une structure de type   &Gp->repere_pointage[z]

#define _centre_matrice_x(etalon)				(0.001*(double)(etalon)->x0)
#define _centre_matrice_y(etalon)				(0.001*(double)(etalon)->y0)
#define _inversion_chc_pixel(etalon)			((etalon)->g>0?1:-1)	// l'effet miroir (ou pas) pour l'identification des pixels d'une matrice
#define _grossissement_uphys_pixel(etalon)		(0.001*(double)( _inversion_chc_pixel(etalon) * (etalon)->g))	// le grossissement en unites physiques (mm, murad,...) par pixel
#define _decalage_rotation(etalon)				(0.000001*(double)(etalon)->alpha)


#define _IRAM_latitude						(37.065941*pi/180.)


// position des detecteurs dans le param
#define	_Xpix(dhs,n_bol)				((double)_param_d((dhs),_pd_X,n_bol)/1000.)		// en pixels
#define	_Ypix(dhs,n_bol)				((double)_param_d((dhs),_pd_Y,n_bol)/1000.)		// en pixels



//===================================   les conversions d'unite pour passer du pointage elvin et brut en entier,  data en double  =================================
#define _d2ra(a)	(0.000001*(double)a*pi/180.)	 					// ce sont des mircrodegres convertis en radians
#define _r2ra(a)	(0.000001 * (double) a )							// ce sont des mircroradians convertis en radians
#define _r2mr(a)	( (180.*3600.) / (pi * 1e6) *  (double) a )			// je passe en seconde d'arc  pour les ofsets x et y 


//#define _trace_carte_ok(dhs)			( 1 )


//================================================================================================================================
//===================			les definitions pour les synchro et le mpi  						==============================
//================================================================================================================================

#define	_c_lum	300000.0	// la vitesse de la lumiere dans le vide

// -------------------   les differentes synchros  -----------------
// - de 0 a 8 (inclus) : synchros physiques, liees a des signaux electriques     - de 9 a 15 (inclus) : synchros logicielles, definies dans Camadia
enum {_sync_roue,_sync_bras_av,_sync_bras_arr,_sync_butee_av,_sync_butee_arr,_sync_avance,_sync_recule,_sync_7,_sync_8,_sync_9,_sync_fichier,_sync_mpi,_sync_pointage,_sync_calage_kids,_sync_scans,_sync_subscans,_sync_16,_nb_synchros};
#define _def_noms_sychros	char noms_synchros[32][_nb_synchros]={"Roue","Bras en avant","Bras arriere","Butee avant","Butee arreire","Avance","Recule","Sy 7","Sy 8","Sy 9","Fichier","MPI","Pointage","Calage KIDs","Scans","Subscans","Sy 16"};


#define		_synchro_n(Dd,i,sy)			( (((int)_data_pc(Dhs,Dd,_d_synchro_flag,i))>>sy) & 1 )


#define		_code_centre_bras	53500
#define _pas_mmm_bras_puplett	0.0025			// le pas en mmm pour un pas moteur		pour le calcul de cUser[_bras_mpi] en mm autour du centre 
#define  _position_mpi(x)       (_pas_mmm_bras_puplett * (double)((x)-_code_centre_bras))


#endif	//  #ifndef __A_DEF__

