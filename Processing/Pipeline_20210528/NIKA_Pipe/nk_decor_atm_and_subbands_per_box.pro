
pro nk_decor_atm_and_subbands_per_box, param, info, kidpar, toi, flag, off_source, elevation, $
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
subband = kidpar.numdet/80 ; integer division on purpose


b = kidpar[w1].acqbox
acq_box_out = b[UNIQ(b, SORT(b))]
nboxes = n_elements(acq_box_out)

for ibox=0, nboxes-1 do begin
   wkbox = where( kidpar.type eq 1 and kidpar.acqbox eq ibox, nwkbox)
   if nwkbox ne 0 then begin

      ;; how many bands ?
      sb = subband[wkbox]
      b = sb[ uniq( sb, sort(sb))]
      nsubbands = n_elements(b)

      ;; allocate templates
      nt     = n_elements(atm_temp[*,0])
      templates = dblarr(nsubbands+nt, nsn)
      templates[0:nt-1,*] = atm_temp
      
      ;; fill templates with modes per bands
      for ib=0, nsubbands-1 do begin
         wb = where( kidpar.type eq 1 and subband eq b[ib], nwk)
         if defined(snr_toi) then begin
            w8_source = 1.d0/(1.d0+param.k_snr_w8_decor*snr_toi[wb,*]^2)
         endif
         nk_get_cm_sub_2, param, info, toi_no_atm[wb,*], flag[wb,*], $
                          off_source[wb,*], kidpar[wb], subband_cm, w8_source=w8_source
         templates[nt+ib,*] = subband_cm
      endfor
      
      ;; regress out atm and all subbands of the current box at the
      ;; same time
      junk = toi[wkbox,*]
      nk_subtract_templates_3, param, info, junk, flag[wkbox,*], off_source[wkbox,*], $
                               kidpar[wkbox], templates, out_temp1, out_coeffs=out_coeffs, $
                               w8_source=w8_source

      if param.niter_atm_el_box_modes gt 1 then all_out_common_modes = dblarr(param.niter_atm_el_box_modes, 1+nsubbands, nsn)

      ;; Iterate on the separation of atm and box modes if requested
      if param.niter_atm_el_box_modes gt 1 then begin
         iter = 0
         all_out_common_modes[iter,0,*]   = templates[0,   *] ; atm_cm
         all_out_common_modes[iter,1:*,*] = templates[nt:*,*] ; el box modes
         
         alpha = out_coeffs
         for iter=1, param.niter_atm_el_box_modes-1 do begin
            message, /info, "iter "+strtrim(iter,2)+"/"+strtrim(param.niter_atm_el_box_modes-1,2)
            
            ;; Build new estimates of common modes with out_coeffs and TOI's
            ata = alpha##transpose(alpha)
            atam1 = invert(ata)
            atd = toi[wkbox,*]##transpose(alpha)
            out_common_modes = transpose(atam1##transpose(atd))
            
            all_out_common_modes[iter,*,*] = out_common_modes[1:*,*,*]
            
            junk = toi[wkbox,*]
            templates = out_common_modes[1:*,*] ; get rid of the constant terms for "regress.pro"
            ;; Use nk_subtract_templates_3 to determine alpha at each
            ;; iteration and take the last decorrelation when we exit
            ;; this loop.
            nk_subtract_templates_3, param, info, junk, flag[wkbox,*], off_source[wkbox,*], $
                                     kidpar[wkbox], templates, out_temp1, out_coeffs=alpha
         endfor
         
      endif
      toi_out[wkbox,*] = junk
      out_temp[wkbox,*] = out_temp1
   endif
endfor


end
