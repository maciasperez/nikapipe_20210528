function nika_pipe_yinteg, radius, y_prof, radius_max
  
  N_case = n_elements(radius_max)
  N_pt = n_elements(y_prof)
  Y_int = dblarr(N_case)

  for i = 0, N_case-1 do begin
     loc_ok = where(y_prof/y_prof eq 1) ;To be sure that it is a number

     rad_i = radius_max[i]*dindgen(N_pt)/N_pt
     y_i = interpol(y_prof[loc_ok], radius[loc_ok], rad_i)

     Y_int[i] = 2*!pi*int_tabulated(rad_i,y_i*rad_i,/double)
  endfor

return,Y_int
end
