
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_improve_atm
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

pro nk_improve_atm, param, info, kidpar, toi, flag, off_source, elevation, $
                    toi_out, out_temp, snr_toi=snr_toi, out_coeffs=out_coeffs

;-

if n_params() lt 1 then begin
   dl_unix, 'nk_improve_atm'
   return
endif

nsn   = n_elements( toi[0,*])
nkids = n_elements( kidpar)
toi_out  = dblarr(nkids,nsn)
out_temp = dblarr(nkids,nsn)

for iarray=1, 3 do begin
   w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
   if nw1 ne 0 then begin
      
      ;; 1st rough estimate with all valid kids
      myflag = flag[w1,*]
      nk_get_cm_sub_2, param, info, toi[w1,*], myflag, $
                       off_source[w1,*], kidpar[w1], atm_cm ;,w8_source=myw8
      flag[w1,*] = myflag

      ;; Look for tiny glitches that have not been detected on
      ;; individual TOI's
      if param.deglitch_atm_cm eq 1 then begin
         sigma2cm = dblarr(n_elements(kidpar)) - 1 ; init to negative to make ensure the "where sigma gt ..."
         for i=0, nw1-1 do begin
            ikid = w1[i]
            woff = where( off_source[ikid,*] eq 1, nwoff)
            fit = linfit( atm_cm[woff], toi[ikid,woff])
            y = toi[ikid,woff] - fit[0] - fit[1]*atm_cm[woff]
            np_histo, y, xh, yh, gpar, /fit, /noplot, /noprint, /force, status=status
            if status eq 0 then begin
               sigma2cm[ikid] = gpar[2]
            endif else begin
               sigma2cm[ikid] = stddev(y)
            endelse
            w = where( abs(y-avg(y)) gt 3*gpar[2], nw)
            ;; Take margin w.r.t to pure gaussian noise that
            ;; would call for only 1% data at more than 3sigma
            if float(nw)/nwoff gt 0.02 then kidpar[ikid].type=12
         endfor
         ;; flag out noisy kids as well
         np_histo, sigma2cm[w1], xh, yh, gpar, /fit, /force, /noprint, /noplot, status=status
         if status eq 0 then begin
            ww = where( sigma2cm[w1] gt (gpar[1]+3*gpar[2]), nww)
         endif else begin
            ww = where( sigma2cm[w1] gt (avg(sigma2cm[w1])+3*stddev(sigma2cm[w1])), nww)
         endelse
         if nww ne 0 then kidpar[w1[ww]].type = 12
         
         junk = where(kidpar.type eq 12, njunk) ;  or sigma2cm gt (gpar[1]+3*gpar[2]), njunk)
         message, /info, "rejected "+strtrim(njunk,2)+"/"+strtrim(nw1,2)+" kids for array "+strtrim(iarray,2)+" to derive atm_cm"
         
         ;; Improved derivation of the atmosphere template
         w11 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw11)
         myflag = flag[w11,*]
         nk_get_cm_sub_2, param, info, toi[w11,*], myflag, $
                          off_source[w11,*], kidpar[w11], atm_cm1 ;, $w8_source=myw8
         flag[w11,*] = myflag
         
         ;; Restore kidpar.type 12 to 1 to recover all of them and try
         ;; to improve their decorrelation with other modes
         w = where( kidpar.type eq 12, nw)
         if nw ne 0 then kidpar[w].type = 1

         ;; Deglitch the common mode and apply to all kids
         qd_deglitch, atm_cm1, param.glitch_width, param.glitch_nsigma, atm_cm_out, flag0, $
                      deglitch_nsamples_margin=param.deglitch_nsamples_margin
         wflag = where( flag0 ne 0, nwflag, compl=wk)
         index = lindgen(nsn)
         if nwflag ne 0 then begin
            for i=0, nw1-1 do begin
               ikid = w1[i]
               flag[ikid,wflag] = 1
               y = toi[ikid,*]
               y_smooth = smooth( y, long(!nika.f_sampling), /edge_mirror)
               sigma = stddev( y[wk]-y_smooth[wk])
               z = interpol( y_smooth[wk], index[wk], index)
               y[wflag] = z[wflag] + randomn( seed, nwflag)*sigma
               toi[ikid,*] = y
            endfor
         endif
               
         ;; Update atm_cm for the rest of this routine
         atm_cm = atm_cm_out

;         atm_cm = smooth( atm_cm, 10, /edge_mirror)

      endif
      
      if param.include_elevation_in_decor_templates eq 1 then begin
         which_templates = 'elevation, atm'
         if param.log then nk_log, info, "add elevation in the list of decorrelation templates"
         atm_temp = dblarr(2,nsn)
         atm_temp[0,*] = atm_cm
         atm_temp[1,*] = elevation
      endif else begin
         which_templates = 'atm'
         atm_temp = dblarr(1,nsn)
         atm_temp[0,*] = atm_cm
      endelse

      ;; @ 1. Subtract atmosphere from all KIDs
      myflag   = flag[w1,*]
      residual = toi[w1,*]
      nk_subtract_templates_3, param, info, residual, myflag, off_source[w1,*], $
                               kidpar[w1], atm_temp, out_temp1, out_coeffs=out_coeffs, $
                               w8_source=myw8

;;       nx = 6
;;       ny = 5
;;       nplots_per_window = nx * ny
;;       my_multiplot, nx, ny, ntot=nplots_per_window, pp, pp1, /rev, gap_x=0.02, xmin=0.05, xmargin=0.01
;;       !p.charsize = 0.7
;;       yra = array2range(residual, margin=0.05)
;;       for i=0, nw1-1 do begin
;;          if (i mod nplots_per_window) eq 0 then begin
;;             wind, 1, 1, /free, /large
;;             xyouts, 0.02, 0.5, param.scan, /norm, orient=90, chars=1
;;             xyouts, 0.03, 0.5, "nk_improve_atm", /norm, orient=90
;;          endif
;;          plot, residual[i,*], /xs, yra=yra, /ys, $
;;                position=pp1[i mod nplots_per_window,*], /noerase, $
;;                title=strtrim(kidpar[w1[i]].numdet,2)
;;       endfor
      
      toi_out[ w1,*] = residual
      out_temp[w1,*] = out_temp1
   endif

endfor


if param.cpu_time then nk_show_cpu_time, param

end
