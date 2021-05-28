
pro nika_init_structure

run = getenv("NIKA_RUN")
lambda_a = 1
lambda_b = 2

f_sampling = 23.8418

nika_struct = create_struct( "f_sampling", f_sampling, $
                             "new_find_data_method", 0, $
                             "pipeline_dir", getenv('NIKA_PIPELINE'),$
                             "raw_data_dir", getenv('NIKA_RAW_DATA_DIR'), $
                             "raw_acq_dir", getenv('NIKA_RAW_ACQ_DIR'), $
                             "fpc_dir", getenv('NIKA_FPC_DIR'), $
                             "soft_dir", getenv('NIKA_SOFT_DIR'), $
                             "simu_dir", getenv('NIKA_SIMU_DIR'), $
                             "data_dir", getenv('NIKA_DATA_DIR'), $
                             "save_dir", getenv('NIKA_SAVE_DIR'), $
                             "imb_fits_dir", getenv('IMB_FITS_DIR'), $
                             "off_proc_dir", getenv('OFF_PROC_DIR'), $
                             "plot_dir", getenv('NIKA_PLOT_DIR'), $
                             "workspace", getenv('NIKA_WORKSPACE'), $
                             "preproc_dir", getenv('NIKA_PREPROC_DIR'), $
                             "xml_dir", getenv('XML_DIR'), $
                             "config_file", getenv('NIKA_CONFIG_FILE'), $
                             "zigzag", dblarr(3), $ ; 0.d0
                             "lng", -3.3987564198685, $     ; retrieved from IMBfits
                             "lat", 37.0684132670517, $     ; retrived from IMBfits
                             "boxes", ["A", "B"], $
                             "plot_window", intarr(10)-1, $
                             ;;--------------
                             ;; Parameters to re-compute PF from I, Q, dI, dQ on
                             ;; the fly
                             "pf_ndeg", 0, $
                             "freqnorma", 0.d0, $
                             "freqnormb", 0.d0, $
                             "freqnorm1", 0.d0, $
                             "freqnorm2", 0.d0, $
                             "freqnorm3", 0.d0, $
                             ;; FXD: add sign_angle (+ for Run9+ and - for
                             ;;                                        Run8-)
                             "sign_angle", +1, $
                             ;;--------------
                             "matrix", ["W1", "W2"], $
                             "grid_step", [6.91, 9.53, 6.91], $
                                ; FXD: nominal number of kids designed to
                                ; cover the FOV (valid till run 5,
                                ; tbc before)
                             "ntot_nom", [1140, 616, 1140], $
                             "lambda", [1.25,2.05], $
                             "omega_90", [211., 434., 211.], $ ; table 9 of Perotto et al, 2020
;;                              "fwhm_nom", [12.d0, 17.d0], $
;;                              "fwhm_array", [12.d0, 17.d0, 12.d0], $
                             "fwhm_nom", [12.5d0, 18.5d0], $
                             "fwhm_array", [12.5d0, 18.5d0, 12.5d0], $
                             "nefd", [63.3, 9.2, 46.7], $ ; mJy.s^1/2
                             "retard", 0, $
                             "debug", 0, $
                             "ptg_shift", 0.d0, $
                             ;; place holders
                             "numdet_ref_1mm", -1, $
                             "numdet_ref_2mm", -1, $
                             "ref_det", [-1,-1,-1], $ ; 3 arrays in NIKA2
                             "sign_data_position", 1.d0, $
                             "fpga_change_frequence_flag", 0B, $
                             "balayage_en_cours_flag", 0B, $
                             "tuning_en_cours_flag", 0B, $
                             "blanking_synthe_flag", 0B, $
                             "flux_mercury", dblarr(3), $
                             "flux_uranus",  dblarr(3), $
                             "flux_mars",    dblarr(3), $
                             "flux_jupiter", dblarr(3), $
                             "flux_neptune", dblarr(3), $
                             "flux_saturn",  dblarr(3), $
                             "flux_venus",   dblarr(3), $
                             "flux_ceres",   dblarr(3), $
                             "flux_pallas",  dblarr(3), $
                             "flux_vesta",   dblarr(3), $
                             "flux_lutetia", dblarr(3), $
                             "flux_3c84",    dblarr(3), $
                             "flux_mwc349",  dblarr(3), $
                             "flux_crl618",  dblarr(3), $
                             "flux_crl2688", dblarr(3), $
                             "flux_ngc7027", dblarr(3), $
                             "ext", ["A1mm", "B2mm"], $
                             "run", 'dummy', $
                             "acq_version", 'v1', $
                             "subscan_delay_sec", 1.20796) ; shift subscan forward by this delay so that subscan starts close to scan_st=subscanstarted

;; Add new field to !nika and keep backward compatibility
m = create_struct("lambda", -1, $
                  "numdet_ref", -1, $
                  "numdet_ptg_ref", -1, $
                  "box", 'z', $
                  "name", 'z', $
                  "mask", 'a', $
                  "kidpar_ref", 'a', $
                  "fwhm_avg", 0.d0, $
                  "magnif", 0.d0, $
                  "ngrid_nodes_max", 0, $
                  "median_s2", 0.d0, $
                  "median_s1", 0.d0, $
                  "median_calib", 0.d0, $
                  "nvalid", 0, "noff", 0, "ntbc", 0)

m = replicate(m, 2) ; two arrays

m[0].lambda             = 1
m[0].box                = 'A'
m[0].name               = 'W1'
m[0].fwhm_avg           = 0
;m[0].mask               = 'NICA8E_20nm'
m[0].ngrid_nodes_max = 256 ; 16x16
;m[0].kidpar_ref         = getenv('OFF_PROC_DIR')+'/2012_11_15_16h29m30_0061_W1_kidpar_v1.fits'
m[0].numdet_ref         = 0
m[0].numdet_ptg_ref     = 0
m[0].magnif             = 0


m[1].lambda             = 2
m[1].box                = 'B'
m[1].name               = 'W2'
m[1].fwhm_avg           = 0
;m[1].mask               = 'NICA8C_new'
m[1].ngrid_nodes_max = 144 ; 12x12
;m[1].kidpar_ref         = getenv('OFF_PROC_DIR')+'/2012_11_15_16h29m30_0061_W2_kidpar_v1.fits'
m[1].numdet_ref         = 0
m[1].numdet_ptg_ref     = 0
m[1].magnif             = 0

nika_struct = create_struct( nika_struct, "array", m)

defsysv, '!nika', nika_struct

;; Update fluxes and retard
;; fill_nika_struct, run


end
