
pro show_focal_planes, param

kidpar1 = mrdfits( param.kid_file.a, 1)
kidpar2 = mrdfits( param.kid_file.b, 1)

w1 = where( kidpar1.type eq 1)
w2 = where( kidpar2.type eq 1)

xra = minmax( [kidpar1[w1].nas_x, kidpar2[w2].nas_x])
xra = xra + [-0.1, 0.1]*(xra[1]-xra[0])
yra = minmax( [kidpar1[w1].nas_y, kidpar2[w2].nas_y])
yra = yra + [-0.1, 0.1]*(yra[1]-yra[0])


wind, 1, 1, /free, /large
plot, xra, yra, /iso, xtitle='Arcsec', ytitle='Arcsec', /nodata, /xs, /ys
oplot, kidpar1[w1].nas_x, kidpar1[w1].nas_y, psym=1, col=70
oplot, kidpar2[w2].nas_x, kidpar2[w2].nas_y, psym=1, col=250
xyouts, kidpar1[w1].nas_x, kidpar1[w1].nas_y, strtrim( kidpar1[w1].numdet,2), charsize=0.6, col=70
xyouts, kidpar2[w2].nas_x, kidpar2[w2].nas_y, strtrim( kidpar2[w2].numdet,2), charsize=0.6, col=250
legendastro, ['Nasmyth offsets'], box=0

end
