

pro nika_map_noise_estim_2, param, map, xmap, ymap, fwhm, flux, $
                          sigma_flux, sigma_bg, map_conv, output_fit_par, $
                          bg_rms, flux_center, sigma_flux_center, $
                          output_fit_par_error, $
                          input_fit_par=input_fit_par, educated=educated, $
                          k_noise=k_noise

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nika_map_noise_estim, param, map, xmap, ymap, fwhm, flux, $"
   print, "                      sigma_flux, sigma_bg, map_conv, output_fit_par, bg_rms, $"
   print, "                      input_fit_par=input_fit_par, educated=educated"
   return
endif

;; Precompute quantities required for sensitivity esimates
flux_noise     = dblarr(2)
total_obs_time = n_elements(data)/!nika.f_sampling

;; Make sure the kernel is centered
sigma_beam = fwhm*!fwhm2sigma
nx_beam    = 2*long(3*sigma_beam/param.map_reso/2)+1
ny_beam    = 2*long(3*sigma_beam/param.map_reso/2)+1
xx         = dblarr(nx_beam, ny_beam)
yy         = dblarr(nx_beam, ny_beam)
for ii=0, nx_beam-1 do xx[ii,*] = (ii-nx_beam/2)*param.map_reso
for ii=0, ny_beam-1 do yy[*,ii] = (ii-ny_beam/2)*param.map_reso
beam = exp(-(xx^2+yy^2)/(2.*sigma_beam^2)) ; Do not normalize this beam

;; Convolve data by this gaussian kernel
map_conv = convol( map.jy, beam)

;; Estimate the flux
xx   = reform(xmap[*,0])
yy   = reform(ymap[0,*])
w = where( map.time le 0 or finite(map.var) ne 1, nw)
if nw ne 0 then map.var[w] = -1 ; sometimes, map_var has crazy values instead of -1 or !values.d_nan
if keyword_set(input_fit_par) then begin
   output_fit_par = input_fit_par
endif else begin

   fitmap, map.jy, map.var, xmap, ymap, output_fit_par, covar, output_fit_par_error, educated=educated, k_noise=k_noise

   ;; ;;---------------------------
   ;; ;; Use nika_pipe_fit_beam
   ;; if keyword_set(educated) then begin
   ;;    dmax =  20.
   ;;    search_box = 2.d0*[dmax, dmax]
   ;;    center =  [0., 0.]
   ;;    d =  sqrt(xmap^2+ymap^2)
   ;;    w =  where( d le dmax)
   ;;    ampli =  max( map.jy[w])
   ;; endif else begin
   ;;    delvarx, search_box, center,  ampli
   ;; endelse
   ;; 
   ;; nika_pipe_fit_beam,  map.jy,  param.map.reso, var_map = map.var, /tilt, coeff = coeff, $
   ;;                      err_coeff = err_coeff, search_box = search_box,  center = center, ampli = ampli
   ;; 
   ;; coeff[2] =  coeff[2]*!fwhm2sigma
   ;; coeff[3] =  coeff[3]*!fwhm2sigma
   ;; output_fit_par       = coeff
   ;; output_fit_par_error = err_coeff
   ;; 
   ;; ;; Change orientation convention
   ;; output_fit_par[6] = -output_fit_par[6]
   ;; ;; Force X to be the largest FWHM
   ;; if output_fit_par[3] gt output_fit_par[2] then begin
   ;;    c    = output_fit_par[2]
   ;;    output_fit_par[2] = output_fit_par[3]
   ;;    output_fit_par[3] = c
   ;;    output_fit_par[6] = output_fit_par[6] + !dpi/2.
   ;;    
   ;;    c =  output_fit_par_error[2]
   ;;    output_fit_par_error[2] = output_fit_par_error[3]
   ;;    output_fit_par_error[3] = c
   ;; endif
   ;; output_fit_par[6] = (output_fit_par[6]+2*!dpi) mod !dpi

endelse

;; Determine weights for aperture photometry
d           = sqrt( (xmap-output_fit_par[4])^2 + (ymap-output_fit_par[5])^2)
gauss_w8    = exp( -d^2/(2.d0*sigma_beam^2))

;; Estimate background
nhits = map.time*!nika.f_sampling
ww    = where( map.var gt 0 and d gt 5*sigma_beam, nww)
wpix  = where( map.var gt 0 and d gt 5*sigma_beam and nhits ge median( nhits[ww]), nwpix)
if nwpix eq 0 then message, "No pixel with var > 0 and further from the peak than 5*sigma ?!"
if nwpix le 2 then message, "Not more than 2 valid pixels to estimate the noise ?!"
bckgd  = total( map.jy[wpix]/map.var[wpix])/total(1.d0/map.var[wpix])

;; Take all valid pixels and weight by gaussian and noise
w = where( map.var gt 0, compl=wout, nw, ncompl=nwout)
if nwout ne 0 then gauss_w8[wout] = 0.d0
;;gauss_w8[w] = gauss_w8[w];/map.var[w]

;; Subtract background and compute flux
flux        = total( (map.jy[w]-bckgd)*gauss_w8[w]  )/total(gauss_w8[w]^2)
var         = total(        map.var[w]*gauss_w8[w]^2)/total(gauss_w8[w]^2)^2
sigma_flux  = sqrt(var)


;;---------------------------------------------------------------------------------
;; Derive the flux at the map center
d_1        = sqrt( xmap^2 + ymap^2)
gauss_w8_1 = exp( -d_1^2/(2.d0*sigma_beam^2))

;; Estimate background
ww    = where( map.var gt 0 and d_1 gt 5*sigma_beam, nww)
wpix  = where( map.var gt 0 and d_1 gt 5*sigma_beam and nhits ge median( nhits[ww]), nwpix)
if nwpix eq 0 then message, "No pixel with var > 0 and further from the map center than 5*sigma ?!"
if nwpix le 2 then message, "Not more than 2 valid pixels to estimate the noise on center flux?!"
bckgd_1  = total( map.jy[wpix]/map.var[wpix])/total(1.d0/map.var[wpix])

;; Take all valid pixels and weight by gaussian and noise
w = where( map.var gt 0, compl=wout, nw)
gauss_w8_1[wout] = 0.d0

;; Subtract background and compute flux
flux_center        = total( (map.jy[w]-bckgd_1)*gauss_w8_1[w]  )/total(gauss_w8_1[w]^2)
var                = total(          map.var[w]*gauss_w8_1[w]^2)/total(gauss_w8_1[w]^2)^2
sigma_flux_center  = sqrt(var)

;; 'External' noise estimate on the background (ie. far from the CENTER)
;; I no longer compute it far from the "source", because either the source is at
;; the center and it makes no difference or the source is too faint to be
;; detected and the fit is nonsense.
;; when the source is strong and not at the center like e.g. in pointing_liss,
;; the noise estimate is not critical anyway.
ww   = where( map.var gt 0 and d_1 gt 5*sigma_beam, nww)
wpix = where( map.var gt 0 and d_1 gt 5*sigma_beam and nhits ge median( nhits[ww]), nwpix)
hh   = sqrt(nhits[wpix])*map.jy[wpix]
n_histwork, hh, bin=stddev(hh)/5., g, gg, gpar, /noplot, /fit, /noprint
sigma_h = gpar[2]               ; Jy

;; Average noise per pixel converted in noise per arcsec^2
bg_rms = sqrt( sigma_h^2/avg( nhits[wpix]))*param.map_reso/10. ; for 10 arcsec square, fiducial

;; Noise per beam
w                = where( map.var gt 0, nw)
noise_var_map    = xmap*0.
noise_var_map[w] = sigma_h^2/nhits[w]
ss2      = total( noise_var_map*gauss_w8^2)/total(gauss_w8^2)^2
sigma_bg = sqrt( ss2)

end
