;calibration_uranus_n2r12_np,'/home/macias/NIKA/Plots/Run25/kidpar_20171022s158_v0_LP_skd.fits','N2R12v1', outplot_dir='/home/macias/NIKA/Plots/Run25/',/png, /compute

pro calibration_uranus_n2r12_np, input_kidpar_file, nickname, $
                               compute=compute, png=png, ps=ps, $
                               outplot_dir=outplot_dir
  
  
;; Uranus scans Run10
;;restore, !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R12_v0.save"

;; take beammaps only for the moment
;;w = where( strupcase(scan.object) eq "URANUS" and $
;;           strmid( scan.comment, 0, 5) ne "focus", nw)

;;scan_list = scan[w].day+"s"+strtrim( scan[w].scannum,2)


;; After a selection based on FWHM:
;;scan_list = ['20170419s117', '20170419s123', '20170419s124', '20170419s125', $
;             '20170419s126', '20170419s132', '20170419s133', '20170419s134', '20170419s135', $
;             '20170420s107', '20170420s113', '20170420s114', '20170420s115', '20170421s154', $
;             '20170421s160', '20170421s161', '20170421s162', '20170421s166', '20170421s177', $
;             '20170421s185', '20170422s21', '20170422s22', '20170422s24', '20170422s25', $
;;              '20170422s38', '20170422s39', '20170423s102', '20170423s108', $
;;              ;'20170424s110', $
;;              '20170424s116', '20170424s117', '20170424s123', '20170424s124', $
;;              '20170424s125', '20170424s133', $ ;'20170424s134',
;;              ;'20170425s41', $
;;              '20170425s46', '20170425s52']
;; scan_list = [scan_list[0:6], $
;;              scan_list[9:10], $
;;              scan_list[13:14], $
;;              scan_list[20:30], scan_list[33]]

  ;scan_list = scan_list[ where( scan_list ne '20170420s107' or
scan_list =['20171025s41','20171025s42','20171027s49']

nscans = n_elements(scan_list)

ncpu_max = 24
optimize_nproc, nscans, ncpu_max, nproc
method = 'common_mode_kids_out'
source = 'Uranus'

nk_scan2run, scan_list[0]

if not keyword_set(outplot_dir) then outplot_dir=!nika.plot_dir

;; Aug. 18th, 2017 : new C0/C1 by Xavier
; input_kidpar_file = !nika.off_proc_dir+"/avg_kidpar_run10_BC_recal_skd.fits"

;; Make maps of all observations of Uranus
reset=0
if compute eq 1 then begin
   reset = 1
   for NoTauCorrect=0, 1 do begin
      project_dir = outplot_dir+"/Uranus_photometry_"+nickname+"_NoTauCorrect"+strtrim(NoTauCorrect,2)
      spawn, "mkdir -p "+project_dir
      split_for, 0, nscans-1, $
                 commands=['obs_nk_ps, i, scan_list, project_dir, '+$
                           'method, source, input_kidpar_file=input_kidpar_file, '+$
                           'reset=reset, NoTauCorrect=NoTauCorrect'], $
                 nsplit=nproc, $
                 varnames=['scan_list', 'project_dir', 'method', 'source', 'input_kidpar_file', $
                           'reset', 'NoTauCorrect']
   endfor
endif

scan_list = scan_list[ sort(scan_list)]
nscans = n_elements(scan_list)

;; check if all scans were indeed processed
run = !nika.run

for NoTauCorrect=0, 1 do begin
   project_dir = outplot_dir+"/Uranus_photometry_"+nickname+"_NoTauCorrect"+strtrim(NoTauCorrect,2)
   
   flux_1     = fltarr(nscans)
   flux_2     = fltarr(nscans)
   flux_3     = fltarr(nscans)
   err_flux_1 = fltarr(nscans)
   err_flux_2 = fltarr(nscans)
   err_flux_3 = fltarr(nscans)
   tau_1mm      = fltarr(nscans)
   tau_2mm      = fltarr(nscans)
   fwhm         = fltarr(nscans,3)
   for i =0, nscans-1 do begin
      dir = project_dir+"/v_1/"+strtrim(scan_list[i], 2)
      if file_test(dir+"/results.save") then begin
         restore,  dir+"/results.save"
         if info1.polar eq 1 then print, scan_list[i]+" is polarized !"
         fwhm[i,0] = info1.result_fwhm_1
         fwhm[i,1] = info1.result_fwhm_2
         fwhm[i,2] = info1.result_fwhm_3
         
         flux_1[i] = info1.result_flux_i1
         flux_2[i] = info1.result_flux_i2
         flux_3[i] = info1.result_flux_i3
         
         tau_1mm[ i] = info1.result_tau_1mm
         tau_2mm[ i] = info1.result_tau_2mm
         err_flux_1[i] = info1.result_err_flux_i1
         err_flux_2[i] = info1.result_err_flux_i2
         err_flux_3[i] = info1.result_err_flux_i3
      endif
   endfor

   sigma_1 = stddev( flux_1)
   sigma_2 = stddev( flux_2)
   sigma_3 = stddev( flux_3)
   flux_avg_1 = avg( flux_1)
   flux_avg_2 = avg( flux_2)
   flux_avg_3 = avg( flux_3)
   
   day_list = strmid(scan_list,0,8)

   delvarx, yra ; yra = [0, 20 ]               ; [0,10]

;   w = where( abs(fwhm[*,0]-12) lt 5, nw)

   index = dindgen(n_elements(flux_1))
   fmt = "(F5.2)"
   wind, 1, 1, /free, /large
   outfile = project_dir+'/photometry_uranus_NoTauCorrect'+strtrim(NoTauCorrect,2)+'_run'+strtrim(run,2)
   if defined(suffix) then outfile = outfile+"_"+suffix
   outplot, file=outfile, png=png, ps=ps
   my_multiplot, 1, 5, pp, pp1, /rev, gap_y=0.02, xmargin=0.1, ymargin=0.1 ; 1e-6
   !x.charsize = 1e-10
   plot,       index, flux_1, ytitle='Flux Jy', /xs, position=pp1[0,*], yra=yra, /ys, title=file_basename(project_dir)
   oploterror, index, flux_1, err_flux_1, psym=8

   oplot, index, flux_1*0 + flux_avg_1, col=70
   legendastro, ['Array 1', 'sigma/avg: '+strtrim( string(sigma_1/flux_avg_1,format=fmt),2)], box=0, /bottom
   myday = day_list[0]
   for i=0, nscans-1 do begin
      if day_list[i] ne myday then begin
         oplot, [i,i]*1, [-1,1]*1e10
         myday = day_list[i]
      endif
   endfor
   
   plot,       index, flux_3, ytitle='Flux Jy', /xs, position=pp1[1,*], /noerase, yra=yra, /ys
   oploterror, index, flux_3, err_flux_3, psym=8
   oplot, index, flux_3*0 + flux_avg_3, col=70
   legendastro, ['Array 3', 'sigma/avg: '+strtrim( string(sigma_3/flux_avg_3,format=fmt),2)], box=0, /bottom
   myday = day_list[0]
   for i=0, nscans-1 do begin
      if day_list[i] ne myday then begin
         oplot, [i,i]*1, [-1,1]*1e10
         myday = day_list[i]
      endif
   endfor

   plot,       index, flux_2, ytitle='Flux Jy', /xs, position=pp1[2,*], /noerase, yra=yra, /ys
   oploterror, index, flux_2, err_flux_2, psym=8
   oplot, index, flux_2*0 + flux_avg_2, col=70
   xyouts, index, flux_2, scan_list, charsi=0.5, orient=90
   legendastro, ['Array 2', 'sigma/avg: '+strtrim( string(sigma_2/flux_avg_2,format=fmt),2)], box=0, /bottom
   myday = day_list[0]
   for i=0, nscans-1 do begin
      if day_list[i] ne myday then begin
         oplot, [i,i]*1, [-1,1]*1e10
         myday = day_list[i]
      endif
   endfor

   plot, index, tau_1mm, /xs, position=pp1[3,*], /noerase
   legendastro, 'Tau 1mm', box=0, /bottom
   myday = day_list[0]
   for i=0, nscans-1 do begin
      if day_list[i] ne myday then begin
         oplot, [i,i]*1, [-1,1]*1e10
         myday = day_list[i]
      endif
   endfor

   !x.charsize = 1
   plot, index, tau_2mm, /xs, position=pp1[4,*], /noerase
   legendastro, 'Tau 2mm', box=0, /bottom
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

   wind, 1, 1, /free, /large
   outplot, file='fwhm_uranus_run'+strtrim(run,2), png=png, ps=ps
   !p.multi=[0,1,3]
   for j=0, 2 do begin
      plot, index, fwhm[*,j], /xs, psym=-4, xtitle='scan index', ytitle='FWHM (arcsec)', $
            /ys
      if j eq 2 then  xyouts, index, fwhm[*,j], scan_list, charsi=0.5, orient=90
      myday = day_list[0]
      for i=0, nscans-1 do begin
         if day_list[i] ne myday then begin
            oplot, [i,i]*1, [-1,1]*1e10
            myday = day_list[i]
         endif
      endfor
      legendastro, 'Array '+strtrim(j+1,2), box=0
   endfor
   !p.multi=0
   outplot, /close

   print, !nika.flux_uranus[0]/flux_avg_1
   print, !nika.flux_uranus[0]/flux_avg_3
   print, !nika.flux_uranus[1]/flux_avg_2

   stop
   
;; Recalibrate
   kidpar = mrdfits( input_kidpar_file, 1, /silent)
   w1 = where( (kidpar.array eq 1 or kidpar.array eq 3),nw1); and $
              ; kidpar.n_of_geom ge 2, nw1)
   kidpar[w1].calib          *= !nika.flux_uranus[0]/flux_avg_1
   kidpar[w1].calib_fix_fwhm *= !nika.flux_uranus[0]/flux_avg_1
   
   w1 = where( kidpar.array eq 2 ,nw2);and $
               ;kidpar.n_of_geom ge 2, nw1)
   kidpar[w1].calib          *= !nika.flux_uranus[1]/flux_avg_2
   kidpar[w1].calib_fix_fwhm *= !nika.flux_uranus[1]/flux_avg_2
   
   nk_write_kidpar, kidpar, "kidpar_recal_NoTauCorrect"+strtrim(NoTauCorrect,2)+".fits"
endfor

print, scan_list
print, nscans

end

