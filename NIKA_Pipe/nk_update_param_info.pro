;+
;
; SOFTWARE:
;
; NAME: 
; nk_update_param_info
;
; CATEGORY: general
;
; CALLING SEQUENCE:
;  nk_update_param_info, scan, param, info, focus_liss_new, xml=xml, katana=katana
;
; PURPOSE: 
;        Updates param and info with relevant scan information
; 
; INPUT: 
;      - param, info
;      - scan: e.g '20140219s205'
;      - focus_liss_new: (temporary) set to 1 if multiple subscans in a
;        focus_liss scan
; 
; OUTPUT: 
;     - param and info are updated
; 
; KEYWORDS:
;     - katana, xml
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - March 27th, 2015: NP, merged nk_update_scan_param and
;          nk_update_scan_info to cope with different nasmyth offsets during
;          Run11 that imply different kidpars.
;-
;================================================================================================

pro nk_update_param_info, scan, param, info, xml=xml, katana=katana, silent=silent, $
                          raw_acq_dir=raw_acq_dir, preproc_copy=preproc_copy

if n_params() lt 1 then begin
   message,  /info,  "Calling sequence:"
   print, "nk_update_param_info, scan, param, info, xml=xml, katana=katana, silent=silent, $"
   print, "                      raw_acq_dir=raw_acq_dir"
   return
endif

if defined(param) eq 0 then nk_default_param, param
if defined(info)  eq 0 then nk_default_info,  info

if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif
scan2daynum, scan, day, scan_num

;; Pipeline version and repo
;nk_get_svn_rev, rev
;param.svn_rev = rev
param.pipeline_dir = !nika.pipeline_dir

nk_scan2run, scan, run
;message, /info, !nika.raw_acq_dir
fill_nika_struct, run

if keyword_set(raw_acq_dir) then !nika.raw_acq_dir = raw_acq_dir
param.raw_acq_dir = !nika.raw_acq_dir


if run le 5 then param.math = "RF"

param.scan = strtrim(scan,2)
param.day  = day
param.scan_num = scan_num
if keyword_set(silent) then param.silent=1

;; LP modif, 16 March 2021
;; default
readdata = 1
if keyword_set(preproc_copy) then begin
   preproc_data_file = param.preproc_dir+"/data_"+strtrim(param.scan,2)+".save"
   if file_test(preproc_data_file) then begin
      readdata = 0
      message, /info, "param.preproc_copy = 1 => restoring "+preproc_data_file+"..."
      restore, preproc_data_file

      info                = info_preproc
      param.data_file     = param_preproc.data_file
      param.file_imb_fits = param_preproc.file_imb_fits
      param.xml_file      = param_preproc.xml_file

      param.output_dir = param.project_dir+"/v_"+strtrim(param.version,2)+"/"+strtrim(param.scan,2)
      ;; param.bp_file    = param.project_dir+"/UP_files/BP_"+scan+".dat"
      ;; param.ok_file    = param.project_dir+"/UP_files/OK_"+scan+".dat"
      spawn, "mkdir -p "+param.output_dir
  
      ;; If param.map_center_ra has already been defined, it is not
      ;; overwritten.
      ;; (in case we project several "subfields" onto a larger "field")
      if finite(param.map_center_ra) eq 0 then begin
         param.map_center_ra  = info.longobj
         param.map_center_dec = info.latobj
      endif

   endif
   ;; else no preproc_data_file found: nothing to do
endif

if readdata gt 0 then begin
;; end LP modif, 16 March 2021
   nk_find_raw_data_file, scan_num, day, file, imb_fits_file, xml_file, $
   SILENT=param.SILENT, NOERROR=param.NOERROR, file_found=file_found, $
   raw_acq_dir=raw_acq_dir, uncompressed=param.uncompressed
   
if file eq "" then begin
   nk_error, info, "no data file for scan "+strtrim(day,2)+"s"+strtrim(scan_num,2)
   return
endif
param.data_file     = file
param.file_imb_fits = imb_fits_file
param.xml_file      = xml_file


param.output_dir = param.project_dir+"/v_"+strtrim(param.version,2)+"/"+strtrim(param.scan,2)
;; param.bp_file    = param.project_dir+"/UP_files/BP_"+scan+".dat"
;; param.ok_file    = param.project_dir+"/UP_files/OK_"+scan+".dat"
spawn, "mkdir -p "+param.output_dir

info.f_sampling = !nika.f_sampling
info.status   = 0
info.scan     = param.scan
info.day      = param.day
info.scan_num = param.scan_num
info.map_proj = param.map_proj ; for convenience
if param.lab eq 0 and param.make_imbfits eq 0 then begin

   if keyword_set(xml) then begin
      nk_xml2info, param.scan_num, param.day, pako_str, info

      if strupcase( strtrim( pako_str.obs_type, 2)) eq "LISSAJOUS" and $
         strupcase( strtrim(pako_str.purpose,2)) eq "FOCUS" then param.focus_liss_new = 1
   endif else begin
      
      if file_test( param.file_imb_fits) then begin
         nk_imbfits2info, param.file_imb_fits, info

         ;; Convert to galactic coordinates the radec in the imbfits
         ;; if necessary
         if param.map_proj eq "GALACTIC" then begin
            euler, info.longobj, info.latobj, glon_center, glat_center, 1
            info.longobj = glon_center
            info.latobj  = glat_center
         endif
         
         ;; If param.map_center_ra has already been defined, it is not
         ;; overwritten.
         ;; (in case we project several "subfields" onto a larger "field")
         if finite(param.map_center_ra) eq 0 then begin
            param.map_center_ra  = info.longobj
            param.map_center_dec = info.latobj
         endif

      endif else begin
         if param.accept_no_imbfits eq 0 then begin
            nk_error, info, "No antenna imbfits"
            return
         endif
      endelse
      
   endelse

endif

endif ;; LP modif

if param.force_kidpar eq 0 and (not keyword_set(katana)) then begin
   nk_get_kidpar_ref, scan_num, day, info, kidpar_file, corr_file = corr_file, /noread
   param.file_kidpar = kidpar_file
   param.file_ptg_photo_corr= corr_file
; testing with:
;      param.file_ptg_photo_corr= '$NIKA_SOFT_DIR/Pipeline/Datamanage/Logbook/' + $
;        'Log_Iram_corr_N2R12_v0.csv'
   ;; check here to save time :)
   if file_test( param.file_kidpar) eq 1 then $
      kidpar = mrdfits( kidpar_file, 1, /silent)
   gk = where( kidpar.type eq 1 and $
               kidpar.c0_skydip lt 0 and $
               kidpar.c1_skydip gt 0, ngk)
   if ngk eq 0 and param.do_opacity_correction ge 1 and param.skydip eq 0 and param.rta eq 0 then begin
      txt = "all kids have skydip C0 and C1 = 0, " + $
            "you must set param.do_opacity_correction = 0 to process this scan."
      nk_error, info, txt
      return
   endif
   
endif else begin  ; FXD added that March 2018
   if file_test( param.file_kidpar) eq 1 then $
      kidpar = mrdfits( param.file_kidpar, 1, /silent)
endelse
if file_test( param.file_kidpar) ne 1 and (not keyword_set(katana)) then begin
   nk_error, info, 'Kidpar '+strtrim(param.file_kidpar,2)+ $
             ' not available on this disk ? Check your !nika.off_proc_dir'
   return
endif

; FXD and NP added that in March 2018
if param.do_fpc_correction eq 2 then begin
   if file_test( param.file_ptg_photo_corr) then begin
      nk_read_csv_3, param.file_ptg_photo_corr, corr
      isc = where(strmatch( strtrim(corr.day, 2)+'s'+strtrim( corr.scannum,2), $
                       param.scan),nist)
      ;; Apply pointing correction
      param.fpc_az = corr[ isc].ncx
      param.fpc_el = corr[ isc].ncy
;     print, param.fpc_az, param.fpc_el
      ;; Update photometric correction in nk_update_kidpar
   endif else message, /info, 'No pointing/photometric correction file available= -'+ $
                       param.file_ptg_photo_corr+'-'
endif



;; Quick fix
param.source = info.object

;; Get the unit conversions relevant to this scan
nk_get_unit_conv, param, MAKE_UNIT_CONV=MAKE_UNIT_CONV

end
