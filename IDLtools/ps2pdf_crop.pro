;+
;PURPOSE: Convert a ps file to a pdf file and crop the result image
;
;INPUT: The name of the file without extension
;
;LAST EDITION: 06/02/2014: creation (adam@lpsc.in2p3.fr)
;-

pro ps2pdf_crop, file
  
  spawn, 'hostname', hostname
  Nocrop = 'no'
  if STRCMP(hostname, 'lpsc-c', 6) eq 1 then Nocrop = 'yes'
  if hostname eq 'cosmos-2.oca.eu' then Nocrop = 'yes'
  if hostname eq 'logincosmos.oca.eu' then Nocrop = 'yes'

  spawn, 'ps2pdf '+file+'.ps '+file+'.pdf'
  spawn, 'rm -f '+file+'.ps'
  if Nocrop eq 'no' then begin
     spawn, "pdfcrop -margins 5 "+file+'.pdf', junk
     spawn, 'rm -f '+file+'.pdf'
     spawn, 'mv '+file+'-crop.pdf '+file+'.pdf
  endif
  
  return
end
