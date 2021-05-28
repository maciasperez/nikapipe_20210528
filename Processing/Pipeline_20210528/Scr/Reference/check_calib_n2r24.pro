
;; Compare the relative flux of calibrators along a run
;;
;; Hack from check_calib_n2r22.pro
;;-------------------------------------------------------------------

process       = 0
reset         = 0 ; 1

;; object_list = ['CRL2688', 'NEPTUNE', 'URANUS', '2251+158', 'MWC349']
object_list = ['CRL2688', 'NEPTUNE', 'URANUS', '2251+158']

n_objects = n_elements(object_list)

message, /info, "fix me:"
print, '1. Uncomment log_iram_tel_n2r24'
print, '2. restore Log_Iram_tel_N2R24_v0.save instead of ...N2R22...'
print, '3. remove the stop'
;log_iram_tel_n2r24
logbook_file = !nika.pipeline_dir+'/Datamanage/Logbook/Log_Iram_tel_N2R22_v0.save'
stop


;;===================================================================================


;; Do not include beammaps at this stage to save computation time
restore, logbook_file
db_scan = temporary(scan)
idx = [-1]
for iobj=0, n_elements(object_list)-1 do begin
   w = where( strmid( db_scan.comment, 0, 4) ne 'focu' and $
              db_scan.obstype eq 'onTheFlyMap' and $
              db_scan.n_obs lt 60 and strupcase(db_scan.object) eq strupcase(object_list[iobj]), nw)
   if nw ne 0 then idx = [idx, w]
endfor
idx = idx[1:*]
mjd = db_scan[idx].mjd
scan_list = db_scan[idx].day+"s"+strtrim(db_scan[idx].scannum,2)
nidx = n_elements(idx)

;time = strarr(nidx)
;for i=0, nw-1 do time[i] = strmid( mjd2date( mjd), 11)

;; ;; Restrict to night data
;; w = where( long(strmid(time,0,2)) ge 21 or long(strmid(time,0,2)) le 8)
;; scan_list = scan_list[w]
;; 
;; black list
scan_list = scan_list[ where( scan_list ne '20181009s7')]

nscans = n_elements(scan_list)
root_dir = "place_holder"
source_init_param_2, 'junk', 60., param, root_dir, method_num=2
param.project_dir = !nika.plot_dir
param.do_opacity_correction = 0
param.flag_sat              = 0
param.flag_ovlap            = 0
param.flag_oor              = 0

in_param_file = 'param.save'
save, param, file=in_param_file
;obs_nk_ps_2, 10, scan_list, in_param_file
;stop

if reset eq 1 then begin
   for iscan=0, nscans-1 do begin
      spawn, "rm -f "+!nika.plot_dir+"/v_1/"+scan_list[iscan]+"/*"
   endfor
endif

if process eq 1 then begin
 ;; check which scans need to be reduced
   tbp = intarr(nscans)
   for iscan=0, nscans-1 do begin
      if file_test(!nika.plot_dir+"/v_1/"+scan_list[iscan]+"/results.save") eq 0 then tbp[iscan]=1
   endfor
   w = where( tbp eq 1)
   tbp_scan_list = scan_list[w]
   nscans_tbp = n_elements(tbp_scan_list)
   print, strtrim(nscans_tbp,2)+" scan(s) remain to be processed out of "+strtrim(nscans,2)

   ncpu_max = 24
   ;; Use the maximum of cpus
   if nscans_tbp le ncpu_max then begin
      rest = 0
      my_scan_list = tbp_scan_list
      my_nscans = nscans_tbp
      ncpu_eff = my_nscans
   endif else begin
      nscans_per_proc = long( nscans_tbp/ncpu_max)
      my_nscans = nscans_per_proc * ncpu_max
      rest = nscans_tbp - my_nscans
      my_scan_list = tbp_scan_list[0:my_nscans-1]
      ncpu_eff = ncpu_max
   endelse
   
   split_for, 0, my_nscans-1, nsplit=ncpu_eff, $
              commands=['obs_nk_ps_2, i, my_scan_list, in_param_file'], $
              varnames=['my_scan_list', 'in_param_file']
   ;; Then redistribute the rest if any
   if rest ne 0 then begin
      my_scan_list = tbp_scan_list[my_nscans:*]
      split_for, 0, rest-1, nsplit=rest, $
                 commands=['obs_nk_ps_2, i, my_scan_list, in_param_file'], $
                 varnames=['my_scan_list', 'in_param_file']
   endif
endif

reduced = intarr(nscans)
for iscan=0, nscans-1 do begin
   if file_test(!nika.plot_dir+"/v_1/"+scan_list[iscan]+"/info.csv") then reduced[iscan]=1
endfor

w = where( reduced eq 1)
scan_list = scan_list[w]
print, "After processing, scan_list:"
help, scan_list
stop

;; sort in chronological order like RZ
nscans = n_elements(scan_list)
mjd    = dblarr(nscans) + !values.d_nan
for iscan=0, nscans-1 do begin
   file = !nika.plot_dir+"/v_1/"+scan_list[iscan]+"/info.csv"
   if file_test(file) then begin
      nk_read_csv_2, file, info
      mjd[iscan] = info.mjd
   endif
endfor
w = where( finite(mjd))
scan_list  = scan_list[w]
mjd        = mjd[w]
order      = sort(mjd)
mjd        = mjd[order]
scan_list = scan_list[order]

;; Retrieve all results
nscans = n_elements(scan_list)
index           = indgen(nscans)
flux_res        = dblarr(3,nscans)
err_flux_res    = dblarr(3,nscans)
gauss_flux_res  = dblarr(3,nscans)
fwhm_res        = dblarr(3,nscans)
opa_corr        = dblarr(3,nscans)
snr_res         = dblarr(3,nscans)
scan_obj        = strarr(nscans)
tau225          = dblarr(nscans)
tau1mm_rz       = dblarr(nscans)
tau2mm_rz       = dblarr(nscans)
elevation       = dblarr(nscans)
for iscan=0, nscans-1 do begin
   file = !nika.plot_dir+"/v_1/"+scan_list[iscan]+"/info.csv"
   if file_test(file) then begin
      nk_read_csv_2, file, info
      scan_obj[iscan] = info.object
      tau225[iscan]   = info.tau225
      elevation[iscan] = info.result_elevation_deg
      mjd[iscan] = info.mjd

      ;;tau = interpol( tau1, my_mjd, info.mjd)
      tau1mm_rz[iscan] = info.tau225*1.28689-0.00012725
      tau2mm_rz[iscan] = info.tau225*0.732015+0.0200369

      opa_corr[0,iscan] = exp( tau1mm_rz[iscan]/sin(elevation[iscan]*!dtor))
      opa_corr[1,iscan] = exp( tau2mm_rz[iscan]/sin(elevation[iscan]*!dtor))
      opa_corr[2,iscan] = exp( tau1mm_rz[iscan]/sin(elevation[iscan]*!dtor))
      
      flux_res[0,iscan] = info.result_flux_i1 * opa_corr[0,iscan]
      flux_res[1,iscan] = info.result_flux_i2 * opa_corr[1,iscan]
      flux_res[2,iscan] = info.result_flux_i3 * opa_corr[2,iscan]

      err_flux_res[0,iscan] = info.result_err_flux_i1 * opa_corr[0,iscan]
      err_flux_res[1,iscan] = info.result_err_flux_i2 * opa_corr[1,iscan]
      err_flux_res[2,iscan] = info.result_err_flux_i3 * opa_corr[2,iscan]

      snr_res[0,iscan] = info.result_flux_i1/info.result_err_flux_i1
      snr_res[1,iscan] = info.result_flux_i2/info.result_err_flux_i2
      snr_res[2,iscan] = info.result_flux_i3/info.result_err_flux_i3
      
      ;; A la RZ: integral over the fitted main beam
      phi1 = info.result_peak_1 * 2.d0*!dpi*(info.result_fwhm_1*!fwhm2sigma)^2
      phi2 = info.result_peak_2 * 2.d0*!dpi*(info.result_fwhm_2*!fwhm2sigma)^2
      phi3 = info.result_peak_3 * 2.d0*!dpi*(info.result_fwhm_3*!fwhm2sigma)^2
      
      gauss_flux_res[0,iscan] = phi1 * exp( tau1mm_rz[iscan]/sin(elevation[iscan]*!dtor))
      gauss_flux_res[1,iscan] = phi2 * exp( tau2mm_rz[iscan]/sin(elevation[iscan]*!dtor))
      gauss_flux_res[2,iscan] = phi3 * exp( tau1mm_rz[iscan]/sin(elevation[iscan]*!dtor))

      fwhm_res[0,iscan] = info.result_fwhm_1
      fwhm_res[1,iscan] = info.result_fwhm_2
      fwhm_res[2,iscan] = info.result_fwhm_3
   endif
endfor

;; Normalize each flux to the average of the same object (on the 1st
;; apparent plateau)
obj = scan_obj
obj = obj[UNIQ(obj, SORT(obj))]
nobj = n_elements(obj)
for i=0, nobj-1 do begin
   wobj  = where( scan_obj eq obj[i])
;;   wnorm = where( scan_obj eq obj[i] and round((mjd-mjd[0])) le 4)
   wnorm = where( scan_obj eq obj[i] and round((mjd-mjd[0])) le 1)
   for j=0, 2 do begin
      flux_res[       j, wobj] /= avg( flux_res[       j,wnorm])
      gauss_flux_res[ j, wobj] /= avg( gauss_flux_res[ j,wnorm])
      opa_corr[       j, wobj] /= avg( opa_corr[       j,wnorm])
      snr_res[        j, wobj] /= avg( snr_res[        j,wnorm])
      err_flux_res[   j, wobj] /= avg( err_flux_res[   j, wnorm])
   endfor
endfor
make_ct, nobj, ct

syms = 0.5
wind, 1, 1, /free, /large
my_multiplot, 3, 3, pp, pp1, /rev, gap_x=0.04, gap_y=0.02, $
              xmargin=0.05              ;, ymin=0.3,  ymax=0.95
;my_multiplot, 3, 2, aa, aa1, /rev, gap_x=0.05, gap_y=0.01, ymin=0.01, ymax=0.3
!p.charsize=0.6
for iarray=1, 3 do begin
   yra=[0,2]
   xcharsize = 1d-10
   p=0
   
;;    plot, index, flux_res[iarray-1,*], /xs, yra=yra, /ys, $
;;          xcharsize=xcharsize, position=pp[iarray-1,p,*], /noerase ;, /nodata
;;    p++
;;    legendastro, 'Fixed FWHM Flux A'+strtrim(iarray,2)
;;    oplot, minmax(index), [1,1]
;;    for iobj=0, nobj-1 do begin
;;       w = where( scan_obj eq obj[iobj])
;;       oplot, [index[w]], [flux_res[iarray-1,w]], psym=8, col=ct[iobj], syms=syms
;;    endfor
;;    legendastro, obj, col=ct, /right

  plot, index, gauss_flux_res[iarray-1,*], /xs, yra=yra, /ys, $
        xcharsize=xcharsize, position=pp[iarray-1,p,*], /noerase ;, /nodata
  p++
  legendastro, 'Gauss Flux A'+strtrim(iarray,2)
  oplot, minmax(index), [1,1]
  for iobj=0, nobj-1 do begin
     w = where( scan_obj eq obj[iobj])
     oplot, [index[w]], [gauss_flux_res[iarray-1,w]], psym=8, col=ct[iobj], syms=syms
  endfor
  legendastro, obj, col=ct, /right
;   day = mjd-mjd[0]
;   oplot, index, day/max(day)*2, col=150

;;    if iarray eq 1 then ytitle='arcsec' else ytitle=''
;;    plot, index, fwhm_res[iarray-1,*], /xs, /ys, $;/nodata, $
;;          xcharsize=xcharsize, position=pp[iarray-1,p,*], /noerase, yra=[10,20], $
;;          ytitle=ytitle
;;    oplot, minmax(index), [1,1]
;;    p++
;;    legendastro, 'FWHM A'+strtrim(iarray,2)
;;    for iobj=0, nobj-1 do begin
;;       w = where( scan_obj eq obj[iobj])
;;       oplot, [index[w]], [fwhm_res[iarray-1,w]], psym=8, col=ct[iobj], syms=syms
;;    endfor

;;    if iarray eq 1 then ytitle='e!u-!7r!3/sin!7d!3!n (normalized)' else ytitle=''
;;    plot, index, opa_corr[iarray-1,*], /xs, /ys, $
;;          /noerase, $
;;          ytitle=ytitle, xcharsize=xcharsize, position=pp[iarray-1,p,*]
;;    p++
;;    oplot, minmax(index), [1,1]
;;    legendastro, 'A'+strtrim(iarray,2)
;;    for iobj=0, nobj-1 do begin
;;       w = where( scan_obj eq obj[iobj])
;;       oplot, [index[w]], [opa_corr[iarray-1,w]], psym=8, col=ct[iobj], syms=syms
;;    endfor


   if iarray eq 1 then ytitle='ERR_FLUX (normalized)' else ytitle=''
   plot, index, err_flux_res[iarray-1,*], /xs, /ys, $
         /noerase, $
         ytitle=ytitle, xcharsize=xcharsize, position=pp[iarray-1,p,*]
   p++
   legendastro, 'A'+strtrim(iarray,2)
   oplot, minmax(index), [1,1]
   for iobj=0, nobj-1 do begin
      w = where( scan_obj eq obj[iobj])
      oplot, [index[w]], [err_flux_res[iarray-1,w]], psym=8, col=ct[iobj], syms=syms
   endfor

   xcharsize = 1
   if iarray eq 1 then ytitle='SNR (normalized)' else ytitle=''
   plot, index, snr_res[iarray-1,*], /xs, /ys, $
         /noerase, $
         ytitle=ytitle, xcharsize=xcharsize, position=pp[iarray-1,p,*]
   p++
   oplot, minmax(index), [1,1]
   legendastro, 'A'+strtrim(iarray,2)
   for iobj=0, nobj-1 do begin
      w = where( scan_obj eq obj[iobj])
      oplot, [index[w]], [snr_res[iarray-1,w]], psym=8, col=ct[iobj], syms=syms
   endfor

endfor

end
