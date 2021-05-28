#ifndef _ELVIN_STRUCTURE_H
#define _ELVIN_STRUCTURE_H

//===================================================================================================================================
//===================================================================================================================================
//========================================   defines utilises pour le pointage     ==================================================
//===================================================================================================================================
//===================================================================================================================================

#define _ELVIN_STRUCTURE_

//===================================================================================================================================
//=================== les differentes donnees des chaines  pointage  et  message en provenance d'elvin  =============================
//===================================================================================================================================

// ici ce sont les noms tels qu'ils apparraissent dans la reponse d'elvin
enum {_pt_id,_pt_xOffset,_pt_yOffset,_pt_paralactique,_pt_actualAz,_pt_actualEl,
	  _pt_MJD_int,_pt_MJD_deci,_pt_MJD_dec2,_pt_LST,_pt_basisLong,_pt_basisLat,_pt_time_elvin,_pt_nb_params
	 };
#define _def_noms_elvin		char *noms_elvin[_pt_nb_params]= {"elvin","xOffset","yOffset","paralact","actualAz","actualEl",\
		"MJD_int"   ,"MJD_deci" ,"MJD_dec2" ,"LST"   ,"basisLong","basisLat","t_elvin"};\
char *unites_elvin[_pt_nb_params]={"   " ,"mu_rad" ,"mu_rad" ,"mu_rad"  ,"mu_deg"  ,"mu_deg"  ,\
								   "day"       ,"day_e-8"   ,"day_e-8"   ,"mu_rad","mu_rad"   ,"mu_rad","msec"};

// les differentes donnees de la chaine de message elvin  // les noms correspondants sont dans memoire.h
//  le enum du _nb_data_possibles  doit etre identique a celui-ci  de _mg_year .. _mg_tau  correspond a _d_year .. _d_tau
enum {_mg_id,_mg_year,_mg_month,_mg_day,_mg_scan,_mg_subscan,_mg_scan_st,_mg_obs_st,_mg_size_x,_mg_size_y,_mg_nb_sbscan,_mg_step_y,_mg_speed,_mg_tau,_mg_nb_params};
//enum {_mg_id,_mg_year,_mg_month,_mg_day,_mg_scan,_mg_subscan,_mg_scan_message,_mg_obs_status,_mg_size_x,_mg_size_y,_mg_nb_sbscan,_mg_step_y,_mg_speed,_mg_tau,_mg_nb_params};

#define _nb_total_parametres_de_pointage        (_pt_nb_params+_mg_nb_params-2)
//===================================================================================================================================
//===================================================		le codage des messages d'elvin	=========================================
//===================================================================================================================================
#define		_broadcast_type_pointage		1
#define		_broadcast_type_message			2

//  message envoye dans le champ  "obs_st"
enum {_tracking,_otfMap,_focus,_pointing,_tuning,_special,_skydip, _onoff, _obs_balayage, _obs_MPI , _obs_tablexy ,_lissajous,_obs_inconnu, _nb_obs_status};
#define _def_noms_modes_iram  char nom_mode[_nb_obs_status][32]={\
		"track","onTheFlyMap","focus","pointing","tuning","special","DIY", "onOff","Balayage","MPI" , "Tablexy" ,"Lissajous","Inconnu"};

//  message envoye dans le champ  "scan_st"
enum {_scanNothing,_scanLoaded,_scanStarted,_scanDone,_subscanStarted,_subscanDone, _scanbackOnTrack,_subscan_tuning,_scan_tuning,_scan_new_file,_nb_scan_status};
#define _def_nom_scan_status	char* nom_scan_status[_nb_scan_status+1] = {\
		"scan_rien","scanLoaded","scanStarted","scanDone","subscanStarted","subscanDone","scanBackOnTrack","subscanTuning","scanTuning","scanNewFile",""};

#define _longueur_du_nom_de_la_source	256

#endif // _ELVIN_STRUCTURE_H
