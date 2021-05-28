;+
; Wrapper to put Run6+ data to Run5 format and use the Run5 modules if necessary
;LAST EDITOR: March, 2013 Nicolas Ponthieu (nicolas.ponthieu@obs.ujf-grenoble.fr)
;-

pro nika_pipe_data2run5, param, data, data_1mm, data_2mm, fits=fits, ext_params=ext_params, nocut=nocut, tau_force=tau_force
;To be used :nika_find_data_file instead of nika_pipe_whichfile

;; List what we want
list_data = "subscan scan el RF_didq retard 49 ofs_az ofs_el paral scan_st"
if keyword_set(ext_params) then begin
   for i=0, n_elements(ext_params)-1 do list_data = list_data+" "+ext_params[i]
endif
params_read = strupcase( strsplit( list_data, " ", /extract))

;; Read data
nika_find_raw_data_file, param.scan_num, param.day, file_scan, imb_fits_file, /silent
param.imb_fits_file = imb_fits_file
rr = read_nika_brute(file_scan, param_c, kidpar, data0, units, $
                     list_data=list_data, read_type=12)
n_pt = n_elements( data0)

if not keyword_set(nocut) then begin
   ;; cut the scan
   nika_pipe_cutscan, data0, loc_ok, type_scan, /safe ;get the valid location of the scan
   param.scan_type = type_scan
   data0 = data0[loc_ok]
endif

scan_here = long( param.scan_num) ;get long('0008') = 8
;; Opacities and units
;;.... Bug in file: take closest scans (until file repaired) ......
if (param.day eq '20121122' and ( long(param.scan_num) ge 78 and long(param.scan_num) le 82)) then scan_here=83


;; Data common to all matrices
el_source = data0.el*!radeg
x_0       = data0.ofs_az * cos(data0.el)
y_0       = data0.ofs_el
copar     = cos(data0.paral)    ;paral = paralactic angle
sipar     = sin(data0.paral)

;; Create one data structure per acquisition box
pos = 0                   ; kid position index
for ibox=0, n_elements( tag_names( param.kid_file))-1 do begin

   ;; Get the kid parameter file
   kidpar_box = mrdfits( param.kid_file.(ibox), 1)

   ;; Unit conversion
   lambda_mm = !const.c*1d-6/param.nu.(ibox)
   nika_pipe_unit_conv, lambda_mm, KRJperKCMB, KCMBperY

   ;; Init the structure command
   cmd  = " data_" +strtrim(ibox,2)+" = {lambda:long(lambda_mm), KRJperKCMB:KRJperKCMB, KCMBperY:KCMBperY"
   cmd1 = " data1_"+strtrim(ibox,2)+" = {lambda:long(lambda_mm), KRJperKCMB:KRJperKCMB, KCMBperY:KCMBperY"
   cmd1 = cmd1 + ", N_pt:N_pt, subscan:data0.subscan, scan_st:data0.scan_st, el_source:el_source, copar:copar, sipar:sipar, ofs_az:x_0, ofs_el:y_0"

   ;; Rearange the data
   nkids_box = n_elements( kidpar_box)
   w_on      = where( kidpar_box.type eq 1, n_on)
   w_off     = where( kidpar_box.type eq 2, n_off)

   if keyword_set(tau_force) then begin
      tau0 = 0.d0
   endif else begin
      message, /info, ""
      message, /info, "opacities in run6 to be written"
      message, /info
   endelse
;;        tau_file = mrdfits(!nika.soft_dir+'/Pipeline/Run5/Calibration/opacity.fits', 1, header)
;;        loc = where(tau_file.day eq param.day and tau_file.scan_num eq scan_here, nloc)
;;        if nloc ne 1 then begin
;;           print, 'Multiple or 0 possible values for tau, STOP!!!'
;;           stop
;;        endif
;;        tau0_a = (tau_file.tau1mm[loc])[0]        
;;        tau0_b = (tau_file.tau2mm[loc])[0]
;;     endelse

   cmd  = cmd  +", kid_on:w_on, kid_off:w_off, n_on:n_on, n_off:n_off, n_kid:nkids_box, kidpar:kidpar_box, tau0:tau0"
   cmd1 = cmd1 +", kid_on:w_on, kid_off:w_off, n_on:n_on, n_off:n_off, n_kid:nkids_box, kidpar:kidpar_box, tau0:tau0"
   for j=0, n_elements(params_read)-1 do begin
      doext = 0
      if params_read[j] eq "RF_DIDQ" or $
         params_read[j] eq "I" or $
         params_read[j] eq "Q" or $
         params_read[j] eq "DI" or $
         params_read[j] eq "DQ" or $
         params_read[j] eq "F_TONE" or $
         params_read[j] eq "DF_TONE" then begin
         
         if params_read[j] eq "RF_DIDQ" then begin
            junk = execute( "TOI = data0."+params_read[j]+"[ pos:pos+nkids_box-1,*]")
            cmd  = cmd  + ", TOI:TOI"
            cmd1 = cmd1 + ", TOI:TOI"
         endif else begin
            junk = execute( params_read[j]+" = data0."+params_read[j]+"[ pos:pos+nkids_box-1,*]")
            cmd  = cmd  + ", "+params_read[j]+":"+params_read[j]
            cmd1 = cmd1 + ", "+params_read[j]+":"+params_read[j]
         endelse
      endif
   endfor

   flag = intarr(nkids_box, n_pt)
   cmd  = cmd  + ", flag:flag"
   cmd1 = cmd1 + ", flag:flag"

   ;; create the data structure for the current box
   junk = execute( cmd +"}")
   junk = execute( cmd1+"}")

   ;; update kid index
   pos += nkids_box
endfor

;; Gathers both structures and common parameters in the output structure

data = {A:data_0, B:data_1, N_pt:N_pt,$
        subscan:data0.subscan, scan_st:data0.scan_st, $
        el_source:el_source, copar:copar, sipar:sipar, ofs_az:x_0, ofs_el:y_0}

if data1_0.lambda eq 1 then begin
   data_1mm = data1_0
   data_2mm = data1_1
endif else begin
   data_1mm = data1_1
   data_2mm = data1_0
endelse


return
end
