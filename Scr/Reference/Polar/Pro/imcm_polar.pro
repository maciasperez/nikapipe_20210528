
;; Choose your source
; source = 'IRAS4A'
;source = 'OMC-1'
; source = 'CRAB'
 source = 'DR21OH'

;; First and last iterations that you want to do
iter_min = 0
iter_max = 3

;; Set to process to 1 to actually reduce the data
;; Set it to 0 to bypass processing and directly plot results
process = 1

;; Set to 1 to produce the preprocessed data
;; set to 0 once this is done to save time.
reset_preproc_data = 1

;; Restore the logbook to select scans
restore, !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R46_v0.save"
db_scan = scan
w = where( db_scan.object eq strupcase(source), nw)
scan_list = db_scan[w].day+"s"+strtrim(db_scan[w].scannum,2)
scan_list = scan_list[where(scan_list ne '20201113s1' and scan_list ne '20201112s205')]
if strupcase(source) eq "DR21OH" then begin
   ;; restrict to the nicest scans to save time
   scan_list = scan_list[0:8]
   ;; remove one problematic scan (should be able to cure it though, 
   ;; with a bit more efforts)
   scan_list = scan_list[ where( scan_list ne '20201112s207')]
endif

nscans = n_elements(scan_list)

;; Display color scales
imrange_i = [-1,1]/2.
imrange_q = [-1,1]/100.
imrange_u = [-1,1]/100.
imrange_i_tot = imrange_i ; default
if strupcase(source) eq "OMC-1" then imrange_i_tot=[-1,3]

;; Define the list of scans to pass to the pipeline
scan_list_file = 'junk_scan_list.dat'
openw, 1, scan_list_file
for i=0, nscans-1 do printf, 1, scan_list[i]
close, 1

;;  You may change "ext", this is the root directory that will contain
;;  all the scan maps and the combined maps
ext = 'imcm'

;; For high SNR sources, we need a high SNR threshold for the mask
snr_thres_1mm = 20
boost = 0

;; Use this method for now
method_num = 676

;; Define the pipeline input txt file
input_txt_file = "./imcm_input_"+strtrim(method_num,2)+".txt"
spawn, "cp "+!nika.pipeline_dir+"/IMCM/imcm_template.txt ./"+input_txt_file
openw, 1, input_txt_file, /append
printf, 1, "ext = '"+ext+"'"
if defined(undersamp) then printf, 1, "undersamp = "+strtrim(undersamp,2)
printf, 1, "method_num = "+strtrim(method_num,2)
printf, 1, "polar = 1"          ; to save time and memory
printf, 1, "reset_preproc_data = "+strtrim(reset_preproc_data,2)
printf, 1, "mask_default_radius = 80"
printf, 1, "source = '"+strupcase(source)+"'"
printf, 1, "iter_min = "+strtrim( iter_min, 2)
printf, 1, "iter_max = "+strtrim( iter_max, 2)
printf, 1, "new_snr_mask_method = 1"
printf, 1, "snr_thres_1mm = "+strtrim(snr_thres_1mm,2)
printf, 1, "boost="+strtrim(boost,2) ; to avoid pb with histo fit with diffuse signal in nk_bg_var_map
;; no mask accounted for in nk_get_hwpss_sub_1 for now
printf, 1, "force_subtract_hwp_per_subscan = 1"
printf, 1, "hwp_harmonics_only = 0"
printf, 1, "decor_qu = 0"
close, 1

if process eq 1 then imcm, input_txt_file, scan_list_file

;; Check all scans one by one
readcol, scan_list_file, scan_list, format='A', /silent
nscans = n_elements(scan_list)

@read_imcm_input_txt_file.pro
for iter=0, iter_max do begin
;; for iter=iter_max, iter_max do begin
   dir = param.project_dir+"/iter"+strtrim(iter,2)
   wind, 1, 1, /free, /large
   my_multiplot, 1, 1, ntot=nscans, pp, pp1, /rev, /full, /dry
   for iscan=0, nscans-1 do begin
      restore, dir+"/v_1/"+scan_list[iscan]+"/results.save"
      dp = {noerase:1, coltable:39, xmap:grid1.xmap, ymap:grid1.ymap, nobar:1, $
            c_colors:255, contour:grid1.mask_source_1mm, cont_header:header}

      himview, grid1.map_i_1mm, header, dp=dp, position=pp1[iscan,*], imrange=[-1,1]/5., title='I 1mm' ;imrange_i
      legendastro, ["iter "+strtrim(iter,2), scan_list[iscan]]
   endfor
endfor

;; Display IQU maps per iteration
@read_imcm_input_txt_file.pro
for iter=0,iter_max do begin
   nk_fits2grid, param.project_dir+"/iter"+strtrim(iter,2)+"/map.fits", grid, header
   subfile = param.project_dir+"/subtract_maps_"+strtrim(iter-1,2)+".save"

   wind, 1, 1, /free, /large
   phi = dindgen(360)*!dtor
   r_fov = 6.5*60./2
   
   my_multiplot, 3, 2, pp, pp1, /rev
   dp = {noerase:1, coltable:39, xmap:grid.xmap, ymap:grid.ymap, fwhm_arcsec:3., $
         c_colors:0, contour:grid.mask_source_1mm, cont_header:header}
   delvarx, contour

   himview, grid.map_i_1mm, header, dp=dp, $
            position=pp[0,0,*], title='I 1mm iter'+strtrim(iter,2), imrange=imrange_i, /nobar
   ra_c = sxpar(header,'crval1')
   dec_c = sxpar(header,'crval2')
   extast, header, astr
   ad2xy, ra_c, dec_c, astr, xc, yc
   oplot, xc + r_fov*cos(phi)/grid.map_reso, yc + r_fov*sin(phi)/grid.map_reso, line=2, col=255
   oplot, xc + param.mask_default_radius*cos(phi)/grid.map_reso, yc + param.mask_default_radius*sin(phi)/grid.map_reso, col=255
   
   if tag_exist( grid, 'map_q_1mm') then begin
      himview, grid.map_q_1mm, header, charsize=1d-10, fwhm=3., $
               dp=dp, position=pp[1,0,*], title='Q 1mm', imrange=imrange_q
      oplot, r_fov*cos(phi), r_fov*sin(phi), line=2, col=255
      oplot, param.mask_default_radius*cos(phi), param.mask_default_radius*sin(phi), col=255

      himview, grid.map_u_1mm, header, fwhm=3., charsize=1d-10, $
               dp=dp, position=pp[2,0,*], title='U 1mm', imrange=imrange_q, /nobar
      oplot, r_fov*cos(phi), r_fov*sin(phi), line=2, col=255
      oplot, param.mask_default_radius*cos(phi), param.mask_default_radius*sin(phi), col=255
      himview, grid.map_i_1mm, header, dp=dp, $
               position=pp[0,1,*], title='I 1mm', imrange=imrange_i_tot
   endif
endfor
;; xyouts, 0.5, 0.35, "force_subtract_hwp_per_subscan = "+strtrim(force_subtract_hwp_per_subscan,2), /norm
;; xyouts, 0.5, 0.3, "hwp_harmonics_only = "+strtrim(hwp_harmonics_only,2), /norm
;; xyouts, 0.5, 0.25, "decor_qu = "+strtrim(decor_qu,2), /norm

end
