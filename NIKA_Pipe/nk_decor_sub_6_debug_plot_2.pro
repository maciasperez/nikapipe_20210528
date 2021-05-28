
if param.debug then begin &$
   ata = out_coeffs##transpose(out_coeffs) &$
   atam1 = invert(ata) &$
   atd = toi##transpose(out_coeffs) &$
   out_common_modes = transpose(atam1##transpose(atd)) &$
   wind, 1, 1, /free, /large &$
   nmodes = n_elements(out_common_modes[*,0]) &$
   my_multiplot, 1, 1, ntot=nmodes, pp, pp1, /rev &$
   make_ct, param.niter_cm, ct &$
   for imode=0, nmodes-1 do begin &$
      plot, out_common_modes[imode,*], /xs, /ys, $
            position=pp1[imode,*], /noerase, title='common mode '+strtrim(imode,2) &$
   endfor &$
   stop &$
endif
