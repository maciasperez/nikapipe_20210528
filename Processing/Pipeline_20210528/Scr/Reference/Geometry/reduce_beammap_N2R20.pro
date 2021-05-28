;
;   Script for the production of the kidpar file 
;
;   September, 3rd, 2018, LP
;
;______________________________________________________________________


;;  PROCESSING PARAMETERS
;;____________________________________________________________________

;; acquisition version
;; attention : editer NIKA_Pipe/nk_scan2run.pro
;;!nika.acq_version = 'v2'


;; output dir
runname        = 'N2R20'   ; (run33)
output_dir     =  getenv('HOME')+'/NIKA/Plots/'+runname 
beam_maps_dir  =  output_dir+'/Beammaps'

ptg_numdet_ref = 3137;  824 ; !nika.ref_det[1]

;; scan to be analysed

;; URANUS
source = "Uranus"
scan_list = '20180905s34'



;; JUAN ANALYSIS
source = "Uranus"
scan_list = '20180906s42'
;;beam_maps_dir  =  '/home/macias/NIKA/Plots/N2R20/Beammaps'


scan_list = '20180906s105'


;; MARS
;;source = 'Mars'
;;-- get day-to-day flux expectations (useful for Mars only) 
;;fill_nika_struct, '27', /day
;scan_list = '20180122s82'


;; ACTIONS
;; 1) first analysis using simple decorrelation method
;; 2) [OPTION] apply the skydip coefficients
;; 3) second analysis using COMMON_MODE_ONE_BLOCK
;; 6) calculate the corr2cm coefficients


;; 1) first analysis using simple decorrelation method
do_first_iteration = 1

;; 2) [OPTION] apply the skydip coefficients
apply_skydip_coef  = 0
;; kidpar from which the C0, C1 coefficients will be copied if apply_skydip_coef = 1 
;;kidpar_skydip_file = !nika.off_proc_dir+"/kidpar_N2R9_baseline.fits"

;; 3) second analysis using COMMON_MODE_ONE_BLOCK
do_second_iteration = 1

;; 4) [OPTION] recalibration by hand calib = input_flux_th/input_flux_th_old
recalibration = 0
;;input_flux_th_old = [102.08, 33.68, 102.08] ;; Mars
;;input_flux_th_old = [39.49, 15.29, 39.49]  ;; Uranus

;; 5) [OPTION] remove the KIDs that do not match the designed grid (from FXD)
design_matching = 0
;; not-design-compliant KIDs list (mail FXD 8 Nov 2017)
;; offgrid_list = [3206, 4405] 

;; 6) calculate the corr2cm coefficients (correlation with the Common
;; Mode)
do_corr2cm     = 1
flat_field_dir = output_dir+"/Flat_fields"
;; input kidpar containing the corr2cm if already processed 
;; input_kidpar_corr2cm_file = !nika.off_proc_dir+"/kidpar_20171023s101_v2_LP_md_calUranus.fits"
input_kidpar_corr2cm_file = '' ;; corr2cm to be processed


suf = ''
;; if optionnal step number 4 done (recalibration) then suf='_recal'
;; if optionnal step number 5 done (match design)  then suf='_matchdesign'
;; suf = '_LP_skd13'


show_plot = 1

;
;
;    PROCESSING
;_________________________________________________________________________________________
;
nk_scan2run, scan_list[0]

case 1 of
   strupcase(source) eq "URANUS":  input_flux_th = !nika.flux_uranus
   strupcase(source) eq "NEPTUNE": input_flux_th = !nika.flux_neptune
   strupcase(source) eq "MARS":    input_flux_th = !nika.flux_mars
   else:  input_flux_th = [1.d0,1.d0,1.d0]
endcase
simu = 0

scanlist2nickname, scan_list, nickname


;; 1) first analysis using simple decorrelation method
;;-----------------------------------------------------
if do_first_iteration gt 0 then begin
   
prepare   = 1
beams     = 1
merge     = 1
select    = 1
finalize  = 1
iteration = 0

delvarx, input_kidpar_file

make_geometry_5, scan_list, input_flux_th, ptg_numdet_ref=ptg_numdet_ref, iteration=iteration, $
                 simu=simu, point_source=point_source, input_simu_map=input_simu_map, $
                 source=source, beam_maps_dir=beam_maps_dir, input_kidpar_file=input_kidpar_file, $
                 prepare=prepare, beams=beams, merge=merge, select=select, finalize=finalize, $
                 nickname=nickname

print, "First iteration done...."


if show_plot gt 0 then begin

   nk_get_kidpar_ref, scan_num, day, info, kidpar_ref_file, scan=scan_list[0]
   kidpar_file     = "kidpar_"+scan_list[0]+"_v0.fits"
   
   
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
   
   compare_kidpar_plot, [kidpar_ref_file, kidpar_file], nobeam=nobeam, zoom_coord=zoom_coord, $
                        savepng=savepng, saveps=saveps, file_suffixe=file_suffixe, $
                        plot_histo=plot_histo


   
endif
   
stop
endif


;; Apply skydip coeffs
;;-------------------------------------------------------------------
if apply_skydip_coef gt 0 then begin
   
kidpar_in_file     = "kidpar_"+nickname+"_v0.fits"
kidpar_out_file    = "kidpar_"+nickname+"_v0_skd.fits"
skydip_coeffs, kidpar_in_file, kidpar_skydip_file, kidpar_out_file

print, "Skydip coefficients added...."
stop
endif


;; 3) second analysis using COMMON_MODE_ONE_BLOCK
;;-------------------------------------------------------------------
if do_second_iteration gt 0 then begin

   print, ''
   print, "Let's start the second iteration"
   ;; add the input_kidpar_file below if skipping the first iteration
   
   if scan_list[0] eq '20171025s41' then input_kidpar_file = !nika.off_proc_dir+"/kidpar_20171025s41_v2_LP_md_recal_calUranus.fits" else begin
      if apply_skydip_coef lt 1 then input_kidpar_file =  "kidpar_"+nickname+"_v0.fits" else $
         input_kidpar_file =  "kidpar_"+nickname+"_v0_skd.fits"
   endelse
   
   print, "input_kidpar_file = ", input_kidpar_file

   no_opacity_correction = 0
   if apply_skydip_coef  lt 1 then no_opacity_correction = 1
   
   prepare   = 1
   beams     = 1
   merge     = 1
   select    = 1
   finalize  = 1
   iteration = 2

   decor_method  = "COMMON_MODE_ONE_BLOCK"
   ;;decor_method  = "COMMON_MODE_KIDS_OUT"
   aperture_phot = 0
      
   make_geometry_5, scan_list, input_flux_th, ptg_numdet_ref=ptg_numdet_ref, iteration=iteration, $
                    simu=simu, point_source=point_source, input_simu_map=input_simu_map, $
                    source=source, beam_maps_dir=beam_maps_dir, input_kidpar_file=input_kidpar_file, $
                    prepare=prepare, beams=beams, merge=merge, select=select, finalize=finalize, $
                    decor_method=decor_method, no_opacity_correction=no_opacity_correction
   
   print, "second iteration done...."
   
   if show_plot gt 0 then begin
      
      nk_get_kidpar_ref, scan_num, day, info, kidpar_ref_file, scan=scan_list[0]
      kidpar_file     = "kidpar_"+scan_list[0]+"_v2.fits"
      
      
      ;; set to 1 to plot the kid offsets only (no ellipses)
      nobeam = 0
      ;; set to some nasmyth offset coordinates to zoom in 
      zoom_coord = [1,1]
      zoom_coord = 0
      ;; plot histograms (for fwhm and ellipticity)
      plot_histo = 1
      ;; save the plots
      savepng = 1
      saveps  = 0
      file_suffixe = 0
      
      compare_kidpar_plot, [kidpar_ref_file, kidpar_file], nobeam=nobeam, zoom_coord=zoom_coord, $
                           savepng=savepng, saveps=saveps, file_suffixe=file_suffixe, $
                           plot_histo=plot_histo
      
   endif
   
   
   stop
endif


;;==========================================================================
;;
;;   OPTIONAL ANALYSIS STEPS
;;
;;==========================================================================
;; apply the design matching selection from FXD
;;--------------------------------------------------------------------
if design_matching gt 0 then begin

   ;; KI001 KL000
   ;; 3206  4405

   suf = '_matchdesign'
   kidpar_in_file     = "kidpar_"+nickname+"_v2.fits"
   kidpar_out_file    = "kidpar_"+nickname+"_v2"+suf+".fits"


   ; Test FXD
   ;; kidpar_in_file     = 'kidpar_20180117s92_v2_LP_skd14_calUranus8.fits'
   ;; kidpar_out_file     = 'kidpar_20180117s92_v2_LP_skd14_calUranus8test.fits'
   ;;   !nika.plot_dir   ; Local non-svn directory
   ;; dirin = !nika.off_proc_dir
   ;; dirout = !nika.plot_dir
   ;; kidparin = kidpar_in_file
   ;; kidparout = kidpar_out_file
; Test line by line focal_plane_match
; or now can test the whole thing
;   fill_nika_struct, !nika.run
;;   focal_plane_match, !nika.off_proc_dir, kidpar_in_file, $
;;                      !nika.plot_dir, kidpar_out_file, plotname = 'N2R14Test'
   ;;kidpar_in_file     = !nika.off_proc_dir+"/kidpar_20171025s41_v2_LP_calUranus_RecalNP.fits"
   ;;kidpar_out_file    = !nika.off_proc_dir+"/kidpar_20171025s41_v2_LP_calUranus_RecalNP_md.fits"

; FXD: I propose to use the routine  (in the same directory)
                                ; focal_plane_match that does
                                ; everything instead
   ;; noff = n_elements(offgrid_list)
   ;; if noff gt 0 then begin
   ;;    kp =  mrdfits( kidpar_in_file, 1)
   ;;    for ik = 0, noff-1 do begin
   ;;       w = where(kp.numdet eq offgrid_list[ik], nn)
   ;;       if nn gt 0 then begin
   ;;          kp[w].type = 10
   ;;          print, "Type of KID ",offgrid_list[ik], " set to 10"
   ;;       endif
   ;;    endfor

   ;;    nk_write_kidpar, kp, kidpar_out_file
      
   ;; endif else print, "Empty offgrid_list"
   fill_nika_struct, !nika.run
   focal_plane_match, !nika.off_proc_dir, kidpar_in_file, $
                      !nika.off_proc_dir, kidpar_out_file

endif


;; if needed, recalibration 
;;-------------------------------------------------------------------
if recalibration gt 0 then begin

   input_kidpar_file =  "kidpar_"+nickname+"_v2"+suf+".fits"
     
   print, "============================================="
   print, 'Recalibration'
   print, "============================================"
   print, ''
   print, 'Reading ', input_kidpar_file
   kidpar = mrdfits( input_kidpar_file, 1, /silent)
   w1 = where( (kidpar.array eq 1 or kidpar.array eq 3),nw1)
   kidpar[w1].calib          *= input_flux_th[0]/input_flux_th_old[0]
   kidpar[w1].calib_fix_fwhm *= input_flux_th[0]/input_flux_th_old[0]
   
   w1 = where( kidpar.array eq 2 ,nw2)
   kidpar[w1].calib          *= input_flux_th[1]/input_flux_th_old[1]
   kidpar[w1].calib_fix_fwhm *= input_flux_th[1]/input_flux_th_old[1]

   suf = suf+'_recal'
   print, 'Writing recalibrated kidpar in ', "kidpar_"+nickname+"_v2"+suf+".fits"
   nk_write_kidpar, kidpar, "kidpar_"+nickname+"_v2"+suf+".fits"
   
endif


  
;;kp_1mm    = mrdfits( "kidpar_"+nickname+"_v2"+suf+".fits", 1)
;;kp_2mm    = mrdfits( !nika.off_proc_dir+"/kidpar_N2R12_baseline.fits", 1)
;;w2 = where( kp_2mm.array eq 2 and  kp_2mm.type eq 1, nw2)




;; calculate corr2cm coefficients
;;-------------------------------------------------------------------
if do_corr2cm gt 0 then begin

   print, ''
   print, "Let's start the flat field processing...."
   
   if input_kidpar_corr2cm_file eq '' then begin
      input_kidpar_corr2cm_file = "kidpar_"+nickname+"_v2"+suf+".fits"
      do_process = 1
   endif else do_process = 0
   
   print, 'input_kidpar_corr2cm_file = ', input_kidpar_corr2cm_file
   
   output_dir            = flat_field_dir
   process               = do_process
   decor_cm_rmin         = 60.
   use_tau225            = 0
   mooncut_a1            = 0 ;; for the plot only
   saveplot              = 1
   no_opacity_correction = 0
   if apply_skydip_coef  lt 1 then no_opacity_correction = 1

   output_kidpar_file    = "kidpar_"+nickname+"_v2"+suf+"_corr2cm.fits"
   
   ;get_flatfields_pro, scan_list[0], input_kidpar_corr2cm_file, output_kidpar_file, output_dir=output_dir, $
   ;                    process=process, $
   ;                    decor_cm_rmin=decor_cm_rmin, $
   ;                    use_tau225=use_tau225, mooncut_a1 = mooncut_a1, saveplot=saveplot, $
   ;                    no_opacity_correction=no_opacity_correction


   stop
   
   file_save = flat_field_dir+'/v_1/'+scan_list[0]+'/results.save'
   restore, file_save, /v

   kp = kidpar1
   
   ;; Main Beam Flat Field (using kp.calib_fix_fwhm)
   ;;--------------------------------------------------------------
   plot_flatfields, '', 'mbff', info1.result_elevation_deg, info1.tau225, use_tau225=use_tau225, $
                    no_opacorr=no_opacity_correction, $
                    saveplot=saveplot, kidpar=kp, mooncut_a1 = mooncut_a1, $
                    normalization=normalised, png_nickname=scan_list[0], project_dir=flat_field_dir
   
   ;; Forward Beam Flat Field (using kp.corr2cm)
   ;;--------------------------------------------------------------
   plot_flatfields, '', 'fbff', info1.result_elevation_deg, info1.tau225, $
                    saveplot=saveplot, kidpar=kp, mooncut_a1 = mooncut_a1,$
                    normalization=normalised, png_nickname=scan_list[0], project_dir=flat_field_dir

   use_tau225 = 1
   no_opacity_correction = 0
   plot_flatfields, '', 'gain', info1.result_elevation_deg, info1.tau225, use_tau225=use_tau225, $
                    no_opacorr=no_opacity_correction, $
                    saveplot=saveplot, kidpar=kp, mooncut_a1 = mooncut_a1, normalization=normalised, $
                    png_nickname=scan_list[0], project_dir=flat_field_dir

   
   plot_flatfields, '', 'noise', info1.result_elevation_deg, info1.tau225, use_tau225=use_tau225, $
                    no_opacorr=no_opacity_correction, $
                    saveplot=saveplot, kidpar=kp, mooncut_a1 = mooncut_a1, normalization=normalised, $
                    png_nickname=scan_list[0], project_dir=flat_field_dir
   
endif





   
end
