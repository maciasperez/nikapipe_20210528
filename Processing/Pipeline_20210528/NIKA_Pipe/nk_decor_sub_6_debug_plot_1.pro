
if param.debug then begin &$
   wind, 1, 1, /f, /large &$
   my_multiplot, 3, 2, pp, pp1, /rev &$
   for iarray=1, 3 do begin  &$
      w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)  &$
      if nw1 ne 0 then begin  &$
         m = median(toi[w1,*],dim=1)  &$
         nkids = n_elements(kidpar)  &$
         make_ct, nkids, ct  &$
         yra=array2range( toi[w1,*]) &$
         plot, toi[w1[0],*], yra=yra, /ys, position=pp[iarray-1,0,*], /noerase &$
         legendastr, "A"+strtrim(iarray,2) &$
         slope = dblarr(nw1)  &$
         for i=0, nw1-1 do begin  &$
            oplot, toi[w1[i],*], col=ct[w1[i]]  &$
            fit = linfit( m, toi[w1[i],*])  &$
            slope[i] = fit[1]  &$
         endfor  &$
         plot, slope, position=pp[iarray-1,1,*], /noerase  &$
         legendastro, 'slope to median mode' &$
      endif &$
   endfor &$
   stop &$
endif
