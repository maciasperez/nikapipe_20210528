;+
;PURPOSE: Change the sampling frequency by averaging the data over a
;         given number of points
;
;INPUT: The data structures and the number of point over which to average
;
;OUTPUT: The data structure with less points
;
;LAST EDITION: 08/02/2013: creation(adam@lpsc.in2p3.fr)
;-

function nika_pipe_rmpoints, data, nb

  index0 = indgen(n_elements(data))
  index1 = indgen(n_elements(data)/nb)*nb
  !nika.f_sampling /= nb

  tags  = tag_names(data)
  ntags = n_elements(tags)
  for itag=0, ntags-1 do begin
     cmd = "arr0 = data."+tags[itag]
     junk = execute(cmd)
     dim = (size(arr0))[0]
     nx = (size(arr0))[1]
     if dim eq 2 then begin
        ny = (size(arr0))[2]
        ind0 = replicate(1, ny) # index0
        ind1 = replicate(1, ny) # index1
     endif else begin
        ind0 = index0
        ind1 = index1
     endelse

     arr1 = interpol(arr0, ind0, ind1)

     if strupcase(tags[itag]) eq 'SUBSCAN' or $
        strupcase(tags[itag]) eq 'SCAN' or $
        strupcase(tags[itag]) eq 'SCAN_ST' or $
        strupcase(tags[itag]) eq 'SAMPLE' or $
        strupcase(tags[itag]) eq 'A_MASQ' or $
        strupcase(tags[itag]) eq 'B_MASQ' or $
        strupcase(tags[itag]) eq 'C_POSITION' or $
        strupcase(tags[itag]) eq 'C_SYNCHRO' then arr1 = long(arr1)

     if itag eq 0 then begin
        cmd = "data_out = {"+tags[itag]+":arr1}"
        junk = execute(cmd)
     endif else begin
        cmd = "new_struct = {"+tags[itag]+":arr1}"
        junk = execute(cmd)
        upgrade_struct, data_out, new_struct, data_out2
        data_out = data_out2
     endelse
  endfor

  return, data_out
end
