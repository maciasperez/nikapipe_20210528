pro nk_decor_atmb_per_array, param, info, kidparext, toiext, flagext, $
                             off_sourceext, elevationext, $
                             toi_outext, out_tempext, $
                             snr_toi=snr_toiext, subscan = subscanext, $
                             subtoi = subtoiext
  
; Split in a given number of subscans
                                ; If number of harmonics is too high,
                                ; the CPU is terrible. Inverting a
                                ; matrix costs N^3 where N is
                                ; (2nharm+1)Nsub
; FXD May 2020, one atm per array, box and subbands are studied.
;  stop
  ;; if param.atmb_defilter ne 0 then begin
  ;; ;; if param.atmb_defilter ne 0 and $
  ;; ;;    param.imcm_iter ge param.atmb_defilter then begin
  ;;    message, /info, 'Saving now'
  ;;    save, file = '/home/desert/temp/N2Rall/data'+info.scan+'.save', $
  ;;          param, info, kidparext, toiext, flagext, $
  ;;          off_sourceext, elevationext, subscanext, snr_toiext,subtoiext
  ;;    stop, 'Saved'
  ;; endif
  if param.cpu_time then param.cpu_t0 = systime(0, /sec)
  if param.atmb_filt_time1mm gt 0 then begin
     Np = nk_atmb_count_param( info,  param, 1)          ; in order to set up nharm, etc...
     subscan_time = info.subscan_arcsec / info.median_scan_speed
     message, /info, 'Modifying nharm and atmb_nsubscan'
     print, 'tim1,tim2= ', param.atmb_filt_time1mm, param.atmb_filt_time2mm
     print, 'subscan_time, nharm1, nharm2= ', $
            subscan_time, param.nharm_subscan1mm, param.nharm_subscan2mm
     print, 'nsubscan, atmb_nsubscan= ', info.nsubscans, param.atmb_nsubscan
  endif
  
  nsn = n_elements( toiext[0,*])
  nkids = n_elements(kidparext)
  toi_outext  = dblarr(nkids,nsn)
  out_tempext = dblarr(nkids,nsn)
  subscan_min = long( min( subscanext))
  subscan_max = long( max( subscanext))
  nsubscans = subscan_max - subscan_min + 1 
; It seems that sometimes the last subscan is a lot shorter
; Dump it if it is the case
  nsub = subscan_max+1
  subscan_len = lonarr( nsub)
  for isub = subscan_min, subscan_max do $
     subscan_len[ isub] =total( subscanext eq isub)

  if param.flag_n_seconds_subscan_start ne 0 then $
     npts_flag = round( param.flag_n_seconds_subscan_start*!nika.f_sampling) $
  else npts_flag = 0.
  flsub = 1.5*!nika.f_sampling+npts_flag ; the flagged beginning of subscan
  badsub = where( (subscan_len-flsub) lt $
                  (median( subscan_len)-flsub)*2./3. and $
                  lindgen(nsub) ge 2, nbadsub)
; above or = 2, to have normal subscans

; Do something if it is the final subscan (too complicated otherwise)
  nwsubscan = 0                 ; default
  if nbadsub gt 0 then begin
     message, /info, 'Some subscans are short '+ info.scan
     if param.silent eq 0 then $
        print, 'Subscans ', strtrim( badsub, 2), $
               ' will be removed (if last one = '+ $
               strtrim( subscan_max, 2)+ '), with length of '+ $
               strtrim( subscan_len[ badsub])+' samples'
     if badsub[ nbadsub-1] eq subscan_max then begin
        wsubscan = where( subscanext eq subscan_max, nwsubscan)
        if nwsubscan ne 0 then flagext[*, wsubscan] = 1
        nsubscans = nsubscans-1
     endif
  endif

  chunk_size = long( param.atmb_nsubscan)
  if chunk_size gt 0 then begin
     nchunk = (((nsubscans-1)/ chunk_size)+1) ; number of chunks being processed (a chunk is a number of subscans done simultaneously)
     iminch = subscan_min+indgen( nchunk) * chunk_size ; Beginning of chunk in subscan number
     imaxch = (iminch+ chunk_size-1) < subscan_max
; Here are the indices (sligthly extended) for the processing
     iminchfull = (iminch < (imaxch - (chunk_size-1))) > subscan_min ; a chunk needs to be of atmb_nsubscan length
     imaxchfull = imaxch
  endif else begin
     nchunk = 1                 ; one chunk
     iminch = subscan_min                
     imaxch = subscan_min+ nsubscans-1
     iminchfull = iminch
     imaxchfull = imaxch
  endelse
  kidout = kidparext            ; output kidpar for the end
  kidtype = lonarr( nkids, nchunk)
                                ; loop on chunks
  for ichunk = 0, nchunk-1 do begin
     imin = iminch[ ichunk]
     imax = imaxch[ ichunk]
     imif = iminchfull[ ichunk]
     imaf = imaxchfull[ ichunk]
     ;;;print, imin, imax, imif, imaf
     samplesf = where( subscanext ge imif and subscanext le imaf, nsamplef)
     if nsamplef eq 0 then message, strtrim( nsamplef, 2), ' f should not be 0'
     subscan = subscanext[samplesf]
     samples = where( subscanext ge imin and subscanext le imax, nsample)
     ind_toi = where( subscan ge imin and subscan le imax, nind_toi)
     if nsample eq 0 then message, strtrim( nsample, 2), ' should not be 0'
     toi = toiext[ *, samplesf] ; all kids
     flag = flagext[*, samplesf]
     off_source = off_sourceext[*, samplesf]
     elevation = elevationext[samplesf]
     if defined( snr_toiext) then snr_toi = snr_toiext[*, samplesf]
     if defined( subtoiext) then subtoi = subtoiext[*, samplesf]
     kidloc = kidparext         ; dump place to avoid messing up kidpar
     paramloc = param
     infoloc = info
     message, /info, string( strtrim( ichunk, 2),  ' th chunk up to ', strtrim( nchunk-1, 2), ', scan:   ', param.scan)
     nk_decor_atmb_per_array_sub, paramloc, infoloc, kidloc, toi, flag, $
                                  off_source, elevation, $
                                  toi_out, out_temp, $
                                  snr_toi=snr_toi, subscan = subscan, $
                                  subtoi = subtoi
                                ;Put everything in the output now for
                                ;samples only
     if nind_toi ne 0 then begin
        toiext[*, samples] = toi[*, ind_toi]
        flagext[*, samples] = flag[*, ind_toi]
        toi_outext[*, samples] = toi_out[*, ind_toi]
        out_tempext[*, samples] = out_temp[*, ind_toi]
     endif 
     kidtype[*, ichunk] = kidloc.type ; save the type for each iteration
     
  endfor                                 ; loop on chunks
  if nchunk gt 1 then kidparext.type = min(kidtype, dim = 2) $ ; keep the min of the new types
                                       else kidparext.type = kidtype
  if param.cpu_time then nk_show_cpu_time, param
  return
end
