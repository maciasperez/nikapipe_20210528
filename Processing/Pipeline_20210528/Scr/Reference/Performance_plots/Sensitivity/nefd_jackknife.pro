

ext = 'Nov_2018'

;; ;; produce maps
;; png = 0
;; ps  = 0
;; g2_launch, ['G2'], [2], 0, 5, ext, /laurence, png=png, ps=ps
;; g2_launch, ['HLS091828'], [2], 0, 5, ext, /laurence, png=png, ps=ps

;; Read and display maps
nk_fits2grid, !nika.plot_dir+"/"+ext+"/G2_common_mode_one_block/iter0/map.fits", grid_g2, header_g2
nk_fits2grid, !nika.plot_dir+"/"+ext+"/G2_common_mode_one_block/iter0/map_JK.fits", grid_g2_jk
nk_fits2grid, !nika.plot_dir+"/"+ext+"/HLS091828_common_mode_one_block/iter0/map.fits", grid_hls, header_hls
nk_fits2grid, !nika.plot_dir+"/"+ext+"/HLS091828_common_mode_one_block/iter0/map_JK.fits", grid_hls_jk

grid_g2.map_i_1mm     *= 1000.d0
grid_g2_jk.map_i_1mm  *= 1000.d0
grid_hls.map_i_1mm    *= 1000.d0
grid_hls_jk.map_i_1mm *= 1000.d0

g2_imr = [-1,1]*5
hls_imr = [-1,1]*10

chars=0.5
!p.charsize=chars
!mamdlib.coltable=39
wind, 1, 1, /free, /large
my_multiplot, 2, 2, pp, pp1, /rev, gap_y=0.1, gap_x=0.1
outplot, file='nefd_jackknife', /png
himview, grid_g2.map_i_1mm, header_g2, $
         position=pp1[0,*], imr=g2_imr, charbar=chars, $
         units='mJy/beam', legend_text='G2', charsize=chars
himview, grid_hls.map_i_1mm, header_hls, $
         position=pp1[1,*], /noerase, imr=hls_imr, chars=chars, charbar=chars, $
         units='mJy/beam', legend_text='HLS091828'
himview, grid_g2_jk.map_i_1mm, header_g2, $
         position=pp1[2,*], /noerase, imr=g2_imr, chars=chars, charbar=chars, $
         units='mJy/beam', legend_text='G2'
himview, grid_hls_jk.map_i_1mm, header_hls, $
         position=pp1[3,*], /noerase, imr=hls_imr, chars=chars, charbar=chars, $
         units='mJy/beam', legend_text='HLS091828'
outplot, /close, /verb

end
