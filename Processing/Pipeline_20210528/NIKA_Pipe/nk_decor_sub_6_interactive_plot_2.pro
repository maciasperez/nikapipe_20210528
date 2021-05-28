
ibox2plot = 9
w1 = where( kidpar.type eq 1 and kidpar.acqbox eq ibox2plot, nw1)
make_ct, nw1, ct
xra = [1200,1400]
yra = [-10,10]                  ; array2range(toi[w1,*])
plot, toi[w1[0],*]-toi[w1[0],0], /xs, xra=xra, yra=yra, /ys
for i=0, nw1-1 do begin &$
   plot, toi[w1[i],*]-toi[w1[i],0], col=70, xra=xra, yra=yra, /ys, /xs &$
   oplot, common_mode_per_box[ibox2plot,*]-common_mode_per_box[ibox2plot,0], thick=2 &$
   wait, 0.5 &$
endfor
oplot, common_mode_per_box[ibox2plot,*]-common_mode_per_box[ibox2plot,0], thick=2
legendastro, ['all valid kids in box '+strtrim(ibox2plot,2), $
              'common mode box '+strtrim(ibox2plot,2)], textcol=[70,!p.color]
message, /info, "HERE, just before nk_get_one_mode_per_box"
stop

decor_aux_plot_2, param, info, kidpar, w1, $
                  junk, flag, off_source, atm_cm, $
                  common_mode_per_box, nsn, elevation
message, /info, "HERE"
stop

