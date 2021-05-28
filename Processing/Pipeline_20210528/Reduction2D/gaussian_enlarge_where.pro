; Procedure to enlarge the zones detected by a where, with a Gaussian
; e.g.

function gaussian_enlarge_where, mapxsiz, mapysiz, reso, index, fwhm
  mask = fltarr( mapxsiz, mapysiz)
  if index[0] eq (-1) then return, index
  mask[ index] = 1
  kgauss = get_gaussian_kernel( fwhm, reso, /nonorm) ; normalised PSF Gaussian kernel
  lmask = convol( mask, kgauss)
  lindex = where( lmask gt 0.5)
  return, lindex
  end
