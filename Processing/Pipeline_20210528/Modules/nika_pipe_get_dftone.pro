;+
;PURPOSE: Recompute the df_tone offline
;         the original raw_data df_tone may not be correct
;         First method uses raw data coefficients
;         Second method uses internal consistency with toi
;
;INPUT: The parameter and data structure.
;
;OUTPUT: modified df_tone
;
;LAST EDITION: 26/02/2012
;   2015/07/04:creation from nk_get_df_tone.pro
;-

pro nika_pipe_get_dftone, param, data, kidpar, param_d

  if param.renew_df ge 1 then begin ; computation for both cases: 1 and 2
     ;;Compute the angle between i,q and di,dq +pi/2
     ang = nk_angleiq_didq(data)
     
     coeff1mm = 1./1.43931 ;;Renormalize frequencies
     ind = where(kidpar.type le 2,  nind)
     
     if param.renew_df eq 1 then begin ;;Compute df_tone
        if nind ne 0 then begin
           for idet = 0, nind-1 do $
              data.df_tone[ind[idet]] = reform(ang[ind[idet], *] * (param_d[ind[idet]].width) )
        endif
     endif
     if param.renew_df eq 2 then begin 
        ;;Compute df_tone by correlation with TOI (Rf or Pf)
        if nind ne 0 then begin
           scansub= where(data.subscan gt 0 and $
                          data.scan_valid[0] eq 0 and $
                          data.scan_valid[1] eq 0, nscansub)
           ;;Renormalize frequencies
           for idet = 0, nind-1 do begin
              idt = ind[idet]
              if kidpar[idt].array eq 1 then coeff = -coeff1mm else coeff = -1.0
              if stddev(data[scansub].rf_didq[idt]) gt 0. then begin
                 linpar = linfit(coeff*data[ scansub].rf_didq[idt],ang[idt,scansub])
                 if abs(linpar[1]) gt 1D-6 then begin
                    ;;Correct the zero point of data.rf_didq to match the df_tone zero point
                    data.rf_didq[idt] = data.rf_didq[idt]+ linpar[0]/linpar[1]/coeff
                    ;;Correct the df_tone to be calibrated as a toi in Hz
                    data.df_tone[idt] = reform(ang[idt,*])/(linpar[1])
                 endif else data.df_tone[idt] = 0.0
              endif
           endfor
        endif
     endif
  endif
  
  return
end
