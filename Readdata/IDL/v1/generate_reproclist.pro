pro generate_reproclist, flist
; Small program to create 'F_' files
; to be used if one wants to redo nika_filing aka
;    convert_rawdata2imbfits
; First should generate a list of Y33 files to be reprocessed including the
; full directory e.g. 
;   dir_file = '/home/archeops/NIKA/Data/raw_Y33/Y33_2013_06_13'
;   ls_unix, '-1 '+dir_file, fonlist
;   generate_reproclist, dir_file+ '/'+ fonlist
for ifl = 0,  n_elements( flist)-1 do begin
   dirin = file_dirname( flist[ ifl])
   filebase = file_basename( flist[ ifl])
   fout = dirin + '/' + 'F_' + strmid( filebase,  2)
   command = 'touch '+ fout
   spawn, command
endfor
return
end
