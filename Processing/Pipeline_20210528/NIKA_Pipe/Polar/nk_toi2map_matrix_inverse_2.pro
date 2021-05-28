;+
;
; SOFTWARE: NIKA simulation pipeline
;
; NAME: nk_toi2map_matrix_inverse_2
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         nk_toi2map_matrix_inverse_2, param, simpar, info, data, kidpar
; 
; PURPOSE: 
;        Produces TOI's from an input map and input scanning strategy and kidpar.
; 
; INPUT: 
;        - simpar: the simulation parameter structure
;        - param : the pipeline parameter structure
;        - info: the data info structure
;        - data: the original data taken from a real observation scan or
;          produced by another extra simulation routine from scratch.
;        - kidpar: the original kid structure from a real observation scan or
;          produced by another extra simulation routine from scratch.
; 
; OUTPUT: 
;        - data.toi, data.toi_q, data.toi_u if polarization
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Sep, 15th, 2014: AR, (ritacco@lpsc.in2p3.fr)
;        - Dec. 30th, 2014: NP, hacked from nk_toi2map_matrix_inverse. Now use
;          histograms to avoid loops.
;-

pro nk_toi2map_matrix_inverse_2, param, info, data, kidpar, grid

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_toi2maps_matrix_inverse, param, info, data, kidpar, grid"
   return
endif

for i=0, 3 do message, /info, "Does not work yet."
return
;; 
;; 
;; 
;; 
;; 
;; if param.cpu_time then param.cpu_t0 = systime( 0, /sec)
;; 
;; nsn = n_elements(data)
;; for lambda=1, 2 do begin
;;    p=0
;;    q=0
;;    nk_list_kids, kidpar, lambda=lambda, valid=w1, nvalid=nw1
;;    if nw1 ne 0 then begin
;;       ipix  = data.ipix[w1]
;;       ipix1 = data.ipix1[w1]
;;       ipix =  ipix[ where(finite(ipix) and ipix ge 0)  ]
;;       ipix1 = ipix1[ where(finite(ipix1) and ipix1 ge 0)  ]
;; 
;;       order  = sort(ipix )
;;       order1 = sort(ipix1)
;;       b = ipix[UNIQ(ipix, order)]
;;       c = ipix1[UNIQ(ipix1, order1)]
;; 
;;       ;; find all pixels touched by at least one beam
;;       d = [b,c]
;;       d = d[uniq(d,sort(d))]
;;       nd = n_elements(d)
;; 
;;       ata   = dblarr(nd,nd)
;;       ata1  = dblarr(nd,nd)
;; 
;;       ;; Relabel these pixels with the indices of the ata and atd matrix elements
;;       ipix_new  = data.ipix[w1]
;;       ipix1_new = data.ipix1[w1]
;;       for i=0L, nd-1 do begin
;;          w = where( ipix_new eq d[i], nw)
;;          if nw ne 0 then ipix_new[w] = i
;; 
;;          w11 = where( ipix1_new eq d[i], nw11)
;;          if nw11 ne 0 then ipix1_new[w11] = i
;;       endfor
;; 
;;       atd_i = dblarr(nd)
;;       atd_q = dblarr(nd)
;;       atd_u = dblarr(nd)
;; 
;;       ;; Back to Hz
;;       toi   = data.toi[  w1] / (dblarr(nsn)+1)##kidpar[w1].calib_fix_fwhm
;;       toi_q = data.toi_q[w1] / (dblarr(nsn)+1)##kidpar[w1].calib_fix_fwhm
;;       toi_u = data.toi_u[w1] / (dblarr(nsn)+1)##kidpar[w1].calib_fix_fwhm
;;       w8    = data.w8[   w1] * (dblarr(nsn)+1)##kidpar[w1].calib_fix_fwhm^2
;; 
;;       ;; for convenience
;;       c0 = kidpar[w1].calib_fix_fwhm
;;       c1 = kidpar[w1].calib_fix_fwhm_1
;;      
;;       w8_a = w8/( (dblarr(nsn)+1)##c0^2)
;;       w8_b = w8/( (dblarr(nsn)+1)##c0)
;;       w = where(ipix_new lt 0, nw)
;;       if nw ne 0 then ipix_new[w] = !values.d_nan
;;       hp = histogram( ipix_new, /nan, reverse_ind=Rp)
;;       p = lindgen( n_elements(hp)) + long(min(ipix_new,/nan))
;;       for j=0L, n_elements(hp)-1 do begin
;;          if Rp[j] ne Rp[j+1] then begin
;;             index = Rp[Rp[j]:Rp[j+1]-1]
;;             ata[  p[j], p[j]] += total( w8_a[index])
;;             ata1[ p[j], p[j]] += total( w8_a[index])
;; 
;;             atd_i[p[j]] += total( w8_b[index]*toi[  index])
;;             atd_q[p[j]] += total( w8_b[index]*toi_q[index])
;;             atd_u[p[j]] += total( w8_b[index]*toi_u[index])
;;             if lambda eq 1 then grid.nhits_1mm[p[j]] += Rp[j+1]-Rp[j] else grid.nhits_2mm[p[j]] += Rp[j+1]-Rp[j]
;;          endif
;;       endfor
;; 
;;       w = where(ipix1_new lt 0, nw)
;;       if nw ne 0 then ipix1_new[w] = !values.d_nan
;;       hq = histogram( ipix1_new, /nan, reverse_ind=Rq)
;;       q = lindgen( n_elements(hq)) + long(min(ipix1_new,/nan))
;;       w8_a = w8/( (dblarr(nsn)+1)##c1^2)
;;       w8_b = w8/( (dblarr(nsn)+1)##c1)
;;       for j=0L, n_elements(hq)-1 do begin
;;          if Rq[j] ne Rq[j+1] then begin
;;             index = Rq[Rq[j]:Rq[j+1]-1]
;;             ata[ q[j],q[j]] += total( w8_a[index])
;;             ata1[q[j],q[j]] += total( w8_a[index])
;;             
;;             atd_i[q[j]] += total( w8_b[index]*toi[  index])
;;             atd_q[q[j]] -= total( w8_b[index]*toi_q[index])
;;             atd_u[q[j]] -= total( w8_b[index]*toi_u[index])
;; 
;;             if lambda eq 1 then grid.nhits_1mm[q[j]] += Rq[j+1]-Rq[j] else grid.nhits_2mm[q[j]] += Rq[j+1]-Rq[j]
;;          endif
;;       endfor
;; 
;;       w8_a = w8/( (dblarr(nsn)+1)##(c0*c1))
;;       for j=0, n_elements(hp)-1 do begin
;;          for k=0, n_elements(hq)-1 do begin
;;             if p[j] ne q[k] then begin
;;                ata[  p[j],q[k]] += total( w8_a[index])
;;                ata[  q[k],p[j]] += total( w8_a[index])
;;                ata1[ p[j],q[k]] -= total( w8_a[index])
;;                ata1[ q[k],p[j]] -= total( w8_a[index])
;;             endif
;;          endfor
;;       endfor
;;       
;;       ;; Invert
;;       am1  = invert(ata)
;;       am11 = invert(ata1)
;; 
;;       map_out_i = am1##atd_i
;;       map_out_q = am11##atd_q
;;       map_out_u = am11##atd_u
;;   
;;       if lambda eq 1 then begin
;;          for i=0, nd-1 do begin
;;             grid.map_i_1mm[d[i]] = map_out_i[i]
;;             grid.map_q_1mm[d[i]] = map_out_q[i]
;;             grid.map_u_1mm[d[i]] = map_out_u[i]
;;             ;; w8 = 1/var
;;             grid.map_w8_1mm[   d[i]] = 1.d0/am11[0,0]
;;             grid.map_w8_q_1mm[ d[i]] = 1.d0/am11[1,1]
;;             grid.map_w8_u_1mm[ d[i]] = 1.d0/am11[2,2]
;;          endfor
;;       endif
;;       if lambda eq 2 then begin
;;          for i=0, nd-1 do begin
;;             grid.map_i_2mm[d[i]] = map_out_i[i]
;;             grid.map_q_2mm[d[i]] = map_out_q[i]
;;             grid.map_u_2mm[d[i]] = map_out_u[i]
;;             ;; w8 = 1/var
;;             grid.map_w8_1mm[   d[i]] = 1.d0/am11[0,0]
;;             grid.map_w8_q_1mm[ d[i]] = 1.d0/am11[1,1]
;;             grid.map_w8_u_1mm[ d[i]] = 1.d0/am11[2,2]
;;          endfor
;;       endif
;;    endif
;; endfor
;; 
;; ;; wind, 1, 1, /free, xs=1600, ys=900
;; ;; my_multiplot, 3, 2, pp, pp1, /rev
;; ;; imview, grid.map_i_1mm, xmap=grid.xmap, ymap=grid.ymap, position=pp1[0,*]
;; ;; imview, grid.map_q_1mm, xmap=grid.xmap, ymap=grid.ymap, position=pp1[1,*], /noerase
;; ;; imview, grid.map_u_1mm, xmap=grid.xmap, ymap=grid.ymap, position=pp1[2,*], /noerase
;; ;; imview, grid.map_i_2mm, xmap=grid.xmap, ymap=grid.ymap, position=pp1[3,*], /noerase
;; ;; imview, grid.map_q_2mm, xmap=grid.xmap, ymap=grid.ymap, position=pp1[4,*], /noerase
;; ;; imview, grid.map_u_2mm, xmap=grid.xmap, ymap=grid.ymap, position=pp1[5,*], /noerase
;; 
;; if param.cpu_time then nk_show_cpu_time, param, "nk_toi2map_matrix_inverse_2"

end
