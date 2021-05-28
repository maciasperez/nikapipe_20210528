


;; Script to look at all the focus of the run that have been derived
;; by nk_focus_otf
;;-------------------------------------------------------------------

pro all_focus_monitoring, run

;run = 'N2R7'
  
case 1 of
   run eq 'N2R7': begin
      spawn, "ls "+!nika.plot_dir+"/Logbook/Scans/201612*/focus*save", file_list
      nk_scan2run, '20161210s1'
   end
   run eq 'N2R9': begin
      spawn, "ls /home/observer/NIKA/Plots/Run22/Logbook/Scans/201702*/focus*save", file_list
      nk_scan2run, '20170221s1'
   end
   run eq 'N2R10': begin
      spawn, "ls "+"/home/observer/NIKA/Plots/Run23/Logbook/Scans/*/focus*save", file_list
      nk_scan2run, '20170221s1'
   end
   run eq 'N2R12': begin
      spawn, "ls "+"/home/observer/NIKA/Plots/Run25/Logbook/Scans/*/focus*save", file_list
      nk_scan2run, '20170221s1'
   end
   
endcase

;; Set png or ps to 1 to save the final output plot
png = 1

nscans = n_elements(file_list)

;; Retrieve results
focus_res     = dblarr(3,2,nscans)
tau_res       = dblarr(3,nscans)
elevation_res = dblarr(nscans)
for iscan=0, nscans-1 do begin
   restore, file_list[iscan]
   tau_res[0,iscan]     = log_info.tau_1mm
   tau_res[2,iscan]     = log_info.tau_1mm
   tau_res[1,iscan]     = log_info.tau_2mm
   elevation_res[iscan] = log_info.mean_elevation
   for iarray=1, 3 do begin
      w = where( log_info.result_name eq "focus_peak_A"+strtrim(iarray,2), nw)
      if nw ne 0 then focus_res[iarray-1,0,iscan] = log_info.result_value[w]
      w = where( log_info.result_name eq "focus_fwhm_A"+strtrim(iarray,2), nw)
      if nw ne 0 then focus_res[iarray-1,1,iscan] = log_info.result_value[w]
   endfor
endfor

;; ;; Display all focus differences
;; wind, 1, 1, /free, /large
;; outplot, file='focus_differences_run'+strtrim(!nika.run,2), png=png, ps=ps
;; my_multiplot, 3, 2, pp, pp1, /rev, xmargin=0.1, ymargin=0.05, gap_y=0.1
;; plot, focus_res[0,0,*]-focus_res[2,0,*], psym=8, position=pp1[0,*], xtitle='Scan index', ytitle='mm'
;; legendastro, 'Peak focus A1 - A3', box=0
;; plot, focus_res[0,0,*]-focus_res[1,0,*], psym=8, position=pp1[1,*], xtitle='Scan index', ytitle='mm', /noerase
;; legendastro, 'Peak focus A1 - A2', box=0
;; plot, focus_res[1,0,*]-focus_res[2,0,*], psym=8, position=pp1[2,*], xtitle='Scan index', ytitle='mm', /noerase
;; legendastro, 'Peak focus A2 - A3', box=0
;; plot, focus_res[0,1,*]-focus_res[2,1,*], psym=8, position=pp1[3,*], xtitle='Scan index', ytitle='mm', /noerase
;; legendastro, 'Fwhm focus A1 - A3', box=0
;; plot, focus_res[0,1,*]-focus_res[1,1,*], psym=8, position=pp1[4,*], xtitle='Scan index', ytitle='mm', /noerase
;; legendastro, 'Fwhm focus A1 - A2', box=0
;; plot, focus_res[1,1,*]-focus_res[2,1,*], psym=8, position=pp1[5,*], xtitle='Scan index', ytitle='mm', /noerase
;; legendastro, 'Fwhm focus A2 - A3', box=0
;; outplot, /close
;; my_multiplot, /reset

;; 3-panel plot
index = indgen(nscans)
wind, 1, 1, /free, /large
outplot, file='focus_run'+strupcase(run)+'_3panelplot', png=png, ps=ps
my_multiplot, 1, 3, pp, pp1, /rev, xmargin=0.1, ymargin=0.05, gap_y=0.1
;; A1
plot, index, fltarr(nscans), title="Run "+strupcase(run)+" Z-focus analysis", ytitle="A1 [mm]", xtitle="running index", yr=[-1,1], /ys, /xs, /nodata, position=pp1[0,*]
oplot, index, focus_res[0,0,*], psym=8, col=250, symsize=1
oplot, index, fltarr(nscans)+median(focus_res[0,0,*]), col=250
oplot, index, focus_res[0,1,*], psym=8, col=200, symsize=1
oplot, index, fltarr(nscans)+median(focus_res[2,1,*]-focus_res[0,1,*]), col=200
legendastro, ['Flux', 'FWHM'], col=[250, 200], box=0, /trad, textcol=[250, 200] ,/bottom
;; A2
plot,  index, fltarr(nscans), ytitle="A2 [mm]", xtitle="running index", yr=[-1, 1], /ys, /xs, /nodata, position=pp1[1,*], /noerase
oplot, index, focus_res[1,0,*], psym=8, col=250, symsize=1
oplot, index, fltarr(nscans)+median(focus_res[1,0,*]), col=250
oplot, index, focus_res[1,1,*], psym=8, col=200, symsize=1
oplot, index, fltarr(nscans)+median(focus_res[1,1,*]), col=200
legendastro, ['Flux', 'FWHM'], col=[250, 200], box=0, /trad, textcol=[250, 200] ,/bottom
;;A3
plot,  index, fltarr(nscans), ytitle="A3 [mm]", xtitle="running index", yr=[-1, 1], /ys, /xs, /nodata, position=pp1[2,*], /noerase
oplot, index, focus_res[2,0,*], psym=8, col=250, symsize=1
oplot, index, fltarr(nscans)+median(focus_res[2,0,*]), col=250
oplot, index, focus_res[2,1,*], psym=8, col=200, symsize=1
oplot, index, fltarr(nscans)+median(focus_res[2,1,*]), col=200
legendastro, ['Flux', 'FWHM'], col=[250, 200], box=0, /trad, textcol=[250, 200] ,/bottom
outplot, /close
my_multiplot, /reset

;; 3-panel plot
index = indgen(nscans)
wind, 1, 1, /free, /large
outplot, file='focus_differences_run'+strupcase(run)+'_3panelplot', png=png, ps=ps
my_multiplot, 1, 3, pp, pp1, /rev, xmargin=0.1, ymargin=0.05, gap_y=0.1
;; A3-A1
plot, index, fltarr(nscans), title="Run "+strupcase(run)+" Z-focus analysis", ytitle="A3-A1 diff [mm]", xtitle="running index", yr=[-0.3, 0.4], /ys, /xs, /nodata, position=pp1[0,*]
oplot, index, focus_res[2,0,*]-focus_res[0,0,*], psym=8, col=250, symsize=1
oplot, index, fltarr(nscans)+median(focus_res[2,0,*]-focus_res[0,0,*]), col=250
oplot, index, focus_res[2,1,*]-focus_res[0,1,*], psym=8, col=200, symsize=1
oplot, index, fltarr(nscans)+median(focus_res[2,1,*]-focus_res[0,1,*]), col=200
legendastro, ['Flux', 'FWHM'], col=[250, 200], box=0, /trad, textcol=[250, 200] ,/bottom
;; A1-A2
plot,  index, fltarr(nscans), ytitle="A1-A2 diff [mm]", xtitle="running index", yr=[-0.3, 0.4], /ys, /xs, /nodata, position=pp1[1,*], /noerase
oplot, index, focus_res[0,0,*]-focus_res[1,0,*], psym=8, col=250, symsize=1
oplot, index, fltarr(nscans)+median(focus_res[0,0,*]-focus_res[1,0,*]), col=250
oplot, index, focus_res[0,1,*]-focus_res[1,1,*], psym=8, col=200, symsize=1
oplot, index, fltarr(nscans)+median(focus_res[0,1,*]-focus_res[1,1,*]), col=200
legendastro, ['Flux', 'FWHM'], col=[250, 200], box=0, /trad, textcol=[250, 200] ,/bottom
;;A3-A2
plot,  index, fltarr(nscans), ytitle="A3-A2 diff [mm]", xtitle="running index", yr=[-0.3, 0.4], /ys, /xs, /nodata, position=pp1[2,*], /noerase
oplot, index, focus_res[2,0,*]-focus_res[1,0,*], psym=8, col=250, symsize=1
oplot, index, fltarr(nscans)+median(focus_res[2,0,*]-focus_res[1,0,*]), col=250
oplot, index, focus_res[2,1,*]-focus_res[1,1,*], psym=8, col=200, symsize=1
oplot, index, fltarr(nscans)+median(focus_res[2,1,*]-focus_res[1,1,*]), col=200
legendastro, ['Flux', 'FWHM'], col=[250, 200], box=0, /trad, textcol=[250, 200] ,/bottom
outplot, /close
my_multiplot, /reset

;; Focus peak vs elevation and vs opacity
wind, 2, 2, /free, /large
outplot, file='focus_peak_vs_elevation_run'+strupcase(run), png=png, ps=ps
my_multiplot, 2, 3, pp, pp1, /rev, ymargin=0.1
for iarray=1, 3 do begin
   if iarray eq 3 then xtitle='Elevation' else xtitle=''
   plot,  tau_res[iarray-1,*], focus_res[iarray-1,0,*], yra=minmax(focus_res[*,0,*]), /ys, psym=8, $
          position=pp[0,iarray-1,*], /noerase, xtitle=xtitle
   oplot, tau_res[iarray-1,*], focus_res[iarray-1,0,*], col=250, psym=8
   legendastro, ['A'+strtrim(iarray,2), 'Flux focus'], textcol=250, box=0

   plot,  tau_res[iarray-1,*], focus_res[iarray-1,1,*], yra=minmax(focus_res[*,0,*]), /ys, psym=8, $
          position=pp[1,iarray-1,*], /noerase, xtitle=xtitle
   oplot, tau_res[iarray-1,*], focus_res[iarray-1,1,*], col=200, psym=8
   legendastro, ['A'+strtrim(iarray,2), 'FWHM focus'], textcol=200, box=0
endfor
outplot, /close

;; Focus peak vs elevation and vs opacity
wind, 2, 2, /free, /large
outplot, file='focus_peak_vs_elevation_run'+strupcase(run), png=png, ps=ps
my_multiplot, 2, 3, pp, pp1, /rev, ymargin=0.1
for iarray=1, 3 do begin
   if iarray eq 3 then xtitle='Tau' else xtitle=''
   plot,  tau_res[iarray-1,*], focus_res[iarray-1,0,*], yra=minmax(focus_res[*,0,*]), /ys, psym=8, $
          position=pp[0,iarray-1,*], /noerase, xtitle=xtitle
   oplot, tau_res[iarray-1,*], focus_res[iarray-1,0,*], col=250, psym=8
   legendastro, ['A'+strtrim(iarray,2), 'Flux focus'], textcol=250, box=0

   plot,  tau_res[iarray-1,*], focus_res[iarray-1,1,*], yra=minmax(focus_res[*,0,*]), /ys, psym=8, $
          position=pp[1,iarray-1,*], /noerase, xtitle=xtitle
   oplot, tau_res[iarray-1,*], focus_res[iarray-1,1,*], col=200, psym=8
   legendastro, ['A'+strtrim(iarray,2), 'FWHM focus'], textcol=200, box=0
endfor
outplot, /close

my_multiplot, /reset



end
