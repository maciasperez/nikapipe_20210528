PRO simu_atm_map, nx, ny, alpha, seed, map, rdisk_convolve = rdisk_convolve
; Power of 2 for nx, ny
; make a map with a k^(-alpha) turbulence like power spectrum density
; NOTE that Kolmogorov gives 2.alpha=5/3
; normalized intensity according to
; norm of vector k (and avoid dividing by zero
fftmap = fft( randomn( seed, nx, ny), -1) * $
  ( (dist( nx, ny) > .1) * $
    (2. / sqrt( float(nx)^2 + float(ny)^2)))^(-alpha) 
fftmap[0, 0] = 0 ; set average to strictly 0

IF keyword_set( rdisk_convolve) THEN BEGIN 
  diskfft = fft( double(dist( nx, ny) LE rdisk_convolve), -1)
  diskfft = diskfft/ abs(diskfft[ 0, 0]) ; normalize
;stop
  map = float( fft( fftmap * diskfft, 1))
ENDIF ELSE $
map = float( fft( fftmap, 1))
return
END 
