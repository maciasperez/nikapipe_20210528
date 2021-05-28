;
;
;    example script for monitoring zenith opacity measurements using NIKA2 skydip
;
;    LP, Feb, 15, 2017
;    based on Labtools/LP/scripts/n2r7/check_opacity.pro
;
;______________________________________________________________________________________

pro tau_skydip_monitoring, png=png, nostop=nostop
  
  ;;run = 'N2R6'
  ;;run = 'N2R9'
  ;;run = 'N2R10'
  run = 'N2R12'
  ;;run = 'N2R14'

  
;; reading estimates
;;------------------------------------------------------------
;; read the tau estimates from the Data Base logbook file
;; logbook_file = !nika.pipeline_dir+'/Datamanage/Logbook/Log_Iram_tel_N2R9_v1.save'
  use_logbook_file = 1


;; if the Logbook file is unavailable, choose one of the 3 options below:
  
;;  nika2a_rsync_dir = '/mnt/data/NIKA2Team/observer/Plots/Run15'
;;  nika2a_rsync_dir = '/mnt/data/NIKA2Team/observer/Plots/Run22'

  nika2a_rsync_dir = '/mnt/data/NIKA2Team/NP/Plots_new'
  
;; read the tau estimates from result.save files
;; result_file = nika2a_rsync_dir+'v_1/*/results.save'
  use_results_save = 0
  
;; read the tau estimates from the logbook scan directories
;; logbook_file = !nika.plot_dir+'/Logbook/Scans/'
  use_logbook_scan = 0
  
;; reprocess each scan to retrieve tau estimates [not implemented yet]
  reprocess   = 0
;;------------------------------------------------------------
  
  
;; ATM model expectations
;; apply a global shift to NIKA2 bandpass frequency at 2mm [in GHz]
;;  bp_shift = 1.5
  bp_shift = 0
  
;;===================================================================================
;;
;;   no further edition needed......
;;  
;;===================================================================================

  ;; Dark scan list
  case 1 of
     run eq 'N2R9': darklist = ['20170223s16', '20170223s17', '20170224s187', '20170224s190', '20170224s191']
     run eq 'N2R10': darklist = ['20170414s156', '20170414s157',  '20170419s171',  '20170419s173', '20170419s174', '20170419s175','20170419s176','20170421s193','20170421s194',  '20170421s195'] 
     else: darklist = ''
  endcase
     

  
  if use_results_save gt 0 then begin
     
     spawn, "ls -d "+nika2a_rsync_dir+"/v_1/*", dir_list
     nscan = n_elements(dir_list)

     ;; Restrict to Run9 scans
     dir_list = dir_list[ where( strmid( file_basename(dir_list), 0, 6) eq '201702')]
     nscan = n_elements(dir_list)
     
     ;; init
     el_deg = 0.
     day    = ''
     num    = 0.
     tau1   = 0.
     tau2   = 0.
     tau225 = 0.
     nfiles = 0
     for isc = 0, nscan-1 do begin
        resfile = dir_list[isc]+ '/results.save'
        if file_test(resfile) then begin
           restore, resfile
           if strupcase(info1.obs_type) eq 'ONTHEFLYMAP' then begin
              el_deg   = [el_deg, info1.elev]
              day      = [day,    info1.day ]
              num      = [num,    info1.scan_num]
              tau1     = [tau1,   info1.result_tau_1mm ]
              tau2     = [tau2,   info1.result_tau_2mm ]
              tau225   = [tau225, info1.tau225]
              if nfiles eq 0 then available_scans = file_basename(dir_list[isc]) $
              else available_scans = [available_scans, file_basename(dir_list[isc])]
              nfiles++
           endif        
        endif else print, "no results.save for scan = ", file_basename(dir_list[isc])
     endfor
     el_deg = el_deg[1:*]
     day    = day[1:*]
     num    = num[1:*]
     tau1   = tau1[1:*]
     tau2   = tau2[1:*]
     tau225 = tau225[1:*]
     
     list_day = day[UNIQ(day, SORT(day))]
     nday = n_elements(list_day)
     date = num*5.  ;; placeholder for the MJD (assuming average scan duration of 5 min.)
     for id = 0, nday-1 do begin
        w=where(day ge list_day[id], nn)
        if nn ne 0 then date[w] = date[w]+1440.
     endfor
     
     mjd = date
;     print, "availabe_scans: "
;     print, "'"+strtrim(available_scans,2)+"', "
;     stop
     
  endif
  
  
  if use_logbook_scan gt 0 then begin
     
     spawn, "ls -d "+nika2a_rsync_dir+"/Logbook/Scans/*", dir_list
     nscan = n_elements(dir_list)
     
     ;; init
     el_deg = 0.
     day    = ''
     mjd    = 0.
     tau1   = 0.
     tau2   = 0.
     tau225 = 0.
     for isc = 0, nscan-1 do begin
        logfile = dir_list[isc]+ '/log_info.save'
        if file_test(logfile) then begin
           restore, logfile
           tags = tag_names( log_info)
           if strupcase(log_info.scan_type) eq 'ONTHEFLYMAP' then begin
              el_deg   = [el_deg, log_info.mean_elevation]
              day      = [day,    log_info.day ]
              ut       = [mjd,    log_info.ut ]
              tau1     = [tau1,   log_info.tau_1mm ]
              tau2     = [tau2,   log_info.tau_2mm ]
              ;;tau225   = [tau225, log_info.tau_225]
           endif
        endif else print, "no log_info.save for scan = ", file_basename(dir_list[isc])
     endfor
     el_deg = el_deg[1:*]
     day    = day[1:*]
     mjd    = mjd[1:*]
     tau1   = tau1[1:*]
     tau2   = tau2[1:*]
     tau225 = tau225[1:*]
     
  endif
  
  
  if use_logbook_file gt 0 then begin
     
     case 1 of
        run eq 'N2R6': logfile = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R6_v1.save"
        run eq 'N2R9': logfile = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R9_v1.save"
        run eq 'N2R10': logfile = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R10_v2.save"
        run eq 'N2R12': logfile = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R12_v1.save"
        run eq 'N2R14': logfile = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R14_v2.save"
     endcase
     
     restore, logfile, /v
     
     fday=min(scan.day)
     lday=max(scan.day)
     print, "data from "+fday+" to "+lday
     wsc=where(scan.day ge fday and scan.day le lday and $
               strupcase(scan.obstype) eq 'ONTHEFLYMAP' and $
               scan.comment eq 'none', nsc)
     print, "number of scans = ", nsc
     
     scan_str = scan[wsc]
     el_deg   = scan_str.el_deg
     day      = scan_str.day
     num      = scan_str.scannum
     mjd      = scan_str.mjd
     tau1     = scan_str.tau1mm
     tau2     = scan_str.tau2mm
     tau225   = scan_str.tiptau225ghz
     date     = scan_str.date
     
  endif
  
  
  if reprocess gt 0 then begin
     print, "no reprocessing implemented yet"
  endif
  
  
  nsc = n_elements(tau1)
  
  ind_day = UNIQ(day, SORT(day))
  list_day = day[ind_day]
  nday = n_elements(list_day)

;; discard dark scans
  ndark = n_elements(darklist)
  flagdark = intarr(nsc)+1
  if ndark gt 0 then begin
     for idark=0, ndark-1 do begin
        darkid=darklist(idark)
        w=where(day eq strmid(darkid,0, 8) and (num eq strmid(darkid, 9, strlen(darkid)-9)), nn)
        if nn gt 0 then flagdark[w]=0 else print, "[FYI] dark scan ", darkid, " not found"
     endfor
  endif



;;
;;  zenith opacities vs MJD
;;
;;__________________________________________________________________________________________
  print, ''
  print, 'opacity vs obsdate'
 
  outplot, file='opacity_vs_mjd_run'+run, png=png
  
  plot, mjd-min(mjd), fltarr(nsc), ytitle="zenith opacity (tau)", xtitle="MJD - MJD("+strtrim(day(0))+")", /ys, /xs, /nodata
  oplot, mjd-min(mjd), tau1, psym=8, col=250, symsize=1
  oplot, mjd-min(mjd), tau2, psym=8, col=60, symsize=1
  oplot, mjd-min(mjd), tau225, psym=7, col=0, symsize=1
  legendastro, ['NIKA2 tau@1mm', 'NIKA2 tau@2mm', 'tau@225GHz'], col=[250, 60, 0], psym = [8, 8, 7], box=0, /trad, textcol=[250, 60, 0]
  outplot, /close
  
;; candidat dark test
;;  wdark = where(tau1 lt 1d-6 or tau2 lt 1d-6, ndark, compl=won, ncompl=nscans)
  wdark = where(flagdark lt 1, ndark, compl=won, ncompl=nscans)
  if ndark ne 0 then begin
     oplot, mjd(wdark)-min(mjd), tau1(wdark), psym=8, col=255, symsize=0.9
     oplot, mjd(wdark)-min(mjd), tau2(wdark), psym=8, col=255, symsize=0.9
  endif

  print, ''
  print, '.c for opacity vs scan index'
  if not keyword_set(nostop) then stop
  
  outplot, file='opacity_vs_index'+run, png=png
  
  ind = indgen(nsc)
  plot, ind, fltarr(nsc), yr=[0, 2.], xr=[-50, nsc+50], ytitle="zenith opacity (tau)", xtitle="scan index", /ys, /xs, /nodata
  oplot, ind, tau1, psym=8, col=250, symsize=0.35
  oplot, ind, tau2, psym=8, col=60, symsize=0.35
  oplot, ind, tau225, psym=7, col=0, symsize=0.5
  legendastro, ['NIKA2 tau@1mm', 'NIKA2 tau@2mm', 'tau@225GHz'], col=[250, 60, 0], psym = [8, 8, 7], box=0, /trad, textcol=[250, 60, 0]
  
  ;; candidat dark test
  ;;wdark = where(tau1 lt 1d-6 or tau2 lt 1d-6, ndark, compl=won, ncompl=nscans)
  if ndark ne 0 then begin
     oplot, ind(wdark), tau1(wdark), psym=8, col=255, symsize=0.9
     oplot, ind(wdark), tau2(wdark), psym=8, col=255, symsize=0.9
  endif
  
  ;; day label
  for iday = 0, nday-2 do begin
     vline, ind[ind_day[iday]], /data, /noerase, range=[0, 1.6]
     xyouts, ind[ind_day[iday]]+50, 1.2, strtrim(list_day[iday+1],2), chars=0.9, col=0, orientation=90
  endfor

  outplot, /close
  
  ;; les deconnants
  wdeco = where(tau1(won) lt 1d-6 or tau2(won) lt 1d-6, ndeco)

  deco_list = day(won(wdeco))+'s'+strtrim(string(num(won(wdeco)), format='(i3)'), 2)
  

  print, ''
  print, 'print, deco_list ;; for the list of scans at null opacity '
  
print, ''
print, '.c for the scatter plots'

if not keyword_set(nostop) then stop

;;
;;  scatter plots
;;
;;__________________________________________________________________________________________

;; ATM model 2017 (Marco De Petris)
;nostop = 1
old_a2 = 0
;; average zenith opacity
atm_model_mdp, atm_tau1, atm_tau2, atm_tau3, atm_tau225, /tau225, old_a2=old_a2, /nostop, /approx
;; shifting the BP
atm_model_mdp, atm_tau1, atm_tau2_shift, atm_tau3,  old_a2=old_a2, /nostop, bpshift=bp_shift, /approx
;; "skydip" opacity
atm_model_mdp, atm_tau1_dip, atm_tau2_dip, atm_tau3_dip, atm_tau225_dip, /tau225, old_a2=old_a2, /nostop

;;atm_tau1 = 0.5*(atm_tau1+atm_tau3)

leg = 'measures'
col = 50
sym = 8

outplot, file='opacity_tau1_tau2_scatterplot_run'+run+'_newATM_BP2', png=png
plot, tau1, tau2, ytitle="zenith opacity at 2mm", xtitle="zenith opacity at 1mm", /ys, /xs, /nodata, xr=[0, 0.8], yr=[0,0.6]
oplot, tau1, tau2, psym=8, col=70, symsize=0.5
oplot, tau1[won], tau2[won], psym=8, col=50, symsize=0.5

fit = linfit(tau1[won[where(tau1 gt 0.05 and tau1 lt 0.5)]], tau2[won[where(tau1 gt 0.05 and tau1 lt 0.5)]], sigma=sigma)

oplot, atm_tau1, atm_tau2, col=250, linestyle=2
oplot, atm_tau3, atm_tau2, col=200, linestyle=2
oplot, atm_tau1_dip, atm_tau2_dip, col=250
oplot, atm_tau3_dip, atm_tau2_dip, col=200

atm_fit_12 = linfit(atm_tau1, atm_tau2)
atm_fit_32 = linfit(atm_tau3, atm_tau2)

atm_fit_12_dip = linfit(atm_tau1_dip, atm_tau2_dip)
atm_fit_32_dip = linfit(atm_tau3_dip, atm_tau2_dip)

leg = [leg, 'ATM model, A2 vs A1', 'ATM model, A2 vs A3', 'ATM model approx, A2 vs A1', 'ATM model approx, A2 vs A3']
col = [col, 250, 200, 250, 200]
sym = [sym, 0, 0, 0, 0]
line = [0, 0, 0, 2, 2]

if bp_shift ne 0. then begin
   oplot, atm_tau1, atm_tau2_shift, col=150, thick=2
   oplot, atm_tau3, atm_tau2_shift, col=110, thick=2
   leg = [leg, 'ATM model, A1, BP freq shift', 'ATM model, A3, BP freq shift']
   col = [col, 150, 110]
   sym = [sym, 0, 0]
   line = [line, 0, 0]
endif else begin
   x= indgen(100)/100.
   oplot, x, fit[1]*x +fit[0], col=80
   leg = [leg, 'linfit: slope = '+strtrim(string(fit[1], format='(f6.3)'))+', norm = '+strtrim(string(fit[0], format='(f6.3)'))]
   col = [col, 80]
   sym = [sym, 0]
   line = [line, 0]
endelse

legendastro, leg, col=col, psym = sym, linestyle=line, box=0, /trad, textcol=col
outplot, /close

print, ''
print, "Zenith opacity monitoring...."
print, ''
print, 'Linear fit on measurements: '
print,'     tau2mm = '+strtrim(string(fit[1], format='(f6.3)'))+' tau1mm + '+strtrim(string(fit[0], format='(f6.3)'))
print, ''
print, 'Expectation from ATM model: '
print, '    tau2 = '+strtrim(string(atm_fit_12[1], format='(f6.3)'))+' tau1 + '+strtrim(string(atm_fit_12[0], format='(f6.3)'))
print, '    tau2 = '+strtrim(string(atm_fit_32[1], format='(f6.3)'))+' tau3 + '+strtrim(string(atm_fit_32[0], format='(f6.3)'))
print, '...tau_skydip: '
print, '    tau2_dip = '+strtrim(string(atm_fit_12_dip[1], format='(f6.3)'))+' tau1_dip + '+strtrim(string(atm_fit_12[0], format='(f6.3)'))
print, '    tau2_dip = '+strtrim(string(atm_fit_32_dip[1], format='(f6.3)'))+' tau3_dip + '+strtrim(string(atm_fit_32_dip[0], format='(f6.3)'))

print, ''
print, '.c for correlation plot with the taumeter'
 if not keyword_set(nostop) then stop


leg = 'measures'
col = 50
sym = 8

;!p.multi=[0, 2, 1]
;window, 1,  xsize = 1000, ysize =  500
outplot, file='opacity_tau1_scatterplot_run'+run+'_newATM_BP2', png=png
plot, tau225, tau1, ytitle="zenith opacity at 1mm", $
      xtitle="zenith opacity at 225GHz", /ys, /xs, /nodata, xr=[0, 0.8], yr=[0,1.]
oplot, tau225, tau1, psym=8, col=70, symsize=0.5
oplot, tau225[won], tau1[won], psym=8, col=50, symsize=0.5

fit = linfit(tau225[won], tau1[won])

oplot, atm_tau225, atm_tau1, col=250
oplot, atm_tau225, atm_tau3, col=200
atm_fit_12 = linfit(atm_tau225, atm_tau1)
atm_fit_32 = linfit(atm_tau225, atm_tau3)
leg = [leg, 'ATM model, A225-A1', 'ATM model, A225-A3']
col = [col, 250, 200]
sym = [sym, 0, 0]
x= indgen(100)/100.
oplot, x, fit[1]*x +fit[0], col=170
oplot, x, avg(tau1[won]/tau225[won])*x
leg = [leg, 'linfit: slope = '+strtrim(string(fit[1], format='(f6.3)'))+$
       ', norm = '+strtrim(string(fit[0], format='(f6.3)')), $
       'avg(tau1/tau225): '+string(avg(tau1[won]/tau225[won]),form='(F5.2)')]
col = [col, 170, 0]
sym = [sym, 0, 0]
legendastro, leg, col=col, psym = sym, box=0,  textcol=col, charsize=0.8

print, ''
print, "Zenith opacity monitoring...."
print, ''
print, 'Linear fit on measurements: '
print, '    tau1mm = '+strtrim(string(fit[1], format='(f6.3)'))+' tau225 + '+strtrim(string(fit[0], format='(f6.3)'))
print, ''
print, 'Expectation from ATM model: '
print, '    tau1 = '+strtrim(string(atm_fit_12[1], format='(f6.3)'))+' tau225 + '+strtrim(string(atm_fit_12[0], format='(f6.3)'))
print, '    tau3 = '+strtrim(string(atm_fit_32[1], format='(f6.3)'))+' tau225 + '+strtrim(string(atm_fit_32[0], format='(f6.3)'))


;;-----------------------------------------------------------------------------------------
if not keyword_set(nostop) then stop

leg = 'measures'
col = 50
sym = 8

outplot, file='opacity_tau2_scatterplot_run'+run+'_newATM_BP2_freqshift', png=png
plot, tau225, tau2, ytitle="zenith opacity at 2mm", xtitle="zenith opacity at 225GHz", /ys, /xs, /nodata, $
      xr=[0, 0.8], yr=[0,0.6]
oplot, tau225, tau2, psym=8, col=70, symsize=0.5
oplot, tau225[won], tau2[won], psym=8, col=50, symsize=0.5
fit = linfit(tau225[won], tau2[won])
oplot, atm_tau225, atm_tau2, col=250
atm_fit = linfit(atm_tau225, atm_tau2)
leg = [leg, 'ATM model']
col = [col, 250]
sym = [sym, 0]

if bp_shift gt 0. then begin
   oplot, atm_tau225, atm_tau2_shift, col=150, thick=2
   leg = [leg, 'ATM model, BP freq shift']
   col = [col, 150]
   sym = [sym, 0]
endif; else begin
   x= indgen(100)/100.
   oplot, x, fit[1]*x +fit[0], col=70
   oplot, x, avg(tau2[won]/tau225[won])*x
   leg = [leg, 'linfit: slope = '+strtrim(string(fit[1], format='(f6.3)'))+$
          ', norm = '+strtrim(string(fit[0], format='(f6.3)')), $
          'avg(tau2/tau225): '+string(avg(tau2[won]/tau225[won]),form='(F5.2)')]
   col = [col, 70,0]
   sym = [sym, 0,0]
;endelse

legendastro, leg, col=col, psym = sym, box=0,  textcol=col, charsize=0.8
outplot, /close


print, ''
print, "Zenith opacity monitoring...."
print, ''
print, 'Linear fit on measurements: '
print, '    tau2mm = '+strtrim(string(fit[1], format='(f6.3)'))+' tau225 + '+strtrim(string(fit[0], format='(f6.3)'))
print, ''
print, 'Expectation from ATM model: '
print, '    tau2 = '+strtrim(string(atm_fit_12[1], format='(f6.3)'))+' tau225 + '+strtrim(string(atm_fit_12[0], format='(f6.3)'))

!p.multi=0

;;----------------------------------------------------------------------------------------------------

;;
;;  tau1-tau2 ratio plots
;;
;;__________________________________________________________________________________________

print, ''
print, '.c for new plot of the opacity ratios'
if not keyword_set(nostop) then stop


est_r = tau2[won]/tau1[won]
atm_r = atm_tau2_dip/atm_tau1_dip

rescale = mean(est_r[where(abs(tau1-0.2) le 0.05)])-mean(atm_r[where(abs(atm_tau1_dip-0.2) le 0.05)])


outplot, file='opacity_tau1_tau2_ratio'+run, png=png
plot, tau1, tau2/tau1, ytitle="zenith opacity 2mm-to-1mm ratio", xtitle="zenith opacity at 1mm", /ys, /xs, /nodata, xr=[0, 0.8], yr=[0.4,1.3]
;;oplot, tau1, tau2/tau1, psym=8, col=70, symsize=0.5
oplot, tau1[won], tau2[won]/tau1[won], psym=8, col=50, symsize=0.5

;oplot, atm_tau1, atm_tau2/atm_tau1, col=250
;oplot, atm_tau1, atm_tau2/atm_tau3, col=200

oplot, atm_tau1_dip, atm_tau2_dip/atm_tau1_dip, col=250, thick=3
oplot, atm_tau1_dip, atm_tau2_dip/atm_tau3_dip, col=200, thick=3


oplot, atm_tau1_dip, atm_tau2_dip/atm_tau1_dip+rescale, col=250, linestyle=2, thick=3
oplot, atm_tau1_dip, atm_tau2_dip/atm_tau3_dip+rescale, col=200, linestyle=2, thick=3


leg = ['measures', 'ATM model: A2/A1', 'ATM model: A2/A3']
col = [50, 250, 200]
sym = [8, 0, 0]

legendastro, leg, col=col, psym = sym, box=0, /trad, textcol=col, pos=[0.35, 1.2]
outplot, /close

;;---------------------------------------------------------------------------------------

print, ''
print, '.c for ratios to the taumeter'
if not keyword_set(nostop) then stop

leg = 'measures'
col = 50
sym = 8

;!p.multi=[0, 2, 1]
;window, 1,  xsize = 1000, ysize =  500

outplot, file='opacity_tau1_tau225_ratio'+run, png=png
plot, tau1, tau1/tau225, ytitle="zenith opacity 260-to-225 ratio", $
      xtitle="zenith opacity at 1mm", /ys, /xs, /nodata, xr=[0, 0.8], yr=[0,3.]
;oplot, tau1, tau1/tau225, psym=8, col=70, symsize=0.5
oplot, tau1[won], tau1[won]/tau225[won], psym=8, col=50, symsize=0.5
;fit = linfit(tau225[won], tau1[won])
oplot, atm_tau1_dip, atm_tau1_dip/atm_tau225_dip, col=250, thick=2
oplot, atm_tau1_dip, atm_tau3_dip/atm_tau225_dip, col=200, thick=2

;oplot, atm_tau1, atm_tau1/atm_tau225, col=250, thick=2, linestyle=2
;oplot, atm_tau1, atm_tau3/atm_tau225, col=200, thick=2, linestyle=2

atm_fit_12 = linfit(atm_tau225_dip, atm_tau1_dip)
atm_fit_32 = linfit(atm_tau225_dip, atm_tau3_dip)
leg = [leg, 'ATM model, A1/225', 'ATM model, A3/225']
col = [col, 250, 200]
sym = [sym, 0, 0]
x= indgen(100)/100.
;;oplot, x, fit[1]*x +fit[0], col=170
;oplot, x, median(tau1[won]/tau225[won])*x, col=80, thick=2
;;leg = [leg, 'linfit: slope = '+strtrim(string(fit[1], format='(f6.3)'))+$
;;       ', norm = '+strtrim(string(fit[0], format='(f6.3)')), $
;;       'avg(tau1/tau225):
;'+string(avg(tau1[won]/tau225[won]),form='(F5.2)')]
;leg = [leg, 'slope = '+strtrim(string(median(tau1[won]/tau225[won]), format='(f6.2)'),2)]
;col = [col, 80]
;sym = [sym, 0]
legendastro, leg, col=col, psym = sym, box=0,  textcol=col, charsize=0.8
outplot, /close

print, ''
print, "Zenith opacity monitoring...."
print, ''
print, 'Linear fit on measurements: '
print, '    tau1mm = '+strtrim(string(fit[1], format='(f6.3)'))+' tau225 + '+strtrim(string(fit[0], format='(f6.3)'))
print, ''
print, 'Expectation from ATM model: '
print, '    tau1 = '+strtrim(string(atm_fit_12[1], format='(f6.3)'))+' tau225 + '+strtrim(string(atm_fit_12[0], format='(f6.3)'))
print, '    tau3 = '+strtrim(string(atm_fit_32[1], format='(f6.3)'))+' tau225 + '+strtrim(string(atm_fit_32[0], format='(f6.3)'))


;;-----------------------------------------------------------------------------------------
if not keyword_set(nostop) then stop

leg = 'measures'
col = 50
sym = 8

outplot, file='opacity_tau2_tau225_ratio'+run, png=png
plot, tau1, tau2/tau225, xtitle="zenith opacity at 1mm", ytitle="zenith opacity 150-to-225GHz ratio", /ys, /xs, /nodata, $
      xr=[0, 0.8], yr=[0,3]
;oplot, tau225, tau2, psym=8, col=70, symsize=0.5
oplot, tau1[won], tau2[won]/tau225[won], psym=8, col=50, symsize=0.5
;fit = linfit(tau225[won], tau2[won])
oplot, atm_tau1_dip, atm_tau2_dip/atm_tau225_dip, col=250, thick=2
atm_fit = linfit(atm_tau225, atm_tau2)
leg = [leg, 'ATM model']
col = [col, 250]
sym = [sym, 0]

if bp_shift gt 0. then begin
   oplot, atm_tau225, atm_tau2_shift, col=150, thick=2
   leg = [leg, 'ATM model, BP freq shift']
   col = [col, 150]
   sym = [sym, 0]
endif; else begin
   ;;x= indgen(100)/100.
   ;;oplot, x, fit[1]*x +fit[0], col=0
   ;;oplot, x, median(tau2[won]/tau225[won])*x+, col=80, thick=2
   ;;leg = [leg, 'linfit: slope = '+strtrim(string(fit[1], format='(f6.3)'))+$
   ;;       ', norm = '+strtrim(string(fit[0], format='(f6.3)')), $
   ;;       'avg(tau2/tau225):
   ;;       '+string(avg(tau2[won]/tau225[won]),form='(F5.2)')]
   ;;leg = [leg, 'slope = '+strtrim(string(median(tau2[won]/tau225[won]), format='(f6.2)'),2)]
   ;;col = [col, 80]
   ;;sym = [sym, 0]
;endelse

legendastro, leg, col=col, psym = sym, box=0,  textcol=col, charsize=0.8, pos=[0.5, 2.5]
outplot, /close


print, ''
print, "Zenith opacity monitoring...."
print, ''
print, 'Linear fit on measurements: '
print, '    tau2mm = '+strtrim(string(fit[1], format='(f6.3)'))+' tau225 + '+strtrim(string(fit[0], format='(f6.3)'))
print, ''
print, 'Expectation from ATM model: '
print, '    tau2 = '+strtrim(string(atm_fit_12[1], format='(f6.3)'))+' tau225 + '+strtrim(string(atm_fit_12[0], format='(f6.3)'))

!p.multi=0


;;-------------------------------------------------------------------------------------------------------------



print, ''
print, '.c for further plots'

if not keyword_set(nostop) then stop


;; dependence dans le jour 
;;--------------------------------------------------------
list_day = day[UNIQ(day, SORT(day))]
nday = n_elements(list_day)
if nday le 8 then begin
   coltab = [0, 30, 50, 80, 100, 150, 200, 250]
   symtab = intarr(8)+8
   symsize = intarr(8)+0.5
endif else begin
   coltab = [0, 30, 50, 80, 100, 150, 200, 250, 0, 30, 50, 80, 100, 150, 200, 250, 0, 30, 50, 80, 100, 150, 200, 250, 0, 30, 50, 80, 100, 150, 200, 250]
   symtab = [intarr(8)+8, intarr(8)+4, intarr(8)+6, intarr(8)+5]
   symsize = [intarr(8)+0.5, intarr(8)+1, intarr(8)+1, intarr(8)+1]
endelse 

fit = linfit(tau1[won], tau2[won])

!p.multi=[0, 1, 2]
outplot, file='opacity_tau1_tau2_scatterplot_run'+run+'_perday', png=png
plot, tau1, tau2, title="day-to-day dependency", ytitle="zenith opacity at 2mm", xtitle="zenith opacity at 1mm", /ys, /xs, /nodata, xr=[0, 0.8], yr=[0,0.6]
for i=0, nday-2 do begin
   w = where(day ge list_day[i] and day lt list_day[i+1], n)
   if n gt 0 then oplot, tau1[w], tau2[w], psym=8, col=coltab[i+1], symsize=0.5
   legendastro, [strtrim(list_day[i])], col=[coltab[i+1]], psym = [8], box=0, /trad, textcol=[coltab[i+1]], pos=[0.015, (0.6 - i*0.04)]
endfor

plot, tau1, tau2-fit[1]*tau1-fit[0], ytitle="residual to linear fit at 2mm", xtitle="zenith opacity at 1mm", /ys, /xs, /nodata, xr=[0, 0.8], yr=[-0.06,0.06], /noerase ;, position=[0.1, 0.5, 0.9, 0.9]
for i=0, nday-2 do begin
   w = where(day ge list_day[i] and day lt list_day[i+1], n)
   if n gt 0 then oplot, tau1[w], tau2[w]-fit[1]*tau1[w]-fit[0], psym=8, col=coltab[i+1], symsize=0.5
endfor
outplot, /close
!p.multi=0

if not keyword_set(nostop) then stop

png=1
outplot, file='opacity_tau1_tau2_ratio_perday_'+run, png=png
plot, tau1, tau2/tau1, title="day-to-day dependency", ytitle="tau 2mm-to-1mm ratio", xtitle="zenith opacity at 1mm", /ys, /xs, /nodata, xr=[0, 0.8], yr=[0.4,1.5]


;;w = where(day ge '20171029' and day lt 20171030, n)
;;nn = 25
;;bin_num = floor((max(num[w]) - min(num[w]))/20.)*indgen(nn)
;;for i=0, nn-1 do begin
;;   ww = where(day ge '20171029' and day lt 20171030 and num ge bin_num[i] and num lt bin_num[i+1], nf)
;;   if nf gt 0 then print, num[ww]
;;   if nf gt 0 then oplot, tau1[ww], tau2[ww]/tau1[ww], psym=symtab[0], col=coltab[0], symsize=symsize[0]
;;   stop
;;endfor

for i=0, nday-2 do begin
   w = where(day ge list_day[i] and day lt list_day[i+1], n)
   if n gt 0 then oplot, tau1[w], tau2[w]/tau1[w], psym=symtab[i+1], col=coltab[i+1], symsize=symsize[i+1]
   legendastro, [strtrim(list_day[i])], col=[coltab[i+1]], psym = [symtab[i+1]], box=0, /trad, textcol=[coltab[i+1]], pos=[0.6, (1.45 - i*0.04)]
endfor
outplot, /close
png=0

stop


;; dependence on the elevation
;;_________________________________________


elmin = max([min(el_deg), 0])
elmax = max(el_deg)
elbsz = (elmax-elmin)/6.
elbin = indgen(7)*elbsz + elmin

coltab = [23, 50, 85, 150, 200, 250]

fit = linfit(tau1[won], tau2[won])

outplot, file='opacity_tau1_tau2_vs_elevation'+run+'', png=png
!p.multi=[0, 1, 2]
plot, tau1, tau2, title="Dependency on elevation", ytitle="zenith opacity at 2mm", xtitle="zenith opacity at 1mm", /ys, /xs, /nodata, xr=[0, 0.8], yr=[0,0.6];, position=[0.1, 0.5, 0.9, 0.9]
for i=0, 5 do begin
   w = where(el_deg ge elbin[i] and el_deg lt elbin[i+1], n)
   if n gt 0 then oplot, tau1[w], tau2[w], psym=8, col=coltab[i], symsize=0.5
   legendastro, ['el in ['+strtrim(string(elbin[i], format='(f6.1)'),2)+','+strtrim(string(elbin[i+1], format='(f6.1)'),2)+']'], col=[coltab[i]], psym = [8], box=0, textcol=[coltab[i]], pos=[0.015, (0.55 - i*0.05)], charsize=0.8
   oplot, [0,2], fit[0]+fit[1]*[0,2]
endfor
legendastro, ['Const '+string(fit[0],form='(F5.2)'), 'Slope '+string(fit[1],form='(F5.2)')], /right

plot, tau1, tau2-fit[1]*tau1-fit[0],ytitle="residual to linear fit at 2mm", xtitle="zenith opacity at 1mm", /ys, /xs, /nodata, xr=[0, 0.8], yr=[-0.06,0.06], /noerase;, position=[0.1, 0.5, 0.9, 0.9]
for i=0, 5 do begin
   w = where(el_deg ge elbin[i] and el_deg lt elbin[i+1], n)
   if n gt 0 then oplot, tau1[w], tau2[w]-fit[1]*tau1[w]-fit[0], psym=8, col=coltab[i], symsize=0.5
   ;;legendastro, ['el in ['+strtrim(string(elbin[i], format='(f6.1)'),2)+','+strtrim(string(elbin[i+1], format='(f6.1)'),2)+']'], col=[coltab[i]], psym = [8], box=0, /trad, textcol=[coltab[i]], pos=[0.015, (0.6 - i*0.04)]
endfor

!p.multi=0
outplot, /close



print, "That's it !! "

if not keyword_set(nostop) then stop





end
