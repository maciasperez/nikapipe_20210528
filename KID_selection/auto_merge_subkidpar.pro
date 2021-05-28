pro auto_merge_subkidpar, kidpars_dir, beammap, nproc

  kidpar_list = kidpars_dir+"kidpar_"+beammap+"_"+strtrim(indgen(nproc),2)+".fits"
  for iproc=0, nproc-1 do begin
     print, kidpar_list[iproc]
     kidpar1 = mrdfits( kidpar_list[iproc], 1, /silent)
     if iproc eq 0 then begin
        kidpar = kidpar1
     endif else begin
        nk  = n_elements(kidpar)
        nk1 = n_elements(kidpar1)
        kidpar_new = kidpar[0]
        kidpar_new = replicate( kidpar_new, nk+nk1)
        kidpar_new[0:nk-1] = kidpar
        kidpar_new[nk:*]   = kidpar1
        kidpar = kidpar_new
     endelse
  endfor

  nk_write_kidpar, kidpar, kidpars_dir+"kidpar_"+beammap+"_v0.fits"
  stop
end
