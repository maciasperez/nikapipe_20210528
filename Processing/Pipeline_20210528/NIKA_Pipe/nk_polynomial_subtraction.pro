;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_polynomial_subtraction
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_polynomial_subtraction, param, info, data, kidpar
; 
; PURPOSE: 
;        bandpass filters, subtract polynomials...
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
;        - sample_index: the sample nums absolute values
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Dec. 16th, 2014: creation (Nicolas Ponthieu & Remi Adam -
;          adam@lpsc.in2p3.fr)
;        - update from nk_filter, NP, March. 10th, 2016


pro nk_polynomial_subtraction, param, info, data, kidpar, w8_in=w8_in
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_polynomial_subtraction'
   return
endif

;; sanity checks  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

nkf_status = 0

nsn = n_elements(data)

w1 = where( kidpar.type eq 1, nw1)
if nw1 ne 0 then begin

   for isubscan=min(data.subscan), max(data.subscan) do begin
      wsubscan = where( data.subscan eq isubscan, nwsubscan)
      for i=0, nw1-1 do begin
         ikid = w1[i]

         ;; adapt wfit def to the new "index" def (NP, July 9th)
         if keyword_set(w8_in) then begin
            wfit = where( data[wsubscan].flag[ikid] eq 0, nwfit)
         endif else begin
            wfit = where( data[wsubscan].flag[ikid] eq 0 and $
                          data[wsubscan].off_source[ikid] eq 1, nwfit)
         endelse

         if nwfit le param.nsample_min_per_subscan then begin
            ;data[wsubscan].flag[ikid] += 1 ; do not project this subscan
            nk_add_flag, data, 7, wsample=wsubscan, wkid=ikid
         endif else begin
            toi = data[wsubscan].toi[ikid]

            if defined(w8_in) then begin
               measure_errors = reform( sqrt(1.d0/w8_in[ikid,wsubscan[wfit]]), nwfit)
            endif

            ;; renormalize "index" to avoid large sample number to large
            ;; polynomial degrees and possible numerical errors.
            index = dindgen(nwsubscan)/(nwsubscan-1)

            r = poly_fit( index[wfit], toi[wfit], $
                          param.polynomial, status = status, measure_errors=measure_errors)


;;             ;;-----------------------------------------------------------------------------
;;             if data[wsubscan[0]].subscan ge 10 and data[wsubscan[0]].subscan le 13 then begin
;;                if ikid eq 437 then begin
;;                   yfit = index*0.d0
;;                   for ii=0, n_elements(r)-1 do yfit += r[ii]*index^ii
;;                   
;;                   wind, 1, 1, /free, /large
;;                   my_multiplot, 1, 2, pp, pp1, /rev
;;                   plot, index, measure_errors, /xs, position=pp1[0,*]
;;                   legendastro, ['measure_errors', 'k_snr_w8: '+strtrim(param.k_snr_w8_decor,2)]
;;                   plot, index, toi, /xs, /ys, position=pp1[1,*], /noerase
;;                   oplot, index, yfit, col=250
;;                   
;;                   stop
;;                endif
;;             endif
;;             ;;-----------------------------------------------------------------------------
            
            if status eq 0 then begin ; success
               yfit = index*0.d0
               for ii=0, n_elements(r)-1 do yfit += r[ii]*index^ii
               data[wsubscan].toi[ikid] -= yfit
            endif else begin
               ;data[wsubscan].flag[ikid] = 1
               nk_add_flag, data, 7, wsample=wsubscan, wkid=ikid
            endelse

;;            if info.polar ne 0 then begin
;;               toi_q = data[wsubscan].toi_q[ikid]
;;               r = poly_fit( index[wfit], toi_q[wfit], $
;;                             param.polynomial, status = status, measure_errors=measure_errors)
;;               if status eq 0 then begin
;;                  yfit = index*0.d0
;;                  for ii=0, n_elements(r)-1 do yfit += r[ii]*index^ii
;;                  data[wsubscan].toi_q[ikid] -= yfit
;;               endif else begin
;;                  data[wsubscan].flag[ikid] = 1
;;               endelse
;;               
;;               toi_u = data[wsubscan].toi_u[ikid]
;;               r = poly_fit( index[wfit], toi_u[wfit], $
;;                             param.polynomial, status = status, measure_errors=measure_errors)
;;               if status eq 0 then begin
;;                  yfit = index*0.d0
;;                  for ii=0, n_elements(r)-1 do yfit += r[ii]*index^ii
;;                  data[wsubscan].toi_u[ikid] -= yfit
;;               endif else begin
;;                  data[wsubscan].flag[ikid] = 1
;;               endelse
;;            endif
         endelse
      endfor
   endfor
endif

end
