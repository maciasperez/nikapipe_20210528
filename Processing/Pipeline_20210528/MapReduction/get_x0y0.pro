
pro get_x0y0, xx, yy, xc0, yc0, ww

  xc0 = mean( xx)
  yc0 = mean( yy)
  d = (xx-xc0)^2 + (yy-yc0)^2
  ww = where( d eq min(d))
  xc0 = (xx[ww])[0]
  yc0 = (yy[ww])[0]

end
