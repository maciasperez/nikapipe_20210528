
if param.plot_ps eq 0 and param.plot_z eq 0 then wind, 2, 2, /free, /large
outplot, file=param.project_dir+'/Plots/imcm_decorr_modes_and_residuals_'+param.scan+"_A"+strtrim(iarray,2), $
         png=param.plot_png, ps=param.plot_ps, z=param.plot_z
my_multiplot, 1, 1, pp, pp1, ntot=(nboxes+nt+nsubbands), /rev, /full, /dry, $
              ymin=0.3, ymargin=0.01, ymax=0.95, xmin=0.02, xmax=0.95, xmargin=0.001
make_ct, param.niter_atm_el_box_modes, ct
time = dindgen(nsn)/!nika.f_sampling
xyouts, 0.05, 0.2, /norm, param.scan, orient=90
for it=0, nt+nboxes+nsubbands-1 do begin &$
   title = 'A'+strtrim(iarray,2) &$
   if it eq 0 then title += ' atm' else title += ' box '+strtrim(it-1,2) &$
   plot, time, all_out_common_modes[0,it,*], /xs, /ys, $
         position=pp1[it,*], /noerase, chars=0.6, title=title &$
   for iter=0, param.niter_atm_el_box_modes-1 do oplot, time, all_out_common_modes[iter,it,*], col=ct[iter] &$
endfor

my_multiplot, param.niter_atm_el_box_modes, 1, pp, pp1, ymax=0.25, ymin=0.01, $
              xmin=0.02, xmax=0.95, xmargin=0.001
for iter=0, param.niter_atm_el_box_modes-1 do $
   np_histo, resid_rms[iter,*], position=pp1[iter,*], $
             /noerase, /fit, /force, /fill, colorfit=ct[iter], $
             xtitle='TOI residual rms'
outplot, /close, /verb
