
pro init_pol_sim_struct, ps


;;=======================================================================
;;========================== General and type of simu ===================
;;=======================================================================
gen = create_struct( "simu_name", "simu")
gen = create_struct( gen, "version",1)
gen = create_struct( gen, "output_dir", ".") ; Output directory for plots and logbook

;;=======================================================================
;;========================== Type of scan ===============================
;;=======================================================================

;; OTF_geometry
gen = create_struct( gen, "scan_num", 200)
gen = create_struct( gen, "day", '20140126')

gen = create_struct( gen, "real_scan", 0) ; set to 1 to use the actual scan, 0 to simulate one

scan = create_struct( "az_speed", 37.d0)                   ; nominal is 37 arcsec/s
scan = create_struct( scan, "n_subscans", 57)              ; nominal is 57
scan = create_struct( scan, "el_step", 4.d0)               ; nominal is 4.d0 arcsec

;;=======================================================================
;;=========================== Input sky =================================
;;=======================================================================

sky = create_struct(      "t_ampl", 1.d0)            ; set to 0 if no Temperature in input (S0=0)
sky = create_struct( sky, "p_ampl", 1.d0)            ; set to 0 if no Polarization in input (S1=S2=0)

;; Power law, constant polarization
sky = create_struct( sky, "source"        , "dust")
sky = create_struct( sky, "diffuse_index" , -3)
sky = create_struct( sky, "pol_deg"       , 0.1)
sky = create_struct( sky, "alpha_pol"     , 20.*!dtor)
sky = create_struct( sky, "random_pol"    , 0         )   ; set to 1 to have S1 and S2 with the same power law as S0, otherwise polarization is constant (pol_deg, alpha_pol).
sky = create_struct( sky, "reso_map"      , 1.d0       )  ; arcsec

;; unpolarized point sources
sky = create_struct( sky, "n_unpol_ps" , 0)

;; Same flux for all point sources, polarized or not for now
sky = create_struct( sky, "ps_flux", 1.d0)

;; polarized point sources
sky = create_struct( sky, "n_pol_ps"   , 0)
sky = create_struct( sky, "pol_deg_ps" , 0.05)

;; CMB
;; Point source
;; Crab
;; Whatever

sky = create_struct( sky, "nx", 0L)
sky = create_struct( sky, "ny", 0L)
sky = create_struct( sky, "xmin", 0L)
sky = create_struct( sky, "ymin", 0L)



;;=======================================================================
;;============ Instrument parameters to overwrite kidpar etc... =========
;;=======================================================================
instr = create_struct( "fwhm_2mm" , 17.d0             )    ; arcsec
instr = create_struct( instr, "fwhm_1mm" , 12.d0              )  ; arcsec
instr = create_struct( instr, "force_same_beam", 1) ; force all kids to have the same beam

;; HWP
hwp = create_struct( "nu_rot"      , 5.d0             ) ; hwp rotation frequency [Hz]
hwp = create_struct( hwp, "jones", dcomplexarr(2,2))

;; Splitting grid
grid = create_struct( "jones", dcomplexarr(2,2))

;; update
gen = create_struct( gen, "nu_sampling" , round( 8.*4.*hwp.nu_rot)) ; timelines sampling [Hz]

;;================================================================================
;;============================= Atmosphere parameters ============================
;;================================================================================
gen = create_struct( gen, "add_sky_noise",   0)              ; set to 1 to add sky noise

sky_noise = create_struct( "h_cloud"        , 3000.)                     ; meters above the Telescope
sky_noise = create_struct( sky_noise, "atm_alpha"      , 11./3./2      ) ; See Xavier's value in Diabolo/Simu...
sky_noise = create_struct( sky_noise, "cloud_vx"       , 1.            ) ; m.s^-1
sky_noise = create_struct( sky_noise, "cloud_vy"       , 1.            ) ; m.s^-1
sky_noise = create_struct( sky_noise, "cloud_map_reso" , 1.            ) ; m
sky_noise = create_struct( sky_noise, "disk_convolve"  , 1             ) ; convolve by the primary diameter
sky_noise = create_struct( sky_noise, "atm_amplitude"  , 1e-3          ) ; relative to the simulated signal

;;================================================================================
;;============================= HWP template ====================================
;;================================================================================
gen      = create_struct( gen, "add_template", 0)

template = create_struct( "n_harmonics", 8)
template = create_struct( template, "ampl", 1.d0)
template = create_struct( template, "drift", template.ampl*0.01/60.) ; 1 percent per minute (place holder)

;;================================================================================
;;================================ Noise =========================================
;;================================================================================
gen   = create_struct( gen, "add_one_over_f", 0)

noise = create_struct(          "NET", 1d-4)
noise = create_struct( noise, "fknee", 1.d0) ; Hz
noise = create_struct( noise, "alpha", 2)


ps = {gen:gen, $
      scan:scan, $
      sky:sky, $
      instr:instr, $
      hwp:hwp, $
      grid:grid, $
      sky_noise:sky_noise, $
      template:template, $
      noise:noise}


end
