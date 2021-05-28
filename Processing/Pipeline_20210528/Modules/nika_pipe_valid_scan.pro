
;; Keep only the fraction of the scan with scan_valid at 0

pro nika_pipe_valid_scan, param, data, kidpar

w = where( data.scan_valid[0] eq 0 and data.scan_valid[1] eq 0, nw)
if nw eq 0 then begin
   message, /info, "No sample with data.scan_valid=0 ?!"
   stop
endif else begin
   data = data[w]
endelse

end
