function get_gaussian_kernel, fwhm, reso, k1d2d, k_3rd = k_3rd, $
                              nextend = k_nextend, nonorm = nonorm
                                ;FXD, Jan2021 compute an array
                                ;containing a centered normalized
                                ;Gaussian
                                ; can then be used to smooth a map with convol( map,kernel)
                                ; Additionaly give the 1st, 2nd
                                ; derivative kernels (if k1d2d is used) and 3rd (if
                                ; /k_3rd)
  input_sigma_beam = fwhm*!fwhm2sigma
  input_sigma_beam2 = double(fwhm*!fwhm2sigma)^2
  input_sigma_beam4 = double(fwhm*!fwhm2sigma)^4
  input_sigma_beam6 = double(fwhm*!fwhm2sigma)^6
  nextend = 12                 ; found necessary to define the background prope
  if keyword_set( k_nextend) then nextend = k_nextend
  nx_kgauss       = 2*long(nextend*input_sigma_beam/reso/2)+1
  ny_kgauss       = nx_kgauss
  xxg = ((lindgen(nx_kgauss, ny_kgauss) mod nx_kgauss) - nx_kgauss/2) $
        * double(reso)
  yyg = ((lindgen(nx_kgauss, ny_kgauss) /   nx_kgauss) - ny_kgauss/2) $
        * double(reso)
  kgauss = exp(-(xxg^2+yyg^2)/(2.*input_sigma_beam2)) ; PSF Gaussian kernel
  if not keyword_set( nonorm) then kgauss = temporary( kgauss/total(kgauss))
  if n_params() ge 3 then begin
     if keyword_set( k_3rd) then nder = 9 else nder = 5
     k1d2d = dblarr( nx_kgauss, ny_kgauss, nder)
     k1d2d[*, *, 0] = (-xxg / input_sigma_beam2) * kgauss  ; dk/dx
     k1d2d[*, *, 1] = (-yyg / input_sigma_beam2) * kgauss  ; dk/dy
     k1d2d[*, *, 2] = -(input_sigma_beam2 - xxg^2)/ input_sigma_beam4 $
                      * kgauss                            ; d2k/dx2
     k1d2d[*, *, 3] = (xxg * yyg) / input_sigma_beam4 * kgauss  ; d2k/dxdy
     k1d2d[*, *, 4] = -(input_sigma_beam2 - yyg^2)/ input_sigma_beam4 $
                      * kgauss                            ; d2k/dy2
     if keyword_set( k_3rd) then begin
        k1d2d[*, *, 5] = (3*input_sigma_beam2 - xxg^2) * xxg/ input_sigma_beam6 * kgauss ; d3k/dx3
        k1d2d[*, *, 6] =   (input_sigma_beam2 - xxg^2) * yyg/ input_sigma_beam6 * kgauss ; d3k/dx2dy
        k1d2d[*, *, 7] =   (input_sigma_beam2 - yyg^2) * xxg/ input_sigma_beam6 * kgauss ; d3k/dxdy2
        k1d2d[*, *, 8] = (3*input_sigma_beam2 - yyg^2) * yyg/ input_sigma_beam6 * kgauss ; d3k/dx3
     endif 
  endif
  
 return, kgauss
end
