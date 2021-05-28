

pro nk_decor_atm_and_boxes_per_array, param, info, kidpar, toi, flag, off_source, elevation, $
                                      toi_out, out_temp, snr_toi=snr_toi

nsn = n_elements( toi[0,*])


;; 1. Estimate atmosphere
w1 = where( kidpar.type eq 1, nw1)
if defined(snr_toi) then begin
   w8_source=1.d0/(1.d0+param.k_snr_w8_decor*snr_toi^2)
   atm_w8_source = w8_source[w1,*]
endif
nk_get_cm_sub_2, param, info, toi[w1,*], flag[w1,*], $
                 off_source[w1,*], kidpar[w1], atm_cm, $
                 w8_source=atm_w8_source

if param.include_elevation_in_decor_templates eq 1 then begin
   atm_temp = dblarr(2,nsn)
   atm_temp[0,*] = atm_cm
   atm_temp[1,*] = elevation
endif else begin
   atm_temp = dblarr(1,nsn)
   atm_temp[0,*] = atm_cm
endelse

;; 2. Subtract atmosphere from all KIDs
toi_no_atm = toi
nk_subtract_templates_3, param, info, toi_no_atm, flag, off_source, $
                         kidpar, atm_temp, out_temp, out_coeffs=out_coeffs

if param.save_toi_corr_matrix then begin
   mcorr_no_atm = correlate(toi_no_atm)
   save, mcorr_no_atm, file=param.output_dir+"/toi_corr_matrix_no_atm.save"
   delvarx, mcorr_no_atm
endif
if param.show_toi_corr_matrix then begin
   mcorr_no_atm = correlate(toi_no_atm)
   outplot, file=param.project_dir+"/Plots/no_atm_corr_matrix/plot_"+info.scan, /z
   imview, mcorr_no_atm
   outplot, /close, /verb
endif


nkids = n_elements(kidpar)
toi_out  = dblarr(nkids,nsn)
out_temp = dblarr(nkids,nsn)
for iarray=1, 3 do begin
;;   wind, 1, 1, /free, xpos=iarray*100, /large

   w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
   if nw1 ne 0 then begin
      if defined(snr_toi) then begin
         w8_source = 1.d0/(1.d0+param.k_snr_w8_decor*snr_toi[w1,*]^2)
      endif
      ;; 3. 1st estimate of mode per electronic box
      nk_get_one_mode_per_box, param, info, toi_no_atm[w1,*], flag[w1,*], off_source[w1,*], kidpar[w1], $
                               common_mode_per_box, acq_box_out, w8_source=w8_source

      ;; 4. Decorrelate from atm (and elevation if requested) and all
      ;; modes at the same time
      nboxes = n_elements(acq_box_out)
      nt     = n_elements(atm_temp[*,0])
      templates = dblarr(nboxes+nt, nsn)
      templates[0:nt-1,*] = atm_temp
      templates[nt:*,*]   = common_mode_per_box
      junk = toi[w1,*]
      nk_subtract_templates_3, param, info, junk, flag[w1,*], off_source[w1,*], $
                               kidpar[w1], templates, out_temp1, out_coeffs=out_coeffs, $
                               w8_source=w8_source

      ;; Iterate on the separation of atm and box modes if requested
      if param.niter_atm_el_box_modes gt 1 then begin
         all_out_common_modes = dblarr(param.niter_atm_el_box_modes, nboxes+nt, nsn)

         iter = 0
         all_out_common_modes[iter,0,*]   = templates[0,   *] ; atm_cm
         all_out_common_modes[iter,1:*,*] = templates[nt:*,*] ; el box modes
         
         alpha = out_coeffs
         resid_rms = dblarr( param.niter_atm_el_box_modes, nw1)
         resid_rms[0,*] = stddev(junk,dim=2)

         wind, 2, 2, /free, /large
         imrange_corr_mat = [-1,1]*0.2 ; [0, 1]
         my_multiplot, 1, 1, ntot=param.niter_atm_el_box_modes, /rev, pp, pp1
         imview, correlate(junk), position=pp1[0,*], /noerase, $
                 title='A'+strtrim(iarray,2)+' Iter 0', imrange=imrange_corr_mat
         for iter=1, param.niter_atm_el_box_modes-1 do begin
            message, /info, "iter "+strtrim(iter,2)+"/"+strtrim(param.niter_atm_el_box_modes-1,2)
            
            ;; Build new estimates of common modes with out_coeffs and TOI's
            ata = alpha##transpose(alpha)
            atam1 = invert(ata)
            atd = toi[w1,*]##transpose(alpha)
            out_common_modes = transpose(atam1##transpose(atd))
            
            all_out_common_modes[iter,*,*] = out_common_modes[1:*,*,*]
            
            junk = toi[w1,*]
            templates = out_common_modes[1:*,*] ; get rid of the constant terms for "regress.pro"
            ;; Use nk_subtract_templates_3 to determine alpha at each
            ;; iteration and take the last decorrelation when we exit
            ;; this loop.
            nk_subtract_templates_3, param, info, junk, flag[w1,*], off_source[w1,*], $
                                     kidpar[w1], templates, out_temp1, out_coeffs=alpha

            resid_rms[iter,*] = stddev(junk,dim=2)

            imview, correlate(junk), position=pp1[iter,*], /noerase, imrange=imrange_corr_mat, $
                    title='A'+strtrim(iarray,2)+' Iter '+strtrim(iter,2)
         endfor

         wind, 1, 1, /free, /large
         my_multiplot, 1, 1, pp, pp1, ntot=(nboxes+nt), /rev, $
                       ymin=0.25, ymax=0.9, gap_y=0.03, gap_x=0.05
         make_ct, param.niter_atm_el_box_modes, ct
         time = dindgen(nsn)/!nika.f_sampling
         xyouts, 0.05, 0.2, /norm, param.scan, orient=90
         for it=0, nt+nboxes-1 do begin
            title = 'A'+strtrim(iarray,2)
            if it eq 0 then title += ' atm' else title += ' box '+strtrim(it-1,2)
            plot, time, all_out_common_modes[0,it,*], /xs, /ys, $
                  position=pp1[it,*], /noerase, chars=0.6, title=title
            for iter=0, param.niter_atm_el_box_modes-1 do oplot, time, all_out_common_modes[iter,it,*], col=ct[iter]
         endfor

         my_multiplot, param.niter_atm_el_box_modes, 1, pp, pp1, ymax=0.25, ymin=0.01
         for iter=0, param.niter_atm_el_box_modes-1 do $
            np_histo, resid_rms[iter,*], position=pp1[iter,*], $
                      /noerase, /fit, /force, /fill, colorfit=ct[iter]

      endif

      toi_out[w1,*] = junk
      out_temp[w1,*] = out_temp1
   endif

endfor

;; nk_show_toi_corr_matrix, param, info, toi_out, kidpar, imrange=imrange_corr_mat, /subbands

end
