#ifndef __DEF_OPERA__
#define __DEF_OPERA__

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
//  ces define s'appliquent a  une element  reg_horloge =  reglage_pointer(Dhs,_r_opera,-1)  ou   RG_opera
// Je deplace  _nb_canaux_mesure , mode_mlpa   et  _nb_mux dans les parametres
// je les nommes  "opera_canaux" , "opera_mlpa" et  "opera_nb_mux"

//#define		_mode_mlpa(dhs)			(_presence_param_c(dhs,_p_opera_mlpa)? _param_c(dhs,_p_opera_mlpa):0)
//#define		_nb_canaux_mesure(dhs)  (_presence_param_c(dhs,_p_opera_canaux)? _param_c(dhs,_p_opera_canaux):2)
//#define		_nb_mux(dhs)			(_presence_param_c(dhs,_p_opera_nb_mux)? _param_c(dhs,_p_opera_nb_mux):0)
#define	_mode_mlpa(dhs)		0
#define	_nb_mux(dhs)		0

//#define		_nb_mes_per(dhs)		(_presence_param_c(dhs,_p_opera_mes_per)? _param_c(dhs,_p_opera_mes_per):256)
//#define		_nb_phase(reg_horloge)	(2)
//#define		_nb_mes_ph(dhs)	(_nb_mes_per(dhs)/2)

#define	_nb_mes_per_dhs(dhs)	 ( reglage_pointer(dhs,_r_opera,-1) ? _nb_mes_per(reglage_pointer(dhs,_r_opera,-1)) : 0 )
#define	_nb_mes_per(reg_horloge) ((int)_nb_mes_ph(reg_horloge)*(int)_nb_phase(reg_horloge))
#define	_nb_canaux_mesure(dhs)	 ( reglage_pointer(dhs,_r_opera,-1) ? _nb_canaux_mesure_RG(reglage_pointer(dhs,_r_opera,-1)) : 3 )		// 6 bit	// dans les param


#define	_synchro_kid(reg_horloge)		((int)(((reg_horloge)[0]&0x40000000l)>>30))		// 1 bit		// permet de retrouver le mode kid ou bolo dans le reglage
//#define	_mode_mlpa(reg_horloge)			((int)(((reg_horloge)[0]&0x80000000l)>>31))		// 1 bit	// dans les param
#define	_nb_canaux_mesure_RG(reg_horloge)	((int)(((reg_horloge)[0]&0x3f000000l)>>24))		// 6 bit	// dans les param
//#define	_nb_mux(reg_horloge)			((int)(((reg_horloge)[0]&0x00f00000l)>>20))		// 4 bit	// dans les param
#define	_nb_mes_ph(reg_horloge)			((int)( ((reg_horloge)[0]&0x000ffc00l)>>10))		// 10bit
#define	_nb_phase(reg_horloge)			((int)( ((reg_horloge)[0]&0x000000f0l)>>4))		// 4 bit
#define	_flag_bediff(reg_horloge)		((int)( ((reg_horloge)[0]&0x00000300l)>>8))		// 2 bit
#define	_temp_mort(reg_horloge)			((int)  ((reg_horloge)[0]&0x0000000fl))			// 4 bit
#define	_dur_ref(reg_horloge)			((int)  ((reg_horloge)[1]&0x000000ffl))			// 8 bit		// sert aussi en mode kid a indiquer le numero du maxc qui fait la pll

#define	_dur_ref_reglage(reg_horloge)   ((int)  ((reg_horloge)[1]&0x000000ffl))			// 8 bit		// sert aussi en mode kid a indiquer le numero du maxc qui fait la pll
#define	_mac_pll_reglage(reg_horloge)   ((int)  ((reg_horloge)[1]&0x000000ffl))			// 8 bit		// sert aussi en mode kid a indiquer le numero du maxc qui fait la pll
#define	_freq_reglage(reg_horloge)		((int4)(((reg_horloge)[1]&0xffffff00l)>>8))		// 24 bit

#define _horloge_opera0_defaut  _horloge_opera0(0,0,2,0,40,0,2,6)	
#define _horloge_opera0(mode_mlpa,synchro_kid,nb_canaux_mesure,nb_mux,nb_mes_par_phase,flag,nb_phase,tmort)		\
	(((uint4)mode_mlpa<<31)  |  ((uint4)synchro_kid<<30)  |   ((uint4)nb_canaux_mesure<<24)  |  ((uint4)nb_mux<<20)  |  ((uint4)nb_mes_par_phase<<10)|  ((uint4)flag<<8) |  ((uint4)nb_phase<<4) |  ((uint4)tmort))
#define _horloge_opera1(freq,macpll)		((freq<<8 ) | (macpll))


#define	_bitmot						24			/* nb de bit horloge dans un mot ADC				*/
#define _pas_freq_horloge				0.298023224				// pas d'increment de la frequence par le registre x (20mega/2^26)

#define _periode_horloge(reg_horloge)		(1000000./(_pas_freq_horloge*(double)_freq_reglage(reg_horloge)))		/* periode en microsec */
#define _echantillonnage_adc(reg_horloge)	((double)_bitmot/(_pas_freq_horloge*(double)_freq_reglage(reg_horloge)) )				/* en sec */
#define _echantillonnage_mux(reg_horloge)	((_echantillonnage_adc(reg_horloge))*(double)(_nb_mes_per(reg_horloge)))			/* temps total pour une mesure mux complete (tous bolos) en sec */
#define _temps_mesure_mux(reg_horloge)		((_echantillonnage_adc(reg_horloge))*(double)(_nb_mes_ph(reg_horloge) -  _dur_ref_reglage(reg_horloge)))					/* duree de la mesure d'un bolo mux en sec */
#define _temps_integration_mux(reg_horloge)	(_echantillonnage_mux(reg_horloge)-_temps_mesure_mux(reg_horloge))				/* integration d'un bolo entre 2 mesures  en sec */

#define _frequence_modulation_bolo(reg_horloge)		(1./_echantillonnage_mux(reg_horloge))						// en Hz
#define _frequence_echantillonage_opera(reg_horloge)(1./_echantillonnage_adc(reg_horloge)/1000.)					// en kHz
#define _frequence_horloge_opera(reg_horloge)		(_pas_freq_horloge*(double)_freq_reglage(reg_horloge)/1000.)	// en kHz

#define _echantillonnage_bolo(reg_horloge)			((_echantillonnage_adc(reg_horloge))*(double)(_nb_mes_per(reg_horloge))/2)		/* temps total pour une demi periode de mesure en sec */


#define		_nb_coups_MLPA(reg_horloge)			((_nb_mes_per(reg_horloge)/2) - _temp_mort(reg_horloge))

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
#define		_gainbrut(dhs,n_bol)	((int)((RG1_opera[n_bol]&0x1f)))
#define		_phase_bolo(n_bol)		((int)((RG1_opera[n_bol]&0x60)>>5))
#define		_comm(n_bol)			((int)((RG1_opera[n_bol]&0x80)>>7))
#define		_dac_V(dhs,n_bol)		((int)((RG1_opera[n_bol]&0x000fff00l)>>8)	)
#define		_dac_I(dhs,n_bol)		((int)((RG1_opera[n_bol]&0xfff00000l)>>20))
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
#define	bol_micro_volt(val,gain_total)	((val==undef_double)?(undef_double):((1e7*(double)val)/(65536.*(gain_total))))
//#define bol_micro_volt_mux(val,n_bol,par,regl)	(bol_micro_volt(val,(double)(par).bolo[n_bol][_bolo_gain]))
#define	gain_ampli(dhs,n_bol)			gains_reels[_gainbrut((dhs),n_bol)]	/*  gainbrut  ne peut depasser 31  (&1f)   */

//---------------------    pour l'equilibrage automatique    --------------------------------------------

/*
#define		_cmd_equi(voie)		((reglage_pointer(Dhs,_r_o_equi,0)[voie]&0x0000000f))
#define		_mode_equi(voie)	((reglage_pointer(Dhs,_r_o_equi,0)[voie]&0x000000f0)>>4)
#define		_gain_equi(voie)	((reglage_pointer(Dhs,_r_o_equi,0)[voie]&0x0000ff00)>>8)
#define		_courant_equi(voie)	((reglage_pointer(Dhs,_r_o_equi,0)[voie]&0x00ff0000)>>16)
#define		_delai_equi(voie)	((reglage_pointer(Dhs,_r_o_equi,0)[voie]&0xff000000)>>24)

#define		_cmd_equi_st		((st->ma_commande&0x0000000f))
#define		_mode_equi_st		((st->ma_commande&0x000000f0)>>4)
#define		_gain_equi_st		((st->ma_commande&0x0000ff00)>>8)
#define		_courant_equi_st	((st->ma_commande&0x00ff0000)>>16)
#define		_delai_equi_st		((st->ma_commande&0xff000000)>>24)
*/

enum {_cmd_equi_inactif,_cmd_equi_equilibrage,_cmd_equi_chg_mode,_cmd_equi_chg_gain,_cmd_equi_chg_courant,_cmd_equi_chg_delai};					/* code de commande pour change un parametre d'equilibrage : */
enum {_mode_equi_rien,_mode_equi_1fois,_mode_equi_auto,_mode_equi_continu,_mode_equi_transitoire,_mode_equi_total,_nb_mode_equi};		/* mode d'equilibrage : valeur de  mode_equi	*/
#define		_fabrique_code_equi(cmd_equi,mode_equi,gain_equi,courant_equi,delai_equi) (((int4)((int)cmd_equi&0xf))+(((int4)((int)mode_equi&0xf))<<4)+(((int4)((int)gain_equi&0xff))<<8)+(((int4)((int)courant_equi&0xff))<<16)+(((int4)((int)delai_equi&0xff))<<24))



//================================================================================================================================
//===================		les definitions du reglage rg1 et rg2 pour le multilexeur Bemux			==============================
//================================================================================================================================


#define	_gain_mux(n_bol)	((int)((RG1_opera[n_bol] & 0x0000000f )))					/*  4 bit */
#define	_capa_mux(n_bol)	((int)((RG1_opera[n_bol] & 0x0000fff0 )>>4))				/*  12 bit */
//#define	_ref_mux(n_bol)	(-2048+(int)((RG1_opera[n_bol] & 0xffff0000 )>>16))			/*  16 bit */
#define	_ref_mux(n_bol)		(2048-(int)((RG1_opera[n_bol] & 0xffff0000 )>>16))			/*  16 bit */
#define	_ref_mux_en_V(n_bol)(_ref_mux(n_bol) * 0.01/2048)
#define	_voie_mux(n_bol)	((int)((RG2_opera[n_bol]&0xff)))					/* 8 bit  */
#define	_decale_mux(n_bol)	((int)((RG2_opera[n_bol] & 0x00000700)>>8))					/*  3 bit */
#define	_retard_mux(n_bol)	((int)((RG2_opera[n_bol] & 0x0000f800)>>11))				/*  5 bit */
#define	_Q_mux(n_bol)		((int)(char)((RG2_opera[n_bol] & 0x00ff0000)>>16))				/*  8 bit signe */
#define	_I_mux(n_bol)		((int)(char)((RG2_opera[n_bol] & 0xff000000)>>24))				/*  8 bit signe */

//#define		_rgl_mux_mot1(gain,capa,ref)	(((uint4)(gain))&0x0f) | ((((uint4)(capa))&0xfff)<<4) | ((((uint4)(ref+2048))&0xffff)<<16)
#define	_rgl_mux_mot1(gain,capa,ref)	(((uint4)(gain))&0x0f) | ((((uint4)(capa))&0xfff)<<4) | ((((uint4)(2048-ref))&0xffff)<<16)
#define	_rgl_mux_mot2(voie,decale,retard,Q,I)	(((uint4)(voie))&0xff) 	 |  ((((uint4)(decale))&0x07)<<8) | ((((uint4)(retard))&0x1f)<<11)	 |  ((((uint4)(Q))&0xff)<<16) | ((((uint4)(I))&0xff)<<24)


//================================================================================================================================
//===================			les definitions pour les synchro et le mpi  						==============================
//================================================================================================================================

#define	_c_lum	300000.0	// la vitesse de la lumiere dans le vide

// -------------------   les differentes synchros   (_nb_synchros=16)  -----------------
// - de 0 a 8 (inclus) : synchros physiques, liees a des signaux electriques     - de 9 a 15 (inclus) : synchros logicielles, definies dans Camadia
//enum {_sync_roue,_sync_bras_av,_sync_bras_arr,_sync_butee_av,_sync_butee_arr,_sync_avance,_sync_recule,_sync_7,_sync_8,_sync_9,_sync_fichier,_sync_mpi,_sync_pointage,_sync_calage_kids,_sync_scans,_sync_subscans,_sync_16,_nb_synchros};
//#define _def_noms_sychros	char noms_synchros[32][_nb_synchros]={"Roue","Bras en avant","Bras arriere","Butee avant","Butee arreire","Avance","Recule","Sy 7","Sy 8","Sy 9","Fichier","MPI","Pointage","Calage KIDs","Scans","Subscans","Sy 16"};

//----  on a ici le signal synchro ( 0 ou 1 ) correspondant a la synchro sy avec sy=0..15


#define		_code_centre_bras	53500
#define _pas_mmm_bras_puplett	0.0025			// le pas en mmm pour un pas moteur		pour le calcul de cUser[_bras_mpi] en mm autour du centre 
#define  _position_mpi(x)       (_pas_mmm_bras_puplett * ((double)(x)-(double)_code_centre_bras))

//--  nouvel enum pour les signaux synchro qui sortent d'opera : on a 6 bit dispo
enum {_mpi_top_pol,_mpi_pos_av_ar,_mpi_butee_av,_mpi_butee_arr,_mpi_avance,_mpi_recule,_nb_synchros};


#endif	//  #ifndef __DEF_OPERA__

