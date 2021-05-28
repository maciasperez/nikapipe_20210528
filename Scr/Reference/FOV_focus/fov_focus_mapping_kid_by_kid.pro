
;; copy of Processing/Pipeline/Scr/Reference/FOV_focus/fov_focus.pro

;; demonstration script to map the focus accross the entire FOV with a
;; sequence of OTF maps taken at different focus
;;----------------------------------------------------------------------

;; Sequence of out-of-focus beammap scans
;;scan_list = '20170226s'+strtrim([415, 416, 417, 418, 419], 2)
scan_list = '20170419s'+strtrim([133, 134, 135, 136, 137], 2)

source         =  'Neptune'
nk_scan2run, scan_list[0]
input_flux_th  = !nika.flux_neptune

beam_maps_dir  = !nika.plot_dir+"/beammaps_calib"
project_dir    = !nika.plot_dir+"/fov_focus_2"
nscans         = n_elements(scan_list)
result_dir     = project_dir+'/'+strtrim(scan_list[0],2)+'_'+strtrim(scan_list[nscans-1],2)
if file_test(result_dir, /directory) ne 1 then spawn, "mkdir "+result_dir



;; set to 1 to save the plot in png files
savepng  = 0
parallel = 1


;; 1./ preproc, reduce and map-making
;;     -- set to 0 once the beammaps have been processed
process      = 0
;;     -- set to 1 to relaunched the processing of already reduced scans
reprocess    = 0
;;     -- set force_kidpar to 1 and define the kidpar file here, and it will be used instead of the
;;       reference kidpar
force_kidpar = 1
input_kidpar_file  = !nika.off_proc_dir+"/kidpar_20170419s133_v2_cm_one_block_LP.fits"
;;     -- opacity correction
do_opacity_correction = 1
;;     -- noise decorrelation method
decor_method = 'common_mode_one_block'
;;     -- minimum distance to the source for a kid to be off-source
decor_cm_dmin = 90
;;     -- map angular resolution (pixel size in arcsec)
reso=4. 

;; add C0C1 into kidpar
;; input_kidpar_file = !nika.off_proc_dir+"/kidpar_20170422s61_v2_cm_one_block_LP.fits"
;; kidpar_ref_file = !nika.off_proc_dir+"/kidpar_n2r10_calib.fits"
;; kidpar_ref = mrdfits( kidpar_ref_file, 1)
;; kidpar     = mrdfits( input_kidpar_file, 1)
;; w1ref = where( kidpar_ref.type eq 1, nw1ref)
;; w1    = where( kidpar.type eq 1, nw1)
;; kidpar = kidpar[w1]
;; kidpar_ref = kidpar_ref[w1ref]
;; my_match, kidpar_ref.numdet, kidpar.numdet, suba, subb
;; kidpar.c0_skydip = 0.d0
;; kidpar.c1_skydip = 0.d0
;; kidpar[subb].c0_skydip = kidpar_ref[suba].c0_skydip
;; kidpar[subb].c1_skydip = kidpar_ref[suba].c1_skydip

;; kidpar_withskydip_file = !nika.off_proc_dir+"/kidpar_20170422s61_v2_cm_one_block_LP_calib.fits"

;; print, ''
;; print, "Ready do write: ", kidpar_withskydip_file
;; print, "Shall I proceed ? (y/n)"
;; ans = ''
;; read, ans
;; if strupcase(ans) eq 'Y' then nk_write_kidpar, kidpar, kidpar_withskydip_file 

input_kidpar_file  = !nika.off_proc_dir+"/kidpar_20170419s133_v2_cm_one_block_LP_calib.fits"

   
;; 2./ focus fit
;;     -- set to 0 once the focus are fitted
fit_focus             = 0
;;     -- rescale focus error by sqrt(Chi2/N_dof) ?
focus_error_rescaling = 1 
show_focus_fit        = 0
use_flag_kid_list     = 0

;; 3./ Focus surfaces
;;     -- discrete FoV map range
disc_zra = [-0.5, 0.5]
;;     -- continuous FoV map range
cont_zra = [-0.3, 0.3]
;;     -- flag unconsistent results
flag_kids = 0



;;=========================================================================
;; can be launched without further edition
;;
;;=========================================================================
make_focus_surfaces, scan_list, source, input_flux_th, beam_maps_dir, result_dir, $
                     savepng=savepng, process=process, $
                     force_kidpar=force_kidpar, input_kidpar_file=input_kidpar_file, $
                     do_opacity_correction=do_opacity_correction, $
                     decor_method=decor_method, decor_cm_dmin=decor_cm_dmin, reso=reso, $
                     fit_focus=fit_focus, focus_error_rescaling=focus_error_rescaling

;; 
;;
;;        Show some individual focus fits
;; 
;;____________________________________________________________________________
if show_focus_fit eq 1 then begin
   print, "%%%%%%%%%"
   print, ''
   print, 'Plot examples of focus fit...'
   print, ''


   if use_flag_kid_list lt 1 then begin
      ;; mapping the FoV in concentric circles spaced of STEP until a
      ;; maximum radius of RCMAX
      step = 70                 ; arcsec
      rcmax = 250
      ;; Pick the closest kid to (x_center,y_center) 
      rmax = 5.
      
      nr = round(rcmax/step)
      r_list = dindgen(nr)*step
      npoints = 1.
      for ir = 0, nr-1 do npoints = npoints+ceil((2.*!dpi*r_list[ir])/step)
      r_center_list = fltarr(npoints)
      a_center_list = fltarr(npoints)
      count=0
      for ir = 0, nr-1 do begin
         na = ceil((2.*!dpi*r_list[ir])/step)
         if na gt 0 then begin
            ind = count+indgen(na)
            r_center_list[ind] = ir*step
            a_center_list[ind] = dindgen(na)*360./na
         endif
         count+=na
      endfor
;; radial to carth
      x_center_list = r_center_list*cos(a_center_list*!dtor)
      y_center_list = r_center_list*sin(a_center_list*!dtor)
      ncenter = n_elements(x_center_list)
      
      kp = mrdfits(input_kidpar_file, 1)
      
      numdetlist_ = lonarr(ncenter, 3)
      keep = intarr(ncenter)
      for i=0, ncenter-1 do begin
         for iarray=1, 3 do begin
            w1 = where(kp.type eq 1 and kp.array eq iarray, nw1)
            d = sqrt((kp[w1].nas_x-x_center_list[i])^2 + (kp[w1].nas_y-y_center_list[i])^2)
            wc = where(d le rmax, nwc)
            ;;print,nwc, kp[w1[wc[0]]].numdet
            if nwc gt 0 then numdetlist_[i,iarray-1]=kp[w1[wc[0]]].numdet
         endfor
         w = where(numdetlist_[i, *] gt 0, nw)
         if nw eq 3 then keep[i] = 1
      endfor
      wkeep = where(keep gt 0, nkeep)
      numdetlist = lonarr(nkeep, 3)
      for ia=0, 2 do numdetlist[*, ia] = numdetlist_[wkeep, ia]
      nkids = n_elements(numdetlist)
      
      ;; plot de fit habituel pour ncenter
      plot_output_dir = result_dir+"/Plots"
      png=0
      ps=0
      get_focus_error = 1
      
      for icenter = 0, nkeep-1 do begin
         
         wind, 1, 1, /free, /large
         scan_plot_file = plot_output_dir+"/plot_focus_"+strtrim(x_center_list[icenter],2)+"_"+strtrim(y_center_list[icenter],2)
         outplot, file = scan_plot_file, png = png, ps = ps
         my_multiplot, 3, 4, pp, pp1, /rev, gap_x=0.05, ymargin=0.05, gap_y=0.05
         
   
         for iarray = 0, 2 do begin
            ;; read the result file
            resfile = result_dir+"/focus_results_"+strtrim(numdetlist[icenter, iarray],2)+'.save'
            if file_test(resfile) gt 0 then begin
               restore, resfile
               
               dxfocus = (max(focus)-min(focus))
               xx = dindgen(100)/99*dxfocus*1.4 + min(focus)-dxfocus*0.2
               
               fit_p1 = xx*0.d0
               fit_p2 = xx*0.d0
               fit_p3 = xx*0.d0
               fit_p4 = xx*0.d0
               for i = 0, n_elements(cp1_all)-1 do begin
                  fit_p1 += cp1_all[i]*xx^i
                  fit_p2 += cp2_all[i]*xx^i
                  fit_p3 += cp3_all[i]*xx^i
                  fit_p4 += cp4_all[i]*xx^i
               endfor
               xra = minmax(focus) + [-0.2,0.2]*(max(focus)-min(focus))
               opt_z_p1 = -cp1_all[1]/(2.d0*cp1_all[2])
               opt_z_p2 = -cp2_all[1]/(2.d0*cp2_all[2])
               opt_z_p3 = -cp3_all[1]/(2.d0*cp3_all[2])
               opt_z_p4 = -cp4_all[1]/(2.d0*cp4_all[2])
               pm=string(43B)
               err_opt_z_p1 = err_focus_res[0]
               err_opt_z_p2 = err_focus_res[1]
               err_opt_z_p3 = err_focus_res[2]
               err_opt_z_p4 = err_focus_res[3]

               
               nscans = n_elements(peak_res)
               array = iarray+1

               ndof = n_elements(focus) - n_elements(cp1_all)
               
               ;; PEAK
               fit_value = focus*0.d0
               for i = 0, n_elements(cp1_all)-1 do fit_value += cp1_all[i]*focus^i
               chi2 = total( (peak_res[*]-fit_value)^2/sigma_peak_res[*]^2)/ndof
               foc_corr = opt_z_p1 - focus_res[0]
               dyra = max([fit_p1,peak_res]) - min([fit_p1, peak_res])
               yra = minmax([fit_p1, peak_res]) + [-0.3,0.5]*dyra
               ploterror, focus, peak_res, sigma_peak_res, $
                          psym = 8, xtitle='Focus [mm]', position=pp[iarray,0,*], /noerase, chars=0.6, /xs, $
                          xra=xra, yra=yra, /ys
               xyouts, focus-0.05, peak_res+0.05, strmid(scan_list,9), orient=90, chars=0.6
               ;;lfit = linfit( focus, peak_res, measure_errors=sigma_peak_res)
               ;;oplot, [-10,10], lfit[0] + lfit[1]*[-10,10], line=2
               oplot, xx, fit_p1, col = 250
               oplot, [1,1]*opt_z_p1, [-1,1]*1e10, col=70
               if not(keyword_set(get_focus_error)) then begin
                  leg_txt = ['Peak A'+strtrim(array,2), 'Opt '+strtrim(focus_type,2)+': '+num2string(opt_z_p1)]
                  if foc_corr ne 0.d0 then leg_txt = [leg_txt, 'Opt. AVG '+strtrim(focus_type,2)+': '+num2string(opt_z_p1+foc_corr)]
               endif else begin
                  leg_txt = ['Peak A'+strtrim(array,2), $
                             'Opt '+strtrim(focus_type,2)+': '+num2string(opt_z_p1)+'!9'+pm+'!x'+num2string(err_opt_z_p1)]
                  if foc_corr ne 0.d0 then leg_txt = [leg_txt, $
                                                      'Opt. AVG '+strtrim(focus_type,2)+': '+$
                                                      num2string(opt_z_p1+foc_corr)+'!9'+pm+'!x'+num2string(err_opt_z_p1)]
               endelse
               leg_txt = [leg_txt, 'red. chi2: '+strtrim(string(chi2, format='(f6.2)'),2)]
               legendastro, leg_txt, box = 0, chars = 0.6
               
               ;; FLUX (fwhm fixed)
               fit_value = focus*0.d0
               for i = 0, n_elements(cp4_all)-1 do fit_value += cp4_all[i]*focus^i
               chi2 = total( (flux_res[*]-fit_value)^2/sigma_flux_res[*]^2)/ndof
               foc_corr = opt_z_p4 - focus_res[3]
               dyra = max([fit_p4,flux_res]) - min([fit_p4, flux_res])
               yra = minmax([fit_p4, flux_res]) + [-0.3,0.5]*dyra
               ploterror, focus, flux_res, sigma_flux_res, $
                          psym = 8, xtitle='Focus [mm]', position=pp[iarray,1,*], /noerase, chars=0.6, /xs, $
                          xra=xra, yra=yra, /ys
               xyouts, focus-0.05, flux_res+0.05, strmid(scan_list,9), orient=90, chars=0.6
               ;;lfit = linfit( focus, peak_res, measure_errors=sigma_peak_res)
               ;;oplot, [-10,10], lfit[0] + lfit[1]*[-10,10], line=2 
               oplot, xx, fit_p4, col = 250
               oplot, [1,1]*opt_z_p4, [-1,1]*1e10, col=70
               if not(keyword_set(get_focus_error)) then begin
                  leg_txt = ['Flux A'+strtrim(array,2), 'Opt '+strtrim(focus_type,2)+': '+num2string(opt_z_p4)]
                  if foc_corr ne 0.d0 then leg_txt = [leg_txt, 'Opt. AVG '+strtrim(focus_type,2)+': '+num2string(opt_z_p4+foc_corr)]
               endif else begin
                  leg_txt = ['Flux A'+strtrim(array,2), $
                             'Opt '+strtrim(focus_type,2)+': '+num2string(opt_z_p4)+'!9'+pm+'!x'+num2string(err_opt_z_p4)]
                  if foc_corr ne 0.d0 then leg_txt = [leg_txt, $
                                                      'Opt. AVG '+strtrim(focus_type,2)+': '+$
                                                      num2string(opt_z_p4+foc_corr)+'!9'+pm+'!x'+num2string(err_opt_z_p4)]
               endelse
               ;leg_txt = [leg_txt, 'red. chi2: '+strtrim(string(chi2, format='(f6.2)'),2)]
               legendastro, leg_txt, box = 0, chars = 0.6
               
               ;; FWHM
               fit_value = focus*0.d0
               for i = 0, n_elements(cp2_all)-1 do fit_value += cp2_all[i]*focus^i
               chi2 = total( (fwhm_res[*]-fit_value)^2/sigma_fwhm_res[*]^2)/ndof
               foc_corr = opt_z_p2 - focus_res[1]
               yra = minmax([fit_p2, fwhm_res])
               ploterror, focus, fwhm_res, sigma_fwhm_res, $
                          psym = 8, xtitle='Focus [mm]',position=pp[iarray, 2,*], /noerase, chars=0.6, /xs, xra=xra
               oplot, xx, fit_p2, col = 250
               oplot, [1,1]*opt_z_p2, [-1,1]*1e10, col=70
               ;;lfit = linfit( focus, fwhm_res, measure_errors=sigma_fwhm_res)
               ;;oplot, [-10,10], lfit[0] + lfit[1]*[-10,10], line=2
               if get_focus_error eq 0 then begin
                  leg_txt = ['FWHM A'+strtrim(array,2), 'Opt '+strtrim(focus_type,2)+': '+num2string(opt_z_p2)]
                  if foc_corr ne 0.d0 then leg_txt = [leg_txt, 'Opt. AVG '+strtrim(focus_type,2)+': '+num2string(opt_z_p2+foc_corr)]
               endif else begin
                  leg_txt = ['FWHM A'+strtrim(array,2), $
                             'Opt '+strtrim(focus_type,2)+': '+num2string(opt_z_p2)+'!9'+pm+'!x'+num2string(err_opt_z_p2)]
                  if foc_corr ne 0.d0 then leg_txt = [leg_txt, $
                                                      'Opt. AVG '+strtrim(focus_type,2)+': '+$
                                                      num2string(opt_z_p2+foc_corr)+'!9'+pm+'!x'+num2string(err_opt_z_p2)]
               endelse
               leg_txt = [leg_txt, 'red. chi2: '+strtrim(string(chi2, format='(f6.2)'),2)]
               legendastro, leg_txt, box = 0, chars = 0.6
               
               ;; ELLIPTICITY
               fit_value = focus*0.d0
               for i = 0, n_elements(cp3_all)-1 do fit_value += cp3_all[i]*focus^i
               chi2 = total( (ellipt_res[*]-fit_value)^2/sigma_ellipt_res[*]^2)/ndof
               foc_corr = opt_z_p3 - focus_res[2]
               yra = minmax([fit_p3, ellipt_res])
               ploterror, focus, ellipt_res, sigma_ellipt_res, $
                          psym=8, xtitle='Focus [mm]', position=pp[iarray, 3,*], /noerase, /xs, chars=0.6, xra=xra
               oplot, xx, fit_p3, col=250
               oplot, [1,1]*opt_z_p3, [-1,1]*1e10, col=70
               ;;lfit = linfit( focus, ellipt_res, measure_errors=sigma_ellipt_res)
               ;;oplot, [-10,10], lfit[0] + lfit[1]*[-10,10], line=2
               leg_txt = ['Ellipt A'+strtrim(array,2), 'Opt '+strtrim(focus_type,2)+': '+num2string(opt_z_p3)]
               if foc_corr ne 0.d0 then leg_txt = [leg_txt, 'Opt. AVG '+strtrim(focus_type,2)+': '+num2string(opt_z_p3+foc_corr)]
               leg_txt = [leg_txt, 'red. chi2: '+strtrim(string(chi2, format='(f6.2)'),2)]
               legendastro, leg_txt, box = 0, chars = 0.6
               
            endif else print,"no result file: ", resfile
            
         endfor
         outplot, /close
         
         
      endfor
      
   endif else begin
      ;;  show fit for kids with outlier focus
      
      kp = mrdfits(input_kidpar_file, 1)
      ;; plot de fit habituel pour ncenter
      plot_output_dir = result_dir+"/Plots"
      png=0
      ps=0
      get_focus_error = 1

      for iarray = 1, 3 do begin
         ;; read the kid flag list
         restore, result_dir+"/flag_kid_list_arr"+strtrim(iarray, 2)+".save"

         nflag = n_elements(flag_list)
         for ik = 0, nflag-1 do begin
            
            wind, 1, 1, /free, /large
            my_multiplot, 1, 4, pp, pp1, /rev, gap_x=0.05, ymargin=0.05, gap_y=0.05

            ;; read the result file
            resfile = result_dir+"/focus_results_"+strtrim(flag_list[ik],2)+'.save'
            if file_test(resfile) gt 0 then begin
               restore, resfile
               
               dxfocus = (max(focus)-min(focus))
               xx = dindgen(100)/99*dxfocus*1.4 + min(focus)-dxfocus*0.2
               
               fit_p1 = xx*0.d0
               fit_p2 = xx*0.d0
               fit_p3 = xx*0.d0
               fit_p4 = xx*0.d0
               for i = 0, n_elements(cp1_all)-1 do begin
                  fit_p1 += cp1_all[i]*xx^i
                  fit_p2 += cp2_all[i]*xx^i
                  fit_p3 += cp3_all[i]*xx^i
                                ;fit_p4 += cp4_all[i]*xx^i
               endfor
               xra = minmax(focus) + [-0.2,0.2]*(max(focus)-min(focus))
               opt_z_p1 = -cp1_all[1]/(2.d0*cp1_all[2])
               opt_z_p2 = -cp2_all[1]/(2.d0*cp2_all[2])
               opt_z_p3 = -cp3_all[1]/(2.d0*cp3_all[2])
               ;;opt_z_p4 = -cp4_all[1]/(2.d0*cp4_all[2])
               opt_z_p4 = focus_res[3]
               pm=string(43B)
               err_opt_z_p1 = err_focus_res[0]
               err_opt_z_p2 = err_focus_res[1]
               err_opt_z_p3 = err_focus_res[2]
               err_opt_z_p4 = err_focus_res[3]
               
               nscans = n_elements(peak_res)
               array = iarray
               
               ;; PEAK
               fit_value = focus*0.d0
               for i = 0, n_elements(cp1_all)-1 do fit_value += cp1_all[i]*focus^i
               chi2 = total( (peak_res[*]-fit_value)^2/sigma_peak_res[*]^2)/ndof
               foc_corr = opt_z_p1 - focus_res[0]
               dyra = max([fit_p1,peak_res]) - min([fit_p1, peak_res])
               yra = minmax([fit_p1, peak_res]) + [-0.3,0.5]*dyra
               ploterror, focus, peak_res, sigma_peak_res, $
                          psym = 8, xtitle='Focus [mm]', position=pp[0,0,*], /noerase, chars=0.6, /xs, $
                          xra=xra, yra=yra, /ys
               xyouts, focus-0.05, peak_res+0.05, strmid(scan_list,9), orient=90, chars=0.6
               ;;lfit = linfit( focus, peak_res, measure_errors=sigma_peak_res)
               ;;oplot, [-10,10], lfit[0] + lfit[1]*[-10,10], line=2
               oplot, xx, fit_p1, col = 250
               oplot, [1,1]*opt_z_p1, [-1,1]*1e10, col=70
               if not(keyword_set(get_focus_error)) then begin
                  leg_txt = ['Peak A'+strtrim(array,2), 'Opt '+strtrim(focus_type,2)+': '+num2string(opt_z_p1)]
                  if foc_corr ne 0.d0 then leg_txt = [leg_txt, 'Opt. AVG '+strtrim(focus_type,2)+': '+num2string(opt_z_p1+foc_corr)]
               endif else begin
                  leg_txt = ['Peak A'+strtrim(array,2), $
                             'Opt '+strtrim(focus_type,2)+': '+num2string(opt_z_p1)+'!9'+pm+'!x'+num2string(err_opt_z_p1)]
                  if foc_corr ne 0.d0 then leg_txt = [leg_txt, $
                                                      'Opt. AVG '+strtrim(focus_type,2)+': '+$
                                                      num2string(opt_z_p1+foc_corr)+'!9'+pm+'!x'+num2string(err_opt_z_p1)]
               endelse
               leg_txt = [leg_txt, 'red. chi2: '+strtrim(string(chi2, format='(f6.2)'),2)]
               legendastro, leg_txt, box = 0, chars = 0.6
               
               ;; FLUX (fwhm fixed)
               ;;fit_value = focus*0.d0
               ;for i = 0, n_elements(cp4_all)-1 do fit_value += cp4_all[i]*focus^i
               ;chi2 = total( (flux_res[*]-fit_value)^2/sigma_flux_res[*]^2)/ndof
               foc_corr = opt_z_p4 - focus_res[3]
               dyra = max([fit_p4,flux_res]) - min([fit_p4, flux_res])
               yra = minmax([fit_p4, flux_res]) + [-0.3,0.5]*dyra
               ploterror, focus, flux_res, sigma_flux_res, $
                          psym = 8, xtitle='Focus [mm]', position=pp[0,1,*], /noerase, chars=0.6, /xs, $
                          xra=xra, yra=yra, /ys
               xyouts, focus-0.05, flux_res+0.05, strmid(scan_list,9), orient=90, chars=0.6
               ;;lfit = linfit( focus, peak_res, measure_errors=sigma_peak_res)
               ;;oplot, [-10,10], lfit[0] + lfit[1]*[-10,10], line=2 
               oplot, xx, fit_p4, col = 250
               oplot, [1,1]*opt_z_p4, [-1,1]*1e10, col=70
               if not(keyword_set(get_focus_error)) then begin
                  leg_txt = ['Flux A'+strtrim(array,2), 'Opt '+strtrim(focus_type,2)+': '+num2string(opt_z_p4)]
                  if foc_corr ne 0.d0 then leg_txt = [leg_txt, 'Opt. AVG '+strtrim(focus_type,2)+': '+num2string(opt_z_p4+foc_corr)]
               endif else begin
                  leg_txt = ['Flux A'+strtrim(array,2), $
                             'Opt '+strtrim(focus_type,2)+': '+num2string(opt_z_p4)+'!9'+pm+'!x'+num2string(err_opt_z_p4)]
                  if foc_corr ne 0.d0 then leg_txt = [leg_txt, $
                                                      'Opt. AVG '+strtrim(focus_type,2)+': '+$
                                                      num2string(opt_z_p4+foc_corr)+'!9'+pm+'!x'+num2string(err_opt_z_p4)]
               endelse
               ;leg_txt = [leg_txt, 'red. chi2: '+strtrim(string(chi2, format='(f6.2)'),2)]
               legendastro, leg_txt, box = 0, chars = 0.6
               
               ;; FWHM
               fit_value = focus*0.d0
               for i = 0, n_elements(cp2_all)-1 do fit_value += cp2_all[i]*focus^i
               chi2 = total( (fwhm_res[*]-fit_value)^2/sigma_fwhm_res[*]^2)/ndof
               foc_corr = opt_z_p2 - focus_res[1]
               yra = minmax([fit_p2, fwhm_res])
               ploterror, focus, fwhm_res, sigma_fwhm_res, $
                          psym = 8, xtitle='Focus [mm]',position=pp[0, 2,*], /noerase, chars=0.6, /xs, xra=xra
               oplot, xx, fit_p2, col = 250
               oplot, [1,1]*opt_z_p2, [-1,1]*1e10, col=70
               ;;lfit = linfit( focus, fwhm_res, measure_errors=sigma_fwhm_res)
               ;;oplot, [-10,10], lfit[0] + lfit[1]*[-10,10], line=2
               if get_focus_error eq 0 then begin
                  leg_txt = ['FWHM A'+strtrim(array,2), 'Opt '+strtrim(focus_type,2)+': '+num2string(opt_z_p2)]
                  if foc_corr ne 0.d0 then leg_txt = [leg_txt, 'Opt. AVG '+strtrim(focus_type,2)+': '+num2string(opt_z_p2+foc_corr)]
               endif else begin
                  leg_txt = ['FWHM A'+strtrim(array,2), $
                             'Opt '+strtrim(focus_type,2)+': '+num2string(opt_z_p2)+'!9'+pm+'!x'+num2string(err_opt_z_p2)]
                  if foc_corr ne 0.d0 then leg_txt = [leg_txt, $
                                                      'Opt. AVG '+strtrim(focus_type,2)+': '+$
                                                      num2string(opt_z_p2+foc_corr)+'!9'+pm+'!x'+num2string(err_opt_z_p2)]
               endelse
               leg_txt = [leg_txt, 'red. chi2: '+strtrim(string(chi2, format='(f6.2)'),2)]
               legendastro, leg_txt, box = 0, chars = 0.6
               
               ;; ELLIPTICITY
               fit_value = focus*0.d0
               for i = 0, n_elements(cp3_all)-1 do fit_value += cp3_all[i]*focus^i
               chi2 = total( (ellipt_res[*]-fit_value)^2/sigma_ellipt_res[*]^2)/ndof
               foc_corr = opt_z_p3 - focus_res[2]
               yra = minmax([fit_p3, ellipt_res])
               ploterror, focus, ellipt_res, sigma_ellipt_res, $
                          psym=8, xtitle='Focus [mm]', position=pp[0, 3,*], /noerase, /xs, chars=0.6, xra=xra
               oplot, xx, fit_p3, col=250
               oplot, [1,1]*opt_z_p3, [-1,1]*1e10, col=70
               ;;lfit = linfit( focus, ellipt_res, measure_errors=sigma_ellipt_res)
               ;;oplot, [-10,10], lfit[0] + lfit[1]*[-10,10], line=2
               leg_txt = ['Ellipt A'+strtrim(array,2), 'Opt '+strtrim(focus_type,2)+': '+num2string(opt_z_p3)]
               if foc_corr ne 0.d0 then leg_txt = [leg_txt, 'Opt. AVG '+strtrim(focus_type,2)+': '+num2string(opt_z_p3+foc_corr)]
               leg_txt = [leg_txt, 'red. chi2: '+strtrim(string(chi2, format='(f6.2)'),2)]
               legendastro, leg_txt, box = 0, chars = 0.6


               ans=''
               print,"type enter for continuing"
               read, ans
               
            endif
            
         endfor
      endfor
     
   endelse
   
   stop
endif


print, "%%%%%%%%%"
print, ''
print, 'Plotting results...'
print, ''
print, ".c to do the plots"
;stop


;;  
;;        Plotting
;; 
;;_______________________________________________________________
;; Summary plot (or even better map of the results)

suffixe = ''
;;if focus_time_drift gt 0 then suffixe = "_zdrift"
;;if focus_error_rescaling gt 0 then suffixe = suffixe+'_sigma_rescaled'

output_plot_file = 'fov_focus_'+strtrim(scan_list[0],2)+'_'+strtrim(scan_list[nscans-1],2)+suffixe
png=savepng

kp = mrdfits(input_kidpar_file, 1)

z0 = [-0.35, -0.25, -0.25]

zra=[-0.9, 0.1]
zra=[-0.5, 0.5]
zra=[-0.4, 0.4]
;;zra=[-0.2, 0.2]

;; png=0
;; ps=1
;; ps_xsize    = 22.        ;; in cm
;; ps_ysize    = 11.         ;; in cm
;; ps_charsize = 1.
;; ps_yoffset  = 0.
;; ps_thick    = 2.
ysize = 750
if flag_kids then ysize=400
wind, 1, 1, /free, xsize=900, ysize=ysize
outplot, file=output_plot_file, png=png, ps=ps, xsize=ps_xsize, ysize=ps_ysize, charsize=ps_charsize;, yoffset=ps_yoffset, thick=ps_thick
my_multiplot, 3, 3, pp, pp1, ymargin=0.08, gap_x=0.08, xmargin = 0.06
charsize = 0.8
order = [1, 3, 2]
ss = [0.4, 0.5, 0.4]
;; restore kid-by-kid focus result files and gather in a single table
for ilam=0, 2 do begin
   iarray = order[ilam]
   w1 = where(kp.type eq 1 and kp.array eq iarray, nw1)

   xra = minmax(kp[w1].nas_x)
   xra = xra + [-1,1]*0.1*(xra[1]-xra[0])
   yra = minmax(kp[w1].nas_y)
   yra = yra + [-1,1]*0.1*(yra[1]-yra[0])


   z_peak = dblarr(nw1)
   s_peak = dblarr(nw1)
   c_peak = dblarr(nw1)
   z_flux = dblarr(nw1)
   s_flux = dblarr(nw1)
   c_flux = dblarr(nw1)
   z_fwhm = dblarr(nw1)
   s_fwhm = dblarr(nw1)
   c_fwhm = dblarr(nw1)
   z_elli = dblarr(nw1)
   s_elli = dblarr(nw1)
   c_elli = dblarr(nw1)

   for ik = 0, nw1-1 do begin
      resfile = result_dir+"/focus_results_"+strtrim(kp[w1[ik]].numdet,2)+'.save'
      if file_test(resfile) gt 0 then begin
         restore, resfile
         z_peak[ik] = focus_res[0]
         z_fwhm[ik] = focus_res[1]
         z_elli[ik] = focus_res[2]
         z_flux[ik] = focus_res[3]
         s_peak[ik] = err_focus_res[0]
         s_fwhm[ik] = err_focus_res[1]
         s_elli[ik] = err_focus_res[2]
         s_flux[ik] = err_focus_res[3]

         ndof = 2.
         fit_value = focus*0.d0
         for i = 0, n_elements(cp1_all)-1 do fit_value += cp1_all[i]*focus^i
         c_peak[ik] = total( (peak_res[*]-fit_value)^2/sigma_peak_res[*]^2)/ndof
         fit_value = focus*0.d0
         for i = 0, n_elements(cp2_all)-1 do fit_value += cp2_all[i]*focus^i
         c_fwhm[ik] = total( (fwhm_res[*]-fit_value)^2/sigma_fwhm_res[*]^2)/ndof
         fit_value = focus*0.d0
         for i = 0, n_elements(cp3_all)-1 do fit_value += cp3_all[i]*focus^i
         c_elli[ik] = total( (ellipt_res[*]-fit_value)^2/sigma_ellipt_res[*]^2)/ndof
         ;;fit_value = focus*0.d0
         ;;for i = 0, n_elements(cp4_all)-1 do fit_value += cp4_all[i]*focus^i
         ;;c_flux[ik] = total( (flux_res[*]-fit_value)^2/sigma_flux_res[*]^2)/ndof
         
      endif
   endfor

   d = sqrt((kp[w1].nas_x)^2 + (kp[w1].nas_y)^2)
   ;;w0 = where(kp.type eq 1 and kp.array eq iarray and d le 3.*!nika.fwhm_array[iarray-1], nw0)
   w0 = where(d le 80., nw0)
   print,nw0
   ;;optimisation de l'estimée focus au centre
   ;; nr = 150
   ;; z0_peak = dblarr(nr)
   ;; z0_flux = dblarr(nr)
   ;; z0_fwhm = dblarr(nr)
   ;; z0_elli = dblarr(nr)
   ;; s0_peak = dblarr(nr)
   ;; s0_flux = dblarr(nr)
   ;; s0_fwhm = dblarr(nr)
   ;; s0_elli = dblarr(nr)
   ;; for rr = 0, nr-1 do begin
   ;;    w0 = where(kp.type eq 1 and kp.array eq iarray and d le 5.+rr, nw0)
   ;;    if nw0 gt 0 then begin
   ;;       w_peak = where(s_peak[w0] gt 0.)
   ;;       w_flux = where(s_flux[w0] gt 0.)
   ;;       w_fwhm = where(s_fwhm[w0] gt 0.)
   ;;       w_elli = where(s_elli[w0] gt 0.)
   ;;       ;; i0_peak = total(1.d0/s_peak[w0[w_peak]]^2)
   ;;       ;; i0_flux = total(1.d0/s_flux[w0[w_flux]]^2)
   ;;       ;; i0_fwhm = total(1.d0/s_fwhm[w0[w_fwhm]]^2)
   ;;       ;; i0_elli = total(1.d0/s_elli[w0[w_elli]]^2)
         
   ;;       ;; z0_peak[rr] = total(z_peak[w0[w_peak]]/s_peak[w0[w_peak]]^2)/i0_peak
   ;;       ;; z0_flux[rr] = total(z_flux[w0[w_flux]]/s_flux[w0[w_flux]]^2)/i0_flux
   ;;       ;; z0_fwhm[rr] = total(z_fwhm[w0[w_fwhm]]/s_fwhm[w0[w_fwhm]]^2)/i0_fwhm
   ;;       ;; z0_elli[rr] = total(z_elli[w0[w_elli]]/s_elli[w0[w_elli]]^2)/i0_elli
         
   ;;       ;; s0_peak[rr] = sqrt(1d0/i0_peak)
   ;;       ;; s0_flux[rr] = sqrt(1d0/i0_flux)
   ;;       ;; s0_fwhm[rr] = sqrt(1d0/i0_fwhm)
   ;;       ;; s0_elli[rr] = sqrt(1d0/i0_elli)
         
   ;;       z0_peak[rr] = median(z_peak[w0[w_peak]])
   ;;       z0_flux[rr] = median(z_flux[w0[w_flux]])
   ;;       z0_fwhm[rr] = median(z_fwhm[w0[w_fwhm]])
   ;;       z0_elli[rr] = median(z_elli[w0[w_elli]])
         
   ;;       s0_peak[rr] = sqrt(mean(s_peak[w0[w_peak]]^2))
   ;;       s0_flux[rr] = sqrt(mean(s_flux[w0[w_flux]]^2))
   ;;       s0_fwhm[rr] = sqrt(mean(s_fwhm[w0[w_fwhm]]^2))
   ;;       s0_elli[rr] = sqrt(mean(s_elli[w0[w_elli]]^2))
         
   ;;       print, nw0
   ;;    endif
   ;; endfor
   ;; print,'---'
   ;; w0 = where(kp.type eq 1 and kp.array eq iarray and d le 1.3*!nika.fwhm_array[iarray-1], nw0)
   ;; print,nw0
   ;; print,'-------'
   ;; ind = indgen(nr)+5.
   ;; wind, 1, 1, /free
   ;; plot, ind, z0_peak, yr = [-0.8, 0.3], /ys, /nodata, title="A"+strtrim(iarray,2), /xs 
   ;; oploterror,  ind, z0_peak, s0_peak, psym=8
   ;; oploterror,  ind+0.5, z0_fwhm, s0_fwhm, psym=8, col=80, errcol=80
   ;; oploterror,  ind+1, z0_elli, s0_elli, psym=8, col=150, errcol=150
   ;; oploterror,  ind+2, z0_flux, s0_flux, psym=8, col=250, errcol=250
   ;; stop
   
   if nw0 gt 0 then begin
      w_peak = where(s_peak[w0] gt 0. and z_peak[w0] lt 0. and z_peak[w0] gt -1., npeak)
      w_flux = where(s_flux[w0] gt 0. and z_flux[w0] lt 0. and z_flux[w0] gt -1., nflux)
      w_fwhm = where(s_fwhm[w0] gt 0. and z_fwhm[w0] lt 0. and z_fwhm[w0] gt -1., nfwhm)
      w_elli = where(s_elli[w0] gt 0., nelli)
      ;; i0_peak = total(1.d0/s_peak[w0[w_peak]]^2)
      ;; i0_flux = total(1.d0/s_flux[w0[w_flux]]^2)
      ;; i0_fwhm = total(1.d0/s_fwhm[w0[w_fwhm]]^2)
      ;; i0_elli = total(1.d0/s_elli[w0[w_elli]]^2)
      
      ;; z0_peak = total(z_peak[w0[w_peak]]/s_peak[w0[w_peak]]^2)/i0_peak
      ;; z0_flux = total(z_flux[w0[w_flux]]/s_flux[w0[w_flux]]^2)/i0_flux
      ;; z0_fwhm = total(z_fwhm[w0[w_fwhm]]/s_fwhm[w0[w_fwhm]]^2)/i0_fwhm
      ;; z0_elli = total(z_elli[w0[w_elli]]/s_elli[w0[w_elli]]^2)/i0_elli
      
      ;; s0_peak = sqrt(1d0/i0_peak)
      ;; s0_flux = sqrt(1d0/i0_flux)
      ;; s0_fwhm = sqrt(1d0/i0_fwhm)
      ;; s0_elli = sqrt(1d0/i0_elli)

      z0_peak = median(z_peak[w0[w_peak]])
      z0_flux = median(z_flux[w0[w_flux]])
      z0_fwhm = median(z_fwhm[w0[w_fwhm]])
      z0_elli = median(z_elli[w0[w_elli]])
      
      s0_peak = sqrt(mean(s_peak[w0[w_peak]]^2))
      s0_flux = sqrt(mean(s_flux[w0[w_flux]]^2))
      s0_fwhm = sqrt(mean(s_fwhm[w0[w_fwhm]]^2))
      s0_elli = sqrt(mean(s_elli[w0[w_elli]]^2))
      
      print, 'npeak = ', npeak
      print, 'nflux = ', nflux
      print, 'nfwhm = ', nfwhm
      print, 'nelli = ', nelli
   endif

   if flag_kids gt 0 then begin
      
      zmax = -0.1
      zmin = -0.9
      
      w_flag = where(z_peak gt zmax or z_peak lt zmin or $
                     z_flux gt zmax or z_flux lt zmin or $
                     z_fwhm gt zmax or z_fwhm lt zmin, nflag)

      print,"nb flagged kids: ", nflag

            
      histo_min = -0.1
      histo_max = 0.6
      HIST_PLOT, s_peak[w_flag], MIN=histo_min, MAX=histo_max, noplot=1, $
                 BINSIZE=histo_bin, NORMALIZE=NORMALIZE, dostat=0, FILL=FILL, X=X1,Y=Y1, hist=hist
      HIST_PLOT, s_peak, MIN=histo_min, MAX=histo_max, noplot=0, $
                 BINSIZE=histo_bin, NORMALIZE=NORMALIZE, dostat=1, fitgauss=0, FILL=FILL, X=X2,Y=Y2,  $
                 xtitle="A"+strtrim(iarray, 2)+": peak", $
                 position=[0.1/3. +0.33*(0), 0.1, 0.33*(1) -0.1/3., 0.9 ], $
                 noerase=1, xstyle=1, charsize=charsize
      oplot, x1, y1, col=250
            
      HIST_PLOT, s_flux[w_flag], MIN=histo_min, MAX=histo_max, noplot=1, $
                 BINSIZE=histo_bin, NORMALIZE=NORMALIZE, dostat=0, FILL=FILL, X=X1,Y=Y1, hist=hist
      HIST_PLOT, s_flux, MIN=histo_min, MAX=histo_max, noplot=0, $
                 BINSIZE=histo_bin, NORMALIZE=NORMALIZE, dostat=1, fitgauss=0, FILL=FILL, X=X2,Y=Y2, $
                 xtitle="A"+strtrim(iarray, 2)+": flux", $
                 position=[0.1/3. +0.33*(1), 0.1, 0.33*(2) -0.1/3., 0.9 ], $
                 noerase=1, xstyle=1, charsize=charsize
      oplot, x1, y1, col=250
            
      HIST_PLOT, s_fwhm[w_flag], MIN=histo_min, MAX=histo_max, noplot=1, $
                 BINSIZE=histo_bin, NORMALIZE=NORMALIZE, dostat=0, FILL=FILL, X=X1,Y=Y1, hist=hist
      HIST_PLOT, s_fwhm, MIN=histo_min, MAX=histo_max, noplot=0, $
                 BINSIZE=histo_bin, NORMALIZE=NORMALIZE, dostat=1, fitgauss=0, FILL=FILL, X=X2,Y=Y2, $
                 xtitle="A"+strtrim(iarray, 2)+": fwhm", $
                 position=[0.1/3. +0.33*(2), 0.1, 0.33*(3) -0.1/3., 0.9 ], $
                 noerase=1, xstyle=1, charsize=charsize
      oplot, x1, y1, col=250
      
      ;;flag_list = kp[w1[w_flag]].numdet
      ;;save, flag_list, filename=result_dir+"/flag_kid_list_arr"+strtrim(iarray, 2)+".save"
      wd, /a

      
      ;; reduced chi2
      histo_min = -0.1
      histo_max = 200
      HIST_PLOT, c_peak[w_flag], MIN=histo_min, MAX=100, noplot=1, $
                 BINSIZE=2, NORMALIZE=NORMALIZE, dostat=0, FILL=FILL, X=X1,Y=Y1, hist=hist
      HIST_PLOT, c_peak, MIN=histo_min, MAX=100, noplot=0, $
                 BINSIZE=2, NORMALIZE=NORMALIZE, dostat=1, fitgauss=0, FILL=FILL, X=X2,Y=Y2,  $
                 xtitle="A"+strtrim(iarray, 2)+": peak", $
                 position=[0.1/3. +0.33*(0), 0.1, 0.33*(1) -0.1/3., 0.9 ], $
                 noerase=1, xstyle=1, charsize=charsize
      oplot, x1, y1, col=250
            
      HIST_PLOT, c_flux[w_flag], MIN=histo_min, MAX=100, noplot=1, $
                 BINSIZE=2, NORMALIZE=NORMALIZE, dostat=0, FILL=FILL, X=X1,Y=Y1, hist=hist
      HIST_PLOT, c_flux, MIN=histo_min, MAX=100, noplot=0, $
                 BINSIZE=2, NORMALIZE=NORMALIZE, dostat=1, fitgauss=0, FILL=FILL, X=X2,Y=Y2, $
                 xtitle="A"+strtrim(iarray, 2)+": flux", $
                 position=[0.1/3. +0.33*(1), 0.1, 0.33*(2) -0.1/3., 0.9 ], $
                 noerase=1, xstyle=1, charsize=charsize
      oplot, x1, y1, col=250
            
      HIST_PLOT, c_fwhm[w_flag], MIN=histo_min, MAX=10, noplot=1, $
                 BINSIZE=0.2, NORMALIZE=NORMALIZE, dostat=0, FILL=FILL, X=X1,Y=Y1, hist=hist
      HIST_PLOT, c_fwhm, MIN=histo_min, MAX=10, noplot=0, $
                 BINSIZE=0.2, NORMALIZE=NORMALIZE, dostat=1, fitgauss=0, FILL=FILL, X=X2,Y=Y2, $
                 xtitle="A"+strtrim(iarray, 2)+": fwhm", $
                 position=[0.1/3. +0.33*(2), 0.1, 0.33*(3) -0.1/3., 0.9 ], $
                 noerase=1, xstyle=1, charsize=charsize
      oplot, x1, y1, col=250

      stop
      wd, /a
      
   endif else begin
      
      s_peak_min = -1.;0.0
      s_flux_min = -1.;0.0
      s_fwhm_min = -1.;0.0
      s_peak_max = 4.*median(s_peak)
      s_flux_max = 4.*median(s_flux)
      s_fwhm_max = 4.*median(s_fwhm)


      z_peak_max = -0.09
      z_flux_max = -0.09
      z_fwhm_max = -0.09
      z_peak_min = -1.
      z_flux_min = -1.
      z_fwhm_min = -1. 


      ;; PEAK
      z = z_peak - z0_peak
      ;;z = z_peak
      z = z_peak - z0[iarray-1]
      w = where( z_peak gt z_peak_min and z_peak lt z_peak_max and s_peak gt s_peak_min and s_peak lt s_peak_max, nw)
      matrix_plot, kp[w1[w]].nas_x, kp[w1[w]].nas_y, z[w], $
                   position=pp[ilam,0,*], title='Peak focus A'+strtrim(iarray,2), /noerase, $
                   charsize=charsize, xra=xra, yra=yra, zra=zra, format='(f6.2)',/iso, symsize=ss[iarray-1]
      print, "***"
      print, "Array ", iarray
      print, "z0_peak = ",z0_peak
      print, "z0   = ",z0[iarray-1]
      wmax = where(z eq min(z), nmax)
      print, "max focus Peak = ", z(wmax), " pour ", kp[w1[wmax]].nas_x,', ',kp[w1[wmax]].nas_y
      ;;xyouts, xx[wmax]-30, yy[wmax] + 10., $
      ;;        strtrim(string(z(wmax), format='(f6.2)'),2),
      ;;        chars=charsize, col=0
      
      ;; FLUX
      z = z_flux - z0_flux
      ;;z = z_flux
      z = z_flux - z0[iarray-1]
      w = where( z_flux gt z_flux_min and z_flux lt z_flux_max and s_flux gt s_flux_min  and s_flux lt s_flux_max, nw)
      matrix_plot, kp[w1[w]].nas_x, kp[w1[w]].nas_y, z[w], $
                   position=pp[ilam,1,*], title='Flux focus A'+strtrim(iarray,2), /noerase, $
                   charsize=charsize, xra=xra, yra=yra, zra=zra, format='(f6.2)', /iso, symsize=ss[iarray-1]
      print, "z0_flux = ",z0_flux
      print, "z0   = ",z0[iarray-1]
      wmax = where(z eq min(z), nmax)
      print, "max focus Flux = ", z(wmax), " pour ", kp[w1[wmax]].nas_x,', ',kp[w1[wmax]].nas_y
      
      ;; FWHM
      z = z_fwhm - z0_fwhm
      ;;z = z_fwhm
      z = z_fwhm - z0[iarray-1]
      w = where( z_fwhm gt z_fwhm_min and z_fwhm lt z_fwhm_max and s_fwhm gt  s_fwhm_min and s_fwhm lt s_fwhm_max, nw)
      matrix_plot, kp[w1[w]].nas_x, kp[w1[w]].nas_y, z[w], $
                   position=pp[ilam,2,*], title='FWHM focus A'+strtrim(iarray,2), /noerase, $
                   charsize=charsize, xra=xra, yra=yra, zra=zra, format='(f6.2)', /iso, symsize=ss[iarray-1]
      print, "z0_fwhm = ",z0_fwhm
      print, "z0   = ",z0[iarray-1]
      wmax = where(z eq min(z), nmax)
      print, "max focus FWHM = ", z(wmax), " pour ", kp[w1[wmax]].nas_x,', ',kp[w1[wmax]].nas_y
      print, ' '
      
   endelse
   
   
   
endfor

outplot, /close

stop

png = 'plot_fov_mapping_ratio_flux_fwhm_'+strtrim(scan_list[0],2)+suffixe+'.png'
if savepng gt 0 then WRITE_PNG, png, TVRD(/TRUE)

















print, "%%%%%%%%%"
print, ''
print, 'Second series of plot: interpolated FoV mapping'
print, ''
print,'.c to continue'
stop

;; png=0
;; ps=0
;; ps_xsize    = 22         ;; in cm
;; ps_ysize    = 11.         ;; in cm
;; ps_charsize = 1.
;; ps_yoffset  = 0.
;; ps_thick    = 2.
wind, 1, 1, /free, xsize=1100, ysize=550
;;outplot, file='plot_fov_mapping_continuous', png=png, ps=ps, xsize=ps_xsize, ysize=ps_ysize, charsize=ps_charsize, yoffset=ps_yoffset, thick=ps_thick
my_multiplot, 3, 2, pp, pp1, ymargin=0.08, gap_x=0.08, xmargin = 0.06
charsize = 1.
xra = minmax(x_center_list)
xra = xra + [-1,1]*0.2*(xra[1]-xra[0])
yra = minmax(y_center_list)
yra = yra + [-1,1]*0.2*(yra[1]-yra[0])
un = fltarr(400./20.+1.)+1.
ymap = (indgen(round(400./20.+1.))*20.-200.)##un
xmap = transpose(ymap)
rmap = sqrt(xmap*xmap +ymap*ymap)
wout=where(rmap gt max([xx, yy]))



for ilam=0, 2 do begin   
   iarray = order[ilam]
   z = reform(flux_focus[iarray-1,*],npts) - flux_focus_0[iarray-1]
   ;;zmap = GRIDDATA( xx, yy, z)
   zmap = TRI_SURF( z , xx, yy, GS=[20., 20.], BOUNDS=[-200., -200., 199., 199.])
   zmap(wout) = !values.d_nan
   
   imview, zmap, xmap=xmap, ymap=ymap, position=pp[ilam,0,*], title='Flux focus A'+strtrim(iarray,2), /noerase, $
           charsize=charsize, xra=xra, yra=yra, imrange=cont_zra*0.6, format='(f6.2)'
   oplot, kp[w1].nas_x, kp[w1].nas_y, psym=3, col=0, symsize=2., thick=1.
   for ir = 0, 2 do oplot, r[ir]*cosphi, r[ir]*sinphi, col=0, thick=1.
   
   z = reform(fwhm_focus[iarray-1,*],npts) - fwhm_focus_0[iarray-1]
   zmap = TRI_SURF( z , xx, yy, GS=[20., 20.], BOUNDS=[-200., -200., 199., 199.])
   zmap(wout) = !values.d_nan
   
   imview, zmap, xmap=xmap, ymap=ymap, position=pp[ilam,1,*], title='FWHM focus A'+strtrim(iarray,2), /noerase, $
           charsize=charsize, xra=xra, yra=yra, imrange=cont_zra, format='(f6.2)'
   oplot, kp[w1].nas_x, kp[w1].nas_y, psym=3, col=0, symsize=1., thick=1.
   for ir = 0, 2 do oplot, r[ir]*cosphi, r[ir]*sinphi, col=0, thick=1.
   ;;z = reform(ellipt_focus[iarray-1,*],npts) - ellipt_focus_0[iarray-1]
   ;;zmap = TRI_SURF( z , xx, yy, GS=[20., 20.], BOUNDS=[-200., -200., 199., 199.])
   ;;zmap(wout) = !values.d_nan
   
   ;;imview, zmap, xmap=xmap, ymap=ymap, position=pp[iarray-1,2,*], title='ELLIPT focus A'+strtrim(iarray,2), /noerase, $
   ;;        charsize=charsize, xra=xra, yra=yra, imrange=zra, format='(f6.2)'
     
endfor

png = 'plot_fov_mapping_continuous_'+strtrim(scan_list[0],2)+suffixe+'.png'
if savepng gt 0 then WRITE_PNG, png, TVRD(/TRUE)
;;outplot, /close



end

