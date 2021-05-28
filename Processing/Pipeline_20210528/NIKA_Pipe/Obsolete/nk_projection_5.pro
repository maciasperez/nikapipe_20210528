;+
;
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
;        nk_projection_5
;
; CATEGORY: 
;        projection
;
; CALLING SEQUENCE:
; 
; PURPOSE: 
;        same as nk_projection_3 but projects one map per array rather
;than one map per band
; 
; INPUT: 
;        - param: the reduction parameter structure
;        - info: the information parameter structure
;        - data: the data structure
;        - kidpar: the KID structure
;        - grid: the map and mask structure
; 
; OUTPUT: 
;        - info.map_1mm: the coadded data weighted by their inverse variance)
;        - info.map_w8_1mm: the sum of sample weights (inverse variance)
;        - info.nhits_1mm: the number of hits per pixel
;        - same for the 2mm
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - 15/03/2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;-

pro nk_projection_5, param, info, data, kidpar, grid

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_projection_3, param, info, data, kidpar, grid"
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then  message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

nsn = n_elements(data)

grid_tags = tag_names(grid)
if param.naive_projection eq 1 then begin

   ;; I loop on lambda and define temporary map, map_w8 and nhits to avoid a
   ;; loop over all kids and then test kid by kid the band to which it
   ;; belongs.
   for iarray=1, 3 do begin
      w1 = where(kidpar.type eq 1 and kidpar.array eq iarray, nw1)

      if nw1 ne 0 then begin
         ;; init (1mm and 2mm maps have the same size)
         map     = grid.xmap*0.d0
         map_w8  = grid.xmap*0.d0
         nhits   = grid.xmap*0.d0
         
         if info.polar ne 0 then begin
            map_q    = grid.xmap*0.d0
            map_u    = grid.xmap*0.d0
            map_w8_q = grid.xmap*0.d0
            map_w8_u = grid.xmap*0.d0
         endif

         ;; Limit projection of data around the center (temporary)
         if param.rmax_proj gt 0 then begin
            dd = sqrt( data.dra[w1]^2 + data.ddec[w1]^2)
            data.w8[w1] = data.w8[w1] * double( dd ge param.rmin_proj and dd le param.rmax_proj)
         endif

         ;; Define toi and w8 to speed up histograms and sums
         toi  = data.toi[w1]
         w8   = data.w8[ w1]
         ipix = data.ipix[w1]
         w = where( data.flag[w1] ne 0 or finite(data.w8[w1]) eq 0, nw)

         if nw ne 0 then ipix[w] = !values.d_nan ; for histogram
         w = where(ipix lt 0, nw)
         if nw ne 0 then ipix[w] = !values.d_nan
         w = where( finite( ipix) ne 1, nw)
         if nw eq n_elements( ipix) then begin
            nk_error, info, 'All ipix values are -1 or infinite (array '+strtrim(iarray,2)+')'
            return
         endif
         h = histogram( ipix, /nan, reverse_ind=R)
         p = lindgen( n_elements(h)) + long(min(ipix,/nan))

         if info.polar ne 0 then begin
            toi_q = data.toi_q[w1]
            toi_u = data.toi_u[w1]
            w8_q  = data.w8_q[ w1]
            w8_u  = data.w8_u[ w1]
         endif

         for j=0L, n_elements(h)-1 do begin
            if r[j] ne r[j+1] then begin
               index = R[R[j]:R[j+1]-1]
               map[   p[j]] += total( toi[index]*w8[index])
               map_w8[p[j]] += total(            w8[index])
               nhits[ p[j]] += R[j+1]-1 - R[j] + 1
               if info.polar ne 0 then begin
                  map_q[    p[j]] += total( toi_q[index]*w8_q[index])
                  map_u[    p[j]] += total( toi_u[index]*w8_u[index])
                  map_w8_q[ p[j]] += total(  w8_q[index])
                  map_w8_u[ p[j]] += total(  w8_u[index])
               endif
            endif
         endfor

         if iarray eq 1 or iarray eq 3 then begin
            grid.nhits_1mm  += nhits
            grid.map_w8_1mm += map_w8
            grid.map_i_1mm  += map_8*map
            if info.polar ne 0 then begin
               grid.map_q_1mm += map_w8_q*map_q
               grid.map_u_1mm += map_w8_u*map_u
            endif
         endif

         w = where( map_w8 ne 0, nw)
         if nw eq 0 then begin
            nk_error, info, "all pixels empty for array "+strtrim(iarray,2), /silent
            return
         endif else begin
            map[w] /= map_w8[w]
            if info.polar ne 0 then begin
               map_q[w] /= map_w8_q[w]
               map_u[w] /= map_w8_u[w]
            endif
         endelse

         wmap = where( strupcase(grid_tags) eq "MAP_I"+strtrim(iarray,2), nwmap)
         if nwmap eq 0 then message, "MAP_I"+strtrim(iarray,2)+" not found in grid structure"
         wvar = where( strupcase(grid_tags) eq "MAP_VAR_I"+strtrim(iarray,2), nwvar)
         if nwvar eq 0 then message, "MAP_VAR_I"+strtrim(iarray,2)+" not found in grid structure"
         wnhits = where( strupcase(grid_tags) eq "NHITS_"+strtrim(iarray,2), nwnhits)
         if nwnhits eq 0 then message, "NHITS_"+strtrim(iarray,2)+" not found in grid structure"
         ww8 = where( strupcase(grid_tags) eq "MAP_W8_I"+strtrim(iarray,2), nww8)
         if nww8 eq 0 then message, "MAP_W8_I"+strtrim(iarray,2)+" not found in grid structure"

         grid.(wmap)   = map
         grid.(wnhits) = nhits
         grid.(ww8)    = map_w8
         w = where( map_w8 ne 0,  nw, compl=wout, ncompl=nwout)
         if nw    ne 0 then map_w8[w]    = 1.d0/map_w8[w]
         if nwout ne 0 then map_w8[wout] = 0.d0
         grid.(wvar) = map_w8
            
         if info.polar ne 0 then begin
            wq = where( strupcase(grid_tags) eq "MAP_Q"+strtrim(iarray,2), nwq)
            if nwq eq 0 then message, "MAP_Q"+strtrim(iarray,2)+" not found in grid structure"

            wu = where( strupcase(grid_tags) eq "MAP_U"+strtrim(iarray,2), nwu)
            if nwu eq 0 then message, "MAP_U"+strtrim(iarray,2)+" not found in grid structure"

            wvarq = where( strupcase(grid_tags) eq "MAP_VAR_Q"+strtrim(iarray,2), nwvarq)
            if nwvarq eq 0 then message, "MAP_VAR_Q"+strtrim(iarray,2)+" not found in grid structure"
            
            wvaru = where( strupcase(grid_tags) eq "MAP_VAR_U"+strtrim(iarray,2), nwvaru)
            if nwvaru eq 0 then message, "MAP_VAR_U"+strtrim(iarray,2)+" not found in grid structure"

            ww8q = where( strupcase(grid_tags) eq "MAP_W8_Q"+strtrim(iarray,2), nww8q)
            if nww8q eq 0 then message, "MAP_W8_Q"+strtrim(iarray,2)+" not found in grid structure"
            
            ww8u = where( strupcase(grid_tags) eq "MAP_W8_U"+strtrim(iarray,2), nww8u)
            if nww8u eq 0 then message, "MAP_W8_U"+strtrim(iarray,2)+" not found in grid structure"

            grid.(wq)   = map_q
            grid.(wu)   = map_u
            grid.(ww8q) = map_w8_q
            grid.(ww8u) = map_w8_u
            w = where( map_w8 ne 0,  nw, compl=wout, ncompl=nwout)
            if nw    ne 0 then begin
               map_w8_q[w] = 1.d0/map_w8_q[w]
               map_w8_u[w] = 1.d0/map_w8_u[w]
            endif
            if nwout ne 0 then begin
               map_w8_q[wout] = 0.d0
               map_w8_u[wout] = 0.d0
            endif
            grid.(wvarq) = map_w8_q
            grid.(wvaru) = map_w8_u
         endif
         
      endif
   endfor
endif

if param.cpu_time then nk_show_cpu_time, param, "nk_projection_5"
end
