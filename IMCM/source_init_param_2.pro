
;; Launch several types of reduction on all G2 scans
;; Calls Labtools/NP/Dev/source_analysis.pro
;;=========================================================
;+
pro source_init_param_2, source, mask_default_radius, param, root_dir, nickname, $
                         method_num=method_num, status=status, $
                         grid=grid, subtract_maps=subtract_maps, extended_source=extended_source
;-

if n_params() lt 1 then begin
   dl_unix, 'source_init_param_2'
   return
endif

status = 0 ; default

;; Define parameters
nk_default_param, param

param.mask_default_radius = mask_default_radius

param.clean_data_version = 4

param.nhits_min_bg_var_map = 1

param.one_fitsmap_per_scan = 0
;; param.do_opacity_correction = 4 ; 2
param.map_xsize = 1000.
param.map_ysize = 1000.

param.do_rfpipq = 0

if strupcase(source) eq "GASTON" then begin
   param.map_xsize = 10800.
   param.map_ysize = 10800.
   param.map_center_ra  = 278.75
   param.map_center_dec = -8.d0
endif

if strupcase(source) eq "CRAB" then begin
   param.map_xsize             = 15.*60.
   param.map_ysize             = 15*60.
   param.polar_lockin_freqhigh = 6.d0
endif

param.silent               = 0 ; 1

param.map_reso = 2.d0
param.map_proj = 'radec'
param.math                 = "CF" ; "RF"
param.alain_rf             = 1
param.ata_fit_beam_rmax    = 60.d0
param.interpol_common_mode = 1

param.do_plot              = 0
param.plot_png             = 0
param.plot_ps              = 0

param.new_deglitch         = 0
param.fast_deglitch        = 0

param.line_filter          = 0
param.fourier_opt_sample   = 1
param.polynomial           = 0
param.do_meas_atmo         = 0
param.w8_per_subscan       = 1
param.decor_elevation      = 1
param.version              = 1
param.do_aperture_photometry = 0
param.source    = source
param.name4file = source
param.preproc_copy = 1
param.preproc_dir = !nika.preproc_dir

if keyword_set(extended_source) then param.extended_source = 1


if keyword_set(method_num) then begin
   param.method_num = long(method_num)
   
   case method_num of
      1: begin
         param.decor_method = "common_mode_kids_out" ; for ref, even if know not to be optimal
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method
      end

      2: begin
         param.decor_method = "common_mode_one_block" ; for ref, even if know not to be optimal
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method
         param.do_opacity_correction = 4
      end

      3: begin
         param.decor_method = 'common_mode_one_block'
         param.decor_all_kids_in_block = 1
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)+"_"+param.decor_method+"_AllKidsInBlock"
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_AllKidsInBlock"
      end

      4: begin
         param.decor_method = "atm_and_all_box_iter" ; global atm + decor from all boxes at the same time
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)+"_"+param.decor_method+"_decorFullScan"
         param.decor_per_subscan=0
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorFullScan"
      end

      5: begin
         param.decor_method = "atm_and_all_box_iter" ; global atm + decor from all boxes at the same time
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan"
         param.decor_per_subscan=1
         param.subtract_pos_signal_only = 1
         param.set_zero_level_full_scan = 0
         param.set_zero_level_per_subscan = 0
         param.mask_default_radius = 0 ; no mask
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan"
      end

      6: begin
         param.decor_method = "atm_and_all_box_iter" ; for ref, even if known not to be optimal
         param.cos_sin_elev_offset = 1
         param.decor_per_subscan=1
         param.set_zero_level_full_scan = 0
         param.set_zero_level_per_subscan = 0
         ;; param.project_dir  = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)+"_"+param.decor_method+"_IterativeMM_CosSinElevOffset"
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_IterativeMM_CosSinElevOffset"
      end

      7:begin
         param.decor_method = "ATM_DERIV_ONE_BOX"
         ;; No zero level in this mode since the constants are
         ;; determined at the same time as the coeffs on the modes by "regress"
         param.set_zero_level_full_scan = 0
         param.set_zero_level_per_subscan = 0
         ;; param.project_dir  = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)+"_"+param.decor_method
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method
      end

      8:begin
         param.decor_method = 'raw_median' ; for reference
         ;; param.project_dir  = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         param.set_zero_level_full_scan = 0
         param.set_zero_level_per_subscan = 1
         param.decor_per_subscan=1         
         param.polynomial = 1
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method
      end

      9:begin
         ;; start from method 5 and add Fourier filtering after decorrelation to try a more
         ;; agressive strategy
         param.decor_method = "atm_and_all_box_iter"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_HighPass"
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_HighPass"
         param.decor_per_subscan=1
         param.set_zero_level_full_scan = 0
         param.set_zero_level_per_subscan = 0
         param.bandpass = 1
         param.freqlow = 0.08
      end

;;       10:begin
;;          ;; Start from method 5 and notch filter the Pulse Tube line at 2mm
;;          param.decor_method = "atm_and_all_box_iter"
;;          ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan"
;;          param.decor_per_subscan=1
;;          param.set_zero_level_full_scan = 0
;;          param.set_zero_level_per_subscan = 0
;;          param.notch_filter = 1
;;          param.notch_freq_min = 
;;          param.notch_freq_max = 
;;       end
 
      11:begin
         ;; test CF method on common_mode_one_block
         param.decor_method = "common_mode_one_block" ; for ref, even if known not to be optimal
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)+"_"+param.decor_method+"_CF"
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_CF"
         param.math = "CF"
      end

      12:begin
         param.decor_method = "atm_common_mode_box"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method
      end

      13:begin
         param.decor_method = "atm_common_mode_one_block"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method
      end

      14:begin
         param.decor_method = 'ATM_COMMON_MODE_ONE_BLOCK_ITER'
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)+"_"+param.decor_method
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method
      end

      ;; With the new formula for opacities
      15:begin
         param.decor_method = "common_mode_one_block" ; for ref, even if know not to be optimal
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         param.do_opacity_correction = 6

         param.decor_qu              = 1

         if strupcase(source) eq "GRB1" or strupcase(source) eq "GRB2" then begin
            param.force_kidpar = 1
            param.file_kidpar = !nika.off_proc_dir+"/kidpar_n2r26_recal_method15.fits"
            message, /info, "FORCING KIDPAR FILE = "+param.file_kidpar
            stop
         endif
      end

      ;; With the new formula for opacities
      16: begin
         param.decor_method = "atm_and_all_box_iter" ; global atm + decor from all boxes at the same time
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_CorrectedTau"
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_CorrectedTau"
         param.decor_per_subscan=1
         param.set_zero_level_full_scan = 0
         param.set_zero_level_per_subscan = 0
         ;;param.correct_tau = 1
         param.do_opacity_correction = 6
      end

      ;; for a test
      17:begin
         param.decor_method = 'common_mode_box'
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)+"_"+param.decor_method
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method
      end

      ;; only all electronic boxes
      18: begin
         param.decor_method = "all_box" ; global atm + decor from all boxes at the same time
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan"
         param.decor_per_subscan=1
         param.set_zero_level_full_scan = 0
         param.set_zero_level_per_subscan = 0
      end

      ;; only all electronic boxes and notch filter around what seems
      ;; to be peak at 1.4Hz
      19: begin
         param.decor_method = "all_box" ; global atm + decor from all boxes at the same time
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_NotchFilter"
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_NotchFilter"
         param.decor_per_subscan = 1
         param.set_zero_level_full_scan = 0
         ;; Recompute zero level because the notch filter biases the
         ;; average that has been taken out by the all_box decorr
         param.set_zero_level_per_subscan = 1
         param.notch_filter = 1
         param.notch_freq_min = 1.3
         param.notch_freq_max = 1.5
      end

      ;; only all electronic boxes and lowpass at 8Hz
      20: begin
         param.decor_method = "all_box" ; global atm + decor from all boxes at the same time
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_LowPass8Hz"
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_LowPass8Hz"
         param.decor_per_subscan = 1
         param.set_zero_level_full_scan = 0
         ;; Recompute zero level because the Fourier filter biases the
         ;; average that has been taken out by the all_box decorr
         param.set_zero_level_per_subscan = 1
         param.bandpass = 1
         param.freqlow = 0.d0
         param.freqhigh = 8.d0
      end

      ;; only all electronic boxes, new tau formula
      21: begin
         param.decor_method = "all_box" ; global atm + decor from all boxes at the same time
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_CorrectedTau"
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_CorrectedTau"
         param.correct_tau = 1
         param.decor_per_subscan=1
         param.set_zero_level_full_scan = 0
         param.set_zero_level_per_subscan = 0
      end

      ;; Try to highpass...
      22: begin
         param.decor_method = "all_box" ; global atm + decor from all boxes at the same time
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_HighPass0.1Hz"
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_HighPass0.1Hz"
         param.decor_per_subscan=1
         param.set_zero_level_per_subscan = 1
         param.bandpass = 1
         param.freqlow = 0.1
         param.correct_tau = 1
      end

      ;; Try to highpass...
      23: begin
         param.decor_method = "all_box" ; global atm + decor from all boxes at the same time
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_HighPass0.2Hz"
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_HighPass0.2Hz"
         param.decor_per_subscan=1
         param.set_zero_level_per_subscan = 1
         param.bandpass = 1
         param.freqlow = 0.2
         param.correct_tau = 1
      end

      ;; Try to highpass...
      24: begin
         param.decor_method = "all_box" ; global atm + decor from all boxes at the same time
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_HighPass0.05Hz"
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_HighPass0.05Hz"
         param.decor_per_subscan=1
         param.set_zero_level_per_subscan = 1
         param.bandpass = 1
         param.freqlow = 0.05
         param.correct_tau = 1
      end

      ;; Try to highpass...
      25: begin
         param.decor_method = "all_box" ; global atm + decor from all boxes at the same time
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_HighPass0.25Hz"
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_HighPass0.25Hz"
         param.decor_per_subscan=1
         param.set_zero_level_per_subscan = 1
         param.bandpass = 1
         param.freqlow = 0.25
         param.correct_tau = 1
      end

      ;; Brute force highpass to compare to decorr+highpass
      26: begin
         param.decor_method = "none" ; global atm + decor from all boxes at the same time
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_HighPass0.2Hz"
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_HighPass0.2Hz"
         param.decor_per_subscan=1
         param.set_zero_level_per_subscan = 1
         param.bandpass = 1
         param.freqlow = 0.2
         param.correct_tau = 1
      end

      ;; Crude decorr then bandpass
      27: begin
         param.decor_method = "common_mode_kids_out" ; global atm + decor from all boxes at the same time
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_HighPass0.2Hz"
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_HighPass0.2Hz"
         param.decor_per_subscan=1
         param.set_zero_level_per_subscan = 1
         param.bandpass = 1
         param.freqlow = 0.2
         param.correct_tau = 1
      end

      ;; all box and polynomial
      28: begin
         ;;param.decor_method = "all_box" ; global  decor from all boxes at the same time
         param.decor_method = "atm_and_all_box_iter" ; global atm + decor from all boxes at the same time
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_Poly5"
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_Poly5"
         param.decor_per_subscan=1
         param.set_zero_level_full_scan = 0
         param.set_zero_level_per_subscan = 0
         param.polynomial = 5
         param.correct_tau = 1
      end

      ;; Iterating on the determination of atm and all boxes
      29: begin
         param.decor_method = "atm_and_all_box_iter" ; global atm + decor from all boxes at the same time
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_CorrectedTau"
         param.decor_per_subscan=1
         param.set_zero_level_full_scan = 0
         param.set_zero_level_per_subscan = 0
         param.correct_tau = 1
      end 

      ;; Iterating on the determination of atm and all boxes
      30: begin
         param.decor_method = "atm_and_all_box_iter" ; global atm + decor from all boxes at the same time
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_CorrectedTau_IterFullDecorr"
         param.decor_per_subscan=1
         param.set_zero_level_full_scan = 0
         param.set_zero_level_per_subscan = 0
         param.n_iter_full_decorr = 2
         param.correct_tau = 1
      end 

      ;; Iterating on the determination of atm and all boxes
      31: begin
         param.decor_method = "atm_and_all_box_iter" ; global atm + decor from all boxes at the same time
         param.n_iter_atm_and_all_box = 3
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_CorrectedTau_IterFullDecorr"
         param.decor_per_subscan=1
         param.set_zero_level_full_scan = 0
         param.set_zero_level_per_subscan = 0
         param.n_iter_full_decorr = 2
         param.correct_tau = 1
      end 

      ;; all box and polynomial
      32: begin
         param.decor_method = "atm_and_all_box_iter" ; global atm + decor from all boxes at the same time
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_Poly5_oldTauFormula"
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_Poly5_oldTauFormula"
         param.decor_per_subscan=1
         param.set_zero_level_full_scan = 0
         param.set_zero_level_per_subscan = 0
         param.polynomial = 5
;         param.correct_tau = 0
      end

      ;; CF !
      33: begin
         param.math = "CF"
         param.decor_method = "atm_and_all_box_iter" ; global atm + decor from all boxes at the same time
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_CorrectedTau_CF"
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_CorrectedTau"
         param.decor_per_subscan = 1
         param.subtract_pos_signal_only = 1
         param.mask_default_radius = 0 ; no mask
         param.set_zero_level_full_scan = 0
         param.set_zero_level_per_subscan = 0
      end

      34:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)+"_"+param.decor_method+"_decorFullScan"
         param.decor_per_subscan=0
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorFullScan"
         param.k_snr_w8_decor = 1.d0
         param.subtract_pos_signal_only = 1
      end

      35:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)+"_"+param.decor_method+"_decorFullScan_ImproveLockin"
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorFullScan_ImproveLockin"

         param.k_snr_w8_decor           = 1.d0
         param.subtract_pos_signal_only = 1

         param.decor_per_subscan              = 0
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0

         ;;*************
         param.simul_atmosphere_leakage = 0
         ;;*************
         param.do_opacity_correction = 6
         
         param.qu_iterative_mm                = 1
         param.improve_lockin                 = 1
         param.decor_qu                       = 1
         param.force_subtract_hwp_per_subscan = 0
         param.hwp_harmonics_only             = 1
         param.polar_n_template_harmonics     = 5
      end
      
      ;; like 35 but with zero_level per subscan (for the GRB)
      36: begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8" ; global atm + decor from all boxes at the same time
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_CorrectedTau"
         param.decor_per_subscan          = 1
         param.subtract_pos_signal_only   = 1
         param.k_snr_w8_decor             = 1.d0
         param.set_zero_level_full_scan   = 0
         param.set_zero_level_per_subscan = 0 ; with the decor method, no extra zero level to subtract
         param.do_opacity_correction      = 6
         
         param.mask_default_radius = 0 ; to have no mask ("off_source" in nk_decor_sub_6) at the 1st iteration

         param.debug = 0
         
      end

      ;; NO OPACITY CORRECTION TO TRY
      37: begin
         param.decor_method = "atm_and_all_box_iter" ; global atm + decor from all boxes at the same time
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_CorrectedTau"
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_CorrectedTau"
         param.decor_per_subscan          = 1
         param.subtract_pos_signal_only   = 1
         param.k_snr_w8_decor             = 1.d0
         param.set_zero_level_full_scan   = 0
         param.set_zero_level_per_subscan = 0 ; with the decor method, no extra zero level to subtract
         param.do_opacity_correction      = 0
      end

      ;; common_mode_one_block per subscan, zero level per subscan,
      ;; smaller mask, new opacity formula
      38: begin
         param.decor_method = "common_mode_one_block"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_CorrectedTau"
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_CorrectedTau"
         param.decor_per_subscan          = 1
         param.set_zero_level_full_scan   = 0
         param.set_zero_level_per_subscan = 1
         param.mask_default_radius = 40. ; smaller than usual
         param.do_opacity_correction      = 6
      end

      ;; Same as 36 but forcig tau225 for a comparison
      39: begin
         param.decor_method = "common_mode_one_block"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_CorrectedTau"
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan_CorrectedTau"
         param.decor_per_subscan          = 1
         param.set_zero_level_full_scan   = 0
         param.set_zero_level_per_subscan = 1
         param.mask_default_radius = 40. ; smaller than usual

         param.do_opacity_correction      = 1
         param.force_opacity_225          = 1
      end

      ;; Trying iterative MM on SZ
      40:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)+"_"+param.decor_method+"_decorFullScan_ImproveLockin"
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorFullScan_ImproveLockin"

         param.k_snr_w8_decor           = 1.d0
         param.subtract_pos_signal_only = 0

         param.decor_per_subscan              = 0
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
      end

      ;; Try to improve the GRB
      41:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan"
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan"
         param.k_snr_w8_decor                 = 1.d0
         param.subtract_pos_signal_only       = 1
         param.decor_per_subscan              = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
      end

      ;; Try to improve the GRB, no opacity correction to test
      42:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan"
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan"
         param.k_snr_w8_decor                 = 1.d0
         param.subtract_pos_signal_only       = 1
         param.decor_per_subscan              = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0

         param.do_opacity_correction          = 0
      end

      ;; Try to improve the GRB, tau225 opacity
      43:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan"
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan"
         param.k_snr_w8_decor                 = 1.d0
         param.subtract_pos_signal_only       = 1
         param.decor_per_subscan              = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0

         param.force_opacity_225              = 1
      end

      ;; Constant elevation correction with tau225 to try...
      44:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan"
         param.k_snr_w8_decor                 = 1.d0
         param.subtract_pos_signal_only       = 1
         param.decor_per_subscan              = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0

         param.force_opacity_225                = 1
         param.force_constant_elevation_opacorr = 1
      end

      ;; 44 + zero level per subscan (even post decorr see if it improves)
      45:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan"
         param.k_snr_w8_decor                 = 1.d0
         param.subtract_pos_signal_only       = 1
         param.decor_per_subscan              = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 1

         param.force_opacity_225                = 1
         param.force_constant_elevation_opacorr = 1
      end

      46:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorFullScan_ImproveLockin"

         param.k_snr_w8_decor           = 1.d0
         param.subtract_pos_signal_only = 1

         param.decor_per_subscan              = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0

         ;;*************
         param.simul_atmosphere_leakage = 0
         ;;*************
         param.do_opacity_correction = 6
         
         param.qu_iterative_mm                = 1
         param.improve_lockin                 = 1
         param.decor_qu                       = 1
         param.force_subtract_hwp_per_subscan = 1
         param.hwp_harmonics_only             = 1
         param.polar_n_template_harmonics     = 5
      end

      47:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorFullScan_ImproveLockin"

         param.k_snr_w8_decor           = 1.d0
         param.subtract_pos_signal_only = 1

         param.decor_per_subscan              = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0

         ;;*************
         param.simul_atmosphere_leakage = 0
         ;;*************
         param.do_opacity_correction = 6
         
         param.qu_iterative_mm                = 1
         param.improve_lockin                 = 1
         param.decor_qu                       = 1
         param.force_subtract_hwp_per_subscan = 1
         param.hwp_harmonics_only             = 1
         param.polar_n_template_harmonics     = 5
      end

      ;; 45 + opacorr = 6
      48:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan"
         param.k_snr_w8_decor                 = 1.d0
         param.subtract_pos_signal_only       = 1
         param.decor_per_subscan              = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 1

         param.do_opacity_correction = 6
      end

      ;; No subtraction of signal, just snr in the common mode estimation
      49:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan"
         param.k_snr_w8_decor                 = 1.d0
         param.subtract_pos_signal_only       = 1
         param.decor_per_subscan              = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 1

         param.do_opacity_correction = 6
         param.subtract_frac = 0.d0
      end

      ;; Subtraction of the signal but no snr_w8
      50:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan"
         param.subtract_pos_signal_only       = 1
         param.decor_per_subscan              = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 1

         param.do_opacity_correction = 6
         param.subtract_frac  = 1.d0
         param.k_snr_w8_decor = 0.d0
      end

      ;; Mask out sources, no weight
      51:begin
         param.decor_method = "ATM_AND_ALL_BOX_ITER"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan"
         param.subtract_pos_signal_only       = 1
         param.decor_per_subscan              = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 1

         param.do_opacity_correction = 6

         param.subtract_frac  = 0.d0
         param.k_snr_w8_decor = 0.d0

         param.use_iter_mask = 1
      end

      ;; Mask out sources, no weight + fourier
      52:begin
         param.decor_method = "ATM_AND_ALL_BOX_ITER"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan"
         param.subtract_pos_signal_only       = 1
         param.decor_per_subscan              = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 1

         param.do_opacity_correction = 6

         param.subtract_frac  = 0.d0
         param.k_snr_w8_decor = 0.d0
         
         param.bandpass = 1
         param.freqlow = 1./12

         param.use_iter_mask = 1
      end

      ;; Mask out sources, no weight + fourier
      53:begin
         param.decor_method = "ATM_AND_ALL_BOX_ITER"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan"
         param.subtract_pos_signal_only       = 1
         param.decor_per_subscan              = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 1

         param.do_opacity_correction = 6

         param.subtract_frac  = 0.d0
         param.k_snr_w8_decor = 0.d0
         
         param.bandpass = 1
         param.freqlow = 2./12

         param.use_iter_mask = 1
      end
      
      ;; Mask out sources, no weight + Fourier off_source (constrained
      ;; noise realization + interpolation)
      54:begin
         param.decor_method = "ATM_AND_ALL_BOX_ITER"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan"
         param.subtract_pos_signal_only       = 1
         param.decor_per_subscan              = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 1

         param.do_opacity_correction = 6

         param.subtract_frac  = 0.d0
         param.k_snr_w8_decor = 0.d0

         param.use_iter_mask = 1
         param.off_source_fourier = 1
         param.freqlow = 1./12d0
      end

      ;; Same as 54 but with tau225
      56:begin
         param.decor_method = "ATM_AND_ALL_BOX_ITER"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan"
         param.subtract_pos_signal_only       = 1
         param.decor_per_subscan              = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 1

         param.do_opacity_correction = 1
         param.force_opacity_225     = 1

         param.subtract_frac  = 1.d0 ; 0.d0
         param.k_snr_w8_decor = 0.d0

         param.use_iter_mask = 0 ; 1
         param.off_source_fourier = 0 ; 1
         param.polynomial = 0
         param.freqlow = 1./12d0
      end

      ;; tau225 and subtract previsou iteration before fourier
      ;; filtering instead of interpolating of the mask's holes
      57:begin
         param.decor_method = "ATM_AND_ALL_BOX_ITER"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan"
         param.subtract_pos_signal_only       = 1
         param.decor_per_subscan              = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 1

         param.do_opacity_correction = 1
         param.force_opacity_225     = 1

         param.subtract_frac  = 0.d0
         param.k_snr_w8_decor = 0.d0

         param.use_iter_mask = 1
         param.off_source_fourier = 0
         param.fourier_subtract = 1
         param.freqlow = 1./12d0
      end

      ;; Decor per scan and polynomials per subscan
      59:begin
         param.decor_method = "ATM_AND_ALL_BOX_ITER"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)+"_"+param.decor_method+"_decorPerSubscan"
         param.subtract_pos_signal_only       = 1

         param.decor_per_subscan              = 0
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0

         param.polynomial = 5

         param.do_opacity_correction = 1
         param.force_opacity_225     = 1

         param.subtract_frac  = 0.d0
         param.k_snr_w8_decor = 0.d0

;         param.use_iter_mask = 1
;         param.off_source_fourier = 0
;         param.fourier_subtract = 1
;         param.freqlow = 1./12d0
      end

      ;;=========================================================================================================
      ;; Restart fresh...

      ;; default is to use the mask derived based on smoothed SNR
      ;; after each iteration and therefore to mask out the data for
      ;; decorrelation where there are bright spots.
      60:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)

         if strupcase(source) eq "GRB1" or strupcase(source) eq "GRB2" then begin
            param.force_kidpar = 1
            param.file_kidpar = !nika.off_proc_dir+"/kidpar_n2r26_recal_method60.fits"
         endif

         param.do_opacity_correction = 1
         param.force_opacity_225     = 1

         param.subtract_pos_signal_only       = 1
         param.subtract_frac                  = 0.d0
         param.k_snr_w8_decor                 = 0.d0

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0

         param.subtract_i_map = 1
         
         param.bandpass       = 0 ; 1
         param.freqlow        = 0 ; 1./12
      end

      61:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)

         param.do_opacity_correction = 1
         param.force_opacity_225     = 1

         param.subtract_pos_signal_only       = 1
         param.subtract_frac                  = 1.d0
         param.k_snr_w8_decor                 = 0.d0

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0

         param.subtract_i_map = 1
         
         param.bandpass       = 0 ; 1
         param.freqlow        = 0 ; 1./12
      end

      62:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 1
         param.force_opacity_225     = 1

         param.subtract_pos_signal_only       = 1
         param.subtract_frac                  = 0.d0
         param.k_snr_w8_decor                 = 1.d0

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0

         param.subtract_i_map = 1
         
         param.bandpass       = 0 ; 1
         param.freqlow        = 0 ; 1./12
      end

      63:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 1
         param.force_opacity_225     = 1
         
         param.subtract_pos_signal_only       = 1
         param.subtract_frac                  = 0.d0
         param.k_snr_w8_decor                 = 0.d0

         param.decor_per_subscan              = 1

         ;;******************
         param.no_variance_w8 = 1
         ;;******************

         
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0

         param.subtract_i_map = 1

         param.off_source_fourier = 1
         param.freqlow            = 1./12d0
         
         param.bandpass       = 0 ; 1
         param.freqlow        = 0 ; 1./12
      end

      64:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 1
         param.force_opacity_225     = 1
         
         param.subtract_pos_signal_only       = 1
         param.subtract_frac                  = 0.d0
         param.k_snr_w8_decor                 = 0.d0

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 5

         param.subtract_i_map = 1

         param.off_source_fourier = 0.d0 ; 1
         param.freqlow            = 0.d0 ; 1./12d0
         
         param.bandpass       = 0 ; 1
         param.freqlow        = 0 ; 1./12
      end

      65:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 6 ; 1
         param.force_opacity_225     = 0 ; 1
         
         param.subtract_pos_signal_only       = 1
         param.subtract_frac                  = 1.d0
         param.k_snr_w8_decor                 = 0.d0
         param.ignore_mask_for_decorr         = 1

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0

         param.subtract_i_map = 1

         param.off_source_fourier = 0.d0 ; 1
         param.freqlow            = 0.d0 ; 1./12d0
         
         param.bandpass       = 0 ; 1
         param.freqlow        = 0 ; 1./12
      end

      66:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 1
         param.force_opacity_225     = 1
         
         param.subtract_pos_signal_only       = 1
         param.subtract_frac                  = 1.d0
         param.k_snr_w8_decor                 = 1.d0
         param.ignore_mask_for_decorr         = 1

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0

         param.subtract_i_map = 1

         param.off_source_fourier = 0.d0 ; 1
         param.freqlow            = 0.d0 ; 1./12d0
         
         param.bandpass       = 0 ; 1
         param.freqlow        = 0 ; 1./12
      end

      67:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 1
         param.force_opacity_225     = 1
         
         param.subtract_pos_signal_only       = 1
         param.subtract_frac                  = 0.d0
         param.k_snr_w8_decor                 = 1.d0
         param.ignore_mask_for_decorr         = 1
         
         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0

         param.subtract_i_map = 1

         param.off_source_fourier = 0.d0 ; 1
         param.freqlow            = 0.d0 ; 1./12d0
         
         param.bandpass       = 0 ; 1
         param.freqlow        = 0 ; 1./12
      end

      68:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)

         param.do_opacity_correction = 6

         param.subtract_pos_signal_only       = 1
         param.subtract_frac                  = 0.d0
         param.k_snr_w8_decor                 = 0.d0

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0

         param.subtract_i_map = 1
         
         param.niter_cm                       = 3

         param.bandpass       = 0 ; 1
         param.freqlow        = 0 ; 1./12
      end

      69:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 1
         param.force_opacity_225     = 1
         
         param.subtract_pos_signal_only       = 1
         param.subtract_frac                  = 1.d0
         param.k_snr_w8_decor                 = 0.d0
         param.ignore_mask_for_decorr         = 1

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 5

         param.subtract_i_map = 1

         param.off_source_fourier = 0.d0 ; 1
         param.freqlow            = 0.d0 ; 1./12d0
         
         param.bandpass       = 0 ; 1
         param.freqlow        = 0 ; 1./12
      end

      ;; like 65 with no_variance_w8 in JK
      70:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 1
         param.force_opacity_225     = 1

         param.no_variance_w8 = 1
         
         param.subtract_pos_signal_only       = 1
         param.subtract_frac                  = 1.d0
         param.k_snr_w8_decor                 = 0.d0
         param.ignore_mask_for_decorr         = 1

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0

         param.subtract_i_map = 1

         param.off_source_fourier = 0.d0 ; 1
         param.freqlow            = 0.d0 ; 1./12d0
         
         param.bandpass       = 0 ; 1
         param.freqlow        = 0 ; 1./12
      end

      ;; 65 and ******* polynomial=1 (not 5) ?! ***************
      71:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 6 ; 1
         param.force_opacity_225     = 0 ; 1
         
         param.subtract_pos_signal_only       = 1
         param.subtract_frac                  = 1.d0
         param.k_snr_w8_decor                 = 0.d0
         param.ignore_mask_for_decorr         = 1

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 1

         param.subtract_i_map = 1

         param.off_source_fourier = 0.d0 ; 1
         param.freqlow            = 0.d0 ; 1./12d0
         
         param.bandpass       = 0 ; 1
         param.freqlow        = 0 ; 1./12
      end

      ;; 65 and polynomial (DEG 1) + tau225 = 71 with tau225
      72:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         if strupcase(source) eq "GRB1" or strupcase(source) eq "GRB2" then begin
            param.force_kidpar = 1
            param.file_kidpar = !nika.off_proc_dir+"/kidpar_n2r26_recal_method72.fits"
         endif

         param.do_opacity_correction = 1
         param.force_opacity_225     = 1
         
         param.subtract_pos_signal_only       = 1
         param.subtract_frac                  = 1.d0
         param.k_snr_w8_decor                 = 0.d0
         param.ignore_mask_for_decorr         = 1

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 1

         param.subtract_i_map = 1

         param.off_source_fourier = 0.d0 ; 1
         param.freqlow            = 0.d0 ; 1./12d0
         
         param.bandpass       = 0 ; 1
         param.freqlow        = 0 ; 1./12
      end

      73:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)

         param.do_opacity_correction = 6

         param.subtract_pos_signal_only       = 1
         param.subtract_frac                  = 0.d0
         param.k_snr_w8_decor                 = 0.d0

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0

         param.subtract_i_map = 1
         
         param.bandpass       = 0 ; 1
         param.freqlow        = 0 ; 1./12
      end

      ;; 65 and ******* polynomial=5 ?! ***************
      74:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 6 ; 1
         param.force_opacity_225     = 0 ; 1
         
         param.subtract_pos_signal_only       = 1
         param.subtract_frac                  = 1.d0
         param.k_snr_w8_decor                 = 0.d0
         param.ignore_mask_for_decorr         = 1

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 5

         param.subtract_i_map = 1

         param.off_source_fourier = 0.d0 ; 1
         param.freqlow            = 0.d0 ; 1./12d0
         
         param.bandpass       = 0 ; 1
         param.freqlow        = 0 ; 1./12
      end

      ;; 65 and polynomial (DEG 1) NO OPACITY CORRECTION
      75:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 0
         
         param.subtract_pos_signal_only       = 1
         param.subtract_frac                  = 1.d0
         param.k_snr_w8_decor                 = 0.d0
         param.ignore_mask_for_decorr         = 1

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 1

         param.subtract_i_map = 1

         param.off_source_fourier = 0.d0 ; 1
         param.freqlow            = 0.d0 ; 1./12d0
         
         param.bandpass       = 0 ; 1
         param.freqlow        = 0 ; 1./12
      end

      ;; 65 and ******* polynomial=3
      76:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         if strupcase(source) eq "GRB1" or strupcase(source) eq "GRB2" then begin
            param.force_kidpar = 1
            param.file_kidpar = !nika.off_proc_dir+"/kidpar_n2r26_recal_method76.fits"
         endif
         param.do_opacity_correction = 6 ; 1
         param.force_opacity_225     = 0 ; 1
         
         param.subtract_pos_signal_only       = 1
         param.subtract_frac                  = 1.d0
         param.k_snr_w8_decor                 = 0.d0
         param.ignore_mask_for_decorr         = 1

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 3

         param.subtract_i_map = 1

         param.off_source_fourier = 0.d0 ; 1
         param.freqlow            = 0.d0 ; 1./12d0
         
         param.bandpass       = 0 ; 1
         param.freqlow        = 0 ; 1./12
      end

      77:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 6 ; 1
         param.force_opacity_225     = 0 ; 1
         
         param.subtract_pos_signal_only       = 1
         param.subtract_frac                  = 0.d0
         param.k_snr_w8_decor                 = 0.d0
         param.ignore_mask_for_decorr         = 0

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 3

         param.subtract_i_map = 1

         param.off_source_fourier = 0.d0 ; 1
         param.freqlow            = 0.d0 ; 1./12d0
         
         param.bandpass       = 0 ; 1
         param.freqlow        = 0 ; 1./12
      end

      78:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 6 ; 1
         param.force_opacity_225     = 0 ; 1
         
         param.subtract_pos_signal_only       = 1
         param.subtract_frac                  = 0.d0
         param.k_snr_w8_decor                 = 0.d0
         param.ignore_mask_for_decorr         = 0

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0

         param.subtract_i_map = 1

         param.off_source_fourier = 0.d0 ; 1
         param.freqlow            = 0.d0 ; 1./12d0
         
         param.bandpass       = 1
         param.freqlow        = 0.2
      end

      ;; 71 and deg 3 polynomial
      79:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 6 ; 1
         param.force_opacity_225     = 0 ; 1
         
         param.subtract_pos_signal_only       = 1
         param.subtract_frac                  = 1.d0
         param.k_snr_w8_decor                 = 0.d0
         param.ignore_mask_for_decorr         = 1

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 3

         param.subtract_i_map = 1

         param.off_source_fourier = 0.d0
         param.freqlow            = 0.d0
         
         param.bandpass       = 0
         param.freqlow        = 0
      end

      ;; 71 (no mask in decorr, subtract I, polynomial 1)
      ;; + common_mode_per_subband + force_constant_elevation_opacorr
      80:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 6 ; 1 ; 1
         param.force_opacity_225     = 0 ; 1 ; 1
         
         param.subtract_pos_signal_only       = 1
         param.subtract_frac                  = 1.d0
         param.k_snr_w8_decor                 = 0.d0
         param.ignore_mask_for_decorr         = 1

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 1

         param.subtract_i_map = 1

         param.off_source_fourier = 0.d0
         param.freqlow            = 0.d0
         
         param.bandpass       = 0
         param.freqlow        = 0

         param.common_mode_subband_1mm = 1
         param.force_constant_elevation_opacorr  = 1
         param.dave_tau_file = !nika.off_proc_dir+'/Lin15012019_22012019F.txt'
;;          if strupcase(source) eq "GRB1" or strupcase(source) eq "GRB2" then begin
;;             param.force_kidpar = 1
;;             param.file_kidpar = !nika.off_proc_dir+"/kidpar_n2r26_recal_method80.fits"
;;          endif
      end

      ;; 71 (no mask in decorr, subtract I, polynomial 1)
      ;; + common_mode_per_subband
      ;; like 80 but without force_constant_elevation_opacorr
      81:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 6 ; 1 ; 1
         param.force_opacity_225     = 0 ; 1 ; 1
         
         param.subtract_pos_signal_only       = 1
         param.subtract_frac                  = 1.d0
         param.k_snr_w8_decor                 = 0.d0
         param.ignore_mask_for_decorr         = 1

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 1

         param.subtract_i_map = 1

         param.common_mode_subband_1mm = 1

;;          if strupcase(source) eq "GRB1" or strupcase(source) eq "GRB2" then begin
;;             param.force_kidpar = 1
;;             param.file_kidpar = !nika.off_proc_dir+"/kidpar_n2r26_recal_method80.fits"
;;          endif
      end
      
      ;; Like 81 but accepts a mask for the decorrelation to enable an
      ;; external mask and a single iteration
      82:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 6 ; 1 ; 1
         param.force_opacity_225     = 0 ; 1 ; 1
         
         param.subtract_pos_signal_only       = 1
         param.subtract_frac                  = 1.d0
         param.k_snr_w8_decor                 = 0.d0
         param.ignore_mask_for_decorr         = 0

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0

         param.subtract_i_map = 1

         param.off_source_fourier = 0.d0
         param.freqlow            = 0.d0
         
         param.bandpass       = 0
         param.freqlow        = 0

         param.common_mode_subband_1mm = 1
         param.force_constant_elevation_opacorr  = 0
         param.dave_tau_file = !nika.off_proc_dir+'/Lin15012019_22012019F.txt'
;;          if strupcase(source) eq "GRB1" or strupcase(source) eq "GRB2" then begin
;;             param.force_kidpar = 1
;;             param.file_kidpar = !nika.off_proc_dir+"/kidpar_n2r26_recal_method80.fits"
;;          endif
      end

      ;; atm only to produce plots for the paper
      83:begin
         param.decor_method = "ATM_ONLY"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 6
         param.force_opacity_225     = 0
         
         param.subtract_pos_signal_only       = 1
         param.subtract_frac                  = 1.d0
         param.k_snr_w8_decor                 = 0.d0
         param.ignore_mask_for_decorr         = 0

         param.decor_per_subscan              = 1
         param.subtract_i_map = 1
      end

      ;; 71 (no mask in decorr, subtract I, polynomial 1)
      ;; + all common_mode_per_subband at the same time, no
      ;; intermediate step with box decorrelation
      84:begin
         param.decor_method = "ATM_AND_SUBBANDS"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 6
         param.force_opacity_225     = 0
         
         param.subtract_pos_signal_only       = 1
         param.subtract_frac                  = 1.d0
         param.k_snr_w8_decor                 = 0.d0
         param.ignore_mask_for_decorr         = 1

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1

         param.subtract_i_map = 1
      end

      ;; 81 + nomask_poly + no polynomials
      85:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 6 ; 1 ; 1
         param.force_opacity_225     = 0 ; 1 ; 1
         
         param.subtract_pos_signal_only       = 0
         param.subtract_frac                  = 1.d0
         param.k_snr_w8_decor                 = 0.d0
         param.ignore_mask_for_decorr         = 1

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0

         param.no_const_in_regress            = 1
         param.set_zero_level_per_subscan     = 1
         
         param.polynomial                     = 0 ; 1
         param.nomask_poly                    = 0 ; 1

         param.subtract_i_map = 1

         param.off_source_fourier = 0.d0
         param.freqlow            = 0.d0
         
         param.bandpass       = 0
         param.freqlow        = 0

         param.common_mode_subband_1mm = 1
         param.force_constant_elevation_opacorr  = 0
         param.dave_tau_file = !nika.off_proc_dir+'/Lin15012019_22012019F.txt'
;;          if strupcase(source) eq "GRB1" or strupcase(source) eq "GRB2" then begin
;;             param.force_kidpar = 1
;;             param.file_kidpar = !nika.off_proc_dir+"/kidpar_n2r26_recal_method80.fits"
;;          endif
      end

      86:begin
         param.decor_method = "RAW_MEDIAN"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 6 ; 1 ; 1
         param.force_opacity_225     = 0 ; 1 ; 1
         
         param.subtract_pos_signal_only       = 1
         param.subtract_frac                  = 1.d0
         param.k_snr_w8_decor                 = 0.d0
         param.ignore_mask_for_decorr         = 1

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0

         param.subtract_i_map = 1
      end

      ;; - Like 81 but with subtract_pos_only=0 (for transfer functions
      ;; on diffuse emission in particular) (to test)
      ;; - w/o polynomials
      87:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 6 ; 1 ; 1
         param.force_opacity_225     = 0 ; 1 ; 1
         
         param.subtract_pos_signal_only       = 0 ; 1
         param.subtract_frac                  = 1.d0
         param.k_snr_w8_decor                 = 0.d0
         param.ignore_mask_for_decorr         = 1

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1

         param.subtract_i_map = 1

         param.common_mode_subband_1mm = 1

;;          if strupcase(source) eq "GRB1" or strupcase(source) eq "GRB2" then begin
;;             param.force_kidpar = 1
;;             param.file_kidpar = !nika.off_proc_dir+"/kidpar_n2r26_recal_method80.fits"
;;          endif
      end

      ;; Testing small structures subtraction in the common mode (box
      ;; + subbands)
      88:begin
         param.decor_method = "common_mode_kids_out"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 6 ; 1 ; 1
         param.force_opacity_225     = 0 ; 1 ; 1
         
         param.subtract_pos_signal_only       = 0 ; 1
         param.subtract_frac                  = 1.d0
         param.k_snr_w8_decor                 = 0.d0
         param.ignore_mask_for_decorr         = 1

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1

         param.subtract_i_map = 1

         param.common_mode_subband_1mm = 1

;;          if strupcase(source) eq "GRB1" or strupcase(source) eq "GRB2" then begin
;;             param.force_kidpar = 1
;;             param.file_kidpar = !nika.off_proc_dir+"/kidpar_n2r26_recal_method80.fits"
;;          endif
      end
      
      ;; like 81 but without polynomials
      89:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 6
         param.force_opacity_225     = 0
         
         param.subtract_pos_signal_only       = 1
         param.subtract_frac                  = 1.d0
         param.k_snr_w8_decor                 = 0.d0
         param.ignore_mask_for_decorr         = 1

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1

         param.subtract_i_map = 1

         param.common_mode_subband_1mm = 1

;;          if strupcase(source) eq "GRB1" or strupcase(source) eq "GRB2" then begin
;;             param.force_kidpar = 1
;;             param.file_kidpar = !nika.off_proc_dir+"/kidpar_n2r26_recal_method80.fits"
;;          endif
      end

      ;; like 89 but with subtract_pos_signal_only=0
      90:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 6
         param.force_opacity_225     = 0
         
         param.subtract_i_map                 = 1
         param.subtract_pos_signal_only       = 0
         param.subtract_frac                  = 1.d0
         param.k_snr_w8_decor                 = 0.d0
         param.ignore_mask_for_decorr         = 1

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1

         param.common_mode_subband_1mm = 1
         param.common_mode_subband_2mm = 1
      end

      ;; Checking toi_median and polynomials to have a clear comparison
      91:begin
         param.decor_method = "raw_median"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 6
         param.force_opacity_225     = 0
         
         param.subtract_pos_signal_only       = 0
         param.subtract_frac                  = 1.d0
         param.k_snr_w8_decor                 = 0.d0
         param.ignore_mask_for_decorr         = 1

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 3
      end

      ;; like 90 but ensuring null zero level on the bg map
      92:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 6
         param.force_opacity_225     = 0
         
         param.subtract_pos_signal_only       = 0
         param.subtract_frac                  = 1.d0
         param.k_snr_w8_decor                 = 0.d0
         param.ignore_mask_for_decorr         = 1

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1

         param.subtract_i_map = 1

         param.common_mode_subband_1mm = 1
         param.map_bg_zero_level_radius = 250
      end

      ;; like 89 (pos onl=1)+ ensuring null zero level on the bg map
      93:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 6
         param.force_opacity_225     = 0
         
         param.subtract_pos_signal_only       = 1
         param.subtract_frac                  = 1.d0
         param.k_snr_w8_decor                 = 0.d0
         param.ignore_mask_for_decorr         = 1

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1

         param.subtract_i_map = 1

         param.common_mode_subband_1mm = 1
         param.map_bg_zero_level_radius = 250
      end

      94:begin
         param.decor_method = "MEDIAN_SIMPLE"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 6
         param.force_opacity_225     = 0
         
         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 3

         param.subtract_i_map = 1
      end
      
      ;; Instead of subtracting the map to debias the common mode from
      ;; strong point sources, interpolate and replace by constrained
      ;; noise. This way, there should not be "map noise" added to the
      ;; timeline to all kids at the same place that is confounded
      ;; with sky signal.
      ;;
      ;; snr_w8 as well...
      ;; ignore_mask_for_decorr back to 0
      95:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 6
         param.force_opacity_225     = 0

         param.k_snr_w8_decor                 = 1.d0
         param.iter_interpol_high_snr         = 1
         param.subtract_i_map                 = 0 ; No map subtraction
         param.ignore_mask_for_decorr         = 0 ; 1

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1
;         param.common_mode_subband_1mm = 1
      end

      ;; 95 + common_mode_subband
      96:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 6
         param.force_opacity_225     = 0

         param.k_snr_w8_decor                 = 1.d0
         param.iter_interpol_high_snr         = 1
         param.subtract_i_map                 = 0 ; No map subtraction
         param.ignore_mask_for_decorr         = 0 ; 1

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1
         param.common_mode_subband_1mm = 1
      end

      ;; No interpolation, no mask, just snr w8 to decorrelate and
      ;; build common modes
      97:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 6
         param.force_opacity_225     = 0

         param.k_snr_w8_decor                 = 1.d0
         param.iter_interpol_high_snr         = 0
         param.subtract_i_map                 = 0 ; No map subtraction
         param.ignore_mask_for_decorr         = 1

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1
         param.common_mode_subband_1mm        = 1
         param.common_mode_subband_2mm        = 1
      end

      ;; No interpolation, no mask, no snrw8... but subtract a
      ;; smoothed version of the input map to limit pixel noise
      ;; effects...
      ;; and better mimic the actual sky signal ?
      98:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 6
         param.force_opacity_225     = 0

         param.k_snr_w8_decor                 = 0.d0
         param.iter_interpol_high_snr         = 0

         param.ignore_mask_for_decorr         = 1
         param.subtract_i_map                 = 1
;;         param.smooth_input_map               = 1

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1
         param.common_mode_subband_1mm        = 1
         param.common_mode_subband_2mm        = 1
      end

      ;; Trying to take the best of map subtraction and snr weighting
      ;; without creating holes with too high snr_w8, smooth snr_toi
      99:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 6
         param.force_opacity_225     = 0

         param.k_snr_w8_decor              = 1.d0
         param.snr_max                     = 5.

         param.ignore_mask_for_decorr         = 1
         param.subtract_i_map                 = 1

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1
         param.common_mode_subband_1mm        = 1
         param.common_mode_subband_2mm        = 1

         ;; Polar
         param.decor_qu = 1
         param.qu_iterative_mm = 0 ; zero for now on CX-Tau
      end

      ;; like 99 with cm_kid_min_dist = 40
      100:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 6
         param.force_opacity_225     = 0

         param.k_snr_w8_decor                 = 1.d0
         param.snr_max                        = 5.
         param.cm_kid_min_dist                = 40.

         param.ignore_mask_for_decorr         = 1
         param.subtract_i_map                 = 1

         param.decor_per_subscan              = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1
         param.common_mode_subband_1mm        = 1
         param.common_mode_subband_2mm        = 1

         ;; Polar
         param.decor_qu = 1
         param.qu_iterative_mm = 0 ; zero for now on CX-Tau
      end

      ;; like 99 with param.niter_cm and kid2median test
      ;; try decor_per_subscan=0 to show iterations on common modes and
      ;; atmosphere more clearly.
      101:begin
         param.decor_method = "ATM_AND_ALL_BOX_SNR_W8"
         ;; param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction = 6
         param.force_opacity_225     = 0

         param.k_snr_w8_decor                 = 1.d0
         param.snr_max                        = 5.
         param.cm_kid_min_dist                = 0.

         param.niter_cm                       = 5
         param.do_kid2median_test             = 1

         param.ignore_mask_for_decorr         = 1
         param.subtract_i_map                 = 1

         param.decor_per_subscan              = 0 ; 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1
         param.common_mode_subband_1mm        = 1
         param.common_mode_subband_2mm        = 1

         ;; Polar
         param.decor_qu = 1
         param.qu_iterative_mm = 0 ; zero for now on CX-Tau
      end

      ;------------------------------------------------------------------------
      ;; FXD try exploring CF, atm and box decorr per array per subband,
      ;; iteratively, one polynomial for the 0 level per subscan.
      120:begin
         param.preproc_copy = 1  ; force saving preproc data to speed up iterations (indispensible if one wants calibrated data).
         param.decor_method = "test_np2"
         param.new_method = "NEW_DECOR_ATMB_PER_ARRAY"
         nickname = source+"_"+strtrim(method_num,2)
         param.do_opacity_correction = 6
         param.force_opacity_225     = 0
         param.math = 'CF'
         param.fourier_opt_sample = 0 ; default 0 (above set at 1 but this cuts the end of the scan badly (150 samples sometimes (see G2)))
         
; Glitch parameters
         param.k_rts = 1
         param.k_find_jumps = 1  ; Look for glitches and jumps
         param.k_glitch =  [10.,  50, 10]   ; standard glitch find
         param.k_jump[0] = 0 ; 0 don't look for jumps
         param.deal_with_glitches_and_jumps = 0 ; not this method
         param.fast_deglitch = 0  ; don't use 
         param.new_deglitch = 0 ; don't use
         param.second_deglitch = 0 ; don't use

; Flags (Recomm FXD 20 April, 2020)
         param.flag_sat             = 1
         flag_oor                   = 0 ;; 1 can yield elimination to bona fide Kids because the sweep was done a long time ago, 0 default
         param.flag_ovlap           = 1 ;; 1 default
         param.flag_ident           = 1 ;; 1 default

         param.flag_sat_val         = !dpi/2.d0 ;; (!dpi/4D0 if RF), Cf can tolerate larger excursion
         param.flag_oor_val         = 3.d0 ;; can be reduced to 3 if too many resonances are lost
         param.flag_ident_val       = 1.0  ;; default 1Hz
         param.flag_ovlap_val       = 0.8  ;; default
;         param.flag_n_seconds_subscan_start   = 3.  ; Trade-off found (24/8/2020 FXD)
         param.flag_n_seconds_subscan_start   = 0  ; Weigh down instead of cutting (25/8)
         param.discard_noisy_kids   =  0           ; Done elsewhere (in atmb)
         param.on_the_fly_kid_noise =  1 ; compute the real high frequency noise of kids per scan (and do not take it from kidpar file). Jan 2021
; Decorrelation parameters
         param.k_snr_w8_decor                 = 3D-2  ; non zero : take into account snr into weighing decorr. or not (0)
         param.k_snr_template                 = 3D-2 ; non zero: use to weigh down samples for the determination of decor templates.
         param.k_snr                          = 3D-2
; 0.1 is = S/N of 3 means half the weight,
; 0.03 is safer if noise is not properly determined
         ; 0.003 is to have S/N at the scan level instead of ~100 scans
                                ; k_snr is applied at the map level to
                                ; correct noiseup whereas
                                ; k_snr_w8_decor is applied during the
                                ; decorrelation, Advice: keep them equal
         param.snr_max                        = 1D6
         param.snr_exp                        = 2D0
         param.k_snr_radius                   = 1D6  ; 200. Avoid weighing down uncertain border zones Done elsewhere, see map_truncate_percent
         param.k_snr_method                   = 3       ; 2 default=use nk_ata_fit_beam2 (Gaussian with background),
                                ; 3 beam3 (without background), 3
                                ; recommended and tested
         param.noiseup                        = 1      ; If 1, improve noise and (low) signal accuracy by accounting for number of modes.
         param.boost                          = 1 ; boost the noise to have a reduced S/N distribution.
         param.interpol_common_mode           = 1 ; 1 interpol common modes (1 mandatory).
         param.ignore_mask_for_decorr         = 1    ; 1 will not have mask (0 for STRONG source)
         param.source_mask                    = 0    ; 0 set to 0 to ignore any input source mask (old "common_mode"), 1 is necessary for iter 0 in case of a strong source
         param.keep_mask                      = 0   ; set to 1 to keep the mask even during iterative map making
         param.mask_default_radius            = 30.d0  ; default 30 arcsec (undeprecated, use that instead of decor_cm_dmin), not used if keep_mask is 0

         param.one_offset_per_subscan         = 1 ; 1 is standard, still, done by atmb
         param.niter_atm_el_box_modes         = 2 ; 1-2 try further, 2 improves a tiny bit
         param.niter_cm                       = 1 ;1 is default, 2 improves slightly on median mode
         param.include_elevation_in_decor_templates = 0 ; what it says (can be tried)
         param.decor_2_per_subscan            = 0 ; 0 (done in decorr)
         param.decor_per_subscan              = 0 ; 0 = default (done in decorr)
         param.flag_uncorr_kid                = 0 ; 0, don't use
;;;DEPRECATED use mask_default_radius         param.decor_cm_dmin                  = 60.                    ; not used here

         ; Map parameters
         param.subtract_i_map                 = 1 ; 1=default, HERE stop subtracting map (with 0 on ext param)
         param.subtract_frac                  = 1 ; 1, should do some adiabatic move to 1 during iter. Here we subtract the part above some snr, see keep_only_high_snr
         param.map_truncate_percent = 20.      ; used in nk_truncate_filter_map (to eliminate the borders of maps in the iterative process), 0. means no truncation, which is default. >=20. is recommended otherwise
         param.map_median_fract = 0 ; subtract to the map a median obtained with a (fraction of FOV) default=0.25 for that fraction, used in nk_truncate_filter_map. Default is not to used it
         param.keep_only_high_snr = 10. ; in iteration 1 and following, keep in the subtract_map only the part above keep_only_high_snr sigma
         param.sub_thres_sn = 0D0  ; Should not be used keep it at 0
         param.set_zero_level_full_scan       = 0 ;  done in decorr, 0 is default
         param.set_zero_level_per_subscan     = 0 ; 0 = default (done in decorr)
         param.map_bg_zero_level_radius       = -1 ; -1 default (-1 is better than 0 not taken) (use the whole map) Use it for SZ (e.g. 120 in arcsec) means the center is not used to determine the zero level
         param.nomask_poly                    = 1 ; Not used  1=polyn on all samples.
         param.polynomial                     = 0 ; always 0 not used here
         param.polynom_subscan1mm             = 0 ; 0 (offset), 1 (offset+slope), 2, 3 degree of polynomial (lower deg for short subscans)
         param.polynom_subscan2mm             = 0 ; 0 (offset), 1, 2, 3 degree of polynomial (lower is suggested for SZ or short subs, 5 is enough to remove LF noise)
         param.nharm_subscan1mm =  0   ; another way of subtracting harmonics per subscan, only with ATMB method.
         param.nharm_subscan2mm =  0   ; another way of subtracting harmonics per subscan, only with ATMB method.
                                ; if nharm gt 0, then polynomial degree is stuck at 1
         param.w8_per_subscan                 = 5 ; ; set to 1 to compute weights for each subscan independently, 2 to compute a constant weight, evaluated as the median of noise per subscan, other options have been added.; 4 (median avg of subscan or subscan itself if worse) 2 is median avg of all subscan noise, 5 is like 4 but high frequency noise modulates that weight (to deal with subscan beginning)
         param.atmb_defilter            = 0 ; 0 default, no defiltering, 2 means: at least 2 iterations before defiltering the data, the rule is that defiltering must be at the last iteration
         param.split_horver = 3 ; 1, 2 or 3= default means jack-knife maps are made by splitting horizontal and vertical scans instead of every other scan. For the defilter case, 1 means add VER low frequency TOI from horizontal scans (and HOR for vertical). 2 means add twice (HOR-VER) from horizontal scans (and VER-HOR for vertical scans). 3 is recommended: Add the VER partner low frequency to a HOR file and the HOR partner LF to the VER file. Each couple is then assigned a sign (+-) for the jack-knives.
         param.atmb_accelsm = 0 ; 0 default,  acceleration factor (<=23) ie. keep f<1Hz, can improve computation speed by a factor 3, but it does not deal well with strong point sources
         param.common_mode_subband_1mm        = 0 ; 0 not used but indeed applied...
         param.common_mode_subband_2mm        = 0
         param.no_bg_var_map                  = 1 ; Use toi sigma to deduce map variance and propage that to coadded map
         ;; Polar
         param.decor_qu = 1
         param.qu_iterative_mm = 0
         param.cpu_time = 0  ; 1 to measure critical CPU time
                                ; Obsolete parameters ?
         param.debug  =  0

      end


      
      200:begin
         param.decor_method = "test_np2"
         param.new_method   = 'NEW_DECOR_ATM_AND_ALL_BOXES'
         nickname = source+"_"+strtrim(method_num,2)

         param.do_opacity_correction          = 6
         param.k_snr_w8_decor                 = 0.d0

         param.decor_per_subscan              = 1

         param.ignore_mask_for_decorr         = 1
         param.subtract_i_map                 = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1
      end

      201:begin
         param.decor_method = "test_np2"
         param.new_method   = 'NEW_DECOR_ATM_AND_BOXES_PER_ARRAY'
         nickname = source+"_"+strtrim(method_num,2)

         param.do_opacity_correction          = 6
         param.k_snr_w8_decor                 = 0.d0

         param.decor_per_subscan              = 1

         param.ignore_mask_for_decorr         = 1
         param.subtract_i_map                 = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1
      end

      202:begin
         param.decor_method = "test_np2"
         param.new_method   = 'NEW_DECOR_ATM_AND_SUBBANDS_PER_ARRAY'
         nickname = source+"_"+strtrim(method_num,2)

         param.do_opacity_correction          = 6
         param.k_snr_w8_decor                 = 0.d0

         param.decor_per_subscan              = 1

         param.ignore_mask_for_decorr         = 1
         param.subtract_i_map                 = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1
      end

      203:begin
         param.decor_method = "test_np2"
         param.new_method   = 'NEW_DECOR_ATM_AND_SUBBANDS_PER_BOX'
         nickname = source+"_"+strtrim(method_num,2)

         param.do_opacity_correction          = 6
         param.k_snr_w8_decor                 = 0.d0

         param.decor_per_subscan              = 1

         param.ignore_mask_for_decorr         = 1
         param.subtract_i_map                 = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1
      end

      ;; Impose zero level on the outskirt of the map at the end of
      ;; each iteration. + decor per entire scan
      204:begin
         param.decor_method = "test_np2"
         param.new_method   = 'NEW_DECOR_ATM_AND_ALL_BOXES'
         nickname = source+"_"+strtrim(method_num,2)

         param.do_opacity_correction          = 6
         param.k_snr_w8_decor                 = 0.d0

         param.decor_per_subscan              = 0

         param.ignore_mask_for_decorr         = 1
         param.subtract_i_map                 = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0
      end

      ;; Fit subbands per array and trigonometric modes at the same
      ;; time
      ;; decor per full scan
      205:begin
         param.decor_method = "test_np2"
         param.new_method   = 'NEW_DECOR_CM_AND_TRIGO'
         nickname = source+"_"+strtrim(method_num,2)

         param.do_opacity_correction          = 6
         param.k_snr_w8_decor                 = 0.d0

         param.nharm_multi_sinfit             = 16
         param.decor_per_subscan              = 0

         param.ignore_mask_for_decorr         = 1
         param.subtract_i_map                 = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1
      end

      ;; Same as 205 with CF and k_rts
      206:begin
         param.decor_method = "test_np2"
         param.new_method   = 'NEW_DECOR_CM_AND_TRIGO'
         nickname = source+"_"+strtrim(method_num,2)

         param.do_opacity_correction          = 6
         param.k_snr_w8_decor                 = 0.d0

         param.math = "CF"
         param.k_rts = 1
         param.radius_zero_level_mask = 0.d0

         param.nharm_multi_sinfit             = 16
         param.decor_per_subscan              = 0

         param.ignore_mask_for_decorr         = 1
         param.subtract_i_map                 = 1

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1
      end

      ;; Same as 205 with CF and k_rts, + kid2median test + on_the_fly_kid_noise
      207:begin
         param.decor_method = "test_np2"
         param.new_method   = 'NEW_DECOR_CM_AND_TRIGO'
         nickname = source+"_"+strtrim(method_num,2)

         param.do_opacity_correction          = 6
         param.k_snr_w8_decor                 = 0.d0

         param.do_kid2median_test = 1
         param.on_the_fly_kid_noise = 1

         param.math = "CF"
         param.k_rts = 1
         param.k_find_jumps = 1
;; comment out deal_with_glitches_and_jumps, NP, May 18th 2020
;;         param.deal_with_glitches_and_jumps = 1
         param.radius_zero_level_mask         = 100.d0
         param.nharm_multi_sinfit             = 16
         param.decor_per_subscan              = 0

         param.ignore_mask_for_decorr         = 1
         param.subtract_i_map                 = 1
         param.subtract_ignore_mask_radius    = 275.d0

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1
      end

      ;; No map subtraction but interpolation to avoid bias on atm
      ;; when high SNR sources
      208:begin
         param.decor_method = "test_np2"
         param.new_method   = 'NEW_DECOR_CM_AND_TRIGO'
         nickname = source+"_"+strtrim(method_num,2)

         param.do_opacity_correction          = 6
         param.k_snr_w8_decor                 = 0.d0

         param.do_kid2median_test = 1
         param.on_the_fly_kid_noise = 1

         param.math = "CF"
         param.k_rts = 1
         param.k_find_jumps = 1
;; comment out deal_with_glitches_and_jumps, NP, May 18th 2020
;;         param.deal_with_glitches_and_jumps = 1
         param.radius_zero_level_mask         = 200.d0
         param.decor_per_subscan              = 0

         param.subtract_i_map                 = 0

         param.iter_interpol_high_snr = 1

         param.ignore_mask_for_decorr         = 1
         param.subtract_ignore_mask_radius    = 275.d0

         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1
      end

      209:begin
         param.decor_method = "test_np2"
         param.new_method   = 'NEW_DECOR_IMCM'
         nickname = source+"_"+strtrim(method_num,2)

         param.do_opacity_correction          = 6
         param.k_snr_w8_decor                 = 0.d0

         param.decor_per_subscan              = 1

         param.regress_all_box_modes          = 1
         param.niter_atm_el_box_modes         = 3

         param.ignore_mask_for_decorr         = 1
         param.subtract_i_map                 = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1
      end

      210:begin
         param.decor_method = "test_np2"
         param.new_method   = 'NEW_DECOR_IMCM'
         nickname = source+"_"+strtrim(method_num,2)

         param.do_opacity_correction          = 6
         param.k_snr_w8_decor                 = 0.d0

         param.decor_per_subscan              = 0

         param.regress_all_box_modes          = 1
         param.niter_atm_el_box_modes         = 3

         param.ignore_mask_for_decorr         = 1
         param.subtract_i_map                 = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1
      end
      
      ;; like decor_imcm (atm, box modes, subbands), full scan and low
      ;; freq Fourier estimate (=210 + fourier)
      211:begin
         param.decor_method = "test_np2"
         param.new_method   = 'NEW_DECOR_IMCM'
         nickname = source+"_"+strtrim(method_num,2)

         param.do_opacity_correction          = 6
         param.k_snr_w8_decor                 = 0.d0

         param.decor_per_subscan              = 0
;; comment out deal_with_glitches_and_jumps, NP, May 18th 2020
;;         param.deal_with_glitches_and_jumps   = 1

         param.regress_all_box_modes          = 1
         param.niter_atm_el_box_modes         = 3
         param.fourier_lf_freqmax             = 0.2

         param.ignore_mask_for_decorr         = 1
         param.subtract_i_map                 = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1
      end

      ;; like 211 but no Fourier filtering
      212:begin
         param.decor_method = "test_np2"
         param.new_method   = 'NEW_DECOR_IMCM'
         nickname = source+"_"+strtrim(method_num,2)

         param.do_opacity_correction          = 6
         param.k_snr_w8_decor                 = 0.d0

         param.decor_per_subscan              = 0
;; comment out deal_with_glitches_and_jumps, NP, May 18th 2020
;;         param.deal_with_glitches_and_jumps   = 1

         param.regress_all_box_modes          = 1
         param.niter_atm_el_box_modes         = 3
         param.fourier_lf_freqmax             = 0.d0

         param.ignore_mask_for_decorr         = 1
         param.subtract_i_map                 = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1
      end

;;       ;; like 212 but one atmosphere template per array
;; Method 213 has been copied and pasted below to match new
;; parameterization
;; Feb. 4th, 2020
;;       213:begin
;;          param.decor_method = "test_np2"
;;          param.new_method   = 'NEW_DECOR_IMCM'
;;          nickname = source+"_"+strtrim(method_num,2)
;; 
;;          param.do_opacity_correction          = 6
;;          param.k_snr_w8_decor                 = 0.d0
;; 
;;          param.decor_per_subscan              = 0
;; comment out deal_with_glitches_and_jumps, NP, May 18th 2020
;;;;          param.deal_with_glitches_and_jumps   = 1
;;          param.atm_per_array                  = 1
;; 
;;          param.regress_all_box_modes          = 1
;;          param.niter_atm_el_box_modes         = 3
;;          param.fourier_lf_freqmax             = 0.d0
;; 
;;          param.ignore_mask_for_decorr         = 1
;;          param.subtract_i_map                 = 1
;;          param.set_zero_level_full_scan       = 0
;;          param.set_zero_level_per_subscan     = 0
;;          param.polynomial                     = 0 ; 1
;;       end

;;       ;; like 213 but extra fourier_lf_freqmax (masking bright sources)
;;       214:begin
;;          param.decor_method = "test_np2"
;;          param.new_method   = 'NEW_DECOR_IMCM'
;;          nickname = source+"_"+strtrim(method_num,2)
;; 
;;          param.do_opacity_correction          = 6
;;          param.k_snr_w8_decor                 = 0.d0
;; 
;;          param.decor_per_subscan              = 0
;; comment out deal_with_glitches_and_jumps, NP, May 18th 2020
;;;;          param.deal_with_glitches_and_jumps   = 1
;;          param.atm_per_array                  = 1
;; 
;;          param.regress_all_box_modes          = 1
;;          param.niter_atm_el_box_modes         = 3
;;          param.fourier_lf_freqmax             = 0.2d0
;; 
;;          param.ignore_mask_for_decorr         = 1
;;          param.subtract_i_map                 = 1
;;          param.set_zero_level_full_scan       = 0
;;          param.set_zero_level_per_subscan     = 0
;;          param.polynomial                     = 0 ; 1
;;       end
;; 
;;       ;; like 213 but with a simple highpass (do not mask sources to
;;       ;; treat bright and faint sources the same)
;;       215:begin
;;          param.decor_method = "test_np2"
;;          param.new_method   = 'NEW_DECOR_IMCM'
;;          nickname = source+"_"+strtrim(method_num,2)
;; 
;;          param.do_opacity_correction          = 6
;;          param.k_snr_w8_decor                 = 0.d0
;; 
;;          param.decor_per_subscan              = 0
;; comment out deal_with_glitches_and_jumps, NP, May 18th 2020
;;;;          param.deal_with_glitches_and_jumps   = 1
;;          param.atm_per_array                  = 1
;; 
;;          param.regress_all_box_modes          = 1
;;          param.niter_atm_el_box_modes         = 3
;; 
;;          param.bandpass = 1
;;          param.freqlow = 0.2
;;          param.bandpass_delta_f = 0.05
;; 
;;          param.ignore_mask_for_decorr         = 1
;;          param.subtract_i_map                 = 1
;;          param.set_zero_level_full_scan       = 0
;;          param.set_zero_level_per_subscan     = 0
;;          param.polynomial                     = 0 ; 1
;;       end
;; 
;;       ;; like 213 but with a 1st version of polynomial subtraction
;;       216:begin
;;          param.decor_method = "test_np2"
;;          param.new_method   = 'NEW_DECOR_IMCM'
;;          nickname = source+"_"+strtrim(method_num,2)
;; 
;;          param.do_opacity_correction          = 6
;;          param.k_snr_w8_decor                 = 0.d0
;; 
;;          param.decor_per_subscan              = 0
;; comment out deal_with_glitches_and_jumps, NP, May 18th 2020
;;;;          param.deal_with_glitches_and_jumps   = 1
;;          param.atm_per_array                  = 1
;; 
;;          param.regress_all_box_modes          = 1
;;          param.niter_atm_el_box_modes         = 3
;;          param.fourier_lf_freqmax             = 0.d0
;; 
;;          param.polynomial  = 1
;;          param.nomask_poly = 0
;; 
;;          param.ignore_mask_for_decorr         = 1
;;          param.subtract_i_map                 = 1
;;          param.set_zero_level_full_scan       = 0
;;          param.set_zero_level_per_subscan     = 0
;; 
;;       end
;; 
;;       ;; like 213 but with a 2nd version of polynomial subtraction
;;       217:begin
;;          param.decor_method = "test_np2"
;;          param.new_method   = 'NEW_DECOR_IMCM'
;;          nickname = source+"_"+strtrim(method_num,2)
;; 
;;          param.do_opacity_correction          = 6
;;          param.k_snr_w8_decor                 = 0.d0
;; 
;;          param.decor_per_subscan              = 0
;; comment out deal_with_glitches_and_jumps, NP, May 18th 2020
;;;;          param.deal_with_glitches_and_jumps   = 1
;;          param.atm_per_array                  = 1
;; 
;;          param.regress_all_box_modes          = 1
;;          param.niter_atm_el_box_modes         = 3
;;          param.fourier_lf_freqmax             = 0.d0
;; 
;;          param.polynomial  = 1
;;          param.nomask_poly = 1
;; 
;;          param.ignore_mask_for_decorr         = 1
;;          param.subtract_i_map                 = 1
;;          param.set_zero_level_full_scan       = 0
;;          param.set_zero_level_per_subscan     = 0
;;       end

      ;; Play with atm +- box modes +- subbands and how they are built
      ;; Starting from 213 by default with the new parameterization
      ;; (Feb. 4th, 2020)
      213:begin
         param.decor_method = "test_np2"
         param.new_method   = 'NEW_DECOR_IMCM'
         nickname = source+"_"+strtrim(method_num,2)
         param.do_opacity_correction          = 6
         param.k_snr_w8_decor                 = 0.d0

         param.decor_per_subscan              = 0
;; comment out deal_with_glitches_and_jumps, NP, May 18th 2020
;;         param.deal_with_glitches_and_jumps   = 1
         param.atm_per_array                  = 1

         param.decor_from_atm                 = 1
         param.decor_from_box_modes           = 1
         param.regress_all_box_modes          = 1
         param.decor_all_subbands            = 1

         param.niter_atm_el_box_modes         = 3
         param.fourier_lf_freqmax             = 0.d0

         param.ignore_mask_for_decorr         = 1
         param.subtract_i_map                 = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1
      end

      ;; Same as 213 but, for each kid, subtract only the el box mode
      ;; of the current box
      218:begin
         param.decor_method = "test_np2"
         param.new_method   = 'NEW_DECOR_IMCM'
         nickname = source+"_"+strtrim(method_num,2)

         param.do_opacity_correction          = 6
         param.k_snr_w8_decor                 = 0.d0

         param.decor_per_subscan              = 0
;; comment out deal_with_glitches_and_jumps, NP, May 18th 2020
;;         param.deal_with_glitches_and_jumps   = 1
         param.atm_per_array                  = 1

         param.decor_from_atm                 = 1
         param.decor_from_box_modes           = 1
         param.regress_all_box_modes          = 0
         param.decor_all_subbands            = 1

         param.niter_atm_el_box_modes         = 3
         param.fourier_lf_freqmax             = 0.d0

         param.ignore_mask_for_decorr         = 1
         param.subtract_i_map                 = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1
      end

      ;; Decorrelate directly from atm and subbands, to see if we gain
      ;; by adding an extra step as mode per box
      219:begin
         param.decor_method = "test_np2"
         param.new_method   = 'NEW_DECOR_IMCM'
         nickname = source+"_"+strtrim(method_num,2)

         param.do_opacity_correction          = 6
         param.k_snr_w8_decor                 = 0.d0

         param.decor_per_subscan              = 0
;; comment out deal_with_glitches_and_jumps, NP, May 18th 2020
;;         param.deal_with_glitches_and_jumps   = 1
         param.atm_per_array                  = 1

         param.decor_from_atm                 = 1
         param.decor_from_box_modes           = 0
         param.regress_all_box_modes          = 0
         param.decor_all_subbands            = 1

         param.niter_atm_el_box_modes         = 3
         param.fourier_lf_freqmax             = 0.d0

         param.ignore_mask_for_decorr         = 1
         param.subtract_i_map                 = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1
      end

      ;; Decorrelate directly from subbands, leaving atm in there, to see if we gain
      ;; by adding an extra step as mode per box and atm
      220:begin
         param.decor_method = "test_np2"
         param.new_method   = 'NEW_DECOR_IMCM'
         nickname = source+"_"+strtrim(method_num,2)

         param.do_opacity_correction          = 6
         param.k_snr_w8_decor                 = 0.d0

         param.decor_per_subscan              = 0
;; comment out deal_with_glitches_and_jumps, NP, May 18th 2020
;;         param.deal_with_glitches_and_jumps   = 1
         param.atm_per_array                  = 1

         param.decor_from_atm                 = 0
         param.decor_from_box_modes           = 0
         param.regress_all_box_modes          = 0
         param.decor_all_subbands            = 1

         param.niter_atm_el_box_modes         = 3
         param.fourier_lf_freqmax             = 0.d0

         param.ignore_mask_for_decorr         = 1
         param.subtract_i_map                 = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1
      end

      ;; like 213 but with subband decorrelation AFTER atm and box
      ;; modes, like in 99 to see if this is the cause of the
      ;; significant difference
      221:begin
         param.decor_method = "test_np2"
         param.new_method   = 'NEW_DECOR_IMCM'
         nickname = source+"_"+strtrim(method_num,2)

         param.do_opacity_correction          = 6
         param.k_snr_w8_decor                 = 0.d0

         param.decor_per_subscan              = 0
;; comment out deal_with_glitches_and_jumps, NP, May 18th 2020
;;         param.deal_with_glitches_and_jumps   = 1
         param.atm_per_array                  = 1

         param.decor_from_atm                 = 1
         param.decor_from_box_modes           = 1
         param.regress_all_box_modes          = 1

         param.decor_all_subbands            = 0 ; 1
         param.common_mode_subband_1mm        = 1
         param.common_mode_subband_2mm        = 1

         param.niter_atm_el_box_modes         = 3
         param.fourier_lf_freqmax             = 0.d0

         param.ignore_mask_for_decorr         = 1
         param.subtract_i_map                 = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1
      end

      ;; like 221 + decor_per_subscan
      222:begin
         param.decor_method = "test_np2"
         param.new_method   = 'NEW_DECOR_IMCM'
         nickname = source+"_"+strtrim(method_num,2)

         param.do_opacity_correction          = 6
         param.k_snr_w8_decor                 = 0.d0

         param.decor_per_subscan              = 1 ; 0
;; comment out deal_with_glitches_and_jumps, NP, May 18th 2020
;;         param.deal_with_glitches_and_jumps   = 1
         param.atm_per_array                  = 1

         param.decor_from_atm                 = 1
         param.decor_from_box_modes           = 1
         param.regress_all_box_modes          = 1

         param.decor_all_subbands            = 0 ; 1
         param.common_mode_subband_1mm        = 1
         param.common_mode_subband_2mm        = 1

         param.niter_atm_el_box_modes         = 3
         param.fourier_lf_freqmax             = 0.d0

         param.ignore_mask_for_decorr         = 1
         param.subtract_i_map                 = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1
      end

      ;; like 1000 (ie: 222 + subbands = 213 + subscans)
      ;; plus kid_to_median test, on_the_fly_kid_noise...
      223:begin
         param.decor_method = "test_np2"
         param.new_method   = 'NEW_DECOR_IMCM'
         nickname = source+"_"+strtrim(method_num,2)

         param.do_opacity_correction          = 6
         param.k_snr_w8_decor                 = 0.d0

         param.on_the_fly_kid_noise = 1
         param.do_kid2median_test   = 1

         param.decor_per_subscan              = 1
;; comment out deal_with_glitches_and_jumps, NP, May 18th 2020
;;         param.deal_with_glitches_and_jumps   = 1
         param.atm_per_array                  = 1

         param.decor_from_atm                 = 1
         param.decor_from_box_modes           = 1
         param.regress_all_box_modes          = 1
         param.decor_all_subbands            = 1
         param.common_mode_subband_1mm        = 0
         param.common_mode_subband_2mm        = 0

         param.niter_atm_el_box_modes         = 3
         param.fourier_lf_freqmax             = 0.d0

         param.ignore_mask_for_decorr         = 1
         param.subtract_i_map                 = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1
        end

      ;; 223 + k_snr_w8_decorr = 1
      224:begin
         param.decor_method = "test_np2"
         param.new_method   = 'NEW_DECOR_IMCM'
         nickname = source+"_"+strtrim(method_num,2)

         param.do_opacity_correction          = 6
         param.k_snr_w8_decor                 = 1.d0
;;         param.k_snr_radius                   = 200

         param.on_the_fly_kid_noise = 1
         param.do_kid2median_test   = 1

         param.decor_per_subscan              = 1
;; comment out deal_with_glitches_and_jumps, NP, May 18th 2020
;;         param.deal_with_glitches_and_jumps   = 1
         param.atm_per_array                  = 1

         param.decor_from_atm                 = 1
         param.decor_from_box_modes           = 1
         param.regress_all_box_modes          = 1
         param.decor_all_subbands            = 1
         param.common_mode_subband_1mm        = 0
         param.common_mode_subband_2mm        = 0

         param.niter_atm_el_box_modes         = 3
         param.fourier_lf_freqmax             = 0.d0

         param.ignore_mask_for_decorr         = 1
         param.subtract_i_map                 = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1
      end

      ;; 223 + k_snr_w8_decorr = 0.1
      225:begin
         param.decor_method = "test_np2"
         param.new_method   = 'NEW_DECOR_IMCM'
         nickname = source+"_"+strtrim(method_num,2)

         param.do_opacity_correction          = 6
         param.k_snr_w8_decor                 = 0.1d0

         param.on_the_fly_kid_noise = 1
         param.do_kid2median_test   = 1

         param.decor_per_subscan              = 1
;; comment out deal_with_glitches_and_jumps, NP, May 18th 2020
;;         param.deal_with_glitches_and_jumps   = 1
         param.atm_per_array                  = 1

         param.decor_from_atm                 = 1
         param.decor_from_box_modes           = 1
         param.regress_all_box_modes          = 1
         param.decor_all_subbands            = 1
         param.common_mode_subband_1mm        = 0
         param.common_mode_subband_2mm        = 0

         param.niter_atm_el_box_modes         = 3
         param.fourier_lf_freqmax             = 0.d0

         param.ignore_mask_for_decorr         = 1
         param.subtract_i_map                 = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1
      end

      ;; 223 + k_snr_w8_decorr = 1 and k_snr_radius=200
      226:begin
         param.decor_method = "test_np2"
         param.new_method   = 'NEW_DECOR_IMCM'
         nickname = source+"_"+strtrim(method_num,2)

         param.do_opacity_correction          = 6
         param.k_snr_w8_decor                 = 1.d0
         param.k_snr_radius                   = 200

         param.on_the_fly_kid_noise = 1
         param.do_kid2median_test   = 1

         param.decor_per_subscan              = 1
;; comment out deal_with_glitches_and_jumps, NP, May 18th 2020
;;         param.deal_with_glitches_and_jumps   = 1
         param.atm_per_array                  = 1

         param.decor_from_atm                 = 1
         param.decor_from_box_modes           = 1
         param.regress_all_box_modes          = 1
         param.decor_all_subbands            = 1
         param.common_mode_subband_1mm        = 0
         param.common_mode_subband_2mm        = 0

         param.niter_atm_el_box_modes         = 3
         param.fourier_lf_freqmax             = 0.d0

         param.ignore_mask_for_decorr         = 1
         param.subtract_i_map                 = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1
      end

      ;; 226 but no kid2median_test = 223 + k_snr_w8_decorr = 1 and k_snr_radius=200
      227:begin
         param.decor_method = "test_np2"
         param.new_method   = 'NEW_DECOR_IMCM'
         nickname = source+"_"+strtrim(method_num,2)

         param.do_opacity_correction          = 6
         param.k_snr_w8_decor                 = 1.d0
         param.k_snr_radius                   = 200

         param.on_the_fly_kid_noise = 1
         param.do_kid2median_test   = 0

         param.decor_per_subscan              = 1
;; comment out deal_with_glitches_and_jumps, NP, May 18th 2020
;;         param.deal_with_glitches_and_jumps   = 1
         param.atm_per_array                  = 1

         param.decor_from_atm                 = 1
         param.decor_from_box_modes           = 1
         param.regress_all_box_modes          = 1
         param.decor_all_subbands            = 1
         param.common_mode_subband_1mm        = 0
         param.common_mode_subband_2mm        = 0

         param.niter_atm_el_box_modes         = 3
         param.fourier_lf_freqmax             = 0.d0

         param.ignore_mask_for_decorr         = 1
         param.subtract_i_map                 = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1
      end

      ;; 227 but no kid2median_test and no on_the_fly_kid_noise = 223 + k_snr_w8_decorr = 1 and k_snr_radius=200
      228:begin
         param.decor_method = "test_np2"
         param.new_method   = 'NEW_DECOR_IMCM'
         nickname = source+"_"+strtrim(method_num,2)

         param.do_opacity_correction          = 6
         param.k_snr_w8_decor                 = 1.d0
         param.k_snr_radius                   = 200

         param.on_the_fly_kid_noise = 1
         param.do_kid2median_test   = 0

         param.decor_per_subscan              = 1
;; comment out deal_with_glitches_and_jumps, NP, May 18th 2020
;;         param.deal_with_glitches_and_jumps   = 1
         param.atm_per_array                  = 1

         param.decor_from_atm                 = 1
         param.decor_from_box_modes           = 1
         param.regress_all_box_modes          = 1
         param.decor_all_subbands            = 1
         param.common_mode_subband_1mm        = 0
         param.common_mode_subband_2mm        = 0

         param.niter_atm_el_box_modes         = 3
         param.fourier_lf_freqmax             = 0.d0

         param.ignore_mask_for_decorr         = 1
         param.subtract_i_map                 = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1
      end

      ;; map and trigo, NO SUBTRACTION
      229:begin
         param.decor_method = "test_np2"
         param.new_method   = 'MAP_AND_TRIGO'
         nickname = source+"_"+strtrim(method_num,2)
         
         param.do_opacity_correction          = 6
         param.k_snr_w8_decor                 = 0.d0
         
         param.on_the_fly_kid_noise = 0
         param.do_kid2median_test   = 0
         
         param.decor_per_subscan              = 0
;; comment out deal_with_glitches_and_jumps, NP, May 18th 2020
;;         param.deal_with_glitches_and_jumps   = 1
         
         param.atm_per_array                  = 0
         param.decor_from_atm                 = 0
         param.decor_from_box_modes           = 0
         param.regress_all_box_modes          = 0
         param.decor_all_subbands            = 0
         param.common_mode_subband_1mm        = 0
         param.common_mode_subband_2mm        = 0
         
         param.niter_atm_el_box_modes         = 0
         param.fourier_lf_freqmax             = 0.d0
         
         param.ignore_mask_for_decorr         = 1
         ;;***********
         param.clean_data_version             = 5
         param.subtract_i_map                 = 0
         param.freq_max_multi_sinfit          = 0.1
         ;;***********
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1
      end

      ;; To illustrate methods for the paper
      ;; simple baselines
      300:begin
         param.decor_method = 'none'
         nickname = source+"_"+strtrim(method_num,2)
         param.do_opacity_correction          = 6

         param.decor_per_subscan              = 1
         param.polynomial                     = 1

         param.subtract_i_map                 = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
      end

      301:begin
         param.decor_method = 'median_simple'
         nickname = source+"_"+strtrim(method_num,2)
         param.do_opacity_correction          = 6

         param.decor_per_subscan = 0 ; irrelevant with median_simple
         param.polynomial                     = 0

         param.subtract_i_map                 = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0

      end

      302:begin
         param.decor_method = 'raw_median'
         nickname = source+"_"+strtrim(method_num,2)
         param.do_opacity_correction          = 6

         param.decor_per_subscan = 0 ; irrelevant with median_simple
         param.polynomial                     = 0

         param.subtract_i_map                 = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
      end

      303:begin
         param.decor_method = 'none'
         nickname = source+"_"+strtrim(method_num,2)
         param.do_opacity_correction          = 6

         param.decor_per_subscan = 0 ; irrelevant with median_simple
         param.polynomial                     = 0

         param.pre_wiener                     = 1

         param.subtract_i_map                 = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
      end


;;==============================================================================================
      ;; FK: like 222 + subbands = like 213 + subscans
      1000:begin
         param.decor_method = "test_np2"
         param.new_method   = 'NEW_DECOR_IMCM'
         nickname = source+"_"+strtrim(method_num,2)

         param.do_opacity_correction          = 6
         param.k_snr_w8_decor                 = 0.d0

         param.decor_per_subscan              = 1
;; comment out deal_with_glitches_and_jumps, NP, May 18th 2020
;;         param.deal_with_glitches_and_jumps   = 1
         param.atm_per_array                  = 1

         param.decor_from_atm                 = 1
         param.decor_from_box_modes           = 1
         param.regress_all_box_modes          = 1
         param.decor_all_subbands            = 1
         param.common_mode_subband_1mm        = 0
         param.common_mode_subband_2mm        = 0

         param.niter_atm_el_box_modes         = 3
         param.fourier_lf_freqmax             = 0.d0

         param.ignore_mask_for_decorr         = 1
         param.subtract_i_map                 = 1
         param.set_zero_level_full_scan       = 0
         param.set_zero_level_per_subscan     = 0
         param.polynomial                     = 0 ; 1
        end

      ;; FK: like 15 but common_mode_kids_out (NIKA legacy?). NB: this should be equiv. to 1
      1001:begin
         param.decor_method = "common_mode_kids_out" ; for ref, even if know not to be optimal
         nickname = source+"_"+strtrim(method_num,2)
         param.do_opacity_correction = 6
         param.decor_qu              = 1
      end

      else:begin
;         message, /info, "Method "+strtrim(method_num,2)+" not implemented"
;         status = 1

         source_init_param_2_sub, param, method_num, source, status
         if status eq 1 then begin
            message, /info, "Method "+strtrim(method_num,2)+" not implemented"
         endif

      end
      
   endcase
endif

if strupcase(source) eq "SATURN" or $
   strupcase(strmid(source,0,6)) eq "URANUS" then begin
   param.map_proj = 'azel'      ; to keep the primary beam fixed on the map
   param.flag_sat   = 0
endif

param.method_num = method_num
param.project_dir = root_dir+"/"+strupcase(source)+"/"+strtrim(method_num,2)

end
