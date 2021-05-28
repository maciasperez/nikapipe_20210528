

;; Script to rsync the data during our observations while preserving the IRAM bandwidth.
;; Prescription from Carsten Kramer not to exceed 50Mbit/s

pro sftp_data

  message, /info, "NOT WORKING, IMPOSSIBLE TO USE SFTP LIKE SCP"
  return
;;   
;; 
;; scan_dir  = "/home/nika2/NIKA/Data/run13_X/scan_24X"
;; 
;; ;; Data directory
;; nika2_dir = "/home/nika2/NIKA/Data/run13_X/X24_2015_10_17"
;; 
;; mydir     = "$HOME/File_transfer_recap"
;; spawn, "mkdir "+mydir
;; 
;; spawn, "ls "+scan_dir+"/F*", list
;; l1 = strlen("F_2015_10_17_A0_")
;; 
;; 
;; n_ref = 0
;; n = n_ref
;; ;; Every second, I check if a new scan has appeared
;; while n eq n_ref do begin
;; 
;;    ;; Copy F files
;;    spawn, "rsync -avuz "+nika2_dir+"/F* "+mydir+"/."
;;    
;;    ;; List F_ files that tell a scan is done
;;    spawn, "ls "+mydir+"/F*", list
;;    n = n_elements(list)
;; 
;;    ;; Loop over file list to catch up if needed
;;    for ifile=0, n_elements(list)-1 do begin
;; 
;;       ;; Deduce scan from file name
;;       myscan   = strmid( file_basename(list[ifile]), l1, 4)
;;       date     = strmid( file_basename(list[ifile]), 2, 10)
;;       
;;       day      = str_replace(date,"_","",/global)
;;       scan_num = long( myscan)
;;       scan     = day+"s"+strtrim(scan_num,2)
;; 
;;       ;; Check if the file is new and needs to be processed
;;       done_file = mydir+"/D_"+scan
;;       if file_test(done_file) eq 0 then begin
;;          
;;          ;; sftp data
;;          cmd = "sftp "+nika2_dir+"/"+list[ifile]+" archeops@nikaneel.grenoble.cnrs.fr:/Archeops/NIKA2015R13/Data/raw_X24/."
;;          print, "cmd = ", cmd
;; 
;;          ;; sftp antennaIMBfits
;;          if file_test(!nika.imb_fits_dir+"/iram30m-antenna-"+scan+"-imb.fits") eq 0 then begin
;;             message, /info, "copying imbfits file from mrt-lx1"
;;             spawn, "scp t22@150.214.224.59:/data/ncs/data/"+day+"/scans/"+strtrim(scan_num,2)+"/*antenna*fits $IMB_FITS_DIR/."
;;          endif
;;          cmd = "sftp "+!nika.imb_fits_dir+"/iram30m-antenna-"+scan+"-imb.fits archeops@nikaneel.grenoble.cnrs.fr:/Archeops/NIKA2015R13/Data/AntennaImbfits/."
;;          print, "cmd = ", cmd
;; 
;;          ;; sftp Pako's xml
;;          if file_test(!nika.xml_dir+"/iram30m-scan-"+scan+".xml") eq 0 then begin
;;             message, /info, "copying xml file from mrt-lx1"
;;             spawn, "scp t22@150.214.224.59:/ncsServer/mrt/ncs/data/"+day+"/scans/"+strtrim(scan_num,2)+"/iram*xml $XML_DIR/."
;;          endif
;;          cmd = "sftp "+!nika.xml_dir+"/iram30m-scan-"+scan+".xml archeops@nikaneel.grenoble.cnrs.fr:/Archeops/NIKA2015R13/Data/Pako_xml/."
;;          print, "cmd = ", cmd
;; 
;;          ;; Write a 'done' file
;;          spawn, "touch "+done_file
;;          
;;       endif
;;    endfor
;; 
;;    ;; Update n_ref
;;    n_ref = n
;;    
;;    print, "waiting for a new file to appear..."
;;    wait, 1
;; endwhile


end

  
