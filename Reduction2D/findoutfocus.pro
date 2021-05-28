function gauss2dfocus, pos, param
; pos is (2,N) array of x, y positions
; param is xmax, ymax, sigma, gmax, bg, xpch, ypch, fat
  return, param[4]+ $  ; background
          param[3]* $  ; intensity scaling
          (param[5]*(pos[0, * ]- param[0])/param[2]^2+ $  ; x pos. change
           param[6]*(pos[1, * ]- param[1])/param[2]^2+ $  ; y pos. change
           param[7]*(((pos[0, * ]- param[0])^2 + (pos[1, * ]-param[1])^2 - $
                      2.*param[2]^2)/ $
                     (param[2]^3))) * $ ; sigma change
          exp(- $
              ((pos[0, * ]- param[0])^2 + (pos[1, * ]-param(1))^2)/ $
              (2. * param[2]^2))
end


pro findoutfocus,  data, err, flag, x,  y, fwhm,  xmax,  ymax,  gmax, bg, $
                   xpch, ypch, fat, $
                   quiet = quiet, maxiter = maxiter, blockpos = blockpos, $
                   xerr, yerr, gerr, bgerr, xpcherr, ypcherr, faterr
; Find the out of focus parameters given
;  the position of the gaussian with a given width going through
; the data. The data do not have to be gridded.
; Find the minimum of data - (c4+ c3*(c5(x-xmax)/2sigma^2 +
;  c6(y-ymax)/2sigma^2+ c7((x-xmax)^2+(y-ymax)^2-2sigma^2)/sigma^3) *
;  gauss2d(x, y, xmax, ymax, gmax))
; xmax, ymax, gmax, bg
; are guess parameters in input
; gmax is degenerate with the other coefficients: block it
; bg has a strange side effect block it. 
; flag=0: keep the data, anything else: bad data
nel = n_elements( data)
parinfo = replicate( {fixed:0B}, 8)
parinfo[[0, 1, 2, 3, 4]].fixed = 1  ; xmax, ymax, sigma are not varied (nor gmax nor bg)
if keyword_set( blockpos) then parinfo[[5, 6]].fixed = 1
stpar = [ xmax,  ymax, fwhm/sqrt( 8 * alog(2.)), gmax, bg, xpch, ypch, fat]
wei = data * 0. + 1
dd = sqrt((x-xmax)^2 + (y -ymax)^2)
bad = where( flag gt 0 or dd gt 2*fwhm, nbad, complem = good)

if nbad gt  nel-8 or nel lt 8 then BEGIN
   gmax=!undef
   IF NOT keyword_set( quiet) THEN print, 'Not enough data', nbad, nel
   return
endif
if nbad ne 0 then wei[ bad] = 0.
wei[ good] = 1/err[ good]^2
xra = minmax(x)
yra = minmax(y)
res = mpfitfun( 'GAUSS2DFOCUS',  $
                transpose([[x[good]], [y[good]]]), data[good], err[good], $
                stpar, $
                parinfo = parinfo, quiet = quiet,  $
                maxiter = maxiter,  weight = wei[good], $
              bestnorm = bestnorm, perror = perror)
DOF     = nel-nbad - 3 ; deg of freedom
PCERROR = PERROR * SQRT(BESTNORM / DOF)     ; scaled uncertainties
xmax = res[0]
ymax = res[1]
gmax = res[3]
bg = res[4]
xpch = res[5]
ypch = res[6]
fat = res[7]*sqrt( 8 * alog(2.))

xerr = pcerror[0]
yerr = pcerror[1]
gerr = pcerror[3]
bgerr = pcerror[4]
xpcherr = pcerror[5]
ypcherr = pcerror[6]
faterr = pcerror[7]*sqrt( 8 * alog(2.))
if ((xmax+xpch) lt xra[0] or (xmax+xpch) gt xra[1] or $
    (ymax+ypch) lt yra[0] or (ymax+ypch) gt yra[1]) then begin
                                ; the fit did not converge towards a
                                ; point source within the boundaries,
                                ; mark it
   gmax = !undef
endif

return
end

; Example
;; npt = 10000
;; x = randomu( seed,  npt) * 10D0
;; y = randomu( seed,  npt) * 10D0
;; xc = 4.
;; yc = 6.
;; fwhm = 1.D0
;; data1 = exp( - ((x-xc)^2 + (y -yc)^2)/(2. * (fwhm/2.35)^2)) / fwhm^2
;; xmax = xc+0.05
;; ymax = yc-0.05
;; data2 = 1.*exp( - ((x-xmax)^2 + (y -ymax)^2)/(2. * ((fwhm+0.1)/2.35)^2))/ $
;;         (fwhm+0.1)^2
;; errlev = 0.1D0
;; data = data2 - data1 + randomn( seed, npt)*errlev
;; gmax = 1.
;; bg = 0.
;; flag = bytarr( npt)
;; err = dblarr( npt)+ errlev
;; xpch = 0.0
;; ypch = 0.0
;; fat = 0.
;; xmax = xc
;; ymax = yc
;; print, xmax, ymax, gmax, bg, xpch, ypch, fat
;; findoutfocus,  data, err, flag, x, y, fwhm, xmax, ymax, gmax, bg, $
;;                    xpch, ypch, fat, $
;;                    maxiter = 30, /quiet, $
;;                    xerr, yerr, gerr, bgerr,
;;                    xpcherr, ypcherr, faterr ;, /blockpos
;; print, xpch, xpcherr
;; print, ypch, ypcherr
;; print, fat, faterr
;; wshet, 12
;; tvsclu,  tri_surf( data, /lin, x, y), /adj
;; wshet, 13
;; ares = tri_surf( gauss2dfocus( transpose([[x], [y]]), $
;;                                 [ xmax,  ymax, fwhm/sqrt( 8 * alog(2.)), $
;;                                   gmax, bg, xpch, ypch, fat]), $
;;                  /lin, x, y)
;; tvsclu, ares,  /adj
