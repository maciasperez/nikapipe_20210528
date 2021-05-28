;;
;;   RESTORE BASELINE CALIBRATION RESULTS
;;
;;   as obtained using e. g. baseline_calibration_demo.pro
;;
;;_______________________________________________________________________

pro restore_calibration_results, runname


  ;;_____________________________________________________________________
  ;;
  ;; RUN NAME
  ;;
  ;; Several NIKA2 runs within the same cryo run can be jointly
  ;; analysed, for example : 
  ;;runname = ['N2R36', 'N2R37']
  ;;_____________________________________________________________________
  ;;runname = ['N2R14'] 

  ;; OUTPUT_DIR
  ;; All calibration results will be in getenv('NIKA_PLOT_DIR')+'/'+runname[0]
  
  ;;_____________________________________________________________________
  ;;
  ;; FOCAL PLANE GEOMETRY
  ;;
  ;; a geometry must have been produced using e.g. Geometry/reduce_beammap.pro
  ;;
  ;; in this case, geom_kidpar_file is the output of reduce_beammap.pro :
  ;; kidpar_<scan_id>_v2
  ;;
  ;; or one can start with the current reference kidpar as defined in
  ;; nk_get_kidpar_ref.pro. See the example below:
  ;;

  
  ;; In case of multiples kidpar used in a run, one can choose to let
  ;; nk_get_kidpar_ref picking the relevant kidpar for each scan
  ;; --> set the keyword multiple_kidpars

  
calibration_dir = getenv('NIKA_PLOT_DIR')+'/'+runname[0]
 

  ;;==========================================================================='
  ;;
  ;;     SAVING THE CALIBRATION RESULTS
  ;;
  ;;==========================================================================='
  nickname = runname[0]+'_baseline'
  calibration_file = calibration_dir+'/calibration_results_'+nickname+'.save'
  
  if file_test(calibration_file) lt 1 then begin
     print, 'The expected file gathering calibration results not found:'
     print, calibration_file
  endif else begin

     print, "RESTORING: ", calibration_file
     restore, calibration_file, /v
     
     print, ''
     print, ''
     print, ''
     print,'==================================================================='
     print, ''
     print, 'The production and validation of the calibration is completed'
     print, 'Congratulation!'
     print, ''
     print, 'Last step:'
     print, 'The lines above are to be copied in the Calibration wiki:'
     print, ''
     print, 'https://wiki.iram.fr/wiki/nika2/index.php/NIKA2Calibration'
     print, ''
     print,'==================================================================='
     print, ''
     print, ''
     print, ''
     ;;==========================================================================='
     ;;
     ;;     SUMMARY  TABLE 
     ;;
     ;;==========================================================================='
     print, '[[NIKA2Calibration | Back to the main calibration page]]'
     print, ''
     print,'<!--===================================================================-->'
     print,''
     print,''
     print,'==     SUMMARY  TABLE    == '
     print,''
     print,'CALIBRATION OF ', runname[0],'  <br />'
     print,'Using the SVN revision of the IDL pipeline = ', calibration.svnrev, '  <br /> '
     print,'All results are summarised below'
     print,''
     print,''
     print,'<!--====================================================================-->'
     print, 'KIDPAR FILES: '
     print, '* Geometry kidpar file: ', calibration.geom_kidpar_file
     print, '* Opacity kidpar file: ', calibration.opacity_kidpar_file
     print, '* Output kidpar file: ', calibration.abscal_kidpar_file
     
     photo_dir = calibration_dir+'/Photometry'
     nickname = runname[0]+'_baseline'
     acal_file = photo_dir+"/Absolute_calibration_"+nickname+'.save'
     if file_test(acal_file) gt 0 then begin
        ;;print, "reading : ",acal_file
        restore, acal_file
        print, ''
        print, '<!--===========================================================================-->'
        print, ''
        print, '===   Absolute calibration summary   === '
        print, ''
        print, '<!--===========================================================================-->'
        print, 'Uranus:'
        print, '* total number of scans     = ', uranus_ntot
        print, '* number of selected scans  = ', uranus_nsel
        print, 'Neptune: '
        print, '* total number of scans    = ', neptune_ntot
        print, '* number of selected scans = ', neptune_nsel
        print, ''
        if strcmp(selection_type, 'lastchance', /fold_case) gt 0 then begin
           print, 'Beware the scan(s) did not meet the nominal selection criteria'
           print, ''
        endif
        print, 'Calibration Coefficients (Expected flux / Raw flux) :'
        print, '* A1 : ', correction_coef[0], ', rms = ', rms_correction_coef[0] 
        print, '* A3 : ', correction_coef[2], ', rms = ', rms_correction_coef[2] 
        print, '* 1mm: ', correction_coef[3], ', rms = ', rms_correction_coef[3]
        print, '* 2mm: ', correction_coef[1], ', rms = ', rms_correction_coef[1]
        print, '<!--===========================================================================-->'
     endif
     
     second_dir = photo_dir + '/SecondaryCal'
     second_file = second_dir+'/photometry_check_on_secondaries.save'
     if file_test(second_file) gt 0 then begin
        ;;print, "reading : ",second_file
        restore, second_file
        print, ''
        print, '<!--===========================================================================-->'
        print, ''
        print, '===  Photometry check on secondary calibrators  === '
        print, ''
        print, '<!--===========================================================================-->'
        print, 'Secondary calibrator              = ', secondary.calibrator, '   <br />'
        w = where(strmatch(secondary.selected_scan_list, '') eq 0, n)
        print, '* number of selected scans          = ', strtrim(n,2)
        w = where(strmatch(secondary.observed_scan_list, '') eq 0, n)
        print, '* total number of scans             = ', strtrim(n, 2)
        print, ''
        if calibration.photometry_check_comment ne '' then begin
           print, 'COMMENT: ',calibration.photometry_check_comment
           print, ''
        endif
        print, 'Calibration bias (Measured/Expected):'
        print, '* A1 : ', (secondary.calibration_bias)[0] , ', rms = ', (secondary.calibration_bias_rms)[0] 
        print, '* A3 : ', (secondary.calibration_bias)[1] , ', rms = ', (secondary.calibration_bias_rms)[1] 
        print, '* 1mm: ', (secondary.calibration_bias)[2] , ', rms = ', (secondary.calibration_bias_rms)[2]
        print, '* 2mm: ', (secondary.calibration_bias)[3] , ', rms = ', (secondary.calibration_bias_rms)[3]
        print, '<!--===========================================================================-->'   
     endif
     
     
     
     
        print, ''
        print, '<!--===========================================================================-->'
        print, ''
        print, '===    Point sources RMS calibration uncertainties   ==='
        print, ''
        print, '<!--===========================================================================-->'
        bs = calibration.list_of_bright_sources
        ubs = bs[ sort(bs)]
        unbs = uniq( ubs)
        print, 'List of used bright point sources = ', ubs[ unbs]
        print, '*number of selected scans          = ', strtrim(calibration.selected_scan_of_bright_sources,2)
        print, '*total number of scans             = ', strtrim(calibration.total_scan_of_bright_sources, 2)
        print, ''
        print, 'RMS calibration uncertainties :'
        print, '* A1 : ', strtrim(string(calibration.rms_calibration_error[0]*100.0d0, format='(f6.2)'), 2), '%'
        print, '* A3 : ', strtrim(string(calibration.rms_calibration_error[1]*100.0d0,format='(f6.2)'), 2), '%'
        print, '* 1mm: ', strtrim(string(calibration.rms_calibration_error[2]*100.0d0,format='(f6.2)'), 2), '%'
        print, '* 2mm: ', strtrim(string(calibration.rms_calibration_error[3]*100.0d0,format='(f6.2)'), 2), '%'
        print, '<!--===========================================================================-->'
     
     
     
        print, ''
        print, '<!--===========================================================================-->'
        print, ''
        print, '===  NEFD at zero atmospheric opacity using faint sources    ==='
        print, ''
        print, '<!--===========================================================================-->'
        faint_sources = calibration.list_of_faint_sources
        w=where(strlen(faint_sources) ge 1, nn )
        fs= ''
        if nn gt 0 then for i =0, nn-1 do fs=fs+faint_sources[w[i]]+' '
        afs = faint_sources[ sort(faint_sources)]
        ufs = uniq( afs)
        print, 'List of used faint sources        = ', strjoin( afs[ ufs]+' ')+' <br/>'
        print, 'number of selected scans          = ', strtrim(calibration.number_of_faint_source_scans,2)
        print, ''
        print, 'NEFD AT ZERO ATMOSPHERIC OPACITY [mJy s^{0.5}]:'
        print, '* A1 : ', strtrim(string(calibration.nefd[0], format='(f5.1)'),2), ' +- ', $
               strtrim(string(calibration.rms_nefd[0], format='(f5.1)'),2)
        print, '* A3 : ', strtrim(string(calibration.nefd[1], format='(f5.1)'),2), ' +- ', $
               strtrim(string(calibration.rms_nefd[1], format='(f5.1)'),2)
        print, '* 1mm: ', strtrim(string(calibration.nefd[2], format='(f5.1)'),2), ' +- ', $
               strtrim(string(calibration.rms_nefd[2], format='(f5.1)'),2)
        print, '* 2mm: ', strtrim(string(calibration.nefd[3], format='(f5.1)'),2), ' +- ', $
               strtrim(string(calibration.rms_nefd[3], format='(f5.1)'),2)
        print, ''
        print, 'MAPPING SPEED AT ZERO ATMOSPHERIC OPACITY [arcmin^2 / mJy^2 / hr]:'
        print, '* A1 : ', strtrim(string(calibration.mapping_speed[0], format='(f6.0)'),2), ' +- ', $
               strtrim(string(calibration.rms_mapping_speed[0], format='(f6.0)'),2)
        print, '* A3 : ', strtrim(string(calibration.mapping_speed[1], format='(f6.0)'),2), ' +- ', $
               strtrim(string(calibration.rms_mapping_speed[1], format='(f6.0)'),2)
        print, '* 1mm: ', strtrim(string(calibration.mapping_speed[2], format='(f6.0)'),2), ' +- ', $
               strtrim(string(calibration.rms_mapping_speed[2], format='(f6.0)'),2)
        print, '* 2mm: ', strtrim(string(calibration.mapping_speed[3], format='(f6.0)'),2), ' +- ', $
               strtrim(string(calibration.rms_mapping_speed[3], format='(f6.0)'),2)
        print, '<!--===========================================================================-->'
        
     
     
     
     ;; GATHER ALL PLOTS IN A SINGLE PDF FILE
     pdf_file_name = calibration_dir+'/calibration_main_plot_summary_'+runname[0]+'.pdf' 
     spawn, 'ls '+calibration_dir+'/Opacity/*.pdf', opa_list
     spawn, 'ls '+calibration_dir+'/Photometry/PrimaryCal/*.pdf', cal_list
     spawn, 'ls '+calibration_dir+'/Photometry/SecondaryCal/*.pdf', phot_list
     spawn, 'ls '+calibration_dir+'/Validation/*.pdf', val_list
     all_list = [opa_list, cal_list, phot_list, val_list]
     pdf_str = ''
     npdf = n_elements(all_list)
     for i=0, npdf-1 do pdf_str=pdf_str+all_list[i]+' '
     spawn, 'which pdfunite', res
     if strlen( strtrim(res, 2)) gt 0 then $
        spawn, 'pdfunite '+pdf_str+' '+pdf_file_name
     
     print, ''
     print, ''
     print, '== MAIN PLOTS =='
     print,'[[Media:Calibration_main_plot_summary_'+runname[0]+'.pdf]]'
     print,''
     print,'' 
     print, 'Please copy the lines above in the calibration wiki page'
     print, 'in the calibration table, click in the link Plots, in the row labelled Details, and paste the copied lines in the new opened page.'
     print, 'Save the page.'
     print, 'Then upload the file of the main plots by clicking on the link Media:... at the bottom of the page.'
     print, ''
     
     print, 'Thank you very much!'
     
     print, 'This the end of the code..'
     print, '.c to go out'
     stop

  endelse
  
  
end
