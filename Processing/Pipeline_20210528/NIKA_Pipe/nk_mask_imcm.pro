
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_mask_imcm
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
; 
; PURPOSE: 
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

pro nk_mask_imcm, param, info, kidpar, toi, flag, off_source, elevation, $
                  toi_out, out_temp, snr_toi=snr_toi, out_coeffs=out_coeffs, $
                  w8_hfnoise=w8_hfnoise
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_mask_imcm'
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

nsn = n_elements( toi[0,*])
nkids = n_elements(kidpar)

;; Compute w8_source once for all
if defined(snr_toi) then begin
   w8_source=1.d0/(1.d0+param.k_snr_w8_decor*snr_toi^2)

   ;; Do not defined w8_source = off_source or this leads to division
   ;; by 0 in nk_subtract_templates_3 when computing measure_errors.
;; endif else begin
;;    w8_source = off_source
;; endelse
endif

;; Implement estimation of excess noise, that in general shows up on
;; subscan edges. See Xavier's trick in
;; nk_decor_atmb_per_array.pro for his method #120
if param.subscan_edge_w8 gt 0 then begin
   toih = toi
   w8_hfnoise = toi*0.d0        ; init for convenience
   nsmooth = round( param.subscan_edge_w8_smooth_duration*!nika.f_sampling)
   for iarray=1, 3 do begin
      w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)

      if nw1 ne 0 then begin
         for i=0, nw1-1 do toih[w1[i],*] = toi[w1[i],*]-smooth( toi[w1[i],*], nsmooth, /edge_mirror)
         hfnoise = smooth( stddev( toih[w1,*], dim=1), nsmooth, /edge_mirror)

         ;; scale to an average single detector and center
         ;;hfnoise[12:nsn-12] = sqrt(nw1) * (hfnoise[12:nsn-12]-avg(hfnoise[12:nsn-12]))
         hfnoise *= sqrt(nw1)
         ;; Normalize to its own stddev
         hfnoise /= stddev( hfnoise)
         ;; Normalize to its average to have something around 1
         hfnoise /= avg( hfnoise)

         ;; Center hfnoise for the w8 formula
         w8_hfnoise[w1,*] = transpose( rebin( $
                            1.d0/(1.d0+param.subscan_edge_w8*((hfnoise-avg(hfnoise))/stddev(hfnoise))^2), nsn, nw1))

         if param.interactive eq 1 then begin
            if defined(my_local_window) eq 0 then begin
               wind, 1, 1, /free, /large
               my_multiplot, 3, 2, pp, pp1, /rev
               my_local_window = !d.window
            endif

            time = dindgen(n_elements(toi[0,*]))/!nika.f_sampling
            ikid = w1[0]
            myavg = avg(toi[ikid,*])
            yra = array2range( toi[ikid,*]-myavg)
            plot, time, toi[ikid,*]-myavg, /xs, position=pp[iarray-1,0,*], /noerase, yra=yra, /ys, $
                  xtitle='Time (sec)', title='nk_mask_imcm'
            wflag = where( flag[ikid,*] ne 0)
            oplot, time[wflag], toi[ikid,wflag]-myavg, psym=1, syms=0.5, col=200
            oplot, time, (-0.5 + (flag[ikid,*] eq 2L^11))*(yra[1]-yra[0])/2., col=70
            legendastro, ['TOI', 'Flag ne 0', 'Anomalous speed'], col=[0,200,70]
            legendastro, ['A'+strtrim(iarray,2), $
                          'Numdet '+strtrim(kidpar[ikid].numdet,2)], /right

            yra = [0, max(hfnoise)>1.5]
            plot,  time, hfnoise, /xs, position=pp[iarray-1,1,*], /noerase, /nodata, yra=yra, $
                   xtitle='Time (sec)'
            oplot, time, hfnoise, col=250
            oplot, time, w8_hfnoise[ikid,*], col=150
            legendastro, ['hfnoise', 'w8_hfnoise'], col=[250,150]
;            stop
         endif
      endif
   endfor

   ;; Account for this weight in w8_source
   if defined(w8_source) then begin
      w8_source *= w8_hfnoise
   endif else begin
      w8_source = w8_hfnoise
   endelse
   delvarx, toih
endif

if param.decor_from_atm eq 1 and $
   param.atm_per_array eq 0 and $
   param.dual_band_1mm_atm eq 0 then begin
;; 1. Estimate atmosphere from all KIDs (both 1 and 2mm)
   if param.log then nk_log, info, "Derive atm_cm from ALL valid kids (1 & 2mm)"
   w1 = where( kidpar.type eq 1, nw1)
   if defined(w8_source) then myw8 = w8_source[w1,*]
   myflag = flag[w1,*]
   nk_get_cm_sub_2, param, info, toi[w1,*], myflag, $
                    off_source[w1,*], kidpar[w1], atm_cm, $
                    w8_source=myw8
   flag[w1,*] = myflag ; update flags
   delvarx, myw8, myflag
endif

;;----------------- Loop over arrays for eletronics related modes -----------------
nkids    = n_elements(kidpar)
toi_out  = dblarr(nkids,nsn)
out_temp = dblarr(nkids,nsn)

subband = kidpar.numdet/80      ; integer division on purpose

which_templates = ''

for iarray=1, 3 do begin
   w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
   
   p=-1
   if nw1 ne 0 then begin
      ;; Init the toi that gets cleaner and cleaner
      residual = toi[w1,*]

      myflag = flag[w1,*]
      if param.interactive eq 1 then !mydebug.array = iarray
;;       message, /info, "HERE"
;;       param.mydebug = 0419
;;       stop
      nk_get_cm_sub_2, param, info, toi[w1,*], myflag, $
                       off_source[w1,*], kidpar[w1], atm_cm, w8_source=myw8
;;      message, /info, "HERE"
;;      param.mydebug = 0418
;;      stop

      if param.mydebug eq 0418 then begin
         make_ct, nw1, ct
         wind, 1, 1, /free, /large
         my_multiplot, 1, 3, pp, pp1, /rev
         plot, toi[w1[0],*], /xs, yra=minmax(residual), /ys, position=pp1[0,*]
         for i=0, nw1-1 do oplot, toi[w1[i],*], col=ct[i]
         
         plot, toi[w1[0],*], /xs, /ys, position=pp1[1,*], /noerase
         for i=0, nw1-1 do begin
            w = where( off_source[w1[i],*] and off_source[w1[0],*], nw)
            if nw ge 200 then begin
               fit = linfit( toi[w1[i],w], toi[w1[0],w])
               oplot, fit[0]+ fit[1]*toi[w1[i],*], col=ct[i]
            endif
         endfor
         
         plot, atm_cm, /xs, /ys, position=pp1[2,*], /noerase
         stop
      endif
      
      flag[w1,*] = myflag
      delvarx, myflag
   
      if param.include_elevation_in_decor_templates eq 1 then begin
         which_templates += 'elevation, atm'
         if param.log then nk_log, info, "add elevation in the list of decorrelation templates"
         atm_temp = dblarr(2,nsn)
         atm_temp[0,*] = atm_cm
         atm_temp[1,*] = elevation
      endif else begin
         which_templates += 'atm'
         atm_temp = dblarr(1,nsn)
         atm_temp[0,*] = atm_cm
      endelse
      
      ;; @ 1. Subtract atmosphere from all KIDs everywhere the
      ;; common mode is defined, fitting only outside the mask (of course)
      if param.log then nk_log, info, "subtract "+which_templates+" from toi"
      if defined(w8_source) then myw8 = w8_source[w1,*]
      myflag = flag[w1,*]

;;      if param.mydebug eq 0418 then begin
;;         toi_copy = residual
;;         flag_copy = myflag
;;
;;         make_ct, nw1, ct
;;         wind, 1, 1, /free, /large
;;         my_multiplot, 1, 2, pp, pp1, /rev
;;         plot, residual[0,*], /xs, yra=minmax(residual), /ys, position=pp1[0,*]
;;         for i=0, nw1-1 do oplot, residual[i,*], col=ct[i]
;;         plot, atm_temp, /xs, /ys, position=pp1[1,*], /noerase
;;         stop
;;         
;;      endif

;      print, "HERE"
;      stop
      
      nk_subtract_templates_4, param, info, residual, myflag, off_source[w1,*], $
                               kidpar[w1], atm_temp, out_temp1, out_coeffs=out_coeffs, $
                               w8_source=myw8

;;       if param.mydebug eq 0418 then begin
;;          i1 = 0
;;          ikid = w1[i1]
;;          wind, 1, 1, /free, /large
;;          my_multiplot, 1, 3, pp, pp1, /rev
;;          yra = minmax( toi[ikid,*])
;;          myoff = off_source[ikid,*]*(yra[1]-yra[0])*0.9 + yra[0]
;;          plot, toi[ikid,*], /xs, position=pp[0,0,*], /noerase, /ys, yra=yra
;;          oplot, myoff, col=150, thick=2
;;          legendastro, ['toi', 'off_source'], col=[!p.color,150], /bottom
;; 
;;          plot, atm_temp, /xs, /ys, position=pp[0,1,*], /noerase
;;          oplot, atm_temp, col=70
;;          legendastro, 'atm_temp', col=70
;; 
;;          nn = n_elements(toi[ikid,*])
;;          yra = minmax( [reform( toi[ikid,*], nn), reform(residual[i1,*],nn)])
;;          plot, toi[ikid,*], /xs, /ys, position=pp[0,2,*], /noerase, yra=yra
;;          oplot, residual[i1,*], col=250
;;          wproj = where( myflag[i1,*] eq 0, nwproj)
;;          if nwproj ne 0 then $
;;             oplot, [wproj], [residual[i1,wproj]], col=150, psym=1, syms=0.5 $
;;                    else print, "No valid sample to project"
;;          stop
;;       endif

         
      flag[    w1,*] = myflag
      toi_out[ w1,*] = residual
      out_temp[w1,*] = out_temp1

      delvarx, myw8, myflag
   endif ; valid kids
endfor   ; loop over arrays


if param.cpu_time then nk_show_cpu_time, param

end
