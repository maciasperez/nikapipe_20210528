pro fourier_line_filter, fsampling, data, list_lines, dataclean, check = check


; if not keyword_set then begin 
  ndata = n_elements(data)
  n2 = n_elements(data)/2
  fr  = dindgen(n2+1)/double(n2) * fsampling/2.0
;  stop
  if ((ndata mod 2) eq 0) then fr=[fr, -1*reverse(fr[1:n2-1])]
  if ((ndata mod 2) eq 1) then fr=[fr, -1*reverse(fr[1:*])]
;endif 
 
  df  = fft(data,1)
  
  s = size(list_lines)
  nlines = s[2]
  for iline=0,nlines-1 do begin
     listf = where(abs(fr) ge list_lines[0,iline] and abs(fr) le list_lines[1,iline],nlistf)
     if nlistf gt 0 then df[listf]=0.0
;     stop
  endfor
  dataclean = double(fft(df,-1))
  
  if keyword_set(check) then begin
     power_spec, data,fsampling,pw,freq
     power_spec, dataclean,fsampling,pwclean,freq
     !p.multi=[0,1,nlines]
     for iline=0,nlines-1 do begin 
      plot, freq, pw, /xs, /ys, xr= reform(list_lines[*,iline],2) +[-0.3,0.3]
      oplot, freq, pwclean, col=250
     endfor
      stop
     !p.multi = 0
  endif

  return
end
