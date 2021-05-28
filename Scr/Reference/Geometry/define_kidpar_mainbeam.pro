;;
;;
;;    Beam map scan analysis and Kidpar file production
;;
;;=====================================================================

;scan_list      = '20170125s243'
scan_list        = '20170224s177'
scan_list        = '20170424s123'
scan_list        = '20171025s41'
;;scan_list        = '20171025s42'

ptg_numdet_ref = 823
ptg_numdet_ref = 824 ;; change of ref KID at N2R12

source         =  'Uranus'
nk_scan2run, scan_list[0]
input_flux_th  = !nika.flux_uranus

;; source         = '3C84'
;; nk_scan2run, scan_list[0]
;; input_flux_th  = !nika.flux_3C84
;; input_flux_th  = dblarr(3)+1.d0

;source         =  'Neptune'
;nk_scan2run, scan_list[0]
;input_flux_th  = !nika.flux_neptune


;; define a directory for the analysis outputs
;;--------------------------------------------------------------
;; make_geom_mainbeam can be launched in a previous Beammap directory
;; it will create 2 output directories:
;; Beams_main_beam and Kidpars_main_beam

beam_maps_dir = "$HOME/NIKA/Plots/Run22/Beammaps_cm_one_block"
beam_maps_dir = "$HOME/NIKA/Plots/Run23/beammaps_reso2"
beam_maps_dir = "$HOME/NIKA/Plots/N2R12/Beammaps"


prepare   = 0  ;; set to 0 if maps are already created
beams     = 1  ;; call for geom_fit_mainbeam_parameters
merge     = 1
select    = 1  ;; set to 1 to write the kidpars (even if no further selection is needed)
finalize  = 1
iteration = 2
reso      = 4.
;;reso      = 2. ; default is 4. arcsec

if iteration eq 1 then begin
   delvarx, input_kidpar_file
endif else begin
   if scan_list[0] eq '20170125s243' then input_kidpar_file = !nika.off_proc_dir+"/kidpar_20170125s243_v2_skd1.fits"
   if scan_list[0] eq '20170224s177' then input_kidpar_file = !nika.off_proc_dir+"/kidpar_20170224s177_v2_cm_one_block_FR.fits"
   if scan_list[0] eq '20170424s123' then input_kidpar_file = !nika.off_proc_dir+"/kidpar_20170424s123_v2_cm_one_block_LP_calib.fits"
   if scan_list[0] eq '20171025s41' then input_kidpar_file = !nika.off_proc_dir+"/kidpar_20171025s41_v2_LP.fits"
   if scan_list[0] eq '20171025s42' then input_kidpar_file = !nika.off_proc_dir+"/kidpar_20171025s42_v2_LP.fits"
endelse

;; reso = 2 , with interpolation
;;make_geometry_mainbeam, scan_list, input_flux_th, ptg_numdet_ref=ptg_numdet_ref, iteration=iteration, $
;;                        source=source, beam_maps_dir=beam_maps_dir, input_kidpar_file=input_kidpar_file, $
;;                        prepare=prepare, beams=beams, merge=merge, select=select, finalize=finalize, $
;;                        decor_method='common_mode_one_block', $
;;                        sidelobe_mask_r_in = [9., 14., 9.], sidelobe_mask_r_out = [50., 50., 50.], $
;;                        sidelobe_mask_fit = 0, reso=reso, guess_fit_par=1, interpol=1, use_fwhm_azel=0


;; reso = 4, no interpolation, for each kid, jointly fit the internal
;; radius and the FWHM.
;; make_geometry_mainbeam, scan_list, input_flux_th, ptg_numdet_ref=ptg_numdet_ref, iteration=iteration, $
;;                         source=source, beam_maps_dir=beam_maps_dir, input_kidpar_file=input_kidpar_file, $
;;                         prepare=prepare, beams=beams, merge=merge, select=select, finalize=finalize, $
;;                         decor_method='common_mode_one_block', $
;;                         sidelobe_mask_r_in = 0., sidelobe_mask_r_out = [50., 50., 50.], $
;;                         sidelobe_mask_fit = 1, reso=reso, guess_fit_par=1, interpol=0, use_fwhm_azel=0, $
;;                         dir_nickname='main_beam_rfit'

;; reso = 4, no interpolation, use fixed radii
make_geometry_mainbeam, scan_list, input_flux_th, ptg_numdet_ref=ptg_numdet_ref, iteration=iteration, $
                       source=source, beam_maps_dir=beam_maps_dir, input_kidpar_file=input_kidpar_file, $
                       prepare=prepare, beams=beams, merge=merge, select=select, finalize=finalize, $
                       decor_method='common_mode_one_block', $
                       sidelobe_mask_r_in = [9., 13., 9.], sidelobe_mask_r_out = [50., 50., 50.], $
                       sidelobe_mask_fit = 0, reso=reso, guess_fit_par=1, interpol=0, use_fwhm_azel=0, $
                       dir_nickname='main_beam_9_13'

;; comparison to v0 kidpar
   
   ;; set to 1 to plot the kid offsets only (no ellipses)
   nobeam = 0
   ;; set to some nasmyth offset coordinates to zoom in 
   zoom_coord = [1,1]
   zoom_coord = 0
   ;; plot histograms (for fwhm and ellipticity)
   plot_histo = 1
   ;; save the plots
   savepng = 0
   saveps  = 0
   file_suffixe = 0
   

   ;; compare_kidpar_plot, [!nika.off_proc_dir+"/kidpar_skydip_n2r9_skd1.fits", "kidpar_"+scan_list[0]+"_v2.fits"], $
   ;;                      nobeam=nobeam, zoom_coord=zoom_coord, $
   ;;                      savepng=savepng, saveps=saveps, file_suffixe=file_suffixe, $
   ;;                      plot_histo=plot_histo
   
   ;; compare_kidpar_plot, ["kidpar_"+scan_list[0]+"_v0.fits", "kidpar_"+scan_list[0]+"_v2.fits"], $
   ;;                      nobeam=nobeam, zoom_coord=zoom_coord, $
   ;;                      savepng=savepng, saveps=saveps, file_suffixe=file_suffixe, $
   ;;                      plot_histo=plot_histo

   
   compare_kidpar_plot, [input_kidpar_file, "kidpar_"+scan_list[0]+"_v2.fits", !nika.off_proc_dir+"/kidpar_20171025s41_v0_FR.fits"], $
                        nobeam=nobeam, zoom_coord=zoom_coord, $
                        savepng=savepng, saveps=saveps, file_suffixe=file_suffixe, $
                        plot_histo=plot_histo


   compare_kidpar_plot, ["kidpar_"+scan_list[0]+"_v2.fits", "$HOME/NIKA/Plots/Run23/beammaps_calib/kidpar_20170424s123_v2_mainbeam_reso4_rin_9_14.fits"], $
                        nobeam=nobeam, zoom_coord=zoom_coord, $
                        savepng=savepng, saveps=saveps, file_suffixe=file_suffixe, $
                        plot_histo=plot_histo
   

stop


end
