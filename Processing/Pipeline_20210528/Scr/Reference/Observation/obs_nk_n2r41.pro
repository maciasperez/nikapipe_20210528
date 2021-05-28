
pro obs_nk_n2r41, i, scan_list, project_dir, method, source, in_param_file=in_param_file, $
               simu=simu, decor2=decor2, quick_noise_sim=quick_noise_sim, $
               param=param, dry=dry, input_kidpar_file=input_kidpar_file, reset=reset, $
               NoTauCorrect=NoTauCorrect, mask_source=mask_source, reso=reso, $
               map_proj=map_proj, no_polar=no_polar, $
               ata_fit_beam_rmax=ata_fit_beam_rmax, polynomial=polynomial, $
               do_tel_gain_corr = do_tel_gain_corr, $
               decor_cm_dmin=decor_cm_dmin, $
               opacity_correction=opacity_correction
  
;  FXD &  LP,  experimental version (Simplified)
if keyword_set(in_param_file) then begin
   restore, in_param_file
endif else begin
;; init param and simpar
   nk_default_param, param
   param.do_opacity_correction = 6
   if keyword_set( input_kidpar_file) then begin
      param.file_kidpar = input_kidpar_file
      param.force_kidpar = 1
   endif
  
endelse

;; Deal with simu
if keyword_set(simu) then simu=1 else simu=0

if keyword_set(reset) then nk_reset_filing, param, scan_list[i]

delvarx, info, grid
;nk_default_info, info
;nk_init_grid2, param, info, grid, header=header

;; Quick and dirty
;; if keyword_set(mask_source) then begin
;;    restore, "mask_source.save"
;;    restore, "mask_source_sz.save"
;;    grid.mask_source = mask_source
;;    delvarx, mask_source
;; endif

if keyword_set(dry) then begin
   ;; exit to get "param" only"
   return
endif else begin
   ;; Reduce scan
   if keyword_set(simu) then begin
      nk, scan_list[i], param=param ;,info=info, grid=grid, header=header
   endif else begin
      nk, scan_list[i], param=param ;,info=info, grid=grid, header=header
   endelse
endelse

end

