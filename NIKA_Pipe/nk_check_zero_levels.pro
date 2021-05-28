
pro nk_check_zero_levels, param, info, data, kidpar, grid, subtract_maps


message, /info, "check zero levels, mask, weights..."

w1 = where( kidpar.type eq 1)
ikid = w1[200]
wsubscan = where( data.subscan eq 15)
off_source1 = data[wsubscan].off_source[ikid]
woff = where( off_source1 gt 0.5, nwoff)

;; no mask but SNR downweight
snr_map = subtract_maps.xmap*0.d0
w = where( subtract_maps.map_var_i_1mm gt 0)
snr_map[w] = sqrt( subtract_maps.map_i_1mm[w]^2/subtract_maps.map_var_i_1mm[w])

nk_map2toi_3, param, info, grid.mask_source_1mm, data.ipix, toi_mask

wind, 1, 1, /f, /large
my_multiplot, 2, 1, pp, pp1, /rev, ymin=0.5, ymax=0.95
imview, grid.mask_source_1mm, title='mask_source_1mm', position=pp1[0,*], $
        xmap=grid.xmap, ymap=grid.ymap
oplot, data[wsubscan].dra[ikid], data[wsubscan].ddec[ikid], col=255

imview, snr_map, imr=[0,3], title='SNR 1mm', /noerase, position=pp1[1,*]

my_multiplot, 1, 4, pp, pp1, gap_y=0.02, ymax=0.45, ymin=0.05, /rev
!x.charsize = 1d-10
plot, data[wsubscan].toi[ikid], /xs, position=pp1[0,*], /noerase
legendastro, 'data[wsubscan].toi[ikid]'
plot, snr_toi[ikid,wsubscan], /xs, position=pp1[1,*], /noerase
legendastro, 'snr_toi'
plot, data[wsubscan].off_source[ikid], /xs, position=pp1[2,*], /noerase
oplot, data[wsubscan].off_source[ikid], col=70, thick=2
legendastro, 'off_source'
plot,  toi_mask[ikid,wsubscan], /xs, position=pp1[3,*], /noerase
oplot, toi_mask[ikid,wsubscan], col=150, thick=2
legendastro, 'toi(mask_source_1mm)'

zero_level_snrw8 = total( data[wsubscan].toi[ikid]/(1.d0+snr_toi[ikid,wsubscan]^2)) / total( 1.d0/(1.d0+snr_toi[ikid,wsubscan]^2))

wmask = where( toi_mask[ikid,*] ne 0)

;; extracted from nk_set0level_sub
off_source1 = data[wsubscan].off_source[ikid]
w_on = where( off_source1 eq 0, nw_on)
toi = data[wsubscan].toi[ikid]
if nw_on ne 0 then toi[w_on] = !values.d_nan
toi_avg = avg( toi, /nan)

print, "avg( data[woff].toi[ikid]), stdd(): ", avg( data[woff].toi[ikid]), stddev( data[woff].toi[ikid])
print, "zero_level_snrw8: ", zero_level_snrw8
print, "avg( data[wsubscan[wmask]].toi[ikid]): ", avg( data[wsubscan[wmask]].toi[ikid])
print, "toi_avg (off_source) (nk_set0level..): ", toi_avg

end
