;+
;PURPOSE: Calibrate the TOI form RFdIdQ (Hz) to flux (Jy) taking into
;         account the opacity
;
;INPUT: The parameter and data structures.
;
;OUTPUT: The calibrated data structure.
;
;LAST EDITION: 
;   2013: correct for opacity (adam@lpsc.in2p3.fr)
;   2013: adapted to Run6 data format (Nicolas.ponthieu@obs.ujf-grenoble.fr)
;   26/04/2013: adapted to work with nika_pipe_opacity (catalano@lpsc.in2p3.fr)
;   17/09/2014 : adapt to the new param structure without breaking the old one
;for Remi's pipeline
;-

pro nika_pipe_calib_2, param, data, kidpar, noskydip=noskydip

  nsn = n_elements(data)
  nkids = n_elements(kidpar)
  
; Correct to avoid elevation being 0 
  bad = where(data.scan_valid[0] gt 0 and data.scan_valid[1] gt 0,nbad,comp=oksamp,ncomp=noksamp)
;  elev_moy = data[nsn/2].el
  if noksamp gt 1 then elev_moy = median(data[oksamp].el)
; Loop for all kids
  for ikid=0, nkids-1 do begin            ;loop over all KIDs
     if kidpar[ikid].type eq 1 then begin ;only calibrate type 1 KIDs
        
        ;;------- Get the correct opacity
        if keyword_set(noskydip) then begin  
           corr = 1.d0
        endif else begin
           if noksamp gt 1 then corr = exp( kidpar[ikid].tau_skydip/sin(elev_moy)) else corr = 1.d0
        endelse

        ;;------- Calibrate
        ;; Feb. 10th, 2014 (Nico)
        if strmid(param.day, 0, 6) eq '201211' or $
           strmid(param.day, 0, 6) eq '201306' or $
           strmid(param.day, 0, 6) eq '201311' $
        then data.toi[ikid] = data.toi[ikid] * kidpar[ikid].calib * corr $
        else data.toi[ikid] = data.toi[ikid] * kidpar[ikid].calib_fix_fwhm * corr
     endif
  endfor
  
end
