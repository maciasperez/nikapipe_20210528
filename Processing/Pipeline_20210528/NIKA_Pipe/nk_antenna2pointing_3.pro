

;+
;
; SOFTWARE: Real time analysis: derives telescope pointing offsets
;
; NAME:
; nk_antenna2pointing_3
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

;pro nk_otf_antenna2pointing, param, info, data, kidpar
pro nk_antenna2pointing_3, param, info, data, kidpar

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nika_pipe_otf_antenna2pointing, param, data, kidpar, plot=plot, flag_holes=flag_holes"
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

nkids = n_elements( kidpar)
nsn   = n_elements(data)
index = lindgen(nsn)

w1 = where( kidpar.type eq 1, nw1)
;;-------------------------------------------------------------------------------------------------------
;; Deal with Lissajous scan first
;; If it's a Lissajou scan, just rely on our sinusoidal fit
if strtrim( strupcase( info.obs_type),2) eq "LISSAJOUS" then begin

   ;; valid samples
   w9 = nika_pipe_wflag( data.flag[0], 9, nflag=nflag, compl=w9compl, ncompl=nw9compl)
   if nw9compl eq 0 then begin
      nk_error, info, "No valid sample ?!"
      if param.silent ne 0 then message, /info, info.error
      return
   endif else begin
      if nflag ne 0 then begin
         data[w9].el      = interpol( data[w9compl].el,      data[w9compl].a_t_utc, data[w9].a_t_utc)
         data[w9].paral   = interpol( data[w9compl].paral,   data[w9compl].a_t_utc, data[w9].a_t_utc)
         data[w9].subscan = interpol( data[w9compl].subscan, data[w9compl].a_t_utc, data[w9].a_t_utc)
         data[w9].scan    = interpol( data[w9compl].scan,    data[w9compl].a_t_utc, data[w9].a_t_utc)
      endif
   endelse

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
         ndeb = nend+1
         ss_val +=  1
      endif
      iext = iext + 1
   endrep until status lt 0
   if nend le 0 then begin
      nk_error, info, "could not read the imbfits file."
      return
   endif
   
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
   w = nika_pipe_wflag( data.flag[w1[0]], 9, nflag=nflag)
   if not keyword_set(flag_holes) then begin
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
      for ikid=0, nkids-1 do data.flag[ikid] += int_holes*2L^9
   endif

   if param.do_plot ne 0 then begin
      w = where( data.flag[0] eq 0, nw)
      if nw eq 0 then begin
         message, /info, "No valid sample ?!"
         stop
      endif
      wind, 1, 1, /free, /large, iconic = param.iconic
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
