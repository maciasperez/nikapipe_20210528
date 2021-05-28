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


pro nk_map2fits_3, param, info, grid, suffix=suffix, output_fits_file=output_fits_file, $
                   header=header, scan_list=scan_list
;-  

if n_params() lt 1 then begin
   dl_unix, 'nk_map2fits_3'
   return
endif

;; Get pipeline revision number
;nk_get_svn_rev, rev


;; General information about the combined scans
output_info = {N_scan:fix(info.nscan), $
               total_obs_time:info.result_total_obs_time, $
               valid_obs_time:info.result_valid_obs_time, $
               f_sampling:!nika.f_sampling, $
               tau_260GHz_avg:info.result_tau_1mm, $
               tau_150GHz_avg:info.result_tau_2mm, $
               az:info.az_source*!radeg, $
               el:info.el_source*!radeg, $
               longobj:info.longobj, $
               latobj:info.latobj, $
               scan_type:info.obs_type, $
               polar:info.polar, $
               stbi1:info.result_sigma_boost_i1, $
               stbi2:info.result_sigma_boost_i2, $
               stbi3:info.result_sigma_boost_i3, $
               stbi1m:info.result_sigma_boost_i_1mm, $
               stbi2m:info.result_sigma_boost_i_2mm, $

               stbq1:info.result_sigma_boost_q1, $
               stbq2:info.result_sigma_boost_q2, $
               stbq3:info.result_sigma_boost_q3, $
               stbq1m:info.result_sigma_boost_q_1mm, $
               stbq2m:info.result_sigma_boost_q_2mm, $

               stbu1:info.result_sigma_boost_u1, $
               stbu2:info.result_sigma_boost_u2, $
               stbu3:info.result_sigma_boost_u3, $
               stbu1m:info.result_sigma_boost_u_1mm, $
               stbu2m:info.result_sigma_boost_u_2mm, $

               ;;keep these keywords for future reference
               fwhm_260Ghz:!nika.fwhm_nom[0], $ ; 12.5, $
               fwhm_150Ghz:!nika.fwhm_nom[1]} ; 18.5}; , $

;; nkids_tot1:info.result_nkids_tot1, $
               ;; nkids_tot2:info.result_nkids_tot2, $
               ;; nkids_tot3:info.result_nkids_tot3, $
               ;; nkids_valid1:info.result_nkids_valid1, $
               ;; nkids_valid2:info.result_nkids_valid2, $
               ;; nkids_valid3:info.result_nkids_valid3}

;; This is a duplicate of the info binary table... 
mkhdr, primaryHeader, '', /EXTEND
FOR I=0, N_TAGS(output_info)-1 DO $
   SXADDPAR, primaryHeader, (TAG_NAMES(output_info))[I], output_info.(I)

sxaddpar, primaryHeader, "N_scan", info.nscan

ext = '_v'+strtrim(param.version,2)+'.fits'
if keyword_set(suffix) then ext = "_"+strtrim(suffix,2)+ext

;; Write file
if not keyword_set(output_fits_file) then $
   output_fits_file = strtrim(param.output_dir,2)+'/MAPS_'+strtrim(param.name4file,2)+ext

;; @ Create an primaryHDU, could have lots and lots of header
fits_add_checksum, primaryHeader, /NO_TIMESTAMP
mwrfits, 0, output_fits_file, primaryHeader, /CREATE

;; @ Writes each map in a separate extension
if keyword_set(header) then begin
   putast_in_header = 0
   head_map = header
endif else begin
   putast_in_header = 1
endelse

grid_tags = tag_names(grid)
for lambda=1, 2 do begin

   if lambda eq 1 then begin
      wi = where( strupcase(grid_tags) eq "MAP_I_"+strtrim(lambda,2)+"MM", nwi)
      wvar  = where( strupcase(grid_tags) eq "MAP_VAR_I_"+strtrim(lambda,2)+"MM", nwvar)
      whits = where( strupcase(grid_tags) eq "NHITS_"+strtrim(lambda,2)+"MM", nwhits)
   endif else begin
      wi = where( strupcase(grid_tags) eq "MAP_I2", nwi)
      wvar  = where( strupcase(grid_tags) eq "MAP_VAR_I2", nwvar)
      whits = where( strupcase(grid_tags) eq "NHITS_2", nwhits)
   endelse
   
   if nwi ne 0 then begin

      if putast_in_header eq 1 then begin
         ;; @ If not provided in input, generates the
         ;; @^ astrometry structure and the header
         nk_grid2astrometry, grid, astrometry
         mkhdr, head_map, grid.(wi), /IMAGE
         nk_putast, head_map, astrometry, equinox=2000, cd_type=0 ;astrometry in header
      endif
      sxaddhist, "Data produced by the NIKA(2) Consortium", head_map, /comment
      sxaddpar, head_map, 'OBJECT', strtrim( info.object,2)
      sxaddpar, head_map, 'INSTRM', 'NIKA'
      sxaddpar, head_map, 'DATE-OBS', strmid(info.scan, 0, 4)+'-'+strmid(info.scan, 4, 2)+'-'+strmid(info.scan, 6, 2)+'T'+info.ut
      sxaddpar, head_map, 'PIPELINE', strtrim( systime(0),2)
      if lambda eq 1 then begin
         sxaddpar, head_map, 'BMAJ', !nika.fwhm_nom[0]/3600.d0
         sxaddpar, head_map, 'BMIN', !nika.fwhm_nom[0]/3600.d0
         sxaddpar, head_map, 'BPA', 0.d0
      endif else begin
         sxaddpar, head_map, 'BMAJ', !nika.fwhm_nom[1]/3600.d0
         sxaddpar, head_map, 'BMIN', !nika.fwhm_nom[1]/3600.d0
         sxaddpar, head_map, 'BPA', 0.d0
      endelse
      
      ;; Write the signal
      sxaddpar, head_map, 'EXTNAME', 'Brightness_'+strtrim(lambda,2)+'mm'
      sxaddpar, head_map, 'UNIT', 'Jy/beam'
      fits_add_checksum, head_map, grid.(wi),/NO_TIMESTAMP
      mwrfits, grid.(wi), output_fits_file, head_map, /silent

      ;; Noise map
      sxaddpar, head_map, 'EXTNAME', 'Stddev_'+strtrim(lambda,2)+'mm'
      sxaddpar, head_map, 'UNIT', 'Jy/beam'
      fits_add_checksum, head_map, sqrt(grid.(wvar)),/NO_TIMESTAMP
      mwrfits, sqrt(grid.(wvar)), output_fits_file, head_map, /silent
      
      ;; Hit count
      sxaddpar, head_map, 'EXTNAME', 'Nhits_'+strtrim(lambda,2)+'mm'
      sxaddpar, head_map, 'UNIT', 'None'
      fits_add_checksum, head_map, grid.(whits),/NO_TIMESTAMP
      mwrfits, grid.(whits), output_fits_file, head_map, /silent
   endif

   ;; Check if it's a polarized map
   wq    = where( strupcase(grid_tags) eq "MAP_Q_"+strtrim(lambda,2)+"MM", nwq)
   if nwq ne 0 then begin
      ;; We have a polar map
      wu    = where( strupcase(grid_tags) eq "MAP_U_"+strtrim(lambda,2)+"MM", nwu)
      wvarq = where( strupcase(grid_tags) eq "MAP_VAR_Q_"+strtrim(lambda,2)+"MM", nwq)
      wvaru = where( strupcase(grid_tags) eq "MAP_VAR_U_"+strtrim(lambda,2)+"MM", nwu)

      sxaddpar, head_map, 'EXTNAME', 'Brightness_Q_'+strtrim(lambda,2)+'mm'
      sxaddpar, head_map, 'UNIT', 'Jy/beam'
      fits_add_checksum, head_map, grid.(wq),/NO_TIMESTAMP
      mwrfits, grid.(wq), output_fits_file, head_map, /silent

      sxaddpar, head_map, 'EXTNAME', 'Stddev_Q_'+strtrim(lambda,2)+'mm'
      sxaddpar, head_map, 'UNIT', 'Jy/beam'
      fits_add_checksum, head_map, sqrt(grid.(wvarq)),/NO_TIMESTAMP
      mwrfits, sqrt(grid.(wvarq)), output_fits_file, head_map, /silent

      sxaddpar, head_map, 'EXTNAME', 'Brightness_U_'+strtrim(lambda,2)+'mm'
      sxaddpar, head_map, 'UNIT', 'Jy/beam'
      fits_add_checksum, head_map, grid.(wu),/NO_TIMESTAMP
      mwrfits, grid.(wu), output_fits_file, head_map, /silent

      sxaddpar, head_map, 'EXTNAME', 'Stddev_U_'+strtrim(lambda,2)+'mm'
      sxaddpar, head_map, 'UNIT', 'Jy/beam'
      fits_add_checksum, head_map, sqrt(grid.(wvaru)),/NO_TIMESTAMP
      mwrfits, sqrt(grid.(wvaru)), output_fits_file, head_map, /silent
   endif
endfor

;; Maps per array
for iarray=1, 3 do begin

   ;; LP: lines aboves to be moved ? 
   ;;if (iarray eq 1) or (iarray eq 3) then begin
   ;;   sxaddpar, head_map, 'BMAJ', !nika.fwhm_nom[0]/3600.d0
   ;;   sxaddpar, head_map, 'BMIN', !nika.fwhm_nom[0]/3600.d0
   ;;   sxaddpar, head_map, 'BPA', 0.d0
   ;;endif else begin
   ;;   sxaddpar, head_map, 'BMAJ', !nika.fwhm_nom[1]/3600.d0
   ;;   sxaddpar, head_map, 'BMIN', !nika.fwhm_nom[1]/3600.d0
   ;;   sxaddpar, head_map, 'BPA', 0.d0
   ;;endelse

   ;; Do not copy the infos for array2, already present in "2mm"
   ;; Put back the copy of A2 temporarily for old polarized tests
;   if iarray ne 2 then begin
      wi    = where( strupcase(grid_tags) eq "MAP_I"+strtrim(iarray,2), nwi)
      if nwi ne 0 then begin
         wvar  = where( strupcase(grid_tags) eq "MAP_VAR_I"+strtrim(iarray,2), nwvari)
         whits = where( strupcase(grid_tags) eq "NHITS_"+strtrim(iarray,2), nwhits)

         ;; LP begin
         if putast_in_header eq 1 then begin
            ;; @ If not provided in input, generates the
            ;; @^ astrometry structure and the header
            nk_grid2astrometry, grid, astrometry
            mkhdr, head_map, grid.(wi), /IMAGE
            nk_putast, head_map, astrometry, equinox=2000, cd_type=0 ;astrometry in header
         endif
         ;;mkhdr, head_map, grid.(wi), /IMAGE
         ;; LP end
         
         sxaddhist, "Data produced by the NIKA(2) Consortium", head_map, /comment
         sxaddpar, head_map, 'OBJECT', strtrim( info.object,2)
         sxaddpar, head_map, 'INSTRM', 'NIKA'
         sxaddpar, head_map, 'DATE-OBS', strmid(info.scan, 0, 4)+'-'+strmid(info.scan, 4, 2)+'-'+strmid(info.scan, 6, 2)+'T'+info.ut
         sxaddpar, head_map, 'PIPELINE', strtrim( systime(0),2)
         ;; LP: moved lines above here 
         if (iarray eq 1) or (iarray eq 3) then begin
            sxaddpar, head_map, 'BMAJ', !nika.fwhm_nom[0]/3600.d0
            sxaddpar, head_map, 'BMIN', !nika.fwhm_nom[0]/3600.d0
            sxaddpar, head_map, 'BPA', 0.d0
         endif else begin
            sxaddpar, head_map, 'BMAJ', !nika.fwhm_nom[1]/3600.d0
            sxaddpar, head_map, 'BMIN', !nika.fwhm_nom[1]/3600.d0
            sxaddpar, head_map, 'BPA', 0.d0
         endelse
         ;; end LP
         
         ;; LP begin
         ;;if putast_in_header eq 1 then begin
         ;;     nk_putast, head_map, astrometry, equinox=2000, cd_type=0 ;astrometry in header
         ;;endif
         ;; LP end
         
         ;; Write the signal
         sxaddpar, head_map, 'EXTNAME', 'Brightness_'+strtrim(iarray,2)
         sxaddpar, head_map, 'UNIT', 'Jy/beam'
         fits_add_checksum, head_map, grid.(wi),/NO_TIMESTAMP
         mwrfits, grid.(wi), output_fits_file, head_map, /silent

         ;; Noise map
         sxaddpar, head_map, 'EXTNAME', 'Stddev_'+strtrim(iarray,2)
         sxaddpar, head_map, 'UNIT', 'Jy/beam'
         fits_add_checksum, head_map, sqrt(grid.(wvar)),/NO_TIMESTAMP
         mwrfits, sqrt(grid.(wvar)), output_fits_file, head_map, /silent
         
         ;; Hit count
         sxaddpar, head_map, 'EXTNAME', 'Nhits_'+strtrim(iarray,2)
         sxaddpar, head_map, 'UNIT', 'None'
         fits_add_checksum, head_map, grid.(whits),/NO_TIMESTAMP
         mwrfits, grid.(whits), output_fits_file, head_map, /silent
      endif

      ;; Check if it's a polarized map
      wq    = where( strupcase(grid_tags) eq "MAP_Q"+strtrim(iarray,2), nwq)
      if nwq ne 0 then begin
         ;; We have a polar map
         wu    = where( strupcase(grid_tags) eq "MAP_U"+strtrim(iarray,2), nwu)
         wvarq = where( strupcase(grid_tags) eq "MAP_VAR_Q"+strtrim(iarray,2), nwq)
         wvaru = where( strupcase(grid_tags) eq "MAP_VAR_U"+strtrim(iarray,2), nwu)

         sxaddpar, head_map, 'EXTNAME', 'Brightness_Q'+strtrim(iarray,2)
         sxaddpar, head_map, 'UNIT', 'Jy/beam'
         fits_add_checksum, head_map, grid.(wq),/NO_TIMESTAMP
         mwrfits, grid.(wq), output_fits_file, head_map, /silent

         sxaddpar, head_map, 'EXTNAME', 'Stddev_Q'+strtrim(iarray,2)
         sxaddpar, head_map, 'UNIT', 'Jy/beam'
         fits_add_checksum, head_map, sqrt(grid.(wvarq)),/NO_TIMESTAMP
         mwrfits, sqrt(grid.(wvarq)), output_fits_file, head_map, /silent

         sxaddpar, head_map, 'EXTNAME', 'Brightness_U'+strtrim(iarray,2)
         sxaddpar, head_map, 'UNIT', 'Jy/beam'
         fits_add_checksum, head_map, grid.(wu),/NO_TIMESTAMP
         mwrfits, grid.(wu), output_fits_file, head_map, /silent

         sxaddpar, head_map, 'EXTNAME', 'Stddev_U'+strtrim(iarray,2)
         sxaddpar, head_map, 'UNIT', 'Jy/beam'
         fits_add_checksum, head_map, sqrt(grid.(wvaru)),/NO_TIMESTAMP
         mwrfits, sqrt(grid.(wvaru)), output_fits_file, head_map, /silent
      endif
 ;  endif
endfor

;; @ Also give the decorrelation mask at 1 and 2mm
;; mkhdr, head_map, grid.mask_source_1mm, /IMAGE           ; typical header
sxaddpar, head_map, 'EXTNAME', 'Decorrelation_mask_1mm'
sxaddpar, head_map, 'UNIT', 'long'
mwrfits, grid.mask_source_1mm, output_fits_file, head_map, /silent

;;mkhdr, head_map, grid.mask_source_2mm, /IMAGE           ; typical header
sxaddpar, head_map, 'EXTNAME', 'Decorrelation_mask_2mm'
sxaddpar, head_map, 'UNIT', 'long'
mwrfits, grid.mask_source_2mm, output_fits_file, head_map, /silent

;; @add zero level masks
sxaddpar, head_map, 'EXTNAME', 'Zero_level_mask_1mm'
sxaddpar, head_map, 'UNIT', 'long'
mwrfits, grid.zero_level_mask_1mm, output_fits_file, head_map, /silent
sxaddpar, head_map, 'EXTNAME', 'Zero_level_mask_2mm'
sxaddpar, head_map, 'UNIT', 'long'
mwrfits, grid.zero_level_mask_2mm, output_fits_file, head_map, /silent

;; @ give the pipeline parameters
fxbhmake, param_header, n_tags(param), 'Param'
mwrfits, param, output_fits_file, param_header, /silent

;; Special case for the last extension
;; @ and auxillary information
fxbhmake, param_header, n_tags(output_info), 'Info'
mwrfits, output_info, output_fits_file, param_header, /silent

;; ;; @ add the list of scans that have been combined to produce these
;; ;; @^ maps if scan_list was provided as input keyword
;; if keyword_set(scan_list) then begin
;;    fxbhmake, scan_list_header, n_elements(scan_list), 'scan_list'
;;    mwrfits, scan_list, output_fits_file, scan_list_header, /silent
;; endif else begin
;;    fxbhmake, scan_list_header, 1, 'scan_list'
;;    mwrfits, info.scan, output_fits_file, scan_list_header, /silent
;; endelse

if param.silent le 1 then message, /info, "Wrote "+strtrim(output_fits_file,2)

end
