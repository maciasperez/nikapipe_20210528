
if param.plot_ps eq 0 and param.plot_z eq 0 then wind, 2, 2, /free, /large
outplot, file=param.project_dir+'/Plots/imcm_decorr_modes_convergence_'+param.scan+"_A"+strtrim(iarray,2), $
         png=param.plot_png, ps=param.plot_ps, z=param.plot_z
nmodes = nt+nboxes+nsubbands
my_multiplot, 1, 1, ntot=nmodes, pp, pp1, /rev, /full, /dry, $
              xmax=0.5, xmargin=0.01
my_multiplot, 1, 1, ntot=nmodes, pp, pp2, /rev, /full, /dry, $
              xmin=0.5, xmargin=0.01, xmax=0.97
make_ct, param.niter_atm_el_box_modes, ct
for imode=0, nmodes-1 do begin &$
   plot, all_out_common_modes[1,imode,*]-all_out_common_modes[0,imode,*], $
         /xs, /ys, position=pp1[imode,*], /noerase, $
         charsize=1d-10 &$
   legendastro, 'Mode '+strtrim(imode,2) &$
         for iter=1, param.niter_atm_el_box_modes-1 do begin &$
      oplot, all_out_common_modes[iter,imode,*]-all_out_common_modes[iter-1,imode,*], col=ct[iter-1] &$
         endfor &$

   syms=1 &$
   my_rms = dblarr(param.niter_atm_el_box_modes-1) &$
   for iter=1, param.niter_atm_el_box_modes-1 do begin &$
      my_rms[iter-1] = stddev( all_out_common_modes[iter,imode,*]-all_out_common_modes[iter-1,imode,*]) &$
         endfor &$
   if imode mod n_elements(pp[*,0,0]) eq 0 then ycharsize=0.5 else ycharsize=1d-10 &$
; change normalization to look at the convergence differently
   my_rms_norm = my_rms[0]       &$
   plot, my_rms/my_rms_norm, /xs, psym=-8, position=pp2[imode,*], /noerase, $
         xcharsize = 1d-10, ycharsize=ycharsize, yra=[0,2], syms=syms &$
   for iter=0, param.niter_atm_el_box_modes-2 do begin &$
      oplot, [iter], [my_rms[iter]/my_rms_norm], psym=8,syms=syms,col=ct[iter] &$
         endfor &$
   oplot, [-1,1]*1d10, [1,1] &$
   oplot, [-1,1]*1d10, [1,1]+0.1 &$
   oplot, [-1,1]*1d10, [1,1]-0.1 &$
   oplot, [-1,1]*1d10, [1,1]*0.1 &$
   legendastro, 'Mode '+strtrim(imode,2) &$
endfor
outplot, /close, /verb
