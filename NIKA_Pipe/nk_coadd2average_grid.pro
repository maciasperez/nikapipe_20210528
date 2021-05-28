
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_coadd2average_grid
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_coadd2average_grid, grid
; 
; PURPOSE: 
;        Converts coadded signal and weights into final signal maps
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
;        - Oct. 2015: NP
;-

pro nk_coadd2average_grid, grid, grid_avg

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   nk_coadd2average_grid, grid
   return
endif

;; Init
grid_avg = grid

grid_tags = tag_names(grid_avg)
stokes = ['I', 'Q', 'U']
;; Main loop
for iarray=1, 3 do begin
   whits = where( strupcase(grid_tags) eq "NHITS_"+strtrim(iarray,2), nwhits)
   if max(grid.(whits)) gt 0 then begin
      w = where( grid.(whits) ne 0, nw, compl=wout, ncompl=nwout)

      for istokes=0, 2 do begin
         wmap = where( strupcase(grid_tags) eq "MAP_"+stokes[istokes]+strtrim(iarray,2), nwmap)
         if nwmap ne 0 then begin
            wvar = where( strupcase(grid_tags) eq "MAP_VAR_"+stokes[istokes]+strtrim(iarray,2), nwmap)
            w_w8 = where( strupcase(grid_tags) eq "MAP_W8_"+stokes[istokes]+strtrim(iarray,2), nwmap)

            ;;IDL forces me into the use of junk as a temporary buffer
            junk = grid_avg.xmap*0.d0
            junk[w] = 1.d0/(grid.(w_w8))[w]
            grid_avg.(wvar) = junk

            junk = junk*0.d0
            junk[w] = (grid.(wmap))[w]/(grid.(w_w8))[w]
            if nwout ne 0 then junk[wout] = 0.d0            
            grid_avg.(wmap) = junk
            
         endif
      endfor
   endif
endfor

end
