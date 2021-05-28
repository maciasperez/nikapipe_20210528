function nk_atmb_count_param, info,  param, iarray
                                ; For array 1, 2, 3: give the number of parameters used
                                ; in the atmb decorrelation so that we
                                ; can correct the noise and toi in
                                ; nk_w8 and nk_average_scans routines

  nsub = long(info.nsubscans) ; number of useful subscans, subscans 0 and 1 have been removed and are not counted
 atmb_coeff = 1D0 ; Default
  if param.atmb_defilter ne 0  then begin ; Do not increase signal and noise for the final iteration
     if param.imcm_iter ge param.atmb_defilter then $
        atmb_coeff = 0
  endif
  
; Setup nharm if not defined
  if param.atmb_filt_time1mm gt 0 and param.nharm_subscan1mm eq 0 then begin
     subscan_time = info.subscan_arcsec / info.median_scan_speed
     param.nharm_subscan1mm = ((long( subscan_time / param.atmb_filt_time1mm )> 0) < 10)
     param.nharm_subscan2mm = ((long( subscan_time / param.atmb_filt_time2mm )> 0) < 10)
     param.atmb_nsubscan = long( param.atmb_filt_fulltime/ subscan_time) > 2
     if param.atmb_nsubscan gt info.nsubscans then param.atmb_nsubscan = 0
  endif

  if iarray eq 2 then begin
     nharm = param.nharm_subscan2mm
     npoly = param.polynom_subscan2mm
  endif else begin
     nharm = param.nharm_subscan1mm
     npoly = param.polynom_subscan1mm
  endelse

  chunk_size = long(param.atmb_nsubscan)
; see nk_decor_atmb_per_array
  if chunk_size gt 0 then $
     nchunk = (((nsub-1)/ chunk_size)+1) $
  else nchunk = 1

  if nharm gt 0 then $
                                ; 4 atmospheric templates, 5 electronic templates, per chunk
                                ; take it back to one subscan: 2 sine
                                ; cosine and a constant term
     np = ((4. + 5.) * nchunk) / nsub + atmb_coeff * (2*nharm + 1) else $
     np = ((4. + 5.) * nchunk) / nsub + atmb_coeff * (npoly + 1)

  return, np
end

  
