;+
;PURPOSE: Deglitch and flag the data.
;
;INPUT: The parameter and the data structures
;
;OUTPUT: The data structure deglitched and flagged.
;
;LAST EDITION: 
;   21/09/2013: creation (adam@lpsc.in2p3.fr)
;   15/10/2013 : NP
;                 - improved version of qd_deglitch based on Archeops routines
;                 - updated recombination of I,Q,dI,DQ into RF_dIdQ (does exactly what Alain
;                 does in C and is somewhat faster)
;   17/12/2013: RA - add the flag of data.flag
;   06/01/2014: RA - use nika_pipe_addflag for flagging
;

pro nika_pipe_deglitch, param, data, kidpar, show=show

  nsn   = n_elements(data)
  nkids = n_elements( kidpar)

  index = lindgen(nsn)
  flag = intarr(nkids, nsn)

;; Choose which deglitching method to apply
  if param.glitch.iq eq 1 then begin
     name_var = ["I", "Q", "DI", "DQ"]
  endif else begin
     name_var = ["RF_DIDQ"]
  endelse

;; ;; Deglitch
;; for j=0, n_elements(name_var)-1 do begin
;; 
;;    for ikid=0, nkids-1 do begin
;;       junk = execute( "y = data."+name_var[j]+"[ikid]")
;;       wg = glitch_find( y, param.glitch.nsigma, param.glitch.width, 5)
;;       
;;       if wg[0] ne -1 then flag[ikid,wg] += 1 
;; 
;;       if keyword_set(show) then plot, index, y, xra=xra, /xs, title=name_var[j]+" "+strtrim(ikid,2), /ys
;; 
;;       if wg[0] ne -1 then begin
;;          y[wg] = !undef
;;          y = interp_hole( y, holedef=!undef, /simple)
;;       endif
;;       
;;       if keyword_set(show) then begin
;;          if wg[0] ne -1 then oplot, index[wg], y[wg], psym=4, col=250
;;          oplot, index, y, col=70
;;          cont_plot, nostop=nostop
;;       endif
;; 
;;       junk = execute( "data."+name_var[j]+"[ikid] = y")
;;    endfor
;; endfor

;; Back to qd_deglitch that seems to be better in NIKA's case
;; but improve with iterations to preserve planets
  for j=0, n_elements(name_var)-1 do begin
     for ikid=0, nkids-1 do begin
        junk = execute( "y = data."+name_var[j]+"[ikid]")
        qd_deglitch, y, param.glitch.width, param.glitch.nsigma, data_out, flag0
        junk = execute( "data."+name_var[j]+"[ikid] = data_out")
        flag[ikid,*] += flag0

        if keyword_set(show) then begin
           y2 = data_out
           wg = where(flag0 eq 1, nglitch)
           plot, index, y, xra=xra, /xs, title=name_var[j]+" "+strtrim(ikid,2), /ys
           if nglitch ne 0 then oplot, index[wg], y[wg], psym=4, col=250
           oplot, index, y2, col=70
           cont_plot, nostop=nostop
        endif

     endfor
  endfor

  for ikid=0, nkids-1 do begin
     loc_flag = where(flag[ikid,*] ne 0, nloc_flag)
     if nloc_flag ne 0 then nika_pipe_addflag, data, 0, wsample=loc_flag, wkid=[ikid]
  endfor

;; Recombine into RF_DIDQ (PF) if needed
  if param.glitch.iq eq 1 then begin 
     case strupcase(param.math) of

        "RF":nika_pipe_iq2rfdidq, param, data, kidpar

        "PF": begin
           if !nika.pf_ndeg gt 0 and !nika.freqnormA gt 0. and n_elements(data.i) gt 1 then $
              nika_conviq2pf, data, kidpar, dapf, !nika.pf_ndeg, [!nika.freqnormA, !nika.freqnormB]         
           data.rf_didq = dapf
        end

     endcase
  endif

end
