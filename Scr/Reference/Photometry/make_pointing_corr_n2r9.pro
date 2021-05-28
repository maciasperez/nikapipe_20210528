; N2R9
; Compute a file to correct pointing and photometry
; March 2018

; Init scans
;;; @make_pointing_corr_n2r9_add1.pro
; In emacs:
@make_pointing_corr_n2r9_add1.scr

; First run to be edited!!!!!!!!!!
; Heavy first computation
nba = 15
split_for, 0, nba-1, nsplit=nba, $
                 commands=['make_pointing_corr_n2r9_split1, i']
; done with PF, and no gain elevation curve


;-----------------------------------------------------
; Compute the correction table for all scans
corr = replicate({DAY:'', SCANNUM:0, fpaz:0., fpel:0., ncx:0., ncy:0., $
                  fwhm1:-1., fwhm2:-1., peak1:0., peak2:0., $
                  flux1:0.,  flux2:0., $
                  fcorr1:1., fcorr2:1.}, $
                 n_elements( scanall))
corr.day = scanall.day
corr.scannum = scanall.scannum
corr.fpaz = !values.f_nan
corr.fpel = !values.f_nan
; Retrieve the v1 pointing corrections
nk_default_param, param
param.version = '2' ; '2' without correction, '3' after correction
for isc = 0, nscans-1 do begin
   param.project_dir = param.dir_save+ '/All'
   outdir = param.project_dir+"/v_"+strtrim(param.version,2)+ $
            "/"+strtrim(scan_list[ isc],2)
   nk_read_csv_2, outdir+'/info.csv', info1
   corr[ indscan[ isc]].fpaz = info1.result_off_x_2mm ; take the 2mm values
   corr[ indscan[ isc]].fpel = info1.result_off_y_2mm
   corr[ indscan[ isc]].fwhm1 = info1.result_fwhm_1mm
   corr[ indscan[ isc]].fwhm2 = info1.result_fwhm_2mm
   corr[ indscan[ isc]].flux1 = info1.result_flux_center_I_1mm
   corr[ indscan[ isc]].flux2 = info1.result_flux_center_I_2mm
endfor
u = where( corr[indscan].fpaz eq 0., nu) &  print, nu,  ' should be 0'
corr.fpaz = last_known_value( corr.fpaz)
corr.fpel = last_known_value( corr.fpel)
; Save result
sav = 'v2'
filout = '$NIKA_SAVE_DIR/Log_Iram_tel_Pointing_corr_' + sav + '.save'
save, file = filout, corr, /verb, /xdr
;-------------------------------------------

; Init scans
;;;;@make_pointing_corr_n2r9_add1.pro
; In emacs:
@make_pointing_corr_n2r9_add1.scr

; Heavy second computation
nba = 15
split_for, 0, nba-1, nsplit=nba, $
                 commands=['make_pointing_corr_n2r9_split2, i']
; done with PF, and no gain elevation curve
;------------------------------------------------------

; Here to make corr v3
; Study of flux correction
prepare_jpgout, 1, ct = 39, /norev, /icon
prepare_jpgout, 2, ct = 39, /norev, /icon

; Do the init 
@make_pointing_corr_n2r9_add1.scr
;-----------------------------------------------------
; Compute the correction table for all scans
corr = replicate({DAY:'', SCANNUM:0, fpaz:0., fpel:0., ncx:0., ncy:0., $
                  fwhm1:-1., fwhm2:-1., peak1:0., peak2:0., $
                  flux1:0.,  flux2:0., $
                  fcorr1:1., fcorr2:1.}, $
                 n_elements( scanall))
corr.day = scanall.day
corr.scannum = scanall.scannum
corr.fpaz = !values.f_nan
corr.fpel = !values.f_nan
; Retrieve the v1 pointing corrections
nk_default_param, param
v1 = '1' ; '1' without correction, '2' after correction
v2 = '2'
for isc = 0, nscans-1 do begin
   param.project_dir = param.dir_save+ '/All'
   outdir = param.project_dir+'/v_'+v1+$
            "/"+strtrim(scan_list[ isc],2)
   nk_read_csv_2, outdir+'/info.csv', info1
   corr[ indscan[ isc]].fpaz = info1.result_off_x_2mm ; take the 2mm values
   corr[ indscan[ isc]].fpel = info1.result_off_y_2mm
   outdir = param.project_dir+'/v_'+v2+$
            "/"+strtrim(scan_list[ isc],2)
   nk_read_csv_2, outdir+'/info.csv', info1
   corr[ indscan[ isc]].fwhm1 = info1.result_fwhm_1mm
   corr[ indscan[ isc]].fwhm2 = info1.result_fwhm_2mm
   corr[ indscan[ isc]].peak1 = info1.result_peak_1mm
   corr[ indscan[ isc]].peak2 = info1.result_peak_2mm
   corr[ indscan[ isc]].flux1 = info1.result_flux_center_I_1mm
   corr[ indscan[ isc]].flux2 = info1.result_flux_center_I_2mm
endfor
u = where( corr[indscan].fpaz eq 0., nu) &  print, nu,  ' should be 0'
corr.fpaz = last_known_value( corr.fpaz)
corr.fpel = last_known_value( corr.fpel)
; Find the last known value of xoffset at last pointing
xlkv = scanall.xoffset_arcsec*0.+!values.f_nan
xlkv[indscan] = scan.xoffset_arcsec
xlkv = last_known_value( xlkv)
dx = scanall.xoffset_arcsec- xlkv

ylkv = scanall.yoffset_arcsec*0.+!values.f_nan
ylkv[indscan] = scan.yoffset_arcsec
ylkv = last_known_value( ylkv)
dy = scanall.yoffset_arcsec- ylkv

; New correction
; - is correct sign
corr.ncx = corr.fpaz - dx
corr.ncy = corr.fpel - dy
print, stddev( corr.fpaz), stddev( corr.ncx)
print, stddev( corr.fpel), stddev( corr.ncy)
; A decrease of rms is a good sign between 1st and 2nd column
      ;; 3.42233      3.28851
      ;; 3.36273      3.53613

corr.fcorr1 = !values.f_nan
corr.fcorr2 = !values.f_nan
corr[indscan].fcorr1 = $
   (corr[indscan].fwhm1^2+!nika.fwhm_nom[0]^2)/(2*!nika.fwhm_nom[0]^2)
corr[indscan].fcorr2 = $
   (corr[indscan].fwhm2^2+!nika.fwhm_nom[1]^2)/(2*!nika.fwhm_nom[1]^2)
corr.fcorr1 = last_known_value(corr.fcorr1)
corr.fcorr2 = last_known_value(corr.fcorr2)
; Save result
sav = 'v3'  ; v3 is with pointing correction and flux correction
filout = '$NIKA_SAVE_DIR/Log_Iram_tel_Pointing_corr_' + sav + '.save'
save, file = filout, corr, /verb, /xdr


;-------------------------------------------
; Convert that file to a csv
sav = 'v3'  ; v3 is with pointing correction and flux correction
filout = '$SAVE/Log_Iram_tel_Pointing_corr_' + sav + '.save'
filecsv_out = '$NIKA_SOFT_DIR/Pipeline/Datamanage/Logbook/' + $
        'Log_Iram_corr_N2R9_v1.csv'   ; This file is used in nk_get_kidpar_ref
restore, file = filout, /verb
nscan = n_elements( corr)
; Save as a csv file
list = strarr( nscan)
tagn = tag_names( corr)
ntag = n_tags( corr[0])

FOR ifl = 0, nscan-1 DO BEGIN
   bigstr = string( corr[ ifl].(0))
   FOR itag = 1, ntag-1 DO bigstr = bigstr + ' , ' + string( corr[ ifl].(itag))
   list[ ifl] = bigstr
ENDFOR
bigstr = tagn[ 0]
FOR itag = 1, ntag-1 DO bigstr = bigstr + ' , ' + string( tagn[itag])

list = [ bigstr, list]
write_file, filecsv_out, list, /delete
; spawn, 'libreoffice ' + filecsv_out +'&'
end
