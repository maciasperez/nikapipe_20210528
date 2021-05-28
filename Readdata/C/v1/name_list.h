#ifndef __NAME_LIST__
#define __NAME_LIST__


//====================    quelques define  par commodite   ======================
//============= a mettre dans les longueur de champs reglage
#define _nb_det -1
//============= a mettre dans les depedances ================
#define _if_synchro -1
#define _if_pointage -2

//===============		mettre ici le nombre maximum de boites instruments utilisees		=========================
#define _nb_max_acqbox	26
#define _nb_max_array	10
#define	_nb_max_bin		4000		// pour les balayages
#define	_nb_max_res		400			// le nombre maxi de resonnances par ligne

//===================================================================================================================
//===================================================================================================================
//==================			DEFINITION   DES   PARAM    POSSIBLES						=========================
//========  on a les param simples, puis tous les param box pour chaque box et enfin les param dtecteurs	=========
//===================================================================================================================
// les param box sont transforme en param simple en les faisant preceder de la lettre de la box
//  dans les possibles, chaque param box apparait autant de fois qu'il y a de boites de mesure possibles
// par contre les param detecteurs n'apparaissent qu'une fois
// pour relire les anciens fichiers, j'ai laisse les parametres  "res_frq","res_niv","res_lg"  qui ne sont plus utilises
// de meme j'ai laisse   "ec_freq","sensib"   qui ne sont pas utilises

//----------------   les param  simples    --------------------------
enum {_p_exp_nom1,_p_exp_nom2,_p_exp_nom3,_p_exp_nom4,\
	  _p_retard_elvin,_p_retard_data,_p_phase_ds,_p_div_kid,_p_mode_acq,_p_auto_tune,_p_fichier,\
	  _p_central1_ip,_p_central2_ip,_p_central3_ip,\
	  _p_code_synthe1,_p_code_synthe2,_p_code_synthe3,\
	  _p_code_horloge1,_p_code_horloge2,_p_code_horloge3,\
	  /* les suivant sont pour relire les vieux fichiers*/
	  _p_ip_tune,
	  _nb_param_simple_possibles
	 };

// je les nommes  "opera_canaux" , "opera_mlpa" et  "opera_nb_mux"

#define _chaines_param_simple	{"nomexp1","nomexp2","nomexp3","nomexp4",\
		"ret_elv","retard","phaseds","div_kid","mode_acq",/*"tuning_ip"*/"auto_tune","fichier",\
		"central1_ip","central2_ip","central3_ip",\
		"code_synthe1","code_synthe2","code_synthe3",\
		"code_horloge1","code_horloge2","code_horloge3",\
		"ip_tune"}

//-------------------------------------------------------------------------------------------------
//----------------     les param box : associes a chaque boite de mesure     ----------------------
//-------------------------------------------------------------------------------------------------
//-----   leur nom sera precede de la lettre indiquant la boite de mesure en majuscule   -----
enum {
// parambox generaux fixe non associe a un reglage
        _pb_enable,_pb_cmd_ip,_pb_cmd_port,_pb_data_ip,_pb_data_port,_pb_eth,_pb_code_horloge, _pb_synthe,_pb_calib,_pb_maxbin,_pb_nb_bande,_pb_tone_bande,_pb_f_bin,
// parambox associes au reglage opera
		_canaux_mes,
// parambox associes au reglage  nikel et amc
		_pb_kid,_pb_f_mod,_pb_f_base,_pb_kid_ba1,_pb_kid_ba2,
		_pb_gain_dac1,_pb_gain_dac2,_pb_gain_dac3,_pb_gain_dac4,_pb_gain_dac5,_pb_att_inj,_pb_att_mes,
// parambox associes au reglage mppsync
		_pb_microstep,_pb_mpp_sensorpol,_pb_mpp_minspeed,_pb_mpp_current,_pb_mpp_Rsense,
        _pb_mpp_retard,_pb_mpp_cnt_clr,_pb_mpp_searchz,_pb_mpp_start_meas_steps,_pb_mpp_pas_tour,_pb_mpp_move_mp,
        _pb_mpp_move_dir,_pb_mpp_vitesse1,_pb_mpp_steps1,_pb_mpp_vitesse2,_pb_mpp_tolerance,_pb_mpp_accel,
// parambox associes au reglage map
		_pb_mapindex_tbm,_pb_mapindex_t4k,_pb_mapindex_pinj,
// parambox associes au reglage tuning
        _pb_tuning_start,_pb_tuning_auto,_pb_tuning_code,_pb_tuning_seuil,_pb_tuning_attente,_pb_tuning_moyenne,_pb_tuning_ofset,_pb_tuning_periode,
// parambox associes à la source RF
        _pb_sRF_ip,_pb_sRF_port,_pb_sRF_freq,_pb_sRF_power,_pb_sRF_startf,_pb_sRF_stopf,_pb_sRF_stepf,_pb_sRF_scanf,_pb_sRF_startp,_pb_sRF_stopp,_pb_sRF_stepp,_pb_sRF_scanp,
		/* les suivant sont pour relire les vieux fichiers*/
		_pb_ip,_pb_port,_pb_gain_tone,
		_nb_param_box_possibles
	 };

#define _chaines_param_box	{\
        "_enable","_cmd_ip","_cmd_port","_data_ip","_data_port","_eth","_code_horloge","_synthe","_calib","_maxbin","_nb_bande","_tone_bande","_f_bin",\
		"_canaux_mes",\
		"_kid","_f_mod","_f_base","_kid_ba1","_kid_ba2",\
		"_gain_dac1","_gain_dac2","_gain_dac3","_gain_dac4","_gain_dac5","_att_inj","_att_mes",\
		"mpp_microstep","mpp_sensorpol","mpp_minspeed","mpp_current","mpp_Rsense",\
        "mpp_retard","mpp_cnt_clr","mpp_searchz","mpp_start_stp","mpp_pas_tour","mpp_move_mp",\
        "mpp_move_dir","mpp_vitesse1","mpp_steps1","mpp_vitesse2","mpp_tolerance","mpp_accel",  \
		"_mapindex_tbm","_mapindex_t4k","_mapindex_pinj",\
		"tuning_start","tuning_auto","tuning_code","tuning_seuil","tuning_attente","tuning_moyenne","tuning_ofset","tuning_periode",\
        "sRF_ip","sRF_port","sRF_freq","sRF_power","sRF_startf","sRF_stopf","sRF_stepf","sRF_scanf","sRF_startp","sRF_stopp","sRF_stepp","sRF_scanp",\
        "_ip","_port","_gain_tone"}

// la valeur -1 indique qu'il n'y a pas de valeur par defaut
#define _defaut_value_param_box int Defaut_value[_nb_param_box_possibles]={\
        1,-1,_port_udp_commande_general,-1,50001,_datain_tcp,-1,-1,10,524288,5,70,95367,\
        4,\
        -1,-1,-1,67204231,135268, /* valeur par defaut des kid  */ \
        -1,-1,-1,-1,-1,10,10,\
        3,0,32,2000,50,  /* valeur par defaut du mppsync */ \
        0,0,0,0,51400,10,\
        0,0,0,4000,20,3000,\
        -1,-1,-1, /* valeur par defaut de map */ \
        0,0,0,400,20,20,0,10, /* valeur par defaut du tuning */ \
        0,0,1000000,-100000,-1,-1,-1,0,-1,-1,-1,0/* valeur par defaut due sourceRF */ \
        -1,-1,-1}

//-------------------------------------------------------------------------------------------------
//------------------  les param detecteurs associes a chaque detecteur      -----------------------
//-------------------------------------------------------------------------------------------------
enum {	_pd_nom1,_pd_nom2,_pd_type,_pd_voie,_pd_bolo_acq,_pd_codeutil,_pd_adr_cmd,_pd_adr_lec,_pd_gain,_pd_capa,_pd_diviseur,\
		_pd_X,_pd_Y,_pd_res_frq,_pd_res_niv,_pd_res_lg,_pd_frequency,_pd_level,_pd_width,_pd_flag,_pd_tune_angle,_pd_ecart_freq,_pd_sens,_nb_param_detecteur_possibles
	 };

#define _chaines_param_detecteur	{"nom1","nom2","type","voie",\
		"bol_acq","cd_util","adr_cmd","adr_lec","gain","capa","divise",\
		"X_pix","Y_pix","res_frq","res_niv","res_lg","frequency","level","width","flag","tune_angle","ec_freq","sensib"}


//===================================================================================================================
//===================================================================================================================
//==================			DEFINITION   DES   REGLAGES    POSSIBLES					=========================
//===================================================================================================================


//-----------------  les elements contenu dans les reglage  opera et o_mpi      -------------------
#define	_nb_elements_reglage_opera			2		//  le nb d'elements du champ "opera" : reglage de l'horloge
enum {_rien_bug,_bras_duree_pas,_bras_mini,_bras_maxi,_pol_nb_mes_per,_pol_duree_acc,_pup_flag,_nb_elements_reglage_o_mpi};

//-----------------  les elements contenu dans le reglage  kid (nikel ou amc)      -------------------
//enum {_kid_attenuateur, _kid_gain_DAC,_kid_freq_synthe,_kid_balayage1,_kid_balayage2,_kid_ip_synthe,_nb_elements_reglage_kid};
// il faut garder les parametres  _kid_f_modul  _kid_f_base  _kid_balayage1  et  _kid_balayage2  au meme endroit qu'avant
enum {_kid_old_attenuateur,_kid_f_modul,_kid_f_base,_kid_balayage1,_kid_balayage2,
	  _kid_gain_dac1,_kid_gain_dac2,_kid_gain_dac3,_kid_gain_dac4,_kid_gain_dac5,_kid_att_inj,_kid_att_mes,_nb_elements_reglage_kid
	 };

//-----------------  les elements contenu dans le reglage  mppsync        -------------------
enum {_retard,_cnt_clr_mask,_search_zero,_start_meas_steps,_pas_tour,_move_mp,_move_dir,_vitesse1,_steps1,_vitesse2,
	  _tolerance_pas_tour,_acceleration,	_nb_elements_reglage_mppsync
	 };

//-----------------  les elements contenu dans le reglage  smjd        -------------------
enum {_new_smjd,_num_courant,_indice_courant,_sample0,_mjd0,_sample_mjd,	_nb_elements_reglage_smjd};

//-----------------  les elements contenu dans le reglage  tuning        -------------------
enum {_tuning_start,_tuning_auto,_tuning_code,_tuning_seuil,_tuning_attente,_tuning_moyenne,_tuning_ofset,_tuning_periode,	_nb_elements_reglage_tuning};
enum {_tuning_normal,_decalage_seul,_decalage_continu,_tuning_complet};
// tuning_start = 1  commande tuning pour le mac dont mon_ip ==  tuning_ip
// tuning_start = ip commande tuning pour le mac dont mon_ip ==  ip

//-----------------  les elements contenu dans le reglage  sourceRF -------------------
enum {sRF_freq,sRF_power,sRF_start_freq,sRF_stop_freq,sRF_step_freq,sRF_scanf,sRF_start_power,sRF_stop_power,sRF_step_power,sRF_scanp, _nb_elements_reglage_sourceRF};


//-------------------------------------------------------------------------------------------------
//----------------------     la liste des reglages possibles       --------------------------------
//-------------------------------------------------------------------------------------------------

// le nom du champ de reglage en clair. Le nom de l'instrument est le nom du premier champ de son reglage
// le nom sera precede de la lettre correspondant au numero d'instrument

// le nombre d'elements de chaque champ de reglage. Il peut exister des champs de longueur nulle (0).
// mettre le define _nb_det pour indiquer que la longueur du champ correspond au nombre de detecteurs de l'instrument considere

// si le champ de reglage est associé a une serie de parambox, mettre ici le nom du premier parambox (dans son enum),
// si les reglage doivent etre initialises à zero, mettre  _init_zero
// si les reglages ne doivent pas etre modifier mettre     _ignore
// attention, les elements du champ de reglage doivent correspondre exactement aux parabox de la liste et dans le bon ordre
// cela permettra au programme d'initialiser les reglages avec les valeurs des parambox et de sauver le reglage dans les parambox.
#define _init_zero  -1
#define _ignore     -2
#define _paramd_kid  -3


enum    {_r_ctrl,_r_smjd,_r_tuning,_r_newfile,_r_elvin,_r_antenna,\
        _r_opera,_r_o_mpi,_r_o_mux,_r_o_equi,_r_o_rg1,_r_o_rg2,\
        _r_nikel,_r_amc,_r_bside,
        _r_k_freq,_r_k_niv,_r_k_width,_r_k_shape,\
        _r_mppsync,_r_map,_r_sourceRF,_nb_type_reglage_possibles
        };

#define _chaines_reglage	{"ctrl","smjd","tuning","newfile","elvin","antenna",\
                            "opera","o_mpi","o_mux","o_equi","o_rg1","o_rg2",\
                            "nikel","amc","bside",\
                            "k_freq","k_niv","k_width","k_shape",\
                            "mppsync","map","sourceRF"}

#define _nb_element_reglage_type {0,_nb_elements_reglage_smjd,_nb_elements_reglage_tuning,1,0,0,\
                                _nb_elements_reglage_opera,_nb_elements_reglage_o_mpi,0,0,_nb_det,_nb_det,\
                                _nb_elements_reglage_kid,_nb_elements_reglage_kid,_nb_elements_reglage_kid,\
                                _nb_det,_nb_det,_nb_det,_nb_det,\
                                _nb_elements_reglage_mppsync,0,_nb_elements_reglage_sourceRF}

#define _reglage_parambox_associe { _ignore,_ignore,_pb_tuning_start,_ignore,_ignore,_ignore,\
                                    _ignore,_ignore,_ignore,_ignore,_ignore,_ignore,\
                                    _pb_kid,_pb_kid,_pb_kid, \
                                    _paramd_kid,_paramd_kid,_paramd_kid,_ignore,\
                                    _pb_mpp_retard,_ignore,_pb_sRF_freq}


//===================================================================================================================
//==================			  DEFINITION   DES   BRUT  ou  DATA    POSSIBLES			=========================
//========  on a les data simples,    puis les data box          et enfin les data detecteurs      ==================
//==================================================================================================================

//----------------,  les  brut et data simple : une sule valeur a chaque echantillon  ----------------------
enum	{_d_sample,_d_t_mac,_d_synchro_rapide,_d_synchro_flag,_d_synchro_periode,_d_synchro_phase,_d_bras_mpi,\
		 _d_ofs_X,_d_ofs_Y,_d_Paral,_d_Az,_d_El,_d_MJD_int,_d_MJD_deci,_d_MJD_dec2,_d_LST,_d_Ra,_d_Dec,_d_t_elvin,\
		 _d_ofs_Az,_d_ofs_El,_d_ofs_Ra,_d_ofs_Dec,_d_ofs_Mx,_d_ofs_My,_d_MJD,_d_rotazel, \
		 _d_year,_d_month,_d_day,_d_scan,_d_subscan,_d_scan_st,_d_obs_st,\
		 _d_size_x,_d_size_y,_d_nb_sbsc,_d_step_y,_d_speed,_d_tau,\
		 _d_antMJD_int,_d_antMJD_dec,_d_antLST,_d_antxoffset,_d_antyoffset,_d_antAz,_d_antEl,
		 _d_antMJDf_int,_d_antMJDf_dec,_d_antactualAz,_d_antactualEl,_d_anttrackAz,_d_anttrackEl,
		 _d_map_tbm,_d_map_t4k,_d_map_pinj,
		 _nb_data_simple_possibles
	 };

#define _data_simple_dependance {_d_sample,_d_t_mac,_d_synchro_rapide,_d_synchro_flag,_d_synchro_periode,_d_synchro_phase,_d_bras_mpi,\
		_d_ofs_X,_d_ofs_Y,_d_Paral,_d_Az,_d_El,_d_MJD,_d_MJD,_d_MJD,_d_LST,_d_Ra,_d_Dec,_d_t_elvin,\
		_d_ofs_X,_d_ofs_X,_d_ofs_X,_d_ofs_X,_d_ofs_X,_d_ofs_X,_d_MJD_int,_d_El, \
		_d_year,_d_month,_d_day,_d_scan,_d_subscan,_d_scan_st,_d_obs_st,\
		_d_size_x,_d_size_y,_d_nb_sbsc,_d_step_y,_d_speed,_d_tau, \
		_d_antMJD_int,_d_antMJD_dec,_d_antLST,_d_antxoffset,_d_antyoffset,_d_antAz,_d_antEl,\
		_d_antMJDf_int,_d_antMJDf_dec,_d_antactualAz,_d_antactualEl,_d_anttrackAz,_d_anttrackEl,\
		_d_map_tbm,_d_map_t4k,_d_map_pinj}

#define _chaines_data_simple  {"sample","t_mac","synchro","sy_flag","sy_per","sy_pha","Bra_mpi",\
		"ofs_X","ofs_Y", "Paral", "Az","El", "MJD_int","MJD_dec","MJD_dec2","LST","Ra","Dec","t_elvin",\
		"ofs_Az", "ofs_El","ofs_Ra","ofs_Dec","ofs_Mx","ofs_My","MJD","rotazel", \
		"year","month","day","scan","subscan","scan_st","obs_st","size_x","size_y","nb_sbsc","step_y","speed","tau",\
		"antMJD_int","antMJD_dec","antLST","antxoffset","antyoffset","antAz","antEl",\
		"antMJDf_int","antMJDf_dec","antactualAz","antactualEl","anttrackAz","anttrackEl",\
		"map_tbm","map_t4k","map_pinj"}

#define _chaines_unite_simple  {\
		"sample","msec","synchro","sy_flag","sy_per","sy_pha","mm",\
		"rad","rad", "rad", "Az","El", "MJD_int","daye-6","daye-6","LST","Ra","Dec","t_elvin",\
		"arc_sec", "arc_sec","arc_sec","arc_sec","arc_sec","arc_sec","day","rad", \
		"year","month","day","scan","subscan","scan_st","obs_st","size_x","size_y","nb_sbsc","step_y","speed","tau",\
		"day","day","rad","rad","rad","rad","rad",\
		"day","day","rad","rad","rad","rad",\
		"K","K","mbar"}

//----------------  les  brut et data box : une valeur pour chaque boite a chaque echantillon  ----------------------
//----------------  leur nom sera precede de la lettre indiquant la boite de mesure en majuscule   ------------------
enum	{					  _db_t_utc,_db_pps,_db_o_pps,_db_freq,_db_masq,_db_n_inj ,_db_n_mes ,_db_status ,_db_position ,_db_synchro ,_db_fRF ,_db_pRF, _nb_data_box_possibles};
#define _data_box_dependance {_db_t_utc,_db_pps,_db_o_pps,_db_freq,_db_masq,_db_n_inj ,_db_n_mes ,_db_status ,_db_position ,_db_synchro ,_db_fRF ,_db_pRF}
#define _chaines_data_box {"_t_utc","_pps","_o_pps","_freq" ,"_masq" ,"_n_inj"  ,"_n_mes"  ,"_status"  ,"_position"  ,"_synchro" , "_fRF" ,"_pRF"}
#define _chaines_unite_box {"sec","micro_sec","micro_sec","_freq" ,"_masq" ,"_n_inj","_n_mes","status","...","...", "Hz", "dBm"}

//----------------,  les  brut et data detecteur : une une valeur pour chaque detecteur a chaque echantillon  ----------------------
enum	{_dd_I,_dd_Q,_dd_dI,_dd_dQ,_dd_pI,_dd_pQ,\
		 _dd_RF_deco,_dd_RF_didq,_dd_F_tone,_dd_dF_tone,_dd_amplitude,_dd_log_amplitude,_dd_ap_dIdQ,_dd_amp_pIQ,_dd_rap_pIQdIQ,\
		 _dd_phase_IQ,_dd_ph_rel,_dd_k_angle,_dd_k_flag,_dd_k_width,\
		 _dd_boloA,_dd_boloB,_dd_V_bolo,_dd_V_brut,_dd_V_dac,_dd_I_dac,\
		 _dd_ds_pha,_dd_ds_qua,\
		 _dd_X_det,_dd_Y_det,_dd_Az_det,_dd_El_det,_dd_Ra_det,_dd_Dec_det,_nb_data_detecteur_possibles
	 };

#define _data_detecteur_dependance {_dd_I,_dd_Q,_dd_dI,_dd_dQ,_dd_pI,_dd_pQ,\
		_dd_I,_dd_I,_dd_I,_dd_I,_dd_I,_dd_I,_dd_I,_dd_pI,_dd_pI,\
		_dd_I,_dd_I,_dd_I,_dd_I,_dd_I,\
		_dd_boloA,_dd_boloA,_dd_boloA,_dd_boloA,_dd_boloA,_dd_boloA,\
		_if_synchro,_if_synchro,\
		-_if_pointage,_if_pointage,_if_pointage,_if_pointage,_if_pointage,_if_pointage}

#define _chaines_data_detecteur {"I" , "Q" , "dI" , "dQ"  , "pI" , "pQ" ,\
		"RF_deco","RF_didq","F_tone","dF_tone",  "amplit", "logampl",	"amp_dIdQ" ,	"amp_pIQ", "rap_pIQdIQ" , \
		"ph_IQ",	"ph_rel","k_angle","k_flag","k_width",\
		"boloA","boloB","V_bolo","V_brute","V_dac","I_dac",\
		"ds_pha","ds_qua",\
		"X_det",	"Y_det",  "Az_det",	"El_det", "Ra_det",	"Dec_det"}

#define _chaines_unite_detecteur {"I" , "Q" , "dI" , "dQ"   , "pI" , "pQ" ,\
		"RF_deco","Hz","kHz","kHz",  "amplit", "db",	"adu" ,	"adu", "rel" ,\
		"ph_IQ","ph_rel","radian","flag","kHz",\
		"boloA","boloB","V_bolo","V_brute","V_dac","I_dac",\
		"ds_pha","ds_qua",\
		"X_det",	"Y_det",  "Az_det",	"El_det", "Ra_det",	"Dec_det"}

// une fonction contenant un modele de lecture et ecriture des variables
// dans le fichier brut_to_data.c
//void modele_lecture_ecriture_variables(Data_header_shared_memory *dhs,int4 * Br,double * Dd);

//------  je rajoute ici la liste des data a creer si l'on demande  'raw' dans la liste data  ----
#define _nb_brut_detecteur_possibles 14
#define _chaines_brut_detecteur {"I" , "Q" , "dI" , "dQ"  , "pI" , "pQ" ,\
		"k_flag","k_width",\
		"boloA","boloB","V_bolo","V_brute","V_dac","I_dac"}

enum	{_liste_detecteurs_all=1,_liste_detecteurs_not_zero,_liste_detecteurs_kid_pixel,_liste_detecteurs_kid_pixel_array1,\
		 _liste_detecteurs_kid_pixel_array2,_liste_detecteurs_kid_pixel_array3
	 };

enum {_datain_rien,_datain_tcp,_datain_udp,_datain_broadcast,_datain_tcp_antenna,_datain_tcp_map,_datain_amc,_datain_bside,_datain_tcp_sourceRF};

#define     undef_double	-32768.5
#ifndef PI
#define PI	3.1415926535897932384626433832795028841971L
#endif


#endif		//  indef  __NAME_LIST__

