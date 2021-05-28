
pro kid_selection, scan_list, maps_output_dir,  kidpars_output_dir, $
                   iter = iter,  keep_neg = keep_neg, input_kidpar_file = input_kidpar_file

  
for iscan = 0, n_elements(scan_list)-1 do begin
   scan = scan_list[iscan]
   spawn, "ls "+maps_output_dir+"/map_list*"+scan+"*.save",  map_list

   nmaps = n_elements(map_list)
   scan2daynum, scan, day, scan_num
   for i=0, nmaps-1 do begin
      print, "**********************"
      print, "i = ", i
      katana_light, scan_num, day, $
                    /absurd, preproc_file=map_list[i], $
                    preproc_index=i, keep_neg = keep_neg, $
                    input_kidpar_file = input_kidpar_file
      spawn, "mv kidpar_"+scan+"_test_"+strtrim(i,2)+".fits "+kidpars_output_dir+"/."
   endfor
;   print,  "scan "+scan+" done. is the next one ready ?"
;   stop
endfor
  
end
