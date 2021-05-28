;+
;PURPOSE: Convert a ps file to a pdf file and crop the result image
;
;INPUT: The name of the file without extension
;
;LAST EDITION: 20/03/2016: creation (ritacco@lpsc.in2p3.fr)
;-

pro pstopdf_crop, file
  
  spawn, 'hostname', hostname
  
  if STRCMP(hostname, 'lpsc-c', 6) eq 1 then atLPSC = 'yes' else atLPSC = 'no'

  spawn, 'ps2pdf '+file+'.ps '+file+'.pdf'
  spawn, 'rm -f '+file+'.ps'
  if atLPSC eq 'no' then begin
     spawn, "pdfcrop -margins 5 "+file+'.pdf', junk
     spawn, 'rm -f '+file+'.pdf'
     spawn, 'mv '+file+'-crop.pdf '+file+'.pdf
  endif
  
  return
end
