;+
;PURPOSE: Regress all the TOI far enough from the fitted one
;
;INPUT: The parameter structure, the TOI of the given array, the
;kidpar and the subscan
;
;OUTPUT: The decorrelated data structure.
;
;LAST EDITION: 21/01/2012: creation(adam@lpsc.in2p3.fr)
;              10/01/2014: use an other kidpar with flagged KIDs
;              05/07/2104: use nika_pipe_atmxcalib now and no loop for
;                          common mode construction
;-

pro nika_pipe_fulldec, param, TOI, kidpar, subscan

  N_pt = n_elements(TOI[0,*])
  n_kid = n_elements(TOI[*,0])
  
  w_on = where(kidpar.type eq 1, n_on)   ;Number of detector ON
  w_off = where(kidpar.type eq 2, n_off) ;Number of detector OFF
  
  TOI_in = TOI
  TOI_out = dblarr(n_kid, N_pt)
  
;#################################
  if param.decor.common_mode.per_subscan eq 'no' then begin ;All the scan
     for ikid=0, n_on-1 do begin
        distance = sqrt((kidpar[w_on].nas_x - kidpar[w_on[ikid]].nas_x)^2 $
                        + (kidpar[w_on].nas_y - kidpar[w_on[ikid]].nas_y)^2)
        loc = w_on[where(w_on ne w_on[ikid] and $                    ;all on KIDs except the one we are looking at
                         distance ge param.decor.common_mode.d_min)]        ;and not same airy stain
        template = TOI_in[loc, *]
        y = reform(TOI_in[w_on[ikid],*])
        coeff = regress(template, y,  CHISQ= chi, CONST= const, CORRELATION= corr, $
                        /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status, YFIT=yfit)
        TOI_out[w_on[ikid],*] = TOI_in[w_on[ikid],*] - reform(yfit)
     endfor
  endif
  
;#################################
  if param.decor.common_mode.per_subscan eq 'yes' then begin ;Only the subscan
     for isubscan=(min(subscan)>0), max(subscan) do begin
        wsubscan = where(subscan eq isubscan, nwsubscan)
        if nwsubscan gt long(2.5*!nika.f_sampling) then begin
           for ikid=0, n_on-1 do begin
              distance = sqrt((kidpar[w_on].nas_x - kidpar[w_on[ikid]].nas_x)^2 $
                              + (kidpar[w_on].nas_y - kidpar[w_on[ikid]].nas_y)^2)
              loc = w_on[where(w_on ne w_on[ikid] and $             ;all on KIDs except the one we are looking at
                               distance ge param.decor.common_mode.d_min)] ;and not same airy stain
              template = (TOI_in[loc, *])[*,wsubscan]
              y = reform(TOI_in[w_on[ikid],wsubscan])
              coeff = regress(template, y,  CHISQ= chi, CONST= const, CORRELATION= corr, $
                              /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status, YFIT=yfit)
              TOI_out[w_on[ikid],wsubscan] = TOI_in[w_on[ikid],wsubscan] - reform(yfit)
           endfor
        endif
     endfor
  endif
  
  TOI = TOI_out

  return
end
