function convert_toc_string,input

thename=string(input)
;thename_out=BYTARR(128)
thename_out=BYTARR(1024)
thename_out(*)=0
if (N_ELEMENTS(thename) GT 0) THEN if (STRLEN(thename) GT 0) THEN $
  thename_out(0:STRLEN(thename)-1)=BYTE(thename)

return,thename_out
end
