args = command_line_args()

outdir = args[0]  
rev = args[1]
n2run = args[2]

print, "Calibration dir  = ", outdir
print, "IDL Pipeline rev = ", rev
print, "N2R number = ", n2run

runname = ['N2R'+strtrim(n2run,2)]

;; redefined Plot dir
setenv, 'NIKA_PLOT_DIR='+outdir       
!nika.plot_dir = outdir
if file_test(!nika.plot_dir+'/'+runname[0], /directory) lt 1 then spawn, "mkdir -p "+!nika.plot_dir+'/'+runname[0]

get_nika2_run_info, nika2run_info
wrun = where(strmatch(nika2run_info.nika2run, runname[0]) gt 0)
day = nika2run_info[wrun].firstday
nk_get_kidpar_ref, '1', day, info, kidpar_file_1
day = nika2run_info[wrun].lastday
nk_get_kidpar_ref, '1', day, info, kidpar_file_2

multiple_kidpars = 0
geom_kidpar_file = kidpar_file_1
if kidpar_file_1 ne kidpar_file_2 then multiple_kidpars = 1
if multiple_kidpars gt 0 then geom_kidpar_file = [kidpar_file_1, kidpar_file_2]

;;___________________________________________________________________________
;;
;; ACTIONS
;;____________________________________________________________________________

;; C0, C1 estimate
do_opacity_correction        = 0

;; IF SKYDIP REDUCTION IS NOT SET, TAKE THE C0, C1 FROM THE REFERENCE KIDPAR
if do_opacity_correction lt 1 and file_test(!nika.plot_dir+'/'+runname[0]+'/Opacity', /directory) lt 1 then spawn, "mkdir -p "+!nika.plot_dir+'/'+runname[0]+'/Opacity'
if do_opacity_correction lt 1 then spawn, "cp "+geom_kidpar_file[0]+" "+!nika.plot_dir+'/'+runname[0]+'/Opacity/kidpar_C0C1_'+runname[0]+'_baseline.fits'

;; PERFORM THE ABSOLUTE CALIBRATION
do_absolute_calibration      = 0

;; >>>> When the two previous steps are done, the calibration is
;; completed
;; >>>> The next steps consists of validation and assessment of the
;; calibration quality

;; VALIDATION OF THE CALIBRATION
;; 1/ minimum validation: check the photometry on secondary calibrators 
do_photometry_check_on_secondaries = 0

  ;; 2/ [REDUCTION OF ABOUT 100 SCANS] evaluate the RMS uncertainties on bright sources (>1Jy)
do_rms_calibration_uncertainties   = 0

;; 3/ [REDUCTION OF ABOUT 100 SCANS] evaluate the NEFD using all sources < 1 Jy
do_nefd_using_scatter_method       = 0

;; OUTPUT THE CALIBRATION RESULTS
;; the IDL structure 'calibration' will be saved in the output directory 
save_calibration_results           = 0

;; set to 1 to run the whole script without stopping after the main steps
nostop = 1

;; set to 1 to stop after each step 
pas_a_pas = 0

basecalrun, runname, kidin = geom_kidpar_file,  $
            multiple_kidpars = multiple_kidpars, $
            opacorr = do_opacity_correction, $
            abscal  = do_absolute_calibration, $
            photsec = do_photometry_check_on_secondaries, $
            rmscal  = do_rms_calibration_uncertainties, $
            nefd    = do_nefd_using_scatter_method, $
            savecal = save_calibration_results, $
            nostop  = nostop, pas_a_pas = pas_a_pas


exit
