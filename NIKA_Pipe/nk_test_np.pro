
pro nk_test_np, param, info, toi, flag, off_source, kidpar, $
                                    common_mode, elevation, kid_corr_block;, w8_source=w8_source
  
;; sanity checks  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

nkids = n_elements(kidpar)
nsn  = n_elements(toi[0,*])

;; Loop on kids
w1 = where( kidpar.type eq 1, nw1)
if nw1 eq 0 then begin
   nk_error, info, "No valid kid"
   return
endif

;; Backup toi, otherwise, it gets modified for each kid and the
;; decorrelation is performed on decorrelated timelines for the last
;; kids rather than on the same raw timelines on which the block was
;; determined ! (in nk_decor_sub_corr_block_2, the correction was done
;; on data.toi, so no prob.
toi_copy = toi

common_mode = dblarr(nkids, nsn)
snr         = dblarr(nkids, nsn)

for i=0, nw1-1 do begin
   ikid = w1[i]
   
   ;; Flagged data have either been interpolated and are safe or are due
   ;; to uncertain pointing between subscans, but this does not affect their
   ;; temporal correlation, so we can use them for the regress.
   wsample = where( off_source[ikid,*] eq 1, nwsample)
   if nwsample lt param.nsample_min_per_subscan then begin
      ;; do not project this subscan for this kid
      flag[ikid,*] = 1
   endif else begin
      wb = where(kid_corr_block[ikid,*] ne -1, nwb)
      if nwb eq 0 then begin
         nk_error, info, "no correlated kid found for ikid = "+strtrim(ikid,2)
         return
      endif
      block = reform(kid_corr_block[ikid,wb])

      if param.decor_all_kids_in_block eq 1 then begin
         templates = dblarr( 1 + nwb, nsn)
         templates[0,  *] = elevation
         templates[1:*,*] = toi_copy[block,*]
      endif else begin
;         if keyword_set(w8_source) then my_w8_source = w8_source[block,*]
         nk_get_cm_sub_2, param, info, toi_copy[block,*], flag[block,*], off_source[block,*], $
                          kidpar[block], block_common_mode;, w8_source=my_w8_source

         ;; Use this first CM estimation to derive a SNR per sample and
         ;; improve its estimation
         for i=0, nwb-1 do begin
            ib = block[i]
            w = where( off_source[ib,*] eq 1 and (flag[ib,*] eq 0 or flag[ib,*] eq 2L^11), nw)
            if nw ne 0 then begin
               fit = linfit( block_common_mode[w], toi[ib,w])
               y = toi[ib,*] - (fit[0] + fit[1]*block_common_mode)
               ;; Compute standard dev off_source as a first easy and
               ;; better than nothing estimation, but estimate snr everywhere...
               snr[ib,*] = abs(y/stddev(y[w]))
            endif
         endfor
         
         ;; do the same for the current kid
         w = where( off_source[ikid,*] eq 1 and (flag[ikid,*] eq 0 or flag[ikid,*] eq 2L^11), nw)
         fit = linfit( block_common_mode[w], toi[ikid,w])
         y = toi[ikid,*] - (fit[0] + fit[1]*block_common_mode)
         snr[ikid,*] = abs(y/stddev(y[w]))
         
         ;; Build final common mode like in get_cm_sub_2 but
         ;; weighting with the current snr rather than the hard
         ;; coded kidpar.noise
         measure_error = reform( sqrt(1.+param.k_snr*snr[ikid,*]^2))
         fit1 = linfit( block_common_mode, toi[ikid,*], measure_error=measure_error)
         new_common_mode = (fit1[0] + fit1[1]*reform(toi[ikid,*]))/measure_error^2
         new_w8          = 1.d0/measure_error^2
         for i=0, nwb-1 do begin
            ib = block[i]
            measure_error = reform( sqrt(1.+param.k_snr*snr[ib,*]^2))
            fit1 = linfit( block_common_mode, toi[ib,*], measure_error=measure_error)
            new_common_mode += (fit1[0] + fit1[1]*toi[ib,*])/measure_error^2
            new_w8          += 1.d0/measure_error^2
         endfor
         wjunk = where( new_w8 le 0, nwjunk)
         new_common_mode /= new_w8

         if param.do_plot eq 1 and kidpar[ikid].numdet eq !nika.ref_det[1] then begin
            ;; Now fit with SNR weight
            measure_error = reform( sqrt(1.+param.k_snr*snr[ikid,*]^2))
            fit1 = linfit( block_common_mode, toi[ikid,*], measure_error=measure_error)

            if param.plot_ps eq 0 then wind, 1, 1, /free, /large
            outplot, file=param.plot_dir+"/measure_error_common_mode", png=param.plot_png, ps=param.plot_ps
            my_multiplot, 1, 3, pp, pp1, /rev
            plot, block_common_mode, yra=minmax([block_common_mode, new_common_mode]), /ys, position=pp1[0,*]
            oplot, new_common_mode, col=250
            junk = linfit( block_common_mode, new_common_mode)
            oplot, junk[0] + junk[1]*block_common_mode, col=70
            legendastro, 'k = '+strtrim(k,2)

            plot, toi[ikid,*], /xs, /ys, position=pp1[1,*], /noerase
            oplot, measure_error, col=200
            oplot, off_source[ikid,*]*100, col=250
            oplot, 1.d0/measure_error^2 * 100, col=150
            legendastro, ['Toi', 'Measure error', 'off_source x 100', $
                          '1/measure_error^2 x 100'], col=[!p.color, 200, 250, 150]

            w = where( off_source[ikid,*] eq 1 and (flag[ikid,*] eq 0 or flag[ikid,*] eq 2L^11), nw)
            fit  = linfit( block_common_mode[w], toi[ikid,w])
            fit1 = linfit( new_common_mode, toi[ikid,*], measure_error=measure_error)
            plot,  toi[ikid,*] - (fit[0]+fit[1]*block_common_mode), /xs, position=pp1[2,*], /noerase
            oplot, toi[ikid,*] - (fit[0]+fit[1]*block_common_mode), col=70
            oplot, toi[ikid,*] - (fit1[0] + fit1[1]*new_common_mode), col=250
            legendastro, ['toi-block_CM(off_source)', 'toi-new_CM'], col=[70,250]
         endif

         ;; Add elevation like for all decorrelations
;;         templates = transpose( [[block_common_mode], [elevation]])
         templates = transpose( [[new_common_mode], [elevation]])
         
;         if ikid eq 580 then begin
;            wind, 1, 1, /free, /xlarge
;            plot, block_common_mode, /xs, /ys
;            stop
;         endif
      endelse

      ;; Regress the common_mode and the data WITH MEASURE_ERROR
      measure_error = reform( sqrt(1.+param.k_snr*snr[ikid,*]^2))
      coeff = regress( templates, reform( toi[ikid,*]), measure_error=measure_error, $
                       CHISQ= chi, CONST= const, CORRELATION= corr, $
                       /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status)
      ;; ... but subtract the common_mode everywhere
      yfit = dblarr(nsn) + const
      for ii=0, n_elements(coeff)-1 do yfit += coeff[ii]*templates[ii,*]
      toi[ikid,*] -= yfit
      common_mode[ikid,*] = yfit

      ;; Comment out the decorrelation on Q and U,
      ;; NP. Nov. 19th, 2017, see nk_decor_sub_corr_block2.
   endelse
endfor

if param.cpu_time then nk_show_cpu_time, param
  
end
