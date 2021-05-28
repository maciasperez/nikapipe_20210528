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


pro nk_map2fits_2, param, info, grid, suffix=suffix, $
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

;; ;; General information about the combined scans
output_info = {N_scan:fix(info.nscan), $
               total_obs_time:info.result_total_obs_time, $
               valid_obs_time:info.result_valid_obs_time, $
               f_sampling:!nika.f_sampling, $
               tau_260GHz_avg:info.result_tau_1mm, $
               tau_150GHz_avg:info.result_tau_2mm, $
               az:info.az_source*!radeg, $
               el:info.el_source*!radeg, $
               scan_type:info.obs_type, $
               fwhm_260Ghz:12.5, $
               fwhm_150Ghz:18.5, $
               nkids_tot1:info.result_nkids_tot1, $
               nkids_tot2:info.result_nkids_tot2, $
               nkids_tot3:info.result_nkids_tot3, $
               nkids_valid1:info.result_nkids_valid1, $
               nkids_valid2:info.result_nkids_valid2, $
               nkids_valid3:info.result_nkids_valid3}

mkhdr, primaryHeader, '',/EXTEND
FOR I=0, N_TAGS(output_info)-1 DO $
   SXADDPAR, primaryHeader, (TAG_NAMES(output_info))[I], output_info.(I)

sxaddpar, primaryHeader, "N_scan", info.nscan

ext = '_v'+strtrim(param.version,2)+'.fits'
if keyword_set(suffix) then ext = "_"+strtrim(suffix,2)+ext

;; Write the 1mm results if present
grid_tags = tag_names(grid)
for lambda=1, 2 do begin
   wi = where( strupcase(grid_tags) eq "MAP_I_"+strtrim(lambda,2)+"MM", nwi)
   if nwi ne 0 then begin
      file = strtrim(param.output_dir,2)+'/MAPS_'+strtrim(lambda,2)+'mm_'+strtrim(param.name4file,2)+ext          
      if lambda eq 1 then output_file_1mm = file else output_file_2mm=file
      mwrfits, 0, file, primaryHeader, /CREATE ;; Create an primaryHDU, could have lots and lots of header
      
      wvari = where( strupcase(grid_tags) eq "MAP_VAR_I_"+strtrim(lambda,2)+"MM", nwvari)
      whits = where( strupcase(grid_tags) eq "NHITS_"+strtrim(lambda,2)+"MM", nwhits)

      wq    = where( strupcase(grid_tags) eq "MAP_Q_"+strtrim(lambda,2)+"MM", nwq)
      if nwq ne 0 then begin
         ;; We have a polar map
         wu    = where( strupcase(grid_tags) eq "MAP_U_"+strtrim(lambda,2)+"MM", nwu)
         wvarq = where( strupcase(grid_tags) eq "MAP_VAR_Q_"+strtrim(lambda,2)+"MM", nwq)
         wvaru = where( strupcase(grid_tags) eq "MAP_VAR_U_"+strtrim(lambda,2)+"MM", nwu)

         map = [ [[grid.(wi)]], [[grid.(wq)]], [[grid.(wu)]] ]
         std = [ [[sqrt(grid.(wvari))]], [[sqrt(grid.(wvarq))]], [[grid.(wvaru)]] ]
      
         mkhdr, head_map, map, /EXTEND, /IMAGE ; typical header
         sxaddpar,  head_map, 'CTYPE3', 'STOKES'
         sxaddpar,  head_map, 'CRVAL3', 1.
         sxaddpar,  head_map, 'CDELT3', 1.
         sxaddpar,  head_map, 'CRPIX3', 1.
         sxaddpar,  head_map, 'CROTA3', 0.
      ENDIF ELSE BEGIN
         ;; No polar
         map = grid.(wi)
         std = sqrt(grid.(wvari))
         mkhdr, head_map, map, /EXTEND, /IMAGE ; typical header
      ENDELSE

      sxaddhist, "Data produced by the NIKA(2) Consortium", head_map, /comment
      sxaddpar, head_map, 'OBJECT', strtrim( info.object,2)
      sxaddpar, head_map, 'INSTRM', 'NIKA'
      sxaddpar, head_map, 'DATE-OBS', strmid( param.scan, 0, 8)
      sxaddpar, head_map, 'PIPELINE', strtrim( systime(0),2)
      
      ;; Now write the signal ...
      ;; ext 1
      putast, head_map, astrometry, equinox=2000, cd_type=0 ;astrometry in header
      sxaddpar, head_map, 'EXTNAME', 'Brightness'
      sxaddpar, head_map, 'UNIT', 'Jy/beam'
      mwrfits, map, file, head_map, /silent

      ;; ... and the std maps
      ;; ext 2
      sxaddpar, head_map, 'EXTNAME', 'Stddev'
      mwrfits, std, file, head_map, /silent

      ;; Special case for the hit map, always the same for all stokes
      ;; ext 3
      mkhdr, head_map, grid.(whits), /EXTEND, /IMAGE        ; typical header
      putast, head_map, astrometry, equinox=2000, cd_type=0 ;astrometry in header
      sxaddpar, head_map, 'EXTNAME', 'Time per map pixel'
      sxaddpar, head_map, 'UNIT', 'second'
      sxaddpar, head_map, 'SAMPL_Hz', !nika.f_sampling
      mwrfits, grid.(whits)/!nika.f_sampling, file, head_map, /silent

      ;; Decorrelation mask
      ;; ext 4
      mkhdr, head_map, grid.mask_source, /EXTEND,/IMAGE  ; typical header
      putast, head_map, astrometry, equinox=2000, cd_type=0 ;astrometry in header
      sxaddpar, head_map, 'EXTNAME', 'decorrelation mask'
      sxaddpar, head_map, 'UNIT', 'long'
      mwrfits, grid.mask_source, file, head_map, /silent

      ;; Add maps per array for NIKA2 if relevant
      ;; ext 5
      if lambda eq 1 then begin
         for iarray=1,3 do begin
            if iarray ne 2 then begin
               wi = where( strupcase(grid_tags) eq "MAP_I"+strtrim(iarray,2), nwi)
               if nwi ne 0 then begin
                  wvari = where( strupcase(grid_tags) eq "MAP_VAR_I"+strtrim(iarray,2), nwvari)
                  whits = where( strupcase(grid_tags) eq "NHITS_"+strtrim(iarray,2), nwhits)

                  wq    = where( strupcase(grid_tags) eq "MAP_Q"+strtrim(iarray,2), nwq)
                  if nwq ne 0 then begin
                     ;; We have a polar map
                     wu    = where( strupcase(grid_tags) eq "MAP_U"+strtrim(iarray,2), nwu)
                     wvarq = where( strupcase(grid_tags) eq "MAP_VAR_Q"+strtrim(iarray,2), nwq)
                     wvaru = where( strupcase(grid_tags) eq "MAP_VAR_U"+strtrim(iarray,2), nwu)

                     map = [ [[grid.(wi)]], [[grid.(wq)]], [[grid.(wu)]] ]
                     std = [ [[sqrt(grid.(wvari))]], [[sqrt(grid.(wvarq))]], [[grid.(wvaru)]] ]
      
                     mkhdr, head_map, map, /EXTEND, /IMAGE ; typical header
                     sxaddpar,  head_map, 'CTYPE3', 'STOKES'
                     sxaddpar,  head_map, 'CRVAL3', 1.
                     sxaddpar,  head_map, 'CDELT3', 1.
                     sxaddpar,  head_map, 'CRPIX3', 1.
                     sxaddpar,  head_map, 'CROTA3', 0.
                  ENDIF ELSE BEGIN
                     ;; No polar
                     map = grid.(wi)
                     std = sqrt(grid.(wvari))
                     mkhdr, head_map, map, /EXTEND, /IMAGE ; typical header
                  ENDELSE
               endif
            endif else begin ; (FXD 23/01/2016) case of array 2 which is non existent here
               map = map*0.
               std = std*0.
            endelse

 
            sxaddpar, head_map, 'EXTNAME', 'Brightness_'+strtrim(iarray,2)
            sxaddpar, head_map, 'UNIT', 'Jy/beam'
            mwrfits, map, file, head_map, /silent

            sxaddpar, head_map, 'EXTNAME', 'Stddev_'+strtrim(iarray,2)
            mwrfits, std, file, head_map, /silent

            mkhdr, head_map, grid.(whits), /EXTEND, /IMAGE  ; typical header
            putast, head_map, astrometry, equinox=2000, cd_type=0 ;astrometry in header
            sxaddpar, head_map, 'EXTNAME', 'Time per map pixel'
            sxaddpar, head_map, 'UNIT', 'second'
            sxaddpar, head_map, 'SAMPL_Hz', !nika.f_sampling
            mwrfits, grid.(whits)/!nika.f_sampling, file, head_map, /silent

         endfor
      endif

      ;; Pipeline parameters
      ;; ext 5 or 6
      header = ["EXTNAME = Param", $
                "DUMMY   = MWRFITS bug does not take this line"] 
      mwrfits, param, file, header, /silent
      
      ;; Special case for the last extension
      header = ["EXTNAME = Info", $
                "DUMMY   = MWRFITS bug does not take this line"] 
      mwrfits, output_info, file, header, /silent

      if param.silent ne 1 then message, /info, "Wrote "+strtrim(file,2)
   endif
endfor

end
