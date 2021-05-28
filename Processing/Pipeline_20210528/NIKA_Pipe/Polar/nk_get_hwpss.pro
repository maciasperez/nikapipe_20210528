;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_get_hwpss.pro
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         nk_get_hwpss, param, info, data, kidpar, hwpss
; 
; PURPOSE: 
;        Fits the HWP synchronous signal
; 
; INPUT: 
;        - param, info, data, kidpar
; 
; OUTPUT: 
;        - hwpss
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Feb. 19th, 2019 NP: improved version of
;          nk_deal_with_hwp_template that forced to do things twice
;          when in iterative mode

pro nk_get_hwpss, param, info, data, kidpar, hwpss, plot=plot, snr_toi=snr_toi
;-

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   dl_unix, 'nk_get_hwpss'
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

if param.lab_polar eq 1 then return

;; ;; if not specified, filter just before the next harmonics of the HWP rotation
;; if param.polar_lockin_freqhigh le 0 then param.polar_lockin_freqhigh = 0.99*info.hwp_rot_freq

if not keyword_set(plot) then plot = param.debug

if defined(snr_toi) then w8_source=1.d0/(1.d0+param.k_snr_w8_decor*snr_toi^2)

;; Compute HWPSS
w1 = where( kidpar.type eq 1, nw1)
nsn = n_elements(data)
hwpss = dblarr(nw1,nsn)
if param.force_subtract_hwp_per_subscan eq 1 then begin

   multiplot_index=0
   
   for isubscan=min(data.subscan), max(data.subscan) do begin
      wsubscan = where( data.subscan eq isubscan, nwsubscan)
      if nwsubscan ne 0 then begin
         info.CURRENT_SUBSCAN_NUM = isubscan
         myflag = data[wsubscan].flag[w1]

         ;; IDL does not accept to pass w8_source[w1,wsubscan]
         ;; directly as keyword (sic!) => have to do it in two steps
         if defined(w8_source) then begin
            in_w8_source = w8_source[w1,*]
            in_w8_source = in_w8_source[*,wsubscan]
         endif
         
         nk_get_hwpss_sub_1, param, info, data[wsubscan].toi[w1], $
                             data[wsubscan].synchro, data[wsubscan].position, myflag, $
                             kidpar[w1], hwpss_subscan, plot=plot, off_source=data[wsubscan].off_source[w1], $
                             amplitudes=amplitudes, multiplot_pp1=multiplot_pp1, multiplot_index=multiplot_index, $
                             in_w8_source=in_w8_source
         multiplot_index++
         hwpss[*,wsubscan] = hwpss_subscan
         data[wsubscan].flag[w1] = myflag
      endif
      
      if param.hwp_harmonics_only eq 1 then begin
         for i=0, param.polar_n_template_harmonics-1 do begin
            junk = execute( "kidpar[w1].cos"+strtrim(i+1,2)+"omega = amplitudes[*, i*2  ]")
            junk = execute( "kidpar[w1].sin"+strtrim(i+1,2)+"omega = amplitudes[*, i*2+1]")
         endfor
      endif else begin
         for i=0, param.polar_n_template_harmonics-1 do begin
            junk = execute( "kidpar[w1].cos"+strtrim(i+1,2)+"omega     = amplitudes[*, i*4    ]")
            junk = execute( "kidpar[w1].dcos"+strtrim(i+1,2)+"omega_dt = amplitudes[*, i*4 + 1]")
            junk = execute( "kidpar[w1].sin"+strtrim(i+1,2)+"omega     = amplitudes[*, i*4 + 2]")
            junk = execute( "kidpar[w1].dsin"+strtrim(i+1,2)+"omega_dt = amplitudes[*, i*4 + 3]")
         endfor
      endelse
   endfor
   
endif else begin

   if param.force_subtract_hwp_per_two_subscans eq 1 then begin
      multiplot_index=0
      i1 = min(data.subscan)
      while i1 le max(data.subscan) do begin
         wsubscan = where( data.subscan ge i1 and data.subscan le i1+1, nwsubscan)
         if nwsubscan ne 0 then begin
            info.CURRENT_SUBSCAN_NUM = i1
            myflag = data[wsubscan].flag[w1]
            
            ;; IDL does not accept to pass w8_source[w1,wsubscan]
            ;; directly as keyword (sic!) => have to do it in two steps
            if defined(w8_source) then begin
               in_w8_source = w8_source[w1,*]
               in_w8_source = in_w8_source[*,wsubscan]
            endif
            nk_get_hwpss_sub_1, param, info, data[wsubscan].toi[w1], $
                                data[wsubscan].synchro, data[wsubscan].position, myflag, $
                                kidpar[w1], hwpss_subscan, plot=plot, off_source=data[wsubscan].off_source[w1], $
                                amplitudes=amplitudes, multiplot_pp1=multiplot_pp1, multiplot_index=multiplot_index, $
                                in_w8_source=in_w8_source
            multiplot_index++
            hwpss[*,wsubscan] = hwpss_subscan
            data[wsubscan].flag[w1] = myflag
         endif
         
         if param.hwp_harmonics_only eq 1 then begin
            for i=0, param.polar_n_template_harmonics-1 do begin
               junk = execute( "kidpar[w1].cos"+strtrim(i+1,2)+"omega = amplitudes[*, i*2  ]")
               junk = execute( "kidpar[w1].sin"+strtrim(i+1,2)+"omega = amplitudes[*, i*2+1]")
            endfor
         endif else begin
            for i=0, param.polar_n_template_harmonics-1 do begin
               junk = execute( "kidpar[w1].cos"+strtrim(i+1,2)+"omega     = amplitudes[*, i*4    ]")
               junk = execute( "kidpar[w1].dcos"+strtrim(i+1,2)+"omega_dt = amplitudes[*, i*4 + 1]")
               junk = execute( "kidpar[w1].sin"+strtrim(i+1,2)+"omega     = amplitudes[*, i*4 + 2]")
               junk = execute( "kidpar[w1].dsin"+strtrim(i+1,2)+"omega_dt = amplitudes[*, i*4 + 3]")
            endfor
         endelse

         i1 += 2
      endwhile
      
   endif else begin
      myflag = data.flag[w1]
      
      ;; IDL does not accept to pass w8_source[w1,wsubscan]
      ;; directly as keyword (sic!) => have to do it in two steps
      if defined(w8_source) then begin
         in_w8_source = w8_source[w1,*]
      endif
      nk_get_hwpss_sub_1, param, info, data.toi[w1], $
                          data.synchro, data.position, myflag, $
                          kidpar[w1], hwpss, plot=plot, $
                          off_source=data.off_source[w1], amplitudes=amplitudes, $
                          in_w8_source=in_w8_source
      data.flag[w1] = myflag
      
      if param.hwp_harmonics_only eq 1 then begin
         for i=0, param.polar_n_template_harmonics-1 do begin
            junk = execute( "kidpar[w1].cos"+strtrim(i+1,2)+"omega = amplitudes[*, i*2  ]")
            junk = execute( "kidpar[w1].sin"+strtrim(i+1,2)+"omega = amplitudes[*, i*2+1]")
         endfor
      endif else begin
         for i=0, param.polar_n_template_harmonics-1 do begin
            junk = execute( "kidpar[w1].cos"+strtrim(i+1,2)+"omega     = amplitudes[*, i*4    ]")
            junk = execute( "kidpar[w1].dcos"+strtrim(i+1,2)+"omega_dt = amplitudes[*, i*4 + 1]")
            junk = execute( "kidpar[w1].sin"+strtrim(i+1,2)+"omega     = amplitudes[*, i*4 + 2]")
            junk = execute( "kidpar[w1].dsin"+strtrim(i+1,2)+"omega_dt = amplitudes[*, i*4 + 3]")
         endfor
      endelse
   endelse

endelse

end
