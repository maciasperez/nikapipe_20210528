;+
;PURPOSE: Add fake subscan to lissajous data
;
;INPUT: The data structure
;
;OUTPUT: The data structure with data.subscan containing fake subscans
;
;LAST EDITION: 2013: creation (adam@lpsc.in2p3.fr)
;              06/10/2013: changed from procedure to function   
;              13/02/2014: 2 fois moins de subscans
;              09/11/2104: keyword factor to choose the number of subscans
;-

function nika_pipe_subscan4lissajous, data0, factor=factor, silent = silent

  if not keyword_set(factor) then factor_pro = 1.0 else factor_pro = factor

  data = data0

  x = data.ofs_az
  y = data.ofs_el

  size_x = max(x) - min(x)      ;Size of the map
  size_y = max(y) - min(y)      

  vx = deriv(x)*!nika.f_sampling ;scan speed (arcsec/sec)
  vy = deriv(y)*!nika.f_sampling 
  vx_mean = mean(abs(vx))       ;Mean speed
  vy_mean = mean(abs(vy))        
  
  T_x = factor_pro * 2*size_x/vx_mean          ;time to cross the map (so we call that a subscan)
  T_y = factor_pro * 2*size_y/vy_mean

  N_subscan = long(max([T_x, T_y]*!nika.f_sampling)) ;Number of point per subscan that I chose
  
  i = 0
  while i lt n_elements(x) - N_subscan - 1 do begin
     data[i:*].subscan += 1
     i = i + N_subscan
  endwhile

  data.subscan += -1            ;first subscan is 1
  
  if not keyword_set( silent) then $
     message, /info, 'You are using fake subscans for this lissajous scan.'

  return, data
end
