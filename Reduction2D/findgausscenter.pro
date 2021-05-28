function gauss2d, pos, param
; pos is (2,N) array of x, y positions
; param is xmax, ymax, sigma, gmax
return, param[4]+ param[3] * exp(- $
    ((pos[0, * ]- param[0])^2 + (pos[1, * ]-param(1))^2)/ $
    (2. * param[2]^2))
end


pro findgausscenter,  data, flag, x,  y, fwhm,  xmax,  ymax,  gmax, bg, $
          quiet = quiet, maxiter = maxiter, xerr, yerr, gerr, bgerr
; Find the position of the maximum gaussian with a given width going through
; the data. The data do not have to be gridded.
; Find the peak of data*gauss using mpfit
; Find the minimum of data - (bg+ gauss2d(x, y, xmax, ymax, gmax))
; xmax, ymax, gmax, bg
; are guess parameters in input and optimum values on output
; flag=0: keep the data, anything else: bad data
nel = n_elements( data)
parinfo = replicate( {fixed:0B}, 5)
parinfo[2].fixed = 1  ; sigma is not varied
stpar = [ xmax,  ymax, fwhm/sqrt( 8 * alog(2.)), gmax, bg]
wei = data * 0. + 1
;bad = where( data eq !undef, nbad)
bad = where( flag gt 0, nbad)
if nbad gt  nel-8 or nel lt 8 then BEGIN
   gmax=!undef
   IF NOT keyword_set( quiet) THEN print, 'Not enough data', nbad, nel
   return
endif
if nbad ne 0 then wei[ bad] = 0.
xra = minmax(x)
yra = minmax(y)
res = mpfitfun( 'GAUSS2D',  transpose([[x], [y]]), data, err, stpar, $
                parinfo = parinfo, quiet = quiet,  $
                maxiter = maxiter,  weight = wei, $
              bestnorm = bestnorm, perror = perror)
DOF     = nel-nbad - 3 ; deg of freedom
PCERROR = PERROR * SQRT(BESTNORM / DOF)     ; scaled uncertainties
xmax = res[0]
ymax = res[1]
gmax = res[3]
bg = res[4]
xerr = pcerror[0]
yerr = pcerror[1]
gerr = pcerror[3]
bgerr = pcerror[4]
if (xmax lt xra[0] or xmax gt xra[1] or ymax lt yra[0] or ymax gt yra[1]) then begin
                                ; the fit did not converge towards a
                                ; point source within the boundaries,
                                ; mark it
   gmax = !undef
endif

return
end

; Example
;; x = randomu( seed,  100) * 10
;; y = randomu( seed,  100) * 10
;; data = exp( - ((x-1)^2 + (y -7)^2)/(2. * (1/2.35)^2))
;; xmax = 3.5
;; ymax = 6.2
;; gmax = 0.5
;; bg=0.
;; findgausscenter,  data, x,  y,  1.,  xmax,  ymax,  gmax, bg, $
;;           maxiter = 20,  /quiet
;; print, xmax,  ymax,  gmax,  bg
;; print, xerr, yerr, gerr, bgerr
