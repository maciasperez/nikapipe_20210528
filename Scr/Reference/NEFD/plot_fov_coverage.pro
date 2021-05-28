
pro plot_fov_coverage, scan, param, output_dir
  
nk, scan, param=param, info=info1, kidpar=kidpar1, data=data, grid=grid1
restore, output_dir+"/"+scan+"/results.save"

print, "info1.RESULT_NKIDS_VALID1, 2, 3: ", $
       info1.RESULT_NKIDS_VALID1, info1.RESULT_NKIDS_VALID2, info1.RESULT_NKIDS_VALID3
print, "info1.result_nefd_center_i1, i2, i3, i_1m: ", $,
       info1.result_nefd_center_i1, info1.result_nefd_center_i2, info1.result_nefd_center_i3, info1.result_nefd_center_i_1mm
print, "info1.RESULT_ON_SOURCE_TIME_GEOM: ", $
       info1.RESULT_ON_SOURCE_TIME_GEOM
print, "info1.result_time_matrix_center_1, 2, 3, 1mm: ", $
       info1.result_time_matrix_center_1, info1.result_time_matrix_center_2, info1.result_time_matrix_center_3, $
       info1.result_time_matrix_center_1mm
;; Plot
xra = [-1,1]*15.*60
yra = xra
phi = dindgen(100)/99.*2*!pi
rfov = 6.2/2.*60.
col_fov = 100
image = grid1.map_i_1mm
w = where( grid1.nhits_1mm eq 0, nw)
image[w] = -1000
imrange = [-1,1]*0.1
nsn = n_elements(data)
png = 1
wind, 1, 1, /free, /large
outplot, file='HLS_source_coverage', png=png
imview, image, xmap=grid1.xmap, ymap=grid1.ymap, title='I 1mm, scan '+strtrim(scan_list[iscan],2), imrange=imrange, colt=4, $
        xtitle='Azimuth offset (arcsec)', ytitle='Elevation offset (arcsec)'
oplot, data.ofs_az, data.ofs_el, col=255
for i=min(data.subscan), max(data.subscan) do begin
   w = where( data.subscan eq i, nw)
   az_min = min( data[w].ofs_az)
   az_max = max( data[w].ofs_az)
   el = avg( data[w].ofs_el)
   oplot, az_min + rfov*cos(phi), el + rfov*sin(phi), col=col_fov
   oplot, az_max + rfov*cos(phi), el + rfov*sin(phi), col=col_fov
endfor
w1 = where( kidpar1.type eq 1)
ikid0 = w1[0]
junk=nk_where_flag( data.flag[ikid0], 11, nflag=nflag, ncompl=nproj) ; anomalous speed flag = inter subscan
time_proj = nproj/!nika.f_sampling
time_tot  = nsn/!nika.f_sampling
legendastro, ['Total scan time: '+string( time_tot,format='(F6.2)'), $
              'Total time projected: '+string( time_proj,form='(F6.2)'), $
              'Integration time (geom): '+       string( info1.RESULT_ON_SOURCE_TIME_GEOM,    form='(F6.2)'), $
              'Integration time (Nhits) A1: '+   string( info1.result_time_matrix_center_1,   form='(F6.2)'), $
              'Integration time (Nhits) A2: '+   string( info1.result_time_matrix_center_2,   form='(F6.2)'), $
              'Integration time (Nhits) A3: '+   string( info1.result_time_matrix_center_3,   form='(F6.2)'), $
              'Integration time (Nhits) A1&A3: '+string( info1.result_time_matrix_center_1mm, form='(F6.2)')], $
             textcol=255
legendastro, ['time on source / total scan time: '+string( info1.RESULT_ON_SOURCE_TIME_GEOM/time_tot, form='(F4.2)'), $
              'time on source / total time projected: '+string( info1.RESULT_ON_SOURCE_TIME_GEOM/time_proj, form='(F4.2)')], $
             textcol=255, /bottom
outplot, /close, /v
print, "info1.result_time_matrix_center_1, 2, 3, 1mm: ", $
       info1.result_time_matrix_center_1, info1.result_time_matrix_center_2, info1.result_time_matrix_center_3, $
       info1.result_time_matrix_center_1mm
print, "!nika.ntot_nom: ", !nika.ntot_nom
print, "pi x R^2/grid_step: ", !dpi*(6.5/2.*60)^2/!nika.grid_step^2
array_eff = [info1.result_nkids_valid1/!nika.ntot_nom[0], $
             info1.result_nkids_valid2/!nika.ntot_nom[1], $
             info1.result_nkids_valid3/!nika.ntot_nom[2], $
             info1.result_nkids_valid1/!nika.ntot_nom[0] + info1.result_nkids_valid3/!nika.ntot_nom[2], $
             info1.result_nkids_valid2/!nika.ntot_nom[1]]
print, "array_eff: ", array_eff

end
