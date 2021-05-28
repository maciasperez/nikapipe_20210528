
pro nk_decor_atm_and_all_boxes, param, info, kidpar, toi, flag, off_source, elevation, $
                                toi_out, out_temp, snr_toi=snr_toi, subscan=subscan

nsn = n_elements( toi[0,*])

if param.niter_atm_el_box_modes gt 1 then all_out_common_modes = dblarr(param.niter_atm_el_box_modes, 21, nsn)

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

;; 3. 1st estimate of mode per electronic box
nk_get_one_mode_per_box, param, info, toi_no_atm, flag, off_source, kidpar, $
                         common_mode_per_box, acq_box_out, w8_source=w8_source

;; 4. Decorrelate from atm (and elevation if requested) and all
;; modes at the same time
nboxes = n_elements(acq_box_out)
nt     = n_elements(atm_temp[*,0])
if param.one_offset_per_subscan eq 1 then begin
   subscan_min = min(subscan)
   nsubscans = max(subscan) - min(subscan) + 1
   ;; Do not fit all subscans because regress needs one constant that
   ;; will be the one of the last subscan
   templates = dblarr(nboxes+nt+nsubscans-1, nsn)
endif else begin
   templates = dblarr(nboxes+nt, nsn)
endelse
templates[0:nt-1,*]         = atm_temp
templates[nt:nt+nboxes-1,*] = common_mode_per_box
if param.one_offset_per_subscan eq 1 then begin
   if nsubscans gt 1 then begin
      for iss=0, nsubscans-2 do begin
         wsubscan = where( subscan eq (subscan_min+iss), nwsubscan)
         if nwsubscan eq 0 then begin
            nk_error, info, 'Subscan '+strtrim(subscan_min+iss,2)+" is empty"
            return
         endif
         templates[nt+nboxes+iss,wsubscan] = 1.d0
      endfor
   endif
endif

junk = toi
nk_subtract_templates_3, param, info, junk, flag, off_source, $
                         kidpar, templates, out_temp, out_coeffs=out_coeffs, $
                         w8_source=w8_source

;; if param.plot_ps eq 0 and param.plot_z eq 0 then wind, 1, 1, /free, /large
;; nbb = n_elements(common_mode_per_box[*,0])
;; xmax = 0.5
;; my_multiplot, 1, nbb, pp, pp1, /rev, xmax=xmax, xmargin=0.01, xmin=0.02, gap_y=0.01
;; for ib=0, nbb-1 do plot, common_mode_per_box[ib,*], position=pp1[ib,*], /noerase, chars=0.6
;; my_multiplot, 1, 3, pp, pp1, /rev, xmargin=0.01, xmin=xmax+0.05, xmax=0.95
;; for iarray=1, 3 do begin
;;    w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
;;    make_ct, nw1, ct
;;    yra=array2range(junk[w1,*])
;;    plot, junk[w1[0],*], position=pp1[iarray-1,*], /noerase, yra=yra, /ys
;;    for ii=0, nw1-1 do oplot, junk[w1[ii],*], col=ct[ii]
;; endfor
;; stop

;; Iterate on the separation of atm and box modes if requested
if param.niter_atm_el_box_modes gt 1 then begin
   iter = 0
   all_out_common_modes[iter,0,*]   = templates[0,   *]       ; atm_cm
   all_out_common_modes[iter,1:*,*] = templates[nt:*,*]       ; el box modes
   
   alpha = out_coeffs
   for iter=1, param.niter_atm_el_box_modes-1 do begin
      message, /info, "iter "+strtrim(iter,2)+"/"+strtrim(param.niter_atm_el_box_modes-1,2)
      
      ;; Build new estimates of common modes with out_coeffs and TOI's
      ata = alpha##transpose(alpha)
      atam1 = invert(ata)
      atd = toi[w1,*]##transpose(alpha)
      out_common_modes = transpose(atam1##transpose(atd))
      
      all_out_common_modes[iter,*,*] = out_common_modes[1:*,*,*]
      
      junk = toi
      templates = out_common_modes[1:*,*] ; get rid of the constant terms for "regress.pro"
      ;; Use nk_subtract_templates_3 to determine alpha at each
      ;; iteration and take the last decorrelation when we exit
      ;; this loop.
      nk_subtract_templates_3, param, info, junk, flag, off_source, $
                               kidpar, templates, out_temp, out_coeffs=alpha
   endfor
   
   if param.interactive eq 1 then begin
      wind, 1, 1, /free, /large
      make_ct, param.niter_atm_el_box_modes, ct
      my_multiplot, 1, 1, ntot=21, pp, pp1, /rev, gap_x=0.05
      for imode=0, 20 do begin
         plot, all_out_common_modes[0,imode,*], position=pp1[imode,*], /noerase
         for iter=0, param.niter_atm_el_box_modes-1 do begin
            oplot, all_out_common_modes[iter,imode,*], col=ct[iter]
         endfor
      endfor
   endif
   
endif

toi_out = junk

end
