;+
; 
; SOFTWARE: 
;        NIKA pipeline
; 
; PURPOSE: 
;        Read the raw data
; 
; INPUT: 
;        - param: the parameter structure
;        - info: the information structure
; 
; OUTPUT: 
;        - data: the data structure
;        - kidpar: the KID parameter structure
; 
; KEYWORDS:
;        - LIST_DATA: the list of variables to be put in the data structure
;        - RETARD: a retard between NIKA and telescope data
;        - EXT_PARAMS: extra variables to be put in the data structure
;        - ONE_MM_ONLY: set this keyword if you only want the 1mm channel
;        - TWO_MM_ONLY: set this keyword if you only want the 2mm channel
;        - FORCE_FILE:Use this keyword to force the list of scans used
;        instead of checking if they are valid
;        - RF: set this keyword if you want to use RF_dIdQ instead of
;          the polynom
;        - NOERROR: set this keyword to bypass errors
; 
; MODIFICATION HISTORY: 
;        - 13/03/2014: creation from nika_pipe_getdata.pro 
;        (Nicolas Ponthieu - nicolas.ponthieu@obs.ujf-grenoble.fr)
;-
;====================================================================================================

pro nk_getdata_polar, param, info, data, kidpar, $
                LIST_DATA=LIST_DATA, $
                RETARD=RETARD, $
                EXT_PARAMS=EXT_PARAMS, $
                FORCE_FILE=FORCE_FILE, $
                RF=RF, $
                NOERROR=NOERROR, $
                plot=plot

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_getdata_polar, param, info, data, kidpar, $"
   print, "            LIST_DATA=LIST_DATA, $"
   print, "                RETARD=RETARD, $"
   print, "                EXT_PARAMS=EXT_PARAMS, $"
   print, "                FORCE_FILE=FORCE_FILE, $"
   print, "                RF=RF, $"
   print, "                NOERROR=NOERROR"
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

  ;;========== Select the KIDs to be used
  if param.ONE_MM_ONLY ne 0 then begin
     indexdetecteurdebut = 0
     nb_detecteurs_lu    = 400
  endif
  if param.TWO_MM_ONLY ne 0 then begin
     indexdetecteurdebut = 400
     nb_detecteurs_lu    = 400
  endif
  if param.all_kids ne 0 then begin
     indexdetecteurdebut = 0
     nb_detecteurs_lu    = 800
  endif

  ;;========== List what we want to read
  nk_check_list_data, LIST_DATA=LIST_DATA, RETARD=RETARD, EXT_PARAMS=EXT_PARAMS

  ;; Determine which raw data file must be read.
  ;; Allow FORCE_FILE for laboratory files with no correct day and scan_num
  if keyword_set(FORCE_FILE) then begin
     file_scan     = FORCE_FILE
     imb_fits_file = ''
     nk_default_param, param
     nk_default_info, info
     if keyword_set(RF) then param.math = "RF"

  endif else begin
     nk_find_raw_data_file, param.scan_num, param.day, file_scan, imb_fits_file, xml_file, $
                            /silent, noerror=noerror
     if strlen( file_scan) eq 0 then begin
        nk_error, info, "No data available for scan "+strtrim(param.day,2)+"s"+strtrim(param.scan_num,2)
        message, /info, info.error_message
        return
     endif
  endelse
  param.data_file     = file_scan
  param.file_imb_fits = imb_fits_file

  ;; Init !nika
  day2run, param.day, run
  fill_nika_struct, run

  ;; Retrieve general information from the Antenna IMBfits file
  nk_update_scan_info, param, info

  ;; Read data
  rr = read_nika_brute(file_scan, param_c, kidpar, data, units, $
                       PARAM_D=PARAM_D, LIST_DATA=LIST_DATA, READ_TYPE=12, $
                       INDEXDETECTEURDEBUT=INDEXDETECTEURDEBUT, $
                       NB_DETECTEURS_LU=NB_DETECTEURS_LU, AMP_MODULATION=AMP_MODULATION, /silent)

  ;; replace rf_didq by toi, adds dra, ddec etc...
  nk_update_data_fields, data

  ;; Deal with units convention (numdet, frequencies, parallactic angle, RF/PF...)
  nk_data_conventions, param, info, data, kidpar, param_c

  ;; If a kidpar is passed to nk_getdata_polar, then it replaces the current
  ;; one given by read_nika_brute
stop
  nk_update_kidpar_polar, param, info, kidpar, param_c
  
  ;; Acquisition flags
  nk_acqflag2pipeflag, param, info, data, kidpar

  ;; Flag nan values on some scans
  nk_nan_flag, param, info, data, kidpar

  ;; Flag from scan status
  nk_flag_scanst, param, info, data, kidpar

  ;; Flag from *_masq (detect tunings)
  nk_tuningflag, param, info, data, kidpar

  ;; Discard useless information in data to save memory
  rm_fields = ['I', 'Q', 'DI', 'DQ', 'A_MASQ', 'B_MASQ', 'K_FLAG']
  if param.glitch_iq eq 1 then rm_fields = ['A_MASQ', 'B_MASQ', 'K_FLAG']
  nk_shrink_data, param, info, data, kidpar, rm_fields=rm_fields

  ;; Restrict to the largest continuous valid section and force data's
  ;; length to a convenient number for future FFT's
  nk_cut_scans, param, info, data, kidpar

  ;; Flag out sections when the telescope is not moving at
  ;; regular speed (inter subscans, approach phases, slew...) and interpolates
  ;; missing data
  nk_restore_pointing, param, info, data, kidpar

  ;; Flag out anomalous speed behaviour (intersubscans)
  ;; It's not needed and it's an overkill for Lissajous
  if strupcase( info.obs_type) eq "ONTHEFLYMAP" then begin
     nk_speed_flag, param, info, data, kidpar
  endif

  ;; Extend structure "data" with flags, weights and off_source + interpolate pointing
  nk_low_level_proc, param, info, data, kidpar, amp_modulation

  ;; Compute individual kid pointing once for all
  nk_get_kid_pointing, param, info, data, kidpar
  
  ;; Update kidpar
  nkids = n_elements(kidpar)
  for ikid=0, nkids-1 do begin
     if min(data.flag[ikid]) ne 0 then kidpar[ikid].type = 3
  endfor

  if not param.silent then message, /info, "done."

end
