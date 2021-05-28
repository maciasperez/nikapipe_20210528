pro nika_pipe_nan_flag, param, data, kidpar
  nkids = n_elements(data[0].rf_didq)
  for ikid=0,nkids-1 do begin
     l = where(finite(data[*].rf_didq[ikid]) eq 0, nl)
     if nl gt 0 then data[l].flag[ikid] += 2l^18
  endfor 
  return
end
