

pro nk_mdc_try, param, info, data, kidpar, grid

if n_params() lt 1 then begin
   dl_unix, 'nk_mdc_try'
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

nsn = n_elements( data)
nkids    = n_elements(kidpar)

for iarray=1, 3 do begin
   w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
   if nw1 ne 0 then begin

      ;; 1st rough estimate with all valid kids
      myflag = data.flag[w1]
      nk_get_cm_sub_2, param, info, data.toi[w1], myflag, $
                       data.off_source[w1], kidpar[w1], atm_cm ;,w8_source=myw8
      data.flag[w1] = myflag

      ;; Look for tiny glitches that have not been detected on
      ;; individual TOI's
      if param.deglitch_atm_cm eq 1 then begin
         sigma2cm = dblarr(n_elements(kidpar)) - 1 ; init to negative to make ensure the "where sigma gt ..."
         for i=0, nw1-1 do begin
            ikid = w1[i]
            woff = where( data.off_source[ikid] eq 1, nwoff)
            fit = linfit( atm_cm[woff], data[woff].toi[ikid])
            y = data[woff].toi[ikid] - fit[0] - fit[1]*atm_cm[woff]
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
         myflag = data.flag[w11]
         nk_get_cm_sub_2, param, info, data.toi[w11], myflag, $
                          data.off_source[w11], kidpar[w11], atm_cm1 ;, $w8_source=myw8
         data.flag[w11] = myflag
         
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
               data[wflag].flag[ikid] = 1
               y = data.toi[ikid]
               y_smooth = smooth( y, long(!nika.f_sampling), /edge_mirror)
               sigma = stddev( y[wk]-y_smooth[wk])
               z = interpol( y_smooth[wk], index[wk], index)
               y[wflag] = z[wflag] + randomn( seed, nwflag)*sigma
               data.toi[ikid] = y
            endfor
         endif
               
         ;; Update atm_cm for the rest of this routine
         atm_cm = atm_cm_out
      endif
      
      if param.include_elevation_in_decor_templates eq 1 then begin
         which_templates = 'elevation, atm'
         if param.log then nk_log, info, "add elevation in the list of decorrelation templates"
         atm_temp = dblarr(2,nsn)
         atm_temp[0,*] = atm_cm
         atm_temp[1,*] = data.elevation
      endif else begin
         which_templates = 'atm'
         atm_temp = dblarr(1,nsn)
         atm_temp[0,*] = atm_cm
      endelse

      ;; @ 1. Subtract atmosphere from all KIDs
      myflag = data.flag[w1]
      residual = data.toi[w1]
      nk_subtract_templates_3, param, info, residual, myflag, data.off_source[w1], $
                               kidpar[w1], atm_temp, out_temp1, out_coeffs=out_coeffs, $
                               w8_source=myw8
      data.flag[w1] = myflag    ; update flags 
      
      ;; @ 2. Decorrelate residuals
      mcorr = correlate( residual)
      wnan  = where(finite(mcorr) ne 1, nwnan)
      if nwnan ne 0 then mcorr[wnan] = -1

      kid2kid_dist = dblarr(nw1,nw1)
      for i=0, nw1-1 do begin
         for j=0, nw1-1 do begin
            kid2kid_dist[i,j] = sqrt( (kidpar[w1[i]].nas_x-kidpar[w1[j]].nas_x)^2 + $
                                      (kidpar[w1[i]].nas_y-kidpar[w1[j]].nas_y)^2)
         endfor
      endfor
      
      residual_copy = residual
      kid2kid_dist_min = 30.    ; place holder
      for i=0, nw1-1 do begin

         ;; Search for best set of KIDs to be used for deccorelation
         corr = reform(mcorr[i,*])
         
         ;; Do not consider KIDs that are too close to avoid filtering
         ;; out the source
         wdist = where( kid2kid_dist[i,*] lt kid2kid_dist_min, nwdist)
         if nwdist ne 0 then corr[wdist] = -1
         
         ;; Sort by order of maximum correlation
         s_corr = corr[reverse(sort(corr))]
         
         ;; First block with the requested min number of KIDs
         block = where(corr gt s_corr[param.n_corr_block_min+1] and corr ne 1, nblock)
         if nblock ge 2 then begin
            ;; Determine the common mode of this block
            nk_get_cm_sub_2, param, info, residual_copy[block,*], data.flag[w1[block]], data.off_source[w1[block]], kidpar[w1[block]], cm
            
            ;; subtract from the current kid
            ;; fit = linfit( cm, residual[i,*])
            fit = poly_fit( cm, residual[i,*], 1, status=status)
            if status eq 0 then begin
               residual[i,*] -= (fit[0] + fit[1]*cm)
               data.toi[w1[i]] = reform(residual[i,*])
            endif else begin
               message, /info, "poly_fit failed"
               kidpar[ikid].type = 3
            endelse
         endif
      endfor
      
;;       if param.show_toi_corr_matrix then begin
;;          corr_mat2 = abs(correlate( residual))
;;          wind, 1, 1, /free, /large
;;          my_multiplot, 2, 2, pp, pp1, /rev
;;          imview, abs(corr_mat0), position=pp1[0,*], imrange=[0,1], title='raw A'+strtrim(iarray,2)
;;          imview, abs(corr_mat1), position=pp1[1,*], imrange=[0,1], title='atm subtracted', /noerase
;;          imview, abs(corr_mat2), position=pp1[2,*], imrange=[0,1], title='multi decorr', /noerase
;;          stop
;;       endif
      ;;===============================
      
   endif

endfor

if param.cpu_time then nk_show_cpu_time, param

end
