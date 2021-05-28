;;
;;   LAUNCHER SCRIPT FOR A SERIES OF CALIBRATIONS
;;
;;   AIM: THE COMPARISON OF CALIBRATION METHODS
;;
;;   LP, April 2018
;;_________________________________________________




do_opacity_correction        = 0
do_absolute_calibration      = 1
do_crosscheck_on_secondaries = 1


n2r9_opacity_selection  = 'baseline'
n2r12_opacity_selection = 'atmlike'
n2r14_opacity_sele
ction = 'atmlike'



;; N2R9
;;_________________________________________________

runname = 'N2R9'
input_kidpar_file = !nika.off_proc_dir+'/kidpar_best3files_FXDC0C1_GaussPhot_NewConv.fits'

;; 1/ OPACITY CORRECTION

if do_opacity_correction gt 0 then begin
   
;; first iteration without any scan selection
   do_first_iteration  = 0  
;; NB: equivalent to '_1803'
   
   do_skydip_selection = 0
   do_second_iteration = 1
   
   show_plot = 1
   check_after_selection  = 1 ;; launch again the selection code after the second iteration
   
;; Baseline
   baseline = 4  ;; 1: no tau3 cut; 2:tau3<0.9; 3:tau3<0.8; 4: high-tau2-v3
   atmlike  = 0
   hightau2 = 0
   
   
   png=1
   
   reduce_skydips_reference, runname, input_kidpar_file, $
                             hightau2=hightau2, atmlike=atmlike, $
                             baseline=baseline, $
                             showplot=show_plot, png=png, $
                             do_first_iteration=do_first_iteration, $
                             do_skydip_selection=do_skydip_selection, $
                             do_second_iteration=do_second_iteration, $
                             check_after_selection=check_after_selection, $
                             reiterate=reiterate
   
   
   
;; test
   dir = '/mnt/data/NIKA2Team/perotto/Plots/N2R9/Opacity/'
   skdout_hightau  = dir+'all_skydip_fit_N2R9_ref_hightau2_v3.save'
   skdout_atmlike  = dir+'all_skydip_fit_N2R9_ref_atmlike.save'
   skdout_baseline = dir+'all_skydip_fit_N2R9_ref_baseline.save'
   skdout_baseline2 = dir+'all_skydip_fit_N2R9_ref_baseline_v2.save'
   skdout_baseline3 = dir+'all_skydip_fit_N2R9_ref_baseline_v3.save'
   skdout_baseline4 = dir+'all_skydip_fit_N2R9_ref_baseline_v4.save'
   skdout_hightaulight = dir+'all_skydip_fit_N2R9_ref_hightau2_bis_v3.save'
   
   restore, skdout_atmlike
   skd_atmlike = skdout
   index = indgen(n_elements(skd_atmlike.scanname))
   restore, skdout_hightau
   skd_hightau = skdout
   my_match,skd_hightau.scanname,skd_atmlike.scanname, suba, subb
   index_hightau = index(subb)
   restore, skdout_baseline
   skd_baseline = skdout
   my_match,skd_baseline.scanname,skd_atmlike.scanname, suba, subb
   index_baseline = index(subb)
   
   restore, skdout_baseline2
   skd_baseline2 = skdout
   my_match,skd_baseline2.scanname,skd_atmlike.scanname, suba, subb
   index_baseline2 = index(subb)
   
   restore, skdout_baseline3
   skd_baseline3 = skdout
   my_match,skd_baseline3.scanname,skd_atmlike.scanname, suba, subb
   index_baseline3 = index(subb)
   
   restore, skdout_baseline4
   skd_baseline4 = skdout
   my_match,skd_baseline4.scanname,skd_atmlike.scanname, suba, subb
   index_baseline4 = index(subb)
   
   restore, skdout_hightaulight
   skd_hightaulight = skdout
   my_match,skd_hightaulight.scanname,skd_atmlike.scanname, suba, subb
   index_hightaulight = index(subb)
   
   window, 0
;;outplot, file=dir+'/skydip_tau3_comparison_ref', png=png, ps=ps
   plot, index, skd_atmlike.taufinal3, psym=8, yr=[0.05, 1.2], /ys, $
         ytitle='skydip tau3', xtitle='skydip scan index'
   oplot, index_hightau, skd_hightau.taufinal3, psym=4, col=250, thick=2
   oplot, index_baseline, skd_baseline.taufinal3, psym=8, col=80
   oplot, index_baseline2, skd_baseline2.taufinal3, psym=4, col=150, thick=2
   oplot, index_baseline3, skd_baseline3.taufinal3, psym=1, col=200, thick=2
   oplot, index_baseline4, skd_baseline4.taufinal3, psym=8, col=190, thick=2
;;oplot, index_hightaulight, skd_hightaulight.taufinal3, psym=1,col=200, thick=2
   legendastro, ['ATM-like', 'high-tau2', 'baseline v1', 'baseline v2'], col=[0, 250, 80, 150],$
                textcol=[0, 250, 80, 150], psym=[8, 8, 8, 4], box=0, /right
   
   
   window, 1
   plot, index, skd_atmlike.taufinal1, psym=8, yr=[0.05, 1.3], /ys, ytitle='tau1'
   oplot, index_hightau, skd_hightau.taufinal1, psym=8, col=250
   oplot, index_baseline, skd_baseline.taufinal1, psym=8, col=80
   oplot, index_baseline2, skd_baseline2.taufinal1, psym=4, col=150
   oplot, index_hightaulight, skd_hightaulight.taufinal1, psym=1,col=200, thick=2

   window, 2
   plot, index, skd_atmlike.taufinal2, psym=8, yr=[0.05, 1.3], /ys, ytitle='tau2'
   oplot, index_hightau, skd_hightau.taufinal2, psym=8, col=250
   oplot, index_baseline, skd_baseline.taufinal2, psym=8, col=80
   oplot, index_baseline2, skd_baseline2.taufinal2, psym=4, col=150
   oplot, index_hightaulight, skd_hightaulight.taufinal2, psym=1,col=200, thick=2
   
   window, 3
   my_match,skd_baseline.scanname,skd_baseline2.scanname, suba, subb
   plot, skd_baseline.taufinal3(suba)/skd_baseline.taufinal1(suba), psym=8, yr=[0.9, 1.2],$
         /ys, ytitle='tau3/tau1'
   oplot, skd_baseline2.taufinal3(subb)/skd_baseline2.taufinal1(subb), psym=8, col=250
   
   output_dir = '/mnt/data/NIKA2Team/perotto/Plots/N2R9/Opacity/'
   kpnew = mrdfits(output_dir+'/kidpar_C0C1_N2R9_ref_baseline_v2.fits', 1)
   kpref = mrdfits(output_dir+'/kidpar_C0C1_N2R9_ref_baseline.fits', 1)
   
   stop
endif

;; 2/ ABSOLUTE CALIBRATION

if do_absolute_calibration gt 0 then begin
   
;; copy param
   runname = 'N2R9'
   input_kidpar_file = !nika.off_proc_dir+'/kidpar_best3files_FXDC0C1_GaussPhot_NewConv.fits'
   
   atmlike  = 0
   hightau2 = 0
   baseline = 0
   
   showplot = 1
   png=1
   
   version_name = '_ref'
   if atmlike gt 0 then  version_name = version_name+'_atmlike'
;;if hightau2 gt 0 then version_name = version_name+'_hightau2_v3'
   if hightau2 gt 0 then version_name = version_name+'_hightau2_bis_v2'
   if baseline gt 0 then version_name = version_name+'_baseline'
   
   geom_kidpar_file   = input_kidpar_file
   skydip_kidpar_file = getenv('HOME')+'/NIKA/Plots/'+runname+'/Opacity/kidpar_C0C1_'+runname+version_name+'.fits'
   input_kidpar_file  = getenv('HOME')+'/NIKA/Plots/'+runname+'/Photometry/kidpar_calib_'+runname+version_name+'.fits'
   if file_test(input_kidpar_file) lt 1 then skydip_coeffs, geom_kidpar_file, skydip_kidpar_file, input_kidpar_file
   
   print, "geom_kidpar_file: ",   geom_kidpar_file
   print, "skydip_kidpar_file: ", skydip_kidpar_file
   print, "input_kidpar_file: ",  input_kidpar_file
   
;rep = ''
;read, rep
;print, 'on y va ?'
   
;; photometric correction
   var1_photocorr = 1
   var2_photocorr = 0
   
;; accounting for the apparent size of Uranus
   fwhm_base = [11.2, 17.4, 11.2]
   angdiam   = 4.0              ; 3.3 - 4.1
   fwhm_disc = sqrt(fwhm_base^2 + alog(2.0d0)/2.0d0*angdiam^2 )
   
   fix_photocorr  = fwhm_disc
   fix_photocorr  = 0
   
;; use hybrid opacity after the scans were reduced
   hybrid_opacity_after_reduction = 0
   
   
   calibration_uranus_reference, runname, input_kidpar_file, $
                                 output_dir=output_dir, showplot=showplot, png=png, $
                                 fix_photocorr=fix_photocorr, $
                                 var1_photocorr=var1_photocorr, $
                                 var2_photocorr=var2_photocorr, $
                                 version_name=version_name,$
                                 hybrid_opacity_after_reduction = hybrid_opacity_after_reduction
   
   
   photocorr_suffixe = '_photocorr'
   nn = n_elements(fix_photocorr)
   if fix_photocorr[0] gt 0 then $
      if nn eq 1 then photocorr_suffixe=photocorr_suffixe+'_fix' else $
         if nn eq 3 then photocorr_suffixe=photocorr_suffixe+'_step'
   if var1_photocorr gt 0 then photocorr_suffixe=photocorr_suffixe+'_var1'
   if var2_photocorr gt 0 then photocorr_suffixe=photocorr_suffixe+'_var2'
   
   stop
   
endif



;; 3./ CROSS_CHECK USING MWC349

;; parameter copy here
runname = 'N2R9'
version_name = '_ref_baseline'
photocorr_name = photocorr_suffixe
output_dir = getenv('HOME')+'/NIKA/Plots/'+runname+'/Photometry'

input_kidpar_file =  getenv('HOME')+'/NIKA/Plots/'+runname+'/Photometry/kidpar_calib_'+runname+version_name+photocorr_name+'.fits'

png=1



;; photometric correction
;;-----------------------------
fwhm_base      = [11.2, 17.4, 11.2]
fix_photocorr  = fwhm_base
;;fix_photocorr  = 0
var1_photocorr = 0
var2_photocorr = 0


;; same photometric correction as in the input kidpar
if var2_photocorr gt 0 then recalibration_coef = 0 

;; calibration coefficients of the input kidpar
restore, output_dir+'/Absolute_calibration_'+runname+version_name+photocorr_name+'.save', /v
input_calib = correction_coef
;; calibration coefficient for the tested photometric correction
test_pc=''
nn = n_elements(fix_photocorr)
if (fix_photocorr[0] gt 0 and nn eq 1) then test_pc = '_photocorr_fix'
if (fix_photocorr[0] gt 0 and nn eq 3) then test_pc = '_photocorr_step'
if var1_photocorr gt 0 then test_pc = '_photocorr_var1'
if test_pc gt '' then restore, output_dir+'/Absolute_calibration_'+runname+version_name+test_pc+'.save', /v

;; Uranus using hybrid_opacity_after_reduction
hybrid_opacity_after_reduction = 0
if hybrid_opacity_after_reduction gt 0 then restore, output_dir+'/Absolute_calibration_'+runname+version_name+test_pc+'_hybrid_v0.save', /v


test_calib  = correction_coef

if var2_photocorr gt 0 then recalibration_coef = 0 else recalibration_coef = test_calib/input_calib

;; hybrid opacity
;;-----------------------------
hybrid_opacity = 0



validate_calibration_reference, runname, input_kidpar_file, $
                                output_dir=output_dir, showplot=showplot, png=png, $
                                fix_photocorr=fix_photocorr, $
                                var1_photocorr=var1_photocorr, $
                                var2_photocorr=var2_photocorr, $
                                version_name=version_name, $
                                recalibration_coef = recalibration_coef, $
                                hybrid_opacity=hybrid_opacity





;; N2R12
;;_________________________________________________

runname = 'N2R12'
input_kidpar_file = !nika.off_proc_dir+'/kidpar_20171025s41_v2_LP_md_recal.fits'


;; 1/ OPACITY CORRECTION

do_first_iteration     = 0
do_skydip_selection    = 1
do_second_iteration    = 0
show_plot              = 1
check_after_selection  = 0 ;; launch again the selection code after the second iteration
atmlike                = 0
hightau2               = 0
baseline               = 1
reiterate              = ''
png=1

reduce_skydips_reference, runname, input_kidpar_file, $
                          hightau2=hightau2, atmlike=atmlike, $
                          baseline=baseline, $
                          showplot=show_plot, png=png, $
                          do_first_iteration=do_first_iteration, $
                          do_skydip_selection=do_skydip_selection, $
                          do_second_iteration=do_second_iteration, $
                          check_after_selection=check_after_selection, $
                          reiterate=reiterate



;; 2/ ABSOLUTE CALIBRATION

;; copy param
runname = 'N2R12'
input_kidpar_file = !nika.off_proc_dir+'/kidpar_20171025s41_v2_LP_md_recal.fits'

atmlike  = 1
hightau2 = 0

hybrid_using_c1   = 0
hybrid_opacity_after_reduction = 1

showplot = 1
png=1

version_name = '_ref'
if atmlike  gt 0 then version_name = version_name+'_atmlike'
if hightau2 gt 0 then version_name = version_name+'_hightau2_v2'
;;if hybrid   gt 0 then version_name = version_name+'_atmlike_A2C1_fromN2R9'
if hybrid_using_c1  gt 0 then version_name = version_name+'_atmlike_A2C1_fromN2R9_bis'

geom_kidpar_file   = input_kidpar_file
skydip_kidpar_file = getenv('HOME')+'/NIKA/Plots/'+runname+'/Opacity/kidpar_C0C1_'+runname+version_name+'.fits'
input_kidpar_file  = getenv('HOME')+'/NIKA/Plots/'+runname+'/Photometry/kidpar_calib_'+runname+version_name+'.fits'
if file_test(input_kidpar_file) lt 1 then skydip_coeffs, geom_kidpar_file, skydip_kidpar_file, input_kidpar_file

print, "geom_kidpar_file: ",   geom_kidpar_file
print, "skydip_kidpar_file: ", skydip_kidpar_file
print, "input_kidpar_file: ",  input_kidpar_file

;rep = ''
;read, rep
;print, 'on y va ?'

;; photometric correction : weakly variable
fix_photocorr  = 0
var1_photocorr = 0
var2_photocorr = 1
calibration_uranus_reference, runname, input_kidpar_file, $
                              output_dir=output_dir, showplot=showplot, png=png, $
                              fix_photocorr=fix_photocorr, $
                              var1_photocorr=var1_photocorr, $
                              var2_photocorr=var2_photocorr, $
                              version_name=version_name, $
                              hybrid_opacity_after_reduction=hybrid_opacity_after_reduction



;; 3./ CROSS_CHECK USING MWC349

;; parameter copy here
runname           = 'N2R12'
version_name      = '_ref_atmlike'
;;version_name      = '_ref_hightau2_v2'
photocorr_name    = '_photocorr_var1' ;; photocorr used for abs. calib. 
output_dir        = getenv('HOME')+'/NIKA/Plots/'+runname+'/Photometry'

input_kidpar_file =  getenv('HOME')+'/NIKA/Plots/'+runname+'/Photometry/kidpar_calib_'+runname+version_name+photocorr_name+'.fits'

png=1

fix_photocorr  = 0
var1_photocorr = 0
var2_photocorr = 1

;; same photometric correction as in the input kidpar
if var1_photocorr gt 0 then recalibration_coef = 0 

;; calibration coefficients of the input kidpar
restore, output_dir+'/Absolute_calibration_'+runname+version_name+'_photocorr_var1.save', /v
input_calib = correction_coef
;; calibration coefficient for the tested photometric correction
test_pc=''
if fix_photocorr gt 0 then test_pc = '_photocorr_fix'
if var2_photocorr gt 0 then test_pc = '_photocorr_var2'
if test_pc gt '' then restore, output_dir+'/Absolute_calibration_'+runname+version_name+test_pc+'.save', /v
test_calib  = correction_coef

if var1_photocorr gt 0 then recalibration_coef = 0 else recalibration_coef = test_calib/input_calib

print, "recalibration_coef = ", recalibration_coef

validate_calibration_reference, runname, input_kidpar_file, $
                                output_dir=output_dir, showplot=showplot, png=png, $
                                fix_photocorr=fix_photocorr, $
                                var1_photocorr=var1_photocorr, $
                                var2_photocorr=var2_photocorr, $
                                version_name=version_name, $
                                recalibration_coef = recalibration_coef




;; N2R14
;;_________________________________________________

runname = 'N2R14'
input_kidpar_file = !nika.off_proc_dir+'/kidpar_20180122s309_v2_HA_skd16_calUranus17.fits'


;; 1/ OPACITY CORRECTION

do_first_iteration     = 0 ;; no scan selection
do_skydip_selection    = 0 ;; perform the scan selection
do_second_iteration    = 0 ;; C0, C1 using the scan selection
show_plot              = 1
check_after_selection  = 1 ;; launch again the selection code after the second iteration
baseline               = 0
atmlike                = 1
hightau2               = 0
reiterate              = ''
png=1

reduce_skydips_reference, runname, input_kidpar_file, $
                          hightau2=hightau2, atmlike=atmlike, $
                          baseline=baseline, $
                          showplot=show_plot, png=png, $
                          do_first_iteration=do_first_iteration, $
                          do_skydip_selection=do_skydip_selection, $
                          do_second_iteration=do_second_iteration, $
                          check_after_selection=check_after_selection, $
                          reiterate=reiterate


;; 2/ ABSOLUTE CALIBRATION

;; copy param
runname = 'N2R14'
input_kidpar_file = !nika.off_proc_dir+'/kidpar_20180122s309_v2_HA_skd16_calUranus17.fits'

atmlike  = 1
hightau2 = 0

showplot = 1
png=1

version_name = '_ref'
if atmlike gt 0 then  version_name = version_name+'_atmlike'
if hightau2 gt 0 then version_name = version_name+'_hightau2'

geom_kidpar_file   = input_kidpar_file
skydip_kidpar_file = getenv('HOME')+'/NIKA/Plots/'+runname+'/Opacity/kidpar_C0C1_'+runname+version_name+'.fits'
input_kidpar_file  = getenv('HOME')+'/NIKA/Plots/'+runname+'/Photometry/kidpar_calib_'+runname+version_name+'.fits'
if file_test(input_kidpar_file) lt 1 then skydip_coeffs, geom_kidpar_file, skydip_kidpar_file, input_kidpar_file

print, "geom_kidpar_file: ",   geom_kidpar_file
print, "skydip_kidpar_file: ", skydip_kidpar_file
print, "input_kidpar_file: ",  input_kidpar_file

hybrid_opacity_after_reduction = 1

;rep = ''
;read, rep
;print, 'on y va ?'

;; photometric correction
fix_photocorr  = 0
var1_photocorr = 0
var2_photocorr = 0
;; accounting for the apparent size of Uranus
fwhm_base = [11.2, 17.4, 11.2]
angdiam   = 4.0; 3.3 - 4.1
fwhm_disc = sqrt(fwhm_base^2 + alog(2.0d0)/2.0d0*angdiam^2 )
fix_photocorr  = fwhm_disc

calibration_uranus_reference, runname, input_kidpar_file, $
                              output_dir=output_dir, showplot=showplot, png=png, $
                              fix_photocorr=fix_photocorr, $
                              var1_photocorr=var1_photocorr, $
                              var2_photocorr=var2_photocorr, $
                              version_name=version_name, $
                              hybrid_opacity_after_reduction=hybrid_opacity_after_reduction



;; 3./ CROSS_CHECK USING MWC349

;; parameter copy here
runname           = 'N2R14'
version_name      = '_ref_atmlike'
;;version_name      = '_ref_hightau2'
photocorr_name    = '_photocorr_var2' ;; photocorr used for abs. calib. 
output_dir        = getenv('HOME')+'/NIKA/Plots/'+runname+'/Photometry'

;; hybrid opacity
;;-----------------------------
hybrid_opacity    = 1
opa_suffixe       = '_hybrid_v0'

hybrid_opacity    = 0
opa_suffixe       = ''
photocorr_name    = '_photocorr_var1'

input_kidpar_file =  getenv('HOME')+'/NIKA/Plots/'+runname+'/Photometry/kidpar_calib_'+runname+version_name+photocorr_name+opa_suffixe'.fits'

png=1

;; photometric correction
;;-----------------------------
fwhm_base      = [11.2, 17.4, 11.2]
fix_photocorr  = fwhm_base
;;fix_photocorr  = 0
var1_photocorr = 0
var2_photocorr = 0

;; same photometric correction as in the input kidpar
if var2_photocorr gt 0 then recalibration_coef = 0 

;; calibration coefficients of the input kidpar
restore, output_dir+'/Absolute_calibration_'+runname+version_name+photocorr_name+opa_suffixe+'.save', /v
input_calib = correction_coef
;; calibration coefficient for the tested photometric correction
test_pc=''
nn = n_elements(fix_photocorr)
if (fix_photocorr[0] gt 0 and nn eq 1) then test_pc = '_photocorr_fix'
if (fix_photocorr[0] gt 0 and nn eq 3) then test_pc = '_photocorr_step'
if var1_photocorr gt 0 then test_pc = '_photocorr_var1'
if var2_photocorr gt 0 then test_pc = '_photocorr_var2'
if test_pc gt '' then restore, output_dir+'/Absolute_calibration_'+runname+version_name+test_pc+opa_suffixe+'.save', /v
test_calib  = correction_coef

;; NB: editer ici suivant hybrid_opacity ou non 
if var2_photocorr gt 0 then recalibration_coef = 0 else recalibration_coef = test_calib/input_calib

print, "recalibration_coef = ", recalibration_coef

outlier_scan_list = ['20180122s98']

validate_calibration_reference, runname, input_kidpar_file, $
                                output_dir=output_dir, showplot=showplot, png=png, $
                                fix_photocorr=fix_photocorr, $
                                var1_photocorr=var1_photocorr, $
                                var2_photocorr=var2_photocorr, $
                                version_name=version_name, $
                                recalibration_coef = recalibration_coef, $
                                outlier_scan_list = outlier_scan_list, $
                                hybrid_opacity=hybrid_opacity








end
