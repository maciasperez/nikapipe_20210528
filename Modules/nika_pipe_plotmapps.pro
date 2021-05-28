pro nika_pipe_plotmapps, map, name_plot, name_title, reso, smooth, range=range

  nx = (size(map))[1]
  ny = (size(map))[2]

  set_plot, 'PS'
  device, /color, bits_per_pixel=256, filename=name_plot
  dispim_bar, filter_image(map, fwhm=smooth/reso, /all), $
              /aspect, /nocont, $
              xmap=dindgen(nx)*reso - nx/2*reso, $
              ymap=dindgen(ny)*reso - nx/2*reso, $
              title=name_title, $
              xtitle='R.A. offset (arcsec)', $
              ytitle='DEC. offset (arcsec)',$
              crange=range
  device,/close
  
  set_plot, 'X'

  return
end
