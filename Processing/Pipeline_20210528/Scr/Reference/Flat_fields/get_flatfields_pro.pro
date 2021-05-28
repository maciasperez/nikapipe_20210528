;+
;
;
;  Routine adapted from the reference script get_flatfields.pro 
;
;  LP, Feb. 16, 2017
;
;
;-


;; Example of inputs here
;;----------------------------------------------------------------------------
;;scan          = '20170125s223'
;;kidpar_file   = !nika.off_proc_dir+'/kidpar_20170125s223_v2_sk_20170124s189.fits'
;; NB: one can use: nk_get_kidpar_ref, 268, '20161212', info, kidpar_file

pro get_flatfields_pro, scan, kidpar_file, output_kidpar_file, output_dir=output_dir, process=process, $
                        decor_cm_rmin=decor_cm_rmin, $
                        use_tau225=use_tau225, mooncut_a1 = mooncut_a1, saveplot=saveplot, $
                        no_opacity_correction=no_opacity_correction


project_dir =  !nika.plot_dir+"/Flat_fields"
if keyword_set(output_dir) then project_dir = output_dir
if keyword_set(process) then process = 1 else process = 0
decor_cm_dmin = 60.             ; set to a large value for planets (bright sources)
if keyword_set(decor_cm_rmin) then decor_cm_dmin = decor_cm_rmin


;; plotting options
;;----------------------------------------------------------------------------
;; whether to show the flat normalised 
normalised = 1
;; whether to cut the left side of A1
if keyword_set(mooncut_a1) then mooncut_a1 = 1 else mooncut_a1 = 0


;; set to 1 for saving the FF plot in png files
if keyword_set(saveplot) then saveplot = 1 else saveplot=0

;; opacity correction
use_tau_skydip = 1
if keyword_set(use_tau225) then begin
   use_tau225 = 1
   use_tau_skydip = 0
endif else use_tau225 = 0 
no_correction      = 0
opacity_correction = 1
if keyword_set(no_opacity_correction) then begin
   no_correction      = 0
   opacity_correction = 0
endif

;; default plots are 1) MBFF (calib_fix_fwhm), 2) FBFF (corr2cm), 3) MBFF/FBFF ratio
;; set the option below for plotting other quantities
plot_calib_fix_fwhm = 0  ;; in (Hz/beam)/Jy
plot_calib          = 0  ;; in Hz/Jy
plot_apeak          = 0  ;; in Hz



;;=========================================================================
;; can be launched without further edition
;;
;;=========================================================================
if process gt 0 then begin
   nk_default_param, param
   param.force_kidpar = 1
   param.file_kidpar = kidpar_file
   param.decor_cm_dmin = decor_cm_dmin
   param.interpol_common_mode = 1
   param.decor_per_subscan = 0
   param.decor_elevation = 0
   param.median_common_mode_per_block = 0  ;; kids cross-calibration with the median CM of all kids
   param.do_plot=0
   param.output_noise = 1
   param.do_opacity_correction = opacity_correction
   param.flag_ovlap=1
   param.flag_sat=0
   
   param.plot_dir = !nika.plot_dir
   param.project_dir = project_dir
   
   nk, scan, param=param, grid=grid, info=info, kidpar=kidpar
endif



;;
;;     update the input kidpar
;;
;;_________________________________________
file_save = project_dir+'/v_1/'+scan+'/results.save'
restore, file_save, /v
kidpar_corr2cm = kidpar1

kidpar_in = mrdfits(kidpar_file, 1)

corr2cm_coeffs, kidpar_in, kidpar_corr2cm, kidpar_out

nk_write_kidpar, kidpar_out, output_kidpar_file


;;
;;     plots
;;
;;_________________________________________
kp = kidpar_out


;; Main Beam Flat Field (using kp.calib_fix_fwhm)
;;--------------------------------------------------------------
plot_flatfields, '', 'mbff', info1.result_elevation_deg, info1.tau225, use_tau225=use_tau225, $
                 no_opacorr=no_correction, $
                 saveplot=saveplot, kidpar=kp, mooncut_a1 = mooncut_a1, $
                 normalization=normalised, png_nickname=scan, project_dir=project_dir  

;; Forward Beam Flat Field (using kp.corr2cm)
;;--------------------------------------------------------------
plot_flatfields, '', 'fbff', info1.result_elevation_deg, info1.tau225, $
                 saveplot=saveplot, kidpar=kp, mooncut_a1 = mooncut_a1,$
                 normalization=normalised, png_nickname=scan, project_dir=project_dir     


;; Main Beam over Forward Beam flat field ratio
;;--------------------------------------------------------------
if use_tau225 gt 0 then begin
   tau225 = info1.tau225
   ;; simple nu2
   tau1mm = tau225 * (250./225.)*(250./225.)
   tau2mm = tau225 * (160./225.)*(160./225.)
   ;; fit from :
   ;; atm_model_mdp, atm_tau1, atm_tau2, atm_tau3, atm_tau_225, nostop=1, /tau225
   tau1mm = tau225 * 1.28210
   tau2mm = tau225 * 0.697936
   
   mytau = [tau1mm, tau1mm, tau2mm]
endif
if no_correction gt 0 then mytau = dblarr(3)

array_tab = [1, 3, 2]

!p.multi=[0, 3, 1]
window, 2,  xsize = 1200, ysize =  400
for ilam=0, 2 do begin
   iarray = array_tab[ilam]
   w1 = where(kp.type eq 1 and kp.array eq iarray, n1)
   nas_x = kp(w1).nas_x
   nas_y = kp(w1).nas_y
   corr2cm = kp(w1).corr2cm
   calib   = kp(w1).calib_fix_fwhm

   if (use_tau225 gt 0 or no_correction gt 0) then begin
      print,"tau_skydip = ", mean(kp[w1].tau_skydip)
      el_avg_rad = info1.result_elevation_deg*!dtor
      tau = mytau[ilam]
      opacor = exp((kp[w1].tau_skydip-tau)/sin(el_avg_rad))
      calib  = calib*opacor         ;*10.
   endif

   ratio   = calib/corr2cm
   
   if mooncut_a1 gt 0. then begin
      if iarray eq 1 then begin
         angle = 13.*!dtor
         rot_x = nas_x*cos(angle) + nas_y*sin(angle)
         rot_y = -1*nas_x*sin(angle) + cos(angle)*nas_y
         
         wmoon = where(((rot_x-100.)^2 + rot_y^2) lt 3d4, nmoon)
         
         nas_x =  rot_x(wmoon)*cos(angle) - rot_y(wmoon)*sin(angle)
         nas_y = rot_x(wmoon)*sin(angle) + cos(angle)*rot_y(wmoon)
         ratio = ratio(wmoon)
         
      endif
   endif
   
   zra=0
   myformat='(f8.4)'
   if (normalised gt 0.) then begin
      med = median(ratio)
      ratio = ratio/med 
      zra = [0.7, 1.3]
      myformat='(f8.2)'
   endif
   
   
   ;; plot
   xra = [-220, 220]
   yra = [-220, 220]
   matrix_plot, nas_x, nas_y, ratio, xtitle='Nasmyth offset x', ytitle='Nasmyth offset y',title = 'Flat field ratio of array '+strtrim(iarray, 2), xr = xra, yr=yra, /iso, format=myformat, charsize=1., position=[0.1/3. +0.33*(ilam), 0.1, 0.33*(ilam+1) -0.1/3., 0.9 ], zra=zra ;, units="calib_fix_fwhm/corr2cm"
                                ;oplot, nas_x, nas_y, col=0, psym=8, symsize=0.2
   
endfor

if keyword_set(saveplot) then begin
   png = project_dir+'/fov_map_ratio_mbtofb_'+strtrim(scan,2)+'.png'
   WRITE_PNG, png, TVRD(/TRUE)
endif

!p.multi=0


;; other FoV plots
;;--------------------------------------------------------------

if plot_calib_fix_fwhm gt 0 then begin
   plot_flatfields, '', 'gain', info1.result_elevation_deg, info1.tau225, use_tau225=use_tau225, $
                    no_opacorr=no_correction, $
                    saveplot=saveplot, kidpar=kp, mooncut_a1 = mooncut_a1, normalization=normalised, $
                    png_nickname=scan
   
endif

if plot_calib gt 0 then begin
   plot_flatfields, '', 'gain_peak', info1.result_elevation_deg, info1.tau225, use_tau225=use_tau225, $
                    no_opacorr=no_correction, $
                    saveplot=saveplot, kidpar=kp, mooncut_a1 = mooncut_a1, normalization=normalised, $
                    png_nickname=scan  
endif

if plot_apeak gt 0 then begin
   plot_flatfields, '', 'apeak', info1.result_elevation_deg, info1.tau225, use_tau225=use_tau225, $
                    no_opacorr=no_correction, $
                    saveplot=saveplot, kidpar=kp, mooncut_a1 = mooncut_a1, normalization=normalised, $
                    png_nickname=scan      
endif



  
end
