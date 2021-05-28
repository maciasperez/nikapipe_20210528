

;; Trying to have a single routine to make maps and derive associated
;; parameters, polar or not, otf or lissajou...

;; At least scans 225 to 233 of Jan 26th, 2014

;; restore, "mask_source_ipol.save"
;; day      = '20140126'
;; scan_num = 226
;; n_iter   = 2
;; ;; add_simu = 1
;; 
;; iter_min = 1
;; png = 0

pro make_casa_map, day, scan_num, param, maps_s0, maps_s1, maps_s2, maps_covar, nhits, $
                   one_mm_only=one_mm_only, two_mm_only=two_mm_only, azel=azel,$
                   nasmyth=nasmyth, maps_q=maps_q, maps_u=maps_u, add_simu=add_simu, $
                   xmap=xmap, ymap=ymap, diffuse=diffuse, reso=reso, $
                   n_iter=n_iter, iter_min=iter_min, png=png, mask_source=mask_source

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "make_polar_map, day, scan_num, param, maps_s0, maps_s1, maps_s2, maps_covar, nhits, $"
   print, "                one_mm_only=one_mm_only, two_mm_only=two_mm_only, azel=azel,$"
   print, "                nasmyth=nasmyth, maps_q=maps_q, maps_u=maps_u, add_simu=add_simu, $"
   print, "                xmap=xmap, ymap=ymap, diffuse=diffuse"
   return
endif

if not keyword_set(iter_min) then iter_min = 0

radec = 1 ; default
if keyword_set(nasmyth) or keyword_set(azel) then radec = 0


;; Ensure correct format for "day"
t = size( day, /type)
if t eq 7 then day = strtrim(day,2) else day = string( day, format="(I8.8)")

;; quick sanity checks
if keyword_set(calibrate) and keyword_set(noskydip) then begin
   message, /info, "If you ask for /calibrate, you must not set /noskydip"
   return
endif

if keyword_set(diffuse) and keyword_set(slow) then begin
   message, /info, "Please do not set /slow together with /diffuse"
   return
endif

if keyword_set(online) and keyword_set(imbfits) then begin
   message, /info, "Please do not set /online and /imbfits at the same time"
   return
endif

if not keyword_set(k_noise) then k_noise = 0.05 ; S/N max = 20

;; Init param to be used in pipeline modules
if not keyword_set(param) then begin
   nika_pipe_default_param, scan_num, day, param
   param.map.size_ra                = 300.
   param.map.size_dec               = 300.
   
   if keyword_set(xsize) then param.map.size_ra  = xsize
   if keyword_set(ysize) then param.map.size_dec = ysize

   param.map.reso                   = 4.
   if keyword_set(diffuse) then begin
      param.decor.method = "COMMON_MODE"
;;      param.decor.common_mode.per_subscan = "yes" ; "no"
   endif else begin
      param.decor.method = 'COMMON_MODE_KIDS_OUT'
   endelse
   param.decor.iq_plane.apply       = 'no'
   param.decor.common_mode.d_min    = 30 ; 40. ; 55.0
   param.w8.dist_off_source         = 40.0
   param.zero_level.dist_off_source = 60.0
endif

if keyword_set(reso) then param.map.reso = reso


;; Ensure scan_num and day are correct (if param is passed in input
;; and comes from a previous map)
param.scan_num = scan_num
param.day      = day

;; Prepare output directory for plots and logbook
output_dir = !nika.plot_dir+"/"+day+"_"+strtrim(scan_num,2)
spawn, "mkdir -p "+output_dir
param.output_dir = output_dir

lambda_min = 1
lambda_max = 2
if keyword_set(one_mm_only) then lambda_max = 1
if keyword_set(two_mm_only) then lambda_min = 2

;; Guess if need to reset coordinates or not for each scan in case not provided
if ten(param.coord_pointing.ra[0],param.coord_pointing.ra[1],param.coord_pointing.ra[2])*15.0 eq 0 $
   and ten(param.coord_pointing.dec[0],param.coord_pointing.dec[1],param.coord_pointing.dec[2]) eq 0 then $
      reset_coord_pointing = 'yes' else reset_coord_pointing = 'no'
if ten(param.coord_source.ra[0],param.coord_source.ra[1],param.coord_source.ra[2])*15.0 eq 0 $
   and ten(param.coord_source.dec[0],param.coord_source.dec[1],param.coord_source.dec[2]) eq 0 then $
      reset_coord_source = 'yes' else reset_coord_source = 'no'

if reset_coord_pointing eq 'yes'  then param.coord_pointing.ra  *= 0
if reset_coord_pointing eq 'yes'  then param.coord_pointing.dec *= 0
if reset_coord_source   eq 'yes'  then param.coord_source.ra    *= 0
if reset_coord_source   eq 'yes'  then param.coord_source.dec   *= 0

xml     = 1                     ; default
if keyword_set(online) then begin
   xml = 0
   if not keyword_set(p2cor) then begin
      message, /info, "Please set p2cor as an input keyword if you're in /online mode"
      message, /info, "If your want to put p2cor = zero, then set p2cor=1e-10"
      return
   endif
   if not keyword_set(p7cor) then begin
      message, /info, "Please set p7cor as an input keyword if you're in /online mode"
      message, /info, "If your want to put p7cor = zero, then set p7cor=1e-10"
      return
   endif
   ;;   if not keyword_set(focusz) then begin
   ;;      message, /info, "Please set focusz as an input keyword if you're in /online mode"
;;      message, /info, "If your want to put focusz = zero then focusz=1e-10"
;;      return
;;   endif

   init_pako_str, pako_str
   pako_str.p2cor = p2cor
   pako_str.p7cor = p7cor
;;   pako_str.focusz = focusz
   pako_str.obs_type = "map"
endif

if keyword_set(imbfits) then begin
   xml = 0
   init_pako_str, pako_str
   pako_str.obs_type = "pointing"

   nika_find_raw_data_file, scan_num, day, file, imb_fits_file, /silent

   test  = file_test( imb_fits_file, /dir) ; is a directory
   test2 = file_test( imb_fits_file)       ; file/dir exists

   antexist = (test eq 0) and (test2 eq 1)
   if antexist then begin 
      imbHeader = HEADFITS( imb_fits_file,EXTEN='IMBF-scan')
      pako_str.p2cor = SXPAR(imbHeader, 'P2COR')/!pi*180.d0*3600.d0
      pako_str.p7cor = SXPAR(imbHeader, 'P7COR')/!pi*180.d0*3600.d0
      r = mrdfits( imb_fits_file, 1)
      pako_str.NAS_OFFSET_X = r.XOFFSET/!arcsec2rad
      pako_str.NAS_OFFSET_Y = r.YOFFSET/!arcsec2rad
      a = mrdfits( imb_fits_file,0,hdr,/sil)
      pako_str.obs_type = sxpar( hdr,'OBSTYPE',/silent)
      pako_str.source = sxpar(imbheader, 'OBJECT')
      ;; iext = 1
      ;; status = 0
      ;; WHILE status EQ 0 AND  iext LT 100 DO BEGIN
      ;;    aux = mrdfits(  strtrim( imb_fits_file), iext, haux, status = status, /silent)
      ;;    extname = sxpar( haux, 'EXTNAME')
      ;;    if strupcase(extname) eq 'IMBF-SCAN' then begin
      ;;       pako_str.focusz = sxpar( haux, 'FOCUSZ')
      ;;       print, "iext, focusz: ", iext, focusz
      ;;    endif
      ;;    iext = iext + 1
      ;; endwhile

      
   endif else begin
      message, /info, "the AntennaIMBfits file does not exist"
      return
   endelse
endif

if xml eq 1 then parse_pako, scan_num, day, pako_str

param.source    = strtrim( pako_str.source, 2)
param.name4file = day+"s"+strtrim(scan_num,2)
param.version   = "v1"
nickname        = param.source+"  "+param.day+"s"+strtrim(param.scan_num,2)

pf = 1
if keyword_set(RF) then pf=0
nika_pipe_getdata, param, data, kidpar, pf=pf, ext_params=ext_params, /silent, $
                   one_mm_only=one_mm_only, two_mm_only=two_mm_only, no_acq_flag=no_acq_flag, $
                   jump = jump,  list_data = list_data

;; Discard tunings and unreliable sections of data
if not keyword_set(no_acq_flag) then nika_pipe_valid_scan, param, data, kidpar

; Replace bad pointing data
if keyword_set( imbfits) and keyword_set( antimb) then begin
   ;;nika_pipe_antenna2pointing, data, imb_fits_file
   nika_pipe_antenna2pointing_2, param, data, kidpar
                                ; in case of missing pointing data paralactic
                                ; angle is bad, replace it by the last known
                                ; value
  u = where( data.paral eq 0., nu)
  v = where( data.paral ne 0., nv)
  if nu ne 0 then data[u].paral = mean( data[v].paral)

  junk = mrdfits(imb_fits_file, 2, h)
  param.projection.type = sxpar(h, "systemof")

endif

;; Flag saturated, out of resonance kids etc...
if not keyword_set(force) then nika_pipe_outofres, param, data, kidpar, /bypass
;;nika_pipe_outofres, param, data, kidpar, bypass = keyword_set(force)

;; Account for telescope gain dependence on elevation
nika_pipe_gain_cor, param, data, kidpar

;; Check if we are in "total power" or "polarization" mode
nika_pipe_get_hwp_angle, param, data, kidpar
synchro_med = median( data.c_synchro)
polar = 0 ; default
if max( abs(data.c_synchro - median( data.c_synchro))) gt 1e5 then polar = 1

;; Additional sanity check on subscan value and try to take margin
;; with tunings

if strupcase(pako_str.obs_type) eq "LISSAJOUS" or keyword_set(lissajous) then begin
   pako_str.obs_type = "lissajous" ; fill if /lissajous

   nika_pipe_lissajou_select, param, data, kidpar;, /show

   ;; values out of sections have a w8=0, but we keep them for common
   ;; mode estimation.
   ;; We reject samples outside subscans to avoid tunings and other problems
   wkeep = where( data.subscan ge 1, nw)
endif else begin
   ;;w = where( data.subscan ge 1 and data.subscan lt
   ;;max(data.subscan), nw)
   wkeep = where( data.subscan ge 1, nw) ;  and data.subscan lt max(data.subscan), nw)
endelse

nika_pipe_speedflag2, param, data

nsubscans =  max(data.subscan)-min(data.subscan)+1
make_ct, nsubscans, ct
nsn = n_elements(data)
index = lindgen(nsn)

;; Quicklook at a raw timeline
wind, 1, 1, /free, xs=1000, ys=700
!p.multi=[0,1,2]
xra = minmax(index)

w = where( kidpar.numdet eq !nika.numdet_ref_1mm, nw)
if nw ne 0 then begin
   ikid = w[0]
endif else begin
   w = where( kidpar.numdet eq !nika.numdet_ref_2mm, nw)
   if nw eq 0 then begin
      message, /info, "No reference kid available neither at 1mm nor at 2mm ?!"
      message, /info, "I'll take the first valid one"
      ikid = min( where( kidpar.type eq 1))
   endif else begin
      ikid = w[0]
   endelse
endelse

subscan_plot =  data.subscan/max(data.subscan)*max(data.rf_didq[ikid])

plot, index, data.rf_didq[ikid], xtitle='Sample Number', $
      ytitle='Flux', title=nickname+' Raw timeline', $
      xra=xra, /xs

for i=(min(data.subscan)>1), max(data.subscan) do begin
   w = where( data.subscan eq i, nw)
   oplot, index[w], data[w].rf_didq[ikid], col=ct[i-min(data.subscan)], psym=1
endfor

data.a_masq = double( data.a_masq ne 0)
oplot, index, data.a_masq*max(data.rf_didq[ikid]), col=70, thick=2
data.b_masq = double( data.b_masq ne 0)
oplot, index, data.b_masq*max(data.rf_didq[ikid]), col=250
oplot, index, subscan_plot,  line = 2,  thick = 2, col = 200

for i = min(data.subscan),  max(data.subscan) do begin
   m =  min(where(data.subscan eq i))
   xyouts,  index[m], subscan_plot[m], "Subscan = "+strtrim( long(i), 2), chars = 1.5
endfor
legendastro, "Subscan "+strtrim( indgen(nsubscans)+long(min(data.subscan)), 2), col=ct, box=0, line=0, chars=0.6
legendastro, ['a_masq', 'b_masq'], col=[70,250], line=0, /bottom, box=0


;ww = where( data[wkeep].w8[0] ne 0 and data[wkeep].flag[0] eq 0)
plot, index[wkeep], data[wkeep].rf_didq[ikid], xtitle='Sample Number', $
      ytitle='Flux [Hz]', title='Kept samples', xra=xra, /xs
;oplot, index[wkeep[ww]], data[wkeep[ww]].rf_didq[ikid], col=250
legendastro, ['Selection on subscans', 'Selection on subscans and flags'], $
             col=[0,250], line=0, box=0
legendastro, [strtrim(kidpar[ikid].array,2)+" mm, Numdet "+strtrim( kidpar[ikid].numdet, 2)], box=0, /right
!p.multi=0
if keyword_set(check) then stop

;; update
data    = data[wkeep]
nsn     = n_elements(data)
index   = lindgen(nsn)

;; Ensure that data has a convenient number for FFTs
nsn = n_elements( data)
tol = 0.10 ; percent of data ok to discard
primes = [2,3,5,7,11,13]
sn_max = 0
i=0
while (sn_max lt (nsn-1)) and ( (nsn-sn_max)/float(nsn) gt tol) and (i le (n_elements(primes)-1)) do begin
   p = long(alog( nsn-sn_max)/alog( primes[i]))
   print, "p=", p
   sn_max = sn_max + long(primes[i])^p
   i +=1
endwhile
;print, "************************************"
;print, "************************************"
;print, "************************************"
;print, "CHECK SN_MAX"
;sn_max = 2L^15 + 3L^8 ; to remove the last sample (weird)
;print, "************************************"
;print, "************************************"
;print, "************************************"
;stop
data = data[0:sn_max-1]
nsn                 = n_elements(data)
param.integ_time[0] = nsn/!nika.f_sampling
nsubscans           =  max(data.subscan)-min(data.subscan)+1
index               = lindgen(nsn)
make_ct, nsubscans, ct

data_copy  = data
nkids = n_elements(kidpar)

;; Subtract low frequencies before fiting out the template (it should improve)
low_freq = data.rf_didq*0.d0 ; init
freqhigh = 1.d0
np_bandpass, dblarr(nsn), !nika.f_sampling, freqhigh=freqhigh, filter=filter
for i=0, nkids-1 do begin
   if kidpar[i].type eq 1 then begin
      np_bandpass, data.rf_didq[i], !nika.f_sampling, s_out, filter=filter
      low_freq[i,*]    = s_out
      data.rf_didq[i] -= s_out
   endif
endfor

;; Determine HWP rotation speed
get_hwp_rot_freq, data, rot_freq_hz
param.polar.nu_rot_hwp = rot_freq_hz

;; Subtract HWP template
nika_pipe_hwp_rm, param, kidpar, data

;; Restore low frequencies
data.rf_didq += low_freq
delvarx, low_freq ; save memory

;;------------------------------------------------------------
power_spec, data_copy.rf_didq[0] - my_baseline(data_copy.rf_didq[0]), !nika.f_sampling, pw1, freq
power_spec, data.rf_didq[0]      - my_baseline(data.rf_didq[0]),      !nika.f_sampling, pw,  freq
wind, 1, 1, /free, /large
!p.multi=[0,2,2]
plot_oo, freq, pw1, /xs
oplot, freq, pw, col=250
plot, data.rf_didq[0] - my_baseline(data.rf_didq[0])
!p.multi=0

;;------------------------------------------------------------

;;------- Correct the pointing from antenna data !!!!!!!!!!!!!! TO BE IMPROVED !!!!!!!!!!!!!!
;nika_pipe_corpointing, param, data, kidpar, simu=simu, azel=azel
     
;; Calibrate the data
nika_pipe_deglitch, param, data, kidpar
nika_pipe_opacity,  param, data, kidpar, simu=simu, noskydip=noskydip
nika_pipe_calib,    param, data, kidpar, noskydip=noskydip
  
data_copy = data ; for iteration with cmkidout

;; Assume the source is point like, at the center and jump directly
;; to cmkidout
box = ['A', 'B']
source_pos = dblarr(2,2)
educated = 1

;;-------------------------------------------------------------------------------------
if keyword_set(add_simu) then begin
   ;; Add a strong polarized point source at the center to see if we can detect
   ;; it
   
   ;;*********************************************
   ;; No sky rotation (Azel,radec,nasmyth) for now
   ;;**********************************************

   p = 0.2
   psi = 10

   Intensity = 30 ; Jy
   Q = I*p*cos(2*psi*!dtor)
   U = I*p*sin(2*psi*!dtor)

   cos4omega = cos(4.d0*data.c_position)
   sin4omega = sin(4.d0*data.c_position)

   for lambda=1, 2 do begin

      if lambda eq 1 then sigma_beam = 12*!fwhm2sigma else sigma_beam = 17*!fwhm2sigma

      nk_list_kids, kidpar, lambda=lambda, valid=w1, nvalid=nw1
      if nw1 ne 0 then begin
         for i=0, nw1-1 do begin
            ikid = w1[i]
            
            ;; compute pointing for each detector
            nika_nasmyth2draddec, data.ofs_az, data.ofs_el, data.el, data.paral, $
                                  kidpar[ikid].nas_x, kidpar[ikid].nas_y, $
                                  0., 0., dra, ddec, nas_x_ref=kidpar[ikid].nas_center_X, $
                                  nas_y_ref=kidpar[ikid].nas_center_Y
         
            beam_w8 = exp( -(dra^2+ddec^2)/(2*sigma_beam^2))
            ;;data.rf_didq[ikid] += beam_w8*( Intensity + cos4omega*Q + sin4omega*U)
            data.rf_didq[ikid] = 0.5*beam_w8*( Intensity + cos4omega*Q + sin4omega*U) + randomn( seed, nsn)
            ;;data.rf_didq[ikid] = 0.5*beam_w8*Intensity + randomn( seed, nsn)*0.01
         endfor
      endif
   endfor

;; ;; Plot for astropol
;; noise_1d, n_elements(data), !nika.f_sampling, noise, net=0.1, fknee=1., alpha=2
;; power_spec, noise + data.rf_didq[0], !nika.f_sampling, pw1, freq
;; outplot, file='power_spec', /png
;; plot_oo, freq, pw1, /xs, yra=[1e-2, 1e2], xtitle='Frequency [Hz]', ytitle='Power Spectrum'
;; outplot, /close

endif


;;------------------------------------------------------------------------
;; Main loop
pos = avg( source_pos, 0)
if keyword_set(one_mm_only) then pos = reform( source_pos[0,*])
if keyword_set(two_mm_only) then pos = reform( source_pos[1,*])

cos4omega = cos(4*data.c_position)
sin4omega = sin(4*data.c_position)

if not keyword_set(n_iter) then n_iter = 1

param.polar.do_lockin       = 1
param.polar.lockin_freqhigh = param.polar.nu_rot_hwp * 0.9
param.polar.lockin_freqlow  = 0.d0

data     = data_copy
noise    = data.rf_didq*0.d0 ; init
w8source = data.rf_didq*0.d0 ; init
w1 = where( kidpar.type eq 1, nw1)

;; ;; Init lowpass filter for atmosphere common mode
;; delvarx, filter
;; high_freq = data.rf_didq*0.d0    ; init
;; freqhigh = 1.d0
;; np_bandpass, dblarr(nsn), !nika.f_sampling, freqhigh=freqhigh, filter=filter

reso_x = param.map.reso
reso_y = param.map.reso
nx = round(param.map.size_ra/param.map.reso)     ;Number of pixels along ra
ny = round(param.map.size_dec/param.map.reso)    ;Number of pixels along dec
nx = 2*long(nx/2.0) + 1                          ;Ensure there's a pixel centered on (0,0)
ny = 2*long(ny/2.0) + 1
xmin = (-nx/2-0.5)*param.map.reso
ymin = (-ny/2-0.5)*param.map.reso


if keyword_set(mask_source) then begin
   for i=0, nw1-1 do begin
      ikid = w1[i]
      nika_nasmyth2draddec, data.ofs_az, data.ofs_el, data.el, data.paral, $
                            kidpar[ikid].nas_x, kidpar[ikid].nas_y, $
                            0., 0., dra, ddec, nas_x_ref=kidpar[ikid].nas_center_X, $
                            nas_y_ref=kidpar[ikid].nas_center_Y
      ix   = long( (dra  - xmin)/param.map.reso) ;Coord of the pixel along x
      iy   = long( (ddec - ymin)/param.map.reso) ;Coord of the pixel along y
      ipix = ix + iy*nx                          ;Number of the pixel
      
      w8source[ikid,*] = mask_source[ipix]
   endfor
endif else begin
   print, "warning, you need mask source here"
   stop
;;   w8source = data.rf_didq*0.d0 + 1.d0
endelse


;; wind, 1, 1, /free
;; lambda=1
;; w11 = where( kidpar.type eq 1 and kidpar.array eq lambda, nw11)
;; for i=0, nw11-1 do begin
;;    ikid = w11[i]
;;    ;;plot, data_copy.rf_didq[ikid]
;;    plot, data.rf_didq[ikid]
;;    legendastro, strtrim( kidpar[ikid].numdet,2), box=0
;;    cont_plot
;; endfor
;; 


;;------------------------------------------------------------------------
;; Check for outlyers in their bands
my_match, kidpar.numdet, [16,32,48,56,286,431,488], suba, subb
kidpar[suba].type = 3
iband_max = max( kidpar.raw_num/80)

;; subtract a global baseline to each kid
for ikid=0, n_elements(kidpar)-1 do begin
   if kidpar[ikid].type eq 1 then data.rf_didq[ikid] -= my_baseline(data.rf_didq[ikid])
endfor

;; wind, 1, 1, /free
;; for iband=0, iband_max-1 do begin
;;    w = where( kidpar.raw_num/80 eq iband and kidpar.type eq 1, nw)
;;    if nw eq 0 then begin
;;       print, "no valid kid in band "+strtrim(iband,2)
;;    endif else begin
;;       make_ct, nw, ct
;;       ;;plot, data.rf_didq[w[0]], /xs, yra=minmax( data.rf_didq[w]), /ys, title="band "+strtrim(iband,2)
;;       plot, data.rf_didq[w[0]]-my_baseline(data.rf_didq[w[0]]), /xs, yra=minmax( data.rf_didq[w]), /ys, title="band "+strtrim(iband,2)
;;       if nw ge 2 then begin
;;          for ii=1, nw-1 do begin
;;             oplot, data.rf_didq[w[ii]], col=ct[ii]
;;             print, kidpar[w[ii]].numdet
;;             cont_plot
;;          endfor
;;       endif
;;    endelse
;; cont_plot
;; endfor

;; wind, 1, 1, /free
;; for iband=0, iband_max-1 do begin
;;    w = where( kidpar.raw_num/80 eq iband and kidpar.type eq 1, nw)
;;    if nw eq 0 then begin
;;       print, "no valid kid in band "+strtrim(iband,2)
;;    endif else begin
;;       make_ct, nw, ct
;;       plot, data.rf_didq[w[0]]-my_baseline(data.rf_didq[w[0]]), /xs, yra=[-50,50], /ys, title="band "+strtrim(iband,2)
;;       if nw ge 2 then begin
;;          for ii=1, nw-1 do begin
;;             ;;oplot, data.rf_didq[w[ii]], col=ct[ii]
;;             oplot, data.rf_didq[w[ii]] - my_baseline(data.rf_didq[w[ii]]), col=ct[ii]
;;             print, kidpar[w[ii]].numdet
;;             cont_plot
;;          endfor
;;       endif
;;    endelse
;; cont_plot
;; endfor
;; stop
;;------------------------------------------------------------------------

my_match, kidpar.numdet, [17,27,36,51,171,193,55,85,86,94,104,178,185,202,250,254,263,268,282,288,330,333,334,336,340,350], suba, subb
kidpar[suba].type = 3


;; Pass flag info to kidpar
w1 = where( kidpar.type eq 1, nw1)
for i=0, nw1-1 do begin
   ikid = w1[i]
   if min(data.flag[ikid]) ne 0 then kidpar[ikid].type = 3
endfor

for iter=iter_min, n_iter-1 do begin

   data.rf_didq = data_copy.rf_didq

   if iter eq 0 then begin
      ;; first estimate by median filter
      nika_pipe_decor, param, data, kidpar
   endif else begin
      
      ;;---------------------------
      ;; Classic common mode
      for lambda=1, 2 do begin
         w11 = where( kidpar.type eq 1 and kidpar.array eq lambda, nw11)
         if nw11 ne 0 then begin
            
            ;; Subtract the atmosphere (simple common mode outside the mask)
            rf_didq = data.rf_didq[w11]
            nika_pipe_subtract_common_atm, param, rf_didq, kidpar[w11], w8source[w11,*]
            data.rf_didq[w11] = rf_didq
         endif
      endfor
   
      ;; ;;---------------------------
      ;; ;; Common mode per band
      ;; for iband=0, iband_max-1 do begin
      ;;    w = where( kidpar.raw_num/80 eq iband and kidpar.type eq 1, nw)
      ;;    if nw lt 2 then begin
      ;;       print, "Less than 2 kids in band "+strtrim(iband,2)
      ;;    endif else begin
      ;;       rf_didq = data.rf_didq[w]
      ;;       nika_pipe_subtract_common_atm, param, rf_didq, kidpar[w], w8source[w,*]
      ;;       data.rf_didq[w] = rf_didq
      ;;    endelse
      ;; endfor

;;       ;;---------------------------
;;       ;; using blocks of max correlated kids
;;       param.decor.common_mode.nbloc_min = 10 ; by hand
;;       for lambda=1, 2 do begin
;;          w11 = where( kidpar.type eq 1 and kidpar.array eq lambda, nw11)
;;          if nw11 ne 0 then begin
;;             rf_didq = data.rf_didq[w11] 
;;             nika_pipe_subtract_common_bloc, param, rf_didq, kidpar[w11], w8source[w11,*]
;;          endif
;; 
;; ;;         ;; Discard 50% of kids for a test, based on stddev
;; ;;         sigma = dblarr(nw11)
;; ;;         for i=0, nw11-1 do sigma[i] = stddev( rf_didq[i,*])
;; ;;         med = median(sigma)
;; ;;         for i=0, nw11-1 do begin
;; ;;            if sigma[i] gt med then begin
;; ;;               ikid = w11[i]
;; ;;               kidpar[ikid].type = 3
;; ;;            endif
;; ;;         endfor
;; ;;
;; ;;         ;; iterate on common mode subtraction
;; ;;         w11 = where( kidpar.type eq 1 and kidpar.array eq lambda, nw11)
;; ;;         if nw11 ne 0 then begin
;; ;;            rf_didq = data.rf_didq[w11]
;; ;;            nika_pipe_subtract_common_bloc, param, rf_didq, kidpar[w11], w8source[w11,*]
;; ;;            data.rf_didq[w11] = rf_didq
;; ;;         endif
;;      endfor

   endelse

   ;; Update toi weights
   for lambda=1, 2 do begin
      w11 = where( kidpar.type eq 1 and kidpar.array eq lambda, nw11)
      if nw11 ne 0 then begin
         for i=0, nw11-1 do begin
            ikid = w11[i]
            w = where( data.flag[ikid] eq 0 and w8source[ikid,*] eq 1, nw)
            if nw eq 0 then begin
               print, "no valid hits ?!"
               stop
            endif else begin
               data.w8[ikid] = 1.d0/stddev( data[w].rf_didq[ikid])^2
            endelse
         endfor
      endif
   endfor

   ;; Project (Lock-in)
   nika_pipe_polar_maps, param, data, kidpar, maps_S0, maps_S1, maps_S2, maps_covar, nhits, $
                         xmap=xmap, ymap=ymap, azel=azel, nasmyth=nasmyth

   ;; nika_pipe_polar_maps_uranus, param, data, kidpar, maps_S0, maps_S1, maps_S2, maps_covar, nhits, $
   ;;                              xmap=xmap, ymap=ymap, azel=azel, nasmyth=nasmyth


   ;; replace NaN by zeros for the subtraction below
   wnan = where( finite( maps_s0) ne 1, nwnan)
   if nwnan ne 0 then maps_s0[wnan] = 0.d0
   wnan = where( finite( maps_s1) ne 1, nwnan)
   if nwnan ne 0 then maps_s1[wnan] = 0.d0
   wnan = where( finite( maps_s2) ne 1, nwnan)
   if nwnan ne 0 then maps_s2[wnan] = 0.d0
   
   xmin = min(xmap)-param.map.reso/2.
   ymin = min(ymap)-param.map.reso/2.
   nx   = n_elements(xmap[*,0])
   ny   = n_elements(xmap[0,*])
   map_i_1mm = reform( maps_s0[*,0], nx, ny)
   map_q_1mm = reform( maps_s1[*,0], nx, ny)
   map_u_1mm = reform( maps_s2[*,0], nx, ny)
   map_i_2mm = reform( maps_s0[*,1], nx, ny)
   map_q_2mm = reform( maps_s1[*,1], nx, ny)
   map_u_2mm = reform( maps_s2[*,1], nx, ny)
   
   nick = day+'s'+strtrim(scan_num,2)+", iter="+strtrim(iter,2)
   wind, 1, 1, /free, xs=1600, ys=1000
   outplot, file='maps_'+day+'s'+strtrim(scan_num,2)+'_iter'+strtrim(iter,2), png=png
   nick = nick+"el: "+num2string( data[nsn/2].el*!radeg)
;   my_multiplot, 3, 3, pp, pp1, /rev
   my_multiplot, 3, 2, pp, pp1, /rev
   imview, map_i_1mm, xmap=xmap, ymap=ymap, position=pp1[0,*], imrange=[-1,1], title='T 1mm '+nick
   imview, map_q_1mm, xmap=xmap, ymap=ymap, position=pp1[1,*], imrange=[-1,1]*0.5, title='Q 1mm '+nick, /noerase
   imview, map_u_1mm, xmap=xmap, ymap=ymap, position=pp1[2,*], imrange=[-1,1]*0.5, /noerase, title='U 1mm '+nick
   imview, map_i_2mm, xmap=xmap, ymap=ymap, position=pp1[3,*], imrange=[-1,1], /noerase, title='T 2mm '+nick
   imview, map_q_2mm, xmap=xmap, ymap=ymap, position=pp1[4,*], imrange=[-1,1]*0.1, /noerase, title='Q 2mm '+nick
   imview, map_u_2mm, xmap=xmap, ymap=ymap, position=pp1[5,*], imrange=[-1,1]*0.1, /noerase, title='U 2mm '+nick
;   imview, maps_q.b.jy, xmap=xmap, ymap=ymap, position=pp1[7,*], /noerase, title='Q common...', imrange=[-1,1]*0.1
;   imview, maps_u.b.jy, xmap=xmap, ymap=ymap, position=pp1[8,*], /noerase, title='U common...', imrange=[-1,1]*0.1
   outplot, /close


   ;; Estimate the noise timeline for this iteration and w8source
   threshold = 0.2
;   stop
;;   mask_source = long( map_i_2mm lt threshold)


endfor

;; save, maps_q, maps_u, maps_s0, maps_s1, maps_s2, maps_covar, nhits, xmap, ymap, file='maps_'+day+'s'+strtrim(scan_num,2)+'.save'
save, maps_s0, maps_s1, maps_s2, maps_covar, nhits, xmap, ymap, file='maps_'+day+'s'+strtrim(scan_num,2)+'.save'

end
