;+
;
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
;        nk_default_info
;
; CATEGORY: 
;        initialization
;
; CALLING SEQUENCE:
;         nk_default_info, info
; 
; PURPOSE: 
;        Create the initial info structure
; 
; INPUT: 
;       
; OUTPUT: 
;        - info: the default info structure for one scan used to store info
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - 04/03/2014: creation Remi Adam and Nicolas Ponthieu
;        - Oct. 2015: clean up and update for NIKA2, NP
;-

pro nk_default_info, info


;; Tags that depend on lambda or array and the stokes param
stokes_tags = 'RESULT_'+['FLUX', 'ERR_FLUX', 'FLUX_CENTER', 'ERR_FLUX_CENTER', $
                         'APERTURE_PHOTOMETRY', 'ERR_APERTURE_PHOTOMETRY', $
                         'NEFD', 'NEFD_CENTER', 'ERR_NEFD', 'ERR_FLUX_LIST', 'SIGMA_BOOST', 'SIGMA_1HIT', 'BG_RMS']
stokes = ['I', 'Q', 'U']
tag_list = ['']
for istokes=0,2 do begin
   for itag=0, n_elements(stokes_tags)-1 do begin
      for lambda=1, 2 do begin
         tag_list = [tag_list, stokes_tags[itag]+"_"+strtrim(stokes[istokes],2)+"_"+strtrim(lambda,2)+"mm"]
      endfor
;;      for iarray=1, 3 do begin
      for iarray=1, 4 do begin ; adding 4 = combined 1mm for convenience
         tag_list = [tag_list, stokes_tags[itag]+"_"+strtrim(stokes[istokes],2)+strtrim(iarray,2)]
      endfor
   endfor
endfor
tag_list = tag_list[1:*]

;; Tags that do not depend on Stokes parameters
tag_list_1 = 'RESULT_'+['POL_DEG', 'ERR_POL_DEG', 'POL_ANGLE', 'ERR_POL_ANGLE', $
                        'POL_DEG_CENTER', 'ERR_POL_DEG_CENTER', 'POL_ANGLE_CENTER', 'ERR_POL_ANGLE_CENTER', $
                        'POL_DEG_APPHOT', 'ERR_POL_DEG_APPHOT', 'POL_ANGLE_APPHOT', 'ERR_POL_ANGLE_APPHOT', $
                        'OFF_X', 'OFF_Y', 'FWHM_X', 'FWHM_Y', 'FWHM', 'PEAK', 'TAU', $
                        'OPT_FOCUS', 'ERR_OPT_FOCUS', 'COMM_GLI', 'COMM_JUM', 'ON_SOURCE_FRAC_ARRAY', $
                        'ATM_QUALITY', 'SCAN_QUALITY', 'GEOM_TIME_CENTER', 'SKY_NOISE_POWER', $
                        'TIME_MATRIX_CENTER', 'ETA', 'T_GAUSS_BEAM', 'ANOM_REFRAC_SCATTER']

for itag=0, n_elements(tag_list_1)-1 do begin
   for lambda=1, 2 do begin
      tag_list = [tag_list, tag_list_1[itag]+"_"+strtrim(lambda,2)+"mm"]
   endfor
;;   for iarray=1, 3 do begin
   for iarray=1, 4 do begin     ; adding 4 = combined 1mm for convenience
      tag_list = [tag_list, tag_list_1[itag]+"_"+strtrim(iarray,2)]
   endfor
endfor

;; weather monitoring
tag_list1 = 'RESULT_'+["FATM1MM_B"+strtrim(indgen(9)+1,2), $
                       "FATM2MM_B"+strtrim(indgen(9)+1,2), $
                       "ATMO_AM2JY_1MM", "ATMO_AM2JY_2MM", "ATMO_SLOPE_1MM", "ATMO_SLOPE_2MM", $
                       "ATMO_AMPLI_1MM", "ATMO_AMPLI_2MM", "ATMO_LEVEL_1MM", "ATMO_LEVEL_2MM", $
                       "ATM_POWER_60SEC_A1", "ATM_POWER_60SEC_A2", "ATM_POWER_60SEC_A3", $
                       "ATM_POWER_4HZ_A1", "ATM_POWER_4HZ_A2", "ATM_POWER_4HZ_A3"]
tag_list = [tag_list, tag_list1]

;; Pipeline exchange information
tag_list = [tag_list, $
            'POLAR', 'HWP_ROT_FREQ', 'STATUS', $
            'LISS_FREQ_AZ', 'LISS_FREQ_EL', 'F_SAMPLING']

;; Scan information
tag_list = [tag_list, $
            'PARAL', 'ELEV', 'LST', 'TAU225', 'PRESSURE', 'TEMPERATURE', 'HUMIDITY', $
            'WIND_SPEED', 'LONGOBJ', 'LATOBJ', 'AZIMUTH_DEG', 'RESULT_ELEVATION_DEG', $
            'FOCUSX', 'FOCUSY', 'FOCUSZ', 'NASMYTH_OFFSET_X', 'NASMYTH_OFFSET_Y', $
            'P2COR', 'P7COR', 'AZ_SOURCE', 'EL_SOURCE', 'NSUBSCANS', 'N_OBS', 'SCAN_NUM', 'NSCAN', 'DAY', $,
            'RESULT_SCAN_TIME', 'RESULT_TOTAL_OBS_TIME', 'RESULT_VALID_OBS_TIME', $
            'RESULT_NKIDS_VALID1', 'RESULT_NKIDS_VALID2', 'RESULT_NKIDS_VALID3', $
            'RESULT_NKIDS_TOT1', 'RESULT_NKIDS_TOT2', 'RESULT_NKIDS_TOT3', 'RESULT_ON_SOURCE_TIME_GEOM', $
            'MEDIAN_SCAN_SPEED', 'PHASE_HWPSS_SYNCHRO', 'A2_TO_A1_CM_CORR', 'A2_TO_A3_CM_CORR', 'MJD', 'PHASE_HWP', $
            'PHASE_HWPSS_A1_1', 'PHASE_HWPSS_A1_2', 'PHASE_HWPSS_A1_3', 'PHASE_HWPSS_A1_4', $
            'PHASE_HWPSS_A3_1', 'PHASE_HWPSS_A3_2', 'PHASE_HWPSS_A3_3', 'PHASE_HWPSS_A3_4', 'PHASE_HWP_MOTOR_POSITION', $
            'TOP_SYNCHRO_VALUE', 'PIPQ', $
            'SATURATED_KIDS_A1', 'SATURATED_KIDS_A2', 'SATURATED_KIDS_A3', $
            "IDENTICAL_FTONE_A1", "IDENTICAL_FTONE_A2", "IDENTICAL_FTONE_A3", $
            "NKIDS_OVERLAP_A1", "NKIDS_OVERLAP_A2", "NKIDS_OVERLAP_A3", $
            'COMMON_MODE_INTERPOLATED_SAMPLES', 'SUBSCAN_ARCSEC', 'SUBSCAN_STEP', 'SCAN_ANGLE', $
            'REF_DET_PROFILE_AZ_OFFSET', 'REF_DET_PROFILE_EL_OFFSET', 'CURRENT_SUBSCAN_NUM']
;;
;;

letter = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', $
          'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', $
          'q', 'r', 's', 't', 'u']
nlett = n_elements(letter)
for i=1, nlett-1 do tag_list = [tag_list, 'BOX_TIME_DIFF_MSEC_A'+strupcase(letter[i])]
for i=0, nlett-1 do tag_list = [tag_list, 'BOX_TIME_DIFF_MSEC_FRAC_ABOVE_1MSEC_A'+strupcase(letter[i])]
for i=0, nlett-1 do tag_list = [tag_list, 'FRAC_VALID_KIDS_BOX_'+strupcase(letter[i])]

for i=0, nlett-1 do tag_list = [tag_list, 'N_JUMP_OR_GLITCH_FLAGGED_SAMPLES_BOX'+strtrim(i,2)]

;; "eta" refers to the nominal number of kids per array, here I keep
;; trace of the kids that were "on" when reading the raw data and that
;; have been rejected during the processing.
for iarray=1, 3 do tag_list = [tag_list, "FRAC_VALID_KIDS_ARRAY_"+strtrim(iarray,2)]


;; String tags
string_tags = ['ROUTINE', 'ERROR_MESSAGE', 'OBS_TYPE', $
               'SYSTEMOF', 'OBJECT', 'SCAN',  'FOTRANSL', 'UT', $
               'CTYPE1', 'CTYPE2', 'ERROR_REPORT_FILE', 'MAP_PROJ', 'LOGFILE', 'ACQ_VERSION']

;;--------------------------------------------------------------------------------------------
;; Do not edit below this line

;; Sort by alphabetical order
tag_type_1 = replicate( 'double', n_elements(tag_list))
tag_type_2 = replicate( 'string', n_elements(string_tags))
all_tags = [tag_list, string_tags]
all_types = [tag_type_1, tag_type_2]
o = sort( all_tags)
all_tags = all_tags[o]
all_types = all_types[o]

;; ;; Create the structure
;; info = create_struct( tag_list[0], 0.d0)
;; for i=1, n_elements(tag_list)-1    do info = create_struct( info, tag_list[i], 0.d0)
;; for i=0, n_elements(string_tags)-1 do info = create_struct( info, string_tags[i], '')

info = create_struct( all_tags[0], all_types[0])
for i=1, n_elements(all_tags)-1 do begin
   if all_types[i] eq 'double' then begin
      info = create_struct( info, all_tags[i], 0.d0)
   endif else begin
      info = create_struct( info, all_tags[i], 'a')
   endelse
endfor

;; Init this one to something to avoid crashes when nk_error is called
;; somewhere else than in the pipeline
w = where( strupcase(all_tags) eq "ERROR_REPORT_FILE", nw)
if nw ne 0 then info.(w) = 'error_report.dat'

end
