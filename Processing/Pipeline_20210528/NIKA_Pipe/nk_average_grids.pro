
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_average_grids
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_average_grids, grid1, grid2, grid_avg
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
;        - Apr. 2015: NP, add sign=sign to allow subtraction (for
;          jacknife tests and /cumul in nk_average_scans)

pro nk_average_grids, grid1, grid2, grid_avg, $
                      sign=sign, silent=silent, $
                      extra_w81=extra_w81, extra_w82=extra_w82, $
                      bypass_unmatched_grid = bypass_unmatched_grid, $
                      no_variance_w8=no_variance_w8
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_average_grids'
   return
endif

if not keyword_set(sign) then sign = 1
if not keyword_set(extra_w81) then extra_w81 = 1.d0
if not keyword_set(extra_w82) then extra_w82 = 1.d0

;; Check that grid1 and grid2 are of the same form
grid_tags_1 = tag_names(grid1)
grid_tags_2 = tag_names(grid2)
w = where( grid_tags_1 ne grid_tags_2, nw)
if nw ne 0 then begin
   txt = "grid1 and grid2 have different tags and cannot be coadded."
   if not keyword_set(silent) then message, /info, txt
   if not keyword_set( bypass_unmatched_grid) then begin
      stop
      return
   endif
endif

;; Check that they are of the same size and resolutions
if grid1.nx ne grid2.nx then begin
   message, /info, "grid1.nx = "+strtrim(grid1.nx,2)+" /= grid2.nx = "+strtrim(grid2.nx,2)
   return
endif
if grid1.ny ne grid2.ny then begin
   message, /info, "grid1.ny = "+strtrim(grid1.ny,2)+" /= grid2.ny = "+strtrim(grid2.ny,2)
   return
endif
if float(grid1.map_reso) ne float(grid2.map_reso) then begin
   message, /info, "grid1.map_reso = "+strtrim(grid1.map_reso,2)+" /= grid2.map_reso = "+strtrim(grid2.map_reso,2)
   return
endif

;; Main loop
fields       = ['_1MM', '_2MM', '1', '2','3']
nhits_fields = [ '1MM',  '2MM', '1', '2','3']
stokes       = ['I', 'Q', 'U']
nfields      = n_elements(fields)

;; init
grid_avg   = grid1
grid_tags1 = tag_names(grid1)
grid_tags2 = tag_names(grid2)

;; Integration time
grid_avg.integ_time = grid1.integ_time + grid2.integ_time

;; Average sky signals
for ifield=0, nfields-1 do begin

   whits1 = where( strupcase(grid_tags1) eq "NHITS_"+nhits_fields[ifield], nh1)
   whits2 = where( strupcase(grid_tags2) eq "NHITS_"+nhits_fields[ifield], nh2)
   if nh1 ne 0 and nh2 ne 0 then grid_avg.(whits1) = grid1.(whits1) + grid2.(whits2)

   for istokes=0, 2 do begin
      wmap1 = where( strupcase(grid_tags1) eq "MAP_"+stokes[istokes]+fields[ifield], nwmap1)
      wmap2 = where( strupcase(grid_tags2) eq "MAP_"+stokes[istokes]+fields[ifield], nwmap2)

      if nwmap1 ne 0 and nwmap2 ne 0 then begin
         wvar1 = where( strupcase(grid_tags1) eq "MAP_VAR_"+stokes[istokes]+fields[ifield], nwvar1)
         wvar2 = where( strupcase(grid_tags2) eq "MAP_VAR_"+stokes[istokes]+fields[ifield], nwvar2)
         
         if keyword_set(no_variance_w8) then begin
            w81 = dblarr( grid1.nx, grid1.ny) + 1.d0
            w82 = dblarr( grid1.nx, grid1.ny) + 1.d0
         endif else begin
            w81 = dblarr( grid1.nx, grid1.ny)
            w = where( grid1.(wvar1) ne 0, nw)
            if nw ne 0 then w81[w] = 1.d0/(grid1.(wvar1))[w]
            
            w82 = dblarr( grid2.nx, grid2.ny)
            w = where( grid2.(wvar2) ne 0, nw)
            if nw ne 0 then w82[w] = 1.d0/(grid2.(wvar2))[w]
         endelse
         
         w8 = extra_w81*w81 + extra_w82*w82
         grid_avg.(wmap1) = extra_w81*w81*grid1.(wmap1) + extra_w82*w82*grid2.(wmap2)*sign

         w = where( w8 ne 0, nw)
         if nw ne 0 then begin
            map = grid_avg.(wmap1)
            map[w] /= w8[w]
            grid_avg.(wmap1) = map

            map = grid_avg.(wvar1)*0.d0
            map[w] = 1.d0/w8[w]
            grid_avg.(wvar1) = map
         endif

         ;; toi noise propagation for the record
         ww81 = where( strupcase(grid_tags1) eq "MAP_W8_"+stokes[istokes]+fields[ifield], nww81)
         ww82 = where( strupcase(grid_tags2) eq "MAP_W8_"+stokes[istokes]+fields[ifield], nww82)

         if nww81 ne 0 then begin
            w8final = grid1.xmap*0.d0
            w = where( grid1.(ww81) ne 0, nw)
            if nw ne 0 then w8final[w] += (grid1.(ww81))[w]
         endif

         if nww82 ne 0 then begin
            w = where( grid2.(ww82) ne 0, nw)
;;; This line seems wrong
            ;;; if nw ne 0 then w8final[w] += (grid2.(ww81))[w]
            ; FXD 6/3/2018 correction:
            if nw ne 0 then w8final[w] += (grid2.(ww82))[w]
            grid_avg.(ww81) += w8final
         endif

      endif
   endfor
endfor

end
