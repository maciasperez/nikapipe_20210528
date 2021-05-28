
pro g2_paper_show_toi_corr_matrices, param, kidpar, corr_mat0, corr_mat1, corr_mat2, corr_mat3, corr_mat_final


position = [0.14,0.07,0.95,0.95]
dp = {position:position, xtitle:'KID index', ytitle:'KID index'}

wind, 1, 1, /free, xs=900, ys=700

outplot, file=!nika.plot_dir+"/G2_paper/Plots/corr_mat0", $
         ps=param.plot_ps, png=param.plot_png
imview, corr_mat0, dp=dp, title='A', imrange=[0.75,1]        
outplot, /close, /verb


outplot, file=!nika.plot_dir+"/G2_paper/Plots/corr_mat1", $
         ps=param.plot_ps, png=param.plot_png
imview, corr_mat1, dp=dp, title='B', imrange=[0., 0.4]
overplot_corr_contours, kidpar, 0, col=255
outplot, /close, /verb

outplot, file=!nika.plot_dir+"/G2_paper/Plots/corr_mat2", $
         ps=param.plot_ps, png=param.plot_png
imview, corr_mat2, dp=dp, title='C', imrange=[0., 0.4]
overplot_corr_contours, kidpar, 1, col=255
outplot, /close, /verb

outplot, file=!nika.plot_dir+"/G2_paper/Plots/corr_mat3", $
         ps=param.plot_ps, png=param.plot_png
imview, corr_mat3, dp=dp, title='D', imrange=[0., 0.2]
overplot_corr_contours, kidpar, 1, col=255
outplot, /close, /verb

outplot, file=!nika.plot_dir+"/G2_paper/Plots/corr_mat_final", $
         ps=param.plot_ps, png=param.plot_png
imview, corr_mat_final, dp=dp, title='E', imrange=[0., 0.2]
overplot_corr_contours, kidpar, 1, col=255
outplot, /close, /verb

end
