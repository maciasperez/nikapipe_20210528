
pro obs_nk_ps, i, scan_list, project_dir, method, source, in_param_file=in_param_file, $
               simu=simu, decor2=decor2, quick_noise_sim=quick_noise_sim, $
               param=param, dry=dry, input_kidpar_file=input_kidpar_file, reset=reset, $
               NoTauCorrect=NoTauCorrect, mask_source=mask_source, reso=reso, $
               map_proj=map_proj, no_polar=no_polar, $
               ata_fit_beam_rmax=ata_fit_beam_rmax, polynomial=polynomial, $
               do_tel_gain_corr = do_tel_gain_corr, $
               decor_cm_dmin=decor_cm_dmin, $
               opacity_correction=opacity_correction

if keyword_set(in_param_file) then begin
   restore, in_param_file
endif else begin
;; init param and simpar  
   point_source_default_param, param, simpar, method, source, $
                               decor2=decor2, input_kidpar_file=input_kidpar_file, reso=reso, $
                               map_proj=map_proj, ata_fit_beam_rmax=ata_fit_beam_rmax, $
                               polynomial=polynomial, $
                               do_tel_gain_corr = do_tel_gain_corr, $
                               decor_cm_dmin=decor_cm_dmin, $
                               opacity_correction=opacity_correction
   
   param.project_dir = project_dir

   if keyword_set(NoTauCorrect) then param.do_opacity_correction = 0
   if keyword_set(no_polar) then param.no_polar = 1

;; Decorrelation method specificities
   if strupcase(method) eq "TRIPLE" or $
      strupcase(method) eq "SUCCESSIVE" then begin
      param.decor_elevation     = 1
      param.common_mode_array   = 1
      param.common_mode_acqbox  = 1
      param.common_mode_subband = 1
   endif

   if strupcase(method) eq "TRIPLE_POLYNOMIAL" or $
      strupcase(method) eq "SUCCESSIVE_POLYNOMIAL" then begin
      param.decor_method = "triple"
      param.decor_elevation     = 1
      param.common_mode_array   = 1
      param.common_mode_acqbox  = 1
      param.common_mode_subband = 1
      param.polynomial = 3
   endif

   if keyword_set(quick_noise_sim) then begin
      simpar.quick_noise_sim = 1
      param.project_dir += "_quick_noise_sim"
   endif
endelse

;; Deal with simu
if keyword_set(simu) then simu=1 else simu=0

if keyword_set(reset) then nk_reset_filing, param, scan_list[i]

delvarx, info, grid
nk_default_info, info
nk_init_grid, param, info, grid, header=header

;; Quick and dirty
if keyword_set(mask_source) then begin
;;    restore, "mask_source.save"
   restore, "mask_source_sz.save"
   grid.mask_source = mask_source
   delvarx, mask_source
endif

if keyword_set(dry) then begin
   ;; exit to get "param" only"
   return
endif else begin
   ;; Reduce scan
   if keyword_set(simu) then begin
      nk, scan_list[i], param=param, /filing, simpar=simpar, info=info, grid=grid, header=header
   endif else begin
      nk, scan_list[i], param=param, /filing, info=info, grid=grid, header=header
   endelse
endelse


end

