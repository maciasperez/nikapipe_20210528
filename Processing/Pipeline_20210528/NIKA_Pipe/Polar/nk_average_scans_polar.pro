;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: nk_average_scans_polar
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         nk_average_scans_polar, info_in, info_out
; 
; PURPOSE: 
;        Averages several scan into a single 1mm map and a single 2mm
;        map. It doesn the same as nk_data_coadd and nk_coadd2maps, but it
;        works with pre-processed data stores on the disk.
; 
; INPUT: 
;        - info_in: the structure containing the weightd coadded maps
; 
; OUTPUT: 
;        - info_out: info_out.map_1mm, info_out.map_q_1mm,
;          info_out.map_u_1mm, info_out.2mm, info_out.map_q_2mm,
;          info_out.map_u_2mm, info_out.map_var_1mm,
;          info_out.map_var_2mm
; 
; KEYWORDS:plot
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - June 13th, NP
;-

pro nk_average_scans_polar, scan_list, param, info, output_maps, plot=plot

if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

nscans     = n_elements(scan_list)

;; Init
coadd_1mm   = info.coadd_1mm   *0.d0
coadd_q_1mm = info.coadd_q_1mm *0.d0
coadd_u_1mm = info.coadd_u_1mm *0.d0
coadd_2mm   = info.coadd_1mm   *0.d0
coadd_q_2mm = info.coadd_q_1mm *0.d0
coadd_u_2mm = info.coadd_u_1mm *0.d0
nhits_1mm   = info.coadd_1mm   *0.d0
nhits_2mm   = info.coadd_1mm   *0.d0
w8_1mm      = info.coadd_1mm   *0.d0
w8_2mm      = info.coadd_1mm   *0.d0

for iscan=0, nscans-1 do begin
   dir = !nika.plot_dir+"/Pipeline/scan_"+strtrim( scan_list[iscan], 2)
   file_save = dir+"/results.save"

   if file_test(file_save) eq 1 then begin
      restore, file_save
      
      ;; Check that the results were computed with the correct parameters
      r = nk_compare_params( param, param1)
      if r ne 0 then begin
         nk_error, info, "param1 does not match param for scan "+strtrim(param1.scan,2)
         return
      endif

      ;; Check that intermediate products match (mask_source...)
      r = nk_compare_infos( info, info1)
      if r ne 0 then begin
         nk_error, info, "info1 does not match info for scan "+strtrim(param1.scan,2)
         return
      endif

      w = where( info1.map_w8_1mm ne 0, nw)
      if nw ne 0 then begin
         coadd_1mm[  w] += info1.coadd_1mm[  w]
         coadd_q_1mm[w] += info1.coadd_q_1mm[w]
         coadd_u_1mm[w] += info1.coadd_u_1mm[w]
         w8_1mm[     w] += info1.map_w8_1mm[ w]
         nhits_1mm[  w] += info1.nhits_1mm[  w]
      endif
      w = where( info1.map_w8_2mm ne 0, nw)
      if nw ne 0 then begin
         coadd_2mm[  w] += info1.coadd_2mm[  w]
         coadd_q_2mm[w] += info1.coadd_q_2mm[w]
         coadd_u_2mm[w] += info1.coadd_u_2mm[w]
         w8_2mm[     w] += info1.map_w8_2mm[ w]
         nhits_2mm[  w] += info1.nhits_2mm[  w]
      endif
   endif
endfor

;; Normalize raw coaddition by weights
nk_coadd2maps, param, info, coadd_1mm,   w8_1mm, map_1mm,   map_var_1mm
nk_coadd2maps, param, info, coadd_q_1mm, w8_1mm, map_q_1mm, map_var_1mm
nk_coadd2maps, param, info, coadd_u_1mm, w8_1mm, map_u_1mm, map_var_1mm
nk_coadd2maps, param, info, coadd_2mm,   w8_2mm, map_2mm,   map_var_2mm
nk_coadd2maps, param, info, coadd_q_2mm, w8_2mm, map_q_2mm, map_var_2mm
nk_coadd2maps, param, info, coadd_u_2mm, w8_2mm, map_u_2mm, map_var_2mm


;; Update output structure
output_maps = {map_1mm:map_1mm,$
               map_q_1mm:map_q_1mm,$
               map_u_1mm:map_u_1mm,$
               map_2mm:map_2mm, $
               map_q_2mm:map_q_2mm, $
               map_u_2mm:map_u_2mm,$
               map_var_1mm:map_var_1mm, $
               map_var_2mm:map_var_2mm, $
               nhits_1mm:nhits_1mm, $
               nhits_2mm:nhits_2mm, $
               xmap:info.xmap, $
               ymap:info.ymap}

if keyword_set(plot) then begin
wind, 1, 1, /free, /large
my_multiplot, 3, 2, pp, pp1
imview, output_maps.map_1mm,          xmap=info.xmap, ymap=info.ymap, title = '1mm', $
        position=pp1[0,*], imrange=[-1,1]
imview, output_maps.map_q_1mm,        xmap=info.xmap, ymap=info.ymap, title = 'Q_1mm',$
        position=pp1[1,*],imrange=[-1,1]*0.5, /noerase
imview, output_maps.map_u_1mm,        xmap=info.xmap, ymap=info.ymap, title = 'U_1mm',$
        position=pp1[2,*],imrange=[-1,1]*0.5, /noerase
imview, output_maps.map_2mm,          xmap=info.xmap, ymap=info.ymap, title = '2mm', $
        position=pp1[3,*],imrange=[-1,1], /noerase
imview, output_maps.map_q_2mm,        xmap=info.xmap, ymap=info.ymap, title = 'Q_2mm',$
        position=pp1[4,*],imrange=[-1,1]*0.06, /noerase
imview, output_maps.map_u_2mm,        xmap=info.xmap, ymap=info.ymap, title = 'U_2mm',$
        position=pp1[5,*],imrange=[-1,1]*0.06, /noerase
endif


;; Create output directory
;; output_dir = !nika.plot_dir+"/Pipeline/scan_"+strtrim(param.scan,2)
;; spawn, "mkdir -p "+output_dir

;; Change names of variables for easier comparison to the current ones
;; when we restore them
;; param1  = param
;; output_maps1   = output_maps
;; kidpar1 = kidpar

;; cmd = "save, file=output_dir+'/total_maps.save', param1, output_maps1, kidpar1"
;; if keyword_set(map_1mm)   then cmd = cmd+", map_1mm"
;; if keyword_set(map_q_1mm) then cmd = cmd+", map_q_1mm"
;; if keyword_set(map_u_1mm) then cmd = cmd+", map_u_1mm"
;; if keyword_set(map_2mm)   then cmd = cmd+", map_2mm"
;; if keyword_set(map_q_2mm) then cmd = cmd+", map_q_2mm"
;; if keyword_set(map_u_2mm) then cmd = cmd+", map_u_2mm"
;; junk = execute(cmd)

end
