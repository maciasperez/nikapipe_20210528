;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
;  Script NIKA2 performance 
;
;
;   NIKA2 FWHM estimates using OTF scans (5x8arcmin^2)
;
;-----------------------------------------------------------------------------

;; SELECTION OF STRONG SOURCE SCANS 
;;___________________________________________________________________________


;; calib I&II : Uranus, Neptune, Ceres, Vesta, (Pallas, Lutetia),
;; MWC349, CRL618, CRL2688
;;----------------------------------------------------------------------

source_list = ['Uranus', 'Neptune', 'Pluto', 'BODY Ceres', 'BODY Vesta', 'Pallas', 'Lutetia', 'MWC349', 'CRL618', 'CRL2688', '0316+413', '3C279', '3C273']

;; source_n2r9 : ['3C273', 'MWC349', '3C345', 'Uranus', '3C84', '2251+158' ]


calib_run   = ['N2R9', 'N2R12', 'N2R14']
nrun  = n_elements(calib_run)


;;file_suffixe          = '_mb'
file_suffixe          = '_mb_radius_binning2'

;; pipeline reduction info
;;-------------------------------------------------
opa_suffixe = ['baseline', 'atmlike', 'atmlike']
runnum = [9, 12, 14]
dir0 = '/data/Workspace/macias/NIKA2/Plots/CalibTests'
dir1 = '/data/Workspace/Laurence/Plots/CalibTests'

dir9  = dir0+'/RUN9_OTFS_v2_calpera'
dir12 = dir1+'/RUN12_OTFS_v2_calpera'
dir14 = dir0+'/RUN14_OTFS_v2_calpera'
  
result_dir   = [dir9, dir12, dir14]

;; Flux threshold for sources selection
;;--------------------------------------------
flux_threshold_1mm = 1.0d0
flux_threshold_2mm = 1.0d0
  
;; outplot directory
dir     = getenv('HOME')+'/NIKA/Plots/Beams/'


;;________________________________________________________________
;;
;; get all result files
;;________________________________________________________________
;;________________________________________________________________
outdir = '/home/perotto/NIKA/Plots/Performance_plots/'
get_all_scan_result_files_v2, result_files, outputdir = outdir

scan_list    = ''
for irun = 0, nrun-1 do begin
   
   print,''
   print,'------------------------------------------'
   print,'   ', strupcase(calib_run[irun])
   print,'------------------------------------------'
   print,'READING RESULT FILE: '
   allresult_file = result_files[irun] 
   print, allresult_file
   
   ;;
   ;;  restore result tables
   ;;____________________________________________________________
   restore, allresult_file, /v
   ;; allscan_info
   
   ;; remove known outliers
   ;;___________________________________________________________
   scan_list_ori = allscan_info.scan
   
   outlier_list =  ['20170223s16', $    ; dark test
                    '20170223s17', $    ; dark test
                    '20171024s171', $   ; focus scan
                    '20171026s235', $   ; focus scan
                    '20171028s313', $   ; RAS from tapas
                    '20180114s73', $    ; TBC
                    '20180116s94', $    ; focus scan
                    '20180118s212', $   ; focus scan
                    '20180119s241', $   ; Tapas comment: 'out of focus'
                    '20180119s242', $   ; Tapas comment: 'out of focus'
                    '20180119s243', $   ; Tapas comment: 'out of focus'   '20180122s98', $
                    '20180122s118', '20180122s119', '20180122s120', '20180122s121', $ ;; the telescope has been heated
                    '20170226s415', $                                                 ;; wrong ut time
                    '20170226s416','20170226s417', '20170226s418', '20170226s419']    ;; defocused beammaps
   
   
   outlier_list = [outlier_list, $
                   '20171024s202', '20171024s220'] ;; during a pointing session
   
   out_index = 1
   remove_scan_from_list, scan_list_ori, outlier_list, scan_list_run, out_index=out_index
   allscan_info = allscan_info[out_index]
   
   nscans = n_elements(scan_list_run)
   print, "number of scan: ", nscans
   
   ;; NSCAN TOTAL ESTIMATE :
   ;; select scans for the desired sources
   ;;____________________________________________________________
   ;; flux thresholding
   wkeep = where( allscan_info.result_flux_i_1mm ge flux_threshold_1mm and $
                  allscan_info.result_flux_i2    ge flux_threshold_2mm, nkeep)
   print, 'nb of found scan of the sources = ', nkeep
   allscan_info = allscan_info[wkeep]
   
   wq = where(allscan_info.object eq '0316+413', nq)
   if nq gt 0 then allscan_info[wq].object = '3C84'
   
   ;; discarding resolved sources for photometric correction
   allsources  = strupcase(allscan_info.object)
   wreso = where(allsources eq 'MARS' or allsources eq 'NGC7027' or allsources eq 'CRL2688', wres, compl=wpoint)
   allscan_info = allscan_info[wpoint]
   
   nscans       = n_elements(allscan_info)
      
   ;;
   ;; Scan selection
   ;;____________________________________________________________ 
   to_use_photocorr = 0
   complement_index = 0
   beamok_index     = 0
   largebeam_index  = 0
   tauok_index      = 0
   hightau_index    = 0
   obsdateok_index  = 0
   afternoon_index  = 0
   fwhm_max         = 0
   nefd_index       = 0
   scan_selection, allscan_info, wtokeep, $
                   to_use_photocorr=to_use_photocorr, complement_index=wout, $
                   beamok_index = beamok_index, largebeam_index = wlargebeam,$
                   tauok_index = tauok_index, hightau_index=whitau3, $
                   osbdateok_index=obsdateok_index, afternoon_index=wdaytime, $
                   fwhm_max = fwhm_max, nefd_index = nefd_index
   allscan_info = allscan_info[wtokeep]

   allsources = allscan_info.object
   allsources = allsources[uniq(allsources)]
   
   ;;
   ;; ANALYSIS
   ;;____________________________________________________________
   n_to_proc = n_elements(allscan_info.scan)
   print, 'nscans to process = ', n_to_proc
   ;;stop
   
   scan_list             = allscan_info.scan 
   project_dir           = result_dir[irun]

   ;; if nk analysis needed
   do_opacity_correction = 4
   force_kidpar          = 1
   file_kidpar           = !nika.soft_dir+'/Kidpars/kidpar_calib_'+strtrim(calib_run[irun],2)+'_ref_'+opa_suffixe[irun]+'_v2_calpera.fits'
   decor_method          = 'COMMON_MODE_ONE_BLOCK'
   decor_cm_dmin         = 60.0d0 ;;100.
   map_reso              = 2.d0
   map_size              = 900.0d0;; 600.d0
   map_proj              = "azel" 
   fixmask               = 0
   version               = '1'

   ;; main beam result directory
   output_dir            = dir+'/'+calib_run[irun]
   spawn, 'mkdir -p '+ output_dir
   relaunch_nk           = 0

   noplot                = 1
      
   nsplit = min([n_to_proc, 16])
   if nsplit gt 2 then begin
      split_for, 0, n_to_proc-1, nsplit=nsplit, $
                 commands=['nk_main_beam_sub, i, scan_list, input_dir=project_dir, output_dir=output_dir, do_opacity_correction=do_opacity_correction, file_kidpar=file_kidpar, decor_method=decor_method, decor_cm_dmin=decor_cm_dmin, map_reso=map_reso, map_size=map_size, map_proj=map_proj, version=version, relaunch_nk=relaunch_nk, file_suffixe=file_suffixe, fixmask=fixmask, noplot=noplot'], $
                 varnames = ['scan_list', 'project_dir', 'output_dir', 'do_opacity_correction', $
                             'file_kidpar','decor_method' ,'decor_cm_dmin', 'relaunch_nk', $
                             'file_suffixe', 'version', $
                             'map_reso', 'map_size', 'map_proj', 'fixmask', 'noplot']
   endif else begin
      for i=0, n_to_proc-1 do nk_main_beam_sub, i, scan_list, input_dir=project_dir, output_dir=output_dir, do_opacity_correction=do_opacity_correction, file_kidpar=file_kidpar, decor_method=decor_method, decor_cm_dmin=decor_cm_dmin, map_reso=map_reso, map_size=map_size, map_proj=map_proj, version=version, relaunch_nk=relaunch_nk, file_suffixe=file_suffixe, fixmask=fixmask, noplot=noplot
   endelse


endfor



stop

end
