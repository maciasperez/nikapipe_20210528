;+
;
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
;        nk_projection_4
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
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - 15/03/2014: creation (Nicolas Ponthieu & Remi Adam)

pro nk_projection_4, param, info, data, kidpar, grid
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_projection_4'
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then  message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

if param.force_w8_to_1 ne 0 then data.w8 = 1.d0

;; if there are remaining NaN (in particular if method_num=676)
;; have to defined temporary arrays, otherwise indices in data.toi do
;; not match those of data.w8, God knows why...
toi = data.toi
w8  = data.w8
w   = where( finite(toi) ne 1, nw)
if nw ne 0 then begin
   w8[w] = 0.d0
   data.w8 = w8
endif
delvarx, toi, w8

grid_tags = tag_names(grid)
bg_mask = grid.xmap*0.d0

;; Reset output maps to make sure there's not unexpected
;; coaddition of previous results if the routine is called several
;; times
nk_reset_grid, grid

nsn = n_elements(data)
grid.integ_time = nsn/!nika.f_sampling

;; if requested for a quick simulation, project pure white noise with
;; input NEFD
if param.project_white_noise_nefd eq 1 then begin
   for iarray=1, 3 do begin
      w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
      if nw1 ne 0 then begin
         nefd = !nika.nefd[iarray-1]/1000. ; mJy to Jy
         data.toi[w1] = reform( randomn( seed, long(nsn)*long(nw1))*$
                                nefd*sqrt(!nika.f_sampling), nw1, nsn)

         ;; do not apply uniform weight otherwise the A1+A3
         ;; combination is not weighted properly since they do not
         ;; have the same sensitivity
         ;; data.w8[w1] = 1.d0
         data.w8[w1] = 1.d0/nefd^2
      endif
   endfor
endif

;; Pure normalized white noise projection to have a standard ruler
if param.project_pure_white_noise eq 1 then begin
   w1 = where( kidpar.type eq 1, nw1)
   if nw1 ne 0 then begin
      data.toi[w1] = reform( randomn( seed, nw1*nsn), nw1, nsn)
      data.w8[w1] = 1.d0
   endif
endif

;; if requested, do not project the 1st or last n seconds of subscans
if param.flag_n_seconds_subscan_start ne 0 then begin
   npts_flag = round( param.flag_n_seconds_subscan_start*!nika.f_sampling)
   for i=min(data.subscan), max(data.subscan) do begin
      w = where( data.subscan eq i, nw)
      if nw ne 0 then begin
         wsample = (indgen(npts_flag) + min(w)) < max(w)
         nk_add_flag, data, 8, wsample=wsample
      endif
   endfor
endif

if param.flag_n_seconds_subscan_end ne 0 then begin
   npts_flag = round( param.flag_n_seconds_subscan_end*!nika.f_sampling)
   for i=min(data.subscan), max(data.subscan) do begin
      w = where( data.subscan eq i, nw)
      if nw ne 0 then begin
         wsample = (max(w)-indgen(npts_flag)) > min(w)
         nk_add_flag, data, 8, wsample=wsample
      endif
   endfor
endif

if param.naive_projection eq 1 then begin

   ;; I loop on lambda and define temporary map, map_w8 and nhits to avoid a
   ;; loop over all kids and then test kid by kid the band to which it
   ;; belongs.
   ;; @ Projects I, Q, U maps per array
   for iarray=1, 3 do begin
      w1 = where(kidpar.type eq 1 and kidpar.array eq iarray, nw1)
      junk = execute( "grid.nvalid_kids"+strtrim(iarray,2)+" = nw1")

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
            if info.polar ne 0 then begin
               data.w8_q[w1] = data.w8_q[w1] * double( dd ge param.rmin_proj and dd le param.rmax_proj)
               data.w8_u[w1] = data.w8_u[w1] * double( dd ge param.rmin_proj and dd le param.rmax_proj)
            endif
         endif

         ;; Define toi and w8 to speed up histograms and sums
         toi  = data.toi[w1]
         w8   = data.w8[ w1]
         if param.simuJK2 eq 0 then begin 
            ipix = data.ipix[w1] ; Normal case
         endif else begin
            w1rand = permut( seed, nw1) ; random permutation with a variable seed based on time-of-day (FXD, May 2020)
            ipix = data.ipix[w1rand]
         endelse
                  
         w = where( data.flag[w1] ne 0 or $
                    finite(data.w8[w1]) eq 0 or $
                    data.w8[w1] eq 0, nw)
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
         d = sqrt( grid.xmap^2 + grid.ymap^2)
         if param.source_mask then wbg = where( d gt 2*max(!nika.fwhm_nom) and finite(grid.(wmap)) eq 1, nwbg) else $
             wbg = where( finite(grid.(wmap)) eq 1, nwbg)
;;; Changed 27 July 2020         wbg = where( d gt 2*max(!nika.fwhm_nom) and finite(grid.(wmap)) eq 1, nwbg)
         if nwbg eq 0 then begin
            txt = "Cannot compute the variance map on the background"
            nk_error, info, txt
            return
         endif else begin
            bg_mask[wbg] = 1
         endelse

         if param.no_bg_var_map then begin
            map_var = map_w8*0.d0
            w = where( map_w8 ne 0, nw)
            if nw ne 0 then map_var[w] = 1.d0/map_w8[w]
         endif else begin
            nk_bg_var_map, grid.(wmap), grid.(wnhits), bg_mask, map_var, $
                           boost=param.boost, nhits_min_bg_var_map=param.nhits_min_bg_var_map, $
                           commissioning_plot=param.commissioning_plot, status=status
         endelse
         grid.(wvar) = map_var
         
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
            if param.no_bg_var_map then begin
               map_var = map_w8_q*0.d0
               w = where( map_w8_q ne 0, nw)
               if nw ne 0 then map_var[w] = 1.d0/map_w8_q[w]
            endif else begin
               nk_bg_var_map, grid.(wq), grid.(wnhits), bg_mask, map_var, $
                              boost=param.boost, nhits_min_bg_var_map=param.nhits_min_bg_var_map
            endelse
            grid.(wvarq) = map_var

            if param.no_bg_var_map then begin
               map_var = map_w8_u*0.d0
               w = where( map_w8_u ne 0, nw)
               if nw ne 0 then map_var[w] = 1.d0/map_w8_u[w]
            endif else begin
               nk_bg_var_map, grid.(wu), grid.(wnhits), bg_mask, map_var, $
                              boost=param.boost, nhits_min_bg_var_map=param.nhits_min_bg_var_map
            endelse
            grid.(wvaru) = map_var
         endif

      endif
   endfor

   w1 = where( kidpar.type eq 1 and (kidpar.array eq 1 or kidpar.array eq 3), nw1)
   if nw1 ne 0 then begin
      ;; @ combines array 1 and 3 into '1mm' and duplicates results of
      ;; array 2 into 2mm
      grid.nhits_1mm = grid.nhits_1 + grid.nhits_3
      stokes = ['I', 'Q', 'U']
      if info.polar ge 1 then nstokes = 3 else nstokes = 1
      for istokes=0, nstokes-1 do begin
         wmap1    = where( strupcase(grid_tags) eq 'MAP_'+stokes[istokes]+'1', nwmap1)
         wmap3    = where( strupcase(grid_tags) eq 'MAP_'+stokes[istokes]+'3', nwmap3)
         wmap1MM  = where( strupcase(grid_tags) eq 'MAP_'+stokes[istokes]+'_1MM', nwmap1MM)
         whits1   = where( strupcase(grid_tags) eq 'NHITS_1', nwhits1)
         ww81     = where( strupcase(grid_tags) eq "MAP_W8_"+stokes[istokes]+'1', nww81)
         ww83     = where( strupcase(grid_tags) eq "MAP_W8_"+stokes[istokes]+'3', nww83)
         whits3   = where( strupcase(grid_tags) eq 'NHITS_3', nwhits3)
         ww81MM   = where( strupcase(grid_tags) eq "MAP_W8_"+stokes[istokes]+'_1MM', nww81MM)
         whits1MM = where( strupcase(grid_tags) eq 'NHITS_1MM', nwhits1MM)
         wvar1MM  = where( strupcase(grid_tags) eq 'MAP_VAR_'+stokes[istokes]+'_1MM', nwvar1MM)

         ;; add nhits
         grid.(whits1mm) = grid.(whits1) + grid.(whits3)

         ;; add weights
         grid.(ww81mm) = grid.(ww81) + grid.(ww83)

         ;; weighted sum of signal
         grid.(wmap1mm) = grid.(ww81)*grid.(wmap1) + grid.(ww83)*grid.(wmap3)

         ;; normalization by the total weight
         w = where( grid.(ww81mm) ne 0, nw)
         if nw eq 0 then begin
            message, /info, "No pixel with w8 /= 0 in "+stokes[istokes]+'1 and 3'
         endif else begin
            junk = grid.xmap*0.d0
            junk[w] = (grid.(wmap1mm))[w]/(grid.(ww81mm))[w]
            grid.(wmap1mm) = junk
         endelse

         ;; Derive the variance map on the background
         nk_bg_var_map, grid.(wmap1mm), grid.(whits1mm), bg_mask, map_var, $
                        boost=param.boost, nhits_min_bg_var_map=param.nhits_min_bg_var_map, $
                        status=status
         if status eq 1 then begin
            err_mess = "pb with nk_bg_var_map"
            message, /info, err_mess
            nk_error, info, err_mess
         endif
         grid.(wvar1mm) = map_var
      endfor
   endif
   
   ;; Copy array2 results into 2mm fields for convenience
   grid.map_i_2mm     = grid.map_i2
   grid.nhits_2mm     = grid.nhits_2
   grid.map_var_i_2mm = grid.map_var_i2
   grid.map_w8_I_2mm  = grid.map_w8_i2
   if info.polar ne 0 then begin
      grid.map_q_2mm     = grid.map_q2
      grid.map_u_2mm     = grid.map_u2
      grid.map_var_q_2mm = grid.map_var_q2
      grid.map_var_u_2mm = grid.map_var_u2
      grid.map_w8_q_2mm  = grid.map_w8_q2
      grid.map_w8_u_2mm  = grid.map_w8_u2
   endif

   ;; Log the number of kids used for these maps
   grid.nvalid_kids_2mm = grid.nvalid_kids2
   ;; old def of nvalid_kids_1mm probably for some reason of FOV area
   ;; grid.nvalid_kids_1mm = max( [grid.nvalid_kids1,
   ;; grid.nvalid_kids3])
   ;; Replace by a more rational def (not used anymore in
   ;; nk_map_photometry)
   grid.nvalid_kids_1mm = grid.nvalid_kids1 + grid.nvalid_kids3
endif

if param.cpu_time then nk_show_cpu_time, param, "nk_projection_4"
end
