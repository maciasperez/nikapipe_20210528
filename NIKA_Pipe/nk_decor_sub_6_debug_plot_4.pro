
if param.debug then begin &$
   wind, 1, 1, /free, /large, xpos=100 &$
   nmodes = n_elements(all_out_common_modes[0,*,0]) &$
   my_multiplot, 1, 1, ntot=nmodes, pp, pp1 &$
   make_ct, param.niter_cm, ct &$
   for imode=0, nmodes-1 do begin &$
   plot, all_out_common_modes[0,imode,*], /xs, /ys, $
   position=pp1[imode,*], /noerase, title='common mode '+strtrim(imode,2) &$
   for iter=0, param.niter_cm-1 do oplot, all_out_common_modes[iter,imode,*], col=ct[iter] &$
   endfor &$
   stop &$
endif
