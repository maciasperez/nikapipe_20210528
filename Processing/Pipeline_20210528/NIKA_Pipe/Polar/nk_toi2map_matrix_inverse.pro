;+
;
; SOFTWARE: NIKA simulation pipeline
;
; NAME: nk_toi2map_matrix_inverse
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         nk_toi2map_matrix_inverse, param, simpar, info, data, kidpar
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
;-

pro nk_toi2map_matrix_inverse, param, info, data, kidpar, grid

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_toi2maps_matrix_inverse, param, info, data, kidpar, grid"
   return
endif


if param.cpu_time then param.cpu_t0 = systime( 0, /sec)

;; ;;-------------------------------------
;; message, /info, "fix me and speed up:"
;; data_copy = data
;; ;;-------------------------------------

nsn = n_elements(data)
for lambda=1, 2 do begin
   p=0
   q=0
   nk_list_kids, kidpar, lambda=lambda, valid=w1, nvalid=nw1
   if nw1 ne 0 then begin
      ipix  = data.ipix[w1]
      ipix1 = data.ipix1[w1]
      ipix =  ipix[ where(finite(ipix) and ipix ge 0)  ]
      ipix1 = ipix1[ where(finite(ipix1) and ipix1 ge 0)  ]

      order  = sort(ipix )
      order1 = sort(ipix1)
      b = ipix[UNIQ(ipix, order)]
      c = ipix1[UNIQ(ipix1, order1)]

      ;; find all pixels touched by at least one beam
      d = [b,c]
      d = d[uniq(d,sort(d))]
      nd = n_elements(d)

      ata   = dblarr(nd,nd)
      ata1  = dblarr(nd,nd)

      ;; Relabel these pixels with the indices of the ata and atd matrix elements
      ipix_new  = data.ipix[w1]
      ipix1_new = data.ipix1[w1]
      for i=0L, nd-1 do begin
         w = where( ipix_new eq d[i], nw)
         if nw ne 0 then ipix_new[w] = i

         w11 = where( ipix1_new eq d[i], nw11)
         if nw11 ne 0 then ipix1_new[w11] = i
      endfor

      atd_i = dblarr(nd)
      atd_q = dblarr(nd)
      atd_u = dblarr(nd)
     
      for i=0, nw1-1 do begin
         ikid = w1[i]

         ;; Back to Hz
         data.toi[ikid] /= kidpar[ikid].calib_fix_fwhm
         data.w8[ikid]  *= kidpar[ikid].calib_fix_fwhm^2

         ;; for convenience
         c0 = kidpar[ikid].calib_fix_fwhm
         c1 = kidpar[ikid].calib_fix_fwhm_1

         for isn=0L, n_elements(data)-1 do begin
            p = ipix_new[ i, isn]
            q = ipix1_new[i, isn]
            
            if p ne -1 then begin
               ata[p,p]   += data[isn].w8[ikid]/c0^2
               ata1[p,p]  += data[isn].w8[ikid]/c0^2

               atd_i[p]   += data[isn].w8[ikid]/c0 * data[isn].toi[  ikid]
               atd_q[p]   += data[isn].w8[ikid]/c0 * data[isn].toi_q[ikid]
               atd_u[p]   += data[isn].w8[ikid]/c0 * data[isn].toi_u[ikid]

               if lambda eq 1 then grid.nhits_1mm[p] += 1 else grid.nhits_2mm[p] += 1
            endif

            if q ne -1 then begin
               ata[q,q]   += data[isn].w8[ikid]/c1^2
               ata1[q,q]  += data[isn].w8[ikid]/c1^2
            
               atd_i[q]   += data[isn].w8[ikid]/c1 * data[isn].toi[  ikid]
               atd_q[q]   -= data[isn].w8[ikid]/c1 * data[isn].toi_q[ikid]
               atd_u[q]   -= data[isn].w8[ikid]/c1 * data[isn].toi_u[ikid]
            
               if lambda eq 1 then grid.nhits_1mm[q] += 1 else grid.nhits_2mm[q] += 1
            endif
            
            if (p ne -1) and (q ne -1) and (p ne q) then begin
               ata[p,q]  += data[isn].w8[ikid] /(c0*c1)
               ata[q,p]  += data[isn].w8[ikid] /(c0*c1)
               ata1[p,q] -= data[isn].w8[ikid] /(c0*c1)
               ata1[q,p] -= data[isn].w8[ikid] /(c0*c1)
            endif
         endfor
      endfor
      
      ;;save, ata, atd_i, atd_q, atd_u, file='ata.save'

      ;; Invert
      am1  = invert(ata)
      am11 = invert(ata1)

      map_out_i = am1##atd_i
      map_out_q = am11##atd_q
      map_out_u = am11##atd_u
  
      if lambda eq 1 then begin
         for i=0, nd-1 do begin
            grid.map_i_1mm[d[i]] = map_out_i[i]
            grid.map_q_1mm[d[i]] = map_out_q[i]
            grid.map_u_1mm[d[i]] = map_out_u[i]
            ;; w8 = 1/var
            grid.map_w8_1mm[   d[i]] = 1.d0/am11[0,0]
            grid.map_w8_q_1mm[ d[i]] = 1.d0/am11[1,1]
            grid.map_w8_u_1mm[ d[i]] = 1.d0/am11[2,2]
         endfor
      endif
      if lambda eq 2 then begin
         for i=0, nd-1 do begin
            grid.map_i_2mm[d[i]] = map_out_i[i]
            grid.map_q_2mm[d[i]] = map_out_q[i]
            grid.map_u_2mm[d[i]] = map_out_u[i]
            ;; w8 = 1/var
            grid.map_w8_1mm[   d[i]] = 1.d0/am11[0,0]
            grid.map_w8_q_1mm[ d[i]] = 1.d0/am11[1,1]
            grid.map_w8_u_1mm[ d[i]] = 1.d0/am11[2,2]
         endfor
      endif
   endif
endfor

wind, 1, 1, /free, xs=1200, ys=900
my_multiplot, 3, 2, pp, pp1, /rev
imview, map_struct.map_i_1mm, position=pp1[0,*]
imview, map_struct.map_q_1mm, position=pp1[1,*], /noerase
imview, map_struct.map_u_1mm, position=pp1[2,*], /noerase
imview, map_struct.map_i_2mm, position=pp1[3,*], /noerase
imview, map_struct.map_q_2mm, position=pp1[4,*], /noerase
imview, map_struct.map_u_2mm, position=pp1[5,*], /noerase

;; wind, 1, 1, /free, xs=1600, ys=900
;; my_multiplot, 3, 2, pp, pp1, /rev
;; imview, grid.map_i_1mm, xmap=grid.xmap, ymap=grid.ymap, position=pp1[0,*]
;; imview, grid.map_q_1mm, xmap=grid.xmap, ymap=grid.ymap, position=pp1[1,*], /noerase
;; imview, grid.map_u_1mm, xmap=grid.xmap, ymap=grid.ymap, position=pp1[2,*], /noerase
;; imview, grid.map_i_2mm, xmap=grid.xmap, ymap=grid.ymap, position=pp1[3,*], /noerase
;; imview, grid.map_q_2mm, xmap=grid.xmap, ymap=grid.ymap, position=pp1[4,*], /noerase
;; imview, grid.map_u_2mm, xmap=grid.xmap, ymap=grid.ymap, position=pp1[5,*], /noerase

;; ;;----------------
;; message, /info, "fix me:"
;; data = data_copy
;; ;;----------------

if param.cpu_time then nk_show_cpu_time, param, "nk_toi2map_matrix_inverse"

end
