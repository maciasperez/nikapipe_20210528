;+
;PURPOSE: Produces a default param structure and parameter file to be used by the
;         pipeline modules
;
;INPUT: The scan number and day lists.
;
;OUTPUT: The param structure.
;
;LAST EDITION: 
;   2013: creation (adam@lpsc.in2p3.fr)
;   04/07/2013: source_interpol substructure removed
;   04/07/2015: add the df_tone recomputation technique
;-

pro nika_pipe_default_param, scan_num, day, param, no_refpix=no_refpix

  if n_params() lt 1 then begin
     message, /info, "Calling sequence:"
     print, "nika_pipe_default_param, scan_num, day, param, no_refpix=no_refpix"
     return
  endif
  
  ;; Ensure correct format for "day"
  t = size( day, /type)
  if t eq 7 then day = strtrim(day,2) else day = string( day, format="(I8.8)")

  nscan = n_elements(scan_num)  ;Nombre de scan

  ;;######################### which type of data are used  ###########################
  math = "RF"; PF, CF

  ;;######################### To be given by hand  ###########################
  source = ''                                                 ;Proper name of the source (ex: Horse Head Nebula)
  name4file = ''                                              ;Name used for files (ex: Horse_Head_Nebula)
  version = 'v1'                                              ;Version of the analysis
  coord_pointing = {ra:[0.0,0.0,0.0],dec:[0.0,0.0,0.0]} ;Pointing coordinates
  coord_source = {ra:[0.0,0.0,0.0],dec:[0.0,0.0,0.0]}   ;Source coordinates (not very usefull anymore)
  coord_map = {ra:[0.0,0.0,0.0],dec:[0.0,0.0,0.0]}      ;Map center coordinates
  
  ;;################ Parameters and Files used for this data reduction ###############
  get_kidpar_ref, scan_num, day, kidpar_a1mm_file, kidpar_b2mm_file, no_refpix=no_refpix
  kid_file = {A:kidpar_a1mm_file, B:kidpar_b2mm_file}

  ;;############### Map parameters ###################
  map = {size_ra:400.0,$        ;arcsec
         size_dec:400.0,$       ;arcsec
         reso:4.0}              ;arcsec

  ;;############### Deglitching #######################
  glitch = {width:100              ,$
            nsigma:5.0, $
            iq:0}               ; set to 1 to deglitch I,Q, dI, dQ before recombining into RF_DIDQ

  ;;############### Decorrelation used ###############
  ;;param for all methods
  IQ_plane = {apply:'no',$       ;Do you want to decorrelate the electronic noise in the IQ plane?
              per_subscan:'no',$ ;Decorrelation per subscan?
              one_mode:'yes'}    ;Only one OFF common mode or use all OFFs

  median = {width:201}          ;Width for median filtering
  
  common_mode = {per_subscan:'yes',$           ;Decorrelation per subscan?
                 x_calib:'yes',$               ;Do you want to cross calib the atmosphere
                 median:'no',$                 ;Use median instead of mean for common mode computing
                 nsmooth:0,$                   ;Number of points on which the common mode is smoothed
                 ncomp:1, $                    ;Number of components for PCA
                 dbfcut:[0.5, 1.5],$           ;Transition freq for dual-band decor
                 d_min:1.5*!nika.fwhm_nom[1],$ ;Min distance for considering a KID to be far
                 nbloc_min:15,$                ;Min number of KIDs for bloc decorrelation
                 nsig_bloc:2.0,$               ;Number of sigma (for correlation) allowed from the best bloc
                 map_guess1mm:'',$             ;Map used as a first guess for source flagging
                 map_guess2mm:'',$             ;Map used as a first guess for source flagging
                 flag_type:'snr',$             ;Map used for flaging (snr or flux)
                 flag_lim:[5.0,5.0],$          ;Above this snr (or flux) we are on source (Jy/beam if flux)
                 flag_max_noise:[2.0,2.0],$    ;
                 relob:{a:10.0,b:10.0}}        ;Smooth of the map (for flag) in arcsec
  
  ;;global param which goes in the structure
  decor = {IQ_plane:IQ_plane,$               ;IQ plane decorrelation
           method:'median_simple',$          ;Simple median filter as decorrelator
           median:median,$                   ;Median parameters
           common_mode:common_mode,$         ;Common mode parameters
           frac:0.1, $                       ;fraction of the subscan used to subtract a baseline fit on the edges of each subscan
           baseline:[0,2.0]}                 ;Remove a polynome with given order [order,w8 ratio on/off source]
  
  ;;############### Weight and zero level used ###############
  w8 = {apply:'yes',$                           ;Do you want to apply weight in the data
        dist_off_source:1.5*!nika.fwhm_nom[1],$ ;Compute the weight excluding data closer from this to the source
        per_subscan:'no',$                      ;Do you get the weight per subscan?
        map_guess1mm:'',$                       ;Map used as a first guess for source flagging
        map_guess2mm:'',$                       ;Map used as a first guess for source flagging
        flag_type:'snr',$                       ;Map used for flaging (snr or flux)
        flag_lim:[5.0, 5.0],$                   ;Above this snr we are on source (Jy/beam)
        relob:{a:10.0, b:10.0},$                ;Smooth of the map (for flag) in arcsec
        nsigma_cut:1e6}                         ;Number of sigma above which we flag (not projected) the data
  
  zero_level = {apply:'yes',$                           ;Do you want to remove zero level
                dist_off_source:1.5*!nika.fwhm_nom[1],$ ;distance bellow which we flag the source
                per_subscan:'no',$                      ;Do you get the weight per subscan?
                map_guess1mm:'',$                       ;Map used as a first guess for source flagging
                map_guess2mm:'',$                       ;Number of sigma to flag the source (for strong source)
                flag_type:'snr',$                       ;Map used for flaging (snr or flux)
                flag_lim:[5.0, 5.0],$                   ;Above this snr we are on source (Jy/beam)
                relob:{a:10.0, b:10.0}}                 ;Smooth of the map (for flag) in arcsec
  
  ;;############### Filtering used ###############
  filter = {apply:'no',$          ;Do you want to apply the filter
            width:500,$           ;Number of point considered when flagging lines
            nsigma:4,$            ;Flag at nsigma above the noise
            freq_start:1.0,$      ;Start to search for lines at freq_start (Hz)
            low_cut:[0.0, 0.0],$  ;Low frequency cutoff by cos between the two given freq (Hz)
            dist_off_source:0.0,$ ;distance bellow which we flag the source
            cos_sin:'no',$        ;Do you want to apply cos and sin filtering
            pre:'no'}             ;Do you want to filter the TOI before decorrelation

  ;;###### Units convert ###############
  JYperKRJ = {A:0.d0, B:0.d0}   ;To be computed with the beam
  KRJperKCMB = {A:0.d0, B:0.d0} ;To be computed with bandpasses
  KCMBperY = {A:0.d0, B:0.d0}
  
  ;;###### Pointing ###############
  pointing = {antenna_corr:'no',$  ;Do you use the antenna_imb_fits for pointing correction
              cut:[0, 0],$         ;Cut the scans (begin, end)
              fake_subscan:'yes',$ ;If set to yes, creates fake subscans in the case of lissajous
              liss_cross:1.0}

  ;;###### Atmospheric noise characterization ###############
  meas_atmo = {ampli:{a:dblarr(nscan), b:dblarr(nscan)},$       ; Amplitude of the fuctuation at 1Hz
               slope:{a:dblarr(nscan),b:dblarr(nscan)},$        ; Slope of the spectrum
               flux_bin:{a:dblarr(nscan,8),b:dblarr(nscan,8)},$ ; Flux in bins
               dofitatmo:"yes", $                               ; do the fit
               am2jy:{a:0.d0,b:0.d0}}                           ; correlation between air mass and common mode in Jy
  ;;###### Flag the saturation - out of resonance and overlap ###############
  flag = {sat:'yes',$
          sat_val:!dpi/2,$      ;Before it was !pi/4 but it flags too many KIDs
          oor:'no',$            ; Fxd: Not good for bad weather. Rely on sat only. 25-Mar-2014, anyway bad kids are excluded in other ways
          oor_val:3.0,$         ; Fxd: 2 is too restrictive at 2mm, go to 3
          ovlap:'yes',$         ;
          ovlap_val:0.8,$       ;
          uncorr:'yes', $       ;
          scan:intarr(nscan)}   ;Scan bad because
  
  renew_df = 2                  ; default is now to recompute df_tone using Xavier's last formula (Feb. 2015)

  ;;########################################################################################################
  ;;##################################### Derived parameters ###############################################
  ;;########################################################################################################
  nu = {A:!const.c*1d-6/!nika.lambda[0], B:!const.c*1d-6/!nika.lambda[1]}
  scan_list = day+'s'+string(scan_num,format="(I4.4)")
  iscan = 0                                            ;label the scan used, modified in the pipeline
  scan_type = strarr(nscan)                            ;Direction of the scan (azimuth or elevation) 
  tau_list = {A:dblarr(nscan), B:dblarr(nscan), $      ;List of the opacities NIKA
              iram225:dblarr(nscan)}                   ;List of the opacities Iram tau225
  mean_noise_list = {A:dblarr(nscan), B:dblarr(nscan)} ;List of the mean noise level after decorrelation
  nefd_toi = {A:dblarr(nscan), B:dblarr(nscan)}        ;List of NEFD
  nefd_map = {A:dblarr(nscan), B:dblarr(nscan)}        ;List of NEFD
  elev_list = dblarr(nscan)                            ;List of the mean elevation
  paral = dblarr(nscan)                                ;List of paralactic angle
  integ_time = dblarr(nscan)                           ;List of integration time per scan

  ;;########################################################################################################
  ;;################################## Polarization specific parameter  ####################################
  ;;########################################################################################################

  polar = {subtract_template:0, $
           nu_rot_hwp:2.d0, $
           n_template_harmonics:7, $
           do_lockin:1, $       ; map making
           do_coadd:0, $
           cond_num_max:100, $
           lockin_freqlow:0.d0, $
           lockin_freqhigh:!nika.f_sampling*2, $ ; margin
           lockin_delta_f:0.05}

  ;;######################################################################################################
  ;;################################### SCAN STATUS PARAMETERS ###########################################
  ;;######################################################################################################

  scanst = {scanNothing:0, scanLoaded:1, scanStarted:2, scanDone:3, subscanStarted:4, subscanDone:5, $
            scanbackOnTrack:6, subscan_tuning:7, scan_tuning:8, scan_new_file:9}

  ;;******************************
  ;; Pointing flag quality
  ptg_quality_threshold = 3.    ; arcsec

  ;;######################################################################################################
  ;;################################### PAKO's projection type ###########################################
  ;;######################################################################################################
  projection =  {type:"horizontalTrue"}

  ;;########################################################################################################
  ;;##################################### Creation of the structure ########################################
  ;;########################################################################################################

  param = {math:math, $         ; rf_didq, pf or cf
           renew_df:renew_df, $
           source:source,$
           name4file:name4file,$
           version:version,$
           coord_pointing:coord_pointing,$
           coord_source:coord_source,$
           coord_map:coord_map,$
           ;;___________________________
           scan_num:scan_num, $
           day:day, $
           scan_list:scan_list,$
           kid_file:kid_file,$
           config_file:'', $
           data_file:'', $
           imb_fits_file:'a', $
           output_dir:'.', $
           logfile_dir:'.', $
           nickname:'', $
           source_flux_jy:{A:dblarr(nscan), B:dblarr(nscan)}, $
           err_source_flux_jy:{A:dblarr(nscan), B:dblarr(nscan)}, $
           source_loc:{A:dblarr(nscan,2), B:dblarr(nscan,2)}, $
           ;;___________________________
           map:map,$
           glitch:glitch,$
           decor:decor,$
           filter:filter,$
           w8:w8,$
           zero_level:zero_level,$
           flag:flag,$
           ;;___________________________
           iscan:iscan,$
           scan_type:scan_type,$
           tau_list:tau_list,$
           do_opacity_correction:1, $
           silent:0,$
           mean_noise_list:mean_noise_list,$
           nefd_toi:nefd_toi,$
           nefd_map:nefd_map,$
           elev_list:elev_list,$
           paral:paral,$
           integ_time:integ_time,$
           ;;___________________________
           nu:nu,$
           JYperKRJ:JYperKRJ,$
           KRJperKCMB:KRJperKCMB,$
           KCMBperY:KCMBperY,$
           ;;___________________________
           pointing:pointing,$
           fit_elevation:'no', $
           meas_atmo:meas_atmo,$
           ;;---------------------------
           polar:polar,$
           ptg_quality_threshold:ptg_quality_threshold, $
           ;; --------------------------
           scanst: scanst, $
           ;; --------------------------
           projection:projection}
  
end
