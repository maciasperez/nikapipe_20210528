
if param.plot_ps eq 0 and param.plot_z eq 0 then wind, 1, 1, /free, /large
outplot, file=param.project_dir+'/Plots/imcm_decorr_corr_matrices_'+param.scan+"_A"+strtrim(iarray,2), $
         png=param.plot_png, ps=param.plot_ps, z=param.plot_z
dp = {noerase:1, charsize:0.5, charbar:0.5, coltable:39}
my_multiplot, 1, 1, ntot=3 + param.niter_atm_el_box_modes, pp, pp1, /rev
if defined(title_out) eq 0 then nika_title, info, title=title_out, /all, /silent
xyouts, 0.05, 0.1, /norm, orient=90, title_out
p = 0
imview, dp=dp, corr_mat0, position=pp1[p,*], $
        title='Raw TOI A'+strtrim(iarray,2), imrange=[0.75,1]
legendastro, strtrim(param.method_num,2), textcol=255
imrange_corr_mat = [0,1]*0.2
p++ & imview, dp=dp, corr_mat1, position=pp1[p,*], title='Atm and zero sub.', imrange=imrange_corr_mat
overplot_corr_contours, kidpar[w1], 0, col=255
p++ & imview, dp=dp, corr_mat2, position=pp1[p,*], title='... and el. box', imrange=imrange_corr_mat
overplot_corr_contours, kidpar[w1], 1, col=255
p++ & imview, dp=dp, corr_mat3, position=pp1[p,*], title='A'+strtrim(iarray,2)+' Iter 0', imrange=imrange_corr_mat
for iter=1, param.niter_atm_el_box_modes-1 do begin &$
   p++ &$
   junk = execute("m = corr_mat"+strtrim(iter+3,2)) &$
   imview, dp=dp, m, position=pp1[p,*], imrange=imrange_corr_mat, $
           title='A'+strtrim(iarray,2)+' Iter '+strtrim(iter,2) &$
endfor
outplot, /close, /verb

if param.g2_paper and iarray eq 2 then begin &$
   corr_mat_final = m &$
   g2_paper_show_toi_corr_matrices, param, kidpar[w1], $
                                    corr_mat0, corr_mat1, corr_mat2, corr_mat3, $
                                    corr_mat_final &$
endif
