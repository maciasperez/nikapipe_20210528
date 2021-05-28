

stokes = ['I', 'Q', 'U']
case istokes of
   0:toi = data.toi
   1:toi = data.toi_q
   2:toi = data.toi_u
endcase

nsn = n_elements(data)
for iarray=1, 3 do begin &$
   w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1) &$
   if nw1 ne 0 then begin &$
      
      nk_get_median_common_mode, param, info, toi[w1,*], data.flag[w1], $
                                 data.off_source[w1], kidpar[w1], median_common_mode &$

   if here_plot eq 1 then make_ct, nw1, ct &$
   if here_plot eq 1 then wind, 1, 1, /f, /large &$
      if here_plot eq 1 then my_multiplot, 1, 3, pp, pp1, /rev &$
   if here_plot eq 1 then plot, toi[w1[0],*], /xs, yra=array2range(toi[w1,*]), title='Array '+strtrim(iarray,2), position=pp1[0,*] &$
   if here_plot eq 1 then for i=0, nw1-1 do oplot, toi[w1[i],*], col=ct[i] &$
   if here_plot eq 1 then oplot, median_common_mode, col=0, thick=2 &$
   if here_plot eq 1 then plot, data.subscan, /xs, /noerase, position=pp1[0,*],  col=70
   if here_plot eq 1 then legendastro, 'Stokes '+strupcase(stokes[istokes]) &$
      
      s = dblarr(nw1) &$
      yy = dblarr(nw1,nsn) &$
      for i=0, nw1-1 do begin &$
         ikid = w1[i] &$
         woff = where( data.off_source[ikid] eq 1 and $
                       (data.flag[ikid] eq 0 or data.flag[ikid] eq 2L^11), nwoff) &$
         if nwoff gt 10 then begin &$
            fit = linfit( median_common_mode[woff], toi[ikid,woff]) &$
            yy[i,*] = toi[ikid,*] - fit[0] - fit[1]*median_common_mode &$
            s[i] = stddev( yy[i,woff]) &$
         endif &$
      endfor &$
      if here_plot eq 1 then plot, s, /xs, yra=avg(s)+[-5,5]*stddev(s), /ys, position=pp1[1,*], /noerase &$
      if here_plot eq 1 then oplot, s*0 + avg(s) &$
      if here_plot eq 1 then for j=-3, 3 do oplot, s*0 + avg(s) + j*stddev(s), line=2 &$
      
      if here_plot eq 1 then plot, yy[0,*], /xs, yra=array2range(yy), /ys, position=pp1[2,*], /noerase &$
      nn=0 &$
      for i=0, nw1-1 do begin &$
         if s[i] gt (avg(s)+3*stddev(s)) then begin &$
            mycol=250 &$
            nn++ &$
            kidpar[w1[i]].type = 3 &$
         endif else begin &$
            mycol=0 &$
         endelse &$
         if here_plot eq 1 then oplot, yy[i,*], col=mycol &$
      endfor &$
      print, strtrim(nn,2)+"/"+strtrim(nw1,2) &$
   endif &$
endfor
