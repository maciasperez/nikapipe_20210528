pro nika_pipe_plotfluxintegps, rad, phi_int, name_plot, name_title, beam=beam

  if keyword_set(beam) then ytitre='Solid angle (arcsec!U2!N/Beam)' else ytitre='Flux (Jy/Beam.arcsec!U2!N)'

  set_plot, 'PS'
  device, /color, bits_per_pixel=256, filename=name_plot
  
  plot, rad, phi_int, title=name_title, $
        xtitle='Integration radius (arcsec)', ytitle=ytitre, /nodata
  oplot, rad, phi_int, col=50, thick=2
  device,/close
  set_plot, 'X'

  return
end
