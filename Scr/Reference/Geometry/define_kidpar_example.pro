;;
;;
;;    Beam map scan analysis and Kidpar file production
;;
;;=====================================================================

;scan_list      = '20170125s243'
scan_list      = '20170125s223'
scan_list      = '20170419s133'
scan_list      = '20170424s123'
scan_list      = '20170421s160'
scan_list      = '20170420s113'
scan_list      = '20170425s52'
scan_list      = '20170608s130'
ptg_numdet_ref =  823

source         =  'Neptune'
nk_scan2run, scan_list[0]
input_flux_th  = !nika.flux_neptune
;input_flux_th  = [115.1, 40.4, 115.1] ; placeholder for Mars

source         =  'Uranus'
nk_scan2run, scan_list[0]
input_flux_th  = !nika.flux_uranus


;; define a directory for the analysis outputs
beam_maps_dir = "$HOME/NIKA/Plots/Run23/beammaps_calib"
beam_maps_dir = "$HOME/NIKA/Plots/Run24/Beammaps"

;; [option]
;; define a skydip file nickname to be used to get the C0, C1
skydip_id = '20170124s189'
skydip_id = '20170221s48'
;;nk_rta, skydip_id


prepare   = 1
beams     = 1
merge     = 1
select    = 1
finalize  = 1
iteration = 1
reso      = 4.
if iteration eq 1 then begin
   delvarx, input_kidpar_file
endif else begin
   if scan_list[0] eq '20170125s223' then input_kidpar_file = "kidpar_20170125s223_v0_withskydip.fits"
   if scan_list[0] eq '20170125s223' then input_kidpar_file = "kidpar_20170125s223_v0_withskydip_"+skydip_id+".fits"
   if scan_list[0] eq '20170125s243' then input_kidpar_file = "kidpar_20170125s243_v0_withskydip_"+skydip_id+".fits"
   if scan_list[0] eq '20170414s195' then input_kidpar_file = "kidpar_20170414s195_v0_withskydip.fits"
   if scan_list[0] eq '20170424s123' then input_kidpar_file = "kidpar_20170424s123_v0_withskydip.fits"
   if scan_list[0] eq '20170421s160' then input_kidpar_file = "kidpar_20170421s160_v0_withskydip.fits"
   if scan_list[0] eq '20170420s113' then input_kidpar_file = "kidpar_20170420s113_v0_JFMP_calib.fits"
endelse


;; make_geometry_5, scan_list, input_flux_th, ptg_numdet_ref=ptg_numdet_ref, iteration=iteration, $
;;                  decor_method='common_mode_one_block', reso=reso, $
;;                  source=source, beam_maps_dir=beam_maps_dir, input_kidpar_file=input_kidpar_file, $
;;                  prepare=prepare, beams=beams, merge=merge, select=select, finalize=finalize

make_geometry_5, scan_list, input_flux_th, ptg_numdet_ref=ptg_numdet_ref, iteration=iteration, $
                 reso=reso, $
                 source=source, beam_maps_dir=beam_maps_dir, input_kidpar_file=input_kidpar_file, $
                 prepare=prepare, beams=beams, merge=merge, select=select, finalize=finalize


stop

if iteration eq 1 then begin
   
   ;; Compare to the previous reference kidpar
   ;;-----------------------------------------------------------------------------
   kidpar_ref_file = !nika.off_proc_dir+"/kidpar_20161010s37_v3_skd8_match_calib_NP_recal_FR.fits"
   kidpar_ref_file = !nika.off_proc_dir+"/kidpar_20170125s223_v2_sk_20170124s189.fits"
   kidpar_ref_file = !nika.off_proc_dir+"/kidpar_best3files_FXDC0C1_GaussPhot.fits"
   kidpar_ref_file = !nika.off_proc_dir+"/kidpar_n2r10_calib.fits"
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
   
   
   kidpar_ref = mrdfits( kidpar_ref_file, 1)
   kidpar     = mrdfits( kidpar_file, 1)


   ;; FLag out outlyers
   ;; uncomment below if the previous reference kidpar is robust
   ;; enought
   ;;-----------------------------------------------------------------------------
   ;; w1ref = where( kidpar_ref.type eq 1, nw1ref)
   ;; w1    = where( kidpar.type eq 1, nw1)
   ;; kidpar = kidpar[w1]
   ;; kidpar_ref = kidpar_ref[w1ref]
   ;; my_match, kidpar_ref.numdet, kidpar.numdet, suba, subb
   ;; kidpar_ref = kidpar_ref[suba]
   ;; kidpar     = kidpar[subb]
   ;; kid_dist = sqrt( (kidpar_ref.nas_x-kidpar.nas_x)^2 + $
   ;;                 (kidpar_ref.nas_y-kidpar.nas_y)^2)
   ;;wind, 1, 1, /free
   ;;plot, kid_dist 
   ;; flagging
   ;;w = where( kid_dist gt 3, nw)
   ;;if nw ne 0 then kidpar[w].type = 4

   
   ;; Add skydip coeffs
   ;;---------------------------------------------------------------------------

   ;; 1/ using co, c1 from a recent skydip

   ;; kidpar_c0c1_file = "kidpar_"+skydip_id+".fits"
   
   ;; if file_test(kidpar_c0c1_file) eq 0 then begin
   ;;    print, ''
   ;;    ;; print, "Reducing the skydip scan: ", skydip_id
   ;;    ;; nk_default_param, param
   ;;    ;; nk_default_info, info
   ;;    ;; scan2daynum, skydip_id, day, scan_num
   ;;    ;; param.plot_dir = !nika.plot_dir+"/Logbook/Scans/"+skydip_id
   ;;    ;; in_kidpar_file = kidpar_ref_file
   ;;    ;; nk_skydip_5, scan_num, day, param, info, kidpar, data, dred,
   ;;    ;; input_kidpar_file = in_kidpar_file, raw_acq_dir=raw_acq_dir

   ;;    restore, !nika.plot_dir+'/Run22/'+skydip_id+'/results.save', /v

   ;;    print, ''
   ;;    print, "writing the kidpar file with C0, C1 estimates: ",  kidpar_c0c1_file
   ;;    nk_write_kidpar, kidpar,  kidpar_c0c1_file
   ;; endif
     
   ;; kidpar1 = mrdfits(kidpar_c0c1_file, 1)
   ;; w1sk    = where( kidpar1.type eq 1, nw1ref)
   ;; w1      = where( kidpar.type eq 1, nw1)
   ;; kidpar = kidpar[w1]
   ;; kidpar1 = kidpar1[w1sk]
   ;; my_match, kidpar1.numdet, kidpar.numdet, suba, subb
   ;; kidpar.c0_skydip = 0.d0
   ;; kidpar.c1_skydip = 0.d0
   ;; kidpar[subb].c0_skydip = kidpar1[suba].c0_skydip
   ;; kidpar[subb].c1_skydip = kidpar1[suba].c1_skydip

   ;; kidpar_withskydip_file = "kidpar_"+scan_list[0]+"_v0_withskydip_"+skydip_id+".fits"

   
   ;; 2/ using former C0, C1 coeff
   
   w1ref = where( kidpar_ref.type eq 1, nw1ref)
   w1    = where( kidpar.type eq 1, nw1)
   kidpar = kidpar[w1]
   kidpar_ref = kidpar_ref[w1ref]
   my_match, kidpar_ref.numdet, kidpar.numdet, suba, subb
   kidpar.c0_skydip = 0.d0
   kidpar.c1_skydip = 0.d0
   kidpar[subb].c0_skydip = kidpar_ref[suba].c0_skydip
   kidpar[subb].c1_skydip = kidpar_ref[suba].c1_skydip
   kidpar_withskydip_file = "kidpar_"+scan_list[0]+"_v0_withskydip.fits"
   
   print, ''
   print, "Ready do write: ", kidpar_withskydip_file
   print, "Shall I proceed ? (y/n)"
   ans = ''
   read, ans
   if strupcase(ans) eq 'Y' then nk_write_kidpar, kidpar, kidpar_withskydip_file 

   stop
   
;; all done for iteration 1
;;______________________________________________________________________
endif else begin


;; comparison to v0 kidpar
   
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
   
   
   compare_kidpar_plot, ["kidpar_"+scan_list[0]+"_v0.fits", "kidpar_"+scan_list[0]+"_v2.fits"], $
                        nobeam=nobeam, zoom_coord=zoom_coord, $
                        savepng=savepng, saveps=saveps, file_suffixe=file_suffixe, $
                        plot_histo=plot_histo

   
;;______________________________________________________________________
;;   
;; Calibration and flat fields
;;
   
   ;; comparing calib_fix_fwhm and calib
   kidpar = mrdfits( "kidpar_"+scan_list[0]+"_v2.fits", 1)


   ;; debug
   ;;-----------------------------
   ;; restore, beam_maps_dir+'/Maps_kids_out/kid_maps_20170125s223_0.save', /v
   ;; kidpar = mrdfits( "kidpar_"+scan_list[0]+"_v2.fits", 1)
   ;; lambda = 1
   ;; flux = input_flux_th[lambda-1]
   ;; nk_list_kids, kidpar, lambda=lambda, on=w1, non=nw1
   ;; calib          = flux * exp(-kidpar[w1].tau_skydip/sin(el_avg_rad))/kidpar[w1].a_peak ; Jy/Hz
   ;; calib_fix_fwhm = flux * exp(-kidpar[w1].tau_skydip/sin(el_avg_rad))/kidpar[w1].flux
   ;; kidpar[w1].calib          = calib
   ;; kidpar[w1].calib_fix_fwhm = calib_fix_fwhm
   ;; nk_write_kidpar, kidpar, "kidpar_"+scan_list[0]+"_v2.fits"
   ;;
   
   w1 = where( kidpar.type eq 1, nw1)
 
   wind, 1, 1, /free, /large
   !p.multi=[0,1,3]
   for iarray=1, 3 do begin
      w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
      plot,  kidpar[w1].calib_fix_fwhm/median(kidpar[w1].calib_fix_fwhm), /xs, /nodata, ytitle="normalised calib coef A"+strtrim(string(iarray), 2), charsize=2
      oplot,  kidpar[w1].calib_fix_fwhm/median(kidpar[w1].calib_fix_fwhm), col=70
      oplot, kidpar[w1].calib/median(kidpar[w1].calib), col=250
      if iarray eq 1 then legendastro, ['calib_fix_fwhm', 'calib'], line=0, col=[70, 250], box=0, /trad
   endfor
   !p.multi=0
   ;;png = +'/home/perotto/NIKA/Plots/Run20/calib_to_calib_fix_fwhm_'+strtrim(scan,2)+'.png'
   ;;WRITE_PNG, png, TVRD(/TRUE)

   
   ;; calculate corr2cm and plot the flats
   print, ''
   print, "Ready for the Flat Field estimates"
   print, "Shall I proceed ? (y/n)"
   ans = ''
   read, ans
   if strupcase(ans) eq 'Y' then begin
      project_dir    = !nika.plot_dir+"/Flats"
      ;;project_dir    = "/home/perotto/NIKA/Plots/Run20/Flats"
      process        = 0
      decor_cm_dmin  = 70.       ; set to a large value for planets (bright sources)
      use_tau225     = 0
      mooncut_a1     = 1
      
      get_flatfields_pro, scan_list[0], "kidpar_"+scan_list[0]+"_v2.fits", output_dir = project_dir, $
                          process=process, decor_cm_rmin = decor_cm_dmin, use_tau225=use_tau225, $
                          mooncut_a1=mooncut_a1
   endif
   
   print, ''
   print, "Ready for plotting NEP"
   print, "Shall I proceed ? (y/n)"
   ans = ''
   read, ans
   if strupcase(ans) eq 'Y' then begin
      use_tau225     = 0
      el_avg_deg     = 0
      no_opacorr     = 0
      mooncut_a1     = 1
      
      plot_flatfields, "kidpar_"+scan_list[0]+"_v2.fits", 'noise', el_avg_deg, tau225, $
                       use_tau225=use_tau225, no_opacorr=no_opacorr, $
                       saveplot=saveplot, mooncut_a1=mooncut_a1
   endif

   
endelse


stop


end
