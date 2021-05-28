


;; Script to look at all the focus of the run that have been derived
;; by nk_focus_otf
;;-------------------------------------------------------------------

pro focus_compare_runs, run_list, ps = ps

;run = 'N2R7'
  nruns = n_elements(run_list)
  

focus_list = list()
tau_list = list()
elevation_list= list()
scan_day_list = list()
scan_num_list = list()
ntotscans = 0
runstr = ''
for irun=0,nruns-1 do begin
   run = run_list[irun]
   runstr = runstr+'_'+run
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
      ;nk_scan2run, '201721s1'
   end
   run eq 'N2R12': begin
      spawn, "ls "+"/home/observer/NIKA/Plots/Run25/Logbook/Scans/*/focus*save", file_list
      ;nk_scan2run, '20170221s1'
   end
   
endcase

;; Set png or ps to 1 to save the final output plot
png = 1
if keyword_set(ps) then begin
   png  = 0
   ps   = 1
endif


nscans = n_elements(file_list)
ntotscans += nscans

;; Retrieve results
focus_res     = dblarr(3,2,nscans)
tau_res       = dblarr(3,nscans)
elevation_res = dblarr(nscans)
scan_day = lonarr(nscans)
scan_num = lonarr(nscans)

for iscan=0, nscans-1 do begin
   restore, file_list[iscan]
   scan_day[iscan]      = long(log_info.day)
   scan_num[iscan]      = long(log_info.scan_num)
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

focus_list->add, focus_res
tau_list->add, tau_res
elevation_list->add, elevation_res
scan_day_list->add, scan_day
scan_num_list->add, scan_num
endfor



indtotscans = indgen(ntotscans)

runcolor =[50,100,250,200,150]

;; 3-panel plot
wind, 1, 1, /free, /large
outplot, file='focus_runs_'+strupcase(runstr)+'_3panelplot', png=png, ps=ps
my_multiplot, 1, 3, pp, pp1, /rev, xmargin=0.1, ymargin=0.05, gap_y=0.1
;; A1
plot, indtotscans, indtotscans,title='Z focus', ytitle="A1 [mm]", xtitle="running index", yr=[-1.2,1.2], /ys, /xs, /nodata, position=pp1[0,*]

index0=0
for irun=0,nruns-1 do begin

   nscans = n_elements(scan_day_list[irun])
   index = index0+indgen(nscans)
   index0 +=  nscans
   focus_res = focus_list[irun]
;plot, index, fltarr(nscans), title="Run "+strupcase(run)+" Z-focus analysis", ytitle="A1 [mm]", xtitle="running index", yr=[-1,1], /ys, /xs, /nodata, position=pp1[0,*]
   oplot, index, focus_res[0,0,*], psym=8, col=runcolor[irun], symsize=1
   oplot, index, fltarr(nscans)+median(focus_res[0,0,*]), col=runcolor[irun]
   oplot, index, focus_res[0,1,*], psym=4, col=runcolor[irun], symsize=1
   oplot, index, fltarr(nscans)+median(focus_res[2,1,*]-focus_res[0,1,*]), col=runcolor[irun],linestyle=2,thick=2
endfor

legendastro, ['Flux', 'FWHM','Flux Mean','FHM mean'], col=[0,0,0,0], box=0, /trad,psym=[8,4,0,0],linestyle=[0,0,0,2] ,/top, /left,thick=2
legendastro, run_list, col=runcolor[0:nruns-1], box=0, /trad ,/top, /right


;; A2
plot,  indtotscans, indtotscans, ytitle="A2 [mm]", xtitle="running index", yr=[-1.2, 1.2], /ys, /xs, /nodata, position=pp1[1,*], /noerase
index0=0
for irun=0,nruns-1 do begin
   nscans = n_elements(scan_day_list[irun])
   index = index0+indgen(nscans)
   index0 +=  nscans
   focus_res = focus_list[irun]
   
   oplot, index, focus_res[1,0,*], psym=8, col=runcolor[irun], symsize=1
   oplot, index, fltarr(nscans)+median(focus_res[1,0,*]), col=runcolor[irun]
   oplot, index, focus_res[1,1,*], psym=4, col=runcolor[irun], symsize=1
   oplot, index, fltarr(nscans)+median(focus_res[1,1,*]), col=runcolor[irun],linestyle=2,thick =2
endfor
legendastro, ['Flux', 'FWHM','Flux Mean','FHM mean'], col=[0,0,0,0], box=0, /trad,psym=[8,4,0,0],linestyle=[0,0,0,2] ,/top, /left,thick=2
legendastro, run_list, col=runcolor[0:nruns-1], box=0, /trad ,/top, /right

;;A3
plot,  indtotscans, indtotscans, ytitle="A3 [mm]", xtitle="running index", yr=[-1.2, 1.2], /ys, /xs, /nodata, position=pp1[2,*], /noerase
index0=0
for irun=0,nruns-1 do begin
   nscans = n_elements(scan_day_list[irun])
   index = index0+indgen(nscans)
   index0 +=  nscans
   focus_res = focus_list[irun]
   oplot, index, focus_res[2,0,*], psym=8, col=runcolor[irun], symsize=1
   oplot, index, fltarr(nscans)+median(focus_res[2,0,*]), col=runcolor[irun]
   oplot, index, focus_res[2,1,*], psym=4, col=runcolor[irun], symsize=1
   oplot, index, fltarr(nscans)+median(focus_res[2,1,*]), col=runcolor[irun],linestyle=2, thick =2

endfor
legendastro, ['Flux', 'FWHM','Flux Mean','FHM mean'], col=[0,0,0,0], box=0, /trad,psym=[8,4,0,0],linestyle=[0,0,0,2] ,/top, /left,thick=2
legendastro, run_list, col=runcolor[0:nruns-1], box=0, /trad ,/top, /right

outplot, /close
my_multiplot, /reset


;; 3-panel plot
index = indgen(nscans)
wind, 1, 1, /free, /large
outplot, file='focus_differences_runs_'+strupcase(runstr)+'_3panelplot', png=png, ps=ps
my_multiplot, 1, 3, pp, pp1, /rev, xmargin=0.1, ymargin=0.05, gap_y=0.1
;; A3-A1
plot, indtotscans,indtotscans, title='Z focus difference', ytitle="A3-A1 diff [mm]", xtitle="running index", yr=[-0.6, 0.6], /ys, /xs, /nodata, position=pp1[0,*]
index0=0
for irun=0,nruns-1 do begin
   nscans = n_elements(scan_day_list[irun])
   index = index0+indgen(nscans)
   index0 +=  nscans
   focus_res = focus_list[irun]


   oplot, index, focus_res[2,0,*]-focus_res[0,0,*], psym=8, col=runcolor[irun], symsize=1
   oplot, index, fltarr(nscans)+median(focus_res[2,0,*]-focus_res[0,0,*]), col=runcolor[irun]
   oplot, index, focus_res[2,1,*]-focus_res[0,1,*], psym=4, col=runcolor[irun], symsize=1
   oplot, index, fltarr(nscans)+median(focus_res[2,1,*]-focus_res[0,1,*]), col=runcolor[irun], thick=2, linestyle=2
endfor
legendastro, ['Flux', 'FWHM','Flux Mean','FHM mean'], col=[0,0,0,0], box=0, /trad,psym=[8,4,0,0],linestyle=[0,0,0,2] ,/top, /left,thick=2
legendastro, run_list, col=runcolor[0:nruns-1], box=0, /trad ,/top, /right


;; A1-A2
plot,  indtotscans, indtotscans, ytitle="A1-A2 diff [mm]", xtitle="running index", yr=[-0.6, 0.6], /ys, /xs, /nodata, position=pp1[1,*], /noerase
index0=0
for irun=0,nruns-1 do begin
   nscans = n_elements(scan_day_list[irun])
   index = index0+indgen(nscans)
   index0 +=  nscans
   focus_res = focus_list[irun]

   oplot, index, focus_res[0,0,*]-focus_res[1,0,*], psym=8, col=runcolor[irun], symsize=1
   oplot, index, fltarr(nscans)+median(focus_res[0,0,*]-focus_res[1,0,*]), col=runcolor[irun]
   oplot, index, focus_res[0,1,*]-focus_res[1,1,*], psym=4, col=runcolor[irun], symsize=1
   oplot, index, fltarr(nscans)+median(focus_res[0,1,*]-focus_res[1,1,*]), col=runcolor[irun],thick=2, linestyle=2
endfor
legendastro, ['Flux', 'FWHM','Flux Mean','FHM mean'], col=[0,0,0,0], box=0, /trad,psym=[8,4,0,0],linestyle=[0,0,0,2] ,/top, /left,thick=2
legendastro, run_list, col=runcolor[0:nruns-1], box=0, /trad ,/top, /right


;;A3-A2
plot,  indtotscans, indtotscans, ytitle="A3-A2 diff [mm]", xtitle="running index", yr=[-0.6, 0.6], /ys, /xs, /nodata, position=pp1[2,*], /noerase
index0=0
for irun=0,nruns-1 do begin
   nscans = n_elements(scan_day_list[irun])
   index = index0+indgen(nscans)
   index0 +=  nscans
   focus_res = focus_list[irun]

   oplot, index, focus_res[2,0,*]-focus_res[1,0,*], psym=8, col=runcolor[irun], symsize=1
   oplot, index, fltarr(nscans)+median(focus_res[2,0,*]-focus_res[1,0,*]), col=runcolor[irun]
   oplot, index, focus_res[2,1,*]-focus_res[1,1,*], psym=4, col=runcolor[irun], symsize=1
   oplot, index, fltarr(nscans)+median(focus_res[2,1,*]-focus_res[1,1,*]), col=runcolor[irun],thick=2, linestyle=2
endfor
legendastro, ['Flux', 'FWHM','Flux Mean','FHM mean'], col=[0,0,0,0], box=0, /trad,psym=[8,4,0,0],linestyle=[0,0,0,2] ,/top, /left,thick=2
legendastro, run_list, col=runcolor[0:nruns-1], box=0, /trad ,/top, /right

outplot, /close
my_multiplot, /reset



end
