
wind, 1, 1, /free, /large
nplots = 4
p=-1
j = -1
ii=0
while j lt 0 and ii lt nw1 do begin &$
   if max(toi_i_1mm[ii,*]) eq max(toi_i_1mm) then j = ii &$
   ii++ &$
endwhile
my_multiplot, 1, 1, ntot=nplots, /rev, pp, pp1, gap_x=0.1
p++
plot, data.off_source[w1[j]], /xs, col=150, /noerase, position=pp1[p,*], yra=[0,1.2], /ys, $
      xtitle='index', ytitle='Jy/beam'
plot, data.toi[w1[j]], /xs, position=pp1[p,*], /noerase
legendastro, ['off_source', 'data.toi'], line=0, col=[150,0]
p++
plot, data.off_source[w1[j]], /xs, col=150, /noerase, position=pp1[p,*], yra=[0,1.2], /ys, $
      xtitle='index', ytitle='Jy/beam'
plot, toi_i_1mm[j,*], /xs, position=pp1[p,*], /noerase
legendastro, ['off_source', 'toi_i_1mm'], line=0, col=[150,0]
p++
plot, data.toi[w1[j]], /xs, position=pp1[p,*], /noerase, xra=xra, $
      xtitle='index'
oplot, data.toi[w1[j]]-toi_i_1mm[j,*], col=250
legendastro, ['data.toi', 'data.toi-toi_i_1mm'], col=[0,250], line=0
