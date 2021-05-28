

pro focus_plot_fit, z_pos, flux, s_flux, z_opt, delta_z_opt, $
                    color=color, title=title, leg_txt=leg_txt, position=position, $
                    noerase=noerase, ref=ref, no_acq_flag=no_acq_flag

fmt = "(F5.2)"
xra = minmax(z_pos) + [-0.2, 0.2]*(max(z_pos)-min(z_pos))
w = where( z_pos gt !undef, nw)
ploterror, z_pos[w], flux[w], s_flux[w], psym=8, $
           xra=xra, /xs, noerase=noerase, xtitle='z [mm]', title=title, position=position, color=color
;xyouts, z_pos[w], flux[w], strtrim(w,2)

if nw ge 3 then begin
   zz = dindgen(100)/100.*(max(xra)-min(xra))+min(xra)
       
   templates = dblarr( 3, nw)
   for ii=0, 2 do templates[ii,*] = z_pos[w]^ii
   multifit, flux[w], s_flux[w], templates, ampl_out, fit, out_covar
   z_opt = -ampl_out[1]/(2.d0*ampl_out[2])
   delta_z_opt = abs(z_opt) * ( abs( sqrt(out_covar[1,1])/ampl_out[1]) + abs(sqrt(out_covar[2,2])/ampl_out[2]))
       
   oploterror, z_pos[w], flux[w], s_flux[w], psym=8, color=color, errcol=color
   oplot, zz, ampl_out[0] + ampl_out[1]*zz + ampl_out[2]*zz^2, color=color
   legendastro, leg_txt, box=0, /right, textcol=color
   legendastro, ['z: '+num2string(z_opt)+" +- "+num2string(delta_z_opt)], $
                /bottom, /right, box=0
endif else begin
   message, "Less than three focus positions available to fit focus ?!"
endelse

end

;;---------------------------------------------------------------------------------------------
pro focus_snapshot, samples, ikidlist, data, kidpar, fwhm, xmap, ymap, map, nhits, params

map   = xmap*0.d0
nhits = xmap*0.d0
nx    = n_elements( xmap[*,0])
ny    = n_elements( xmap[0,*])
sigma = fwhm*!fwhm2sigma

nkids = n_elements( ikidlist)
for i=0, nkids-1 do begin
   ikid = ikidlist[i]
   d2 = (xmap-kidpar[ikid].nas_x)^2 + (ymap-kidpar[ikid].nas_y)^2
   mask = double( d2 lt (4.*sigma)^2)
   map   += avg(data[samples].rf_didq[ikid]) * exp(-d2/(2.*sigma^2)) * mask
   nhits +=                                    exp(-d2/(2.*sigma^2)) * mask
endfor
wpix = where( nhits ne 0, nwpix)
if nwpix eq 0 then message, "all pixels empty ?"
;map[wpix] /= nhits[wpix]

;; Gaussian Fit
errors = 1.d0/sqrt(nhits[wpix])
pguess = [min(map[wpix]), max(map[wpix]), sigma, sigma, 0., 0., 0.]
delvarx, params
fit = nika_gauss2dfit( map[wpix], xmap[wpix], ymap[wpix], errors, params)

end

;;===============================================================================================
pro focus, day, scan_num, focus1, focus2, xbeam_1mm, ybeam_1mm, xbeam_2mm, ybeam_2mm, $
           numdet1_in=numdet1_in, numdet2_in=numdet2_in, png=png, ps=ps, $
           one_mm_only=one_mm_only, two_mm_only=two_mm_only, no_acq_flag=no_acq_flag, $
           common_mode_radius=common_mode_radius, logbook=logbook, param=param, $
           online=online, imbfits=imbfits, fooffset=fooffset, focusz=focusz, radius=radius, noskydip=noskydip, $
           list_data=list_data, check=check, debug=debug, RF=RF, sn_min=sn_min, sn_max=sn_max, force=force, $
           antimb = antimb, jump = jump, err_focus1=err_focus1, err_focus2=err_focus2, max6=max6

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   return
endif

if not keyword_set(radius)             then radius             = 20.
if not keyword_set(common_mode_radius) then common_mode_radius = 40.

if keyword_set(online) and keyword_set(imbfits) then begin
   message, /info, "Please do not set /online and /imbfits at the same time"
   return
endif

if keyword_set(online) then begin
   if not keyword_set(fooffset) then begin
      message, /info, "Please set fooffset in input keyword if you're working /online"
      return
   endif
   if not keyword_set(focusz) then begin
      message, /info, "Please set focusz in input keyword if you're working /online"
      return
   endif
endif

;; Ensure correct format for "day"
t = size( day, /type)
if t eq 7 then day = strtrim(day,2) else day = string( day, format="(I8.8)")

if not keyword_set(param) then nika_pipe_default_param, scan_num, day, param
param.map.size_ra    = 200.
param.map.size_dec   = 200.
param.map.reso       = 4.

;; Prepare output directory for plots and logbook
output_dir = !nika.plot_dir+"/"+day+"_"+strtrim(scan_num,2)
spawn, "mkdir -p "+output_dir
param.output_dir = output_dir

;; Get data
pf = 1
if keyword_set(rf) then pf = 0
nika_pipe_getdata,  param, data, kidpar, /nocut, list_data=list_data, ext_params=ext_params, $
                    no_acq_flag=no_acq_flag, /silent, pf=pf, jump = jump

;; Patch to save a few files from Run6 with extra subscans
if keyword_set(max6) then data = data[ where(data.subscan le 6)]

nkids = n_elements(kidpar)

;; Discard tunings and unreliable sections of data
if not keyword_set(no_acq_flag) then nika_pipe_valid_scan, param, data, kidpar

;; Flag saturated, out of resonance kids etc...
if not keyword_set(force) then nika_pipe_outofres, param, data, kidpar, /bypass

;; Account for telescope gain dependence on elevation
nika_pipe_gain_cor, param, data, kidpar

;if not keyword_set(sn_min) then sn_min = 0
;if not keyword_set(sn_max) then sn_max = n_elements(data)-1
;data = data[sn_min:sn_max]

;; Check if we are in "total power" or "polarization" mode
;nika_pipe_get_hwp_angle, param, data, kidpar
;synchro_med = median( data.c_synchro)
polar = 0 ; default
;if max( abs(data.c_synchro - median( data.c_synchro))) gt 1e5 then polar = 1

if polar eq 1 then begin
   ;; Determine HWP rotation speed
   get_hwp_rot_freq, data, rot_freq_hz
   param.polar.nu_rot_hwp = rot_freq_hz

   ;; Subtract HWP template
   nika_pipe_hwp_rm, param, kidpar, data, fit
endif

nika_pipe_deglitch, param, data, kidpar
nika_pipe_opacity,  param, data, kidpar, noskydip=noskydip
nika_pipe_calib,    param, data, kidpar, noskydip=noskydip                     

;; !nika.numdet_ref_Xmm is initialized in get_kidpar_ref, called by nika_pipe_getdata
if keyword_set(numdet1_in) then numdet1 = numdet1_in else numdet1 = !nika.numdet_ref_1mm
if keyword_set(numdet2_in) then numdet2 = numdet2_in else numdet2 = !nika.numdet_ref_2mm
numdet_ref = [numdet1, numdet2]

xml = 1 ; default
if keyword_set(online) then begin
   xml = 0

   init_pako_str, pako_str
   pako_str.obs_type = "focus"
   pako_str.focusz   = focusz
   pako_Str.source   = ""
endif

if keyword_set(imbfits) then begin
   xml = 0

   init_pako_str, pako_str
   pako_str.obs_type = "focus"
   pako_Str.source   = ""

   iext = 1
   status = 0
   fooffset = [0]
   imbHeader = HEADFITS( param.imb_fits_file,EXTEN='IMBF-scan')
   pako_str.source = sxpar(imbheader, 'OBJECT')
   WHILE status EQ 0 AND  iext LT 100 DO BEGIN
      aux = mrdfits(  strtrim( param.imb_fits_file), iext, haux, status = status, /silent)
      extname = sxpar( haux, 'EXTNAME')
      if strupcase(extname) eq "IMBF-ANTENNA" then begin
         fooffset = [fooffset, sxpar( haux, 'FOOFFSET')]
         print, sxpar( haux, 'FOOFFSET')
      endif
      if strupcase(extname) eq 'IMBF-SCAN' then begin
         focusz = sxpar( haux, 'FOCUSZ')
         print, "iext, focusz: ", iext, focusz
      endif
      iext = iext + 1
   endwhile
   fooffset = fooffset[1:*]
endif

if xml eq 1 then begin
   parse_pako, scan_num, day, pako_str

   focusz   = pako_str.focusz
   fooffset = dblarr(6)
   pako_tags = tag_names(pako_str)
   for i=0, 5 do begin
      w = where( strupcase(pako_tags) eq "FOFFSET"+strtrim(i,2), nw)
      if nw eq 0 then begin
         message, /info, "Wrong focus offset information in pako_str"
         stop
      endif else begin
         fooffset[i] = pako_str.(w)
      endelse
   endfor
endif

param.source    = strtrim( pako_str.source, 2)


nsn = n_elements( data)
index = lindgen(nsn)

if !nika.run eq '5' then begin
   ;; synchronization was different for run 5...
   ;; this shift 70 was derived by hand by comparing timelines of runcryo
   ;; (20131114s22) and run5 (20121122s220)
   data.rf_didq = shift( data.rf_didq, 0, 70)
endif

if keyword_set(check) then begin

   lambda = 2
   ikid = (where( kidpar.numdet eq numdet_ref[lambda-1], nw))[0]

   yra = [min(data.rf_didq[ikid]), max(data.rf_didq[ikid]) + 0.2*(max(data.rf_didq[ikid]) - min(data.rf_didq[ikid]))]
   wind, 1, 1, /free, xs=1200, ys=600
   my_multiplot, 1, 5, pp, pp1, /full, /dry
   plot, index, data.subscan, position=pp[0,0,*], /noerase, /xs
   w = where( data.scan_st eq 4, nw)
   for j=0, nw-1 do oplot, [1,1]*w[j], [-1,1]*1e10, col=150
   w = where( data.scan_st eq 5, nw)
   for j=0, nw-1 do oplot, [1,1]*w[j], [-1,1]*1e10, col=250
   ;; show subscan limits
   for i=1, 6 do begin
      i1 = min( where( data.subscan eq i))
      i2 = max( where( data.subscan eq i))
      oplot, [i1,i1], [-1,1]*1e10, line=2
      oplot, [i2,i2], [-1,1]*1e10, line=2
      xyouts, i1, 0.95*max(yra), "subscan "+strtrim(i,2)
   endfor
   oplot, index, data.subscan ; overplot
   legendastro, 'Subscan', /right, /bottom, box=0

   plot, index, data.rf_didq[ikid], /xs, /ys, yra=yra, position=[pp[0,1,0], pp[0,1,1], pp[0,4,2], pp[0,4,3]], /noerase
   ;; scan_st
   w = where( data.scan_st eq 4, nw)
   for j=0, nw-1 do oplot, [1,1]*w[j], [-1,1]*1e10, col=150
   w = where( data.scan_st eq 5, nw)
   for j=0, nw-1 do oplot, [1,1]*w[j], [-1,1]*1e10, col=250
   legendastro, ['scan started', 'scan done'], col=[150,250], /bottom, /right, box=0, line=0
   ;; show subscan limits
   for i=1, 6 do begin
      i1 = min( where( data.subscan eq i))
      i2 = max( where( data.subscan eq i))
      oplot, [i1,i1], [-1,1]*1e10, line=2
      oplot, [i2,i2], [-1,1]*1e10, line=2
      xyouts, i1, 0.95*max(yra), "subscan "+strtrim(i,2)
   endfor

   stop
endif

;; Derive limits of secondary mirror fixed positions
w_start = intarr(6)
w_done  = intarr(6)
for isubscan=1, 6 do begin
   istart = where( data.subscan eq isubscan and data.scan_st eq 4, nstart)
   iend   = where( data.subscan eq isubscan and data.scan_st eq 5, nend)
   ;;if nstart eq 0 then message, "No data.scan_st=4 (start) for subscan "+strtrim(isubscan,2)+" ?!"

   ;; to cope with Juan's tuning selection at the begining
   if nstart eq 0 then begin
      if isubscan ne 1 then begin
         message, "No data.scan_st=4 (start) for subscan "+strtrim(isubscan,2)+" ?!"
      endif else begin
         istart = min( where( data.subscan eq isubscan))
         nstart = 1
      endelse
   endif

   ;;if nend   eq 0 then message, "No data.scan_st=5 ( end ) for subscan "+strtrim(isubscan,2)+" ?!"
   ;; to cope with Juan's tuning selection at the end
   if nend eq 0 then begin
      if isubscan ne 6 then begin
         message, "No data.scan_st=5 ( end ) for subscan "+strtrim(isubscan,2)+" ?!"
      endif else begin
         iend = max( where( data.subscan eq isubscan))
         nend = 1
      endelse
   endif
   
   ;; there may be multiple scan_st at the beginning of the first subscan
   w_start[isubscan-1] = istart[nstart-1]
   w_done[ isubscan-1] = iend[  nend  -1]
endfor

;; Discard data outside this sample range to avoid problems with edges and
;; common_mode estimation
w       = where( index ge min(w_start) and index le max(w_done), nsn)
data    = data[w]
index   = lindgen(nsn)
w_done  = w_done  - min(w_start)
w_start = w_start - min(w_start)

;; Prepare plot positions
my_multiplot, 2, 2, gpp, gpp1, /rev

;; Main loop
focus1    = !values.d_nan
focus2    = !values.d_nan
xbeam_1mm = !values.d_nan
ybeam_1mm = !values.d_nan
xbeam_2mm = !values.d_nan
ybeam_2mm = !values.d_nan
wind, 1, 1, /free, xs=1200, ys=1000
outplot, file=output_dir+'/plot', png=png, ps=ps, /transp
for lambda=1, 2 do begin
   if keyword_set(one_mm_only) and lambda eq 2 then goto, ciao
   if keyword_set(two_mm_only) and lambda eq 1 then goto, ciao

   w1 = where( kidpar.type eq 1 and kidpar.array eq lambda, nw1)

   ;; Check reference detector
   w_lambda = where( kidpar.array eq lambda, nw_lambda)
   ikid_ref = (where( kidpar.numdet eq numdet_ref[lambda-1], nw))[0]
   if nw eq 0 then message, "could nof find "+strtrim(numdet_ref[lambda-1],2)+" in kidpar"
 
    ;; Which kids are close or far from ikid_ref
    d      = sqrt( (kidpar.nas_x-kidpar[ikid_ref].nas_x)^2 + (kidpar.nas_y-kidpar[ikid_ref].nas_y)^2)
    w_near = where( kidpar.type eq 1 and d lt radius and kidpar.numdet ne kidpar[ikid_ref].numdet and $
                    kidpar.array eq lambda, nw_near)

    ;; Which kids are far to estimate the common mode
    w_far  = where( kidpar.type eq 1 and d ge common_mode_radius and kidpar.array eq lambda, nw_far)
    if nw_far eq 0 then begin
       message, /info, ""
       message, /info, "radius = "+strtrim(radius,2)+" arcsec is too large to find fixel for the decorrelation"
       stop
    endif

    ;; Timeline plot
    loadct, /silent, 39
    ct = [0, 40, 70, 100, 150, 190, 250]
    ind = lindgen(nsn)

    plot, ind, data.rf_didq[ikid_ref], /noerase, title='Scan '+param.day+'s'+$
          strtrim(param.scan_num,2)+", "+strtrim(param.source,2)+", Ref. Pixel "+strtrim(numdet_ref[lambda-1],2), $
          position=gpp[lambda-1,0,*], xtitle='Sample num', ytitle='Flux on ref pixel'
    for i=4, 6 do begin ;; hard code values to be sure about meaning
       w = where( data.scan_st eq i,nw)
       if nw ne 0 then begin
          oplot, [ind[w]], [data[w].rf_didq[ikid_ref]], col=ct[i], psym=8
       endif
       if nw ne 0 then for j=0, nw-1 do oplot, [1,1]*ind[w[j]], [-1,1]*1e10, col=ct[i]
    endfor
    for i=0, 5 do begin
       w = where( index ge w_start[i] and index le w_done[i], nw)
       m1 = min( data[w].rf_didq[ikid_ref])
       m2 = max( data[w].rf_didq[ikid_ref])
       loadct, /silent, 2
       oplot, ind[w], data[w].rf_didq[ikid_ref], psym=1, col=200
       loadct, /silent, 39
       plots, [ ind[w[0]], ind[w[0]], ind[w[nw-1]], ind[w[nw-1]], ind[w[0]]], $
              [ m1, m2, m2, m1, m1], col=70
    endfor
    legendastro, ['Scan Rien', 'Scan Loaded', 'Scan Started', 'Scan Done', $
                  'Subscan Started', 'Subscan Done', 'Scan Back on Track'], $
                 col=ct, line=0, /bottom, /right, thick=2
    legendastro,  "Raw Timeline", box = 0, /top, /right

    ;; Subtract common mode:
    ;; Do not use nika_pipe_cmkidfar in this code as it is now otherwise
    ;; there might be cross-calibration on the ref kid and this is touchy
    ;; with the flux variations it sees
    common_mode = dblarr(nsn)
    for i=0, nw_far-1 do begin
       fit = linfit( data.rf_didq[w_far[i]], data.rf_didq[w_far[0]])
       common_mode += 1.d0/nw_far * (fit[0] + fit[1]*data.rf_didq[w_far[i]])
    endfor

    ;; One fit per identical M2 position
    ;; The constant is degenerate with the variations of the source flux from
    ;; one position to the other, but we care only about relative variations,
    ;; so we do not use fit[0]
    w = where( (index ge w_start[0] and index le w_done[0]) or $
               (index ge w_start[5] and index le w_done[5]), nw)
    fit = linfit( common_mode[w], data[w].rf_didq[ikid_ref])
    data[w].rf_didq[ikid_ref] -= fit[1]*common_mode[w]

    w = where( (index ge w_start[1] and index le w_done[1]) or $
               (index ge w_start[2] and index le w_done[2]), nw)
    fit = linfit( common_mode[w], data[w].rf_didq[ikid_ref])
    data[w].rf_didq[ikid_ref] -= fit[1]*common_mode[w]

    w = where( (index ge w_start[3] and index le w_done[3]) or $
               (index ge w_start[4] and index le w_done[4]), nw)
    fit = linfit( common_mode[w], data[w].rf_didq[ikid_ref])
    data[w].rf_didq[ikid_ref] -= fit[1]*common_mode[w]

    ;; ;; Init snapshot parameters
    ;; xra = minmax( kidpar[w1].nas_x)
    ;; xra = xra + [-1,1]*0.2*(max(xra)-min(xra))
    ;; yra = minmax( kidpar[w1].nas_y)
    ;; yra = yra + [-1,1]*0.2*(max(yra)-min(yra))
    ;; xyra2xymaps, xra, yra, param.map.reso, xmap, ymap, nx, ny, xmin, ymin
    ;; fwhm = median( kidpar[w1].fwhm)
    ;; phi = dindgen(100)/99.*2*!dpi


    ;; Integrate fluxes
    z_pos = fooffset+focusz
    flux        = dblarr(6)
    s_flux      = dblarr(6)
    flux_near   = dblarr( nw_near, 6)
    s_flux_near = dblarr( nw_near, 6)
    ind = lindgen(nsn)
    flux_all    = dblarr( nkids, 6)
    for ipos=0, 5 do begin
       w = where( index ge w_start[ipos] and index le w_done[ipos], nw)
       
       ;; Ref kid
       flux[  ipos] = avg( data[w].rf_didq[ikid_ref])
       s_flux[ipos] = stddev( data[w].rf_didq[ikid_ref])
       if finite(s_flux[ipos]) eq 0 then s_flux[ipos] = 0.
       
       ;; Nearby kids                                                                                                              
       for j=0, nw_near-1 do begin
          flux_near[  j,ipos] = avg(      data[w].rf_didq[w_near[j]])
          s_flux_near[j,ipos] = 3*stddev( data[w].rf_didq[w_near[j]])/sqrt(nw)
          if finite(s_flux_near[j,ipos]) eq 0 then s_flux_near[j,ipos] = 0.d0
       endfor

       ;; All kids for the image
       for j=0, nkids-1 do flux_all[j,ipos] = avg( data[w].rf_didq[j])

       ;;;; Fit a gaussian on the integrated flux at kids position in Nasmyth
       ;;;; coordinates
       ;;errors = dblarr(nw1) + 1
       ;;junk = nika_gauss2dfit( flux_all[w1,ipos], kidpar[w1].nas_x, kidpar[w1].nas_y, errors, params)
       ;;fit = nika_gauss2( xmap, ymap, params)
       ;;!mamdlib.coltable=1
       ;;imview, fit, udgrade=2, xmap=xmap, ymap=ymap, xtitle='Nasmyth X', ytitle='Nasmyth Y'
       ;;loadct, /silent, 39
       ;;oplot,  kidpar[w1].nas_x, kidpar[w1].nas_y, psym=1, col=250
       ;;xyouts, kidpar[w1].nas_x, kidpar[w1].nas_y, strtrim( kidpar[w1].numdet,2), col=250, chars=0.6
       ;;legendastro, "ipos = "+strtrim(ipos,2), box=0, textcol=255
       ;;stop
    endfor

    ;; New error bar estimate : compare the values for two identical positions
    s_flux[0] = abs( flux[0]-flux[5])
    s_flux[5] = abs( flux[0]-flux[5])

    s_flux[1] = abs( flux[1]-flux[2])
    s_flux[2] = abs( flux[1]-flux[2])

    s_flux[3] = abs( flux[3]-flux[4])
    s_flux[4] = abs( flux[3]-flux[4])

    ;; ;; Which kids are used to estimate the common_mode
    ;; plot, kidpar[w1].nas_x, kidpar[w1].nas_y, psym=1, /iso, $
    ;;       xtitle='Nasmyth x [arcsec]', ytitle='Nasmyth y [arcsec]', $
    ;;       title='Kids used for common mode estimation', position=snapshot_pos[7,*], /noerase
    ;; xyouts, kidpar[w1].nas_x, kidpar[w1].nas_y, strtrim(kidpar[w1].numdet,2), chars=0.5
    ;; xyouts, kidpar[ikid_ref].nas_x, kidpar[ikid_ref].nas_y, strtrim(kidpar[ikid_ref].numdet,2), col=250, chars=0.5
    ;; oplot, kidpar[ikid_ref].nas_x + common_mode_radius*cos(phi), kidpar[ikid_ref].nas_y + common_mode_radius*sin(phi)
    ;; oplot, [kidpar[ikid_ref].nas_x], [kidpar[ikid_ref].nas_y], col=250, thick=2
    ;; oplot, kidpar[w_far].nas_x, kidpar[w_far].nas_y, psym=4, col=150, thick=2

    ;; Focus plots and fits
    ;; Ref kid
    loadct, /silent, 2
    focus_plot_fit, z_pos, flux, s_flux, z_opt, delta_z_opt, position=gpp[lambda-1,1,*], $
                    color=200, leg_txt=[strtrim(lambda,2)+"mm", "", 'Numdet '+strtrim(kidpar[ikid_ref].numdet,2)], $
                    /noerase
    loadct, /silent, 39
    if lambda eq 1 then begin
       focus1 = z_opt
       err_focus1 = delta_z_opt
    endif else begin
       focus2 = z_opt
       err_focus2 = delta_z_opt
    endelse


ciao:
endfor
outplot, /close

my_multiplot, /reset

;; Print summary
print, ""
banner, "*****************************", n=1
print, "      FOCUS results"
print, ""
print, "To be used directly in PAKO (take the value at 1mm in priority)"
print, ""
;;print, '1mm, Z = '+string( focus1, format='(F5.2)')
;;print, '2mm, Z = '+string( focus2, format='(F5.2)')
print, '(1mm) SET FOCUS '+strtrim( string( focus1, format='(F5.2)'),2)
print, '(2mm) SET FOCUS '+strtrim( string( focus2, format='(F5.2)'),2)
print, ""
banner, "*****************************", n=1


;; Get useful information for the logbook
nika_get_log_info, scan_num, day, data, log_info, kidpar=kidpar
log_info.source    = param.source
log_info.scan_type = pako_str.obs_type
if polar eq 1 then log_info.scan_type = pako_str.obs_type+"_polar"
log_info.result_name[ 0] = 'Focus_1mm'
log_info.result_value[0] = string(focus1,format='(F5.2)')
log_info.result_name[ 1] = 'Focus_2mm'
log_info.result_value[1] = string(focus2,format='(F5.2)')

test = file_test( param.imb_fits_file, /dir) ; is a directory
test2 = file_test( param.imb_fits_file)      ; file/dir exists
antexist = (test eq 0) and (test2 eq 1)
if  antexist then begin 
   a=mrdfits( param.imb_fits_file,0,hdr,/sil)
   log_info.scan_type = sxpar( hdr,'OBSTYPE',/silent)
endif

save, file=output_dir+"/log_info.save", log_info

;; Create a html page with plots from this scan
nika_logbook_sub, scan_num, day

;nika_pipe_measure_atmo, param, data, kidpar, /noplot
;save, file=output_dir+"/param.save", param

end
