;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_set0level
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_set0level, param, info, data, kidpar
; 
; PURPOSE: 
;        Subtract the mean of each kid outside the source to ensure that each
;subscan has a correct background zero level.
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the NIKA general data structure
;        - kidpar: the NIKA general kid structure
; 
; OUTPUT: 
;        - data: 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Nov. 26th, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;        - June 26th,2015: back to version before June ,16th (revision
;          7568), we subtract an average per kid    

pro nk_set0level, param, info, data, kidpar

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_set0level, param, info, data, kidpar"
   return
endif

;; sanity checks  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime( 0, /sec)

nsn = n_elements(data)
w1  = where( kidpar.type eq 1, nw1)

;; Full scan
toi        = data.toi
off_source = data.off_source

if info.polar ne 0 and param.force_no_zero_level_polar eq 0 then begin
   toi_q = data.toi_q
   toi_u = data.toi_u
endif

;; message, /info, "fix me"
;; nsn = n_elements(data)
;; w1 = where(kidpar.type eq 1, nw1)
;; toi1 = toi[w1,*]
;; toi2 = toi1
;; toi_avg = avg( toi1, 1, /nan)
;; t0 = systime(0,/sec)
;; for i=0, nw1-1 do begin
;;    toi1[i,*] -= toi_avg[i]
;; endfor
;; t1 = systime(0,/sec)
;; 
;; toi2 -= rebin(toi_avg,nw1,nsn)
;; t2 = systime(0,/sec)
;; help, toi1, toi2
;; print, minmax(toi2-toi1)
;; print, "t1-t0: ", t1-t0
;; print, "t2-t1: ", t2-t1
;; stop





if param.set_zero_level_full_scan eq 1 then begin
   w = where(data.off_source eq 0,nw)

   ;; I
   if nw ne 0 then toi[w] = !values.d_nan
   toi_avg = avg( toi, 1, /nan)
   toi = 0 ; save memory
   for i=0, nw1-1 do begin
      ikid = w1[i]
      if finite(toi_avg[ikid]) then begin
         data.toi[ikid] -= toi_avg[ikid]
      endif else begin
         ;; These data should already be flagged, but make it sure here
         data.flag[ikid] = 1
      endelse
   endfor

   if info.polar ne 0 and param.force_no_zero_level_polar eq 0 then begin
      if nw ne 0 then begin
         toi_q[w] = !values.d_nan
         toi_u[w] = !values.d_nan
      endif

      toi_avg = avg( toi_q, 1, /nan)
      toi_q = 0                   ; save memory
      for i=0, nw1-1 do begin
         ikid = w1[i]
         if finite(toi_avg[ikid]) then begin
            data.toi_q[ikid] -= toi_avg[ikid]
         endif else begin
            ;; These data should already be flagged, but make it sure here
            data.flag[ikid] = 1
         endelse
      endfor

      toi_avg = avg( toi_u, 1, /nan)
      toi_u = 0                   ; save memory
      for i=0, nw1-1 do begin
         ikid = w1[i]
         if finite(toi_avg[ikid]) then begin
            data.toi_u[ikid] -= toi_avg[ikid]
         endif else begin
            ;; These data should already be flagged, but make it sure here
            data.flag[ikid] = 1
         endelse
      endfor
   endif

endif

if param.set_zero_level_per_subscan eq 1 then begin
   for isubscan=min(data.subscan), max(data.subscan) do begin
      wsubscan = where( data.subscan eq isubscan, nwsubscan)
;;;      if nwsubscan ne 0 then begin
      if nwsubscan gt 1 then begin
;;; Otherwise toi1 is only a 1D array
;;;         
         off_source1 = off_source[*,wsubscan]
         w           = where( off_source1 eq 0, nw)

         ;; I
         toi1 = toi[       *,wsubscan]
         if nw ne 0 then toi1[w] = !values.d_nan
         toi_avg = avg( toi1, 1, /nan) ; one average zero level per kid
         for j=0, nw1-1 do begin
            ikid = w1[j]
            if finite(toi_avg[ikid]) then begin
               data[wsubscan].toi[ikid] -= toi_avg[ikid]
            endif else begin
               ;; These data should already be flagged, but make it sure here
               data[wsubscan].flag[ikid] = 1
            endelse
         endfor

          if info.polar ne 0 and param.force_no_zero_level_polar eq 0 then begin
             ;; Q
             toi1 = toi_q[*,wsubscan]
             if nw ne 0 then toi1[w] = !values.d_nan
             toi_avg = avg( toi1, 1, /nan) ; one average zero level per kid
             for j=0, nw1-1 do begin
                ikid = w1[j]
                if finite(toi_avg[ikid]) then begin
                   data[wsubscan].toi_q[ikid] -= toi_avg[ikid]
                endif else begin
                   ;; These data should already be flagged, but make it sure here
                   data[wsubscan].flag[ikid] = 1
                endelse
             endfor
 
             ;; U
             toi1 = toi_u[*,wsubscan]
             if nw ne 0 then toi1[w] = !values.d_nan
             toi_avg = avg( toi1, 1, /nan) ; one average zero level per kid
             for j=0, nw1-1 do begin
                ikid = w1[j]
                if finite(toi_avg[ikid]) then begin
                   data[wsubscan].toi_u[ikid] -= toi_avg[ikid]
                endif else begin
                   ;; These data should already be flagged, but make it sure here
                   data[wsubscan].flag[ikid] = 1
                endelse
             endfor
          endif

      endif
   endfor
endif
toi = 0 ; save memory

if param.cpu_time then nk_show_cpu_time, param, "nk_set0level"

end
