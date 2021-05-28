
wind, 1, 1, /free, /large
my_multiplot, 2, 2, pp, pp1, /rev, gap_x=0.1
xra = [5200,5600]
for iarray=1, 3 do begin &$
   w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1) &$
   if nw1 ne 0 then begin &$
      if iarray eq 2 then yra=[-2,2] else yra = [-1,1]*5 &$
      plot, toi[w1[0],*]-toi[w1[0],0], yra=yra, /ys, /xs, $
            position=pp1[iarray-1,*], /noerase, xra=xra, title='A'+strtrim(iarray,2) &$
      make_ct, nw1, ct &$
      for i=0, nw1-1 do oplot, toi[w1[i],*]-toi[w1[i],0], col=ct[i] &$
   endif &$
endfor
plot, atm_cm, xra=xra, position=pp1[3,*],/noerase, title='atm_cm '+param.scan

nwmax = -1
kid_str = create_struct('w11', -1L, 'w12', -1L, 'w13', -1L)
for iarray=1, 3 do begin &$
   w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1) &$
   if nw1 gt nwmax then nwmax=nw1 &$
endfor
kid_str = replicate(kid_str, nwmax)
for iarray=1, 3 do begin &$
   w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1) &$
   kid_str[0:nw1-1].(iarray-1) = w1 &$
endfor

my_multiplot, 1, 4, pp, pp1, /rev
erase
for i=0, nwmax-1 do begin &$
   plot, atm_cm, xra=xra, position=pp1[3,*] &$
   for iarray=1, 3 do begin &$
      if iarray eq 2 then yra=[-2,2] else yra = [-1,1]*5 &$
      ikid = kid_str[i].(iarray-1) &$
      if ikid ge 0 then plot, toi[ikid,*]-toi[ikid,0], position=pp1[iarray-1,*], $
                              /noerase, title=strtrim(ikid,2)+", A"+strtrim(iarray,2), $
                              xra=xra, /xs, yra=yra &$
   endfor &$
   wait, 0.2 &$
endfor
stop
