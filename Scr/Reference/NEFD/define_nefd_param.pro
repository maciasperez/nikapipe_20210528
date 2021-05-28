

pro define_nefd_param, param, method_num, source, project_dir, $
                       input_kidpar_file=input_kidpar_file, preproc=preproc, $
                       v19=v19, polydeg=polydeg, boost=boost, reso=reso, $
                       cm_dmin=cm_dmin, freqlow=freqlow, freqhigh=freqhigh, $
                       prefilter=prefilter


if keyword_set(v19) then begin
   nk_default_param, param
   
   param.FLAG_OVLAP =        1
   param.decor_method = "COMMON_MODE_ONE_BLOCK"
   param.NSIGMA_CORR_BLOCK =        1
   param.BANDPASS =        1
   param.FREQHIGH =        7.0000000
   param.W8_PER_SUBSCAN =        1
   param.map_xsize  =        900.00000
   param.MAP_YSIZE  =        900.00000
   param.ATA_FIT_BEAM_RMAX =        60.000000
   param.DO_OPACITY_CORRECTION =        1
   param.DO_TEL_GAIN_CORR =        0
   param.FOURIER_OPT_SAMPLE =        1
   param.ALAIN_RF  =        1
   param.MATH = "RF"
   param.do_aperture_photometry = 0

endif else begin  
   nk_default_param, param

   param.math                 = "RF"
   param.alain_rf             = 1
   param.do_opacity_correction = 2

   param.silent               = 0
   param.map_reso             = 2.d0
   param.ata_fit_beam_rmax    = 60.d0
   param.polynomial           = 0
   param.map_xsize            = 15.*60.d0
   param.map_ysize            = 15.*60.d0
   param.interpol_common_mode = 1
   param.do_plot              = 1
   param.plot_png             = 0
   param.plot_ps              = 1
   param.new_deglitch         = 0
   param.flag_sat             = 0
   param.flag_oor             = 0
   param.flag_ovlap           = 0
   param.line_filter          = 0
   param.fourier_opt_sample   = 1
   param.do_meas_atmo         = 0
   param.w8_per_subscan       = 1
   param.decor_elevation      = 1
   param.version              = 1
   param.do_aperture_photometry = 0

   if method_num eq 1 then begin
      param.flag_sat             = 1
      param.flag_oor             = 1
      param.flag_ovlap           = 1
      param.bandpass = 1
      param.freqhigh = 7.
      param.decor_method = "COMMON_MODE_ONE_BLOCK"
   endif

   if method_num eq 2 then begin
      param.flag_sat             = 1
      param.flag_oor             = 1
      param.flag_ovlap           = 1
      param.bandpass = 1
      param.freqhigh = 7.
      param.decor_method = "COMMON_MODE_ONE_BLOCK"
   endif

   if method_num eq 3 then begin
      param.flag_sat             = 1
      param.flag_oor             = 1
      param.flag_ovlap           = 1
      param.bandpass = 1
      param.freqhigh = 7.
      param.decor_method = "COMMON_MODE_ONE_BLOCK"
      param.lf_sin_fit_n_harmonics = 5
   endif

   if method_num eq 4 then begin
      param.flag_sat             = 1
      param.flag_oor             = 1
      param.flag_ovlap           = 1
      param.bandpass = 0
      param.decor_method = "COMMON_MODE_ONE_BLOCK"
   endif

   if method_num eq 5 then begin
      param.flag_sat             = 1
      param.flag_oor             = 1
      param.flag_ovlap           = 1
      param.bandpass = 0
      param.polynomial = 5
      param.decor_cm_dmin = 60. ; 20.
      param.decor_method = "COMMON_MODE_ONE_BLOCK"
   endif

   if method_num eq 6 then begin
      param.flag_sat             = 1
      param.flag_oor             = 1
      param.flag_ovlap           = 1
      param.bandpass = 0
      param.polynomial = 1
      param.decor_method = "COMMON_MODE_ONE_BLOCK"
   endif

   if method_num eq 7 then begin
      param.flag_sat             = 1
      param.flag_oor             = 1
      param.flag_ovlap           = 1
      param.bandpass = 0
      param.polynomial = 1
      param.do_opacity_correction = 3
      param.decor_method = "COMMON_MODE_ONE_BLOCK"
   endif

   if method_num eq 8 then begin
      param.flag_sat             = 1
      param.flag_oor             = 1
      param.flag_ovlap           = 1
      param.bandpass = 0
      param.polynomial = 1
      param.do_opacity_correction = 2
      param.decor_method = "COMMON_MODE_ONE_BLOCK"
   endif

   if method_num eq 9 then begin
      param.flag_sat             = 1
      param.flag_oor             = 1
      param.flag_ovlap           = 1
      param.bandpass = 0
      param.polynomial = 1
      ;; same as 8 but with opacity correction=1 (to try)
      param.do_opacity_correction = 1
      param.decor_method = "COMMON_MODE_ONE_BLOCK"
   endif

   if method_num eq 11 then begin
      param.flag_sat             = 0
      param.flag_oor             = 0
      param.flag_ovlap           = 0
      param.bandpass = 0
      param.polynomial = 1
      param.do_opacity_correction = 2
      param.decor_method = "COMMON_MODE_ONE_BLOCK"
   endif

   if method_num eq 12 then begin
      param.flag_sat             = 0
      param.flag_oor             = 1
      param.flag_ovlap           = 0
      param.bandpass = 0
      param.polynomial = 1
      param.do_opacity_correction = 2
      param.decor_method = "COMMON_MODE_ONE_BLOCK"
   endif

   if method_num eq 13 then begin
      param.flag_sat             = 0
      param.flag_oor             = 1
      param.flag_ovlap           = 1
      param.bandpass = 0
      param.polynomial = 1
      param.do_opacity_correction = 2
      param.decor_method = "COMMON_MODE_ONE_BLOCK"
   endif

   if method_num eq 14 then begin
      param.flag_sat             = 1
      param.flag_oor             = 1
      param.flag_ovlap           = 1
      param.bandpass = 1
      param.freqlow = 0.1
      param.polynomial = 1
      param.do_opacity_correction = 2
      param.decor_method = "COMMON_MODE_ONE_BLOCK"
   endif

   if method_num eq 15 then begin
      param.flag_sat             = 1
      param.flag_oor             = 1
      param.flag_ovlap           = 1
      param.polynomial = 1
      param.do_opacity_correction = 2

      param.bandpass = 0
      param.flag_uncorr_kid = 1
      param.line_filter = 1

      ;;1st decorrelation
      param.decor_method      = 'common_mode'
      param.decor_per_subscan = 0

      ;;2nd decorrelation
      param.decor_2_method      = 'COMMON_MODE_ONE_BLOCK'
      param.decor_2_per_subscan = 1
      param.n_corr_block_min = 40
      param.set_zero_level_per_subscan = 1
   endif

   if method_num eq 16 then begin
      param.flag_sat             = 1
      param.flag_oor             = 1
      param.flag_ovlap           = 1
      param.bandpass = 1
      param.freqlow = 0.
      param.freqhigh = 4.
      param.polynomial = 1
      param.do_opacity_correction = 2
      param.decor_method = "COMMON_MODE_ONE_BLOCK"
   endif

   ;; Do not mask, common mode but polynomial per subscan
   if method_num eq 17 then begin
      param.flag_sat             = 1
      param.flag_oor             = 1
      param.flag_ovlap           = 1
      param.bandpass             = 0
      param.decor_cm_dmin        = 0.d0
      if keyword_set(polydeg) then param.polynomial = polydeg else param.polynomial = 0
      param.do_opacity_correction = 2
      param.decor_method = "COMMON_MODE"
   endif


   if method_num eq 18 then begin
      ;; Same as 5 but without oor
      param.flag_sat             = 1
      param.flag_oor             = 0
      param.flag_ovlap           = 1
      param.bandpass = 0
      param.polynomial = 5
      param.decor_method = "COMMON_MODE_ONE_BLOCK"
   endif

   if method_num eq 19 then begin
      ;; Same as 5 but without oor + beam_wiener_filter
      param.flag_sat             = 1
      param.flag_oor             = 0
      param.flag_ovlap           = 1
      param.bandpass = 0
      param.polynomial = 5
      param.decor_cm_dmin = 20.
      param.decor_method = "COMMON_MODE_ONE_BLOCK"
   endif

   if method_num eq 20 then begin
      ;; Same as 5 but without oor + raw_wiener filter and no zero levels
      param.flag_sat             = 1
      param.flag_oor             = 0
      param.flag_ovlap           = 1
      param.bandpass = 0
      param.polynomial = 0
      param.decor_cm_dmin = 20.
      param.decor_method = "raw_wiener"
      param.set_zero_level_full_scan = 0
      param.set_zero_level_per_subscan = 0
   endif

   if method_num eq 21 then begin
      ;; Same as 5 but without oor + raw_wiener filter and no zero levels
      param.flag_sat             = 1
      param.flag_oor             = 0
      param.flag_ovlap           = 1
      param.bandpass = 0
      param.polynomial = 0
      param.decor_cm_dmin = 20.
      param.decor_method = "common_mode_one_block"
      param.prefilter = 1
      param.fourier_opt_sample = 1
      param.set_zero_level_full_scan = 0
      param.set_zero_level_per_subscan = 0
   endif

   if method_num eq 22 then begin
      ;; Same as 5 but decorrelating from all kids in block rather
      ;; than their CM
      param.flag_sat             = 1
      param.flag_oor             = 0
      param.flag_ovlap           = 1
      param.bandpass = 0
      param.polynomial = 0
      param.decor_cm_dmin = 60 ; 20.
      param.decor_method = "common_mode_one_block"
      param.decor_all_kids_in_block = 1
      param.prefilter = 0
      param.fourier_opt_sample = 1
      param.set_zero_level_full_scan = 0
      param.set_zero_level_per_subscan = 0
      param.map_xsize            = 5.*60.d0
      param.map_ysize            = 5.*60.d0
   endif

   if method_num eq 23 then begin
      ;; Same as 22 + prefilter with beam and wiener
      param.flag_sat             = 1
      param.flag_oor             = 0
      param.flag_ovlap           = 1
      param.bandpass = 0
      param.polynomial = 0
      param.decor_cm_dmin = 20.
      param.decor_method = "common_mode_one_block"
      param.decor_all_kids_in_block = 1
      param.prefilter = 1
      param.fourier_opt_sample = 1
      param.set_zero_level_full_scan = 0
      param.set_zero_level_per_subscan = 0
      param.map_xsize            = 5.*60.d0
      param.map_ysize            = 5.*60.d0
   endif

   if method_num eq 24 then begin
      ;; Same as 22 + prefilter with beam and wiener and only one
      ;; common mode per block
      param.flag_sat             = 1
      param.flag_oor             = 0
      param.flag_ovlap           = 1
      param.bandpass = 0
      param.polynomial = 0
      param.decor_cm_dmin = 20.
      param.decor_method = "common_mode_one_block"
      param.decor_all_kids_in_block = 0
      param.prefilter = 1
      param.fourier_opt_sample = 1
      param.set_zero_level_full_scan = 0
      param.set_zero_level_per_subscan = 0
      param.map_xsize            = 5.*60.d0
      param.map_ysize            = 5.*60.d0
   endif
   
   if method_num eq 25 then begin
      ;; Same as 5 and 22 but decorrelating from all kids in block rather
      ;; than their CM and also subtracting zero levels and polynomials
      param.flag_sat             = 1
      param.flag_oor             = 0
      param.flag_ovlap           = 1
      param.bandpass = 0
      param.polynomial = 5
      param.decor_cm_dmin = 60. ; 20.
      param.decor_method = "common_mode_one_block"
      param.decor_all_kids_in_block = 1
      param.prefilter = 0
      param.fourier_opt_sample = 1
      param.set_zero_level_full_scan = 0
      param.set_zero_level_per_subscan = 1
      param.map_xsize = 15.*60.d0
      param.map_ysize = 15.*60.d0
   endif

   if method_num eq 26 then begin
      ;; no more polynomial 5 that induces striping
      ;; one block classic
      param.flag_sat             = 1
      param.flag_oor             = 0
      param.flag_ovlap           = 1
      param.bandpass = 0
      param.polynomial = 1
      param.decor_method = "common_mode_one_block"
      param.decor_all_kids_in_block = 0
      param.prefilter = 0
      param.fourier_opt_sample = 1
      param.set_zero_level_full_scan = 0
      param.set_zero_level_per_subscan = 1
      param.map_xsize = 15.*60.d0
      param.map_ysize = 15.*60.d0
   endif

   if method_num eq 27 then begin
      ;; no more polynomial 5 that induces striping
      ;; all kids in block
      param.flag_sat             = 1
      param.flag_oor             = 0
      param.flag_ovlap           = 1
      param.bandpass = 0
      param.polynomial = 1
      param.decor_method = "common_mode_one_block"
      param.decor_all_kids_in_block = 1
      param.prefilter = 0
      param.fourier_opt_sample = 1
      param.set_zero_level_full_scan = 0
      param.set_zero_level_per_subscan = 1
      param.map_xsize = 15.*60.d0
      param.map_ysize = 15.*60.d0
   endif

   if method_num eq 28 then begin
      ;; no more polynomial 5 that induces striping
      ;; all kids in block
      param.flag_sat             = 1
      param.flag_oor             = 0
      param.flag_ovlap           = 1
      param.bandpass = 0
      param.polynomial = 1
      param.decor_method = "common_mode_kids_out"
      param.prefilter = 0
      param.fourier_opt_sample = 1
      param.set_zero_level_full_scan = 0
      param.set_zero_level_per_subscan = 1
      param.map_xsize = 15.*60.d0
      param.map_ysize = 15.*60.d0
   endif

   if method_num eq 29 then begin
      ;; save as 26 + lowpass
      param.flag_sat             = 1
      param.flag_oor             = 0
      param.flag_ovlap           = 1
      param.bandpass = 1
      param.freqhigh = 7.
      param.polynomial = 1
      param.decor_method = "common_mode_one_block"
      param.decor_all_kids_in_block = 0
      param.prefilter = 0
      param.fourier_opt_sample = 1
      param.set_zero_level_full_scan = 0
      param.set_zero_level_per_subscan = 1
      param.map_xsize = 15.*60.d0
      param.map_ysize = 15.*60.d0
   endif

   if method_num eq 30 then begin
      ;; all kids in block but dist_min=100
      param.flag_sat             = 1
      param.flag_oor             = 0
      param.flag_ovlap           = 1
      param.bandpass = 0
      param.polynomial = 0
      param.decor_method = "common_mode_one_block"
      param.decor_all_kids_in_block = 1
      param.dist_min_between_kids = 100.
      param.prefilter = 0
      param.fourier_opt_sample = 1
      param.set_zero_level_full_scan = 0
      param.set_zero_level_per_subscan = 1
      param.map_xsize = 15.*60.d0
      param.map_ysize = 15.*60.d0
   endif

   if method_num eq 31 then begin
      ;; all kids in block but dist_min=30 and polynomial 1
      param.flag_sat             = 1
      param.flag_oor             = 0
      param.flag_ovlap           = 1
      param.bandpass = 0
      param.polynomial = 1
      param.decor_method = "common_mode_one_block"
      param.decor_all_kids_in_block = 1
      param.dist_min_between_kids = 30.
      param.prefilter = 0
      param.fourier_opt_sample = 1
      param.set_zero_level_full_scan = 0
      param.set_zero_level_per_subscan = 1
      param.map_xsize = 15.*60.d0
      param.map_ysize = 15.*60.d0
   endif

   if method_num eq 32 then begin
      ;; classic common mode one block but with dmin=0 to compare to
      ;; method #26
      param.flag_sat             = 1
      param.flag_oor             = 0
      param.flag_ovlap           = 1
      param.bandpass = 0
      param.polynomial = 1
      param.decor_method = "common_mode_one_block"
      param.decor_cm_dmin = 0.d0
      param.decor_all_kids_in_block = 0
      param.dist_min_between_kids = 0.
      param.prefilter = 0
      param.fourier_opt_sample = 1
      param.set_zero_level_full_scan = 0
      param.set_zero_level_per_subscan = 1
      param.map_xsize = 15.*60.d0
      param.map_ysize = 15.*60.d0
   endif

endelse

if keyword_set(input_kidpar_file) then begin
   param.force_kidpar = 1
   param.file_kidpar = input_kidpar_file
endif
param.source    = source
param.name4file = source
if keyword_set(preproc) then param.preproc_copy = 1 else param.preproc_copy = 0
param.preproc_dir = !nika.plot_dir+"/Preproc"

param.project_dir = project_dir

if keyword_set(boost) then param.boost = 1
if keyword_set(reso) then param.map_reso = reso
if keyword_set(cm_dmin) then param.decor_cm_dmin = 20.d0
if keyword_set(freqlow) then begin
   param.bandpass = 1
   param.freqlow = freqlow
endif

if keyword_set(freqhigh) then begin
   param.bandpass = 1
   param.freqhigh = freqhigh
endif

;if keyword_set(prefilter) then begin
;   param.prefilter = prefilter[0]
;   param.prefilter_freqlow = prefilter[1]
;   param.prefilter_freqhigh = prefilter[2]
;   param.bandpass_delta_f = 0.02
;endif


end
