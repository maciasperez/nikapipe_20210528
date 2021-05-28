
nk_init, '20140219s205', param, info, /force

nk_getdata, param, info, data, kidpar


;; check
nika_pipe_default_param, 205, 20140219, param
nika_pipe_getdata, param, data1, kidpar1, /pf

;; Compare toi (in PF mode because it's the default of nk_getdata
print, "minmax( data.toi - data1.toi): ", minmax( data.toi - data1.toi)

;; Compare kidpars
help, kidpar, kidpar1
tags = tag_names(kidpar)
ntags = n_elements( tags)
for j=0, ntags-1 do begin
   type = size( kidpar[0].(j), /type)
   
   for i=0, n_elements(kidpar)-1 do begin
      err_mess = "error in kidpar for kid "+strtrim(i,2)+" and tag "+strtrim(j,2)
      
      if type eq 7 then begin
         if strupcase( strtrim( kidpar[i].(j))) ne strupcase( strtrim( kidpar1[i].(j))) then begin
            print, err_mess
            stop
         endif
      endif else begin
         if finite( kidpar[i].(j)) and finite( kidpar1[i].(j)) then begin
            if kidpar[i].(j) ne kidpar1[i].(j) then begin
               print, err_mess
               stop
            endif
         endif
      endelse
   endfor
endfor

end
