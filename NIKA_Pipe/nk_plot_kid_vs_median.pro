

function gauss_cdf, x
  return, erf(x/sqrt(2.d0))
end


pro nk_plot_kid_vs_median, param, info, data, kidpar, iarray, $
                           comment=comment, stop=stop, ks=ks

wind, 1, 1, /free, /large, xpos=(iarray-1)*100
won = where( kidpar.array eq iarray and kidpar.type ne 2, nwon)
w1  = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
toi_med = median( data.toi[w1], dim=1)
my_multiplot, 1, 1, ntot=nwon, /full, pp, pp1, xmargin=0.02, ymargin=0.02, $
              xmin=0.02, ymin=0.1
for i=0, nwon-1 do begin
   case kidpar[won[i]].type of
      1: col=70
      2: col=0
      else: col=200
   endcase
   plot, toi_med, data.toi[won[i]], psym=3, $
         position=pp1[i,*], /noerase, col=col
endfor
my_multiplot, /reset
if keyword_set(comment) then xyouts, 0.1*!d.x_size, 0.05*!d.y_size, comment,  /device
xyouts, 0.1*!d.x_size, 0.02*!d.y_size, "A"+strtrim(iarray,2)+", nwon: "+strtrim(nwon,2)+" KIDs", /device


if keyword_set(ks) then begin
   ikid = w1[10]
   wind, 1, 1, /free, /large
   my_multiplot, 3, 2, pp, pp1, /rev
   plot, toi_med, position=pp1[0,*]
   legendastro, 'toi_med'
   plot, data.toi[ikid], position=pp1[1,*], /noerase
   legendastro, 'TOI['+strtrim(ikid,2)+"]"
   fit = linfit( toi_med, data.toi[ikid])
   plot, data.toi[ikid]-(fit[0] + fit[1]*toi_med), /xs, /ys, position=pp1[2,*], /noerase
   legendastro, 'TOI['+strtrim(ikid,2)+'- recal x toi_med', /right
   legendastro, "stddev: "+strtrim(stddev( data.toi[ikid]-toi_med),2)

   np_histo, data.toi[ikid]-toi_med, /fit, position=pp1[3,*], /noerase, /fill, $
             title='TOI['+strtrim(ikid,2)+'] - recal x toi_med'
   
   y = data.toi[ikid]-toi_med
   y -= avg(y)
   y /= stddev(y)
   ksone,  abs(y), 'gauss_cdf', D, prob, /PLOT, position=pp1[4,*], /noerase
   kidpar[ikid].ksone_d = d
   kidpar[ikid].ksone_prob = prob
endif

if keyword_set(stop) then stop

end
