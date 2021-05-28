
pro point_source_default_param, param, simpar, method, source, $
                                decor2=decor2, input_kidpar_file=input_kidpar_file, reso=reso, $
                                map_proj=map_proj, ata_fit_beam_rmax=ata_fit_beam_rmax, $
                                polynomial=polynomial, do_tel_gain_corr=do_tel_gain_corr, $
                                mask_default_radius=mask_default_radius, $
                                opacity_correction=opacity_correction


;; Add a fake point sources a bit off center to make sure
nks_init, simpar, n_ps=1
simpar.reset = 1
simpar.polar = 0
simpar.ps_flux_1mm[0] = 0.035          ;Jansky
simpar.ps_flux_2mm[0] = 0.005          ;Jansky
simpar.ps_offset_x[0] = 0.d0
simpar.ps_offset_y[0] = 0.d0
;; simpar.ps_flux_1mm[1] = 0.005          ;Jansky
;; simpar.ps_flux_2mm[1] = 0.005          ;Jansky
;; simpar.ps_offset_x[1] = -80.d0
;; simpar.ps_offset_y[1] = -80.d0
;; sim_dir_ext = '2ps'
sim_dir_ext = '1ps'

;; Param
nk_default_param, param
param.silent               = 0
param.map_reso             = 2.d0

if keyword_set(map_proj) then param.map_proj = map_proj

if keyword_set(reso) then param.map_reso = float(reso)

if keyword_set(ata_fit_beam_rmax) then param.ata_fit_beam_rmax=ata_fit_beam_rmax else $
   param.ata_fit_beam_rmax = 60.0d0
if keyword_set(polynomial) then param.polynomial = polynomial else param.polynomial = 0

param.map_xsize            = 1200.d0
param.map_ysize            = 1200.d0
param.do_meas_atmo         = 0
param.interpol_common_mode = 1
param.do_plot              = 1
param.plot_png             = 1
param.plot_ps              = 0
param.new_deglitch         = 0 
param.flag_sat             = 0
param.flag_oor             = 0 
param.flag_ovlap           = 1 
param.line_filter          = 0 
param.bandpass             = 0
param.NSIGMA_CORR_BLOCK    = 1
param.fourier_opt_sample   = 1
param.do_meas_atmo         = 0
param.w8_per_subscan       = 1
param.decor_per_subscan    = 1
param.decor_elevation      = 1
param.version              = 1
param.math                 = 'RF' ; "PF" ; RF leads to saturated stripes

param.decor_method = method
if keyword_set(mask_default_radius) then param.mask_default_radius = mask_default_radius else param.mask_default_radius = 40.0

param.do_opacity_correction = 4 ;; continuous skydip tau per array
if keyword_set(opacity_correction) then param.do_opacity_correction = opacity_correction
;;if keyword_set(corrected_skydip) then param.correct_tau = 1 else param.correct_tau = 0

param.do_tel_gain_corr = 0
if keyword_set(do_tel_gain_corr) then param.do_tel_gain_corr = do_tel_gain_corr

param.preproc_copy = 0
param.preproc_dir = !nika.plot_dir+"/Preproc"

param.source    = source
param.name4file = source

if keyword_set(decor2) then begin
   param.bandpass = 0
   param.flag_uncorr_kid = 1
   param.flag_sat = 1
   param.line_filter = 1

   ;;1st decorrelation
   param.decor_method      = 'common_mode'
   param.decor_per_subscan = 0

   ;;2nd decorrelation
   param.decor_2_method      = 'COMMON_MODE_ONE_BLOCK'
   param.decor_2_per_subscan = 1
   param.n_corr_block_min = 40
   param.polynomial = 3
   param.set_zero_level_per_subscan = 1
endif

if keyword_set(input_kidpar_file) then begin
   if strlen(input_kidpar_file) gt 1 then begin
      param.force_kidpar = 1
      param.file_kidpar = input_kidpar_file
   endif
endif

end

