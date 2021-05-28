
;+
;
; SOFTWARE: NIKA pipeline / Real time analysis
;
; NAME: 
; geom_prepare_toi_parall
;
; CATEGORY:
;
; CALLING SEQUENCE:
; 
; PURPOSE:
; Processes raw TOIs to produce individual kid maps
; 
; INPUT: 
;
; OUTPUT: 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - July 2016, NP: from IDLtools/nk_otf_geometry_bcast_data.pro
;          that was a subroutine of make_geometry_4.
;-
;================================================================================================

pro auto_prepare_toi_parall, scan_list, toi_dir, maps_dir, nickname, nproc=nproc, $
                             input_kidpar_file = input_kidpar_file, kids_out = kids_out, $
                             reso=reso, preproc=preproc, zigzag=zigzag, gamma=gamma, $
                             sn_min_list=sn_min_list, sn_max_list=sn_max_list, plot_dir=plot_dir, $
                             multiscans=multiscans, decor_method=decor_method
  
for i=0, n_elements(scan_list)-1 do begin
   scan = scan_list[i]
   scan2daynum, scan, day, scan_num
   if file_test(!nika.imb_fits_dir+"/iram30m-antenna-"+scan+"-imb.fits") eq 0 then begin
      message, /info, "copying imbfits file from mrt-lx1"
      spawn, "scp t22@150.214.224.59:/data/ncs/data/"+day+"/scans/"+strtrim(scan_num,2)+"/*antenna*fits $IMB_FITS_DIR/."
   endif
endfor

nscans = n_elements(scan_list)
nsplit = nscans

if keyword_set(noplot) then noplot=1 else noplot=0
if not keyword_set(sn_min_list) then sn_min_list=0
if not keyword_set(sn_max_list) then sn_max_list=0
if keyword_set(zigzag) then zigzag = 1 else zigzag = 0
if keyword_set(kids_out) then kids_out=1 else kids_out=0
if not keyword_set(reso) then reso = 4.d0
if not keyword_set(input_kidpar_file) then input_kidpar_file=0
if not keyword_set(gamma) then gamma = 1d-10
if not keyword_set(nproc) then nproc=0
if not keyword_set(multiscans) then multiscans = 0
if not keyword_set(decor_method) then decor_method = 'common_mode_kids_out'

;; i=0
;; geom_prepare_toi_sub, i, scan_list, toi_dir, maps_dir, nickname, nproc=nproc, $
;;                       noplot=noplot, sn_min_list=sn_min_list, sn_max_list=sn_max_list, $
;;                       zigzag=zigzag, kids_out=kids_out, reso=reso, $
;;                       input_kidpar_file=input_kidpar_file, gamma=gamma, plot_dir=plot_dir
;; stop

split_for, 0, nscans-1, nsplit=nsplit, $
           commands=['auto_prepare_toi_sub, i, scan_list, toi_dir, maps_dir, nickname, nproc=nproc, '+$
                     'noplot=noplot, sn_min_list=sn_min_list, sn_max_list=sn_max_list, '+$
                     'zigzag=zigzag, kids_out=kids_out, reso=reso, , decor_method=decor_method'+$
                     'input_kidpar_file=input_kidpar_file, gamma=gamma, plot_dir=plot_dir, multiscans=multiscans'], $
           varnames = ['scan_list', 'toi_dir', 'maps_dir', 'nickname', 'nproc', 'noplot', 'sn_min_list', $
                       'sn_max_list', 'zigzag', 'kids_out', 'reso', 'decor_method', 'input_kidpar_file', 'gamma', 'plot_dir', 'multiscans']

end
