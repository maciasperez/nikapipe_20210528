;;
;;
;;   launch the reduction of a series of defocused beammaps sequences
;;  
;;
;;

;; common parameters
;;--------------------------------------------------------
beam_maps_dir  = !nika.plot_dir+"/beammaps_calib"
project_dir    = !nika.plot_dir+"/fov_focus_2"
savepng  = 0
parallel = 1


;; 1./ preproc, reduce and map-making
;;     -- set to 0 once the beammaps have been processed
process      = 0
;;     -- set to 1 to relaunched the processing of already reduced scans
force_process    = 0
;;     -- set force_kidpar to 1 and define the kidpar file here, and it will be used instead of the
;;       reference kidpar
force_kidpar = 1
;;     -- opacity correction
do_opacity_correction = 1
;;     -- noise decorrelation method
decor_method = 'common_mode_one_block'
;;     -- map angular resolution (pixel size in arcsec)
reso=4. 

;; 2./ focus fit
;;     -- set to 0 once the focus are fitted
fit_focus             = 0
;;     -- rescale focus error by sqrt(Chi2/N_dof) ?
focus_error_rescaling = 1 


;; 3./ save focus surfaces
saveresults = 1



;; other parameters
;;--------------------------------------------------------
list_sequence = [['20170419s'+strtrim([133, 134, 135, 136, 137], 2)], $
                 ['20170226s'+strtrim([415, 416, 417, 418, 419],2)], $
                 ['20170424s'+strtrim([123, 124, 125, 126, 127],2)], $
                 ['20170422s'+strtrim([61, 62, 63, 64, 65],2)], $
                 ['20170421s'+strtrim([160, 161, 162, 163, 164],2)], $
                 ['20170420s'+strtrim([113, 114, 115, 116, 117],2)]]

nk_scan2run, '20170419s133'
str_nika_n2r10 = !nika
nk_scan2run, '20170226s415'
str_nika_n2r9  = !nika

list_source   = ['Neptune', '3C84', 'Neptune', 'Mars', 'Neptune', 'Neptune']
list_theoflux = [[str_nika_n2r10.flux_neptune],  [1., 1., 1.], [str_nika_n2r10.flux_neptune], $
                 [str_nika_n2r10.flux_mars], [str_nika_n2r10.flux_neptune],[str_nika_n2r10.flux_neptune]  ]

list_kidpar_file = [!nika.off_proc_dir+"/kidpar_20170419s133_v2_cm_one_block_LP_calib.fits", $
                    !nika.off_proc_dir+"/kidpar_20170226s415_FXDC0C1_GaussPhot.fits", $
                    !nika.off_proc_dir+"/kidpar_20170424s123_v2_cm_one_block_LP_calib.fits", $
                    !nika.off_proc_dir+"/kidpar_20170422s61_v2_cm_one_block_LP_calib.fits", $
                    !nika.off_proc_dir+"/kidpar_20170421s160_v2_cm_one_block_LP_calib.fits", $
                    !nika.off_proc_dir+"/kidpar_20170420s113_JFMP_v2_cm_one_block_LP_calib.fits"]
list_dmin        = [90., 90., 90., 120., 90., 90.]


nsequences = n_elements(list_sequence[0, *])

for iseq=0, nsequences-1 do begin
;for iseq=0, 0 do begin

   scan_list     = list_sequence[*, iseq]
   source        = list_source[iseq]
   input_flux_th = list_theoflux[*, iseq]
   
   nscans         = n_elements(scan_list)
   result_dir     = project_dir+'/'+strtrim(scan_list[0],2)+'_'+strtrim(scan_list[nscans-1],2)
   if file_test(result_dir, /directory) ne 1 then spawn, "mkdir "+result_dir
   
   input_kidpar_file = list_kidpar_file[iseq]
   decor_cm_dmin     = list_dmin[iseq]

   
   

   make_focus_surfaces, scan_list, source, input_flux_th, beam_maps_dir, result_dir, $
                        savepng=savepng, process=process, force_process=force_process, $
                        force_kidpar=force_kidpar, input_kidpar_file=input_kidpar_file, $
                        do_opacity_correction=do_opacity_correction, $
                        decor_method=decor_method, decor_cm_dmin=decor_cm_dmin, reso=reso, $
                        fit_focus=fit_focus, focus_error_rescaling=focus_error_rescaling



   ;;  
   ;;        Plotting
   ;; 
   ;;_______________________________________________________________
   ;; Summary plot (or even better map of the results)

   suffixe = ''
   
   output_plot_file = project_dir+'/fov_focus_'+strtrim(scan_list[0],2)+'_'+strtrim(scan_list[nscans-1],2)+suffixe
   png=savepng

   kp = mrdfits(input_kidpar_file, 1)
   
      
   zra=[-0.9, 0.1]
   zra=[-0.5, 0.5]
   zra=[-0.4, 0.4]
   
   
   wind, 1, 1, /free, xsize=900, ysize=750
   outplot, file=output_plot_file, png=png
   my_multiplot, 3, 3, pp, pp1, ymargin=0.08, gap_x=0.08, xmargin = 0.06
   charsize = 0.8
   order = [1, 3, 2]
   ss = [0.4, 0.5, 0.4]
   ;; restore kid-by-kid focus result files and gather in a single table
   for ilam=0, 2 do begin
      iarray = order[ilam]
      print, '***'
      print, 'Array ', strtrim(iarray,2)
      
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
            if (ik mod 100) eq 0. then print, "restoring ", resfile
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
            fit_value = focus*0.d0
            for i = 0, n_elements(cp4_all)-1 do fit_value += cp4_all[i]*focus^i
            c_flux[ik] = total( (flux_res[*]-fit_value)^2/sigma_flux_res[*]^2)/ndof
            
         endif
      endfor
      print, "FOV focus surfaces reconstructed..."
      
      d = sqrt((kp[w1].nas_x)^2 + (kp[w1].nas_y)^2)
      w0 = where(d le 80., nw0)
      print,nw0
      
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
      
      
      s_peak_min = 0.0
      s_flux_min = 0.0
      s_fwhm_min = 0.0
      s_peak_max = 4.*median(s_peak)
      s_flux_max = 4.*median(s_flux)
      s_fwhm_max = 4.*median(s_fwhm)

      z_peak_max = median(focus) + 0.6;-0.09
      z_flux_max = median(focus) + 0.6;-0.09
      z_fwhm_max = median(focus) + 0.6;-0.09
      z_peak_min = median(focus) - 0.6;-1.
      z_flux_min = median(focus) - 0.6;-1.
      z_fwhm_min = median(focus) - 0.6;-1. 


      ;; PEAK
      dz_peak = z_peak - z0_peak
      ;;z = z_peak
      ;;z = z_peak - z0[iarray-1]
      w = where( z_peak gt z_peak_min and z_peak lt z_peak_max and s_peak gt s_peak_min and s_peak lt s_peak_max, nw)
      matrix_plot, kp[w1[w]].nas_x, kp[w1[w]].nas_y, dz_peak[w], $
                   position=pp[ilam,0,*], title='Peak focus A'+strtrim(iarray,2), /noerase, $
                   charsize=charsize, xra=xra, yra=yra, zra=zra, format='(f6.2)',/iso, symsize=ss[iarray-1]
      print, "z0_peak = ",z0_peak
      ;;print, "z0   = ",z0[iarray-1]
      wmax = where(dz_peak eq min(dz_peak), nmax)
      print, "max focus Peak = ", dz_peak(wmax), " pour ", kp[w1[wmax]].nas_x,', ',kp[w1[wmax]].nas_y
      ;;xyouts, xx[wmax]-30, yy[wmax] + 10., $
      ;;        strtrim(string(z(wmax), format='(f6.2)'),2),
      ;;        chars=charsize, col=0
      
      ;; FLUX
      dz_flux = z_flux - z0_flux
      ;;z = z_flux
      ;;z = z_flux - z0[iarray-1]
      w = where( z_flux gt z_flux_min and z_flux lt z_flux_max and s_flux gt s_flux_min  and s_flux lt s_flux_max, nw)
      matrix_plot, kp[w1[w]].nas_x, kp[w1[w]].nas_y, dz_flux[w], $
                   position=pp[ilam,1,*], title='Flux focus A'+strtrim(iarray,2), /noerase, $
                   charsize=charsize, xra=xra, yra=yra, zra=zra, format='(f6.2)', /iso, symsize=ss[iarray-1]
      print, "z0_flux = ",z0_flux
      ;;print, "z0   = ",z0[iarray-1]
      wmax = where(dz_flux eq min(dz_flux), nmax)
      print, "max focus Flux = ", dz_flux(wmax), " pour ", kp[w1[wmax]].nas_x,', ',kp[w1[wmax]].nas_y
      
      ;; FWHM
      dz_fwhm = z_fwhm - z0_fwhm
      ;;z = z_fwhm
      ;;z = z_fwhm - z0[iarray-1]
      w = where( z_fwhm gt z_fwhm_min and z_fwhm lt z_fwhm_max and s_fwhm gt  s_fwhm_min and s_fwhm lt s_fwhm_max, nw)
      matrix_plot, kp[w1[w]].nas_x, kp[w1[w]].nas_y, dz_fwhm[w], $
                   position=pp[ilam,2,*], title='FWHM focus A'+strtrim(iarray,2), /noerase, $
                   charsize=charsize, xra=xra, yra=yra, zra=zra, format='(f6.2)', /iso, symsize=ss[iarray-1]
      print, "z0_fwhm = ",z0_fwhm
      ;;print, "z0   = ",z0[iarray-1]
      wmax = where(dz_fwhm eq min(dz_fwhm), nmax)
      print, "max focus FWHM = ", dz_fwhm(wmax), " pour ", kp[w1[wmax]].nas_x,', ',kp[w1[wmax]].nas_y
      print, ' '


      
      if saveresults gt 0 then begin
         dz_elli = z_elli - z0_elli
         
         output_file = project_dir+'/fov_focus_'+strtrim(scan_list[0],2)+'_'+strtrim(scan_list[nscans-1],2)+'_A'+strtrim(iarray,2)+'.save'

         numdet = kp[w1].numdet
         save, numdet, dz_peak, s_peak, c_peak, dz_flux, s_flux, c_flux, dz_fwhm, s_fwhm, c_fwhm, dz_elli, s_elli, c_elli,filename=output_file
      endif




      
   endfor
   
   outplot, /close

   
endfor



end
