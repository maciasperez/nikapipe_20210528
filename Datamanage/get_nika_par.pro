pro get_nika_par,  hpar1, pars
 nlines =  n_elements(hpar1)
 idx =  0
 result = -1
 while result eq -1 do begin 
   Result = STRPOS(hpar1[idx], 'param')
   idx += 1
 endwhile 

 str = ' pars =  { '
 for iset = idx, nlines-3 do begin
    mpos = STRPOS(hpar1[iset], '=')
    var = strmid(hpar1[iset], 0, mpos-1)
    str =  str + var + ':' +  string(sxpar(hpar1, var)) + ','
 ;   print, str
 endfor
 mpos = STRPOS(hpar1[iset], '=')
 var = strmid(hpar1[iset], 0, mpos-1)
 str =  str + var + ':' + string(sxpar(hpar1, var)) +  '}'
 Result = EXECUTE(str) 
return
end
