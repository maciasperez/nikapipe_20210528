;+
;PURPOSE: Recover point sources in a dusty map by convolving with two gaussians
;
;INPUT: - input_map
;       - resolution
;       - fwhm of the beam to smooth
;       - scale at which we start the cutoff
;       - scale at which we are completely cut
;
;OUTPUT: output_map (filtered)
;
;KEYWORDS: - nsig: number of sigma above which sources are
;            flagged. Default is 4
;          - flag_map: the flagged position above nsig
;
;LAST EDITION: 
;   14/11/2013: creation
;-

function nika_anapipe_mexican_hat, map_in, reso, fwhm1, fwhm2, nsig=nsig, flag_map=flag_map
  
  if not keyword_set(nsig) then nsigma = 4 else nsigma = nsig

  nx = (size(map_in))[1]
  ny = (size(map_in))[2]

  ;;------- Build mexican hat PSF
  hat1 = filter_image(map_in, fwhm=fwhm1/reso, /all)
  hat2 = filter_image(map_in, fwhm=fwhm2/reso, /all)
  map_out = hat1 - hat2
  
  ;;------- Flag sources 1
  flag_map = dblarr(nx, ny)
  rms = stddev(map_out)
  avg = mean(map_out)
  flag = where(map_out gt avg + nsigma*rms, nflag, complement=noflag, ncomplement=nnoflag)
  if nflag ne 0 then flag_map[flag] = 1

  ;;------- Flag sources iterate
  for nit=0, 5 do begin
     if nflag ne 0 then rms = stddev(map_out[noflag])
     if nflag ne 0 then avg = mean(map_out[noflag])
     flag = where(map_out gt avg + nsigma*rms, nflag)
     if nflag ne 0 then flag_map[flag] = 1
  endfor

  return, map_out
end
