;+
;
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
;        nk_projection_2beams
;
; CATEGORY: 
;        projection
;
; CALLING SEQUENCE:
;         nk_projection_2beams, param, info, data, kidpar, maps
; 
; PURPOSE: 
;        Project the data in the prism mode onto a pixelized map. It only coadds the data from the
;        current scan to pre-existing info.map, info.map_w8 etc...
;        The final average is done outside the loop on scans in nk_toi2map.
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
;        - 24/09/2014: creation (Alessia Ritacco & Nicolas Ponthieu - ritacco@lpsc.in2p3.fr)
;-

pro nk_projection_2beams, param, info, data, kidpar, grid

if info.status eq 1 then begin
   if param.silent eq 0 then    message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

nsn = n_elements(data)

if param.naive_projection eq 1 then begin

   ;; I loop on lambda and define temporary map, map_w8 and nhits to avoid a
   ;; loop over all kids and then test kid by kid the band to which it belongs.
   for lambda=1, 2 do begin
      nk_list_kids, kidpar, lambda=lambda, valid=w1, nvalid=nw1

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

         ;; Define toi and w8 to speed up histograms and sums
         toi   = data.toi[  w1]
         toi_q = data.toi_q[w1]
         toi_u = data.toi_u[w1]
         w8    = data.w8[   w1]
         ipix  = data.ipix[ w1]
         ipix1 = data.ipix1[w1]

         sgn   = ipix*0 + 1
         mask  = ipix*0
         mask1 = ipix*0
         for i=0, nw1-1 do begin
            ikid = w1[i]
            w = where(data.off_source1[ikid] eq 0, nw)
            sgn[i,w] = -1   
            mask1[i,w] = 1
            w = where(data.off_source[ikid] eq 0, nw)
            mask[i,w] = 1
         endfor

         w = where(ipix lt 0, nw)
         if nw ne 0 then ipix[w] = !values.d_nan
         w = where(ipix1 lt 0, nw)
         if nw ne 0 then ipix1[w] = !values.d_nan

         h = histogram( ipix, /nan, reverse_ind=R)
         p = lindgen( n_elements(h)) + long(min(ipix,/nan))
         for j=0L, n_elements(h)-1 do begin
            if r[j] ne r[j+1] then begin
               index = R[R[j]:R[j+1]-1]
               map[   p[j]] += total( toi[index]*w8[index]*mask[index])
               map_w8[p[j]] += total(            w8[index]*mask[index])
               nhits[ p[j]] += total( mask[index])
               if info.polar eq 2 then begin
                  map_q[    p[j]] += total( toi_q[index]*w8[index]*mask[index])
                  map_u[    p[j]] += total( toi_u[index]*w8[index]*mask[index])
                  map_w8_q[ p[j]] += total(  w8[index]*mask[index])
                  map_w8_u[ p[j]] += total(  w8[index]*mask[index])
               endif
            endif
         endfor

         h = histogram( ipix1, /nan, reverse_ind=R)
         p = lindgen( n_elements(h)) + long(min(ipix1,/nan))
         for j=0L, n_elements(h)-1 do begin
            if r[j] ne r[j+1] then begin
               index = R[R[j]:R[j+1]-1]
               map[   p[j]] += total( toi[index]*w8[index]*mask1[index])
               map_w8[p[j]] += total(            w8[index]*mask1[index])
               nhits[ p[j]] += total( mask1[index])
               if info.polar eq 2 then begin
                  map_q[    p[j]] += total( sgn[index]*toi_q[index]*w8[index]*mask1[index])
                  map_u[    p[j]] += total( sgn[index]*toi_u[index]*w8[index]*mask1[index])
                  map_w8_q[ p[j]] += total(  w8[index]*mask1[index])
                  map_w8_u[ p[j]] += total(  w8[index]*mask1[index])
               endif
            endif
         endfor

      endif

      w = where( map_w8 ne 0, nw)
      if nw eq 0 then begin
         nk_error, info, "all pixels empty at "+strtrim(lambda,2)+" mm", /silent
         return
      endif else begin
         map[w] /= map_w8[w]
         if info.polar ne 0 then begin
            map_q[w] /= map_w8_q[w]
            map_u[w] /= map_w8_u[w]
         endif
      endelse
      
      if lambda eq 1 then begin
         grid.map_i_1mm  = map
         grid.map_w8_1mm = map_w8
         grid.nhits_1mm  = nhits
         if info.polar ne 0 then begin
            grid.map_q_1mm = map_q
            grid.map_u_1mm = map_u
            grid.map_w8_q_1mm = map_w8_q
            grid.map_w8_u_1mm = map_w8_u
         endif
      endif else begin
         grid.map_i_2mm  = map
         grid.map_w8_2mm = map_w8
         grid.nhits_2mm  = nhits
         if info.polar ne 0 then begin
            grid.map_q_2mm = map_q
            grid.map_u_2mm = map_u
            grid.map_w8_q_2mm = map_w8_q
            grid.map_w8_u_2mm = map_w8_u
         endif
      endelse

   endfor

endif


;; ;; Show maps if requested
;; if info.status ne 1 then begin
;;    if param.do_plot ne 0 then begin
;;       if not param.plot_ps then wind, 1, 1, /free, /xlarge
;;       my_multiplot, 3, 1, pp, pp1
;;       outplot, file=param.output_dir+"/maps", png=param.plot_png, ps=param.plot_ps
;;       imview, grid.map_i_1mm,   xmap=grid.xmap, ymap=grid.ymap, title = param.scan+' 1mm',  position=pp1[0,*], nsigma=4
;;       imview, grid.map_i_2mm,   xmap=grid.xmap, ymap=grid.ymap, title = param.scan+' 2mm',  position=pp1[1,*], nsigma=4, /noerase
;;       imview, grid.mask_source, xmap=grid.xmap, ymap=grid.ymap, title = param.scan+' mask', position=pp1[2,*], nsigma=4, /noerase
;;       outplot, /close
;;    endif
;; endif

if param.cpu_time then nk_show_cpu_time, param, "nk_projection_2"
end
