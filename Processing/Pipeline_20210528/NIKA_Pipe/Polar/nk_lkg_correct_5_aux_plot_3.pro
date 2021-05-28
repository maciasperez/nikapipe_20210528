

my_multiplot, 6, 3, pp, pp1, /rev, ymin=0.2, /full, /dry

dp.xrange = [-1,1]*30
dp.yrange = dp.xrange

imr_p = [-1,1]*0.3

dp.nobar=1
imview, input_q1, dp=dp, position=pp[0,0,*], imr=imr_p
legendastro, 'Input Q1', textcol=255

imview, input_q3, dp=dp, position=pp[1,0,*], imr=imr_p
legendastro, 'Input Q3', textcol=255

imview, input_q_1mm, dp=dp, position=pp[2,0,*], imr=imr_p
legendastro, 'Input Q 1mm', textcol=255

imview, input_u1, dp=dp, position=pp[3,0,*], imr=imr_p
legendastro, 'Input U1', textcol=255

imview, input_u3, dp=dp, position=pp[4,0,*], imr=imr_p
legendastro, 'Input U3', textcol=255

dp.nobar=0
imview, input_u_1mm, dp=dp, position=pp[5,0,*], imr=imr_p
legendastro, 'Input U 1mm', textcol=255

dp.nobar=1
imview, q_lkg, dp=dp, position=pp[0,1,*], imr=imr_p
legendastro, 'Q lkg', textcol=255
imview, q_lkg, dp=dp, position=pp[1,1,*], imr=imr_p
legendastro, 'Q lkg', textcol=255
imview, q_lkg, dp=dp, position=pp[2,1,*], imr=imr_p
legendastro, 'Q lkg', textcol=255
imview, u_lkg, dp=dp, position=pp[3,1,*], imr=imr_p
legendastro, 'U lkg', textcol=255
imview, u_lkg, dp=dp, position=pp[4,1,*], imr=imr_p
legendastro, 'U lkg', textcol=255
dp.nobar=0
imview, u_lkg, dp=dp, position=pp[5,1,*], imr=imr_p
legendastro, 'U lkg', textcol=255

dp.nobar=1
imview, grid.map_q1, dp=dp, position=pp[0,2,*], imr=imr_p
legendastro, 'Output Q1', textcol=255

imview, grid.map_q3, dp=dp, position=pp[1,2,*], imr=imr_p
legendastro, 'Output Q3', textcol=255

imview, grid.map_q_1mm, dp=dp, position=pp[2,2,*], imr=imr_p
legendastro, 'Output Q 1mm', textcol=255

imview, grid.map_u1, dp=dp, position=pp[3,2,*], imr=imr_p
legendastro, 'Output U1', textcol=255

imview, grid.map_u3, dp=dp, position=pp[4,2,*], imr=imr_p
legendastro, 'Output U3', textcol=255

dp.nobar=0
imview, grid.map_u_1mm, dp=dp, position=pp[5,2,*], imr=imr_p
legendastro, 'Output U 1mm', textcol=255

nk_grid2info, grid, info_now, /noplot

plot, [0,1], [0,1], /nodata, position=[0.1, 0.02, 0.4, 0.3], xs=4, ys=4, /noerase
angle_fmt = '(F6.1)'
deg_fmt = '(F5.2)'
legend_text = [param.scan, $
               "Input / Output:", $
               "polangle 1  : "+string(info_b4.result_pol_angle_1,format=angle_fmt)+" / "+string(info_now.result_pol_angle_1,format=angle_fmt), $
               "polangle 3  : "+string(info_b4.result_pol_angle_3,format=angle_fmt)+" / "+string(info_now.result_pol_angle_3,format=angle_fmt), $
               "polangle 1mm: "+string(info_b4.result_pol_angle_1mm,format=angle_fmt)+" / "+string(info_now.result_pol_angle_1mm,format=angle_fmt), $
               "", $
               "pol deg 1  : "+string(  100*info_b4.result_pol_deg_1,format=deg_fmt)+" / "+string(  100*info_now.result_pol_deg_1,format=deg_fmt), $
               "pol deg 3  : "+string(  100*info_b4.result_pol_deg_3,format=deg_fmt)+" / "+string(  100*info_now.result_pol_deg_3,format=deg_fmt), $
               "pol deg 1mm: "+string(100*info_b4.result_pol_deg_1mm,format=deg_fmt)+" / "+string(100*info_now.result_pol_deg_1mm,format=deg_fmt)]
legendastro, legend_text, /bottom

