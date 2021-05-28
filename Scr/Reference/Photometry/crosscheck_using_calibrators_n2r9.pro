;
;
;   Cross-checks of N2R14 Absolute calibration
;
;   LP, January, 2018
;
;____________________________________________________________________

pro crosscheck_using_calibrators_n2r9


input_kidpar_file = "kidpar_best3files_FXDC0C1_GaussPhot_NewConv_calUranus5.fits"
nickname          = 'recalib'

input_kidpar_file =  !nika.off_proc_dir+"/kidpar_best3files_FXDC0C1_GaussPhot_NewConv.fits"
nickname          = 'refkidpar'

input_kidpar_file =  "kidpar_best3files_GaussPhot_NewConv_C0C1inclusive.fits"
nickname          = 'inclusive_skydip_opacorr4'

input_kidpar_file =  "kidpar_best3files_GaussPhot_NewConv_C0C1qualfit.fits"
nickname          = 'qualfit_skydip_opacorr4'

input_kidpar_file =  "kidpar_best3files_GaussPhot_NewConv_C0C1night.fits"
nickname          = 'night_skydip_opacorr4'

input_kidpar_file =  "kidpar_best3files_GaussPhot_NewConv_C0C1tau3low.fits"
nickname          = 'low_skydip_opacorr4'

;; MWC349
;;---------------------------------------------------------------
source            = 'MWC349'
lambda = [!nika.lambda[0], !nika.lambda[1],!nika.lambda[0]]
nu = !const.c/(lambda*1e-3)/1.0d9
th_flux           = 1.69d0*(nu/227.)^0.26
th_flux           = 1.16d0*(nu/100.0)^0.60
;; assuming indep param
err_th_flux       = sqrt( ((nu/100.0)^0.6*0.01)^2 + (1.16*0.6*(nu/100.0)^(-0.4)*0.01)^2)

fill_nika_struct, '22'

outlier_list = ''

;; FWHM selection cut
fwhm_a1_max = 12.0
fwhm_a3_max = 12.0
fwhm_a2_max = 17.9

decor_cm_dmin     = 60.0d0

;; planets
;;----------------------------------------------------------------
;source            = 'MARS'
;lambda = [!nika.lambda[0], !nika.lambda[1],!nika.lambda[0]]
;nu = !const.c/(lambda*1e-3)/1.0d9
;fill_nika_struct, '27'

;; day-to-day variation of the flux expectations


;outlier_list = '20180119s75'

;; FWHM selection cut
;fwhm_a1_max = 12.7
;fwhm_a3_max = 12.7
;fwhm_a2_max = 18.1

;decor_cm_dmin     = 90.0d0


fwhm_a1_min = 10.;11.
fwhm_a3_min = 10.;11.
fwhm_a2_min = 16.;17.
;;==================

compute           = 1
reset             = 0  ; 1 to reanalysis all the scans
png               = 1
ps                = 0
outplot_dir       = '/home/perotto/NIKA/Plots/N2R9/Photometry'
;;do_tel_gain_corr  = 0 ;; no telescope elevation-gain correction
;;do_tel_gain_corr  = 1 ;; telescope elevation-gain correction from EMIR
do_tel_gain_corr  = 2 ;; NIKA2 telescope elevation-gain correction

;; cut in elevation
elevation_min     = 0.0d0

method = 'common_mode_one_block'
;method = 'common_mode_kids_out'


opacity_correction = 4

check_taucorrect  = 0 ;; if 1, do twice the analysis: w and wo opacity correction

  
;; Scan selection
  
restore, !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R9_v0.save"

dz1 = abs(scan.focusz_mm - shift(scan.focusz_mm, -1)) ; 0.8
dz2 = scan.focusz_mm - shift(scan.focusz_mm, -2)      ; 0.4
dz3 = scan.focusz_mm - shift(scan.focusz_mm, -3)      ; -0.4
dz4 = scan.focusz_mm - shift(scan.focusz_mm, -4)      ; -0.8

dx1 = abs(scan.focusx_mm - shift(scan.focusx_mm, -1)) ; 1.4
dx2 = scan.focusx_mm - shift(scan.focusx_mm, -2)      ; 0.7
dx3 = scan.focusx_mm - shift(scan.focusx_mm, -3)      ; -0.7
dx4 = scan.focusx_mm - shift(scan.focusx_mm, -4)      ; -1.4

dy1 = abs(scan.focusy_mm - shift(scan.focusy_mm, -1)) ; 1.4
dy2 = scan.focusy_mm - shift(scan.focusy_mm, -2)      ; 0.7
dy3 = scan.focusy_mm - shift(scan.focusy_mm, -3)      ; -0.7
dy4 = scan.focusy_mm - shift(scan.focusy_mm, -4)      ;-1.4

wfocus = where(strupcase(scan.obstype) eq 'ONTHEFLYMAP' and $
               (dz1 gt 0.3 or dx1 gt 0.5 or dy1 gt 0.5)   $
               , nscans, compl=wok, ncompl=nok)

wtokeep = where(strupcase(scan[wok].obstype) eq 'ONTHEFLYMAP' $
                and scan[wok].n_obs gt 4  $
                and strupcase(scan[wok].object) eq strupcase(source) $
                and scan[wok].el_deg gt elevation_min, nkeep)


scan_str = scan[wok[wtokeep]]
scan_list = scan_str.day+"s"+strtrim( scan_str.scannum,2)

print, scan_list

;; remove outliers if any
;; define outlier_list and relaunch
;;-------------------------------------------------------------
if (n_elements(outlier_list) gt 0 and outlier_list[0] ne '') then begin
   scan_list_ori = scan_list
   remove_scan_from_list, scan_list_ori, outlier_list, scan_list
endif

nscans = n_elements(scan_list)

nk_scan2run, scan_list[0]

if not keyword_set(outplot_dir) then outplot_dir=!nika.plot_dir
  
;; Make maps of all observations
reset=0
if compute eq 1 then begin
   
   for NoTauCorrect=0, check_taucorrect do begin

      if reset gt 0 then begin
         scan_list_to_analyse = scan_list
         nscan_to_analyse = nscans
      endif else begin
         scan_list_to_analyse = ''
         for isc = 0, nscans-1 do begin
            file = outplot_dir+'/'+source+"_photometry_"+nickname+"_NoTauCorrect"+strtrim(NoTauCorrect,2)+'/v_1/'+scan_list[isc]+'/results.save'
            if file_test(file) lt 1 then scan_list_to_analyse = [ scan_list_to_analyse, scan_list[isc]]
         endfor
         nscan_to_analyse = n_elements(scan_list_to_analyse)-1
         if nscan_to_analyse gt 0 then scan_list_to_analyse = scan_list_to_analyse[1:*] 
      endelse
      
      ncpu_max = 24
      optimize_nproc, nscan_to_analyse, ncpu_max, nproc
 
      if nscan_to_analyse gt 0 then begin
         reset = 1
         project_dir = outplot_dir+'/'+source+"_photometry_"+nickname+"_NoTauCorrect"+strtrim(NoTauCorrect,2)
         spawn, "mkdir -p "+project_dir
         split_for, 0, nscan_to_analyse-1, $
                    commands=['obs_nk_ps, i, scan_list_to_analyse, project_dir, '+$
                              'method, source, input_kidpar_file=input_kidpar_file, '+$
                              'reset=reset, NoTauCorrect=NoTauCorrect, ' +$
                              'do_tel_gain_corr=do_tel_gain_corr, ' +$
                              'decor_cm_dmin=decor_cm_dmin, ' +$
                              'opacity_correction=opacity_correction'], $
                    nsplit=nproc, $
                    varnames=['scan_list_to_analyse', 'project_dir', 'method', 'source', 'input_kidpar_file', $
                              'reset', 'NoTauCorrect', 'do_tel_gain_corr', 'decor_cm_dmin', 'opacity_correction']
      endif
         
   endfor
endif

scan_list = scan_list[ sort(scan_list)]
nscans = n_elements(scan_list)

;; check if all scans were indeed processed
run = !nika.run

for NoTauCorrect=0, check_taucorrect do begin
   project_dir = outplot_dir+"/"+source+"_photometry_"+nickname+"_NoTauCorrect"+strtrim(NoTauCorrect,2)
   
   flux     = fltarr(nscans, 3)
   err_flux = fltarr(nscans, 3)
   ap_flux  = fltarr(nscans,3)
   err_ap_flux = fltarr(nscans, 3)
   peak     = fltarr(nscans, 3)
   tau_1mm      = fltarr(nscans)
   tau_2mm      = fltarr(nscans)
   fwhm         = fltarr(nscans,3)
   nsub         = intarr(nscans)
   elev         = fltarr(nscans)
   ut           = strarr(nscans)
   for i =0, nscans-1 do begin
      dir = project_dir+"/v_1/"+strtrim(scan_list[i], 2)
      if file_test(dir+"/results.save") then begin
         restore,  dir+"/results.save"

         if info1.polar eq 1 then print, scan_list[i]+" is polarized !"
         fwhm[i,0] = info1.result_fwhm_1
         fwhm[i,1] = info1.result_fwhm_2
         fwhm[i,2] = info1.result_fwhm_3
         
         flux[i, 0] = info1.result_flux_i1
         flux[i, 1] = info1.result_flux_i2
         flux[i, 2] = info1.result_flux_i3
         
         peak[i, 0] = info1.result_peak_1
         peak[i, 1] = info1.result_peak_2
         peak[i, 2] = info1.result_peak_3
         
         tau_1mm[ i] = info1.result_tau_1mm
         tau_2mm[ i] = info1.result_tau_2mm
         err_flux[i, 0] = info1.result_err_flux_i1
         err_flux[i, 1] = info1.result_err_flux_i2
         err_flux[i, 2] = info1.result_err_flux_i3

         ap_flux[i, 0] = info1.result_aperture_photometry_i1
         ap_flux[i, 1] = info1.result_aperture_photometry_i2
         ap_flux[i, 2] = info1.result_aperture_photometry_i3
         err_ap_flux[i, 0] = info1.result_err_aperture_photometry_i1
         err_ap_flux[i, 1] = info1.result_err_aperture_photometry_i2
         err_ap_flux[i, 2] = info1.result_err_aperture_photometry_i3
         nsub[i]        = info1.nsubscans
         elev[i]        = info1.RESULT_ELEVATION_DEG
         ut[i]          = strmid(info1.ut, 0, 5)
      endif
   endfor
   

   ;; photometric correction
   ;;photometric_correction, transpose(flux), transpose(fwhm), photo_corr_factor
   ;;photo_corr_factor = transpose(photo_corr_factor)
   
   ;; selection on the FWHM before recalibration
   ;;------------------------------------------------------------------
   
   fwhm_sigma = dblarr(3)
   fwhm_avg   = dblarr(3)
   for j=0, 2 do begin
      w=where(fwhm[*,j] lt !nika.fwhm_array[j]*1.2 and fwhm[*,j] gt !nika.fwhm_array[j]*0.65, nok)
      if nok gt 0 then begin
         fwhm_sigma[j] = stddev( fwhm[w, j])
         fwhm_avg[j]   = avg(    fwhm[w, j])
      endif else print, "all scans have catastrophic fwhm!"
   endfor
   
   ;; excluding scans of 2.5 sigma outlier FWHM in any arrays
   nsig = 2.5
   nsig = 5.0
   nsig = 3.0
   nscan_all = nscans
   wtokeep = where( abs(fwhm[*, 0]-fwhm_avg[0]) le nsig*fwhm_sigma[0] and $
                    abs(fwhm[*, 1]-fwhm_avg[1]) le nsig*fwhm_sigma[1] and $
                    abs(fwhm[*, 2]-fwhm_avg[2]) le nsig*fwhm_sigma[2] and $
                    fwhm[*, 0] le 12.5 and fwhm[*, 1] le 18.5 and fwhm[*, 2] le 12.5,$
                    compl=wout, nscans, ncompl=nout)
   selection_type=0
   
   ;; excluding large beam scans
   wtokeep = where( fwhm[*, 0] le fwhm_a1_max and $
                    fwhm[*, 1] le fwhm_a2_max and $
                    fwhm[*, 2] le fwhm_a3_max and $
                    fwhm[*, 0] ge fwhm_a1_min and $
                    fwhm[*, 1] ge fwhm_a2_min and $
                    fwhm[*, 2] ge fwhm_a3_min, compl=wout, nscans, ncompl=nout)
   selection_type = 1
   fwhm_max = [fwhm_a1_max,fwhm_a2_max,fwhm_a3_max]
   
   ;; plot 
   day_list = strmid(scan_list,0,8)
   
   wind, 1, 1, /free, /large
   outplot, file='fwhm_'+strtrim(source,2)+'_'+strtrim(nickname,2), png=png, ps=ps
   !p.multi=[0,1,3]
   index = dindgen(n_elements(flux[*, 0]))
   for j=0, 2 do begin
      ymin = max( [!nika.fwhm_array[j] - 5.0, min(fwhm[*,j])] )
      ymax = min( [ !nika.fwhm_array[j] + 5.0, max(fwhm[*,j])] )
      plot, index, fwhm[*,j], xr=[-1, nscan_all], /xs, psym=-4, xtitle='scan index', ytitle='FWHM (arcsec)', $
            /ys, charsize=1.1, yr=[ymin, ymax]
      if nout gt 0 then oplot, index[wout],   fwhm[wout,j], psym=4, col=250
      if j eq 2 then   xyouts, index[wtokeep]-0.2, fltarr(nscans)+fwhm_avg[j], scan_list[wtokeep], charsi=0.7, orient=90
      if nout gt 0 and j eq 2 then  xyouts, index[wout]-0.2, fltarr(nout)+fwhm_avg[j], scan_list[wout], charsi=0.7, orient=90, col=250
      myday = day_list[0]
      for i=0, nscans-1 do begin
         if day_list[i] ne myday then begin
            oplot, [i,i]*1, [-1,1]*1e10
            myday = day_list[i]
         endif
      endfor
      if selection_type lt 1 then begin
         oplot, index, index*0.+fwhm_avg[j], col=50
         oplot,[0,nscans+nout+1],[fwhm_avg[j],fwhm_avg[j]]+fwhm_sigma[j],col=70,LINESTYLE = 5
         oplot,[0,nscans+nout+1],[fwhm_avg[j],fwhm_avg[j]]-fwhm_sigma[j],col=70,LINESTYLE = 5
      endif
      if selection_type eq 1 then begin
         oplot, [0,nscans+nout+1], index*0.+fwhm_avg[j], col=50, LINESTYLE = 5
         oplot, [0,nscans+nout+1], index*0.+fwhm_max[j], col=50
      endif
      legendastro, 'Array '+strtrim(j+1,2), box=0
   endfor
   !p.multi=0
   outplot, /close
   
   
   if nscans le 0 then begin
      print, "all scans have abberant FWHM...."
      print, "stop here and investigate"
      stop
   endif
   
   
   
   ;; apply the selection
   if nout gt 0 then begin
      print,''
      print,'============================================='
      black_list = scan_list[wout]
      print,'outlier_list =  [ $'
      for i=0, nout-2 do print,"'",black_list[i],"', $"
      print,"'",black_list[nout-1],"' ]"
      print,'============================================='
   endif
   
   scan_list_all = scan_list
   scan_list  = scan_list[wtokeep]
   flux_1     = flux[wtokeep, 0]
   flux_2     = flux[wtokeep, 1]
   flux_3     = flux[wtokeep, 2]
   err_flux_1     = err_flux[wtokeep, 0]
   err_flux_2     = err_flux[wtokeep, 1]
   err_flux_3     = err_flux[wtokeep, 2]
   day_list = strmid(scan_list,0,8)
  

   if strupcase(source) eq 'MARS' then begin
      ;; average flux expectation (for plotting only)
      nday = n_elements(day_list)
      tab_th_flux = dblarr(nday, 3)
      for j=0, nday-1 do begin
         fill_nika_struct, '27', day=day_list[j]
         tab_th_flux[j, *] = !nika.flux_mars
         print, !nika.flux_mars
      endfor
      th_flux = mean(tab_th_flux, dimension=1) 
   endif

   
   
   ;; plot of the flux
   ;;--------------------------------------------------------------------
   print, ""
   print, "============================================================="
   print, "Baseline photometry"
   print, "============================================================="
   print, ""
   sigma_1 = stddev( flux_1)
   sigma_2 = stddev( flux_2)
   sigma_3 = stddev( flux_3)
   flux_avg_1 = avg( flux_1)
   flux_avg_2 = avg( flux_2)
   flux_avg_3 = avg( flux_3)
   
   
   
   delvarx, yra    
   index = dindgen(n_elements(flux_1))
   
   fmt = "(F5.1)"
   wind, 1, 1, /free, /large
   outfile = project_dir+'/photometry_'+strtrim(source)+'_NoTauCorrect'+strtrim(NoTauCorrect,2)+'_'+strtrim(nickname,2)
   if defined(suffix) then outfile = outfile+"_"+suffix
   outplot, file=outfile, png=png, ps=ps
   my_multiplot, 1, 4, pp, pp1, /rev, gap_y=0.02, xmargin=0.1, ymargin=0.1 ; 1e-6
   !x.charsize = 1e-10
   
   yra=th_flux[0]*[0.7, 1.3]
   plot,       index, flux_1, ytitle='Flux Jy', xr=[-1,nscans], /xs, position=pp1[0,*], yra=yra, /ys, title=file_basename(project_dir)
   oploterror, index, flux_1, err_flux_1, psym=8 
   oplot, [-1,nscans], [flux_avg_1, flux_avg_1], col=70
   oplot, [-1,nscans], th_flux[0]*[1., 1.], col=250
   legendastro, ['Array 1'], box=0, pos=[-0.5, yra[1]*0.9]
   legendastro, ['sigma/avg: '+strtrim( string(sigma_1/flux_avg_1*100.0d0,format=fmt),2)+'%'], box=0, /bottom
   myday = day_list[0]
   for i=0, nscans-1 do begin
      if day_list[i] ne myday then begin
         oplot, [i,i]*1, [-1,1]*1e10
         myday = day_list[i]
      endif
   endfor
   
   yra=th_flux[2]*[0.7, 1.3]
   plot,       index, flux_3, ytitle='Flux Jy', xr=[-1,nscans], /xs, position=pp1[1,*], /noerase, yra=yra, /ys
   oploterror, index, flux_3, err_flux_3, psym=8
   oplot, [-1,nscans], [flux_avg_3, flux_avg_3], col=70
   oplot, [-1,nscans], th_flux[2]*[1., 1.], col=250
   legendastro, ['Array 3'], box=0, pos=[-0.5, yra[1]*0.9]
   legendastro, ['sigma/avg: '+strtrim( string(sigma_3/flux_avg_3*100.0,format=fmt)+'%',2)], box=0, /bottom
   myday = day_list[0]
   for i=0, nscans-1 do begin
      if day_list[i] ne myday then begin
         oplot, [i,i]*1, [-1,1]*1e10
         myday = day_list[i]
      endif
   endfor
   
   yra=th_flux[1]*[0.7, 1.3]
   plot,       index, flux_2, ytitle='Flux Jy',xr=[-1,nscans], /xs, position=pp1[2,*], /noerase, yra=yra, /ys
   oploterror, index, flux_2, err_flux_2, psym=8
   oplot, [-1,nscans], [flux_avg_2, flux_avg_2], col=70
   oplot, [-1,nscans], th_flux[1]*[1., 1.], col=250
   xyouts, index, flux_2, strmid(scan_list,4, 12), charsi=0.7, orient=90
   legendastro, ['Array 2'], box=0, pos=[-0.5, yra[1]*0.9]
   legendastro, ['sigma/avg: '+strtrim( string(sigma_2/flux_avg_2*100.0,format=fmt),2)+'%'], box=0, /bottom
   myday = day_list[0]
   for i=0, nscans-1 do begin
      if day_list[i] ne myday then begin
         oplot, [i,i]*1, [-1,1]*1e10
         myday = day_list[i]
      endif
   endfor
   
   
   plot, index, tau_1mm[wtokeep], xr=[-1,nscans],/xs, position=pp1[3,*], /noerase,/nodata
   oplot, index, tau_1mm[wtokeep], col=250
   oplot, index, tau_2mm[wtokeep], col=50
   legendastro, ['Tau 1mm', 'Tau 2mm'], col=[250, 50],box=0, pos=[-0.5, 0.1]
   myday = day_list[0]
   for i=0, nscans-1 do begin
      if day_list[i] ne myday then begin
         oplot, [i,i]*1, [-1,1]*1e10
         myday = day_list[i]
      endif
   endfor
   
   !x.charsize = 1
   myday = day_list[0]
   xyouts, 0.1, 0.01, strtrim(strmid(myday,6),2)
   for i=0, nscans-1 do begin
      if day_list[i] ne myday then begin
         oplot, [i,i]*1, [-1,1]*1e10
         myday = day_list[i]
         xyouts, i+0.1, 0.01, strtrim(strmid(myday,6),2)
      endif
   endfor
   !p.multi = 0
   outplot, /close



   ;; correlation plots
   ;;----------------------------------------------

   index = dindgen(nscans)
   day_list = strmid(scan_list,0,8)
     
   coltab = [200, 80, 250]
   
   ut_tab=['00:00', '05:00', '07:00', '08:00', '09:00', '09:30', '10:00','12:00', '13:00', '15:00','17:00', '18:00', '19:00', '20:00', '21:00', '22:00', '24:00']

   minut = min(ut)
   maxut = max(ut)
   minh = where(ut_tab ge minut)
   maxh = where(ut_tab le maxut)
   ut_tab = ut_tab[minh[0]-1:maxh[n_elements(maxh)-1]+1]
   
   nut = n_elements(ut_tab)-1
   
   ;; 1mm
   ;;--------------------------------------------
   wind, 1, 1, /free, xsize=1150, ysize=670
   outplot, file=project_dir+'/Correlation_plot_'+strtrim(source, 2)+'_'+strtrim(method,2)+'_1mm_'+$
            strtrim(nickname,2)+"_colordate", png=png, ps=ps
   my_multiplot, 3, 2, pp, pp1, /rev, gap_y=0.07, gap_x=0.07, xmargin=0.1, ymargin=0.1 ; 1e-6

      
   plot, fwhm[*, 0] , flux[*, 0], /xs, yr=th_flux[0]*[0.7, 1.2], $
         xr=[min(fwhm[wtokeep, 0])*0.97,min([max(fwhm[*, 0]),15.])], psym=-4, $
         xtitle='FWHM (arcsec)', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
         pos=pp1[0, *]
   
   ;;oplot, fwhm[wtokeep, 0] , flux[wtokeep, 0], psym=8, col=coltab[0]
   ;;oplot, fwhm[wout, 0] , flux[wout, 0], psym=4, col=coltab[0]
   ;;oplot, fwhm[wtokeep, 2] , flux[wtokeep, 2], psym=8, col=coltab[2]
   ;;oplot, fwhm[wout, 2] , flux[wout, 2], psym=4, col=coltab[2]
   for u = 0, nut-1 do begin
      w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
      if nn gt 0 then oplot, fwhm[w, 0] , flux[w, 0], psym=4, col=(u+1.)*250./nut
      if nn gt 0 then oplot, fwhm[w, 2] , flux[w, 2], psym=8, col=(u+1.)*250./nut
      print, 'from ', ut_tab[u], ' to ',  ut_tab[u+1], ' : ', nn, ' scans'
   endfor
   legendastro, ['A1', 'A3'], psym=[4, 8]
   oplot, [0,50], th_flux[0]*[1., 1.], col=0

   oplot, fwhm[*, 0], th_flux[0]*(12.0^2+!nika.fwhm_nom[0]^2)/(fwhm[*,0]^2+!nika.fwhm_nom[0]^2), col=0

 
   
   ;; tau-flux     
   plot, tau_1mm[*] , flux[*, 0], /xs, yr=th_flux[0]*[0.7, 1.2], $
         xr=[min(tau_1mm[wtokeep])*0.5,min([max(tau_1mm[*]),1.])], psym=-4, $
         xtitle='zenith opacity', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
         pos=pp1[1, *], /noerase
   
   ;;oplot, tau_1mm[wtokeep] , flux[wtokeep, 0], psym=8, col=coltab[0]
   ;;oplot, tau_1mm[wout] , flux[wout, 0], psym=4, col=coltab[0]
   ;;oplot, tau_1mm[wtokeep] , flux[wtokeep, 2], psym=8, col=coltab[2]
   ;;oplot, tau_1mm[wout] , flux[wout, 2], psym=4, col=coltab[2]
   for u = 0, nut-1 do begin
      w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
      if nn gt 0 then oplot, tau_1mm[w] , flux[w, 0], psym=4, col=(u+1.)*250./nut
      if nn gt 0 then oplot, tau_1mm[w] , flux[w, 2], psym=8, col=(u+1.)*250./nut
   endfor
   oplot, [0,50], th_flux[0]*[1., 1.], col=0
   
   
   ;; elev-flux
   plot, elev[*] , flux[*, 0], /xs, yr=th_flux[0]*[0.7, 1.2], $
         xr=[min(elev[wtokeep])*0.97,max(elev[*])*1.1], psym=-4, $
         xtitle='Elevation [deg]', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
         pos=pp1[2, *], /noerase
     
   ;;oplot, elev[wtokeep] , flux[wtokeep, 0], psym=8, col=coltab[0]
   ;;oplot, elev[wout] , flux[wout, 0], psym=4, col=coltab[0]
   ;;oplot, elev[wtokeep] , flux[wtokeep, 2], psym=8, col=coltab[2]
   ;;oplot, elev[wout] , flux[wout, 2], psym=4, col=coltab[2]
   for u = 0, nut-1 do begin
      w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
      if nn gt 0 then oplot, elev[w] , flux[w, 0], psym=4, col=(u+1.)*250./nut
      if nn gt 0 then oplot, elev[w] , flux[w, 2], psym=8, col=(u+1.)*250./nut
   endfor
   oplot, [0,90], th_flux[0]*[1., 1.], col=0
   
   ;; FWHM-elev
   f_max = min([max(fwhm[*, 0]),15.])
   f_min = min(fwhm[*, 0])*0.90
   plot, elev[*] , FWHM[*, 0], /xs, yr=[min(fwhm[*, 0])*0.90,min([max(fwhm[*, 0]),15.])], $
         xr=[10., 80.], psym=-4, $
         xtitle='Elevation [deg]', ytitle='FWHM [arcsec]', /ys, /nodata, $
         pos=pp1[3, *], /noerase
   
   ;;oplot, elev[wtokeep] , fwhm[wtokeep, 0], psym=8, col=coltab[0]
   ;;oplot, elev[wout] , fwhm[wout, 0], psym=4, col=coltab[0]
   ;;oplot, elev[wtokeep] , fwhm[wtokeep, 2], psym=8, col=coltab[2]
   ;;oplot, elev[wout] , fwhm[wout, 2], psym=4, col=coltab[2]
   for u = 0, nut-1 do begin
      w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
      if nn gt 0 then oplot, elev[w] , fwhm[w, 0], psym=4, col=(u+1.)*250./nut
      if nn gt 0 then oplot, elev[w] , fwhm[w, 2], psym=8, col=(u+1.)*250./nut
      xyouts, 15., f_max - (f_max-f_min)*(u+0.5)/nut, ut_tab[u], charsi=0.7, orient=0, col=(u+1.)*250./nut
   endfor
   oplot, [0,90], 11.5*[1., 1.], col=0
   
   ;; FWHM-tau 
   plot, tau_1mm[*] , fwhm[*, 0], /xs, yr=[min(fwhm[*, 0])*0.90,min([max(fwhm[*, 0]),15.])], $
         xr=[min(tau_1mm[wtokeep])*0.5,min([max(tau_1mm[*]),1.])], psym=-4, $
         xtitle='zenith opacity', ytitle='FWHM [arcsec]', /ys, /nodata, $
         pos=pp1[4, *], /noerase
   
   ;;oplot, tau_1mm[wtokeep] , fwhm[wtokeep, 0], psym=8, col=coltab[0]
   ;;oplot, tau_1mm[wout] , fwhm[wout, 0], psym=4, col=coltab[0]
   ;;oplot, tau_1mm[wtokeep] , fwhm[wtokeep, 2], psym=8, col=coltab[2]
   ;;oplot, tau_1mm[wout] , fwhm[wout, 2], psym=4, col=coltab[2]
   for u = 0, nut-1 do begin
      w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
      if nn gt 0 then oplot, tau_1mm[w] , fwhm[w, 0], psym=4, col=(u+1.)*250./nut
      if nn gt 0 then oplot, tau_1mm[w] , fwhm[w, 2], psym=8, col=(u+1.)*250./nut    
   endfor
   oplot, [0,50], 11.5*[1., 1.], col=0

   ;; tau-elev
   plot, elev[*] , tau_1mm[*], /xs, yr=[min(tau_1mm[wtokeep])*0.5,min([max(tau_1mm[*]),1.])], $
         xr=[10., 80.], psym=-4, $
         xtitle='Elevation [deg]', ytitle='zenith opacity', /ys, /nodata, $
         pos=pp1[5, *], /noerase
   
   ;;oplot, elev[wtokeep] , tau_1mm[wtokeep, 0], psym=8, col=coltab[2]
   ;;oplot, elev[wout] , tau_1mm[wout, 0], psym=4, col=coltab[2]
   for u = 0, nut-1 do begin
      w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
      if nn gt 0 then oplot, elev[w] , tau_1mm[w], psym=8, col=(u+1.)*250./nut
   endfor
   oplot, [0,90], 0.2*[1., 1.], col=0
   
   !p.multi=0
   outplot, /close
   
   
   
   
   ;; 2mm
   ;;--------------------------------------------
   wind, 1, 1, /free, xsize=1150, ysize=670
   outplot, file=project_dir+'/Correlation_plot_'+strtrim(source, 2)+'_'+strtrim(method, 2)+'_2mm_'+$
            strtrim(nickname,2)+'_colordate', png=png, ps=ps
   my_multiplot, 3, 2, pp, pp1, /rev, gap_y=0.07, gap_x=0.07, xmargin=0.1, ymargin=0.1 ; 1e-6

   ;; FWHM- Flux
   plot, fwhm[*, 1] , flux[*, 1], /xs, yr=th_flux[1]*[0.7, 1.2], $
         xr=[min(fwhm[wtokeep, 1])*0.97,min([max(fwhm[*, 1]),19.])], psym=-4, $
         xtitle='FWHM (arcsec)', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
         pos=pp1[0, *]
   
   ;;oplot, fwhm[wtokeep, 1] , flux[wtokeep, 1], psym=8, col=coltab[1]
   ;;oplot, fwhm[wout, 1] , flux[wout, 1], psym=4, col=coltab[1]
   for u = 0, nut-1 do begin
      w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
      if nn gt 0 then oplot, fwhm[w, 1] , flux[w, 1], psym=8, col=(u+1.)*250./nut
      xyouts, 17.2, !nika.flux_uranus[1]*(1.2-0.5*(u+0.5)/nut), ut_tab[u], charsi=0.7, orient=0, col=(u+1.)*250./nut
   endfor
   oplot, [0,50], th_flux[1]*[1., 1.], col=0
   
     oplot, fwhm[*, 1], th_flux[1]*(17.5^2+!nika.fwhm_nom[1]^2)/(fwhm[*,1]^2+!nika.fwhm_nom[1]^2), col=0

     
     ;; tau-flux     
     plot, tau_2mm[*] , flux[*, 1], /xs, yr=th_flux[1]*[0.7, 1.2], $
           xr=[min(tau_2mm[wtokeep])*0.5,min([max(tau_2mm[*]),1.])], psym=-4, $
           xtitle='zenith opacity', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
           pos=pp1[1, *], /noerase
     
     ;;oplot, tau_2mm[wtokeep] , flux[wtokeep, 1], psym=8, col=coltab[1]
     ;;oplot, tau_2mm[wout] , flux[wout, 1], psym=4, col=coltab[1]
     for u = 0, nut-1 do begin
        w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, tau_2mm[w] , flux[w, 1], psym=8, col=(u+1.)*250./nut
     endfor
     oplot, [0,50], th_flux[1]*[1., 1.], col=0


     ;; elev-flux
     plot, elev[*] , flux[*, 1], /xs, yr=th_flux[1]*[0.7, 1.2], $
           xr=[min(elev[wtokeep])*0.97,max(elev[*])*1.1], psym=-4, $
           xtitle='Elevation [deg]', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
           pos=pp1[2, *], /noerase
     
     ;;oplot, elev[wtokeep] , flux[wtokeep, 1], psym=8, col=coltab[1]
     ;;oplot, elev[wout] , flux[wout, 1], psym=4, col=coltab[1]
     for u = 0, nut-1 do begin
        w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, elev[w] , flux[w, 1], psym=8, col=(u+1.)*250./nut
     endfor
     oplot, [0,90], th_flux[1]*[1., 1.], col=0

     ;; FWHM-elev
     plot, elev[*] , FWHM[*, 1], /xs, yr=[min(fwhm[wtokeep, 1])*0.97,min([max(fwhm[*, 1]),19.])], $
           xr=[min(elev[wtokeep])*0.97,max(elev[*])*1.1], psym=-4, $
           xtitle='Elevation [deg]', ytitle='FWHM [arcsec]', /ys, /nodata, $
           pos=pp1[3, *], /noerase
     
     ;;oplot, elev[wtokeep] , fwhm[wtokeep, 1], psym=8, col=coltab[1]
     ;;oplot, elev[wout] , fwhm[wout, 1], psym=4, col=coltab[1]
     for u = 0, nut-1 do begin
        w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, elev[w] , fwhm[w, 1], psym=8, col=(u+1.)*250./nut
     endfor
     oplot, [0,90], 17.5*[1., 1.], col=0
     
     ;; FWHM-tau 
     plot, tau_2mm[*] , fwhm[*, 1], /xs, yr=[min(fwhm[wtokeep, 1])*0.97,min([max(fwhm[*, 1]),19.])], $
           xr=[min(tau_2mm[wtokeep])*0.5,min([max(tau_2mm[*]),1.])], psym=-4, $
           xtitle='zenith opacity', ytitle='FWHM [arcsec]', /ys, /nodata, $
           pos=pp1[4, *], /noerase
     
     ;;oplot, tau_2mm[wtokeep] , fwhm[wtokeep, 1], psym=8, col=coltab[1]
     ;;oplot, tau_2mm[wout] , fwhm[wout, 1], psym=4, col=coltab[1]
     for u = 0, nut-1 do begin
        w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, tau_2mm[w] , fwhm[w, 1], psym=8, col=(u+1.)*250./nut
     endfor
     oplot, [0,50], 17.5*[1., 1.], col=0

     ;; tau-elev
     plot, elev[*] , tau_2mm[*], /xs, yr=[min(tau_2mm[wtokeep])*0.5,min([max(tau_2mm[*]),1.])], $
           xr=[min(elev[wtokeep])*0.97,max(elev[*])*1.1], psym=-4, $
           xtitle='Elevation [deg]', ytitle='zenith opacity', /ys, /nodata, $
           pos=pp1[5, *], /noerase
     
     ;;oplot, elev[wtokeep] , tau_2mm[wtokeep, 0], psym=8, col=coltab[1]
     ;;oplot, elev[wout] , tau_2mm[wout, 0], psym=4, col=coltab[1]
     for u = 0, nut-1 do begin
        w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, elev[w] , tau_2mm[w], psym=8, col=(u+1.)*250./nut
     endfor
     oplot, [0,90], 0.1*[1., 1.], col=0

     !p.multi=0
     outplot, /close
     ;;---------------------------------------------------------------

     stop
   
   
   
   print,''
   print,'======================================================'
   print,"Average flux density A1: "+strtrim(flux_avg_1,2)+" Jy/beam"
   print,"Average flux density A3: "+strtrim(flux_avg_3,2)+" Jy/beam"
   print,"Average flux density A2: "+strtrim(flux_avg_2,2)+" Jy/beam"
   print,'======================================================'
   if strupcase(source) ne 'MARS' then begin
      print,"Relative uncertainty A1: "+strtrim(100.*sigma_1/flux_avg_1,2)+" %"
      print,"Relative uncertainty A3: "+strtrim(100.*sigma_3/flux_avg_3,2)+" %"
      print,"Relative uncertainty A2: "+strtrim(100.*sigma_2/flux_avg_2,2)+" %"
      print,'======================================================'
      print,"Flux ratio to expectation A1: "+strtrim(flux_avg_1/th_flux[0],2)
      print,"Flux ratio to expectation A3: "+strtrim(flux_avg_3/th_flux[2],2)
      print,"Flux ratio to expectation A2: "+strtrim(flux_avg_2/th_flux[1],2)
   endif else begin
      tab_var = dblarr(nscans, 3)
      for j = 0, nscans-1 do tab_var[j, *] = (flux[wtokeep[j], *]-tab_th_flux[j, *])^2/tab_th_flux[j, *]^2
      error = sqrt(mean(tab_var, dimension=1))
      print,"Relative uncertainty A1: "+strtrim(100.*error[0],2)+" %"
      print,"Relative uncertainty A3: "+strtrim(100.*error[2],2)+" %"
      print,"Relative uncertainty A2: "+strtrim(100.*error[1],2)+" %"
      print,'======================================================'
      tab_ratio = dblarr(nscans, 3)
      ;; tab_th_flux is already filled
      for j = 0, nscans-1 do tab_ratio[j, *] = flux[wtokeep[j], *]/tab_th_flux[j, *]
      print,tab_ratio
      ratio = mean(tab_ratio, dimension=1)
      print,"Flux ratio to expectation A1: "+strtrim(ratio[0],2)
      print,"Flux ratio to expectation A3: "+strtrim(ratio[2],2)
      print,"Flux ratio to expectation A2: "+strtrim(ratio[1],2)   
   endelse
   print,'======================================================'
   
   print,''


   stop
   
   ;; plot of the flux using peak amplitude
   ;;--------------------------------------------------------------------
   print, ""
   print, "============================================================="
   print, "Peak amplitude"
   print, "============================================================="
   print, ""
   peak_1     = peak[wtokeep, 0]
   peak_2     = peak[wtokeep, 1]
   peak_3     = peak[wtokeep, 2]
   sigma_1 = stddev( peak_1)
   sigma_2 = stddev( peak_2)
   sigma_3 = stddev( peak_3)
   peak_avg_1 = avg( peak_1)
   peak_avg_2 = avg( peak_2)
   peak_avg_3 = avg( peak_3)
   
   
   
   delvarx, yra    
   index = dindgen(n_elements(peak_1))
   
   fmt = "(F5.1)"
   wind, 1, 1, /free, /large
   outfile = project_dir+'/A_peak_'+strtrim(source)+'_NoTauCorrect'+strtrim(NoTauCorrect,2)+'_'+strtrim(nickname,2)
   if defined(suffix) then outfile = outfile+"_"+suffix
   outplot, file=outfile, png=png, ps=ps
   my_multiplot, 1, 4, pp, pp1, /rev, gap_y=0.02, xmargin=0.1, ymargin=0.1 ; 1e-6
   !x.charsize = 1e-10
   
   yra=th_flux[0]*[0.7, 1.3]
   plot,       index, peak_1, ytitle='Flux Jy', xr=[-1,nscans], /xs, position=pp1[0,*], yra=yra, /ys, title=file_basename(project_dir)
   oploterror, index, peak_1, peak_1*0., psym=8 
   oplot, [-1,nscans], [peak_avg_1, peak_avg_1], col=70
   oplot, [-1,nscans], th_flux[0]*[1., 1.], col=250
   legendastro, ['Array 1'], box=0, pos=[-0.5, yra[1]*0.9]
   legendastro, ['sigma/avg: '+strtrim( string(sigma_1/peak_avg_1*100.0d0,format=fmt),2)+'%'], box=0, /bottom
   myday = day_list[0]
   for i=0, nscans-1 do begin
      if day_list[i] ne myday then begin
         oplot, [i,i]*1, [-1,1]*1e10
         myday = day_list[i]
      endif
   endfor
   
   yra=th_flux[2]*[0.7, 1.3]
   plot,index, peak_3, ytitle='Flux Jy', xr=[-1,nscans], /xs, position=pp1[1,*], /noerase, yra=yra, /ys
   oploterror, index, peak_3, peak_3*0., psym=8
   oplot, [-1,nscans], [peak_avg_3, peak_avg_3], col=70
   oplot, [-1,nscans], th_flux[2]*[1., 1.], col=250
   legendastro, ['Array 3'], box=0, pos=[-0.5, yra[1]*0.9]
   legendastro, ['sigma/avg: '+strtrim( string(sigma_3/peak_avg_3*100.0,format=fmt)+'%',2)], box=0, /bottom
   myday = day_list[0]
   for i=0, nscans-1 do begin
      if day_list[i] ne myday then begin
         oplot, [i,i]*1, [-1,1]*1e10
         myday = day_list[i]
      endif
   endfor
   
   yra=th_flux[1]*[0.7, 1.3]
   plot, index, peak_2, ytitle='Flux Jy',xr=[-1,nscans], /xs, position=pp1[2,*], /noerase, yra=yra, /ys
   oploterror, index, peak_2, peak_2*0., psym=8
   oplot, [-1,nscans], [peak_avg_2, peak_avg_2], col=70
   oplot, [-1,nscans], th_flux[1]*[1., 1.], col=250
   xyouts, index, peak_2, strmid(scan_list,4, 12), charsi=0.7, orient=90
   legendastro, ['Array 2'], box=0, pos=[-0.5, yra[1]*0.9]
   legendastro, ['sigma/avg: '+strtrim( string(sigma_2/peak_avg_2*100.0,format=fmt),2)+'%'], box=0, /bottom
   myday = day_list[0]
   for i=0, nscans-1 do begin
      if day_list[i] ne myday then begin
         oplot, [i,i]*1, [-1,1]*1e10
         myday = day_list[i]
      endif
   endfor
   
   
   plot, index, tau_1mm, xr=[-1,nscans],/xs, position=pp1[3,*], /noerase, ytitle='Tau', xtitle='scan index'
   oplot, index, tau_2mm, col=250
   legendastro, ['1mm', '2mm'], col=[0, 250], box=0, pos=[-0.5, 0.1]
   myday = day_list[0]
   for i=0, nscans-1 do begin
      if day_list[i] ne myday then begin
         oplot, [i,i]*1, [-1,1]*1e10
         myday = day_list[i]
      endif
   endfor
   
   !x.charsize = 1
   myday = day_list[0]
   xyouts, 0.1, 0.01, strtrim(strmid(myday,6),2)
   for i=0, nscans-1 do begin
      if day_list[i] ne myday then begin
         oplot, [i,i]*1, [-1,1]*1e10
         myday = day_list[i]
         xyouts, i+0.1, 0.01, strtrim(strmid(myday,6),2)
      endif
   endfor
   !p.multi = 0
   outplot, /close
   
   print,''
   print,'======================================================'
   print,"Relative uncertainty A1: "+strtrim(100.*sigma_1/peak_avg_1,2)+" %"
   print,"Relative uncertainty A3: "+strtrim(100.*sigma_3/peak_avg_3,2)+" %"
   print,"Relative uncertainty A2: "+strtrim(100.*sigma_2/peak_avg_2,2)+" %"
   print,'======================================================'
   print,"Average flux density A1: "+strtrim(peak_avg_1,2)+" Jy/beam"
   print,"Average flux density A3: "+strtrim(peak_avg_3,2)+" Jy/beam"
   print,"Average flux density A2: "+strtrim(peak_avg_2,2)+" Jy/beam"
   print,'======================================================'
   print,"Flux ratio to expectation A1: "+strtrim(peak_avg_1/th_flux[0],2)
   print,"Flux ratio to expectation A3: "+strtrim(peak_avg_3/th_flux[2],2)
   print,"Flux ratio to expectation A2: "+strtrim(peak_avg_2/th_flux[1],2)
   print,'======================================================'
   
   print,''





   
   ;; plot of the flux using aperture photometry
   ;;--------------------------------------------------------------------
   print, ""
   print, "============================================================="
   print, " Aperture photometry"
   print, "============================================================="
   print, ""
   ap_flux_1 = ap_flux[wtokeep, 0]
   ap_flux_2 = ap_flux[wtokeep, 1]
   ap_flux_3 = ap_flux[wtokeep, 2]
   sigma_1 = stddev( ap_flux_1)
   sigma_2 = stddev( ap_flux_2)
   sigma_3 = stddev( ap_flux_3)
   ap_flux_avg_1 = avg( ap_flux_1)
   ap_flux_avg_2 = avg( ap_flux_2)
   ap_flux_avg_3 = avg( ap_flux_3)
   
   
   
   delvarx, yra    
   index = dindgen(n_elements(ap_flux_1))
   
   fmt = "(F5.1)"
   wind, 1, 1, /free, /large
   outfile = project_dir+'/aperture_photometry_'+strtrim(source)+'_NoTauCorrect'+strtrim(NoTauCorrect,2)+'_'+strtrim(nickname,2)
   if defined(suffix) then outfile = outfile+"_"+suffix
   outplot, file=outfile, png=png, ps=ps
   my_multiplot, 1, 4, pp, pp1, /rev, gap_y=0.02, xmargin=0.1, ymargin=0.1 ; 1e-6
   !x.charsize = 1e-10
   
   yra=th_flux[0]*[0.7, 1.7]
   plot,       index, ap_flux_1, ytitle='Flux Jy', xr=[-1,nscans], /xs, position=pp1[0,*], yra=yra, /ys, title=file_basename(project_dir)
   oploterror, index, ap_flux_1, err_ap_flux_1, psym=8 
   oplot, [-1,nscans], [ap_flux_avg_1, ap_flux_avg_1], col=70
   oplot, [-1,nscans], th_flux[0]*[1., 1.], col=250
   legendastro, ['Array 1'], box=0, pos=[-0.5, yra[1]*0.9]
   legendastro, ['sigma/avg: '+strtrim( string(sigma_1/ap_flux_avg_1*100.0d0,format=fmt),2)+'%'], box=0, /bottom
   myday = day_list[0]
   for i=0, nscans-1 do begin
      if day_list[i] ne myday then begin
         oplot, [i,i]*1, [-1,1]*1e10
         myday = day_list[i]
      endif
   endfor
   
   yra=th_flux[2]*[0.7, 1.5]
   plot,index, ap_flux_3, ytitle='Flux Jy', xr=[-1,nscans], /xs, position=pp1[1,*], /noerase, yra=yra, /ys
   oploterror, index, ap_flux_3, err_ap_flux_3, psym=8
   oplot, [-1,nscans], [ap_flux_avg_3, ap_flux_avg_3], col=70
   oplot, [-1,nscans], th_flux[2]*[1., 1.], col=250
   legendastro, ['Array 3'], box=0, pos=[-0.5, yra[1]*0.9]
   legendastro, ['sigma/avg: '+strtrim( string(sigma_3/ap_flux_avg_3*100.0,format=fmt)+'%',2)], box=0, /bottom
   myday = day_list[0]
   for i=0, nscans-1 do begin
      if day_list[i] ne myday then begin
         oplot, [i,i]*1, [-1,1]*1e10
         myday = day_list[i]
      endif
   endfor
   
   yra=th_flux[1]*[0.7, 1.3]
   plot, index, ap_flux_2, ytitle='Flux Jy',xr=[-1,nscans], /xs, position=pp1[2,*], /noerase, yra=yra, /ys
   oploterror, index, ap_flux_2, err_ap_flux_2, psym=8
   oplot, [-1,nscans], [ap_flux_avg_2, ap_flux_avg_2], col=70
   oplot, [-1,nscans], th_flux[1]*[1., 1.], col=250
   xyouts, index, ap_flux_2, strmid(scan_list,4, 12), charsi=0.7, orient=90
   legendastro, ['Array 2'], box=0, pos=[-0.5, yra[1]*0.9]
   legendastro, ['sigma/avg: '+strtrim( string(sigma_2/ap_flux_avg_2*100.0,format=fmt),2)+'%'], box=0, /bottom
   myday = day_list[0]
   for i=0, nscans-1 do begin
      if day_list[i] ne myday then begin
         oplot, [i,i]*1, [-1,1]*1e10
         myday = day_list[i]
      endif
   endfor
   
   
   plot, index, tau_1mm, xr=[-1,nscans],/xs, position=pp1[3,*], /noerase, ytitle='Tau', xtitle='scan index'
   oplot, index, tau_2mm, col=250
   legendastro, ['1mm', '2mm'], col=[0, 250], box=0, pos=[-0.5, 0.1]
   myday = day_list[0]
   for i=0, nscans-1 do begin
      if day_list[i] ne myday then begin
         oplot, [i,i]*1, [-1,1]*1e10
         myday = day_list[i]
      endif
   endfor
   
   !x.charsize = 1
   myday = day_list[0]
   xyouts, 0.1, 0.01, strtrim(strmid(myday,6),2)
   for i=0, nscans-1 do begin
      if day_list[i] ne myday then begin
         oplot, [i,i]*1, [-1,1]*1e10
         myday = day_list[i]
         xyouts, i+0.1, 0.01, strtrim(strmid(myday,6),2)
      endif
   endfor
   !p.multi = 0
   outplot, /close
   
   print,''
   print,'======================================================'
   print,"Relative uncertainty A1: "+strtrim(100.*sigma_1/ap_flux_avg_1,2)+" %"
   print,"Relative uncertainty A3: "+strtrim(100.*sigma_3/ap_flux_avg_3,2)+" %"
   print,"Relative uncertainty A2: "+strtrim(100.*sigma_2/ap_flux_avg_2,2)+" %"
   print,'======================================================'
   print,"Average flux density A1: "+strtrim(ap_flux_avg_1,2)+" Jy/beam"
   print,"Average flux density A3: "+strtrim(ap_flux_avg_3,2)+" Jy/beam"
   print,"Average flux density A2: "+strtrim(ap_flux_avg_2,2)+" Jy/beam"
   print,'======================================================'
   print,"Flux ratio to expectation A1: "+strtrim(ap_flux_avg_1/th_flux[0],2)
   print,"Flux ratio to expectation A3: "+strtrim(ap_flux_avg_3/th_flux[2],2)
   print,"Flux ratio to expectation A2: "+strtrim(ap_flux_avg_2/th_flux[1],2)
   print,'======================================================'
   
   print,''


   
endfor


stop



   
end
