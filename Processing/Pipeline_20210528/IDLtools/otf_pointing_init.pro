pro otf_pointing_init, nss, x_info, y_info, x_allinfo, y_allinfo, backward=backward, nsample=nsample

; initialize the param structures per subscan (x/y_allinfo) from the
; averaged params (x/y_info)
; nss = number of subscans  

; the param structure is filled from the beginning to the end of the
; scan unless the keyword "backward" is set 

; the scan is assumed to begin (or to end in \backward) at the
; beginning of a subscan 
;

  med_length = round((x_info.avg_ssl_ok+x_info.avg_isl_ok-1))
  
  x_med_ssl = round(x_info.avg_ssl_ok)
  x_med_isl = round(x_info.avg_isl_ok)
  x_med_amp = x_info.amplitude/2.
  
  x_ss_length = replicate(x_med_ssl,nss)
  x_is_length = replicate(x_med_isl,nss)
  x_amplitude = replicate(x_med_amp,nss)
  x_beg_index = lonarr(nss)
  x_end_index = lonarr(nss)
  if not(keyword_set(backward)) then begin  
     ;x_is_length[nss-1] = 0 
     x_beg_index = lindgen(nss)*(med_length-1)
     x_end_index = x_beg_index+x_ss_length-1
     i_pair = 2.*lindgen(ceil(nss/2.))
     x_amplitude[i_pair] = -1.* x_amplitude[i_pair]
  endif else begin
     last_end_index = (nss*med_length-x_med_isl-1)
     if keyword_set(nsample) then last_end_index = nsample-x_med_isl-1
     x_end_index = reverse(last_end_index - lindgen(nss)*(med_length-1))
     ;; test against negative index
     wneg = where(x_end_index lt 0, nneg, compl=wpos)
     if (nneg gt 0) then begin 
        ;; erreur d'estimation du nb de subscans
        x_end_index = x_end_index[wpos]
        nss = n_elements(x_end_index)
        x_ss_length = replicate(x_med_ssl,nss)
        x_is_length = replicate(x_med_isl,nss)
        x_amplitude = replicate(x_med_amp,nss)
        x_beg_index = lonarr(nss)
     endif
     x_beg_index = x_end_index-(x_ss_length-1)
     ;; test against negative index [non-necessary: treated afterward]
     ;;wneg = where(x_beg_index lt 0, nneg)
     ;;if (nneg gt 0) then begin
     ;;   x_beg_index[wneg] = 0
     ;;   x_ss_length[wneg] = x_end_index[wneg] - x_beg_index[wneg] +1
     ;;endif
     if nss ge 2 then begin
        ;i_sur_2 =  2.*lindgen(nss/2.)+ceil(nss/2.)-floor(nss/2.)
        ;x_amplitude[i_sur_2] = -1.* x_amplitude[i_sur_2]
        i_pair = 2.*lindgen(ceil(nss/2.))
        x_amplitude[i_pair] = -1.* x_amplitude[i_pair]
     endif
  endelse
  ;; the most important info is beg_index: flagging measured beg_index
  ;; (not to change them afterwards) 
  x_beg_index_flag = lonarr(nss)+1L
  x_end_index_flag = lonarr(nss)+1L
  

  
  
  y_med_ssl = round(y_info.avg_ssl_ok)
  y_med_isl = round(y_info.avg_isl_ok)
  y_ampli0 = y_info.amplitude
  y_med_step = y_info.delta
  
  y_ss_length = replicate(y_med_ssl,nss)
  y_is_length = replicate(y_med_isl,nss)
  y_amplitude = fltarr(nss)
  y_beg_index = lonarr(nss)
  y_end_index = lonarr(nss)
  if not(keyword_set(backward)) then begin  
     ;y_is_length[nss-1] = 0 
     y_beg_index = lindgen(nss)*(med_length-1)
     y_end_index = y_beg_index+y_ss_length-1
     y_amplitude = y_ampli0+lindgen(nss)*y_med_step
  endif else begin
     last_end_index = (nss*med_length-y_med_isl-1)
     if keyword_set(nsample) then last_end_index = nsample-y_med_isl-1
     y_end_index = reverse(last_end_index - lindgen(nss)*(med_length-1))
     y_beg_index = y_end_index-(y_ss_length-1)
     ;; test against negative index [non-necessary: treated afterward]
     ;;wneg = where(y_beg_index lt 0, nneg)
     ;;if (nneg gt 0) then begin
     ;;   y_beg_index[wneg] = 0
     ;;   y_ss_length[wneg] = y_end_index[wneg] - y_beg_index[wneg] +1
     ;;endif
     y_amplitude = reverse(y_ampli0 - (lindgen(nss)+1)*y_med_step) 
  endelse
  ;; the most important info is beg_index: flagging measured beg_index
  ;; (not to change them afterwards) 
  y_beg_index_flag = lonarr(nss)+1L
  
  
  x_allinfo = replicate({ss_length:0., is_length:0., beg_index:0L, end_index:0L, beg_index_flag:0, end_index_flag:0, amplitude:0.},nss)
  x_allinfo.ss_length = x_ss_length 
  x_allinfo.is_length = x_is_length
  x_allinfo.beg_index = x_beg_index
  x_allinfo.end_index = x_end_index
  x_allinfo.amplitude = x_amplitude
  x_allinfo.beg_index_flag = x_beg_index_flag
  x_allinfo.end_index_flag = x_end_index_flag
  
  y_allinfo = replicate({ss_length:0., is_length:0., beg_index:0L, end_index:0L, beg_index_flag:0, amplitude:0.},nss)
  y_allinfo.ss_length = y_ss_length 
  y_allinfo.is_length = y_is_length
  y_allinfo.beg_index = y_beg_index
  y_allinfo.end_index = y_end_index
  y_allinfo.amplitude = y_amplitude
  y_allinfo.beg_index_flag = y_beg_index_flag


end
