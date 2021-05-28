;+
;
; SOFTWARE: 
;        NIKA Simulations Pipeline
; 
; PURPOSE: 
;        To initialize the parameter structure used in the simulation.
; 
; INPUT: 
;        None
;        
; OUTPUT: 
;        The parameter structure used to simulate the data
; 
; KEYWORDS:
;        - SIMPAR: the parameter structure containing the simulation
;          information can be provided directly. Otherwise the default
;          pipeline is launched (i.e. Uranus geometry).
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - 09/03/2014: creation from partial_simu_launch.pro (Remi Adam - adam@lpsc.in2p3.fr)
; 
;-

pro nks_init, simpar, n_ps=n_ps, map=map

;;========== Calling sequence
if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nks_init, simpar, n_ps=n_ps"
   return
endif

;; Max number of point sources in a simulation
if not keyword_set(n_ps) then n_ps = 1

;;========== Define the structure
simpar = {$
         reset:1, $                    ; set to 0 if you want to add simulated TOI's
                                       ; to existing data without putting them to zero first
         polar: 1, $                   ; set to 1 if you want to add a modulation to TOI  
         ;;========== Source
         source_type:'point_source', $ ;Default is a point source
         ;;source_type:'point_source_real_beam', $
         ;;source_type:'cluster', $     
         ;;source_type:'cluster_point_source', $ 
         ;;source_type:'disk', $ 
         ;;source_type:'given_map', $ 
         
         ;; Kid uniform fwhm
         uniform_fwhm:0, $      ; set to 1 to impose the same fwhm to all kids at the same lambda
         fwhm_1mm:!nika.fwhm_nom[0], $
         fwhm_2mm:!nika.fwhm_nom[1], $

         ;;---------- Point source 
         parity:0, $ ; set to 1 to apply some parity weight to the data but not the simulated P. S (not fully tested yet)
         n_ps:n_ps, $
         ps_flux_1mm:dblarr(n_ps), $         ;Jansky
         ps_flux_2mm:dblarr(n_ps), $         ;Jansky
         ps_flux_q_1mm:dblarr(n_ps), $         ;Jansky
         ps_flux_u_1mm:dblarr(n_ps), $         ;Jansky
         ps_flux_q_2mm:dblarr(n_ps), $         ;Jansky
         ps_flux_u_2mm:dblarr(n_ps), $         ;Jansky
         ps_offset_x:dblarr(n_ps) + 0.0, $ ;arcsec
         ps_offset_y:dblarr(n_ps) + 0.0, $      ;arcsec

         ;;---------- Galaxy cluster
         source_gc_z:0.45, $      ;
         source_gc_p0:0.2, $      ;keV/cm^3
         source_gc_rs:90.0, $     ;arcsec
         source_gc_a:1.2223, $    ;
         source_gc_b:5.4905, $    ;
         source_gc_c:0.7736, $    ;
         source_gc_conc:1.81, $   ;
         source_gc_posx:0.0, $    ;arcsec
         source_gc_posy:0.0, $    ;arcsec
         
         ;;---------- Disk
         source_disk_flux1mm:1.0, $   ;Jansky/beam
         source_disk_flux2mm:1.0, $   ;Jansky/beam
         source_disk_radius:30.0, $   ;arcsec
         source_disk_posx:0.0, $      ;arcsec
         source_disk_posy:0.0, $      ;arcsec

         ;;---------- Map to be read
         source_map_file1mm:'', $      ;
         source_map_file2mm:'', $      ;
         source_map_relob1mm:10.0, $   ;arcsec
         source_map_relob2mm:10.0, $   ;arcsec
         xmin:0.d0, $
         ymin:0.d0, $
         nx:0.d0,   $
         ny:0.d0,   $
         map_reso:0.d0, $
         ;;---------- Optics properties
         beam1mm:!nika.fwhm_nom[0], $        ;arcsec
         beam2mm:!nika.fwhm_nom[1], $        ;arcsec

         ;; pointing error
         nas_x_offset:0.d0, $ ; add a fixed unknow offset to the Nasmyth kid coordinates
         nas_y_offset:0.d0, $
         nsample_ptg_shift:0.d0, $ ; shift the pointing timelines (ofs_az, ofs_el...) by this number of samples
         
         ;;========== Scan properties
         scan_type:'OTF', $
         ;;scan_type:'lissajous'
         ;;scan_type:'cross'
         scan_speed:36.0, $         ;arcsec/s
         scan_nsubscan:19.0, $      ;
         scan_xsize:360.0, $        ;
         scan_ysize:180.0, $        ;
         scan_elev:50.0, $          ;degrees
         scan_paral:0.0, $          ;degrees

         ;;========== Atmosphere
         atm_tau1mm:0.12, $         ;
         atm_tau2mm:0.08, $         ;
         atm_F01mm:157.0, $         ;Jy
         atm_F02mm:29.0, $          ;Jy
         atm_Fel1mm:43.0*273, $     ;Jy/arcsec
         atm_Fel2mm:13.0*273, $     ;Jy/arcsec
         atm_alpha:1.35, $          ;
         atm_cloud_vx:1.0, $        ;m/s
         atm_cloud_vy:0.0, $        ;m/s
         atm_cloud_reso:0.5, $      ;meters
         atm_cloud_alt:2000.0, $    ;meters
         
         ;;=========== kid independent noise
         toi1:0, $              ; set to 1 to replace all the samples by '1' before projection (to monitor covar matrices)
         quick_noise_sim:0, $   ; quick white and uniform noise on all kids
         sigma_white_noise:0.d0, $       ; set to any non zero value to add uncorrelated white gaussian noise with this stddev
         kid_NET:0.d0, $        ; Hz/sqrt(Hz)
         kid_fknee:0.d0, $
         kid_alpha_noise:0.d0, $
         add_one_corr_and_white_noise:0.d0, $
         white_noise:0, $

         ;;========== Electronics
         elec_Fref:1.0, $           ;Hz
         elec_beta:-0.4, $          ;
         elec_amp_cor1mm:50e-3, $   ;Jy.sqrt(s)
         elec_amp_cor2mm:20e-3, $   ;Jy.sqrt(s)
         elec_beta_block:-0.6, $
         elec_amp_block:[10.0,15.0,20.0,25.0,30.0, $
                         2.0,4.0,6.0,8.0,10.0]*1e-3, $
         elec_amp_dec1mm:25e-3, $   ;Jy.sqrt(s)
         elec_amp_dec2mm:10e-3, $   ;Jy.sqrt(s)

         ;;========== Glitches
         glitch_rate1mm:0.07, $   ;s^-1
         glitch_rate2mm:0.1, $    ;s^-1
         glitch_mean:0.0, $       ;Jy
         glitch_stddev:1.3, $     ;Jy
   
         ;;========== Pulse Tube
         pt_freq:[1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, $      ;Hz
                  5.5, 6.0, 6.5, 7.0, 7.5, 8.0, 8.5, 9.0, 9.5, $      ;
                  10.0, 10.5, 11.0, 11.5, 12.0, 12.5, 13.0, 13.5, $   ;
                  14.0, 14.5, 15.0, 15.5, 16.0, 16.5, 17.0], $        ;
         pt_amp:[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, $       ;Jy
                 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, $       ;
                 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, $            ;
                 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0], $                ;
         pt_phase:[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, $     ;Radian
                   0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, $     ;
                   0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, $          ;
                   0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0], $              ;

         ;;========== Plateau
         plateau_pc1mm:0.0, $   ;Percent
         plateau_pc2mm:0.0}     ;Percent


;; In case there are input maps to the simulation
if keyword_set(map) then begin
   simpar.nx = n_elements(map[*,0])
   simpar.ny = n_elements(map[0,*])

   simpar_out = create_struct( simpar, $
                               "xmap",map*0.d0, $
                               "ymap", map*0.d0, $
                               "map_i_1mm",map*0.d0,$
                               "map_i_2mm",map*0.d0,$
                               "map_var_i_1mm",map*0.d0,$
                               "map_var_i_2mm",map*0.d0)
   
   if simpar.polar ne 0 then simpar_out = create_struct( simpar_out, $
                                                         "map_q_1mm",map*0.d0, $
                                                         "map_u_1mm",map*0.d0, $
                                                         "map_q_2mm",map*0.d0, $
                                                         "map_u_2mm",map*0.d0, $
                                                         "map_var_q_1mm",map*0.d0, $
                                                         "map_var_u_1mm",map*0.d0, $
                                                         "map_var_q_2mm",map*0.d0, $
                                                         "map_var_u_2mm",map*0.d0)
   simpar = simpar_out
endif



end
