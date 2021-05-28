

;; ****** DO NOT RUN THIS UNDER VNC, FOR AN UNKNOWN REASON, SPLIT_FOR
;; KILLS THE VNC SERVER ****************

pro compute_beam_maps, scan_list, iter = iter, input_kidpar_file = input_kidpar_file, $
                       nproc = nproc, beam_maps_dir = beam_maps_dir, reso = reso

if not keyword_set(iter) then iter = 1
if not keyword_set(nproc) then nproc = 16
  
for i=0, n_elements(scan_list)-1 do begin
   scan = scan_list[i]
   scan2daynum, scan, day, scan_num
   if file_test(!nika.xml_dir+"/iram30m-scan-"+scan+".xml") eq 0 then begin
      message, /info, "copying xml file from mrt-lx1"
      spawn, "scp t22@150.214.224.59:/ncsServer/mrt/ncs/data/"+day+"/scans/"+strtrim(scan_num,2)+"/iram*xml $XML_DIR/."
   endif
   if file_test(!nika.imb_fits_dir+"/iram30m-antenna-"+scan+"-imb.fits") eq 0 then begin
      message, /info, "copying imbfits file from mrt-lx1"
      spawn, "scp t22@150.214.224.59:/data/ncs/data/"+day+"/scans/"+strtrim(scan_num,2)+"/*antenna*fits $IMB_FITS_DIR/."
   endif
endfor

if iter gt 1 then kids_out = 1
for iscan=0, n_elements(scan_list)-1 do begin
   compute_kid_maps, scan_list[iscan], nproc=nproc, /noplot, $
                     input_kidpar_file = input_kidpar_file, kids_out = kids_out, $
                     beam_maps_dir = beam_maps_dir, reso = reso
endfor

end
