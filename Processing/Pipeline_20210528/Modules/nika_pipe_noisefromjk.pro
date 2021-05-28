pro nika_pipe_noisefromjk, map_jk, time, stddev_map, noise_level, ps=ps, map_per_kid=map_per_kid, nbins=nbins,title=title

  if not keyword_set(nbins) then nbins = 50
  
  noise = 1e3*map_jk*sqrt(time) ;mJy/beam.sqrt(s)
  
  wcut = where(time gt 0, nwcut, complement=compl)
  
  hist = histogram(noise[wcut], nbins=nbins)
  bins = FINDGEN(N_ELEMENTS(hist))/(N_ELEMENTS(hist)-1) * $
         (MAX(noise[wcut])-MIN(noise[wcut]))+MIN(noise[wcut]) 
  yfit = GAUSSFIT(bins, hist, coeff,nterms=3, sigma=sigma)
  
  print, ''
  print, 'Sensitivity found: '+strtrim(coeff[2],2)+' mJy.sqrt(s)/Beam'
  print, ''

  stddev_map = (noise*0 + coeff[2]) / sqrt(time) *1e-3 ;standard deviation map (Jy/Beam)
  stddev_map[compl] = -1e-3

  noise_level = coeff[2]

  if keyword_set(ps) then begin
     set_plot, 'ps'
     DEVICE, /COLOR, filename=ps
     plot, bins, hist, psym=10, xtitle='Value of the pixel (mJy/Beam.s!E1/2!N)', ytitle='Number of pixels',charthick=2,/nodata,xstyle=1,ystyle=1,xr=[-1,1]*max(bins),yr=[0, max(yfit)*1.2],title=title
     oplot, bins, hist, col=50, psym=10, thick=2
     oplot, bins, yfit, col=250, thick=3
     legendastro,['Data','Fit: !4r!X='+strtrim(coeff[2],2)+' mJy/Beam.s!E1/2!N'],linestyle=[0,0],psym=[0,0],col=[50,250],thick=[5,5],symsize=[1,1],spacing=[1,1],pspacing=[2,2],pos=[-max(bins),max(yfit)*1.2]
     device, /close
     set_plot, 'x'
  endif
  
  return
end
