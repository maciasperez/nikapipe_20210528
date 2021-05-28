
; +TODO : sky rotation with time

raw_dir   = "/Data/NIKA/Iram_Oct2011/Raw/"
scan_file = "d_2011_10_18_00h29m35_Uranus_333"

fp = mrdfits( "/Data/NIKA/Iram_Oct2011/FocalPlaneGeometry/FPG_config_2_RF_v1.fits", 1, h)

rescan = 0
nbol = 10

; Sampling freq
f_sample = 100. ; Hz

; HWP rotation speed
n_harmonics = 3
rot_speed = 2.5 ; Hz
ampl = 500
drift = 0.1

;; Lowpass
freqlow = 0.
freqhigh = 1.12d0 ; 4*sigma_k


beta_coeff       = randomu( seed, nbol) ; HWP template amplitudes
subtract_hwp     = 1 ; set to 1 do do HWP template subtraction
rho              = 1.0d0 ; polarization efficiency
nsmooth          = 0 ; 5 ; to improve on pixelization of the timeline
sky_noise_ampl   = 1. ; 1.0d0
white_noise_ampl = 10.0d0 ;0.

;------------------------------------------------------------------------

if rescan eq 1 then begin
   get_data, scan_file, toi, az, el, w8, kidpar, dir=raw_dir, subscan=subscan, pfstr=pfstr
   nsn_tot = n_elements( toi[0,*])
   t_mn = dindgen(nsn_tot)/!f_sampling/60. ; min

; Restrict to 1 matrix only for now
   delvarx, az, el, w8, toi

;; In the tangential plane
   el_tel = pfstr.actualel                          ; a utiliser dans detcoord
   y_0 = pfstr.yoffset/!arcsec2rad                  ; offset par rapport a la position de la source (el_tel-el_source)(t)
   x_0 = pfstr.xoffset/!arcsec2rad * cos(el_tel*!dtor) ; pfstr.xoffset = (az_tel-az_source)(t)

   t_mn = t_mn[0:26500]
   x_0  =  x_0[0:26500]
   y_0  =  y_0[0:26500]

   t_max = max(t_mn*60.)
   nsn = round( t_max*f_sample)
   t = dindgen( nsn)/(nsn-1)*t_max
   x_1 = interpol( x_0, t_mn*60.d0, t)
   y_1 = interpol( y_0, t_mn*60.d0, t)
   xra = [-1,1]*5
   wind, 1, 1, /free, /large
   !p.multi=[0,2,2]
   plot, x_0, y_0
   oplot, x_1, y_1, col=70
   plot, x_0, y_0, /iso, xra=xra, yra=xra
   oplot, x_0, y_0, psym=1, col=250
   oplot, x_1, y_1, psym=1, col=70
   !p.multi=0

   x_0 = x_1
   y_0 = y_1
   nsn = n_elements(t)

   nsn = test_primenumber( nsn)
   x_0 = x_0[0:nsn-1]
   y_0 = y_0[0:nsn-1]
   t   =   t[0:nsn-1]

   save, x_0, y_0, t, file='scan.save'
endif else begin
   restore, 'scan.save', /verb
endelse

nsn = n_elements(t)
toi = dblarr( nbol, nsn)

; Generate sky
xra = minmax(x_0)
yra = minmax(y_0)
res_arcsec = 1.0d0
index = -1
pol_deg = 0.05
nx = round( (max(xra)-min(xra))/res_arcsec * 4)
ny = round( (max(xra)-min(xra))/res_arcsec * 4)
nx = max([nx,ny])
ny = nx

cls2map, [0,1], [0,1], nx, ny, res_arcsec/60., map_t, k_map, index=index, fwhm_arcmin=15./60

alpha = dist(nx)/nx * !dpi
map_q = pol_deg * map_t * cos(2*alpha)
map_u = pol_deg * map_t * sin(2*alpha)

define_xy_coord, nx, ny, res_arcsec, 0, 0, xg, yg, xmap, ymap

wind, 1, 1, /free, /large
!p.multi=[0,2,2]
plottv, map_t, xmap, ymap, /iso, /scal, title='T'
oplot, x_0, y_0, col=0
plottv, map_q, xmap, ymap, /iso, /scal, title='Q'
oplot, x_0, y_0, col=0
plottv, map_u, xmap, ymap, /iso, /scal, title='U'
oplot, x_0, y_0, col=0
!p.multi=0

;; Pointing
parangle = 30*!dtor ; place holder
copar = cos(parangle)
sipar = sin(parangle)
dx = dblarr( nbol)
dy = dblarr( nbol)
for ibol=0, nbol-1 do begin
   dx[ibol] =  copar * (fp[ibol].nas_x - fp[ibol].nas_center_x) + sipar * (fp[ibol].nas_y - fp[ibol].nas_center_y)
   dy[ibol] = -sipar * (fp[ibol].nas_x - fp[ibol].nas_center_x) + copar * (fp[ibol].nas_y - fp[ibol].nas_center_y)
endfor

omega = (2*!dpi*rot_speed*t) mod (2*!dpi)
cos4omega = cos(4*omega)
sin4omega = sin(4*omega)

;; Build TOIs
toi = toi*0.0d0
toi_signal = toi*0.0d0
toi_pol    = toi*0.0d0
for ibol=0, nbol-1 do begin
   x = x_0 + dx[ibol] - xmap[0] - res_arcsec/2. ; lower left corner
   y = y_0 + dy[ibol] - ymap[0] - res_arcsec/2. ; lower left corner

   ipix = long(y/res_arcsec)*nx + long(x/res_arcsec)
   if min(ipix) lt 0 or max(ipix) gt (long(nx)*long(ny)-1) then begin
      print, "Wrong pixel index: ibol, i, ipix: "
      stop
   endif else begin
      toi_signal[ibol,*] = map_t[ipix] + rho * ( map_q[ipix]*cos4omega + map_u[ipix]*sin4omega)
      toi_pol[   ibol,*] =                       map_q[ipix]*cos4omega + map_u[ipix]*sin4omega

      if nsmooth gt 0 then begin
         toi_signal[ibol,*] = smooth( toi_signal[ibol,*], nsmooth)
         toi_pol[   ibol,*] = smooth( toi_pol[   ibol,*], nsmooth)
      endif

   endelse
endfor

;; Init
toi = toi_signal

;; Add white noise
for ibol=0, nbol-1 do toi[ibol,*] = toi[ibol,*] + randomn( seed, nsn)*white_noise_ampl

;; Add template
make_template, n_harmonics, omega*!Radeg, t, ampl, drift, beta
for ibol=0, nbol-1 do toi[ibol,*] = toi[ibol,*] + beta_coeff[ibol]*beta

;; Add Atmospheric noise
cloud_vx  = 1.0d0
cloud_vy  = 0.1d0
sx        = 10.0d0
sy        = 10.0d0
alpha_atm = 1.8333d0
nika_sky_noise_2, t, dx, dy, cloud_vx, cloud_vy, alpha_atm, sx, sy, sky_noise_toi

sky_noise_toi = sky_noise_ampl*sky_noise_toi

toi = toi + sky_noise_toi

;;Subtract template
if subtract_hwp eq 1 then begin
   nika_hwp_rm, toi, t, omega*!radeg, n_harmonics, fit, toi_out
endif else begin
   fit=dblarr(nsn)
   toi_out = toi
endelse

;wind, 1, 1, /free, /large
;plot,  t, toi[0,*], xra=[0,10], /xs
;oplot, t, toi_signal[0,*]+fit+reform(sky_noise_toi[0,*]), col=70


;;================================================================================================
;; Time domain plots
t_tl = reform(toi_out[0,*])

scan_speed = 15.0d0 ; arcsec/sec
fwhm  = 20.0d0 ; arcsec, approx
sigma_t = fwhm*!fwhm2sigma/scan_speed
sigma_k = 1.d0/(2.d0*!dpi*sigma_t)

;; Full power
prepare_fft, t_tl, f_sample, gna, base=1
power_spec, gna, f_sample, pw_t_out, freq

prepare_fft, toi[0,*], f_sample, gna, base=1
power_spec, gna, f_sample, pw_t_in, freq

prepare_fft, toi_signal[0,*], f_sample, gna, base=1
power_spec, gna, f_sample, pw_t_sky, freq

delvarx, filter
np_bandpass, toi_out[0,*], f_sample, t_tl_out, freqlow=freqlow, freqhigh=freqhigh, filter=filter
power_spec, t_tl_out, f_sample, pw_t_proj

col_in = !p.color
col_out = 70
col_sky = 100
col_proj = 250

wf = where( freq lt sigma_k, nwf)
yra = minmax([pw_t_in, pw_t_out, pw_t_sky])*[0.1,10]
wind, 1, 1, /free
plot_oo, freq, pw_t_in, yra=yra, /ys, $
         xtitle='Fred [Hz]', ytitle='AU/Hz!u-1/2!n', /nodata, $
         title='Raw timelines'
oplot, freq, pw_t_in, col=col_in
oplot, freq, pw_t_out, col=col_out
oplot, freq, pw_t_sky, col=col_sky
oplot, freq, mean(pw_t_sky[wf])*exp(-freq^2/(2.*sigma_k^2)), col=200, line=2
oplot, freq, pw_t_proj, col=col_proj
oplot, [1,1]*4*rot_speed, [1e-10,1e10], line=2
legendastro, ['Input', 'Output', 'Sky', 'Projected'], $
        line=0, col=[col_in, col_out, col_sky, col_proj]

;; Demodulated
q_sky  = reform( toi_signal[0,*]) * cos4omega
q_in   = reform( toi[       0,*]) * cos4omega
q_tl   =                     t_tl * cos4omega

q_tl = toi_out[0,*]*cos4omega
q_tl_out = double( fft( fft( q_tl, /double)*filter, /double, /inv))
power_spec, q_tl_out, f_sample, pw_q_proj

prepare_fft, q_in, f_sample, gna, base=1
gna = q_in
power_spec, gna, f_sample, pw_q_in

;prepare_fft, q_tl, f_sample, gna, base=1
gna = q_tl
power_spec, gna, f_sample, pw_q_out

;prepare_fft, q_sky, f_sample, gna, base=1
gna = q_sky
power_spec, gna, f_sample, pw_q_sky

yra = minmax([pw_q_in, pw_q_out, pw_q_sky])*[0.1,10]
wind, 1, 1, /free
plot_oo, freq, pw_q_in, yra=yra, /ys, xtitle='Hz', /nodata, $
         ytitle='AU/Hz!u-1/2!n', title='Demodulated timelines'
oplot, freq, pw_q_in, col=col_in
oplot, freq, pw_q_out, col=col_out
oplot, freq, pw_q_sky, col=col_sky
oplot, freq, mean(pw_q_sky[wf])*exp(-freq^2/(2.*sigma_k^2)), col=200, line=2
legendastro, ['Input', 'Output', 'Sky'], $
        line=0, col=[col_in, col_out, col_sky]
;;================================================================================================                                                                 
;; Output maps (simple binning of T, Q and U-timelines)
map_t_out = map_t*0.0d0
map_q_out = map_q*0.0d0
map_u_out = map_u*0.0d0
nhits_out = map_t*0.0d0
delvarx, filter
for ibol=0, nbol-1 do begin

   ;prepare_fft, toi_out[ibol,*], f_sample, t_tl, base=1
   t_tl = toi_out[ibol,*]
   q_tl = toi_out[ibol,*]*cos4omega
   u_tl = toi_out[ibol,*]*sin4omega

   if ibol eq 0 then begin
      np_bandpass, t_tl, f_sample, t_tl_out, freqlow=freqlow, freqhigh=freqhigh, /gaussian, filter=filter
   endif else begin
      t_tl_out = double( fft( fft( t_tl, /double)*filter, /double, /inv))
   endelse
   q_tl_out = double( fft( fft( q_tl, /double)*filter, /double, /inv))
   u_tl_out = double( fft( fft( u_tl, /double)*filter, /double, /inv))


   ;;power_spec, q_tl, f_sample, pw_q, freq
   ;;power_spec, q_tl_out, f_sample, pw_q_out
   ;;wind, 1, 1, /free
   ;;plot_oo, freq, pw_q
   ;;oplot, freq, pw_q_out, col=70
   ;;stop

   x = x_0 + dx[ibol] - xmap[0] - res_arcsec/2. ; lower left corner
   y = y_0 + dy[ibol] - ymap[0] - res_arcsec/2. ; lower left corner
   ipix = long(y/res_arcsec)*nx + long(x/res_arcsec)
   if min(ipix) lt 0 or max(ipix) gt (long(nx)*long(ny)-1) then begin
      print, "Wrong pixel index: ibol, i, ipix: "
      stop
   endif else begin
      for ii=0L, nsn-1 do begin
         map_t_out[ ipix[ii]] = map_t_out[ ipix[ii]] + t_tl_out[ii]
         map_q_out[ ipix[ii]] = map_q_out[ ipix[ii]] + q_tl_out[ii] * 2.d0
         map_u_out[ ipix[ii]] = map_u_out[ ipix[ii]] + u_tl_out[ii] * 2.d0
         nhits_out[ ipix[ii]] = nhits_out[ ipix[ii]] + 1.0d0
      endfor
   endelse
endfor

w = where( nhits_out ne 0, nw, compl=w1, ncompl=nw1)
if nw ne 0 then begin
   map_t_out[w] = map_t_out[w]/nhits_out[w]
   map_q_out[w] = map_q_out[w]/nhits_out[w]
   map_u_out[w] = map_u_out[w]/nhits_out[w]
endif
if nw1 ne 0 then begin
   map_t_out[w1] = !undef
   map_q_out[w1] = !undef
   map_u_out[w1] = !undef
endif
   

map_t_diff = map_t*0.0d0
map_t_diff[w] = map_t[w] - map_t_out[w]

map_q_diff = map_q*0.0d0
map_q_diff[w] = map_q[w] - map_q_out[w]

map_u_diff = map_u*0.0d0
map_u_diff[w] = map_u[w] - map_u_out[w]



zrange = [-1,1]*stddev( map_t[w])*3
wind, 1, 1, /free, /large
!p.multi = [0,2,2]
db, map_t, bar_range=zrange, title='T in'
db, map_t_out, bar_range=zrange, title='T out'
db, map_t_diff, bar_range=zrange, title='T in-out'
db, map_t_diff, bar_range=[-1,1]*stddev(map_t_diff[w])*3, title='T in-out'
!p.multi=0

zrange = [-1,1]*stddev( map_q[w])*3
wind, 1, 1, /free, /large
!p.multi = [0,2,2]
db, map_q, bar_range=zrange, title='Q in'
db, map_q_out, bar_range=zrange, title='Q out'
db, map_q_diff, bar_range=zrange, title='Q in-out'
db, map_q_diff, bar_range=[-1,1]*stddev(map_q_diff[w])*3, title='Q in-out'
!p.multi=0

zrange = [-1,1]*stddev( map_u[w])*3
wind, 1, 1, /free, /large
!p.multi = [0,2,2]
db, map_u, bar_range=zrange, title='U in'
db, map_u_out, bar_range=zrange, title='U out'
db, map_u_diff, bar_range=zrange, title='U in-out'
db, map_u_diff, bar_range=[-1,1]*stddev(map_u_diff[w])*3, title='U in-out'
!p.multi=0


end
