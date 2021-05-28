

pro make_focus_surfaces, scan_list, source, input_flux_th, beam_maps_dir, result_dir, $
                         savepng=savepng, process=process, force_process=force_process, $
                         force_kidpar=force_kidpar, input_kidpar_file=input_kidpar_file, $
                         do_opacity_correction=do_opacity_correction, $
                         decor_method=decor_method, decor_cm_dmin=decor_cm_dmin, reso=reso, $
                         fit_focus=fit_focus, focus_error_rescaling=focus_error_rescaling
  
  
  if keyword_set(savepng) then savepng=1 else savepng=0
  if keyword_set(process) then process=1 else process=0
  if keyword_set(force_process) then reprocess=1 else reprocess=0
  if keyword_set(force_kidpar) then force_kidpar=1 else force_kidpar=0
  if keyword_set(do_opacity_correction) then do_opacity_correction=1 else do_opacity_correction=0
  if keyword_set(decor_method) then decor_method=decor_method else decor_method = 'common_mode_one_block'
  if keyword_set(decor_cm_dmin) then decor_cm_dmin=decor_cm_dmin else decor_cm_dmin=90.
  if keyword_set(reso) then reso=reso else reso=4.
  if keyword_set(fit_focus) then fit_focus=1 else fit_focus=0
  if keyword_set(focus_error_rescaling) then focus_error_rescaling=1 else focus_error_rescaling=0

  
  nk_scan2run, scan_list[0]
  
  if force_kidpar lt 1 then nk_get_kidpar_ref, scan_num, day, info, input_kidpar_file, scan=scan_list[0]
  
  ;;  
  ;;
  ;;       process the data, make maps per kid
  ;;
  ;;___________________________________________________________________________
  if process eq 1 then begin
     print, "%%%%%%%%%"
     print, ''
     print, 'TOI processing...'
     ;; process the data if it has not been done already
     
     for iscan=0, n_elements(scan_list)-1 do begin
        scan = scan_list[iscan]
        print, ''
        print, ' reduction of the scan ',strtrim(scan,2)
        
        spawn, 'ls '+beam_maps_dir+'/Maps_kids_out/kid_maps_'+scan+'_*.save', map_file_list
        nf = n_elements(map_file_list)
        
        if nf lt 16  or reprocess eq 1 then begin
           
           print, ' processing scan ',strtrim(scan,2)
           ptg_numdet_ref =  823
           
           if do_opacity_correction eq 1 then !db.lvl = 2 else !db.lvl = 3
           !db.cm_dmin = decor_cm_dmin
           
           make_geometry_5, scan, input_flux_th, ptg_numdet_ref=ptg_numdet_ref, iteration=2, $
                            decor_method=decor_method, reso=reso, source=source, beam_maps_dir=beam_maps_dir, $
                            input_kidpar_file=input_kidpar_file, $
                            prepare=1, beams=0, merge=0, select=0, finalize=0
           
           
        endif else print, "already processed scan: ", scan
     endfor
     
  endif
  
  
  ;; 
  ;;
  ;;        Focus estimation
  ;; 
  ;;____________________________________________________________________________
  if fit_focus eq 1 then begin
     print, "%%%%%%%%%"
     print, ''
     print, 'Focus fitting...'
     print, ''
     
     ;;test
     ;; fov_focus_otf_sub, 15, scan_list, beam_maps_dir, $
     ;;                    kidpar_file=input_kidpar_file,$
     ;;                    result_dir=result_dir, focus_error_rescaling=focus_error_rescaling, $
     ;;                    plot_output_dir=result_dir+'/plot_0', show_focus_plot=0
     ;; stop
     
     
     nproc = 16
     
     kidpar_file     = input_kidpar_file
     plot_output_dir = result_dir
     split_for, 0, nproc-1, nsplit=nproc, $
                commands=['fov_focus_otf_sub, i, scan_list, beam_maps_dir, '+$
                          'kidpar_file=kidpar_file, '+$
                          'result_dir=result_dir, focus_error_rescaling=focus_error_rescaling, '+$
                          'plot_output_dir=plot_output_dir'], $
                varnames = ['scan_list', 'beam_maps_dir', 'kidpar_file', $
                            'result_dir', 'focus_error_rescaling', 'plot_output_dir']
     
     
     
  endif
  
;;stop
  

end

