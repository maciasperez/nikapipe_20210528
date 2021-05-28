

xra = [-1,1]*50
yra = [-1,1]*50

my_multiplot, 3, 3, pp, pp1, /rev
imview, lkgk.map_i_1mm, xmap=lkgk.xmap, ymap=lkgk.ymap, xra=xra, yra=yra, $
        position=pp1[0,*], title='Input Kernel I Nasmyth', imr=imr_i
imview, lkgk.map_q_1mm, xmap=lkgk.xmap, ymap=lkgk.ymap, xra=xra, yra=yra, $
        position=pp1[1,*], title='Input Kernel Q Nasmyth', /noerase, imr=imr_i/50.
imview, lkgk.map_u_1mm, xmap=lkgk.xmap, ymap=lkgk.ymap, xra=xra, yra=yra, $
        position=pp1[2,*], title='Input Kernel U Nasmyth', /noerase, imr=imr_i/50.

imview, lkg_i_radec, xmap=lkgk.xmap, ymap=lkgk.ymap, xra=xra, yra=yra, $
        position=pp1[3,*], title='Kernel I Radec', /noerase, imr=imr_i
imview, lkg_q_radec, xmap=lkgk.xmap, ymap=lkgk.ymap, xra=xra, yra=yra, $
        position=pp1[4,*], title='Kernel Q Radec', /noerase, imr=imr_i/50.
imview, lkg_u_radec, xmap=lkgk.xmap, ymap=lkgk.ymap, xra=xra, yra=yra, $
        position=pp1[5,*], title='Kernel U Radec', /noerase, imr=imr_i/50.

imview, grid.map_i_1mm, xmap=grid.xmap, ymap=grid.ymap, xra=xra, yra=yra, $
        position=pp1[6,*], title='Signal I Radec', /noerase, imr=imr_i
imview, grid.map_q_1mm, xmap=grid.xmap, ymap=grid.ymap, xra=xra, yra=yra, $
        position=pp1[7,*], title='Signal Q Radec', /noerase, imr=imr_i/50.
imview, grid.map_u_1mm, xmap=grid.xmap, ymap=grid.ymap, xra=xra, yra=yra, $
        position=pp1[8,*], title='Signal U Radec', /noerase, imr=imr_i/50.

xyouts, 0.05, 0.5, 'nk_lkg_correct_5', orient=90, /norm, chars=1.5
