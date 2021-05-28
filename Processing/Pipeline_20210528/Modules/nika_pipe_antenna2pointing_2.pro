

; Replaces the data pointing info (Az, El) with what is in the antenna imbfits
; file
; status = -1 means bad

pro nika_pipe_antenna2pointing_2, param, data, kidpar, plot=plot, flag_holes=flag_holes, status = status

status = 0 ; 0 is OK
print, 'Flag_holes = ', strtrim( keyword_set( flag_holes), 2)
nkids = n_elements( kidpar)
nsn   = n_elements(data)
index = lindgen(nsn)

junk = mrdfits( param.imb_fits_file,0,hdr,/sil)
obs_type = sxpar( hdr,'OBSTYPE',/silent)

w1 = where( kidpar.type eq 1, nw1)
;;-------------------------------------------------------------------------------------------------------
;; Deal with Lissajous scan first
;; If it's a Lissajou scan, just rely on our sinusoidal fit
if strtrim( strupcase( obs_type),2) eq "LISSAJOUS" then begin
   i_up = nsn                   ; default
   i_down = -1                  ; everything is masked
  
   ;;  Fit lissajou coordinates around the center of the scan
   i2 = long(nsn*4./5)
   i1 = i2 - nsn/2
   fit_flag = data.ofs_az*0.d0 + 1
   fit_flag[i1:i2] = 0

   ;; flag out missing mjd
   w = where( data.mjd lt 1e4, nw)
   if nw ne 0 then fit_flag[w] = 1

   nika_fit_sine, index, data.ofs_az, fit_flag, params_az, fit_az, status=status1
   if status1 lt 0 then message, "could not fit data.ofs_az"
   nika_fit_sine, index, data.ofs_el, fit_flag, params_el, fit_el, status=status2
   if status2 lt 0 then message, "Could not fit data.ofs_el"
   
   ;; ;; flag interpolated data or data where the fit is too far TBD
   ;; d = sqrt( (data.ofs_az-fit_az)^2 + (data.ofs_el-fit_el)^2)
   ;; w = where( d gt 2, nw)
   ;; if nw ne 0 then data[w].flag = 33 ; random value for now

   ;; Check fit quality on valid data
   w = where( data.flag[w1[0]] eq 0, nw)
   if nw eq 0 then begin
      message, /info, 'No valid sample ?!'
      status = -1
      return
   endif else begin
      rms_az = stddev( fit_az[w]-data[w].ofs_az)
      rms_el = stddev( fit_el[w]-data[w].ofs_el)
      ;; undo bad scan flagging in nika_pipe_flag_scanst unless /flag_holes
      ww = nika_pipe_wflag( data.flag[w1[0]], 18, nflag=nflag)
      if nflag ne 0 then begin
         if not keyword_set(flag_holes) then begin
            if (rms_az lt param.ptg_quality_threshold) and (rms_el lt param.ptg_quality_threshold) $
            then data[ww].flag -= 2L^18
         endif
         data[ww].el      = interpol( data[w].el,      data[w].a_t_utc, data[ww].a_t_utc)
         data[ww].paral   = interpol( data[w].paral,   data[w].a_t_utc, data[ww].a_t_utc)
         data[ww].subscan = interpol( data[w].subscan, data[w].a_t_utc, data[ww].a_t_utc)
         data[ww].scan    = interpol( data[w].scan,    data[w].a_t_utc, data[ww].a_t_utc)
      endif
   endelse

   if keyword_set(plot) then begin
      w = where( data.flag[0] eq 0, nw)
      if nw eq 0 then message, "No valid sample ?!"
      wind, 1, 1, /free, /large
      !p.multi=[0,1,2]
      plot,  data.a_t_utc, data.ofs_az, /xs, title='Az'
      oplot, data.a_t_utc, data.ofs_az, thick=2
      oplot, data.a_t_utc, fit_az, col=70
      oplot, data[w].a_t_utc, fit_az[w], col=250
      
      plot,  data.a_t_utc, data.ofs_el, /xs, title='El'
      oplot, data.a_t_utc, data.ofs_el, thick=2
      oplot, data.a_t_utc, fit_el, col=70
      oplot, data[w].a_t_utc, fit_el[w], col=250
      !p.multi=0
   endif

   ;; Overwrite the pointing with the fit: when data are good, the difference is
   ;; less than 0.5 arcsec, when the difference is large, the data are either
   ;; missing or likely to be drifting towards bad values.
   data.ofs_az = fit_az
   data.ofs_el = fit_el


endif else begin

   ;; -------------------------------------------------------------------------------------------------------
   ;; OTF scans

   ;; Init arrays and take margin on their size
   nmax = 60000L ; max sample length of a scan
   longoff   = dblarr( nmax)
   scan      = dblarr( nmax)
   subscan   = dblarr( nmax)
   elevation = dblarr( nmax)
   azimuth   = dblarr( nmax)
   latoff    = longoff
   mjdarr    = longoff

   ;; Read the imbfits file: Loop on the extensions
   iext = 0
   ndeb = 0
   nend = 0
   ss_val = 1
   junk = mrdfits( param.imb_fits_file,0,hdr,/sil)
   obs_type = sxpar( hdr,'OBSTYPE',/silent)     
   repeat begin
      readin = mrdfits(param.imb_fits_file, iext, hdr, status=status3, /silent)
      extna = sxpar( hdr, 'EXTNAME')
      if strtrim( strupcase(extna), 2) eq strupcase('IMBF-ANTENNA') and $
         status3 ge 0 then begin
         nread = n_elements( readin)
         nend  = ndeb+nread-1
         longoff[   ndeb:nend] = readin.longoff
         latoff[    ndeb:nend] = readin.latoff
         mjdarr[    ndeb:nend] = readin.mjd
         scan[      ndeb:nend] = sxpar( hdr, 'SCANNUM')
         subscan[   ndeb:nend] = ss_val
         azimuth[   ndeb:nend] = readin.cazimuth  ; [rad] Commanded Azimuth
         elevation[ ndeb:nend] = readin.celevatio
         ndeb = nend+1
         ss_val +=  1
      endif
      iext = iext + 1
   endrep until status3 lt 0
   if nend le 0 then message, "could not read the imbfits file."
   
   ;; Discard useless trailing samples from initialization margin
   longoff   = longoff[0:nend]*!radeg*3600
   latoff    = latoff[ 0:nend]*!radeg*3600
   scan      = scan[0:nend]
   subscan   = subscan[0:nend]
   elevation = elevation[0:nend]
   azimuth   = azimuth[0:nend]
   mjdarr    = (mjdarr[0:nend]-long(mjdarr[0]))*86400D0 ; modify to have seconds

   ;; mjdarr seems to go back and forth on the edges of subscans
   ;; here's a fix by Xavier:
   nsub = max( subscan)
   badbyte = bytarr( nend+1)
   for isub = 1, nsub-1 do begin
      u = where( subscan eq isub, nsamp)
      if nsamp ne 0 then badbyte[u] = mjdarr[u] gt mjdarr[u[nsamp-1]+1]
   endfor
   goodindex = where( badbyte eq 0, ngood)
   if ngood ne 0 then begin
      mjdarr    = mjdarr[    goodindex]
      longoff   = longoff[   goodindex]
      latoff    = latoff[    goodindex]
      scan      = scan[      goodindex]
      subscan   = subscan[   goodindex]
      elevation = elevation[ goodindex]
      azimuth   = azimuth[   goodindex]
   endif

   ;; ;; Check multiplication or division by cos(elevation)
   ;; xra = minmax(data.ofs_az) + [-1,1]*0.3*( max(data.ofs_az)-min(data.ofs_az))
   ;; yra = minmax(data.ofs_el) + [-1,1]*0.3*( max(data.ofs_el)-min(data.ofs_el))
   ;; wind, 1, 1, /free, /large
   ;; outplot, file='azel_'+strtrim( param.day,2)+"s"+strtrim( param.scan_num,2), /png
   ;; plot, data.ofs_az, data.ofs_el, /iso, xra=xra, yra=yra, /xs, $
   ;;       title=strtrim( param.day,2)+"s"+strtrim( param.scan_num,2)
   ;; oplot, longoff, latoff, col=70
   ;; oplot, data.ofs_az/cos(data.el), data.ofs_el, col=250
   ;; legendastro, ['ofs_az', 'longoff (imbfits)', 'ofs_az/cos(elev)'], $
   ;;              col=[0,70,250], line=0, box=0
   ;; outplot, /close

   
   ;; estimating parallactic angle using Xavier's routine
   ;; (TO BE CONFIRMED: should be more precise that way than 
   ;; estimating from interpolated elevation and azimuth)
   ;;----------------------------------------------------------------------------
   ;; Final computation of correct parallactic angle
   ;; Must be checked on a map but compatible with raw data values within 1/2 deg.
   paral = parallactic_angle( azimuth, elevation)

   ;; Perform the pointing interpolation
   data.ofs_az  =       interpol( longoff,   mjdarr, data.a_t_utc)
   data.ofs_el  =       interpol( latoff,    mjdarr, data.a_t_utc)
   data.el      =       interpol( elevation, mjdarr, data.a_t_utc)
   data.az      =       interpol( azimuth  , mjdarr, data.a_t_utc)
   data.subscan = long( interpol( subscan,   mjdarr, data.a_t_utc))       
   data.scan    = long( interpol( scan,      mjdarr, data.a_t_utc)) 
   data.paral   =       interpol( paral,     mjdarr, data.a_t_utc)

   ;; undo bad scan flagging in nika_pipe_flag_scanst unless /flag_holes
   w = nika_pipe_wflag( data.flag[w1[0]], 18, nflag=nflag)
   if not keyword_set(flag_holes) then begin
      if nflag ne 0 then data[w].flag -= 2L^18
   endif

   ;; Flag out remaining holes (if any) by looking at mjdarr variations
   dmjd = deriv(mjdarr)
   med  = median( dmjd)
   w    = where( dmjd lt med/10. or dmjd gt 5*med, nw)
   if nw ne 0 then begin
      mjd_flag = mjdarr*0.d0
      mjd_flag[w] = 1
      lkv = mjd_flag + shift( mjd_flag, 1) ; last know value
      holes = double( lkv ne 0)
      ;; Enlarge a bit to take margin
      nk = 10
      holes = convol( holes, dblarr(nk)+1./nk)
      int_holes = double( interpol( holes, mjdarr, data.a_t_utc) gt 0)
      for ikid=0, nkids-1 do data.flag[ikid] += int_holes*2L^18
   endif

   if keyword_set(plot) then begin
      w = where( data.flag[0] eq 0, nw)
      if nw eq 0 then message, "No valid sample ?!"
      wind, 1, 1, /free, /large
      !p.multi=[0,1,2]
      plot,  data.a_t_utc, data.ofs_az, /xs, title='Az'
      oplot, data.a_t_utc, data.ofs_az, thick=2
      oplot, data[w].a_t_utc, data[w].ofs_az, col=250, psym=1
      
      plot,  data.a_t_utc, data.ofs_el, /xs, title='El'
      oplot, data.a_t_utc, data.ofs_el, thick=2
      oplot, data[w].a_t_utc, data[w].ofs_el, col=250, psym=1
      !p.multi=0
   endif
endelse


end
