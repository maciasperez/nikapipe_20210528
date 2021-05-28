;+
;
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
;        nk_default_param
;
; CATEGORY: 
;        initialization
;
; CALLING SEQUENCE:
;         nk_default_param, param
; 
; PURPOSE: 
;        Create the parameter structure from the scan list 
; 
; INPUT: 
;       
; OUTPUT: 
;        - param: a default parameter structure used in the reduction
; 
; KEYWORDS:
;        - FORCE: Use this keyword to force the list of scans used
;          instead of checking if they are valid
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - 04/03/2014: creation
;-

pro nk_default_param, param
  
  param = { $
          ;;---------- Flag related parameters
          flag:0, $         
          scanst_scanNothing:0, $
          scanst_scanLoaded:1, $
          scanst_scanStarted:2, $
          scanst_scanDone:3, $
          scanst_subscanStarted:4, $
          scanst_subscanDone:5, $
          scanst_scanbackOnTrack:6, $
          scanst_subscan_tuning:7, $
          scanst_scan_tuning:8, $
          scanst_scan_new_file:9, $
          flag_holes:1, $       ; set to 1 to bypass the pointing restoration of missing data

          fast_uncorr:0, $          ;set to 1 to keep the source in the TOI's when the cross-corr is estiamted (less accurate but much faster)
          iterate_uncorr_kid:1, $ ; set to the number of iterations you want to detect uncorrelated kids
          flag_uncorr_kid:0, $  ; set to 1 to discard kids that do not correlate like the other ones


          ;; updated to FXD's recommended values, July 23rd, 2020
          flag_sat:1, $         ; to tell nk_outofres to look for saturated samples and flag them out
          flag_oor:0, $         ; to tell nk_outofres to look for out of resonance kids and flag them out
          flag_ident:1, $       ; to tell nk_outofres to look for identical resonances and flag them out
          flag_ovlap:1, $       ; to tell nk_outofres to look for overlapping resonances and flag them out
          flag_sat_val:!dpi/2.d0, $ ; default value defined by Xavier in mask_saturated_data
          flag_oor_val:3.d0, $      ; default value defined by Xavier in test_resopos
          flag_ident_val:1.0, $ ; default value defined by Xavier in test_resoident.pro; tolerate 1Hz difference at most
          flag_ovlap_val:0.8, $ ; default value defined by Xavier in test_resooverlap.pro
          
;; Only to test pointing info per subscan, use map_per_subscan=1 (FXD)
          map_per_subscan:0, $  ; Default is 0

          check_anom_refrac:0, $       ; set to 1 to make a map per subscan and fit the position of the source each time
                                ; the scatter could give an estimation
                                ; of anomalous refraction
          check_anom_refrac_nosave:1, $ ; avoids to save each map per subscan
          
          ;;---------- Decorrelation parameters
          dual_band_1mm_atm:0, $ ; set to 1 to derive the atm template with both A1 and A3, and use it for all arrays
          regress_all_box_modes:1, $
          niter_cm:1, $ ; set to more than 1 to iterate on the determination of the common mode in nk_get_cm_sub_2
          ignore_mask_for_decorr:0, $ ; set to 1 to decorr without mask
          use_iter_mask:0, $ ; set to 1 to use subtract_maps.iter_mask_XX to define data.off_source
          k_snr_w8_decor:0.d0, $ ; set to anything to weigh samples by 1/(1+k*snr^2)
          k_snr_template:0.d0, $ ; set to anything to weigh samples by 1/(1+k*snr^2) for the determination of decorrelation templates
          subtract_pos_signal_only:0, $ ; set to 1 to subtract only positive signal from the input map during iterative map making
          rotate_azel_mask_to_radec:0, $
          decor_from_all_box:0, $ ; set to 1 to decorrelate from all the electronic boxes at the same time
          fake_lissajous_subscans:0, $ ; set to 1 to build fake azimuth subscans in lissajous mode

          keep_mask:0, $ ; set to 1 to keep the mask even during iterative map making
          mask_default_radius:30.d0, $
          decor_per_subscan:1, $                 ; set to 0 to compute common modes and decorrelate on the entire scan
          decor_method:'COMMON_MODE_KIDS_OUT', $          ; Decorrelation method
          median_simple_Nwidth:4, $ ; in units of FWHM
          decor_period:0, $ ; set to a value in seconds on which the decorrelation is performed, other wise it works per subscan or per full scan
          drift_harmo_fmax:0.1, $ ; Hz
          cos_sin_elev_offset:0, $ ; set to 1 to decorrete from cos and sin of elevation offset rather than just elevation

          
          cross_corr_min:0.d0, $ ; set to non zero value to keep only kids cross correlated to better than this parameter for a common mode estimation

          w8_source:0, $ ; set to 1 to impose a 1./(1+ks^2) weight at common mode determination in nk_get_cm_sub_2
          source_mask:1, $ ; set to 0 to ignore any input source mask (old "common_mode")
          dual_band_decorr:0, $ ; use the 1mm to decorrelate the 2mm
          common_mode_array:1, $  ; old "common_mode" or "common_mode_kids_out": computes a single common mode with all the valid kids of the same array
          common_mode_acqbox:0, $ ; computes a common mode per acquisition box
          common_mode_subband_1mm:0, $ ; computes a common mode per acquisition band long(numdet/80)
          common_mode_subband_2mm:0, $ ; computes a common mode per acquisition band long(numdet/80)

          decor_2_method:'none', $ ; if we apply a second decorrelation
          decor_2_per_subscan:1, $ ; set to 1 to apply the second decorrelation per subscan

          n_harmonics_azel:2, $                  ; number of templates as functions of elevation or azimuth
          decor_elevation:1, $  ; set to 1 to decorrelate from sin(el), sin(az), sin(2*el), sin(2*az) (and cos...) in Lissajous mode
          decor_accel:0, $                       ; set to 1 to decorrelate from azimuth-elevation accelerations in OTF maps (to try)
          decor_qu:0, $                          ; set to 1 to decorrate toi_q and toi_u as well
          median_common_mode_per_block:1, $      ; set to 0 to compute the median common mode that is used for cross-calibration
                                            ; on all kids. If set to 1, the median common
                                            ; mode is computed using only kids from the block.
          corr_block_per_subscan:0, $            ; set to 1 to recompute the blocks of correlated kids per subscan (provided decor_per_subscan is set)
          n_corr_block_min:15, $                 ; minimum number of kids used to derive the common mode, in order of maximum correlation
          nsigma_corr_block:2, $ ; once the block or correlated kids is defined, any other kid correlated with those of the block at less than nsigma_corr_bloc is added to the block
          decor_all_kids_in_block:0, $ ; set to 1 to decorrelate from all kids in a block (i.e. several timelines) simultaneously rather than their common mode (single timeline)
          dist_min_between_kids:0.d0, $ ; set to non zero value to decorrelate from kids that are further from the current kid than this parameter.
          dist_max_between_kids:0.d0, $ ;
          polynomial_on_residual:0, $ ; set to 1 to apply to the residual timeline right after decorrelation, rather than on the signal TOI at the end of scan_reduce_1.pro
          flex_polynomial:0, $
          polynomial:0, $ ; set to some degree /= 0 to subtract a polynomial per kid, per subscan or per scan if decor_per_subscan : default subtracts a baseline
          nomask_poly:0, $    ; set to 1 to estimate the polynomials on all samples (iterative MM)
          polynom_subscan1mm:0, $   ; another way of subtracting a polynomial per subscan, only with ATMB method.
          polynom_subscan2mm:0, $   ; another way of subtracting a polynomial per subscan, only with ATMB method.
          nharm_subscan1mm:0, $   ; another way of subtracting harmonics per subscan, only with ATMB method.
          nharm_subscan2mm:0, $   ; another way of subtracting harmonics per subscan, only with ATMB method.
                                ; if nharm gt 0, then polynomial degree is stuck at 1
          atmb_defilter: 0, $ ; 0 default, 1 if one wants to undo the filtering in atmb
          atmb_exclude: 3., $ ; 3. default, in order to exclude kids which are too noisy (used only in the ATMB method and nk_w8 method 5) ie. 3 times more noisy than the median.
          atmb_accelsm: 0, $ ; (atmb method, 23 suggested) acceleration factor (<=23) ie. keep f<1Hz
          atmb_nsubscan:0, $ ; to accelerate atmb (in an exact way), the smaller the faster (>=4 recommended), give the number of subscans to be processed together
; 0 = default i.e. no acceleration, the whole scan is used in one go.
          atmb_dualband: 0, $ ; 0 default, 1 if one wants to decorrelate the 2mm with only the 1mm (no electronic decorrelation, no 2mm average either)
          atmb_init_subtract_file: '', $ ; '' is default. R&D on SZ effect
          atmb_filt_time1mm: 0., $ ; If set, will compute nharm and nsubscan consistently: it represents the longest periode of time (say 3s) in which the noise is flat, nharm will thus cut frequencies lower than 1/time.
          atmb_filt_fulltime: 72., $ ; Do not change (in principle), the duration where electronic noise is stable. (do not modulate with wavelength)
          atmb_filt_time2mm: 0., $ ; see computation in nk_decor_atmb_per_array
          interpol_common_mode:1, $ ; set to 1 to interpolate potential holes in the derived common mode with large masks
          keep_holes_in_common_mode:0, $ ; set to 1 to avoid common mode interpolation and put NaN in holes
          nmin_kids_in_cm:1, $ ; minimum to consider the common mode derivation as robust enough (place holder for now, to be optimized)
          nhits_fraction_min:0.3, $
          bandfreq_cmx_calib:1, $ ;Do you want to cross calib the atmosphere
          bandfreq_median:1, $                   ;Use median instead of mean for common mode computing
          fit_elevation:1, $
          pca_ncomp:0, $        ;Number of components for PCA
;;          baseline:[0,2.0], $
          
          ;;---------- Mask
          mask_freq:2, $                  ; choose between 1 or 2mm to define the mask during iterations
          mask_method:"s_over_n", $       ; choose which criterion to use to define the mask
          mask_s_over_n_nsigma:3.d0, $       ; number of noise sigma required to mask the pixels for decorrelation
          mask_signal_threshold:0.d0, $   ; if mask_method = "signal", pixels are masked when their value exceeds mask_signal_threshold.
          
          ;;---------- Filtering parameters
          notch_filter:0, $ ; set to 1 to filter out a small band
          notch_freq_min:1d6, $
          notch_freq_max:-1.d0, $
          kill_subscans_edges:0, $ ; to debug line_filter
          line_filter:0, $
          line_filter_width:2.264962d0, $ ; [Hz], width used to detect noise lines.
          line_filter_nsigma:4.d0, $   ; threshold to detect noise lines.
          line_filter_freq_start:1.d0, $ ; start to look for noise lines above this freq (Hz)

          prefilter:0, $        ; set to 1 to apply an extra Fourier filtering BEFORE the decorrelation
          prefilter_freqlow:0.d0, $
          prefilter_freqhigh:0.d0, $

          pre_wiener:0, $  ; set to 1 to Wiener filter 1/f before the decorrelation
          post_wiener:0, $ ; set to 1 to Wiener filter 1/f after the deocrrelation
          wiener_freq_min:0.1, $ ; (Hz) fit the 1/f power spec only on frequencies larger than this
          wiener_white_noise_freq:10., $ ; (Hz) minimum frequency of the white noise dominated band

          bandkill:0, $ ; set to 1 to exclude the [freqlow, freqhigh] band
          bandpass:0, $            ; set to 1 to perform a bandpass and keep only [freqlow, freqhigh]
          freqlow:0.d0, $          ; lower freq bound of the bandpass [Hz]
          freqhigh:0.d0, $         ; upper freq bound of the bandpass [Hz]
          bandpass_delta_f:0.d0, $ ; apodization width for the bandpass filter [Hz]

          ;;-------- For decorrelation performed only on some
          ;;         frequency bands
          clean_data_version:4, $ ; 4 = default use nk_clean_data_4 (3 is obsolete), others won't work
          n_decor_freq_bands:0, $ ; set to sthg non zero to do it
          decor_freq_low0:0.5d0, $
          decor_freq_high0:1.5d0, $
          decor_freq_low1:0.d0, $
          decor_freq_high1:0.d0, $
          decor_freq_low2:0.d0, $
          decor_freq_high2:0.d0, $
          
          ;;---------- Weigth parameters
          do_w8:1, $            ; set to 1 to weight timelines according to inverse variance
          w8_per_subscan:0, $   ; set to 1 to compute weights for each subscan independently, 2 to compute a constant weight, evaluated as the median of noise per subscan, other options have been added.; 4 (median avg of subscan or subscan itself if worse) 2 is median avg of all subscan noise, 5 is like 4 but high frequency noise modulates that weight (to deal with subscan beginning)
          force_w8_to_1:0, $
          map_bg_var_w8:1, $    ; set to 1 to weigh the coaddition of scans by the variance computed on the map instead of on TOI's
          kill_noisy_sections:0, $ ; set to 1 to discard the most noisy sections of timelines
          kill_noise_nsigma:3.d0, $ ; threshold used to discard noise sections of timelines
          nsigma_jump:4.d0, $ ; to flag jumps in the data
          discard_noisy_kids:1, $ ; kill noisy ( above 3 times median sigma) kids. 1 is default.
          
          ;;---------- Zero level parameters
          iterative_offsets:0, $ ; set to 1 to derive offsets per subscan after an iteration (May 4th, 2016)
          iterative_offsets_k:0.1, $ ; k parameter in the weighting formula in nk_iterative_offsets.
          set_zero_level_full_scan:0, $
          set_zero_level_per_subscan:1, $
          force_zero_level_polar:0, $ ; by default, we do NOT compute a zero level in polarization like in total power. set this to 1 if you want to compute a zero level in polarization as well
          
          ;;---------- Map parameters
          fine_pointing:0, $               ; set to something non zero to use actual vs commanded positions (0=commanded by default) 1 seems to introduce noise on the speed
          imbfits_ptg_restore:1, $ ; 0 means that we use the pointing from elvin (ie included in the raw nika data), 1 means that we use the antenna imbfits pointing.
          naive_projection:1, $            ; to bypass fits headers and astrometry
          input_fits_header:'', $ ; complete path to the .fits map that contains the header we want to use for the projection
          map_reso:2.d0, $       ; arcsec
          map_xsize:400d0, $ ; arcsec
          map_ysize:400d0, $ ; arcsec
          map_proj:'RADEC', $   ; 'AZEL', $   ;  or azel, or nasmyth
          polar_proj:'RADEC', $ ; to test
          map_smooth_1mm:6.0, $
          map_smooth_2mm:9.0, $
          map_pako_proj:'', $
          specific_reduction:'NONE',$
          saturn_azel_template_file:'none', $
          map_center_ra:!values.d_nan, $  ; output map center Ra in degrees
          map_center_dec:!values.d_nan, $ ; output map center Dec in degrees
          new_map_center_ra:!values.d_nan, $  ; output map center Ra in degrees that may differ from the object coordinates (dev. for Titan and Iapetus)
          new_map_center_dec:!values.d_nan, $ ; output map center Dec in degrees
          new_map_center_ra1:!values.d_nan, $  ; output map center Ra in degrees that may differ from the object coordinates (dev. for Titan and Iapetus)
          new_map_center_dec1:!values.d_nan, $ ; output map center Dec in degrees
;          map_head_1mm:strarr(50), $
;          map_head_2mm:strarr(50), $
          map_truncate_percent: 0., $ ; used in nk_truncate_filter_map (to eliminate the borders of maps in the iterative process), 0. means no truncation, which is default. 20. is recommended othewise
          map_median_fract: 0., $ ; subtract to the map a median obtained with a (fraction of FOV) default=0.3 for that fraction, used in nk_truncate_filter_map
          keep_only_high_snr:0., $ ; keep the high SNR part of a map. Used by nk_keep_only_high_snr and nk_scan_reduce_1. If param is gt than 0 then keep that param and above in the map pixels.
          do_fpc_correction:0, $   ;  set to 1 to apply (az,el) pointing corrections ONLINE
                                ;   set to 2 to read the (az,el)pointing
                                ;     correction from a file per run,
                                ;   3 to include also a photometric
                                ;     correction. 

          fpc_dx:0.d0, $
          fpc_dy:0.d0, $
          fpc_az:0.d0, $        ; azimuth pointing correction (Arcsec)
          fpc_el:0.d0, $        ; elevation pointing correction (arcsec)
          fpc_ra:0.d0, $        ; pointing offset in R. A.
          fpc_dec:0.d0, $       ; pointing offset in Dec
          new_rot_center:0, $   ; set to 1 for Open Pool 3
          
          ;;-------- Plots
          plot_dir:'', $        ; directory where all plots will be saved
          do_plot:1, $          ; set to 0 if you don't want any plot when running the pipeline
          plot_ps:0, $          ; set to 1 to produce .eps plots
          plot_png:0, $         ; set to 1 to produce .png plots (if ps=1, png is ignored)
          plot_pdf:0, $         ; set to 1 to produce .pdf plots instead of ps
          plot_z:0, $ ; set to 1 to plot in the Z buffer
          iconic:0, $           ; set to 1 if you don't want to see directly windows
          ;;---------- Photometry
          KRJ2KCMB_1mm:0.d0, $
          KRJ2KCMB_2mm:0.d0, $
          KCMB2Y_1mm:0.d0, $
          KCMB2Y_2mm:0.d0, $
          JY2KRJ_1mm:0.d0, $
          JY2KRJ_2mm:0.d0, $
          y2Kcmb_1mm:0.d0, $
          y2Kcmb_2mm:0.d0, $
          Beam2Sr_1mm:0.d0, $
          Beam2Sr_2mm:0.d0, $
          input_fwhm_1mm:12.d0, $ ; fwhm used for flux measurements
          input_fwhm_2mm:18.d0, $  ; fwhm used for flux measurements

          ;; aperture photometry
          do_aperture_photometry:1, $           ; set to 1 to do it, 0 to avoid it.
          aperture_photometry_zl_rmin:  60D0, $ ; default150.d0, $  ; min radius for zero level determination print, 90.^2-60.^2= 4500.00
          aperture_photometry_zl_rmax: 112D0, $ ; 300 default; max radius for zero level determination print,112.^2-90^2= 4444.00
          aperture_photometry_rmeas:    90D0, $ ; FXD: 90 to be in phase with Omega_90; default= 150.d0, $   ; radius of the flux measurement
          aperture_photometry_binwidth:5, $     ; arcsec
          ata_fit_beam_rmax:0.d0, $             ; arcsec set to a non zero value to define the maximum distance to the centroid
                                ; to be considered for a
                                ; background+gaussian fit (see
                                ; nk_ata_fit_beam.pro called in
                                ; nk_map_photometry.pro and beam_guess.pro)
          ;;---------- Calibration
          force_opacity_225:0, $ ; set to 1 to apply 225 opacity correction to all kids (for a test)
          mask_source_opacity:0, $ ; set to 1 to mask the source during opacity determination
          do_opacity_correction:6, $
; set to 0 to bypass the opacity estimation and correction,
; set to 1 to have a fixed opacity correction per scan
; set to 2 if one wants a continuous opacity correction
; set to 3 to have a constant opacity per scan corrected after
;               decorrelation (to avoid non linearity corrections).
; set to 4      if one wants a continuous opacity correction with
;                 Array 1 and 3 with different opacities
; set to 5      if one wants a continuous opacity correction with
;                 Array 1 and 3 with different opacities and Array 2
;                 opacities extrapolated from Array 1 ones
          ; set to 6 to implement the correction
          ; factor discussed in the
          ; commissioning report
          force_constant_elevation_opacorr:0, $ ; set to 1 to put a constant elevation in the opacity correction rather than the current one

          median_continuous_opa_samples: 101, $
; should always be 101: 101 samples are taken as the running length
; for the median continuous opacity correction applied to the TOI (the
; running median is applied in
; order to avoid a point-source signal contamination to the opacity).
          
          ;; The correction for the gain vs elevation must be applied
          ;; only for point sources.
          ;; set to 0 if no correction is required.
          ;; set to 1 to use EMIR curve (as we used to do until erly
          ;; 2017)
          ;; set to 2 to use NIKA2 curve (even if preliminary,
          ;; starting from N2R9) NP, Dec. 6th, 2017
          do_tel_gain_corr:0, $ ;nk_tel_gain_cor must be applied only for point sources, FXD recommends 0 if one uses a photometric correction based on the fpc_correction=2 option.
                                ;
          extended_source:0, $ ; set to 1 for an extended source (important for tel_gain_cornef
          
          ;;---------- Polar
          sign_data_position:1, $
          montier:0, $ ; set to 1 to use Montier et al Bayesian estimator of the degree of pol and the pol. angle
          old_pol_deg_formula:0, $ ; to use high S/N formula for polarization degree and associated error
          lab_polar:0, $        ; set to arbitrary value in case of lab tests
          polar:0, $ ; set to 1 if you know a priori that you're analysing a polarized scan
          polar_nu_rot_hwp:3.d0, $
          polar_angle_offset_deg:45.54d0, $ ;; offset angle between M4 and M5 telescope optics
          radec2nasmyth:0.d0, $ ;; for simulations: set to 1 if you read input maps in radec and want to project the results in nasmyth
          proj_nasmyth2radec:0.d0, $ ; set to 1 for correction of two lobes and to include the rotation of alpha angle in data.cospolar and data.sinpolar
          polar_n_template_harmonics:7, $
          off_source_for_hwpss:1, $ ; set to 0 to fit the HWPSS everywhere, including on source
          force_subtract_hwp_per_subscan:1, $ ; set to 1 to fit the HWPSS per subscan even if the I decorrelation is on the full scan
          force_subtract_hwp_per_two_subscans:0, $
          polar_do_lockin:1, $  ;mapmaking
          polar_do_coadd:0, $
          polar_cond_num_max:100, $
          polar_lockin_freqlow:0.d0, $
          polar_lockin_freqhigh:0.d0, $
          polar_lockin_delta_f:0.05d0, $
          improve_lockin:0, $ ; set to 1 to use the new lockin
          boxcar_smooth:0, $ ; set to any number to lowpass with box char avg rather than fourier lowpass in nk_lockin_2
          output_hwpss_residuals:0, $ ; set to 1 to produce a file with residuals amplitudes after HWPSS subtraction
          n_hwp_ang_per_quarter:5, $ ; number of HWP positions per quarter or rotation
          rm_hwp_per_subscan:0, $
          do_not_remove_hwp_template:0, $ ; set to 1 to bypass the HWP template subtraction
          hwp_harmonics_only:0, $ ; if set to 1, we do not fit for the linear drift, only for the sum of harmonics.
          lkg_kmax_2mm:0.06, $ ; NP, waiting for Alessia's commit
          lkg_kmax_1mm:0.08, $ ; NP, waiting for Alessia's commit
          lkg_gauss_regul:0, $
          harmonics_and_synchro:0, $ ; set to 1 to monitor the phases of the HWP harmonics and the top synchro
          keep_one_hwp_position: 0,  $ ; Experimental. Default should be kept at 0 (FXD), to project only one HWP position.
          ;;---------- Directories and files parameters
          name4file:'out',  $   ; used to name the file delivered to the astronomer
          source:'', $
          day:0L, $
          scan_num:0, $
          iscan:0, $            ;Current number of scan treated
          scan:'',$
          dir_save:!nika.save_dir, $
          noise_preproc:0, $
          project_dir:!nika.plot_dir, $ ; directory that will contain all the preproc and scan results of a given project
          preproc_copy:0, $ ; set to 1 to save a copy of data before anything "grid" or "decorrelation" dependent is done to them.
          preproc_dir:!nika.preproc_dir, $ ; where preprocessed data may be saved if param.preproc = 1
          version:'1', $        ; version of decorrelation
          output_dir:'', $  ; where results per scan are saved
          data_file:'', $
          file_kidpar:'', $
          file_ptg_photo_corr:'', $  ; filename is set up in get_kidpar, used if do_fpc_correction>2
          file_raw:'', $
          file_imb_fits:'', $
          xml_file:'', $
;          up_file:'', $         ; the UnProcessed file used when nk, /filing
          bp_file:'', $         ; the BeingProcessed file used when nk, /filing
          ok_file:'', $         ; replaces up_file. Created when the scan was correctly processed

          ;;----------- Glitches
          improve_deglitch:0, $
          glitch_iq:0, $        ; set to 1 to deglitch I, Q, dI, dQ timelines, otherwise deglitch toi
          glitch_width:100L, $ ; samples
          glitch_nsigma:5.d0, $
          deglitch_nsamples_margin:0, $ ; number of samples on each side of the glitch that are flagged out for safety (long glitches sometimes)
          second_deglitch:0, $ ; set to 0 to cancel the secon deglitch after the decorrelation
          new_deglitch:0, $ ; 1, $ ; set to 0 to revert to nk_deglitch (slower)

; FXD Aug2016, common glitches and jumps flagging parameters
          k_find_jumps: 0, $ ; (in nk_getdata)
                             ; Go into the nk_find_jumps routine (1) or not (0)
          k_glitch: [10.,  50, 10], $   ; standard glitch find
          k_jump:   [10., 200, 10], $     ; parameters to find jumps
          ndetglicommon:  30, $; at least 30 detectors must see the same impact
          ndetjumpcommon: 30, $; at least 30 detectors must see the same impact
          nsmoothju: 5,  $ ; smoothing by 5 used in jump detection
; param.k_glitch[0]  =  0  ; 0 is no deglitching
; param.k_jump[0]  =  0                    ; 0 don't look for jumps
          ;; Can deglitch within the Cf method
          Cf_deglitch: 0, $  ; 0= no Cf deglitch, 5 = 5-sigma clipping, 0 recommended.
          ;;------ RTS random telegraphic signal detection, removal of
          ;;       bad kids
          k_rts: 0,  $; 0:   don't do it by default,  1: will work only with Cf method, 1 is recommended
          ;;========= SZ oriented simulations
          add_source:0, $              ;put to 1 if you want to add a source in your TOI
          source_type:'', $            ;you can combine different source types (SZ, PS, WN or GIVEN_MAP) by separating them by + symbols
          ;-------SZ source
          source_z:0.5, $              ;the source redshift
          source_xoff:0.d0, $          ;offset from the center of the map
          source_yoff:0.d0, $
          source_calib_1mm:1.d0, $     ;coefficients to use to go from a y map to a Jy/beam map
          source_calib_2mm:1.d0, $
          gNFW_P0:0.15, $              ;parameters of the gNFW pressure profile
          gNFW_rp:500.0, $
          gNFW_a:1.22, $
          gNFW_b:4.13, $
          gNFW_c:0.31, $
          gNFW_c500:1.81, $
          simu_dir:'', $               ;where you want to save your simulated maps as fits files
;          sz_source_coord_ra:[0.d0,0.d0,0.d0], $        ;the center coordinates of the simulated cluster
;          sz_source_coord_dec:[0.d0,0.d0,0.d0], $
          ;-------Point source (gaussian)
;          N_ps:0, $                              ;Number of point sources to be simulated
;          ps_flux_1mm:dblarr(5), $            ;Point sources fluxes at 1 mm - Warning : the array size has to be N_ps
;          ps_flux_2mm:dblarr(5), $            ;Point sources fluxes at 2 mm
;          ps_position_x:dblarr(5), $          ;Point sources positions
;          ps_position_y:dblarr(5), $
          ;-------White noise
          wn_rms_1mm:0, $                  ;RMS of the simulated white noise
          wn_rms_2mm:0, $
          ;-------Given map
          map_file_1mm:'', $       
          map_file_2mm:'', $
          map_relobe_1mm:0, $
          map_relobe_2mm:0, $

          fast_deglitch:0, $    ; set to 1 to detect glitches on only one timeline and apply correction to all kids
          
          ;;-------- Miscellaneous
          force_mask_nhits:0, $
          decor_on_two_subscans:0, $
          cancel_subtract_maps:0, $
          do_dmm:0, $
          dmm_rmax:0, $
          dmm_kid_reso:30.d0, $
          dmm_map_reso:60.d0, $
          dmm_simu:0, $
          dmm_bandpass:0, $
          new_snr_mask_method:0, $
          skynoise_low_freq:1.d0/(5*60.d0), $ ; hz
          skynoise_high_freq:5.d0, $ ; hz
          atm_nsmooth:0, $
          positive_snr_toi:0, $
          lf_hf_freq_delim:4.d0, $
          mask_positive_region_only:0, $
          mytest:0, $
          mydebug:0, $
          baselines_pol_deg:1, $
          no_mask_before_polynomial_subtraction:0, $
          no_deglitch:0, $
          tiling_decorrelation:0, $
          even_odd_subscans:0, $
          no_bg_var_map:0, $

          test1:0, $
          test2:0, $
          subscan_edge_w8:-1.d0, $
          subscan_edge_w8_smooth_duration:0.461373, $
          imcm_iter:0, $
          extend_flags:0, $
          beam_freq_cut_db:0.d0, $
          eigenvec_block:'box', $
          improve_atm:0, $
          edge_source_interpol:0, $
;;;;;;          deglitch_atm_cm:0, $ ; set to 1 to look for glitches on the common mode
          do_reject_atm_outlyers:0, $ ; set to 1 to test a way to discard kids that could be badly tuned or badly responding
          k_snr_radius:1d6, $ ; to test
          log:0, $ ; set to 1 to record various comments in info.logfile during data processing
          decor_from_atm:1, $ ; set to 1 to include a common mode per array or for the full instru to estimate the atmosphere
          decor_from_box_modes:1, $ ; set to 1 to compute a common mode per elbox and use it in the general decorrelation
          decor_all_subbands:0, $ ; set to 1 to compute a common mode per subband
          scanamnika:0, $       ; set to 1 for Scanamnika specific features
          debug_lkg_plot:0, $
          use_flux_var_w8:0, $ ; set to 1 to recompute the variance per beam in nk_average_scans before combining scans (TB tested)
          g2_paper:0, $
          alpha_radec_deg:0.d0, $ ; extra user defined rotation in the radec plane
          show_decorr_residuals:0, $ ; nk_imcm_decorr
          show_mode_convergence:0, $ ; set to 1 to show convergence of multi modes in nk_imcm_decorr
          atm_per_array:0, $ ; set to 1 to derive an atmosphere template per array rather with all arrays together
          subtract_ignore_mask_radius:0.d0, $ ; set to 1 to ignore the mask inside this radius when subtracting i_map
          radius_zero_level_mask:0.d0, $
          nharm_multi_sinfit:0, $ ; for multi cos and sin templates fitting
          trigo_modes_period_arcsec:-1.d0, $
          freq_max_multi_sinfit:0.d0, $ ; to derive nharm_multi_sinfit on the fly
          fourier_lf_freqmax:-1.d0, $ ; set to anything gt 0.d0 to determine a low freq mode by Fourier transform of interpolated masked TOI's
          extra_nsmooth:0, $
          one_offset_per_subscan:0, $ ; set to 1 to fit one offset per subscan (while decorrelating on the entire scan if requested)
          outskirt_zero_radius:-1.d0, $ ; set to any zero or positive value to remove the average of the map at R > this radius
          restrict_to_3_subscans:0, $
          on_the_fly_kid_noise:0, $ ; set to 1 to recompute the noise per kid at each scan
          new_method:'', $
          show_toi_corr_matrix:0, $
          niter_atm_el_box_modes:1, $ ; number of iterations to separate atmosphere from eletronic boxes noise
          include_elevation_in_decor_templates:0, $ ; set to 1 to do so
          deal_with_glitches_and_jumps:0, $
          interactive:0, $ ; temporary parameter
          do_kid2median_test:0, $ ; set to one to reject kids that do not correlate well to a median mode
          cm_kid_min_dist:0.d0, $ ; minimum distance between KIDs to be used for common mode estimation in nk_get_cm_sub_4
          cm_kid_max_dist:1000d0, $ ; maximum distance between KIDs to be used for common mode estimation in nk_decor_kid_ring
          dir_basename:'', $ ; useful for iterative map making
          snr_max:1d6, $ ; to limit snr_toi during iterations
          iter_interpol_high_snr:0, $ ; set to 1 to interpolate data where subtract_maps.iter_mask_XX == 1
          map_bg_zero_level_radius:-1.d0, $ ; -1 default, no background level corrected, if ge 0, then a background for each map is determined outside the radius from the median of the values with abs(SNR)< 3.
          zero_mask_fits_file: '', $  ; supersedes the previous map_bg_zero_level_radius: give a fits file name containing grid.zero_level_mask_1mm and zero_level_mask_2mm fields (field=1 means use that pixel to force the zero level)
          toi_correlation_plots:0, $
          no_const_in_regress:0, $ ; set to 1 to ignore the constant term in regress (nk_subtract_templates_3)
          dave_tau_file:'', $
          method_num:0, $
          no_variance_w8:0, $ ; set to 1 to discard inverse variance weights in nk_average_scans
          simul_atmosphere_leakage:0, $ ; set to 1 to force some fraction of I timeline to leak into Q and U
          qu_iterative_mm:0, $ ; set to 1 to run an iterative Map making on Q and U as well (need keep_hwpss as well)
          subtract_frac:1.d0, $ ; fraction of the signal that is subtracted during the iterative map making
          smooth_subtract_maps: 0, $ ; if 1 the subtract_maps are smeared out using filter_image and   param.nsmooth_subtract_maps
          nsmooth_subtract_maps: 5, $ ; fwhm for the the smearing out of the subtract maps in arcsec
          off_source_fourier:0, $ ; replace data with constrained noise where off_source eq 0 before applying fourier filtering
          fourier_subtract:0, $ ; set to 1 to subtract the map before fourier filtering
          n_jk_maps:1, $        ; number of jackknife maps
          split_horver:0, $ ; default 0, if 1, will produce coadded maps with horizontal scans (_hor) and vertical scans (_ver), in addition to the usual average map in nk_average_scans, 3 means that a careful pairing of Hor and Ver is done before being injected in the Jack-Knife maps. 3 recommended from ATMB
          split_hor1:-20., $    ; degree, used only if split_horver is 1
          split_hor2:+70., $    ; degree, [hor1, hor2] give the range of scan_angle to qualify for a horizontal scan, everything else will be vertical
          all_proj:0, $ ; set to 1 to project in Nasmyth coordinates at the same time in grid2 in results.save
          show_monitoring:0, $
          commissioning_plot:0, $
          list_data_all:0, $ ; set to 1 to read all the variables in the raw data
          k_snr:0.01d0, $
          snr_exp:2, $
          k_snr_method:2, $     ; 2 default=use nk_ata_fit_beam2 (Gaussian with background),
                                ; 3 beam3 (without background)
          noiseup:0, $        ; 0 default, 1: increase the noise according to the number of fitted parameters (atmb method, and k_snr_method=3).
          restrict_data_to_valid_kids:1, $ ;save only data.toi[w1], etc... if /preproc_copy
          new_pol_synchro:1, $ ; new way to deal with top synchro (2018), mandatory
          sign_new_pol_synchro:-1d0, $ ; set to 0.0do to cancel the correction, -1. to change the sign for tests
          save_toi_corr_matrix:0, $ ; set to 1 to save the Kid to kid correlation matrix in results.save
          nhits_min_bg_var_map:5, $ ; minimum required number of hits per pixel to estimate backgd var map
          boost:0, $            ; set to 1 to increase the variance map by the boost factor of map/stddev
          project_white_noise_nefd:0, $
          project_pure_white_noise:0, $
          scan_quality_low_freq:0.01, $ ; lower bound of the freq. band for atmospheric monitoring
          scan_quality_freq:0.5d0, $ ; limit between low and high frequencies used to estimate the scan_quality
          give_scan_quality:1, $     ; set to 1 to estimate scan quality by total(power_spec(low freqs)^2/power_spec(high freqs)^2)
          SUB_THRES_SN:0.d0, $   ; signal to noise threshold to select which pixels are subtracted during iterative map making
          no_signal_threshold:0, $ ; set to 1 to avoid restriction on positive signals (iterative MM)
          sub_thres:0.d0, $        ; to test (iterative MM)
          iter_mask_radius:1.d6, $ ; to test
          bypass_calib:0, $      ; if set to 1, no calibration is applied to TOI's
          subscan_min:0, $      ; set to any value to discard all subscans before this one
          subscan_max:0, $      ; set to any value to discard all subscans after this one
          pps_time:1, $         ; 1, $               ; recompute UTC using pps info
          force_I_weight:0, $ ; set to 1 to force Q and U weights to be equal to I Weights (to debug)
          subtract_i_map:0, $ ; to test
          subtract_qu_maps:0, $
          accept_no_imbfits:0, $ ; set to 1 to work without the antenna imbfits (at your own risk)
          align:0, $ ; set to 1 to cross-check source alignement in nk_lkg_correct.pro for bright point sources (polar)
          output_noise:0, $ ; set to 1 to measure the noise per timeline at the end of nk and put results in the output kidpar
          read_type:1, $        ; 1 to read only "type 1 kids", 12 to read "type 1 and 2 kids"
          uncompressed:0, $ ; set to 1 to read uncompressed data (provided you've set up !nika.raw_Acq_dir correctly...)
          zigzag_correction:1, $ ; set to 1 to apply zigzag correction per array
          w8_map_rms:0, $       ; set to 1 to weight the coaddition of several scans by the rms of the maps in a radius of param.w8_map_rms_radius rather than the variance per pixel.
          w8_map_rms_radius:100.d0, $
          check_flags:0, $                  ; set to 1 to check flags and tunings (useful for RTA)

          pause:0, $ ; set to 1 to stop sometimes
          flag_n_seconds_subscan_start:0, $ ; set to 1 to discard the first n_seconds of each subscan
          flag_n_seconds_subscan_end:0, $ ; set to 1 to discard the last n_seconds of each subscan
          kid_monitor:0, $      ; set to 1 to monitor kid correlation to their Common Mode (set to 1 in nk_rta by default)
          jump_remove:0, $      ; set to 1 to remove jumps

          force_white_noise:0.d0, $ ; set to a non zero value to *REPLACE* data toi by pure white noise with this rms.
          twin_noise_toi:0, $ ; set to 1 to replace TOI's by simulations (**exact** same spectrum as the timelines after nk_clean_data_2)
          sim_fit_toi:0, $ ; set to 1 to replace TOI's by simulations (**fitted** on the tois after nk_clean_data_2)
          simuJK2:0, $ ; 0=default, 1=Does a jack-knife simulation by randomizing the position of Kids within an array (FXD May 2020)
          save_sim_data:0,  $  ; Recomm from NP
          svn_rev:0,$ ; pipeline version used during the reduction
          pipeline_dir:'', $
          raw_acq_dir:'', $
          cpu_time:0, $                                        ; set to 1 to display the time spent in each routine
          cpu_time_summary_file:'cpu_time_summary_file.dat', $ ; gathers routines and cpu information
          cpu_date_file:'cpu_date.dat', $                      ; system time when we enter a subroutine
          cpu_date0:0.d0, $ ; 1st reference date
          latex_pdf:0, $        ; set to 1 to produce a .pdf summary of the scan analysis
          clean_tex:0, $ ; set to 1 to erase all plots and .dvi, .aux, ... latex files but the .pdf
          input_cm_1mm:0, $
          input_cm_2mm:0, $
          max_on_source_frac:0.d0, $
          lf_sin_fit_n_harmonics:0, $
          do_checks:1, $ ; set to 0 to bypass nk_check_param_grid (at your own risk)
          one_fitsmap_per_scan:0, $
          discard_outlying_samples:0, $ ; set to 1 to do it
          no_polar:0, $ ; to skip polarized scans that are eroneously listed in Log_iram_tel_run11...
          grid_auto_init:0, $ ; set to 1 to let nk determine the (ra,dec) range from the current or 1st scan of the list
          focus_liss_new:0, $
          noerror:0, $
          readdata_feb15:1, $ ; set to 1 to use the new version of readdata (March 2015), default.
          renew_df: 2, $ ; default is now to recompute df_tone using Xavier's last formula (Feb. 2015)
          det2mm_test:176, $
          det1mm_test:6, $
          ;$ subscan_test:7, $     ; to debug
          subscan_test:16, $     ; to debug
          debug:0, $
          switch_rf_didq_sign:0, $ ; set to 1 to switch the sign of RF_DIDQ (debugging versions of acquisition...)
          force_kidpar:0, $  ; set to 1 to avoid using the reference kidpar (then param.file_kidpar should be set manually)
          no_otf_ptg_restore:0,  $ ; set to 1 to bypass otf pointing reconstrution if there are holes
          educated_fit_dmax:60.d0,  $
          delete_all_windows_at_end:0, $ ;set to 1 to remove all plots windows (useful when nk is launched on many scans)
          do_rfpipq:0, $                 ;set to 1 to compute the new RF_pIPQ (calibration diode related quantity)
          nsec_smooth_pipq:10, $ ; width of the smoothing kernel for pipq calibration in SECONDS
          make_imbfits:0, $             ; set to 1 to produce imbfits
          keep_iqdidq:0, $              ; set to 1 to keep i,q,di,dq in the structure data (otherwise, nk_shrink_data kills them)
          pointing_accuracy_tol:2.d0, $ ; tolerance on the azimuth sine fit and the actual ofs_az in lissajous mode to discard the start/end slews
          speed_tol:5.d0, $             ; tolerance on scanning speed (arcsec/s)
          nsample_min_per_subscan:50, $  ;if non zero, any subscan with less samples than this parameter will not be decorrelated nor projected
                                ; We init it to 1 to allow tests with a number
                                ; of samples in a subscan equal to 0.
          treat_data_holes:0, $
          hole_width_sec:10.d0, $   ; set to any number to flag out holes or big jumps in the data (e.g. Run9)
          hole_nsigma:5.d0, $      ; number of stddev to detect a hole in the data

          educated:1, $
          fourier_opt_sample:0,  $ ; by default, optimize the legnth of data for Fourier transforms (set to 0 to bypass)
          undersamp_preproc:0, $   ; integer factor to degrade sampling
          undersamp_postproc:0, $  ; integer factor to degrade sampling
          cut_scan_exec:'', $      ; temporary
          lab:0, $                 ; set to 1 in case of lab data, without imbfits etc...
          rta:0, $                 ; set to 1 if you're running Real Time Analysis
          skydip:0, $              ; set to 1 if you're running a skydip and need to keep a_masq and b_masq
          silent:0, $              ; set to 1 to avoid messages
          one_mm_only:0, $         ; set to 1 to work only with 1mm kids
          two_mm_only:0, $         ; set to 1 to work only with 2mm kids
          a1_discard:0, $          ; set to 1 to discard array 1
          a2_discard:0, $          ; set to 1 to discard array 2
          a3_discard:0, $          ; set to 1 to discard array 3

          x_center_keep:0.d0, $ ; Nasmyth center around which we keep only some kids (see rmin_keep [...] rmin_proj)
          y_center_keep:0.d0, $ ; Nasmyth center around which we keep only some kids (see rmin_keep [...] rmin_proj)
          rmin_keep:0.d0, $     ; keep only kids outside a radius rmin from the reference kid
          rmax_keep:1000.d0, $  ; keep only kids inside a radius rmax from the reference kid
          rmax_proj:-1.d0, $ ; set to a positive values to project only data around the map center at max. dist.= rmax_proj
          rmin_proj:-1.d0, $ ; set to a positive values to project only data around the map center at min. dist.=rmin_proj
          
          all_kids:0, $            ; set to 1 to read all kids

          cpu_t0:0.d0, $           ; start time of the routine
;;          tau_weight:0, $          ; set to 1 to weight maps by (exp(-tau))^2 when we average scans
          discard_otf_slew:1, $    ; set to 1 to discard the beginning and end of otf scans when the telescope moves
                                ; from the source at the center to the edge of
                                ; the first or last subscan.
          trans_func_mask:1, $ 
          
          ;;---- Atmosphere monitoring
          do_meas_atmo:0, $     ; set to 1 to monitor atmosphere power spectrum

;;           ;;---------- Type of signal
;;           alain_rf:0, $
;;           math:"PF"}  ; can be "RF" (the RF_dIdQ method), "PF" the 2D polynomial fitting or "CF" the circle fitting method. PF is recommended for the time being.
          ;;---------- Type of signal
          alain_rf:1, $
          math:"RF"}  ; can be "RF" (the RF_dIdQ method), "PF" the 2D polynomial fitting or "CF" the circle fitting method. PF is recommended for the time being.


end
