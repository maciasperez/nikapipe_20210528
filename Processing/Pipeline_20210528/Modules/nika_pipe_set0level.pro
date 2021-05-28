;+
;PURPOSE: Subtract the zero level in each TOI. This is important
;         because if all the maps per KID are not at the same zero
;         level, fake correlated noise will appear on the map due to
;         multiple jumps combination
;
;INPUT: parameter structure, data structure and kidpar structure
;
;OUTPUT: Zero level free TOIs
;
;LAST EDITION: 
;   05/06/2013: creation (adam@lpsc.in2p3.fr)
;   24/09/2013: add a keyword for flaging a strong source
;   04/07/2104: use nika_pipe_onsource to flag the data
;-

pro nika_pipe_set0level, param, data, kidpar

  if param.zero_level.apply eq 'yes' then begin
     N_kid = n_elements(kidpar)
     
     ;;------- loop over all valid detectors
     for ikid=0, N_kid-1 do begin
        if kidpar[ikid].type eq 1 then begin        
           ;;------- Flag the on source locations en remove the zero
           ;;        level: case of all scan
           if param.zero_level.per_subscan eq 'no' then begin
              loc_estim = where(data.on_source_zl[ikid] eq 0, nloc)
              if nloc ne 0 then data.RF_dIdQ[ikid] = data.RF_dIdQ[ikid] - mean(data[loc_estim].RF_dIdQ[ikid])
           endif

           ;;------- Per subscan case
           if param.zero_level.per_subscan eq 'yes' then begin
              for isubscan=(min(data.subscan)>0), max(data.subscan) do begin
                 wsubscan = where(data.subscan eq isubscan, nwsubscan)
                 if nwsubscan ne 0 then begin
                    loc_estim = where(data.on_source_zl[ikid] eq 0 and data.subscan eq isubscan, nloc)
                    if nloc ne 0 then data[wsubscan].RF_dIdQ[ikid] = data[wsubscan].RF_dIdQ[ikid] - $
                       mean(data[loc_estim].RF_dIdQ[ikid])
                 endif
              endfor
           endif
        endif
     endfor
  endif

  return
end
