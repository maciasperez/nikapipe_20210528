pro check_file_isthere,  file
  available = 0
  while( available eq 0) do begin
     spawn,  'ls '+ file,  res, dummy, /sh
;     stop
     if not strcmp(strtrim(res[0]), "") then available = 1
  endwhile

  return
end
