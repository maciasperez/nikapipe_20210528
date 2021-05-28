
;; Compute the correlation of each kid to the common mode of its
;; matrix to give a 1st quick estimate of kids stability

pro kid_monitor, scan, data=data, kidpar=kidpar, show=show, $
                 output_kidpar_dir=output_kidpar_dir, $
                 noplot=noplot, badkid=badkid

if not keyword_set(output_kidpar_dir) then output_kidpar_dir = "."
if file_test(output_kidpar_dir, /dir) ne 1 then spawn, "mkdir -p "+output_kidpar_dir

;; If data is not passed in input, then it is read from "scan" and preprocessed
if not keyword_set(data) then begin
   nk_default_param, param
   nk_default_info, info
   nk_init_grid, param, info, grid
   
;   param.do_opacity_correction = 0
   if keyword_set(noplot) then param.do_plot=0
   
   nk_scan2run, scan, run
   nk_update_param_info, scan, param, info, xml=xml, katana=katana
   nk_scan_preproc, param, info, data, kidpar, grid, badkid=badkid
   if info.status ne 0 then return
endif

if defined(kidpar) eq 0 then begin
   message, /info, "kidpar is undefined"
   stop
endif

;; Check which kids saturated or went out of resonnance or overlap...
w = where( badkid.(0) ne 0, nw)
if nw ne 0 then kidpar[w].type = 11
w = where( badkid.(1) ne 0, nw)
if nw ne 0 then kidpar[w].type = 12
w = where( badkid.(2) ne 0, nw)
if nw ne 0 then kidpar[w].type = 13

;; Compute correlations and display plot if requested
if keyword_set(show) then wind, 1, 1, /free, /large
for iarray=1, 3 do begin
   w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
   if keyword_set(show) then my_multiplot, 1, 1, ntot=nw1, pp, pp1, /rev, /full
   if nw1 ne 0 then begin
      cm = median( data.toi[w1], dim=1)
      for i=0, nw1-1 do begin
         ikid = w1[i]
         w = where( data.flag[ikid] eq 0, nw)
         if nw ne 0 then begin
            if keyword_set(show) then plot, cm[w], data[w].toi[ikid], psym=3, position=pp1[i,*], /noerase
            fit = linfit( cm[w], data[w].toi[ikid])
            kidpar[ikid].corr2cm = fit[1]
         endif
      endfor
   endif
endfor
if keyword_set(show) then my_multiplot, /reset

;; Save result
nk_write_kidpar, kidpar, output_kidpar_dir+"/kidpar_monitor_"+scan+".fits"


end
