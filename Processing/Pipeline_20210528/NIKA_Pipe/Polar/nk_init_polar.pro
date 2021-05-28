;+
;
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
;        nk_init_polar
;
; CATEGORY: 
;        general, initialization
;
; CALLING SEQUENCE:
;         nk_init_polar, scan_list_in, param, info, [FORCE=]
; 
; PURPOSE: 
;        Create the parameter structure from the scan list
; 
; INPUT: 
;        the list of scans to be used as a string vector
;        e.g. ['20140221s0024', '20140221s0025', '20140221s0026']
; 
; OUTPUT: 
;        the parameter structure used in the reduction
; 
; KEYWORDS:
;        - FORCE: Use this keyword to force the list of scans used
;          instead of checking if they are valid
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - 17/06/2014: creation Alessia Ritacco & Nicolas Ponthieu
;        - Needs simplifications otherwise it gets messy when we combine several
;          scans. I remove per scan info (pressure, humidity...). If anyone is
;          interested in this, he'll parse the imbfits outside the pipeline, this
;          if of no relevance in the middle of the combination of several scans. NP, June 13th, 2014


pro nk_init_polar, scan_list_in, param, info, $
                   DECOR=DECOR, $
                   HEADER=HEADER, $
                   NOPLOT=NOPLOT, $
                   NOLOGTERM=NOLOGTERM, $
                   MAP_PER_KID=MAP_PER_KID, $
                   PROJECTION=PROJECTION, $
                   PARAM_USER=PARAM_USER, $
                   RESET_MAP=RESET_MAP, $
                   MAKE_TOI=MAKE_TOI, $
                   MAKE_UNIT_CONV=MAKE_UNIT_CONV, $
                   FORCE=FORCE, $
                   RESO=RESO, $
                   S_MAP=S_MAP, $
                   POLAR=POLAR
  
;;========== Create the parameter structure to be used in the following
if keyword_set(param_user) then begin
   param = param_user
endif else begin
   nk_default_param, param
endelse

param.scan     = scan_list_in

scan2daynum, scan_list_in, day, scan_num
param.scan_num = scan_num
param.day      = day

nk_find_raw_data_file, scan_num, day, file, imb_fits_file, xml_file, /silent, noerror=noerror, xml=xml
param.file_raw      = file
param.file_imb_fits = imb_fits_file

nk_get_kidpar_ref, scan_num, day, kidpar_ref_file
param.file_kidpar = kidpar_ref_file

;;---------- Read the IMBFITS file
ant1 = mrdfits( imb_fits_file, 1, head_ant1, /silent)
ant2 = mrdfits( imb_fits_file, 2, head_ant2, /silent)

param.map_coord_pointing_ra  = sxpar(head_ant1,'longobj') 
param.map_coord_pointing_dec = sxpar(head_ant1,'latobj') 
param.map_pako_proj          = sxpar(head_ant2, "systemof")

param.sourcename = sxpar(head_ant1,'object')

nk_init_info_polar, param, info, /polar

nk_get_unit_conv, param, MAKE_UNIT_CONV=MAKE_UNIT_CONV

end
