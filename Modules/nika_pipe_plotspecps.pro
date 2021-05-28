
pro nika_pipe_plotspecps, map_combi, param, fov_plot, reso_plot, coord, header, cut, range

  coord_plot = [ten(coord.ra[0],coord.ra[1],coord.ra[2])*15.0,$
                ten(coord.dec[0],coord.dec[1],coord.dec[2])] ;Center of the plot 

  loc_out_time = where(filter_image(map_combi.b.time,fwhm=20/param.map.reso,/all) lt cut.time_b or $
                       filter_image(map_combi.b.jy,fwhm=20/param.map.reso,/all) lt cut.flux_b or $
                       filter_image(map_combi.a.time,fwhm=20/param.map.reso,/all) lt cut.time_a or $
                       filter_image(map_combi.a.jy,fwhm=20/param.map.reso,/all) lt cut.flux_a) ;

  ra = filter_image(map_combi.a.jy, fwhm=sqrt(20.0^2-12.5^2)/param.map.reso,/all) ;same reso:20 arcsec
  rb = filter_image(map_combi.b.jy, fwhm=sqrt(20.0^2-18.5^2)/param.map.reso,/all)
  
  rap = rb/ra
  spec = alog(rap)/alog(!nika.lambda[0]/!nika.lambda[1])
  spec[loc_out_time] = 1e6


  set_plot,'ps'
  device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_1mm-2mm_correlation.ps'
  plot, ra, rb, psym=8,symsize=0.7,title=param.source+' - Correlation of the maps at 1.25mm and 2.05mm', $
        xtitle='Pixel value at 1.25mm (Jy/Beam)', ytitle='Pixel value at 2.05mm (Jy/Beam)', /nodata
  oplot, ra, rb, psym=8,symsize=0.5,col=250
  ;oplot, (dindgen(10)-5),(dindgen(10)-5)*2.8,col=150,thick=5,symsize=3
  ;legendastro,['slope: 2.8'], charsize=1,charthick=1,bthick=3,col=[150], psym=[0],$
  ;       thick=[5],symsize=[2], /left
  device,/close
  set_plot, 'X'

  spec[where(spec lt range[0] or spec gt range[1])] = 1e5

  overplot_radec_bar_map, spec, header, spec, header, fov_plot, reso_plot, coord_plot,$
                          postscript=param.output_dir+'/'+param.name4file+'_spectrum_map.ps', $
                          title=param.source+' spectral index distribution',$
                          xtitle='!4a!X!I2000!N (hr)', ytitle='!4d!X!I2000!N (degree)',$
                          barcharthick=2, mapcharthick=2, barcharsize=1, mapcharsize=1,$
                          range=range, conts1=[range[0]-1e-2, range[0], range[1], range[1]+1e-2],$
                          colconts1=0, thickcont1=1.5,conts2=[-1e10,1e10],$         
                          /type, bg1=1e10,beam=20.0
  

  return
end
