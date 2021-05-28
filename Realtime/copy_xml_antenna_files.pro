
;; xml and AntennaIBMfits files are transfered when nk_rta is called.
;; If for some reason, a scan is not reduced in realtime, these files
;; are therefore not transfered by default.
;;
;; This scripts copies all of them

pro copy_xml_antenna_files

day_list = '201510'+string( [7,8,9,10,11], format="(I2.2)")

;;--------------------------------------------------------------------
ndays = n_elements(day_list)
for iday=0, ndays-1 do begin
   spawn, "scp t22@150.214.224.59:/ncsServer/mrt/ncs/data/"+day_list[iday]+"/scans/*/iram*xml $XML_DIR/."
   spawn, "scp t22@150.214.224.59:/data/ncs/data/"+day_list[iday]+"/scans/*/*antenna*fits $IMB_FITS_DIR/."
endfor

end
