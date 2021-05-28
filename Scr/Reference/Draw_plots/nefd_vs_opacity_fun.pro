function nefd_vs_opacity_fun, obstau, par, der_nefd
  nefd = par[0]*exp(obstau)
  
  if n_params() GT 2 then begin
                                ; Create derivative and compute derivative array
     requested = der_nefd             ; Save original value of DP
     der_nefd = exp(obstau)
  endif

  return, nefd
end
