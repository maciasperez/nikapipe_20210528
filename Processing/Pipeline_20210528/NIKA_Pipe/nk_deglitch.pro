;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_deglitch
;
; CATEGORY: 1D processing
;
; CALLING SEQUENCE:
;         nk_deglitch, param, info, data, kidpar
; 
; PURPOSE: 
;        Detect, flags and interpolate cosmic ray induced glitches
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the NIKA general data structure
;        - kidpar: the NIKA general kid structure
; 
; OUTPUT: 
;        - data
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - April 8th, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;===========================================================================================================

pro nk_deglitch, param, info, data, kidpar
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_deglitch'
   return
endif


if param.new_deglitch eq 1 then begin
   nk_deglitch_2, param, info, data, kidpar
endif else begin

   if info.status eq 1 then begin
      if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
      return
   endif

   if param.cpu_time then param.cpu_t0 = systime( 0, /sec)

   nsn   = n_elements(data)
   nkids = n_elements( kidpar)

   index = lindgen(nsn)
;flag = intarr(nkids, nsn)

;; Only samples for which the signal is not well computed should be
;; discarded. Glitches have nothing to do with pointing errors and so
;; on
;wflag = nika_pipe_wflag( data.flag[0], 7, nflag=nwflag, compl=wflag_compl, ncompl=nwflag_compl)
;flag = intarr(nsn)
;if nwflag ne 0 then flag[wflag] = 1

;; Choose which deglitching method to apply
   if param.glitch_iq eq 1 then begin
      name_var = ["I", "Q", "DI", "DQ"]

      for j=0, n_elements(name_var)-1 do begin
         for ikid=0, nkids-1 do begin
            if kidpar[ikid].type ne 2 then begin
               junk = execute( "y = data."+name_var[j]+"[ikid]")
               qd_deglitch_baseline, y, param.glitch_width, param.glitch_nsigma, data_out, flag0, $
                            deglitch_nsamples_margin=param.deglitch_nsamples_margin ;, input_flag=flag
               junk = execute( "data."+name_var[j]+"[ikid] = data_out")

               w = where( flag0 ne 0, nw)
               if nw ne 0 then print, param.scan+" has "+strtrim(nw,2)+", glitches on kid "+strtrim(ikid,2)
               if nw ne 0 then nk_add_flag, data, 0, wsample=w, wkid=ikid

               if keyword_set(show) then begin
                  y2 = data_out
                  wg = where(flag0 eq 1, nglitch)
                  plot, index, y, xra=xra, /xs, title=name_var[j]+" "+strtrim(ikid,2), /ys
                  if nglitch ne 0 then oplot, index[wg], y[wg], psym=4, col=250
                  oplot, index, y2, col=70
                  cont_plot, nostop=nostop
               endif
            endif
         endfor
      endfor

   endif else begin

      ;; Faster if we can avoid the loop on name var
      for ikid=0, nkids-1 do begin
         if kidpar[ikid].type ne 2 then begin
            y = data.toi[ikid]
;;             message, /info, strtrim(ikid,2)+"/"+strtrim(nkids-1,2)+", nsn: "+strtrim(n_elements(y),2)
;;             if ikid eq 770 then begin
;;                print, "ikid = "+strtrim(ikid,2)+", I stop"
;;                debug = 1
;;                stop
;;             endif
            qd_deglitch_baseline, y, param.glitch_width, param.glitch_nsigma, data_out, flag0, $
                                deglitch_nsamples_margin=param.deglitch_nsamples_margin;, input_flag=flag
            data.toi[ikid] = data_out

            if info.polar ne 0 then begin
               y = data.toi_q[ikid]
               qd_deglitch_baseline, y, param.glitch_width, param.glitch_nsigma, data_out, flag0, $
                                deglitch_nsamples_margin=param.deglitch_nsamples_margin;, input_flag=flag
               data.toi_q[ikid] = data_out

               y = data.toi_u[ikid]
               qd_deglitch_baseline, y, param.glitch_width, param.glitch_nsigma, data_out, flag0, $
                                deglitch_nsamples_margin=param.deglitch_nsamples_margin;, input_flag=flag
               data.toi_u[ikid] = data_out
            endif
            
            w = where( flag0 ne 0, nw)
            if nw ne 0 then nk_add_flag, data, 0, wsample=w, wkid=ikid
            
            if keyword_set(show) then begin
               y2 = data_out
               wg = where(flag0 eq 1, nglitch)
               plot, index, y, xra=xra, /xs, title=name_var[j]+" "+strtrim(ikid,2), /ys
               if nglitch ne 0 then oplot, index[wg], y[wg], psym=4, col=250
               oplot, index, y2, col=70
               cont_plot, nostop=nostop
            endif
         endif
      endfor

   endelse

;; Recombine into TOI (PF, RF) if needed
   if param.glitch_iq eq 1 then begin 
      case strupcase(param.math) of
         
         "RF":nk_iq2rf_didq, param, data, kidpar
         
         "PF": begin
            if !nika.pf_ndeg gt 0 and !nika.freqnorm1 gt 0. and n_elements(data.i) gt 1 then $
               nika_conviq2pf, data, kidpar, dapf, !nika.pf_ndeg, [!nika.freqnorm1, !nika.freqnorm2, !nika.freqnorm3]
            data.toi = dapf
         end
         "CF": begin
            if !nika.pf_ndeg gt 0 and !nika.freqnorm1 gt 0. and n_elements(data.i) gt 1 then $
               nika_conviq2pf, data, kidpar, dapf, !nika.pf_ndeg+1, [!nika.freqnorm1, !nika.freqnorm2, !nika.freqnorm3], /cfmethod
            data.toi = dapf
         end
      endcase

      ;; Now we don't need I, Q, dI, dQ anymore
      rm_fields = ['I', 'Q', 'DI', 'DQ']
      nk_shrink_data, param, info, data, kidpar, rm_fields=rm_fields
   endif
  
   if param.cpu_time then nk_show_cpu_time, param, "nk_deglitch"
endelse

end
