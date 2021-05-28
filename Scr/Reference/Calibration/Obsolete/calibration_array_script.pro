;;
;;   LAUNCHER SCRIPT FOR A SERIES OF CALIBRATIONS
;;
;;   AIM: THE COMPARISON OF CALIBRATION METHODS
;;
;;   LP, April 2018
;;_________________________________________________


;; N2R9
;;_________________________________________________

runname = 'N2R9'
input_kidpar_file = !nika.off_proc_dir+'/kidpar_best3files_FXDC0C1_GaussPhot_NewConv.fits'


;; 1/ OPACITY CORRECTION

do_first_iteration  = 0
;; NB: equivalent to '_1803'

do_skydip_selection = 0
do_second_iteration = 0

show_plot = 1
check_after_selection  = 0 ;; launch again the selection code after the second iteration

;; ATM-like
atmlike     = 1
hightau2    = 0
png=1

reduce_skydips_reference, runname, input_kidpar_file, $
                          hightau2=hightau2, atmlike=atmlike, $
                          showplot=show_plot, png=png, $
                          do_first_iteration=do_first_iteration, $
                          do_skydip_selection=do_skydip_selection, $
                          do_second_iteration=do_second_iteration, $
                          check_after_selection=check_after_selection, $
                          reiterate=reiterate

;; High-tau2
atmlike     = 0
hightau2    = 1

;; reiterate
check_blacklist_file = '/home/perotto/NIKA/Processing/Pipeline/Datamanage/blacklist_N2R9_ref_hightau2_check.dat'
input_blacklist_file = '/home/perotto/NIKA/Processing/Pipeline/Datamanage/blacklist_N2R9_ref_hightau2_v2.dat'
cmd = "cp "+check_blacklist_file+" "+input_blacklist_file
if file_test(input_blacklist_file) lt 1 then spawn, cmd 
reiterate = '_v2'

;; reiterate
check_blacklist_file = '/home/perotto/NIKA/Processing/Pipeline/Datamanage/blacklist_N2R9_ref_hightau2_v2_check.dat'
input_blacklist_file = '/home/perotto/NIKA/Processing/Pipeline/Datamanage/blacklist_N2R9_ref_hightau2_v3.dat'
cmd = "cp "+check_blacklist_file+" "+input_blacklist_file
if file_test(input_blacklist_file) lt 1 then spawn, cmd 
reiterate = '_v3'


png=1

reduce_skydips_reference, runname, input_kidpar_file, $
                          hightau2=hightau2, atmlike=atmlike, $
                          showplot=show_plot, png=png, $
                          do_first_iteration=do_first_iteration, $
                          do_skydip_selection=do_skydip_selection, $
                          do_second_iteration=do_second_iteration, $
                          check_after_selection=check_after_selection, $
                          reiterate=reiterate


;; test using another tau3 cut: tau3<0.8 
runname = 'N2R9'
input_kidpar_file = !nika.off_proc_dir+'/kidpar_best3files_FXDC0C1_GaussPhot_NewConv.fits'

do_first_iteration  = 0
do_skydip_selection = 0
do_second_iteration = 0
show_plot = 1
check_after_selection  = 0 ;; launch again the selection code after the second iteration
atmlike     = 0
hightau2    = 1
png=1
reiterate = '_bis'

;; reiterate
runname = 'N2R9'
input_kidpar_file = !nika.off_proc_dir+'/kidpar_best3files_FXDC0C1_GaussPhot_NewConv.fits'

do_first_iteration  = 0
do_skydip_selection = 0
do_second_iteration = 0
show_plot = 1
check_after_selection  = 1 ;; launch again the selection code after the second iteration
atmlike     = 0
hightau2    = 1
baseline    = 0 
png=1
check_blacklist_file = '/home/perotto/NIKA/Processing/Pipeline/Datamanage/blacklist_N2R9_ref_hightau2_bis_check.dat'
input_blacklist_file = '/home/perotto/NIKA/Processing/Pipeline/Datamanage/blacklist_N2R9_ref_hightau2_bis_v2.dat'
cmd = "cp "+check_blacklist_file+" "+input_blacklist_file
if file_test(input_blacklist_file) lt 1 then spawn, cmd 
reiterate = '_bis_v2'
reiterate = '_bis_v3'

reduce_skydips_reference, runname, input_kidpar_file, $
                          hightau2=hightau2, atmlike=atmlike, $
                          baseline=baseline,$
                          showplot=show_plot, png=png, $
                          do_first_iteration=do_first_iteration, $
                          do_skydip_selection=do_skydip_selection, $
                          do_second_iteration=do_second_iteration, $
                          check_after_selection=check_after_selection, $
                          reiterate=reiterate





stop


;; 2/ ABSOLUTE CALIBRATION

;; copy param
runname = 'N2R9'
input_kidpar_file = !nika.off_proc_dir+'/kidpar_best3files_FXDC0C1_GaussPhot_NewConv.fits'

atmlike  = 0
hightau2 = 1

showplot = 1
png=1

version_name = '_ref'
if atmlike gt 0 then  version_name = version_name+'_atmlike'
if hightau2 gt 0 then version_name = version_name+'_hightau2_v3'
;;if hightau2 gt 0 then version_name = version_name+'_hightau2_bis_v2'

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

;; photometric correction : fix / var 1 /var 2
fix_photocorr  = 0
var1_photocorr = 0
var2_photocorr = 1
calibration_uranus_reference, runname, input_kidpar_file, $
                              output_dir=output_dir, showplot=showplot, png=png, $
                              fix_photocorr=fix_photocorr, $
                              var1_photocorr=var1_photocorr, $
                              var2_photocorr=var2_photocorr, $
                              version_name=version_name


stop



;; 3./ CROSS_CHECK USING MWC349

;; parameter copy here
runname = 'N2R9'
;version_name = '_ref_atmlike'
;photocorr_name = '_photocorr_var1'
version_name = '_ref_hightau2_v3'
photocorr_name = '_photocorr_var1'
;;version_name = '_ref_hightau2_bis_v2'
;;photocorr_name = '_photocorr_var1'
output_dir = getenv('HOME')+'/NIKA/Plots/'+runname+'/Photometry'

input_kidpar_file =  getenv('HOME')+'/NIKA/Plots/'+runname+'/Photometry/kidpar_calib_'+runname+version_name+photocorr_name+'.fits'

;;input_kidpar_file =  getenv('HOME')+'/NIKA/Plots/'+runname+'/Photometry/kidpar_calib_'+runname+version_name+'.fits'

png=1


fix_photocorr  = 0
var1_photocorr = 0
var2_photocorr = 1


;; same photometric correction as in the input kidpar
if var1_photocorr gt 0 then recalibration_coef = 0 

;; calibration coefficients of the input kidpar
restore, output_dir+'/Absolute_calibration_'+runname+version_name+'_photocorr_var1.save', /v
if version_name eq '_ref_hightau2_v3' then input_calib = [1.0d0, 1.0D0, 1.0D0] else input_calib = correction_coef
;; calibration coefficient for the tested photometric correction
test_pc=''
if fix_photocorr gt 0 then test_pc = '_photocorr_fix'
if var2_photocorr gt 0 then test_pc = '_photocorr_var2'
if test_pc gt '' then restore, output_dir+'/Absolute_calibration_'+runname+version_name+test_pc+'.save', /v
test_calib  = correction_coef

if var1_photocorr gt 0 then recalibration_coef = 0 else recalibration_coef = test_calib/input_calib

validate_calibration_reference, runname, input_kidpar_file, $
   output_dir=output_dir, showplot=showplot, png=png, $
   fix_photocorr=fix_photocorr, $
   var1_photocorr=var1_photocorr, $
   var2_photocorr=var2_photocorr, $
   version_name=version_name, $
   recalibration_coef = recalibration_coef





;; N2R12
;;_________________________________________________

runname = 'N2R12'
input_kidpar_file = !nika.off_proc_dir+'/kidpar_20171025s41_v2_LP_md_recal.fits'


;; 1/ OPACITY CORRECTION

;; A./ ATM-like
do_first_iteration     = 1
do_skydip_selection    = 0
do_second_iteration    = 0
show_plot              = 1
check_after_selection  = 0 ;; launch again the selection code after the second iteration
atmlike                = 1
hightau2               = 0
reiterate              = ''
png=1

reduce_skydips_reference, runname, input_kidpar_file, $
                          hightau2=hightau2, atmlike=atmlike, $
                          showplot=show_plot, png=png, $
                          do_first_iteration=do_first_iteration, $
                          do_skydip_selection=do_skydip_selection, $
                          do_second_iteration=do_second_iteration, $
                          check_after_selection=check_after_selection, $
                          reiterate=reiterate

;; B./ High-tau2
do_first_iteration     = 0
do_skydip_selection    = 0
do_second_iteration    = 0
show_plot              = 1
check_after_selection  = 1 ;; launch again the selection code after the second iteration
atmlike                = 0
hightau2               = 1
reiterate              = ''
png=1

reduce_skydips_reference, runname, input_kidpar_file, $
                          hightau2=hightau2, atmlike=atmlike, $
                          showplot=show_plot, png=png, $
                          do_first_iteration=do_first_iteration, $
                          do_skydip_selection=do_skydip_selection, $
                          do_second_iteration=do_second_iteration, $
                          check_after_selection=check_after_selection, $
                          reiterate=reiterate
;; reiterate
check_blacklist_file = '/home/perotto/NIKA/Processing/Pipeline/Datamanage/blacklist_N2R12_ref_hightau2_check.dat'
input_blacklist_file = '/home/perotto/NIKA/Processing/Pipeline/Datamanage/blacklist_N2R12_ref_hightau2_v2.dat'
cmd = "cp "+check_blacklist_file+" "+input_blacklist_file
if file_test(input_blacklist_file) lt 1 then spawn, cmd

do_first_iteration     = 0
do_skydip_selection    = 0
do_second_iteration    = 1
show_plot              = 1
check_after_selection  = 1 ;; launch again the selection code after the second iteration
atmlike                = 0
hightau2               = 1
reiterate              = '_v2'
png=1

reduce_skydips_reference, runname, input_kidpar_file, $
                          hightau2=hightau2, atmlike=atmlike, $
                          showplot=show_plot, png=png, $
                          do_first_iteration=do_first_iteration, $
                          do_skydip_selection=do_skydip_selection, $
                          do_second_iteration=do_second_iteration, $
                          check_after_selection=check_after_selection, $
                          reiterate=reiterate


;; C./ hybrid
;; C0 from N2R12-atm-like & C1 from N2R9-high-tau2 
C0_kidpar_file = getenv('HOME')+'/NIKA/Plots/N2R12/Opacity/kidpar_C0C1_N2R12_ref_atmlike.fits'
;;C1_kidpar_file = getenv('HOME')+'/NIKA/Plots/N2R9/Opacity/kidpar_C0C1_N2R9_ref_hightau2_v3.fits'
C1_kidpar_file =  getenv('HOME')+'/NIKA/Plots/N2R9/Opacity/kidpar_C0C1_N2R9_ref_hightau2_bis_v2.fits'

out_kidpar_file = getenv('HOME')+'/NIKA/Plots/N2R12/Opacity/kidpar_C0C1_N2R12_ref_atmlike_A2C1_fromN2R9_bis.fits'

C0_kp = mrdfits( C0_kidpar_file, 1)
C1_kp = mrdfits( C1_kidpar_file, 1)

w0 = where( C0_kp.type eq 1 and C0_kp.array eq 2, nw0)
w1 = where( C1_kp.type eq 1 and C1_kp.array eq 2, nw1)

my_match, C0_kp[w0].numdet, C1_kp[w1].numdet, suba, subb
C0_kp[w0].c1_skydip = 0.d0
C0_kp[w0[suba]].c1_skydip = C1_kp[w1[subb]].c1_skydip

if file_test(out_kidpar_file) lt 1 then nk_write_kidpar, C0_kp, out_kidpar_file

;; test
C00_kp = mrdfits( C0_kidpar_file, 1)
C0_kp = mrdfits( out_kidpar_file, 1)
w00 = where( C0_kp0.type eq 1, nw00)
w0  = where( C0_kp.type eq 1, nw0)
w1  = where( C1_kp.type eq 1, nw1)
C00_kp = C00_kp[w00]
C0_kp = C0_kp[w0]
c1_kp = C1_kp[w1]
my_match, C0_kp.numdet, C1_kp.numdet, suba, subb
C0_kp = C0_kp[suba]
C1_kp = C1_kp[subb]
my_match, C00_kp.numdet, C1_kp.numdet, suba, subb
C00_kp = C00_kp[suba]
C0_kp = C0_kp[subb]
C1_kp = C1_kp[subb]
plot,C0_kp.c1_skydip, psym=1
oplot, C1_kp.c1_skydip, psym=4, col=250
oplot, C00_kp.c1_skydip, psym=5, col=80


;; 2/ ABSOLUTE CALIBRATION

;; copy param
runname = 'N2R12'
input_kidpar_file = !nika.off_proc_dir+'/kidpar_20171025s41_v2_LP_md_recal.fits'

atmlike  = 0
hightau2 = 0
hybrid   = 1

showplot = 1
png=1

version_name = '_ref'
if atmlike  gt 0 then version_name = version_name+'_atmlike'
if hightau2 gt 0 then version_name = version_name+'_hightau2_v2'
;;if hybrid   gt 0 then version_name = version_name+'_atmlike_A2C1_fromN2R9'
if hybrid   gt 0 then version_name = version_name+'_atmlike_A2C1_fromN2R9_bis'

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
var1_photocorr = 1
var2_photocorr = 0
calibration_uranus_reference, runname, input_kidpar_file, $
                              output_dir=output_dir, showplot=showplot, png=png, $
                              fix_photocorr=fix_photocorr, $
                              var1_photocorr=var1_photocorr, $
                              var2_photocorr=var2_photocorr, $
                              version_name=version_name


;; 3./ CROSS_CHECK USING MWC349

;; parameter copy here
runname           = 'N2R12'
version_name      = '_ref_atmlike'
version_name      = '_ref_hightau2_v2'
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

;; A. / ATM-like
do_first_iteration     = 0 ;; no scan selection
do_skydip_selection    = 1 ;; perform the scan selection
do_second_iteration    = 0 ;; C0, C1 using the scan selection
show_plot              = 1
check_after_selection  = 0 ;; launch again the selection code after the second iteration
atmlike                = 1
hightau2               = 0
reiterate              = ''
png=1

reduce_skydips_reference, runname, input_kidpar_file, $
                          hightau2=hightau2, atmlike=atmlike, $
                          showplot=show_plot, png=png, $
                          do_first_iteration=do_first_iteration, $
                          do_skydip_selection=do_skydip_selection, $
                          do_second_iteration=do_second_iteration, $
                          check_after_selection=check_after_selection, $
                          reiterate=reiterate

;; B. / High-tau2
do_first_iteration     = 0
do_skydip_selection    = 0
do_second_iteration    = 1
show_plot              = 1
check_after_selection  = 1 ;; launch again the selection code after the second iteration
atmlike                = 0
hightau2               = 1
reiterate              = ''
png=1

reduce_skydips_reference, runname, input_kidpar_file, $
                          hightau2=hightau2, atmlike=atmlike, $
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

atmlike  = 0
hightau2 = 1

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
                              version_name=version_name


;; 3./ CROSS_CHECK USING MWC349

;; parameter copy here
runname           = 'N2R14'
version_name      = '_ref_atmlike'
;;version_name      = '_ref_hightau2'
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

outlier_scan_list = ['20180122s98']

validate_calibration_reference, runname, input_kidpar_file, $
                                output_dir=output_dir, showplot=showplot, png=png, $
                                fix_photocorr=fix_photocorr, $
                                var1_photocorr=var1_photocorr, $
                                var2_photocorr=var2_photocorr, $
                                version_name=version_name, $
                                recalibration_coef = recalibration_coef, $
                                outlier_scan_list = outlier_scan_list









end
