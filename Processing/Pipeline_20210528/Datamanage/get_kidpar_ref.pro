;; This reads the correct focal plane geometry relevant to a given scan

;; scan_num : int

;; Retrive the appropriate kidpar

pro get_kidpar_ref, scan_num, day, kidpar_a1mm_file, kidpar_b2mm_file, no_refpix=no_refpix ;, config_file

  nscan = n_elements(scan_num)
  if nscan ne n_elements(day) then message, 'The given number of scans is not equal to the number of days'
  
  kidpar_a1mm_file = strarr(nscan)
  kidpar_b2mm_file = strarr(nscan)

  for iscan = 0, nscan-1 do begin
     myday = long( day[iscan])

     ;; Init to empty string for lab measurements
     file_1mm = ""
     file_2mm = ""

     ;;===================================================================================
     ;; Run5
     if myday lt 20121120 then begin
        file_1mm = !nika.off_proc_dir+"/Kidpar_A1mm_avg_20121115_v3.fits"
        file_2mm = !nika.off_proc_dir+"/Kidpar_B2mm_avg_20121115_v3.fits"
        !nika.numdet_ref_1mm = -1
        !nika.numdet_ref_2mm = 453
     endif
     if myday ge 20121120 and myday le 20121126 then begin
        file_1mm = !nika.off_proc_dir+"/Kidpar_A1mm_avg_20121120_v3.fits"
        file_2mm = !nika.off_proc_dir+"/Kidpar_B2mm_avg_20121120_v3.fits"
        !nika.numdet_ref_1mm = 8
        !nika.numdet_ref_2mm = 414
     endif
     
     ;;===================================================================================
     ;; Run6
     if myday ge 20130601 and myday le 20130629 then begin
        file_1mm = !nika.off_proc_dir+"/kidpar_ref_434pixref_1mm_bestscans_v4.fits"
        file_2mm = !nika.off_proc_dir+"/kidpar_ref_434pixref_2mm_bestscans_v4.fits"
        if keyword_set(no_refpix) then file_1mm = !nika.off_proc_dir+"/kidpar_ref_nopixref_1mm_bestscans_v4.fits"
        if keyword_set(no_refpix) then file_2mm = !nika.off_proc_dir+"/kidpar_ref_nopixref_2mm_bestscans_v4.fits"
        !nika.numdet_ref_1mm = 28
        !nika.numdet_ref_2mm = 434
     endif

     ;;===================================================================================
     ;; RunCryo
     if myday ge 20131111 and myday le 20131116 then begin
        file_1mm =  !nika.off_proc_dir+"/kidpar_ref_1mm_runcryo.fits"
        file_2mm =  !nika.off_proc_dir+"/kidpar_ref_2mm_runcryo.fits"
        !nika.numdet_ref_1mm = 261
        !nika.numdet_ref_2mm = 569
     endif
     
     ;;===================================================================================
     ;; Run7
     if myday eq 20140120 then begin
        ;file_1mm =  !nika.off_proc_dir+"/kidpar_ref_run7_1mm.fits"
        ;file_2mm =  !nika.off_proc_dir+"/kidpar_ref_run7_2mm.fits"
        ;file_1mm =  !nika.off_proc_dir+"/kidpar_ref_run7_1mm_v3.fits"
        ;file_2mm =  !nika.off_proc_dir+"/kidpar_ref_run7_2mm_v3.fits"
        file_1mm =  !nika.off_proc_dir+"/kidpar_20140120s205_1mm_v4.fits"
        file_2mm =  !nika.off_proc_dir+"/kidpar_20140120s205_2mm_v4.fits"
        !nika.numdet_ref_1mm = 32
        !nika.numdet_ref_2mm = 430
     endif
     if myday eq 20140121 then begin
        if scan_num[iscan] le 242 then begin
           ;; the exact limit of 242 will have to be confirmed.
           ;; kid validity must be the same as before but the focus was
           ;; different, so positions may have varied.
           file_1mm =  !nika.off_proc_dir+"/kidpar_20140120s205_1mm_v7.fits"
           file_2mm =  !nika.off_proc_dir+"/kidpar_20140120s205_2mm_v7.fits"
           !nika.numdet_ref_1mm = 32
           !nika.numdet_ref_2mm = 430
        endif else begin
           file_1mm =  !nika.off_proc_dir+"/kidpar_20140121s243_1mm_v7.fits"
           file_2mm =  !nika.off_proc_dir+"/kidpar_20140121s243_2mm_v7.fits"
           !nika.numdet_ref_1mm = 32
           !nika.numdet_ref_2mm = 430
        endelse
     endif
     if myday eq 20140122 then begin
        if scan_num[iscan] lt 89 then begin
           file_1mm =  !nika.off_proc_dir+"/kidpar_20140122s19_1mm_v7.fits"
           file_2mm =  !nika.off_proc_dir+"/kidpar_20140122s19_2mm_v7.fits"
           !nika.numdet_ref_1mm = 32
           !nika.numdet_ref_2mm = 430
        endif else begin
           file_1mm = !nika.off_proc_dir+"/kidpar_20140123s140_1mm_v7.fits"
           file_2mm = !nika.off_proc_dir+"/kidpar_20140123s140_2mm_v7.fits"
           !nika.numdet_ref_1mm = 5
           !nika.numdet_ref_2mm = 494
        endelse
     endif
     if myday ge 20140123 and myday lt 20140128 then begin
        file_1mm = !nika.off_proc_dir+"/kidpar_20140123s140_1mm_v7.fits"
        file_2mm = !nika.off_proc_dir+"/kidpar_20140123s140_2mm_v7.fits"
        !nika.numdet_ref_1mm = 5
        !nika.numdet_ref_2mm = 494
     endif

     ;;===================================================================================
     ;; Run8
     if myday ge 20140214 and myday le 20140314 then begin
        ;file_1mm = !nika.off_proc_dir+"/kidpar_20140123s140_1mm_v7.fits"
        ;file_2mm = !nika.off_proc_dir+"/kidpar_20140123s140_2mm_v7.fits"
        ;file_1mm = !nika.off_proc_dir+"/kidpar_20140219s205_1mm_v0.fits"
        ;file_2mm = !nika.off_proc_dir+"/kidpar_20140219s205_2mm_v0.fits"
        file_1mm = !nika.off_proc_dir+"/kidpar_20140219s205_1mm_v1.fits"
        file_2mm =!nika.off_proc_dir+"/kidpar_20140219s205_2mm_v1.fits"

        ;; Apr 28th, 2014
        file_1mm = !nika.off_proc_dir+"/kidpar_20140219s205_1mm_v2.fits"
        file_2mm = !nika.off_proc_dir+"/kidpar_20140219s205_2mm_v2.fits"
        
        !nika.numdet_ref_1mm = 5
        !nika.numdet_ref_2mm = 494
     endif

     ;;===================================================================================
     ;; Run10
     if myday ge 20141107 and myday lt 20150123 then begin
        file_1mm = !nika.off_proc_dir+"/kidpar_20141109s198_v5.fits"
        file_2mm = !nika.off_proc_dir+"/kidpar_20141109s198_v5.fits"
        
        !nika.numdet_ref_1mm = 5
        !nika.numdet_ref_2mm = 494
     endif
     
     ;;===================================================================================
     ;; Run11
     if myday ge 20150123 and myday lt 20150211 then begin
        ;;file_1mm= !nika.off_proc_dir+"/kidpar_20150123s137.fits"
        ;;file_2mm= !nika.off_proc_dir+"/kidpar_20150123s137.fits"

        file_1mm = !nika.off_proc_dir+"/kidpar_20150123s137_v8.fits"
        file_2mm = !nika.off_proc_dir+"/kidpar_20150123s137_v8.fits"
     endif

     ;;===================================================================================
     kidpar_a1mm_file[iscan] = file_1mm
     kidpar_b2mm_file[iscan] = file_2mm
  endfor

end
