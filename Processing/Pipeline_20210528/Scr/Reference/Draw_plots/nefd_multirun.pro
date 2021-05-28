;
;   NIKA2 performance assessment
; 
;   NEFD using the "pipeline method"
;
;   LP, June 2018
;   from LP/script/n2r10/check_nefd_multirun.pro
;__________________________________________________________

pro nefd_multirun

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
;;----------------------------------------------------------------------
resultfile_9    = outdir+'N2R9_all_scan_results.save'
resultfile_12   = outdir+'N2R12_all_scan_results.save'
resultfile_14   = outdir+'N2R14_all_scan_results.save'

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



;;; condition IRAM
;;;-------------------------------------------------------------------
print,""
print,"condition IRAM"
print,"---------------------------------------------------"
output_pwv = 1.0d0
atm_model_mdp, tau_1, tau_2, tau_3, tau_225, atm_em_1, atm_em_2, atm_em_3, output_pwv=output_pwv, /nostop
w=where(output_pwv eq 2., nn)

tau1 = avg([tau_1[w],tau_3[w]])
tau2 = tau_2[w]
tau_a1 = tau_1[w]
tau_a3 = tau_3[w]
print,"tau_1 @ 2mm pwv = ", tau_a1
print,"tau_3 @ 2mm pwv  = ", tau_a3
print,"tau_1mm @ 2mm pwv  = ", tau1
print,"tau_2mm @ 2mm pwv  = ", tau2


nefd_1mm     = 0.
nefd_2mm     = 0.
nefd_a1      = 0.
nefd_a3      = 0.
err_flux_1mm = 0.
err_flux_2mm = 0.
err_flux_a1  = 0.
err_flux_a3  = 0.
eta_a1       = 0.
eta_a3       = 0.
eta_2mm      = 0.
eta_1mm      = 0.
tau_1mm      = 0.
tau_2mm      = 0.
el           = 0.
obj          = ''
day          = ''
runid        = ''

for irun = 0, nrun-1 do begin
   
   juan_list_file = outdir+'NEFD_scan_list_'+run[irun]+'.save'
   
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

   w1 = where(info_all.result_flux_i_1mm lt 1.0d0 and info_all.result_flux_i_2mm lt 1.0d0, n1) 
   info_all = info_all[w1]
   print,'Run ', run[irun], ' nscans = ', n1
   
   ;; ws = where(strlowcase(info_all.object) ne 'ic342' and $
   ;;            strlowcase(info_all.object) ne 'ngc588' and $
   ;;            strlowcase(info_all.object) ne 'mooj1142' and $
   ;;            strlowcase(info_all.object) ne 'jkcs041' and $
   ;;            strlowcase(info_all.object) ne 'g2' , ns )
   ;; info_all = info_all[ws]
   ;; print,'Run ', run[irun], ' nscans = ', ns
   
   ws = where(strlowcase(info_all.object) ne 'ic342' and $
              strlowcase(info_all.object) ne 'gp_l23p3' and $
              strlowcase(info_all.object) ne 'gp_l23p9' and $
              strlowcase(info_all.object) ne 'jkcs041' and $
              ;strlowcase(info_all.object) ne 'macs1206' and $
              strlowcase(info_all.object) ne 'gp_l24p5', ns )
   info_all = info_all[ws]
   print,'Run ', run[irun], ' nscans = ', ns
   
   nefd_list = strtrim(string(info_all.day, format='(i8)'), 2)+'s'+$
               strtrim(string(info_all.scan_num, format='(i8)'), 2)
   ;;save, nefd_list, filename=juan_list_file

   ;; recalibration coef
   recalibration_file = !nika.soft_dir+'/Labtools/LP/datamanage/Calibration_coefficients_'+run[irun]+'_ref_'+rname[irun]+'_calpera_hybrid_v0.save'
   restore, recalibration_file, /v
   
   
   nefd_1mm     = [nefd_1mm, info_all.result_nefd_i_1mm*1.0d3*recalibration_coef[2]]
   nefd_2mm     = [nefd_2mm, info_all.result_nefd_i2*1.0d3*recalibration_coef[1]]
   nefd_a1      = [nefd_a1, info_all.result_nefd_i1*1.0d3*recalibration_coef[0]]
   nefd_a3      = [nefd_a3, info_all.result_nefd_i3*1.0d3*recalibration_coef[2]]
   err_flux_1mm = [err_flux_1mm, info_all.result_err_flux_i_1mm*1.0d3]
   err_flux_2mm = [err_flux_2mm, info_all.result_err_flux_i2*1.0d3]
   err_flux_a1  = [err_flux_a1, info_all.result_err_flux_i1*1.0d3]
   err_flux_a3  = [err_flux_a3, info_all.result_err_flux_i3*1.0d3]
   eta_a1       = [eta_a1, info_all.result_nkids_valid1/1140.0] ;!nika.ntot_nom[0]
   eta_a3       = [eta_a3, info_all.result_nkids_valid3/1140.0] ;!nika.ntot_nom[2]
   eta_2mm      = [eta_2mm, info_all.result_nkids_valid2/616.0]  ;!nika.ntot_nom[1]
   eta_1mm      = [eta_1mm, (info_all.result_nkids_valid1+info_all.result_nkids_valid3)/2d/1140.0d0]
   tau_1mm      = [tau_1mm, info_all.result_tau_1mm]
   tau_2mm      = [tau_2mm, info_all.result_tau_2mm]
   el           = [el, info_all.result_elevation_deg*!dtor]
   obj          = [obj, info_all.object]
   day          = [day, info_all.day]
   runid        = [runid, replicate(run[irun], n_elements(info_all.day))]

    
endfor
 

;;========================================================================================
;;
;;
;;          PLOT ET FIT
;; 
;;========================================================================================
print,"===================================================="
print,""
print,"    PLOTS 'N' FITS  "
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
fname = outdir + 'NEFD_1mm'+suf

for irun=0, nrun-1 do fname=fname+'_'+run[irun]

outplot, file=fname, png=png, $
         ps=ps, xsize=ps_xsize, ysize=ps_ysize, charsize=ps_charsize, charthick=ps_charthick, thick=1.5


obs_tau1 = tau_1mm/sin(el)
obs_tau2 = tau_2mm/sin(el)

wind, 1, 1, /free, xsize=700, ysize=450
plot, obs_tau1[wrun], nefd_1mm[wrun], /nodata, yrange=[0, 150], xr=[0, 0.75], /xs, /ys, xtitle="tau / sin(el)", ytitle="NEFD (mJy.s^0.5)"



if nr9  gt 0 then oplot, obs_tau1[wr9], nefd_1mm[wr9],   psym=8, symsize=0.5, col=250
if nr10 gt 0 then oplot, obs_tau1[wr10], nefd_1mm[wr10], psym=6, symsize=0.5, col=200;, thick=2
if nr12 gt 0 then oplot, obs_tau1[wr12], nefd_1mm[wr12], psym=6, symsize=0.5, col=80;, thick=2
if nr14 gt 0 then oplot, obs_tau1[wr14], nefd_1mm[wr14], psym=6, symsize=0.5, col=50;, thick=2

leg = ''
col = ''
sym = ''

for irun = 0, nrun-1 do begin

;;    fit par bin 
;;--------------------------------------------------------------------

;; binning
;;-------------------------------------------

   wr = where(runid eq run[irun], nr)
   
   obs_tau = obs_tau1[wr]
   nefd    = nefd_1mm[wr]
   
   nbin = 9L
   obs_tau_bin = dblarr(nbin+1)
   obs_tau_bin[9] = 1.
   nscan_per_bin = n_elements(obs_tau)/nbin
   ind=indgen(nbin)*nscan_per_bin
   obs_tau_sort = obs_tau(sort(obs_tau))
   obs_tau_bin[0:nbin-1] = obs_tau_sort[ind]
   
   
   if run[irun] eq 'N2R9' then obs_tau_bin = [0.03, 0.065, 0.12, 0.19, 0.26, 0.33, 0.39, 0.45, 0.55, 0.75, 1.] 
   if run[irun] eq 'N2R12' then obs_tau_bin = [0.05, 0.25, 0.3, 0.335, 0.365, 0.4, 0.45, 0.55, 0.7]
   if run[irun] eq 'N2R14' then obs_tau_bin = [0.05, 0.25, 0.3, 0.335, 0.365, 0.4, 0.45, 0.55, 0.7]


   nbin = n_elements(obs_tau_bin)-1
   binsize     = (shift(obs_tau_bin, -1) - obs_tau_bin)/2.
   binsize     = binsize[0:nbin-1]
   bin_center  = obs_tau_bin[0:nbin-1]+binsize
   
   
   nefd_bin = dblarr(nbin)
   err_nefd_bin = dblarr(nbin)
   nmeas_bin = dblarr(nbin)+1.0d0
;; premier iteration pour avoir une idee de la moyenne
   for ib=0, nbin-1 do begin
      ww = where(obs_tau ge obs_tau_bin[ib] and obs_tau lt obs_tau_bin[ib+1], nn)
      if nn gt 0 then nefd_bin[ib] = median(nefd(ww))
      if nn eq 0 then nmeas_bin[ib] = 0.0d0
   endfor
;; deuxieme iteration pour enlever les outliers
   for ib=0, nbin-1 do if nmeas_bin[ib] gt 0. then nmeas_bin[ib] = n_elements(where(obs_tau ge obs_tau_bin[ib] and obs_tau lt obs_tau_bin[ib+1] and nefd lt 3.*nefd_bin[ib]))
   for ib=0, nbin-1 do if nmeas_bin[ib] gt 0. then nefd_bin[ib] = avg(nefd(where(obs_tau ge obs_tau_bin[ib] and obs_tau lt obs_tau_bin[ib+1] and nefd lt 3.*nefd_bin[ib])))
   for ib=0, nbin-1 do if nmeas_bin[ib] gt 0. then err_nefd_bin[ib] = stddev(nefd[where(obs_tau ge obs_tau_bin[ib] and obs_tau lt obs_tau_bin[ib+1] and nefd lt 3.*nefd_bin[ib])])
   
;; liste outliers
;;---------------------------------------------
   nefd_list_file = outdir+'NEFD_scan_list_'+run[irun]+'.save'
   restore, nefd_list_file
   scan_name = nefd_list
   for ib=0, nbin-1 do begin
      wout = where(obs_tau ge obs_tau_bin[ib] and obs_tau lt obs_tau_bin[ib+1] and nefd ge 3.*nefd_bin[ib], nout)
      if nout gt 0 then print, 'outliers 1mm: ', scan_name[wout], ', index : ',wout
      
;;20170224s43 20170224s44 20170224s45 20170224s46
;;20170226s429 20170226s433
;;20170227s394
;;20170228s76
   endfor
   

;; plot errorbar
;;------------------------------------------------------
   w0=where(nmeas_bin le 1, compl=wdef)
   err_nefd_bin[w0]=1d3
   err_nefd_bin[wdef] = err_nefd_bin[wdef] / sqrt(nmeas_bin[wdef])
   ;;oploterror, bin_center[wdef], nefd_bin[wdef], binsize[wdef], err_nefd_bin[wdef], psym=8, errcolor=200, color=200
   

;stop
   
;; fitting
;;-----------------------------------------------------
   covar    = 1
   perror   = 1
   bestnorm = 1
   parinfo = {fixed:0, limited:[0,0], limits:[0.D,0.D]}
   par     = 30.0d0
   p = mpfitfun('nefd_vs_opacity_fun', bin_center[0:5], nefd_bin[0:5], err_nefd_bin[0:5], par, yfit=yfit, covar=covar, parinfo=parinfo, perror=perror, bestnorm=bestnorm)
   
;;oplot, bin_center, yfit, psym=1, col=40
   
   ;obs_tau = dindgen(1000)/1000.
   ;oplot, obs_tau, p[0]*exp(obs_tau), col=colrun[irun]
    
   nefd_iram = p[0]*exp(tau1/sin(60.0d0*!dtor))


;; methode Juan
;;---------------------------------------------------------     

   w= where(obs_tau gt 0.0 and obs_tau le 0.5, nn)
   nefd_0 = median(nefd[w]/exp(obs_tau[w]))
   
   nefd_iram = nefd_0*exp(tau1/sin(60.0d0*!dtor))
   
   obs_tau = dindgen(1000)/1000.
   oplot, obs_tau, nefd_0*exp(obs_tau), col=colrun[irun]
   
   leg = [leg, run[irun]+' measures']
   ;;leg = [leg, 'NEFD_0 (mJy.s^0.5) = '+strtrim(string(p(0),
   ;;format='(f6.2)'),2), 'NEFD_iram (mJy.s^0.5) =
   ;;'+strtrim(string(nefd_iram, format='(f6.2)'),2)]
   leg = [leg, 'NEFD_0 (mJy.s^0.5) = '+strtrim(string(nefd_0, format='(f6.2)'),2), 'NEFD_iram (mJy.s^0.5) = '+strtrim(string(nefd_iram, format='(f6.2)'),2)]
   col = [col, colrun[irun], colrun[irun], colrun[irun]]
   sym = [sym, symrun[irun], 0, 0]
endfor

legendastro, leg[1:*] , textcolor=col[1:*], color=col[1:*], psym=sym[1:*], box=0, pos=[0.05,140], charsize=0.9

if png gt 0 then outplot, /close


;;;    2mm
;;;____________________________________________________________________
print,""
print," 2mm"
print,"---------------------------------------------------"
;;; plot
;;;---------------------------------------------------------------------
fname = outdir + 'NEFD_2mm'+suf
for irun=0, nrun-1 do fname=fname+'_'+run[irun]


outplot, file=fname, png=png, $
         ps=ps, xsize=ps_xsize, ysize=ps_ysize, charsize=ps_charsize, charthick=ps_charthick, thick=1.5

wind, 1, 1, /free, xsize=700, ysize=450
plot, obs_tau2[wrun], nefd_2mm[wrun], /nodata, yrange=[0, 45], xr=[0, 0.75], /xs, /ys, xtitle="tau / sin(el)", ytitle="NEFD (mJy.s^0.5)"

if nr9  gt 0 then oplot, obs_tau2[wr9], nefd_2mm[wr9],   psym=8, symsize=0.5, col=250
if nr10 gt 0 then oplot, obs_tau2[wr10], nefd_2mm[wr10], psym=6, symsize=0.5, col=200
if nr12 gt 0 then oplot, obs_tau2[wr12], nefd_2mm[wr12], psym=6, symsize=0.5, col=80
if nr14 gt 0 then oplot, obs_tau2[wr14], nefd_2mm[wr14], psym=6, symsize=0.5, col=50

leg = ''
col = ''
sym = ''

for irun = 0, nrun-1 do begin
;;    fit par bin 
;;--------------------------------------------------------------------

;; binning
;;-------------------------------------------
   wr = where(runid eq run[irun], nr)
   
   obs_tau = obs_tau2[wr]
   nefd    = nefd_2mm[wr]

nbin = 9L
obs_tau_bin = dblarr(nbin+1)
obs_tau_bin[9] = 1.
nscan_per_bin = n_elements(obs_tau)/nbin
ind=indgen(nbin)*nscan_per_bin
obs_tau_sort = obs_tau(sort(obs_tau))
obs_tau_bin[0:nbin-1] = obs_tau_sort[ind]

if run[irun] eq 'N2R9' then obs_tau_bin = [0.03, 0.07, 0.11, 0.15, 0.185, 0.22, 0.27, 0.35, 0.45, 0.60, 1.]
if run[irun] eq 'N2R12' then obs_tau_bin = [0.06, 0.16, 0.185, 0.2, 0.23, 0.26, 0.29, 0.35, 0.45]
if run[irun] eq 'N2R14' then obs_tau_bin = [0.06, 0.16, 0.185, 0.2, 0.23, 0.26, 0.29, 0.35, 0.45]

;stop

nbin = n_elements(obs_tau_bin)-1
binsize     = (shift(obs_tau_bin, -1) - obs_tau_bin)/2.
binsize     = binsize[0:nbin-1]
bin_center     = obs_tau_bin[0:nbin-1]+binsize


nefd_bin = dblarr(nbin)
err_nefd_bin = dblarr(nbin)
nmeas_bin = dblarr(nbin)+1.0d0
;; premier iteration pour avoir une idee de la moyenne
for ib=0, nbin-1 do begin
   ww = where(obs_tau ge obs_tau_bin[ib] and obs_tau lt obs_tau_bin[ib+1], nn)
   if nn gt 0 then nefd_bin[ib] = median(nefd(ww))
   if nn eq 0 then nmeas_bin[ib] = 0.0d0
endfor
;; deuxieme iteration pour enlever les outliers
for ib=0, nbin-1 do if nmeas_bin[ib] gt 0. then nmeas_bin[ib] = n_elements(where(obs_tau ge obs_tau_bin[ib] and obs_tau lt obs_tau_bin[ib+1] and nefd  lt 3.*nefd_bin[ib]))
for ib=0, nbin-1 do if nmeas_bin[ib] gt 0. then nefd_bin[ib] = avg(nefd(where(obs_tau ge obs_tau_bin[ib] and obs_tau lt obs_tau_bin[ib+1] and nefd lt 3.*nefd_bin[ib])))
for ib=0, nbin-1 do if nmeas_bin[ib] gt 0. then err_nefd_bin[ib] = stddev(nefd[where(obs_tau ge obs_tau_bin[ib] and obs_tau lt obs_tau_bin[ib+1] and nefd lt 3.*nefd_bin[ib])])

;; plot errorbar
;;------------------------------------------------------
w0=where(nmeas_bin le 1, compl=wdef)
err_nefd_bin[w0]=1d3
err_nefd_bin[wdef] = err_nefd_bin[wdef] / sqrt(nmeas_bin[wdef])

;oploterror, bin_center[wdef], nefd_bin[wdef], binsize[wdef], err_nefd_bin[wdef], psym=8, errcolor=200, color=200

;; fitting
;;-----------------------------------------------------
covar    = 1
perror   = 1
bestnorm = 1
parinfo = {fixed:0, limited:[0,0], limits:[0.D,0.D]}
par     = 10.0d0
p = mpfitfun('nefd_vs_opacity_fun', bin_center[0:5], nefd_bin[0:5], err_nefd_bin[0:5], par, yfit=yfit, covar=covar, parinfo=parinfo, perror=perror, bestnorm=bestnorm)

;;oplot, bin_center, yfit, psym=1, col=40

;obs_tau = dindgen(1000)/1000.
;oplot, obs_tau, p[0]*exp(obs_tau), col=colrun[irun]

nefd_iram = p[0]*exp(tau2/sin(60.0d0*!dtor))


;; methode Juan
;;---------------------------------------------------------     

w = where(obs_tau gt 0.0 and obs_tau le 0.5, nn)
nefd_0 = median(nefd[w]/exp(obs_tau[w]))
nefd_iram = nefd_0*exp(tau2/sin(60.0d0*!dtor))

obs_tau = dindgen(1000)/1000.
oplot, obs_tau, nefd_0*exp(obs_tau), col=colrun[irun]

leg = [leg, run[irun]+' measures']
;;leg = [leg, 'NEFD_0 (mJy.s^0.5) = '+strtrim(string(p(0), format='(f6.2)'),2), 'NEFD_iram (mJy.s^0.5) = '+strtrim(string(nefd_iram, format='(f6.2)'),2)]

leg = [leg, 'NEFD_0 (mJy.s^0.5) = '+strtrim(string(nefd_0, format='(f6.2)'),2), 'NEFD_iram (mJy.s^0.5) = '+strtrim(string(nefd_iram, format='(f6.2)'),2)]
col = [col, colrun[irun], colrun[irun], colrun[irun]]
sym = [sym, symrun[irun], 0, 0]

endfor

legendastro, leg[1:*], textcolor=col[1:*], color=col[1:*], psym=sym[1:*], box=0, pos=[0.05,40], charsize=0.9

if png gt 0 then outplot, /close



stop










;; day-to-day
;;----------------------------------------------
fname = outdir + 'NEFD_daytoday_'
for irun=0, nrun-1 do fname=fname+'_'+run[irun]
outplot, file=fname, png=png, $
         ps=ps, xsize=ps_xsize, ysize=ps_ysize, charsize=ps_charsize, charthick=ps_charthick, thick=ps_thick

list_day = day[UNIQ(day, SORT(day))]
nday = n_elements(list_day)
if nday le 8 then begin
   coltab = [0, 80, 30, 150, 80, 200, 50, 250]
   symtab = intarr(8)+8
   symsize = intarr(8)+0.5
endif else begin
   coltab = [0, 30, 50, 80, 100, 150, 200, 250, 0, 30, 50, 80, 100, 150, 200, 250, 0, 30, 50, 80, 100, 150, 200, 250, 0, 30, 50, 80, 100, 150, 200, 250]
   symtab = [intarr(8)+8, intarr(8)+4, intarr(8)+6, intarr(8)+5]
   symsize = [intarr(8)+0.5, intarr(8)+1, intarr(8)+1, intarr(8)+1]
endelse 


obs_tau1 = tau_1mm/sin(el)
obs_tau2 = tau_2mm/sin(el)
w1=where(el gt 0.0)
plot, obs_tau1[w1], nefd_1mm[w1], /nodata, yrange=[0, 100], xr=[0, 0.8], /xs, /ys, xtitle="tau / sin(el)", ytitle="NEFD (mJy.s^0.5)"

for i=0, nday-2 do begin
   w = where(day ge list_day[i] and day lt list_day[i+1], n)
   print, "pour le ", list_day[i], " nb scans = ", n
   if n gt 0 then oplot, obs_tau1[w], nefd_1mm[w], psym=symtab[i+1], symsize=symsize[i+1], col=coltab[i+1]
   if n gt 0 then oplot, obs_tau2[w], nefd_2mm[w], psym=symtab[i+1], symsize=symsize[i+1], col=coltab[i+1]
   legendastro, [strtrim(list_day[i])], col=[coltab[i+1]], psym = [symtab[i+1]], box=0, /trad, textcol=[coltab[i+1]], pos=[0.05, (80. - i*4.)], charsize=0.7
   print, ''
   print, nefd_1mm[w]
   print, ''
   print, '-------'
endfor

obs_tau = dindgen(1000)/1000.
oplot, obs_tau, 8.5*exp(obs_tau), col=50
oplot, obs_tau, 30.*exp(obs_tau), col=250


legendastro, ['NEFD(tau=0) = 30 mJy.s^0.5', 'NEFD(tau=0) = 8.5 mJy.s^0.5' ], textcolor=[250,  50], box=0, pos=[0.05,90], charsize=0.7

if png gt 0 then outplot, /close

stop

;; source-to-source
;;----------------------------------------------
wind, 1, 1, /free, /large
fname = outdir + 'NEFD_persource_'
for irun=0, nrun-1 do fname=fname+'_'+run[irun]
outplot, file=fname, png=png, $
         ps=ps, xsize=ps_xsize, ysize=ps_ysize, charsize=ps_charsize, charthick=ps_charthick, thick=ps_thick

list_source = obj[UNIQ(obj, SORT(obj))]
;;list_source = ['HLS091828', 'Pluto', 'BODY Ceres', 'BODY Vesta']
nsource = n_elements(list_source)
if nsource le 8 then begin
   coltab = [80, 50, 200, 150, 250]
   symtab = intarr(8)+8
   symsize = intarr(8)+0.5
endif else begin
   coltab = [0, 30, 50, 80, 100, 150, 200, 250, 0, 30, 50, 80, 100, 150, 200, 250, 0, 30, 50, 80, 100, 150, 200, 250, 0, 30, 50, 80, 100, 150, 200, 250]
   symtab = [intarr(8)+8, intarr(8)+4, intarr(8)+6, intarr(8)+5]
   symsize = [intarr(8)+0.5, intarr(8)+1, intarr(8)+1, intarr(8)+1]
endelse 


obs_tau1 = tau_1mm/sin(el)
obs_tau2 = tau_2mm/sin(el)
w1=where(el gt 0.0)
plot, obs_tau1[w1], nefd_1mm[w1], /nodata, yrange=[0, 100], xr=[0, 0.8], /xs, /ys, xtitle="tau / sin(el)", ytitle="NEFD (mJy.s^0.5)"

for i=0, nsource-1 do begin
   w = where(obj eq list_source[i], n)
   if n gt 0 then oplot, obs_tau1[w], nefd_1mm[w], psym=symtab[i], symsize=0.5, col=coltab[i]
   if n gt 0 then oplot, obs_tau2[w], nefd_2mm[w], psym=symtab[i], symsize=0.5, col=coltab[i]
   legendastro, [strtrim(list_source[i])], col=[coltab[i]], psym = [symtab[i]], box=0, /trad, textcol=[coltab[i]], pos=[0.05, (80. - i*4.)], charsize=0.7
endfor

                                ;oplot, obs_tau1[w1], nefd_a1[w1]*sqrt(eta_a1[w1])/sqrt(2.), psym=8, symsize=0.5, col=200
                                ;oplot, obs_tau1[w1], nefd_a3[w1]*sqrt(eta_a3[w1])/sqrt(2.), psym=8, symsize=0.5, col=200

obs_tau = dindgen(1000)/1000.
oplot, obs_tau, 8.5*exp(obs_tau), col=50
                                ;oplot, obs_tau, 42.*exp(obs_tau), col=200
                                ;oplot, obs_tau, 35.*exp(obs_tau), col=190
oplot, obs_tau, 30.*exp(obs_tau), col=250
                                ;oplot, obs_tau, 32.*exp(obs_tau), col=250
                                ;oplot, obs_tau, 40.*exp(obs_tau), col=250
                                ;oplot, obs_tau, 55.*exp(obs_tau), col=0
                                ;oplot, obs_tau, 64.*exp(obs_tau), col=0
                                ;oplot, obs_tau, 30.*exp(obs_tau)/exp(0.1/sin(60.*!dtor)), col=150
                                ;oplot, obs_tau, 15.*exp(obs_tau)/exp(0.1/sin(60.*!dtor)), col=80

legendastro, ['NEFD(tau=0) = 30 mJy.s^0.5', 'NEFD(tau=0) = 8.5 mJy.s^0.5' ], textcolor=[250,  50], box=0, pos=[0.05,90], charsize=0.7

if png gt 0 then outplot, /close




stop





end
