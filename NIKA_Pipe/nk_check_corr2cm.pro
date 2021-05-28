
;; Look at corr2cm coefficients per subscan and per scan and compare
;; to calib_fix_fwhm
;;-----------------------------------------------------------------

;+
pro nk_check_corr2cm, param, info, data, kidpar
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_check_corr2cm'
   return
endif

toi        = data.toi
flag       = data.flag
off_source = data.off_source*0.d0 + 1.d0

;; On the entire scan
nk_get_one_mode_per_array, param, info, toi, flag, off_source, kidpar, common_mode
kidpar1 = kidpar

;; Per subscan
nsubscans = max(data.subscan) - min(data.subscan) + 1
nkids = n_elements(kidpar)
corr2cm = dblarr(nsubscans,nkids)
w1 = where( kidpar.type eq 1, nw1)
for i=0, nsubscans-1 do begin
   isub = i + min( data.subscan)
   wsubscan = where( data.subscan eq isub)
   toi        = data[wsubscan].toi
   flag       = data[wsubscan].flag
   off_source = data[wsubscan].off_source
   nk_get_one_mode_per_array, param, info, toi, flag, off_source, kidpar1, common_mode
   corr2cm[i,w1] = kidpar1[w1].corr2cm
endfor

array_col = [70, 250, 100]
psym = -8
syms = 0.5
if param.plot_ps eq 0 and param.plot_z eq 0 then wind, 1, 1, /free, /large
outplot, file=param.project_dir+'/Plots/check_corr2cm_full_scan_plot_'+param.scan, $
         png=param.plot_png, ps=param.plot_ps, z=param.plot_z
for iarray=1, 3 do begin
   w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)

   if iarray eq 1 then title = param.scan else title=''

   ;; full scan corr2cm
   my_multiplot, 3, 2, pp, pp1, /rev, gap_x=0.05
   np_histo, kidpar[w1].corr2cm, position=pp[iarray-1,0,*], $
             /noerase, /fill, fcol=array_col[iarray-1], /fit, title=title, $
             xtitle='full scan corr2cm'
   legendastro, ['A'+strtrim(iarray,2), $
                 'full scan corr2cm']

   ;; ratio to calib_fix_fwhm, renorm to averages to see relative
   ;; variations
   a = kidpar[w1].corr2cm       /avg( kidpar[w1].corr2cm)
   b = kidpar[w1].calib_fix_fwhm/avg( kidpar[w1].calib_fix_fwhm)
   yra = [-1,1]*3
   plot, a/b, $
         /noerase, position=pp[iarray-1,1,*], psym=psym, syms=syms, $
         ytitle='full scan corr2cm/calib_fix_fwhm', yra=yra, /ys, /xs
   oplot, a/b, col=array_col[iarray-1], psym=psym, syms=syms
   legendastro, 'A'+strtrim(iarray,2), textcol=array_col[iarray-1]
endfor
outplot, /close, /verb

;; for iarray=1, 3 do begin
;;    w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
;; 
;;    if iarray eq 1 then title = param.scan else title=''
;; 
;;    ;; Variability accross the scan
;;    if param.plot_ps eq 0 and param.plot_z eq 0 then wind, 2, 2, /free, /large
;;    outplot, file=param.project_dir+'/Plots/check_corr2cm_per_subscan_plot_'+param.scan+'_A'+strtrim(iarray,2), $
;;             png=param.plot_png, ps=param.plot_ps, z=param.plot_z
;;    nplots = 25
;;    yra = [-1,2]
;;    my_multiplot, 1, 1, ntot=nplots, pp, pp1, /rev, /full, /dry
;;    nkids_per_plot = nw1/nplots  ; proxy
;;    make_ct, nkids_per_plot, ct
;;    for i=0, nw1-1 do begin
;;       ip = (i/nkids_per_plot) < (nplots-1)
;;       if ip eq 0 then title=param.scan+", A"+strtrim(iarray,2) else title=''
;;       plot, corr2cm[*,w1[i]]/kidpar[w1[i]].corr2cm, /xs, $
;;             position=pp1[ip,*], /noerase, yra=yra, /ys, psym=psym, syms=syms, $
;;             col=ct[i mod nkids_per_plot], title=title, xchars=1d-10
;;    endfor
;;    xyouts, 0.05, 0.3, 'corr2cm_per_subscan / corr2cm_full_scan', orient=90, /norm
;;    outplot, /close, /verb
;; endfor

exit:
end
