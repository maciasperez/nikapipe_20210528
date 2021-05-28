;
;   NIKA2 performance assessment
; 
;   Opacity checks  
;
;   LP, June 2018
;   from LP/script/n2r10/check_nefd_multirun.pro
;__________________________________________________________

pro opacity_multirun

run = ['N2R9', 'N2R12', 'N2R14']
rname = ['baseline', 'atmlike', 'atmlike']

;run   = ['N2R14']
;rname = ['atmlike']

png=1

dir0 = '/data/Workspace/macias/NIKA2/Plots/CalibTests'

dir9  = dir0+'/RUN9_OTFS_pipeline'
dir12 = dir0+'/RUN12_OTFS_pipeline'
dir14 = dir0+'/RUN14_OTFS_baseline'

dir   = [dir9, dir12, dir14]
;dir   = [dir14]

outdir = '/home/perotto/NIKA/Plots/NEFD_update/'
suf='_baseline'


;;  Create table of result structures
;;_________________________________________________________
resultfile_9    = outdir+'Results_N2R9_nefd.save'
resultfile_12   = outdir+'Results_N2R12_nefd.save'
resultfile_14   = outdir+'Results_N2R14_nefd.save'

resultfile = [resultfile_9, resultfile_12, resultfile_14]
;resultfile = [resultfile_14]

nrun = n_elements(run)

colrun = [250, 80, 50]
symrun = [8, 6, 6]


for irun = 0, nrun-1 do begin
   juan_list_file = outdir+'OTF_scan_list_'+run[irun]+'.save'
   if file_test(resultfile[irun]) lt 1 then begin
      spawn, 'ls '+dir[irun]+'/v_1/*/results.save', res_files
      nscans = 0
      if res_files[0] gt '' then nscans = n_elements(res_files)

      juan_list = ''
      if nscans gt 0 then begin
         restore, res_files[0], /v
         info_all = replicate(info1, nscans)
         
         for i =0, nscans-1 do begin
            restore, res_files[i]
            info_all[i] = info1
         endfor
             
         juan_list = strtrim(string(info_all.day, format='(i8)'), 2)+'s'+$
                     strtrim(string(info_all.scan_num, format='(i8)'), 2)
         
      endif
      save, juan_list, filename=juan_list_file

      save, info_all, filename=resultfile[irun]
      
   endif
 
endfor

;; ATM model
tau_model_file = '/home/macias/NIKA/Processing/Pipeline/Datamanage/tau_arrays_April_2018.dat'
readcol, tau_model_file, tau1_model, tau2_model, tau3_model, format='D, D, D'

alp=0.168d0 
mod_atm_r = tau2_model/tau1_model + alp

tau_1        = 0.
tau_3        = 0.
tau_1mm      = 0.
tau_2mm      = 0.
el           = 0.
obj          = ''
day          = ''
runid        = ''

for irun = 0, nrun-1 do begin
   
   allresult_file = resultfile[irun] 
   ;;
   ;;  restore the result tables
   ;;____________________________________________________________
   restore, allresult_file, /v

   ;;
   ;; scan selection
   ;;____________________________________________________________
   wout       = 1
   wlargebeam = 1 
   wdaytime   = 1
   whitau3    = 1
   fwhm_max   = 1
   nefd_index = 1
   scan_selection, info_all, wtokeep, $
                   to_use_photocorr=to_use_photocorr, complement_index=wout, $
                   beamok_index = beamok_index, largebeam_index = wlargebeam,$
                   tauok_index = tauok_index, hightau_index=whitau3, $
                   osbdateok_index=obsdateok_index, afternoon_index=wdaytime, $
                   fwhm_max = fwhm_max, nefd_index = nefd_index

   
   info_all = info_all[nefd_index]

   ;;w1 = where(info_all.result_flux_i_1mm lt 1.0d0 and info_all.result_flux_i_2mm lt 1.0d0, n1) 
   ;;info_all = info_all[w1]
   ;;print,'Run ', run[irun], ' nscans = ', n1
   
   ws = where(strlowcase(info_all.object) ne 'ic342' and $
              strlowcase(info_all.object) ne 'gp_l23p3' and $
              strlowcase(info_all.object) ne 'gp_l23p9' and $
              strlowcase(info_all.object) ne 'jkcs041' and $
              ;strlowcase(info_all.object) ne 'macs1206' and $
              strlowcase(info_all.object) ne 'gp_l24p5', ns )
   info_all = info_all[ws]
   print,'Run ', run[irun], ' nscans = ', ns
   
   scan_list = strtrim(string(info_all.day, format='(i8)'), 2)+'s'+$
               strtrim(string(info_all.scan_num, format='(i8)'), 2)

   ;; recalibration coef
   recalibration_file = !nika.soft_dir+'/Labtools/LP/datamanage/Calibration_coefficients_'+run[irun]+'_ref_'+rname[irun]+'_calpera_hybrid_v0.save'
   restore, recalibration_file, /v
   tau_1        = [tau_1, info_all.result_tau_1]
   tau_3        = [tau_3, info_all.result_tau_3]
   tau_1mm      = [tau_1mm, info_all.result_tau_1mm]
   tau_2mm      = [tau_2mm, info_all.result_tau_2mm]
   el           = [el, info_all.result_elevation_deg*!dtor]
   obj          = [obj, info_all.object]
   day          = [day, info_all.day]
   runid        = [runid, replicate(run[irun], n_elements(info_all.day))]

endfor
mtau_2mm = tau_1mm*modified_atm_ratio(tau_1mm)

;;========================================================================================
;;
;;
;;          PLOT ET FIT
;; 
;;========================================================================================
print,"===================================================="
print,""
print,"    PLOTS "
print,""
print,"===================================================="
  
;;; N2R9
;;;--------------------------------------------------------------------
wr9  = where(day le '20170228', nr9)
wr10 = where(day gt '20170401' and day lt '20170501', nr10)
wr12 = where(day gt '20171001' and day lt '20171101', nr12)
wr14 = where(day gt '20180101' and day lt '20180201', nr14)

wrun = ''
if nr9  gt 0 then wrun=[wrun,wr9]
if nr10 gt 0 then wrun=[wrun,wr10]
if nr12 gt 0 then wrun=[wrun,wr12]
if nr14 gt 0 then wrun=[wrun,wr14]
wrun = wrun[1:*]
   



;;;    1mm
;;;____________________________________________________________________
print,""
print," 1mm"
print,"---------------------------------------------------"
;;; plot
;;;---------------------------------------------------------------------
fname = outdir + 'OPACITY_2_1'+suf

for irun=0, nrun-1 do fname=fname+'_'+run[irun]

outplot, file=fname, png=png, $
         ps=ps, xsize=ps_xsize, ysize=ps_ysize, charsize=ps_charsize, charthick=ps_charthick, thick=1.5


obs_tau1mm = tau_1mm/sin(el)
obs_tau2mm = tau_2mm/sin(el)
obs_tau1 = tau_1/sin(el)
obs_tau3 = tau_3/sin(el)

colrun = [250, 80, 50]
symrun = [8, 6, 6]

wind, 1, 1, /free, xsize=700, ysize=450

plot, tau_1mm[wrun], tau_2mm[wrun]/tau_1mm[wrun], /nodata, yrange=[0.4, 1.25], xr=[0, 0.75], /xs, /ys, xtitle="zenith opacity at 1mm", ytitle="zenith opacity 2mm-to-1mm ratio"



if nr9  gt 0 then oplot,  tau_1mm[wr9], mtau_2mm[wr9]/tau_1mm[wr9], psym=8, symsize=0.5, col=250
if nr10 gt 0 then oplot,  tau_1mm[wr10], mtau_2mm[wr10]/tau_1mm[wr10], psym=6, symsize=0.5, col=200;, thick=2
if nr12 gt 0 then oplot,  tau_1mm[wr12], mtau_2mm[wr12]/tau_1mm[wr12], psym=6, symsize=0.5, col=80;, thick=2
if nr14 gt 0 then oplot,  tau_1mm[wr14], mtau_2mm[wr14]/tau_1mm[wr14], psym=6, symsize=0.5, col=50;, thick=2

oplot, tau1_model, mod_atm_r, col=0
oplot, tau1_model, tau2_model/tau1_model, col=50


legendastro, [run, 'Modified ATM model', 'ATM model'] , textcolor=[colrun, 0, 50], color=[colrun, 0, 50], psym=[symrun, 0, 0], box=0, pos=[0.4,1.2], charsize=0.9

if png gt 0 then outplot, /close


;;;    1mm
;;;____________________________________________________________________
print,""
print," 1mm"
print,"---------------------------------------------------"
;;; plot
;;;---------------------------------------------------------------------
fname = outdir + 'OPACITY_3_1'+suf

for irun=0, nrun-1 do fname=fname+'_'+run[irun]

outplot, file=fname, png=png, $
         ps=ps, xsize=ps_xsize, ysize=ps_ysize, charsize=ps_charsize, charthick=ps_charthick, thick=1.5


obs_tau1 = tau_1mm/sin(el)
obs_tau2 = tau_2mm/sin(el)


colrun = [250, 80, 50]
symrun = [8, 6, 6]

wind, 1, 1, /free, xsize=700, ysize=450

plot, obs_tau1[wrun], tau_3[wrun]/tau_1[wrun], /nodata, yrange=[0.9, 1.25], xr=[0, 0.75], /xs, /ys, xtitle="A1 observed opacity", ytitle="A3-to-A1 opacity ratio"



if nr9  gt 0 then oplot,  obs_tau1[wr9], tau_3[wr9]/tau_1[wr9], psym=8, symsize=0.5, col=250
if nr10 gt 0 then oplot,  obs_tau1[wr10], tau_3[wr10]/tau_1[wr10], psym=6, symsize=0.5, col=200;, thick=2
if nr12 gt 0 then oplot,  obs_tau1[wr12], tau_3[wr12]/tau_1[wr12], psym=6, symsize=0.5, col=80;, thick=2
if nr14 gt 0 then oplot,  obs_tau1[wr14], tau_3[wr14]/tau_1[wr14], psym=6, symsize=0.5, col=50;, thick=2


oplot, tau1_model, tau3_model/tau1_model, col=50
oplot, [0, 10], [1, 1], col=0

legendastro, [run,'ATM model'] , textcolor=[colrun,50], color=[colrun, 50], psym=[symrun, 0], box=0, pos=[0.4,1.2], charsize=0.9

if png gt 0 then outplot, /close



stop





end
