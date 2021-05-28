pro nika_pipe_plotprofileps, prof, name_plot, name_title,xr=xr,yr=yr
  
  err = prof.var
  novar = where(err le 0, nnovar)
  if nnovar ne 0 then err[where(err le 0)] = 1e3*max(prof.var)
  
  set_plot, 'PS'
  device, /color, bits_per_pixel=256, filename=name_plot
  
  ploterror, prof.r, prof.y, sqrt(err), $
             title=name_title, $
             xtitle='radius (arcsec)', ytitle='Flux (Jy/Beam)',$
             psym=1,/nodata,yr=yr,xr=xr,xstyle=1,ystyle=1
  oploterror, prof.r, prof.y, sqrt(err), col=50, errcolor=100,errthick=2,$
              psym=8, symsize=0.7
  device,/close
  
  set_plot, 'X'

  return
end
