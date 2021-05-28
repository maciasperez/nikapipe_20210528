
pro nika_find_xml_file, scan_num, day, xml_file, silent=silent

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nika_find_xml_file, scan_num, day, xml_file, silent=silent"
   return
endif

cmd = "find "+!nika.xml_dir+" -name '*"+day+"s"+strtrim(scan_num,2)+".xml' -print"
spawn, cmd, xml_file

if xml_file[0] eq "" then begin
;;   message, /info, "-----------------------------------------------------------------------------"
;;   message, /info, "Did not find an xml file for scan "+strtrim(scan_num,2)+", day = "+day
;;   message, /info,  "Try in terminal: scp t21@mrt-lx1:/ncsServer/mrt/ncs/data/"+day+"/scans/"+strtrim(scan_num, 2)+"/iram*xml $XML_DIR/."
;;   message, /info, "then type 'retall' in IDL and relaunch your code."
;;   message, /info, "-----------------------------------------------------------------------------"
;;   message, /info, ""
;;   message, /info, "Did not find an xml file for scan "+strtrim(scan_num,2)+", day = "+day
   ;stop
endif else begin

   ;; Deal with .Appledouble issue
   n = where(file_basename(file_dirname(xml_file)) ne '.AppleDouble' and $
             strmatch(xml_file,'*/._*') ne 1 and $
             strmatch(xml_file, '*~') ne 1)
   xml_file = xml_file[n]
   
   if not keyword_set(silent) then begin
      message, /info, ""
      message, /info, "PaKO XML file found: "+xml_file
   endif

endelse

end
