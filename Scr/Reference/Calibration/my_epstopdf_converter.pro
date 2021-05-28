pro my_epstopdf_converter, outfile

  spawn, 'which epstopdf', res1
  spawn, 'which epspdf', res2
  vazy = 1
  cmd=''
  if strlen( strtrim(res2, 2)) gt 0 then cmd = 'epspdf --bbox' else $
     if strlen( strtrim(res1, 2)) gt 0 then cmd = 'epstopdf' else begin
     for i=0,10 do print,''
     print, '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
     print, 'missing a tool to convert eps file to pdf file'
     print, '.c to continue'
     vazy=0
     stop
  endelse
  if vazy then spawn, cmd+' '+outfile+'.eps'
  ;;print, cmd+' '+outfile+'.eps'
end
