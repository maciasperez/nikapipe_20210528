;+
;PURPOSE: Get the 1/variance weighting
;
;INPUT: The parameter, data and kidpar structures.
;
;OUTPUT: The weight
;
;LAST EDITION: 
;   2013: creation (adam@lpsc.in2p3.fr)
;   24/09/2013: modify w8 parameters (adam@lpsc.in2p3.fr)
;   04/07/2104: use nika_pipe_onsource to flag the data
;-

pro nika_pipe_w8toi, param, data, kidpar
  
  if param.w8.apply eq 'yes' then begin
     N_kid = n_elements(kidpar)
     noise = dblarr(N_kid)      ;The noise for all KIDs

     ;;---------- Weight according to the noise
     data.w8 = 0                ;0 for everyone at first
     sig = dblarr(N_kid)
     for ikid=0, N_kid-1 do begin
        if kidpar[ikid].type eq 1 then begin
           ;;------- Start to compute the stddev for each subscan
           if param.w8.per_subscan eq 'yes' then begin
              for isubscan=(min(data.subscan)>0), max(data.subscan) do begin
                 wsubscan = where(data.subscan eq isubscan, nwsubscan)
                 if nwsubscan gt 0 then begin
                    ;;------- Flag the TOI
                    loc_calc = where(data.on_source_w8[ikid] eq 0 and data.subscan eq isubscan, nloc)
                    if nloc gt 20 then sig[ikid] = stddev(data[loc_calc].RF_dIdQ[ikid]) else sig[ikid] = 0
                    if sig[ikid] ne 0 then data[wsubscan].w8[ikid] =  1.0/(sig[ikid])^2.0
                 endif
              endfor
           endif else begin
              ;;------- Flag the TOI
              loc_calc = where(data.on_source_w8[ikid] eq 0, nloc)
              if nloc ne 0 then sig[ikid] = stddev(data[loc_calc].RF_dIdQ[ikid]) else sig[ikid] = 0
              if sig[ikid] ne 0 then data.w8[ikid] =  1.0/(sig[ikid])^2.0
           endelse
           
           ;;------- Get the noise estimate
           noise[ikid] = mean(1/sqrt(data.w8[ikid]))
        endif
     endfor

     ;;---------- Flag obvious glitches/jumps and cut subscans
     for ikid=0, N_kid-1 do begin
        loc = where(abs(data.RF_dIdQ[ikid]-mean(data.RF_dIdQ[ikid])) gt $
                    param.w8.nsigma_cut*stddev(data.RF_dIdQ[ikid]), nloc)
        if nloc ne 0 then nika_pipe_addflag, data, 0, wkid=[ikid], wsample=loc
     endfor
     
     ;;---------- Reorder the estimated noise in the TOI
     w = where(kidpar.array eq 1 and kidpar.type eq 1, nw)
     if nw ne 0 then begin
        noise_a = noise[w]
        param.mean_noise_list.A[param.iscan] = mean((noise_a[sort(noise_a)])[0:10])
     endif
     w = where(kidpar.array eq 2 and kidpar.type eq 1, nw)
     if nw ne 0 then begin
        noise_b = noise[w]
        param.mean_noise_list.B[param.iscan] = mean((noise_b[sort(noise_b)])[0:10])
     endif
  endif

  return
end
