
if param.debug then begin &$
   all_out_common_modes = dblarr(param.niter_cm,nboxes+3,nsn) &$
   if iter_cm eq 1 then wind, 1, 1, /free, /large &$
    &$
   my_multiplot, 2, param.niter_cm, pp, pp1, /rev &$
   w1 = where( kidpar.type eq 1 and kidpar.array eq 1, nw1) &$
   ikid = w1[10] &$
    &$
   y = junk[ikid,*]-out_temp[ikid,*] &$
   power_spec, junk[ikid,*]-my_baseline(junk[ikid,*], base=0.05), !nika.f_sampling, pw, freq &$
   power_spec, y-my_baseline(y,base=0.05), !nika.f_sampling, pw1 &$
   plot, y, /xs, /ys, position=pp[0,iter_cm-1,*], /noerase, $
          title='iter '+strtrim(iter_cm,2) &$
   legendastro, ['toi - out_temp: ikid '+strtrim(ikid,2)] &$
   plot_oo, freq, pw, /xs, /ys, position=pp[1,iter_cm-1,*], /noerase &$
   oplot, freq, pw1, col=250 &$
endif
