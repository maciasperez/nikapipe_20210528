
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_coadd_grids
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_coadd_grids, param, grid1, grid, grid_out
; 
; PURPOSE: 
;        Combine maps with inverse noise weighting
; 
; INPUT: 
; 
; OUTPUT: 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Nov. 28th, 2014: nk_coadd_sub, creation (Nicolas Ponthieu & Remi Adam -
;          adam@lpsc.in2p3.fr)
;        - Oct. 2015: NP
;-

pro nk_coadd_grids, param, info, grid_tot, grid

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_coadd_grids, param, info, grid_tot, grid"
   return
endif

;; Check that grid1 and grid2 are of the same form
grid_tags   = tag_names(grid_tot)
grid_tags_2 = tag_names(grid)
w = where( grid_tags ne grid_tags_2, nw)
if nw ne 0 then begin
   txt = "grid1 and grid2 have different tags and cannot be coadded."
   if param.silent eq 0 then message, /info, txt
   nk_error, info, txt
   return
endif

;; Check that they are of the same size and resolutions
if grid_tot.nx ne grid.nx or grid_tot.ny ne grid.ny or grid_tot.map_reso ne grid.map_reso then begin
   txt = "grid_tot and grid have different sizes or resolutions and cannot be coadded."
   if param.silent eq 0 then message, /info, txt
   nk_error, info, txt
   return
endif   

;; Main loop
stokes = ['I', 'Q', 'U']
for iarray=1, 3 do begin
   whits = where( strupcase(grid_tags) eq "NHITS_"+strtrim(iarray,2), nwhits)
   if max(grid.(whits)) gt 0 then begin
      w = where( grid.(whits) ne 0, nw)

      grid_tot.(whits) += grid.(whits)
      
      for istokes=0, 2 do begin
         wmap = where( strupcase(grid_tags) eq "MAP_"+stokes[istokes]+strtrim(iarray,2), nwmap)
         if nwmap ne 0 then begin

            if param.map_bg_var_w8 eq 1 then begin
               ;; Recompute the variance weights on the background of
               ;; the map rather than from the weighted TOI's
               wbg = where( grid.(whits) gt 0 and grid.mask_source eq 1, nwbg)
               if nwbg eq 0 then begin
                  nk_error, info, "No valid pix to estimate the weight (grid)."
                  return
               endif
               w8_1    = grid.(wmap)*0.d0
               hh      = sqrt( (grid.(whits))[wbg])*(grid.(wmap))[wbg]
               sigma   = stddev(hh)
               w8_1[w] = (grid.(whits))[w]/sigma^2
               
            endif else begin
               wvar = where( strupcase(grid_tags) eq "MAP_VAR_"+stokes[istokes]+strtrim(iarray,2), nwmap)
               w8_1 = grid.(wmap)*0.d0
               w8_1[w] = 1.d0/(grid.(wvar))[w]
            endelse

            w_w8 = where( strupcase(grid_tags) eq "MAP_W8_"+stokes[istokes]+strtrim(iarray,2), nwmap)
            grid_tot.(w_w8) += w8_1
            grid_tot.(wmap) += w8_1*grid.(wmap)
         endif
      endfor
   endif
endfor

end
