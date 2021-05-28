;+
;
;  inspection and sanity checks of the calibrator scans
;
;  LP, december 2017
;
;-


source = 'URANUS'
source = 'MWC349'



if source eq 'MWC349' then begin
;; MWC349
;;---------------------------------------------------------------
   scan_list = ['20171024s178', '20171024s179',  '20171024s182',  '20171024s189',  '20171024s190',  '20171024s194',  '20171024s202',  '20171024s220',  '20171025s18',  '20171027s289',  '20171027s290', '20171028s238',  '20171028s239',  '20171028s240']
   
   map_dir   = '/home/perotto/NIKA/Plots/N2R12/Photometry/MWC349_photometry_kids_out2_NoTauCorrect0/v_1'
   prof_dir  = '/home/perotto/NIKA/Plots/N2R12/Profiles/MWC349'
   plot_dir  = prof_dir
   
   map_dir   = '/home/perotto/NIKA/Plots/N2R12/Photometry/MWC349_photometry_raw_median_NoTauCorrect0/v_1'
   prof_dir  = '/home/perotto/NIKA/Plots/N2R12/Profiles/MWC349/raw_median'
   plot_dir  = prof_dir
   
   
   lambda = [!nika.lambda[0], !nika.lambda[0], !nika.lambda[0], !nika.lambda[1]]
   nu = !const.c/(lambda*1e-3)/1.0d9
   flux_th           = 1.16d0*(nu/100.0)^0.60
;; assuming indep param
   err_flux_th       = sqrt( ((nu/100.0)^0.6*0.01)^2 + (1.16*0.6*(nu/100.0)^(-0.4)*0.01)^2)


endif

if source eq 'URANUS' then begin
;; URANUS
;;---------------------------------------------------------------
scan_list = ['20171024s227', '20171025s337', '20171026s3', '20171028s10', '20171029s259', '20171029s27',$
             '20171030s268', '20171030s46', '20171025s29', '20171025s41', '20171027s375', '20171028s310',$
             '20171029s26', '20171029s28',  '20171030s38', '20171031s1', '20171025s323', '20171025s42', $
             '20171027s49', '20171028s312', '20171029s266', '20171029s31', '20171030s45', '20171031s2']

scan_list = scan_list[sort(scan_list)]

map_dir   = '/home/perotto/NIKA/Plots/N2R12/Photometry/Uranus_photometry_N2R12v9_NoTauCorrect0/v_1'
prof_dir  = '/home/perotto/NIKA/Plots/N2R12/Profiles/Uranus'
plot_dir  = prof_dir

flux_th   = [!nika.flux_uranus[0], !nika.flux_uranus[0], !nika.flux_uranus[0], !nika.flux_uranus[1]]

endif


;; force repeating the profile estimate
redo_fit  = 0

show_maps      = 1
show_profiles  = 1
png            = 1


delta_radius   = 2.0d0 ;; arcsec (Delta r for profiles)

;;---------------------------------------------------------------
tags   = ['1', '3', '1MM', '2']
under  = ['', '', '_', '']
titles = ['A1', 'A3', 'A1&A3', 'A2']
ntags = n_elements(tags)
fwhm_nomi = [!nika.fwhm_nom[0], !nika.fwhm_nom[0],!nika.fwhm_nom[0],!nika.fwhm_nom[1]]
;; coupure sur la FWHM du main beam
fwhm_cut = [12., 12. , 12., 18.]


      
nscans = n_elements(scan_list)
for iscan = 0, nscans-1 do begin
   
   scan = scan_list[iscan]
   input_map_file      = map_dir+"/"+strtrim(scan, 2)+"/results.save"
   
   output_profile_file = prof_dir+"/Beam_parameter_"+scan+".save"
   
   
   if file_test(input_map_file) lt 1 then print, "result file not found" else begin
      
      restore,  map_dir+'/'+strtrim(scan)+"/results.save", /v
   
      
      grid_tags = tag_names( grid1)
      info_tags = tag_names( info1)
      
      
      print, "======================"
      print, " inspect maps"
      print, "======================"
      
      smooth = [3., 3., 3., 5.]
      ran    = [-0.3, -0.3, -0.3, -0.5 ]
      
      xmap = grid1.xmap
      ymap = grid1.ymap
      
      reso = param1.map_reso


      if show_maps gt 0 then begin
         
         outplot, file=plot_dir+'/Maps_'+scan, png=png, ps=ps
         wind, 1, 1, xsize = 800, ysize = 650, /free, title=scan
         my_multiplot, 2, 2,  pp, pp1, /rev, ymargin=0.08, gap_x=0.08, gap_y=0.08, xmargin = 0.08
         
         for i=0, ntags-1 do begin
            print, 'MAP_I'+under[i]+strtrim(tags[i], 2)
            
            wpeak = where(info_tags eq 'RESULT_PEAK_'+strtrim(tags[i],2) )
            a_peak = info1.(wpeak)
            
            print, "A_peak = ", a_peak
            
            wmap = where(grid_tags eq 'MAP_I'+under[i]+strtrim(tags[i], 2), nw)
            map = grid1.(wmap)
            map1 = map/a_peak
            wvar = where(grid_tags eq 'MAP_VAR_I'+under[i]+strtrim(tags[i], 2), nw)
            var = grid1.(wvar)
            var1 = var/a_peak^2
            w = where( var1 gt 0, nw, compl=wcompl, ncompl=nwcompl)
            var_med = median( var1[w])
            imrange = [-1,1]*4.*stddev( map[where( var le var_med and var gt 0)])
            imrange = [-500.*stddev( map[where( var le var_med and var gt 0)]), 1d]
            imrange = [-10d, 1d]
            
            ;; Define the gaussian convolution kernel for output convolved maps
            input_sigma_beam = smooth[i]*!fwhm2sigma
            nx_beam_w8       = 2*long(4*input_sigma_beam/reso/2)+1
            ny_beam_w8       = 2*long(4*input_sigma_beam/reso/2)+1
            xx               = dblarr(nx_beam_w8, ny_beam_w8)
            yy               = dblarr(nx_beam_w8, ny_beam_w8)
            for ii=0, nx_beam_w8-1 do xx[ii,*] = (ii-nx_beam_w8/2)*reso
            for ii=0, ny_beam_w8-1 do yy[*,ii] = (ii-ny_beam_w8/2)*reso
            beam_w8  = exp(-(xx^2+yy^2)/(2.*input_sigma_beam^2))
            beam_w8  = beam_w8/total(beam_w8)
            map_conv = convol( map1, beam_w8)
            
            ;; plot en dB
            d = sqrt(xmap^2 + ymap^2)
            apeak = max(map_conv(where(d lt 40.)))
            map_conv = map_conv/apeak
            ;;apeak = max(map1(where(d lt 40.)))
            ;;map_conv = map1/apeak
            map_db = 10.d0*alog(abs(map_conv))/alog(10.d0)
            imrange = [-44., 0.]
            
            ;;
            
            radius = 150.0d0
            
            imview, map_db, xmap=xmap, ymap=ymap, xr=radius*[-1.0, 1.0], yr=radius*[-1.0, 1.0], position= pp1[i, *], $
                    /noerase, imrange=imrange, title=titles[i], charsize=0.9, $
                    charbar=0.7, formatbar='(f6.0)', nbvaluebar=4., unitsbar='dB', $
                    xtitle='azimuth (arcsec)', ytitle='elevation (arcsec)', coltable=39

         endfor
         if png eq 1 then outplot, /close
         
      endif
         
      print, "======================"
      print, " inspect profiles"
      print, "======================"
      
      if (file_test(output_profile_file) lt 1 or redo_fit gt 0) then begin
         get_beam_parameters, input_map_file, output_profile_file, $
                              do_main_beam=1, optimized_internal_radius=0, $
                              do_profile=1, delta_radius=delta_radius, do_florian_fit=0
      endif
      
      if show_profiles gt 0 then begin

        
         wind, 1, 1, xsize = 1200, ysize = 700, /free
         my_multiplot, 2, 2,  pp, pp1, /rev, ymargin=0., gap_x=0.1, gap_y=0.1, xmargin = 0.
         charsz = 0.9
         
         outplot, file=plot_dir+'/Profiles_'+scan, png=png, ps=ps
         
         print, "restoring ",output_profile_file 
         restore, output_profile_file 
         
         print, ''
         print, '_________________'
         print, ''
         ;;print, scan_list[iscan]
         r0 = lindgen(999)/2.+ 1.
         
         for itag=0, ntags-1 do begin
            
            rad      = measured_profile_radius[*, itag]
            prof     = measured_profile[*, itag]
            proferr  = measured_profile_error[*, itag]
            
            ;;stop
            max = 2.*max(prof)
            min = max-max*(1d0-1d-7) 
            plot, r0, r0,  /xlog, yr=[min, max], /ys, xr=[1., 200.], /xs, /nodata, $
                  ytitle="Flux (Jy/beam)", xtitle="radius (arcsec)", title=titles[itag], pos=pp1[itag,*], /noerase
            
            
            gprof_fix = fix_fwhm_amplitude[itag]*exp(-1.*r0^2/2d0/(fwhm_nomi[itag]*!fwhm2sigma)^2)
            gprof     = amplitude[itag]*exp(-1.*r0^2/2d0/(fwhm_x[itag]*fwhm_y[itag])/!fwhm2sigma^2)
            gprof0    = amplitude[itag]*exp(-1.*r0^2/2d0/(fwhm[itag]*!fwhm2sigma)^2)
            
            oplot, r0, gprof_fix, col=0, thick=3
            oplot, r0, gprof,     col=80, thick=3
            oplot, r0, gprof0,     col=50, thick=3
            
            mb_p   = mainbeam_param[*, itag]
            mb_err = mainbeam_param_error[*, itag]
            oplot, r0, mb_p[1]*exp(-1.*r0^2/2d0/mb_p[2]/mb_p[3]), col=250, thick=3
            
            
            p = threeG_param[*, itag]
            p_err = threeG_param_error[*, itag]
            
            fit_profile = profile_3gauss(r0,p)
            g1 = p[0]*exp(-(r0-p[6])^2/2.0/(p[3]*!fwhm2sigma)^2)
            g2 = p[1]*exp(-(r0-p[6])^2/2.0/(p[4]*!fwhm2sigma)^2)
            g3 = p[2]*exp(-(r0-p[6])^2/2.0/(p[5]*!fwhm2sigma)^2)
            
            ;;oplot, r0, fit_profile, col=250
            ;;oplot, rad, g1, col=0
            ;;oplot, rad, g2, col=0
            ;;oplot, rad, g3, col=0
            
            oplot, r0, fit_profile, col=125, thick=3
            
            oploterror,rad, prof, rad*0., proferr, psym=8, col=80, errcol=80
            
            
            
            print, '****'
            print, titles[itag]
            print, '-------------'
            print, 'Mainbeam : '
            mb_fwhm = sqrt(mb_p[2]*mb_p[3])/!fwhm2sigma
            print, 'FWHM  = ', mb_fwhm
            print, 'error = ', (mb_p[2]*mb_err[3] + mb_p[3]*mb_err[2])/2d0/sqrt(mb_p[2]*mb_p[3])/!fwhm2sigma
            print, 'chi2  = ', mainbeam_chi2[itag]
            print, 'internal radius = ', mainbeam_internal_radius[itag]
            print, ' '
            print, '3Gauss : '
            print,  'G1: ', strtrim(string(p[0]),2)+' pm '+strtrim(string(p_err[0]),2)+', '+strtrim(string(abs(p[3])),2)+' pm '+strtrim(string(p_err[3]),2)
            print,  'G2: ', strtrim(string(p[1], format='(f6.2)'),2)+' pm '+strtrim(string(p_err[1], format='(f6.4)'),2)+', '+strtrim(string(abs(p[4]), format='(f6.2)'),2)+' pm '+strtrim(string(p_err[4], format='(f6.4)'),2)
            print,  'G3: ', strtrim(string(p[2], format='(f6.2)'),2)+' pm '+strtrim(string(p_err[2], format='(f6.4)'),2)+', '+strtrim(string(abs(p[5]), format='(f6.2)'),2)+' pm '+strtrim(string(p_err[5], format='(f6.4)'),2)
            
            prof_amp = p[0]+p[1]+p[2]
            
            text = ['2D Gauss : '+strtrim(string(amplitude[itag], format='(f6.2)'),2)+', '+strtrim(string(fwhm[itag], format='(f6.2)'),2),$
                    'Fix FWHM : '+strtrim(string(fix_fwhm_amplitude[itag], format='(f6.2)'),2)+', '+strtrim(string(fwhm_nomi[itag], format='(f6.1)'),2), $
                    'Main Beam : '+strtrim(string(mb_p[1], format='(f6.2)'),2)+', '+strtrim(string(mb_fwhm, format='(f6.2)'),2), '3Gauss profile amp, fwhm_G1: ', $
                    strtrim(string(prof_amp, format='(f6.2)'),2)+', '+strtrim(string(abs(p[3]), format='(f6.2)'),2)]
            
            legendastro, text, textcolor=[80, 0, 250, 125, 125], box=0, pos=[15, fix_fwhm_amplitude[itag]], charsize=charsz
            
            ;;stop
            
         endfor ;; end loop on TAGS
         
         if png eq 1 then outplot, /close
         
      endif


   endelse


endfor


wd, /a

;;====================================================
;;
;; PLOT AMPLITUDE AND FWHM from various methods
;;
;;====================================================


methods  = ['fixed fwhm', '2D Gaussian', 'Main Beam', '3Gauss profiles']
meth_col = [250, 80, 50, 150]

nmeth        = n_elements(methods)
all_flux     = dblarr(nmeth, nscans, 4)
all_err_flux = dblarr(nmeth, nscans, 4)
all_fwhm     = dblarr(nmeth, nscans, 4)
all_err_fwhm = dblarr(nmeth, nscans, 4)

for iscan = 0, nscans - 1 do begin
   
   scan = scan_list[iscan]
   output_profile_file = prof_dir+"/Beam_parameter_"+scan+".save"
   print, "restoring ",output_profile_file 
   restore, output_profile_file 
         
   for itag = 0, 3 do begin
      
      ;; amplitudes
      ;;-------------------------------------------------
      all_flux[0, iscan, itag] = fix_fwhm_amplitude[itag]
      all_flux[1, iscan, itag] = amplitude[itag]
      all_flux[2, iscan, itag] = mainbeam_param[1, itag]
      all_flux[3, iscan, itag] = threeG_param[3,itag]+threeG_param[4,itag]+threeG_param[5,itag]
      ;; fwhm
      ;;------------------------------------------------
      all_fwhm[0, iscan, itag] = fwhm_nomi[itag]
      all_fwhm[1, iscan, itag] = fwhm[itag]
      all_fwhm[2, iscan, itag] = sqrt( mainbeam_param[2, itag]*mainbeam_param[3, itag])/!fwhm2sigma
      all_fwhm[3, iscan, itag] = threeG_param[3, itag]

      ;; error
      ;;-----------------------------------------------
      all_err_flux[0, iscan, itag] = 0.0d0
      all_err_flux[1, iscan, itag] = 0.0d0
      all_err_flux[2, iscan, itag] = mainbeam_param_error[1, itag]
      ;;
      covar = reform(threeG_param_covar[*, itag], 7, 7)
      aa = [1.0d0, 1.0d0, 1.0d0, 0.0d0, 0.d0, 0.D0, 0.D0]
      var_flux = aa#covar#aa
      all_err_flux[3, iscan, itag] = sqrt(var_flux)
      ;;all_err_flux[3, iscan, itag] = sqrt(threeG_param_error[3,itag]^2+threeG_param_error[4,itag]^2+threeG_param_error[5,itag]^2)
      ;;
      
      all_err_fwhm[0, iscan, itag] = 0.0D0
      all_err_fwhm[1, iscan, itag] = 0.0d0
      ;;
      covar = reform(mainbeam_covar[*, itag], 7, 7)
      aa = [0.d0, 0.D0, mainbeam_param[3, itag]/(2.d0*sqrt(mainbeam_param[2, itag]*mainbeam_param[3, itag])), $
            mainbeam_param[2, itag]/(2.d0*sqrt(mainbeam_param[2, itag]*mainbeam_param[3, itag])), $
            0.d0, 0.D0, 0.D0]/!fwhm2sigma
      var_fwhm = aa#covar#aa
      all_err_fwhm[2, iscan, itag] = sqrt(var_fwhm)
      all_err_fwhm[3, iscan, itag] = threeG_param_error[3, itag]
   endfor
endfor



;; FWHM
;;======================================================================
wind, 1, 1, /free, /large
outplot, file=plot_dir+'/FWHM_'+source+'_kids_out_n2r12', png=png, ps=ps
!p.multi=[0,2,2]
index = dindgen(nscans)
day_list = strmid(scan_list,0,8)

for j=0, 3 do begin
   
   plot, index, all_fwhm[0,*, j], /xs, yr=fwhm_nomi[j]*[0.6, 1.4], xr=[-1, nscans], psym=-4, $
         xtitle='scan index', ytitle='FWHM (arcsec)', /ys, /nodata, title=tags[j]

   for im=0, 3 do oplot, index, all_fwhm[im, *, j], psym=8, col=meth_col[im]
   ;;for im=0, 3 do oploterror, index, all_fwhm[im, *, j], all_err_fwhm[im, *, j], psym=8, col=meth_col[im]

   
   if j eq 3 then  xyouts, index, index*0.0+fwhm_nomi[j]*0.65, scan_list, charsi=0.7, orient=90, col=250

   myday = day_list[0]
   for i=0, nscans-1 do begin
      if day_list[i] ne myday then begin
         oplot, [i,i]*1, [-1,1]*1e10
         myday = day_list[i]
      endif
   endfor
   
   if j eq 0 then legendastro, methods, col=meth_col, textcol=meth_col, box=0
endfor
!p.multi=0
outplot, /close


;; FLUX
;;======================================================================
wind, 1, 1, /free, /large
outplot, file=plot_dir+'/AMPLITUDE_'+source+'_kids_out_n2r12', png=png, ps=ps
!p.multi=[0,2,2]
index = dindgen(nscans)
day_list = strmid(scan_list,0,8)

for j=0, 3 do begin

   w_beam_ok = where(all_fwhm[2,*, j] le fwhm_cut[j], n_beam_ok, compl=w_notok, ncompl=n_notok)
 
   
   plot, index, all_flux[0,*, j], /xs, yr=flux_th[j]*[0.5, 1.5], xr=[-1, nscans], psym=-4, $
         xtitle='scan index', ytitle='Flux density (Jy/beam)', /ys, /nodata, title=tags[j]

   if n_beam_ok gt 0 then for im=0, 3 do oplot, index[w_beam_ok], all_flux[im, w_beam_ok, j], psym=8, col=meth_col[im]
   if n_notok gt 0 then for im=0, 3 do oplot, index[w_notok], all_flux[im, w_notok, j], psym=4, col=meth_col[im]
   ;;for im=0, 3 do oploterror, index, all_flux[im, *, j], all_err_flux[im, *, j], psym=8, col=meth_col[im]

   oplot, [-1, nscans], flux_th[j]*[1., 1.], col=0
   
   if j eq 3 then  xyouts, index, index*0.0+flux_th[j]*1.05, scan_list, charsi=0.7, orient=90, col=250

   myday = day_list[0]
   for i=0, nscans-1 do begin
      if day_list[i] ne myday then begin
         oplot, [i,i]*1, [-1,1]*1e10
         myday = day_list[i]
      endif
   endfor

   legendastro, ['MB FWHM < '+strtrim(string(fwhm_cut[j],format='(f5.1)'), 2)+"''", 'MB FWHM > '+strtrim(string(fwhm_cut[j],format='(f5.1)'), 2)+"''"], col=[0, 0], psym=[8, 4], box=0, pos=[0, flux_th[j]*0.6]
   
   if j eq 0 then legendastro, methods, col=meth_col, textcol=meth_col, box=0, pos=[0, flux_th[j]*1.4]
endfor
!p.multi=0
outplot, /close

;; FLUX-FWHM SCATTER PLOT
;;======================================================================
wind, 1, 1, /free, /large
outplot, file=plot_dir+'/AMPLITUDE_VS_FWHM_'+source+'_kids_out_n2r12', png=png, ps=ps
!p.multi=[0,2,2]
index = dindgen(nscans)
day_list = strmid(scan_list,0,8)

for j=0, 3 do begin

   plot, all_fwhm[2,*, j] , all_flux[0,*, j], /xs, yr=flux_th[j]*[0.5, 1.5], xr=[min(all_fwhm[2,*, j])*0.99,max(all_fwhm[2,*, j])*1.01], psym=-4, $
         xtitle='Main Beam FWHM (arcsec)', ytitle='Flux density (Jy/beam)', /ys, /nodata, title=tags[j]

   for im=0, 3 do oplot, all_fwhm[2,*, j] , all_flux[im, *, j], psym=8, col=meth_col[im]
   ;;for im=0, 3 do oploterror, index, all_flux[im, *, j], all_err_flux[im, *, j], psym=8, col=meth_col[im]

   oplot, [0,50], flux_th[j]*[1., 1.], col=0
   

   if j eq 0 then legendastro, methods, col=meth_col, textcol=meth_col, box=0;, pos=[0, flux_th[j]*1.4]
endfor
!p.multi=0
outplot, /close


stop 

   
end
