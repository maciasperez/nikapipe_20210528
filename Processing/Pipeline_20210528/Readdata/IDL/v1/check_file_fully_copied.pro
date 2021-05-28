pro check_file_fully_copied, file
 
 filelock = 1
res0 = -1
counter = 0
 while(filelock eq 1) do begin
    spawn, 'ls -s '+file,  res, /sh
    res =  double((strsplit(res,  /extract))[0])
;    print,  res,  res0
    if (res gt res0 or res lt 0.1) then begin

       res0 = res 
    endif else begin
       counter =  counter + 1
       if counter gt 2 then filelock = 0
    endelse
    wait,  1
 endwhile
 ;; dir =  file_dirname(file) +"/"
 ;; fname = file_basename(file)
 ;; while(filelock eq 1) do begin
 ;;    spawn, 'ls '+dir+"F_"+fname,  res, /sh

 ;;    if (strlen(res) gt 0) then begin
 ;;       filelock = 0
 ;;    endif else begin
 ;;       wait,  1
 ;;    endelse
 ;; endwhile

 return
end
