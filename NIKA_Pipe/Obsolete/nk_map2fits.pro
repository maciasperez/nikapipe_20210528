;+
;
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
;        nk_map2fits
;
; CATEGORY: 
;        products
;
; CALLING SEQUENCE:
;        nk_map2fits, param, info, maps
; 
; PURPOSE: 
;        Save the maps as FITS products
; 
; INPUT: 
;        - param: the reduction parameter structure
;        - info: the information parameter structure
;        - maps: the map structure (optional as input)
; 
; OUTPUT: 
;        - The maps are saved as fits
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - 17/03/2014: creation (Nicolas Ponthieu & Remi Adam -
;          adam@lpsc.in2p3.fr)
;        - 26/01/2015: A. Beelen: make the .fits more standard
;        - 27/01/2015: L. Perotto: minor debugging
;        - 28/10/2015: F. Mayet, J Macias-Perez, update for 3 arrays
;-


pro nk_map2fits, param, info, grid, suffix=suffix, $
                 output_file_1mm=output_file_1mm, $
                 output_file_2mm=output_file_2mm
  
if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_map2fits, param, info,grid"
   return
endif

;; Get pipeline revision number
;nk_get_svn_rev, rev

;; Astrometry structure
nk_grid2astrometry, param, grid, astrometry

;; General information about the combined scans
output_info_1mm= {N_scan: fix(info.nscan), $
                  total_obs_time:info.result_total_obs_time, $
                  tau_260GHz_avg:info.result_tau_1mm, $
                  tau_150GHz_avg:info.result_tau_2mm, $
                  az:info.az_source*!radeg, $
                  el:info.el_source*!radeg, $
                  scan_type:info.obs_type, $
                  fwhm_260Ghz:12.5}  ; should be improved (FXD)

output_info_2mm= {N_scan:fix(info.nscan), $
                  total_obs_time:info.result_total_obs_time, $
                  tau_260GHz_avg:info.result_tau_1mm, $
                  tau_150GHz_avg:info.result_tau_2mm, $
                  az:info.az_source*!radeg, $
                  el:info.el_source*!radeg, $
                  scan_type:info.obs_type, $
                  fwhm_150Ghz:18.5}

mkhdr, primaryHeader, '',/EXTEND
FOR I=0, N_TAGS(output_info)-1 DO $
   SXADDPAR,primaryHeader, (TAG_NAMES(output_info))[I], output_info.(I)

sxaddpar, primaryHeader, "N_scan", info.nscan

ext = '_v'+strtrim(param.version,2)+'.fits'
if keyword_set(suffix) then ext = "_"+strtrim(suffix,2)+ext

;; Write the 1mm results if present
if tag_exist( grid, 'map_i_1mm') then begin
   file = strtrim(param.output_dir,2)+'/MAPS_1mm_'+strtrim(param.name4file,2)+ext          
   output_file_1mm = file
   mwrfits, 0, file, primaryHeader, /CREATE ;; Create an primaryHDU, could have lots and lots of header

   IF tag_exist(grid, 'map_q_1mm') OR tag_exist(grid, 'map_u_1mm') THEN BEGIN
      ;; We have a polar map
      map = [ [[grid.map_i_1mm]], [[grid.map_i_1mm*!VALUES.F_NAN]], [[grid.map_i_1mm*!VALUES.F_NAN]] ]
      std = [ [[sqrt(grid.map_var_i_1mm)]], [[grid.map_i_1mm*!VALUES.F_NAN]], [[grid.map_i_1mm*!VALUES.F_NAN]] ]
      IF tag_exist( grid, 'map_q_1mm') THEN BEGIN
         map[*,*,1] = grid.map_q_1mm
         std[*,*,1] = sqrt(grid.map_var_q_1mm)
      ENDIF
      IF tag_exist( grid, 'map_u_1mm') THEN BEGIN
         map[*,*,2] = grid.map_u_1mm
         std[*,*,2] = sqrt(grid.map_var_u_1mm)
      ENDIF
      
      mkhdr, head_map, map,/EXTEND,/IMAGE ; typical header
      sxaddpar,  head_map, 'CTYPE3', 'STOKES'
      sxaddpar,  head_map, 'CRVAL3', 1.
      sxaddpar,  head_map, 'CDELT3', 1.
      sxaddpar,  head_map, 'CRPIX3', 1.
      sxaddpar,  head_map, 'CROTA3', 0.
   ENDIF ELSE BEGIN
      ;; No polar
      map = grid.map_i_1mm
      std = sqrt(grid.map_var_i_1mm)
      mkhdr, head_map, map,/EXTEND,/IMAGE ; typical header
   ENDELSE
   sxaddhist, "Data produced by the NIKA(2) Consortium", head_map, /comment
   sxaddpar, head_map, 'OBJECT', strtrim( info.object,2)
   sxaddpar, head_map, 'INSTRM', 'NIKA_1mm'
   sxaddpar, head_map, 'DATE-OBS', strmid( param.scan, 0, 8)
;   sxaddpar,  head_map, 'NKP_VER', rev ; SVN revision number used to produce this map
   sxaddpar, head_map, 'PIPELINE', strtrim( systime(0),2)
   
   ;; Now write the signal ...
   putast, head_map, astrometry, equinox=2000, cd_type=0 ;astrometry in header
   sxaddpar, head_map, 'EXTNAME', 'Brightness'
   sxaddpar, head_map, 'UNIT', 'Jy/beam'
   mwrfits, map, file, head_map, /silent

   ;; ... and the std maps
   sxaddpar, head_map, 'EXTNAME', 'Stddev'
   mwrfits, std, file, head_map, /silent

   ;; Special case for the hit map, always the same for all stokes ?!?
   mkhdr, head_map, grid.nhits_1mm,/EXTEND,/IMAGE ; typical header
   putast, head_map, astrometry, equinox=2000, cd_type=0 ;astrometry in header
   sxaddpar, head_map, 'EXTNAME', 'Time per pixel map'
   sxaddpar, head_map, 'UNIT', 'second'
   
   mwrfits, grid.nhits_1mm/!nika.f_sampling, file, head_map, /silent

   ;; Decorrelation mask
   mkhdr, head_map, grid.mask_source, /EXTEND,/IMAGE ; typical header
   putast, head_map, astrometry, equinox=2000, cd_type=0 ;astrometry in header
   sxaddpar, head_map, 'EXTNAME', 'decorrelation mask'
   sxaddpar, head_map, 'UNIT', 'long'
   mwrfits, grid.mask_source, file, head_map, /silent

   ;; Pipeline parameters
   header = ["EXTNAME = Param", $
             "DUMMY   = MWRFITS bug does not take this line"] 
   mwrfits, param, file, header, /silent

   ;; Special case for the last extension
   header = ["EXTNAME = Info", $
             "DUMMY   = MWRFITS bug does not take this line"] 
   mwrfits, output_info_1mm, file, header, /silent

   if param.silent ne 1 then message, /info, "Wrote "+strtrim(file,2)
endif

;; Write the 2mm results if present
if tag_exist( grid, 'map_i_2mm') then begin
   file = strtrim(param.output_dir,2)+'/MAPS_2mm_'+strtrim(param.name4file,2)+ext          
   output_file_2mm = file
   mwrfits, 0, file, primaryHeader, /CREATE ;; Create an primaryHDU, could have lots and lots of header
   
   IF tag_exist(grid, 'map_q_2mm') OR tag_exist(grid, 'map_u_2mm') THEN BEGIN
      ;; We have a polar map
      map = [ [[grid.map_i_2mm]], [[grid.map_i_2mm*!VALUES.F_NAN]], [[grid.map_i_2mm*!VALUES.F_NAN]] ]
      std = [ [[sqrt(grid.map_var_i_2mm)]], [[grid.map_i_2mm*!VALUES.F_NAN]], [[grid.map_i_2mm*!VALUES.F_NAN]] ]
      IF tag_exist( grid, 'map_q_2mm') THEN BEGIN
         map[*,*,1] = grid.map_q_2mm
         std[*,*,1] = sqrt(grid.map_var_q_2mm)
      ENDIF
      IF tag_exist( grid, 'map_u_2mm') THEN BEGIN
         map[*,*,2] = grid.map_u_2mm
         std[*,*,2] = sqrt(grid.map_var_u_2mm)
      ENDIF
      
      mkhdr, head_map, map,/EXTEND,/IMAGE ; typical header
      sxaddpar, head_map, 'CTYPE3', 'STOKES'
      sxaddpar, head_map, 'CRVAL3', 1.
      sxaddpar, head_map, 'CDELT3', 1.
      sxaddpar, head_map, 'CRPIX3', 1.
      sxaddpar, head_map, 'CROTA3', 0.
   ENDIF ELSE BEGIN
      ;; No polar
      map = grid.map_i_2mm
      std = sqrt(grid.map_var_i_2mm)
      mkhdr, head_map, map,/EXTEND,/IMAGE ; typical header
   ENDELSE
   sxaddhist, "Data produced by the NIKA(2) Consortium", head_map, /comment
   sxaddpar, head_map, 'OBJECT', strtrim( info.object,2)
   sxaddpar, head_map, 'INSTRM', 'NIKA_2mm'
   sxaddpar, head_map, 'DATE-OBS', strmid( param.scan, 0, 8)
;   sxaddpar, head_map, 'NKP_VER', rev ; SVN revision number used to produce this map
   sxaddpar, head_map, 'PIPELINE', strtrim( systime(0),2)
   
   ;; Now write the signal ...
   putast, head_map, astrometry, equinox=2000, cd_type=0 ;astrometry in header
   sxaddpar, head_map, 'EXTNAME', 'Brightness'
   sxaddpar, head_map, 'UNIT', 'Jy/beam'
   mwrfits, map, file, head_map, /silent
   
   ;; ... and the std maps
   sxaddpar, head_map, 'EXTNAME', 'Stddev'
   mwrfits, std, file, head_map, /silent
   
   ;; Special case for the hit map, always the same for all stokes ?!?
   mkhdr, head_map, grid.nhits_2mm,/EXTEND,/IMAGE        ; typical header
   putast, head_map, astrometry, equinox=2000, cd_type=0 ;astrometry in header
   sxaddpar, head_map, 'EXTNAME', 'Time per pixel map'
   sxaddpar, head_map, 'UNIT', 'second'
   
   mwrfits, grid.nhits_2mm/!nika.f_sampling, file, head_map, /silent
   
   ;; Decorrelation mask
   mkhdr, head_map, grid.mask_source, /EXTEND,/IMAGE ; typical header
   putast, head_map, astrometry, equinox=2000, cd_type=0 ;astrometry in header
   sxaddpar, head_map, 'EXTNAME', 'decorrelation mask'
   sxaddpar, head_map, 'UNIT', 'long'
   mwrfits, grid.mask_source, file, head_map, /silent

   ;; Pipeline parameters
   header = ["EXTNAME = Param", $
             "DUMMY   = MWRFITS bug does not take this line"] 
   mwrfits, param, file, header, /silent

   ;; Special case for the last extension
   header = ["EXTNAME = Info", $
             "DUMMY   = MWRFITS bug does not take this line"] 
   mwrfits, output_info_2mm, file, header, /silent
   if param.silent ne 1 then message, /info, "Wrote "+strtrim(file,2)
endif

end
