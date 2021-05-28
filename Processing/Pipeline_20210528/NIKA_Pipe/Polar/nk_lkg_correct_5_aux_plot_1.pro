


imr_p = [-1,1]*0.3
dp.xrange = minmax(grid.xmap)
dp.yrange = dp.xrange

my_multiplot, 3, 4, pp, pp1, /rev, /full, /dry

imview, grid.map_i_1mm, dp=dp, position=pp1[0,*], imr=[-1,1]*10
legendastro, 'Input I', textcol=255
oplot, r*cos(phi), r*sin(phi), col=255

imview, grid.map_q_1mm, dp=dp, position=pp1[1,*], imr=imr_p
legendastro, 'Input Q/I', textcol=255
oplot, r*cos(phi), r*sin(phi), col=255

imview, grid.map_u_1mm, dp=dp, position=pp1[2,*], imr=imr_p
legendastro, 'Input U/I', textcol=255
oplot, r*cos(phi), r*sin(phi), col=255

imview, i_kernel, dp=dp, title='i_map', position=pp1[3,*], imr=[-1,1]*10
legendastro, 'Kernel I', textcol=255
oplot, r*cos(phi), r*sin(phi), col=255

imview, q_kernel/max(i_kernel)*max(grid.map_i_1mm), dp=dp, position=pp1[4,*], imr=imr_p
legendastro, 'Kernel Q/I', textcol=255
oplot, r*cos(phi), r*sin(phi), col=255

imview, u_kernel/max(i_kernel)*max(grid.map_i_1mm), dp=dp, position=pp1[5,*], imr=imr_p
legendastro, 'Kernel U/I', textcol=255
oplot, r*cos(phi), r*sin(phi), col=255

imview, mask*grid.map_i_1mm, dp=dp, position=pp1[6,*], imr=[-1,1]*10
legendastro, 'Input I x Mask', textcol=255
imview, mask*grid.map_q_1mm, dp=dp, position=pp1[7,*], imr=imr_p
legendastro, 'Input Q x Mask', textcol=255
imview, mask * grid.map_u_1mm, dp=dp, position=pp1[8,*], imr=imr_p
legendastro, 'Input U x Mask', textcol=255

imview, mask*i_kernel, dp=dp, title='i_map', position=pp1[9,*], imr=[-1,1]*10
legendastro, 'Kernel I x Mask', textcol=255
imview, mask*q_kernel/max(i_kernel)*max(grid.map_i_1mm), dp=dp, position=pp1[10,*], imr=imr_p
legendastro, 'Kernel Q/I x Mask', textcol=255
imview, mask*u_kernel/max(i_kernel)*max(grid.map_i_1mm), dp=dp, position=pp1[11,*], imr=imr_p
legendastro, 'Kernel U/I x Mask', textcol=255

