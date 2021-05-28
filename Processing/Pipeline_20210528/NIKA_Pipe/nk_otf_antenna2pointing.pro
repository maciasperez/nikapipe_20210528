

;+
;
; SOFTWARE: Real time analysis: derives telescope pointing offsets
;
; NAME: 
; nk_otf_antenna2pointing
;
; CATEGORY:
;
; CALLING SEQUENCE:
; 
; PURPOSE: 
;        Replace missing pointing data by IMBfits pointing data when available
; 
; INPUT: 
;      - param, info, data, kidpar
; 
; OUTPUT: 
; 
; KEYWORDS:
;       - flag_holes: if set, missing data will remain flagged rather than being
;         revalidated for projection.
;       - plot: shows a few plots
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - nika_pipe_antenna2pointing: Creation by Laurence Perotto (LPSC)
;        - nika_pipe_antenna2pointing_2 : clean up by N. Ponthieu
;        - June 12th, 2014: Ported to the new pipeline format, not checked yet. N. Ponthieu
;-
;================================================================================================

pro nk_otf_antenna2pointing, param, info, data, kidpar, int_holes, plot=plot

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_otf_antenna2pointing, param, data, kidpar, plot=plot"
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then $
      message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

nkids = n_elements( kidpar)
nsn   = n_elements(data)
index = lindgen(nsn)

w1 = where( kidpar.type eq 1, nw1)

;if strtrim( strupcase( info.obs_type),2) eq 'ONTHEFLYMAP' then begin
; FXD: change to add Pointing and Lissajous
if strtrim( strupcase( info.obs_type),2) eq 'ONTHEFLYMAP' or $
   strtrim( strupcase( info.obs_type),2) eq 'LISSAJOUS' or $
   strtrim( strupcase( info.obs_type),2) eq 'POINTING' then begin

   ;; Init arrays and take margin on their size
   nmax = 60000L ; max sample length of a scan
   longoff   = dblarr( nmax)
   scan      = dblarr( nmax)
   subscan   = dblarr( nmax)
   elevation = dblarr( nmax)
   azimuth   = dblarr( nmax)
   latoff    = longoff
   mjdarr    = longoff
;   tracking_az = longoff*0.d0
;   tracking_el = longoff*0.d0

   ;; Read the imbfits file: Loop on the extensions
   iext = 0
   ndeb = 0
   nend = 0
   ss_val = 1
   repeat begin
      junk = mrdfits( param.file_imb_fits,0,hdr,/sil)
      readin = mrdfits(param.file_imb_fits, iext, hdr, status=status, /silent)
      extna = sxpar( hdr, 'EXTNAME')
      if strtrim( strupcase(extna), 2) eq strupcase('IMBF-ANTENNA') then begin
         nread = n_elements( readin)
         nend  = ndeb+nread-1
         longoff[   ndeb:nend] = readin.longoff
         latoff[    ndeb:nend] = readin.latoff
         mjdarr[    ndeb:nend] = readin.mjd
         scan[      ndeb:nend] = sxpar( hdr, 'SCANNUM')
         subscan[   ndeb:nend] = ss_val
         azimuth[   ndeb:nend] = readin.cazimuth  ; [rad] Commanded Azimuth
         elevation[ ndeb:nend] = readin.celevatio
;         tracking_az[ ndeb:nend] = reform( readin.tracking_az)
;         tracking_el[ ndeb:nend] = reform( readin.tracking_el)
         ndeb = nend+1
         ss_val +=  1
      endif
      iext = iext + 1
   endrep until status lt 0
   if nend le 0 then message, "could not read the imbfits file."
   
   ;; Discard useless trailing samples from initialization margin
   longoff     = longoff[0:nend]*!radeg*3600
   latoff      = latoff[ 0:nend]*!radeg*3600
;   tracking_az = tracking_az[ 0:nend]*!radeg*3600
;   tracking_el = tracking_el[ 0:nend]*!radeg*3600
   scan      = scan[     0:nend]
   subscan   = subscan[  0:nend]
   elevation = elevation[0:nend]
   azimuth   = azimuth[0:nend]
   mjdarr    = (mjdarr[0:nend]-long(mjdarr[0]))*86400D0 ; modify to have seconds
   if max(mjdarr) gt 86400 then begin
;      stop
;      message,/info, "The scan started before midnight and ended after midnight, fix me."
;      info.status = 1
;      return
      daychange = where( data.a_t_utc-shift( data.a_t_utc, 1) lt 0,  nd)
      daycorr = dblarr(nsn)
      daycorr[ daychange[0]:*] = 86400
      utc = data.a_t_utc+daycorr
      devi = abs(utc-shift(utc, 1))
      mdevi = median(devi)
      gd = where( devi ge mdevi*0.3 and devi lt mdevi*3, ngd)
      data.a_t_utc = interpol(utc[gd], gd, lindgen( nsn))
   endif
   ;; mjdarr seems to go back and forth on the edges of subscans
   ;; here's a fix by Xavier:
   nsub = max( subscan)
   badbyte = bytarr( nend+1)
   for isub = 1, nsub-1 do begin
      u = where( subscan eq isub, nsamp)
      if nsamp ne 0 then badbyte[u] = mjdarr[u] gt mjdarr[u[nsamp-1]+1]
   endfor
   goodindex = where( badbyte eq 0, ngood)

   mjdtest = mjdarr
   if ngood ne 0 then begin
      mjdarr    = mjdarr[    goodindex]
      longoff   = longoff[   goodindex]
      latoff    = latoff[    goodindex]
;      tracking_az = tracking_az[   goodindex]
;      tracking_el = tracking_el[   goodindex]
      
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


;;    ;; LP modif
;;    ;; flag aberrant values at the extrema of data.a_t_utc
;;    wa = where(data.a_t_utc lt 0.01*median(data.a_t_utc), co)
;;    if co gt 0 then begin
;; ;;;      int_a = dblarr(nsn)
;; ;;;      int_a[wa] = 1d0
;; ;;;      for ikid=0, nkids-1 do data.flag[ikid] += int_a*2L^9 
;;       data[wa].flag += 2L^9
;;    endif

   ;; NP + AA, June 9th, 2017
   ;; Correct for abherent values of t_utc rather than just flag them,
   ;; otherwise the pointing is not well interpolated
   nsn = n_elements(data)
   index = dindgen(nsn)
   junk = data.a_t_utc - shift( data.a_t_utc, 1)
   whole = where( abs(junk) gt 2*median(junk), nwhole, compl=wkeep)
;   plot, index, data.a_t_utc, /xs, /ys ;, xra=[6800,7200]
;   oplot, index[whole], data[whole].a_t_utc, psym=1, col=70
   if nwhole ne 0 then begin
      fit = linfit( index[wkeep], data[wkeep].a_t_utc)
;      oplot, index[whole], fit[0] + fit[1]*index[whole], col=150
      data[whole].a_t_utc = fit[0] + fit[1]*index[whole]
   endif
;   oplot, index, data.a_t_utc, col=250
   
   ;; Perform the pointing interpolation
;; message, /info, "fix me:"
;; speed_b4 = sqrt( deriv(data.ofs_az)^2 + deriv(data.ofs_el)^2)*!nika.f_sampling
   data.ofs_az  =       interpol( longoff,   mjdarr, data.a_t_utc)
   data.ofs_el  =       interpol( latoff,    mjdarr, data.a_t_utc)

;; message, /info, "fix me:"
;; speed = sqrt( deriv(data.ofs_az)^2 + deriv(data.ofs_el)^2)*!nika.f_sampling
;; wind, 1, 1, /f
;; yra = minmax([speed_b4,speed])
;; yra = [0,100]
;; plot, speed_b4, /xs, yra=yra, /ys
;; oplot, speed, col=250

   data.el      =       interpol( elevation, mjdarr, data.a_t_utc)
   data.az      =       interpol( azimuth  , mjdarr, data.a_t_utc)
   data.scan    = long( interpol( scan,      mjdarr, data.a_t_utc)) 
   data.paral   =       interpol( paral,     mjdarr, data.a_t_utc)
   data.subscan = long( interpol( subscan,   mjdarr, data.a_t_utc))       
   ;; Protect from EXTRapolation, NP+FXD, Sept. 18th, 2015
   w = where( data.a_t_utc lt min(mjdarr), nw)
   if nw ne 0 then data[w].subscan = -1
   w = where( data.a_t_utc gt max(mjdarr), nw)
   if nw ne 0 then data[w].subscan = -1

   ;; undo bad scan flagging in nika_pipe_flag_scanst unless /flag_holes
   ;; w = nika_pipe_wflag( data.flag[w1[0]], 9, nflag=nflag)
   w = nk_where_flag( data.flag[w1[0]], 9, nflag=nflag)
   
   ;; LP test
   w_before = where( data.flag[w1[0]] eq 0, nw)
   
   ;; LP modif
   ;;if not keyword_set(flag_holes) then begin
   if param.flag_holes lt 1  then begin
      if nflag ne 0 then data[w].flag -= 2L^9
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
;;;      for ikid=0, nkids-1 do data.flag[ikid] += int_holes*2L^9
      w_h = where(int_holes gt 0, c_h)
      if c_h gt 0 then data[w_h].flag += 2L^9
;;;
   endif else begin
      ;; Added NP, Sept. 23rd
      int_holes = -1
   endelse

;;    ;;if param.do_plot ne 0 then begin
;;    if keyword_set(plot) then begin
;;       w = where( data.flag[w1[0]] eq 0, nw)
;;       if nw eq 0 then message, "No valid sample ?!"
;;       wind, 1, 1, /free, /large, iconic = param.iconic
;;       !p.multi=[0,1,2]
;;       plot,  data.a_t_utc, data.ofs_az, $
;;              xr=[min(data[w].a_t_utc), $
;;                  max(data[w].a_t_utc)], /xs, title='OFS_Az', $
;;              xtitle='UT'
;;       oplot, data.a_t_utc, data.ofs_az, thick=2 
;;       oplot, data[w_before].a_t_utc, data[w_before].ofs_az, col=150, psym=3
;;       oplot, data[w].a_t_utc, data[w].ofs_az, col=250, psym=3
;;       legendastro, ['Raw pointing', 'Before', 'After'], $
;;                    col=[!p.color, 150, 250], textcol=[!p.color, 150, 250], line=0
;;       
;;       plot,  data.a_t_utc, data.ofs_el, $
;;              xr=[min(data[w].a_t_utc), max(data[w].a_t_utc)], $
;;              /xs, title='OFS El', xtitle='UT'
;;       oplot, data.a_t_utc, data.ofs_el, thick=2
;;       oplot, data[w_before].a_t_utc, data[w_before].ofs_el, col=150, psym=3
;;       if nw ne 0 then oplot, [data[w].a_t_utc], [data[w].ofs_el], col=250, psym=3
;; ;      oplot, data.a_t_utc, int_holes*100., col=50, psym=2
;;       !p.multi=0
;;       ;;stop
;;    endif

endif



end
