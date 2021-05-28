;;
;;
;;
;;    Fit de modele de profile sur la carte de lobe de la Sect. Full Beam pattern
;;
;;    voir production de la carte dans comresult_beammap.pro
;;
;;________________________________________________________________________


;;.r  /home/perotto/NIKA/Processing/Labtools/FR/Beam/fit_gaussian_beam.pro

project_dir  = '/home/perotto/NIKA/Plots/Beams/FullBeams/'
plot_dir     = project_dir
png          = 0
ps           = 0

;; scan list
;;---------------------------------------------------------------------------------------------

;; N2R8: best file
scan_list_n2r8 = ['20170125s243']

;; N2R9: best file
scan_list_n2r9 = ['20170224s177', '20170226s415']

;; from the DB
select_beammap_scans, selected_scan_list, selected_source

scan_list_all = [scan_list_n2r8, scan_list_n2r9, selected_scan_list]
source_all    = ['Uranus', 'Neptune', '3C84', selected_source]

index = uniq(scan_list_all)
scan_list = scan_list_all[index]
sources   = source_all[index]  

;; excluding scan of Mars
;;wmars=where(strupcase(sources) eq 'MARS', nmars, compl=w)
;;if nmars gt 0 then begin
;;   scan_list = scan_list[w] 
;;   sources   = sources[w]  
;;endif


;; fits (if profile_fit_file not already exists)
;;---------------------------------------------------
launch_nk    = 0
version      = 1 
method       = 'COMMON_MODE_ONE_BLOCK'

;; force repeating the fit
redo_fit = 0

;; fit the main beam FWHM
do_main_beam = 0
optimized_internal_radius = 0

;; fit a 3-Gaussian profile
do_profile = 0
do_florian = 1 ;; compare with Florian's method

;; plots
;;--------------------------------------------------
;; plot profile per beammap
do_plot_permap = 1

;; plot superimposed profile of all the scans
do_plot_allscans = 0
normalise        = 1
plot_suffixe='_mixed'

;; stat on profile models
do_stats = 1
;normalise        = 0
;plot_suffixe='_uranus'
normalise        = 1
plot_suffixe='_mixed'

;; beam etendue
do_etendue = 1
radius_maximum = 90.0d0 ;; 150.0d0        ; arcsec


plot_color_convention, col_a1, col_a2, col_a3, $
                       col_mwc349, col_crl2688, col_ngc7027, $
                       col_n2r9, col_n2r12, col_n2r14

scan_col = [245, 230, 200, 180, 160, 140, 120, 115, 95, 90, 80, 75, 65, 60, 50, 45, 35, 10]
   
;; input_map_files (IN) and profile_fit_files (OUT)
;;---------------------------------------------------------------------------------------------
profile_fit_files = project_dir+'Profiles/'+'Prof_3Gauss_'+strtrim(scan_list,2)+'_2019_r8_16.save'
input_map_files   = project_dir+'v_'+strtrim(string(version), 2)+'/'+strtrim(scan_list,2)+'/results.save'





;;_______________________________________________________________________________________
;;_______________________________________________________________________________________
;;_______________________________________________________________________________________

nscan = n_elements(scan_list)

if launch_nk gt 0 then begin

   print,"============================================="
   print,''
   print,'  MAP PRODUCTION '
   print,''
   print,"============================================="
   
   if nscan gt 1 then begin

      kp_file_tab = strarr(nscan)
      for iscan=0, nscan-1 do begin
         nk_scan2run, scan_list[iscan], run
         if run le 22 then runnum=9 else $
            if run eq 25 then runnum=12 else runnum=14                                  
         opa_suffixe = 'baseline'
         if runnum gt 10 then opa_suffixe = 'atmlike'
         kp_file_tab[iscan]= !nika.soft_dir+'/Kidpars/kidpar_calib_N2R'+strtrim(string(runnum),2)+'_ref_'+opa_suffixe+'_v2_calpera.fits'
      endfor
      
      split_for, 0, nscan-1, nsplit=nscan, $
                 commands=['nk_lobes_sub, i, scan_list, input_kidpar_file=kp_file_tab, project_dir=project_dir, version=version, method=method'], $
                 varnames = ['scan_list', 'kp_file_tab', 'project_dir', 'version', 'method']
   endif else begin
     
      scan = scan_list[0]
            
      nk_default_param, param
      ;param.force_kidpar   = 1
      ;param.file_kidpar    = input_kidpar_file
      param.decor_cm_dmin  = 100.
      param.output_noise   = 1
      param.do_opacity_correction = 1
      
      if (version eq 2 or version eq 3) then param.decor_method   = "COMMON_MODE_ONE_BLOCK"
      param.version        = version
      
      param.map_reso       = 1.d0
      param.map_xsize      = 600d0
      param.map_ysize      = 600d0
      param.map_proj       = 'azel'
      param.map_smooth_1mm = 0
      param.map_smooth_2mm = 0
      
      param.plot_dir       = project_dir
      param.project_dir    = project_dir

      nk, scan, param=param
      
   endelse


   stop
endif

;;    profile fitting
;;_______________________________________________________________________________________
for iscan =0, nscan-1 do begin
   
   outfile = profile_fit_files[iscan]
   
   if (file_test(outfile) lt 1 or redo_fit gt 0) then begin
      
      print,"============================================="
      print,''
      print,'  PROFILE FITTING '
      print,''
      print,"============================================="
      
      ;; test
      ;;input_map = '/home/perotto/NIKA/Plots/Beams/FullBeams/v_1/20170227s84/results.save'
      ;;outfile   = '/home/perotto/NIKA/Plots/Beams/FullBeams/Profiles/test_20170227s84.save'
      ;;get_beam_parameters, input_map, outfile, $
      ;;                     do_main_beam=1, optimized_internal_radius=0, $
      ;;                     do_profile=1, do_florian_fit=1

      
      get_beam_parameters, input_map_files[iscan], outfile, $
                           do_main_beam=do_main_beam, optimized_internal_radius=optimized_internal_radius, $
                           do_profile=do_profile, do_florian_fit=do_florian
      
   endif
   
   
   ;;;
   ;;;
   ;;;
   ;;;
   ;;;       plot
   ;;;
   ;;;_____________________________________________________________________


   if do_plot_permap gt 0 then begin
      
      ;;wind, 1, 1, xsize = 800, ysize = 2000, /free
      ;;my_multiplot, 1, 4,  pp, pp1, /rev, ymargin=0.02, gap_x=0, gap_y=0.06, xmargin = 0.17
      ;;charsz = 0.8

      wind, 1, 1, xsize = 1200, ysize = 700, /free
      my_multiplot, 2, 2,  pp, pp1, /rev, ymargin=0., gap_x=0.1, gap_y=0.1, xmargin = 0.
      charsz = 0.9
      
      if png eq 1 then begin
         if nscan lt 2 then begin
            rootname = rootname(input_map_files[iscan], cutext='.save')
            plot_file = plot_dir+"/Profile_"+strtrim(rootname, 2)+"_v"+strtrim(string(version), 2)
         endif else begin
            plot_file = plot_dir+"/Profile_"+strtrim(scan_list[iscan], 2)+"_v"+strtrim(string(version), 2)
         endelse
         outplot, file=plot_file, /png
      endif
      
      print, "restoring ", profile_fit_files[iscan]
      restore, profile_fit_files[iscan]
      restore, input_map_files[iscan], /v
      res = isa(grid1, /array)
      if res gt 0 then grid_tot=grid1
      res = isa(info1, /array)
      if res gt 0 then info_tot=info1
      res = isa(param1, /array)
      if res gt 0 then param=param1
      info_tags = tag_names( info_tot)
      
      print, ''
      print, '_________________'
      print, ''
      print, scan_list[iscan]
      r0 = lindgen(999)/2.+ 1.
      
      tags   = ['1', '3', '1MM', '2']
      under  = ['', '', '_', '']
      titles = ['A1', 'A3', 'A1&A3', 'A2']
      ntags  = n_elements(tags)
      
      for itag=2, ntags-1 do begin
         
         wind, 1, 1, xsize = 800, ysize = 550, /free
         rad      = measured_profile_radius[*, itag]
         prof     = measured_profile[*, itag]
         proferr  = measured_profile_error[*, itag]
         
         ;;stop
         max = 2.*max(prof)
         min = max-max*(1d0-1d-5) 
         plot, r0, r0, /ylog, /xlog, yr=[min, max], /ys, xr=[1., 200.], /xs, /nodata, $
               ytitle="Flux (Jy/beam)", xtitle="radius (arcsec)", title=titles[itag];;, pos=pp1[itag,*], /noerase
         oploterror,rad, prof, rad*0., proferr, psym=8, col=80, errcol=80
         
         mb_p   = mainbeam_param[*, itag]
         mb_err = mainbeam_param_error[*, itag]
         oplot, r0, mb_p[1]*exp(-1.*r0^2/2d0/mb_p[2]/mb_p[3]), col=125, thick=3
         
         
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

         if do_florian gt 0 then begin
            p2 = threeG_param_2[*, itag]
            
            ;;fit_profile_2 = fit_triple_beam(r0, p2)
            rmax = max(r0)
            sidesize = rmax
            vect = dindgen(sidesize)-sidesize/2.
            un = dblarr(sidesize)+1.0d0
            xmap = un#vect
            ymap = transpose(xmap)
            rmap = sqrt(xmap^2 + ymap^2)
            reso=1.0d0
            beammap = p2[0]*exp(-(rmap-p2[6])^2/2.0/(p2[3]*!fwhm2sigma)^2) + $
                      p2[1]*exp(-(rmap-p2[6])^2/2.0/(p2[4]*!fwhm2sigma)^2) + $
                      p2[2]*exp(-(rmap-p2[6])^2/2.0/(p2[5]*!fwhm2sigma)^2)
            
            maps = {Jy:beammap, var:beammap*0.0+1D0}
            
            ;;nika_pipe_profile, reso, maps, profile_2, nb_prof=sidesize/3.
            ;;rr = profile_2.r
            ;;fit_profile_2 = profile_2.y

            fit_profile_3 = p2[0]*exp(-(r0-p2[6])^2/2.0/(p2[3]*!fwhm2sigma)^2) + $
                            p2[1]*exp(-(r0-p2[6])^2/2.0/(p2[4]*!fwhm2sigma)^2) + $
                            p2[2]*exp(-(r0-p2[6])^2/2.0/(p2[5]*!fwhm2sigma)^2)
            
            oplot, r0, fit_profile_3, col=0, thick=3
            ;;oplot, rr, fit_profile_2, col=100, psym=1, symsize=1.2
            oplot, r0, fit_profile, col=250, thick=3
            ;;stop
         endif
            
         wpeak = where(info_tags eq 'RESULT_PEAK_'+strtrim(tags[itag],2) )
         a_peak = info_tot.(wpeak)
         wflux = where( strupcase(info_tags) eq "RESULT_FLUX_I"+under[itag]+tags[itag], nwtag)
         flux = info_tot.(wflux)
            
         wtag = where( strupcase(info_tags) eq "RESULT_OFF_X_"+tags[itag], nwtag)
         x0   = info_tot.(wtag)
         wtag = where( strupcase(info_tags) eq "RESULT_OFF_Y_"+tags[itag], nwtag)
         y0   = info_tot.(wtag)

         print, '****'
         print, titles[itag]
         print, '-------------'
         print, 'fwhm_fix : '
         print, 'APEAK = ', a_peak
         print, 'FLUX  = ', flux
         print, 'Mainbeam : '
         fwhm = sqrt(mb_p[2]*mb_p[3])/!fwhm2sigma
         print, 'AMP   = ', mb_p[1]
         print, 'FWHM  = ', fwhm
         print, 'error = ', (mb_p[2]*mb_err[3] + mb_p[3]*mb_err[2])/2d0/sqrt(mb_p[2]*mb_p[3])/!fwhm2sigma
         print, 'chi2  = ', mainbeam_chi2[itag]
         print, 'internal radius = ', mainbeam_internal_radius[itag]
         print, ' '
         print, '3Gauss : '
         print,  'AMP = ', p[0]+p[1]+p[2]
         print,  'G1: ', 'amp = '+strtrim(string(p[0], format='(f6.2)'),2)+' pm '+strtrim(string(p_err[0], format='(f6.2)'),2)+', fwhm = '+ strtrim(string(p[3], format='(f6.2)'),2)+' pm '+strtrim(string(p_err[3], format='(f6.2)'),2) 
         print,  'G2: ', 'amp = '+strtrim(string(p[1], format='(f6.2)'),2)+' pm '+strtrim(string(p_err[1], format='(f6.2)'),2)+', fwhm = '+ strtrim(string(p[4], format='(f6.2)'),2)+' pm '+strtrim(string(p_err[4], format='(f6.2)'),2)
         print,  'G3: ', 'amp = '+strtrim(string(p[2], format='(f6.2)'),2)+' pm '+strtrim(string(p_err[2], format='(f6.2)'),2)+', fwhm = '+ strtrim(string(p[5], format='(f6.2)'),2)+' pm '+strtrim(string(p_err[5], format='(f6.2)'),2)
         print,  'par 2 : ', p2
         print, '-----------'
         print, 'center map : ', sqrt(x0^2 +y0^2)
         print, 'center prof : ', p2[6]
         print, '-----------'
         
         text = ['Main Beam FWHM: '+strtrim(string(fwhm, format='(f6.2)'),2)+' arcsec', $
                 'mask internal radius: '+strtrim(string(mainbeam_internal_radius[itag], format='(f6.1)'),2)+' arcsec', $
                 '', $
                 '3Gauss profile amp, fwhm: ', $
                 '  G1 : '+strtrim(string(p[0], format='(f6.2)'),2)+', '+strtrim(string(abs(p[3]), format='(f6.2)'),2),$
                 '  G2 : '+strtrim(string(p[1], format='(f6.2)'),2)+', '+strtrim(string(abs(p[4]), format='(f6.2)'),2),$
                 '  G3 : '+strtrim(string(p[2], format='(f6.2)'),2)+', '+strtrim(string(abs(p[5]), format='(f6.2)'),2)]
         legendastro, text, textcolor=[125, 125, 0, 250, 250, 250, 250], box=0, pos=[25, max(prof)], charsize=charsz
       

      endfor ;; end loop on TAGS
      
      if png eq 1 then outplot, /close

      stop
   endif
   
endfor
;; loop over scans


;;    plots & stats
;;_______________________________________________________________________________________

;; superimpose all the profiles
if do_plot_allscans gt 0 then begin
   
   
   r0 = lindgen(999)/2.+ 1.
   
   tags   = ['1', '3', '1MM', '2']
   under  = ['', '', '_', '']
   titles = ['A1', 'A3', 'A1&A3', 'A2']
   ntags  = n_elements(tags)

   text      = strarr(nscan)
   tab_color = scan_col

   tab_rad   = dblarr(225, nscan, 4)
   tab_prof  = dblarr(225, nscan, 4)
   tab_var   = dblarr(225, nscan, 4)
   
   for itag=0, ntags-1 do begin
      
      restore, profile_fit_files[0]
      rad = measured_profile_radius[*, itag]
      
      if normalise gt 0 then begin
         min = 1d-4
         max = 10.
      endif else begin
         prof     = measured_profile[*, itag]
         max = 2.*max(prof)
         min = max-max*(1d0-1d-5) 
      endelse
      
      wind, 1, 1, /free, xsize=wxsize, ysize=wysize
      outfile = plot_dir+'plot_flux_density_ratio_obstau_allbright_obsdate'+plot_suffixe+'_1mm'
      outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
      
      plot, r0, r0, /ylog, /xlog, yr=[min, max], /ys, xr=[1., 500.], /xs, /nodata, $
            ytitle="Flux (Jy/beam)", xtitle="radius (arcsec)", title=titles[itag];, pos=pp1[itag,*], /noerase
      
      decal = alog(rad)/2.
      if normalise gt 0 then decal = 0.
      
      for iscan =0, nscan-1 do begin
         print, "restoring ", profile_fit_files[iscan]
         restore, profile_fit_files[iscan], /v

         ;; ancienne convention
         ;; if scan_list[iscan] eq '20170224s177' then begin
         ;;    file = project_dir+'/v_'+strtrim(string(2),2)+'/Fit_'+scan_list[iscan]+'_v2.save'
         ;;    print, "restoring ",file
         ;;    restore, file
         ;; endif
         
         rad      = measured_profile_radius[*, itag]
         prof     = measured_profile[*, itag]
         proferr  = measured_profile_error[*, itag]
         nr = n_elements(rad)
         
         if normalise gt 0 then begin
            norm = max(prof[0:10])
            prof = prof/norm
            proferr = proferr/norm
         endif
       
         oploterror,rad+iscan*decal, prof, rad*0., proferr, psym=8, col=tab_color[iscan], errcol=tab_color[iscan]
         text[iscan] = strtrim(scan_list[iscan],2)

         tab_rad[ 0:nr-1, iscan, itag] = rad[0:nr-1]
         tab_prof[0:nr-1, iscan, itag] = prof[0:nr-1]
         tab_var[ 0:nr-1, iscan, itag] = proferr[0:nr-1]^2

         
      endfor ;; end SCAN loop 
      if itag eq 0 then legendastro, text, textcolor=tab_color, box=0, charsize=charsz, /right

      stop    
   endfor ;; end TAG loop

   if png eq 1 then outplot, /close

   ;;stop

   ;; combined profile
   wind, 1, 1, xsize = 1500, ysize = 800, /free
   my_multiplot, 2, 2,  pp, pp1, /rev, ymargin=0., gap_x=0.1, gap_y=0.1, xmargin = 0.
   charsz = 0.9
   
   if png eq 1 then begin
      ;;plot_file =
      ;;plot_dir+"/Profile_allscans_over_combined_v"+strtrim(string(version),2)+plot_suffixe
      plot_file = plot_dir+"/Profile_allscans_over_median"+plot_suffixe
      outplot, file=plot_file, /png
   endif

   r0 = lindgen(999)/2.+ 1.
   
   tags   = ['1', '3', '1MM', '2']
   under  = ['', '', '_', '']
   titles = ['A1', 'A3', 'A1&A3', 'A2']
   ntags  = n_elements(tags)

   decal = alog(rad)/3.
   text  = strtrim(scan_list,2)

   if normalise gt 0 then decal = 0.
   
   for itag=0, ntags-1 do begin

      med_rad  = dblarr(225)
      med_prof = dblarr(225)
      med_var  = dblarr(225)
      w8   = dblarr(100)

      med_rad  = median(tab_rad(*, *, itag),dimension=2)
      med_prof = median(tab_prof(*, *, itag),dimension=2)
      med_err  = stddev(tab_prof(*, *, itag),dimension=2)
      
      ;; for iscan =0, nscan-1 do begin
      ;;    w8[*]      = 1d0/tab_var[*, iscan, itag]
      ;;    med_rad[*] += tab_rad[*, iscan, itag]*w8[*]
      ;;    med_prof[*] += tab_prof[*, iscan, itag]*w8[*]
      ;;    med_var  += w8
      ;; endfor
      
      ;; w = where(med_var gt 0)
      ;; med_rad(w)  = med_rad(w)/med_var(w)
      ;; med_prof(w) = med_prof(w)/med_var(w)
      ;; med_var(w)  = 1d0/med_var(w)
      ;; med_err     = sqrt(med_var)

            
      ;; plot, r0, r0, yr=[1d-4, 30], /ys, xr=[1., 500.], /xs, /nodata, /xlog, /ylog, $
      ;;       ytitle="Profile ratio", xtitle="radius (arcsec)", title=titles[itag], pos=pp1[itag,*], /noerase     
      ;; oploterror, med_rad, med_prof, med_rad*0., med_err, psym=8, col=80, errcol=80
      
      plot, r0, r0, yr=[0.3, 1.7], /ys, xr=[1., 100.], /xs, /nodata, /xlog, $
            ytitle="Profile ratio", xtitle="radius (arcsec)", title=titles[itag], pos=pp1[itag,*], /noerase
      
      for iscan =0, nscan-1 do begin
         rad  = tab_rad(*, iscan, itag)
         prof = tab_prof(*, iscan, itag)/med_prof
         err  = sqrt(tab_var(*, iscan, itag))/med_prof
         oploterror, rad+iscan*decal, prof, rad*0., err, psym=8, col=tab_color(iscan), errcol=tab_color(iscan)
      endfor

      oplot, r0, r0*0.+1d, col=0
      if itag eq 0 then legendastro, text, textcolor=tab_color, box=0, charsize=charsz
      
   endfor ;; end TAG loop

   if png eq 1 then outplot, /close

   stop
   
endif ;; plot_all_scans


;;;
;;;
;;;     stats and beam etendue
;;;
;;;_______________________________________________________________________________________________
;; stabilite des parametres des modeles
if do_stats gt 0 then begin
   
   wind, 1, 1, xsize = 1500, ysize = 800, /free
   my_multiplot, 2, 2,  pp, pp1, /rev, ymargin=0., gap_x=0.1, gap_y=0.1, xmargin = 0.
   charsz = 0.9
      
   if png eq 1 then begin
      plot_file = plot_dir+"/Profile_fit_allscans_v"+strtrim(string(version), 2)+plot_suffixe
      if n_elements(version) gt 1 then plot_file = plot_dir+"/Profile_fit_allscans"+plot_suffixe
      outplot, file=plot_file, /png
   endif

   r0 = lindgen(999)/2.+ 1.
   
   tags   = ['1', '3', '1MM', '2']
   under  = ['', '', '_', '']
   titles = ['A1', 'A3', 'A1&A3', 'A2']
   ntags  = n_elements(tags)

   text      = strarr(nscan)
   tab_color = (indgen(nscan)+1L)*250./nscan 

   ;; nparams = 7, ntags = 4
   tab_3g_par  = dblarr(7, nscan, 4)
   tab_3g_err  = dblarr(7, nscan, 4)
   tab_3g_par2 = dblarr(7, nscan, 4)
   tab_mb_par  = dblarr(7, nscan, 4)
   tab_mb_err  = dblarr(7, nscan, 4)
   tab_mb_ir   = dblarr(1, nscan, 4) ;; internal radius
   
   for itag=0, ntags-1 do begin
      
      restore, profile_fit_files[0]
      
      
      if normalise gt 0 then begin
         min = 1d-4
         max = 4.
      endif else begin
         max = 2.*max(mainbeam_param[1, itag])
         min = max-max*(1d0-1d-5) 
      endelse
      
      plot, r0, r0, /ylog, /xlog, yr=[min, max], /ys, xr=[1., 500.], /xs, /nodata, $
            ytitle="Flux (Jy/beam)", xtitle="radius (arcsec)", title=titles[itag], pos=pp1[itag,*], /noerase
      
      for iscan =0, nscan-1 do begin
         print, "restoring ", profile_fit_files[iscan]
         restore, profile_fit_files[iscan], /v

         ;; ancienne convention
         ;; if scan_list[iscan] eq '20170224s177' then begin
         ;;    file = project_dir+'/v_'+strtrim(string(2),2)+'/Fit_'+scan_list[iscan]+'_v2.save'
         ;;    print, "restoring ",file
         ;;    restore, file
         ;; endif

         
         mb_p   = mainbeam_param[*, itag]
         mb_err = mainbeam_param_error[*, itag]

         norm = 1d0
         if normalise gt 0 then norm = mb_p[1]
         
         p = threeG_param[*, itag]
         p_err = threeG_param_error[*, itag]

         ;; 3-Gauss method LP
         fit_profile = profile_3gauss(r0,p)/norm ;; profile from fit params

         ;; 3-Gauss method FR
         p2 = threeG_param_2[*, itag]
         fit_profile_2 = fit_triple_beam(r0, p2)/norm


         oplot, r0, mb_p[1]*exp(-1.*r0^2/2d0/mb_p[2]/mb_p[3])/norm, col=tab_color[iscan], thick=1, linestyle=2
         oplot, r0, fit_profile, col=tab_color[iscan], thick=2


         tab_3g_par[*, iscan, itag]  = p
         tab_3g_err[*, iscan, itag]  = p_err
         tab_3g_par2[*, iscan, itag] = p2
         tab_mb_par[*, iscan, itag]  = mb_p
         tab_mb_err[*, iscan, itag]  = mb_err
         tab_mb_ir[0, iscan, itag]   = mainbeam_internal_radius[itag]

         
         text[iscan] = strtrim(scan_list[iscan],2)

      endfor ;; end SCAN loop 
      if itag eq 0 then legendastro, text, textcolor=tab_color, box=0, charsize=charsz, /right

            
   endfor ;; end TAG loop

   if png eq 1 then outplot, /close

   ;; 1mm
   print, '----------------------------------------------------'
   print, ''
   print, 'Median results 1mm'
   print, ''
   print, '----------------------------------------------------'
   w_1 = [0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 14, 15, 16, 17]
   w_1f = [0, 1, 2, 3, 4, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]
   print, "median FWHM1 = ", median(abs(tab_3G_par[3, w_1, 2])), ' pm ',stddev(abs(tab_3G_par[3, w_1, 2]))
   print, "median FWHM1 FR = ", median(abs(tab_3G_par2[3, w_1f, 2])), ' pm ',stddev(abs(tab_3G_par2[3, w_1f, 2]))

   w_2 = [0, 6, 12]
   ninv=n_elements(w_2)
   for i=0, ninv-1 do begin
      ind = w_2[i]
      truc = tab_3G_par[*, ind, 2]
      tab_3G_par[1,ind, 2] = truc[2]
      tab_3G_par[2,ind, 2] = truc[1]
      tab_3G_par[4,ind, 2] = truc[5]
      tab_3G_par[5,ind, 2] = truc[4]
   endfor
   w_2 = [0, 10, 11, 12, 13, 14, 5, 6, 8]
   print, "median FWHM2 = ", median(abs(tab_3G_par[4,w_2, 2])), ' pm ',stddev(abs(tab_3G_par[4, w_2, 2]))
   w_3 = [0, 10, 11, 12, 13, 14, 5, 6, 8]
   print, "median FWHM3 = ", median(abs(tab_3G_par[5,w_3, 2])), ' pm ',stddev(abs(tab_3G_par[5, w_3, 2]))

   w_2f = [3, 4, 9, 11, 13]
   ninv=n_elements(w_2f)
   for i=0, ninv-1 do begin
      ind = w_2f[i]
      truc = tab_3G_par2[*, ind, 2]
      tab_3G_par2[1,ind, 2] = truc[2]
      tab_3G_par2[2,ind, 2] = truc[1]
      tab_3G_par2[4,ind, 2] = truc[5]
      tab_3G_par2[5,ind, 2] = truc[4]
   endfor
   print, "median FWHM2 FR = ", median(abs(tab_3G_par2[4,*, 2])), ' pm ',stddev(abs(tab_3G_par2[4, *, 2]))
   w_3f = [0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 16, 17]
   print, "median FWHM3 FR = ", median(abs(tab_3G_par2[5,w_3f, 2])), ' pm ',stddev(abs(tab_3G_par2[5, w_3f, 2]))
   print, ''
   norm = total(abs(tab_3G_par[0:2, *, 2]), 1)
   for i = 0, 17 do print,tab_3G_par[0:2, i, 2]/norm[i]
   print, "median Amp1 = ", median(10.d0*alog(abs(tab_3G_par[0, w_1, 2])/norm[w_1])/alog(10.d0)), ' pm ',stddev(10.d0*alog(abs(tab_3G_par[0, w_1, 2])/norm[w_1])/alog(10.d0))
 
   print, "median Amp2 = ", median(10.d0*alog(abs(tab_3G_par[1, w_1, 2])/norm[w_1])/alog(10.d0)), ' pm ',stddev(10.d0*alog(abs(tab_3G_par[1, w_1, 2])/norm[w_1])/alog(10.d0))
   
   print, "median Amp3 = ", median(10.d0*alog(abs(tab_3G_par[2, w_1, 2])/norm[w_1])/alog(10.d0)), ' pm ',stddev(10.d0*alog(abs(tab_3G_par[2, w_1, 2])/norm[w_1])/alog(10.d0))
   
   norm2 = total(abs(tab_3G_par2[0:2, *, 2]), 1)
   for i = 0, 17 do print,i, ', ',tab_3G_par2[0:2, i, 2]/norm2[i]
   w_2inv = [3, 4, 9, 11, 13]
   w_2 = [0, 1, 2, 5, 6, 7, 8, 10, 12, 14, 15, 16, 17]
   print, "median Amp1 FR = ", median(10.d0*alog(abs(tab_3G_par2[0, w_2, 2])/norm2[w_2])/alog(10.d0)), ' pm ',stddev(10.d0*alog(abs(tab_3G_par2[0, w_2, 2])/norm2[w_2])/alog(10.d0))
   print, "median Amp2 FR = ", median(10.d0*alog(abs(tab_3G_par2[1, w_2, 2])/norm2[*])/alog(10.d0)), ' pm ',stddev(10.d0*alog(abs(tab_3G_par2[1, w_2, 2])/norm2[w_2])/alog(10.d0))
   print, "median Amp3 FR = ", median(10.d0*alog(abs(tab_3G_par2[2, w_2, 2])/norm2[*])/alog(10.d0)), ' pm ',stddev(10.d0*alog(abs(tab_3G_par2[2, w_2, 2])/norm2[*])/alog(10.d0))

   ;; 2mm
   print, '----------------------------------------------------'
   print, ''
   print, 'Median results 2mm'
   print, ''
   print, '----------------------------------------------------'
   print, "median FWHM1 = ", median(abs(tab_3G_par[3,*, 3])), ' pm ',stddev(abs(tab_3G_par[3, *, 3]))
   w_1f = [0, 1, 2, 3, 4, 7, 8, 9, 10, 11, 13, 14, 15, 16, 17]
   print, "median FWHM1 FR = ", median(abs(tab_3G_par2[3, w_1f, 3])), ' pm ',stddev(abs(tab_3G_par2[3, w_1f, 3]))

   print, "median FWHM2 = ", median(abs(tab_3G_par[4,*, 3])), ' pm ',stddev(abs(tab_3G_par[4, *, 3]))
   print, "median FWHM3 = ", median(abs(tab_3G_par[5,*, 3])), ' pm ',stddev(abs(tab_3G_par[5, *, 3]))
   
   for i=0, 17 do print, i, tab_3G_par2[*,i, 3]
   av = [1, 2, 6, 12, 15]
   w_2f = [0, 3, 4, 5, 7, 8, 9, 10, 11, 13, 14, 16, 17]
   print, "median FWHM2 FR = ", median(abs(tab_3G_par2[4,w_2f, 3])), ' pm ',stddev(abs(tab_3G_par2[4, w_2f, 3]))
   print, "median FWHM3 FR = ", median(abs(tab_3G_par2[5,w_2f, 3])), ' pm ',stddev(abs(tab_3G_par2[5, w_2f, 3]))

   print, ''
   for i=0, 17 do print, i, tab_3G_par[0:2, i, 3]
   w_1 = [0, 3, 6, 7, 8, 9, 12, 15, 16]
   norm = total(abs(tab_3G_par[0:2, *, 3]), 1)
   for i = 0, n_elements(w_1)-1 do print,tab_3G_par[0:2, w_1[i], 3]/norm[i]
   print, "median Amp1 = ", median(10.0d0*alog(abs(tab_3G_par[0, w_1, 3])/norm[w_1])/alog(10.0d0)), ' pm ',stddev(10.0d0*alog(abs(tab_3G_par[0, w_1, 3])/norm[w_1])/alog(10.0d0))
   print, "median Amp2 = ", median(10.0d0*alog(abs(tab_3G_par[1, w_1, 3])/norm[w_1])/alog(10.0d0)), ' pm ',stddev(10.0d0*alog(abs(tab_3G_par[1, w_1, 3])/norm[w_1])/alog(10.0d0))
   print, "median Amp3 = ", median(10.0d0*alog(abs(tab_3G_par[2, w_1, 3])/norm[w_1])/alog(10.0d0)), ' pm ',stddev(10.0d0*alog(abs(tab_3G_par[2, w_1, 3])/norm[w_1])/alog(10.0d0))
   
   
   norm2 = total(abs(tab_3G_par2[0:2, *, 3]), 1)
   for i = 0, n_elements(w_2f)-1 do print,tab_3G_par2[0:2, w_2f[i], 3]/norm2[w_2f[i]]
   print, "median Amp1 FR = ", median(10.0d0*alog(abs(tab_3G_par2[0, w_2f, 3])/norm2[w_2f])/alog(10.0d0)), ' pm ',stddev(10.0d0*alog(abs(tab_3G_par2[0, w_2f, 3])/norm2[w_2f])/alog(10.0d0))
   print, "median Amp2 FR = ", median(10.0d0*alog(abs(tab_3G_par2[1, w_2f, 3])/norm2[w_2f])/alog(10.0d0)), ' pm ',stddev(10.0d0*alog(abs(tab_3G_par2[1, w_2f, 3])/norm2[w_2f])/alog(10.0d0))
   print, "median Amp3 FR = ", median(10.0d0*alog(abs(tab_3G_par2[2, w_2f, 3])/norm2[w_2f])/alog(10.0d0)), ' pm ',stddev(10.0d0*alog(abs(tab_3G_par2[2, w_2f, 3])/norm2[w_2f])/alog(10.0d0))


   
   
   stop

   ;; combined profile & histograms
   ;;----------------------------------------
   ;; if png eq 1 then begin
   ;;    ;;plot_file =
   ;;    ;;plot_dir+"/Profile_allscans_over_combined_v"+strtrim(string(version),2)+plot_suffixe
   ;;    plot_file = plot_dir+"/Profile_allscans_over_median_v"+plot_suffixe
   ;;    outplot, file=plot_file, /png
   ;; endif
   
   ;; histograms
   params  = ['3Gauss_FWHM_1', '3Gauss_FWHM_2', '3Gauss_FWHM_3', "MainBeam_FWHM", "Mainbeam_ellip", "MainBeam_FWHM_XY"]
   nparams = 7

   tab_xtitle = ["G1-FWHM (arcsec)", "G2-FWHM (arcsec)", "G3-FWHM (arcsec)", "Main Beam FWHM (arcsec)", 'Main Beam ellipticity', '2D Main Beam FWHM (arcsec)']
   
   tab_params = dblarr(nparams, nscan, 4)
   ;; fill in the table

   ;; 1st G FWHM
   tab_params[0, *, *] = tab_3g_par[3, *, *]
   ;; 2nd and 3rd G FWHM
   for itag=0, ntags-1 do begin
      min = abs(min([tab_3g_par[4, *, itag], tab_3g_par[5, *, itag]], dimension=1, /abs))      
      tab_params[1, *, itag] = min
      max = abs(max([tab_3g_par[4, *, itag], tab_3g_par[5, *, itag]], dimension=1, /abs))      
      tab_params[2, *, itag] = max
   endfor

   ;; Main Beam geometrical FWHM
   tab_params[3, *, *] = sqrt(tab_mb_par[2, *, *]*tab_mb_par[3, *, *])/!fwhm2sigma
   ;; Main Beam ellipticity
   for itag=0, ntags-1 do begin
      ga = max([tab_mb_par[2, *, itag], tab_mb_par[3, *, itag]], dimension=1)
      pa = min([tab_mb_par[2, *, itag], tab_mb_par[3, *, itag]], dimension=1)
      tab_params[4, *, itag] = ga/pa
   endfor
   tab_params[5, *, *] = tab_mb_par[2, *, *]/!fwhm2sigma
   tab_params[6, *, *] = tab_mb_par[3, *, *]/!fwhm2sigma
      ;;endfor
   ;;endfor

   
   for ipar=0, nparams-2 do begin

      print, ' '
      print, "----------------"
      print, params[ipar]
      
      wind, 1, 1, xsize = 1000, ysize = 650, /free
      my_multiplot, 2, 2,  pp, pp1, /rev, ymargin=0., gap_x=0.1, gap_y=0.1, xmargin = 0.
      charsz = 0.9
      ps_thick = 1.
      
      if png eq 1 then begin
         plot_file = plot_dir+"/Profile_fit_allscans"+plot_suffixe+"_histogram_"+params
         ;;outplot, file=plot_file, /png
      endif
      r0 = lindgen(999)/2.+ 1.
      
      tags   = ['1', '3', '1MM', '2']
      under  = ['', '', '_', '']
      titles = ['A1', 'A3', 'A1&A3', 'A2']
      ntags  = n_elements(tags)
      
      text  = strtrim(scan_list,2)
      
      for itag=0, ntags-1 do begin
         
         ;; mb_profiles = dblarr(999, nscan)
         ;; g3_profiles = dblarr(999, nscan)
         ;; if normalise gt 0 then begin
         ;;    for i=0, nscan-1 do mb_profiles[*, i] = exp(-1.*r0^2/2d0/tab_mb_par[2, i, itag]/tab_mb_par[3, i, itag])
         ;;    for i=0, nscan-1 do g3_profiles[*, i] = profile_3gauss(r0,tab_3g_par[*, i, itag])/tab_mb_par[1, i, itag]
         ;; endif else begin
         ;;    for i=0, nscan-1 do mb_profiles[*, i] = tab_mb_par[1, i, itag]*exp(-1.*r0^2/2d0/tab_mb_par[2, i, itag]/tab_mb_par[3, i, itag])
         ;;    for i=0, nscan-1 do g3_profiles[*, i] = profile_3gauss(r0,tab_3g_par[*, i, itag])
         ;; endelse
         
         ;; med_mb_prof = median(mb_profiles,dimension=2)
         ;; med_3g_prof = median(g3_profiles,dimension=2)
      
          
         ;; plot, r0, r0, yr=[1d-4, 30], /ys, xr=[1., 500.], /xs, /nodata, /xlog, /ylog, $
         ;;       ytitle="Profile ratio", xtitle="radius (arcsec)", title=titles[itag], pos=pp1[itag,*], /noerase     
         ;; oplot, r0, med_mb_prof, col=80
         ;; oplot, r0, med_3g_prof, col=250
         
         ;; plot, r0, r0, yr=[0.3, 1.7], /ys, xr=[1., 100.], /xs, /nodata, /xlog, $
         ;;       ytitle="Profile ratio", xtitle="radius (arcsec)", title=titles[itag], pos=pp1[itag,*], /noerase
         
         ;; for iscan =0, nscan-1 do begin
         
         ;;    ;oplot, r0, mb_profiles[*, iscan]/med_mb_prof , col=tab_color(iscan)
         ;;    oplot, r0, g3_profiles[*, iscan]/med_3g_prof , col=tab_color(iscan), thick=2
         ;; endfor
         
         ;; oplot, r0, r0*0.+1d, col=0
         ;; if itag eq 0 then legendastro, text, textcolor=tab_color,
         ;; box=0, charsize=charsz

         print, "---> A"+tags[itag]
     
         f = [reform(tab_params[ipar, *, itag])]
         fcol = 80
         if ipar eq 5 then begin
            f = CREATE_STRUCT('h1', dblarr(nscan), 'h2', dblarr(nscan))
            f.h1 = reform(tab_params[5, *, itag])
            f.h2 = reform(tab_params[6, *, itag])
            ;;help, f, /str
            fcol=[200, 80]
         endif
         
         ;;emin = mini[itag]
         ;;emax = maxi[itag]
         ;;bin  = binsi[itag]
         
         np_histo, f, out_xhist, out_yhist, out_gpar, fcol=fcol, fit=0, noerase=1, position=pp1[itag,*], nolegend=1, colorfit=250, thickfit=2*ps_thick, nterms_fit=3, xtitle=tab_xtitle(ipar)

         if ipar lt 5 then begin
            print, mean(f)
            print, median(f)
            print, stddev(f)
         endif else begin
            print, mean(f.(0))
            print, stddev(f.(0))
            print, mean(f.(1))
            print, stddev(f.(1))
         endelse
         print, ' '
            
            
         
      
      endfor ;; end TAG loop

      if png eq 1 then outplot, /close

   endfor ;; end PARAM loop

   wd, /a
   stop
   
endif ;; end do_stats



;;;
;;;
;;;     beam etendue
;;;
;;;_______________________________________________________________________________________________
if do_etendue gt 0 then begin
   
   wind, 1, 1, xsize = 1500, ysize = 800, /free
   my_multiplot, 2, 2,  pp, pp1, /rev, ymargin=0., gap_x=0.1, gap_y=0.1, xmargin = 0.
   charsz = 0.9
      
   if png eq 1 then begin
      plot_file = plot_dir+"/Profile_fit_allscans_v"+strtrim(string(version), 2)+plot_suffixe
      if n_elements(version) gt 1 then plot_file = plot_dir+"/Profile_fit_allscans"+plot_suffixe
      outplot, file=plot_file, /png
   endif

   r0 = lindgen(999)/2.+ 1.
   
   tags   = ['1', '3', '1MM', '2']
   under  = ['', '', '_', '']
   titles = ['A1', 'A3', 'A1&A3', 'A2']
   ntags  = n_elements(tags)

   fwhm_nomi = [!nika.fwhm_nom[0]+dblarr(3), !nika.fwhm_nom[1]]
   
   text      = strarr(nscan)
   tab_color = (indgen(nscan)+1L)*250./nscan 

   ;; nparams = 7, ntags = 4
   tab_3g_par  = dblarr(7, nscan, 4)
   tab_3g_err  = dblarr(7, nscan, 4)
   tab_3g_par2 = dblarr(7, nscan, 4)
   tab_mb_par  = dblarr(7, nscan, 4)
   tab_mb_err  = dblarr(7, nscan, 4)
   tab_mb_ir   = dblarr(1, nscan, 4) ;; internal radius
   
   for itag=0, ntags-1 do begin
      
      restore, profile_fit_files[0]
      
      
      if normalise gt 0 then begin
         min = 1d-4
         max = 4.
      endif else begin
         max = 2.*max(mainbeam_param[1, itag])
         min = max-max*(1d0-1d-5) 
      endelse
      
      plot, r0, r0, /ylog, /xlog, yr=[min, max], /ys, xr=[1., 500.], /xs, /nodata, $
            ytitle="Flux (Jy/beam)", xtitle="radius (arcsec)", title=titles[itag], pos=pp1[itag,*], /noerase
      
      for iscan =0, nscan-1 do begin
         print, "restoring ", profile_fit_files[iscan]
         restore, profile_fit_files[iscan], /v

         ;; ancienne convention
         ;; if scan_list[iscan] eq '20170224s177' then begin
         ;;    file = project_dir+'/v_'+strtrim(string(2),2)+'/Fit_'+scan_list[iscan]+'_v2.save'
         ;;    print, "restoring ",file
         ;;    restore, file
         ;; endif

         
         mb_p   = mainbeam_param[*, itag]
         mb_err = mainbeam_param_error[*, itag]

         norm = 1d0
         if normalise gt 0 then norm = mb_p[1]
         
         p = threeG_param[*, itag]
         p_err = threeG_param_error[*, itag]

         ;; 3-Gauss method LP
         fit_profile = profile_3gauss(r0,p)/norm ;; profile from fit params

         ;; 3-Gauss method FR
         p2 = threeG_param_2[*, itag]
         fit_profile_2 = fit_triple_beam(r0, p2)/norm


         oplot, r0, mb_p[1]*exp(-1.*r0^2/2d0/mb_p[2]/mb_p[3])/norm, col=tab_color[iscan], thick=1, linestyle=2
         oplot, r0, fit_profile, col=tab_color[iscan], thick=2


         tab_3g_par[*, iscan, itag]  = p
         tab_3g_err[*, iscan, itag]  = p_err
         tab_3g_par2[*, iscan, itag] = p2
         tab_mb_par[*, iscan, itag]  = mb_p
         tab_mb_err[*, iscan, itag]  = mb_err
         tab_mb_ir[0, iscan, itag]   = mainbeam_internal_radius[itag]

         
         text[iscan] = strtrim(scan_list[iscan],2)

      endfor ;; end SCAN loop 
      if itag eq 0 then legendastro, text, textcolor=tab_color, box=0, charsize=charsz, /right

            
   endfor ;; end TAG loop

   if png eq 1 then outplot, /close

   ;;stop

   ;; combined profile & histograms
   ;;----------------------------------------
   ;; if png eq 1 then begin
   ;;    ;;plot_file =
   ;;    ;;plot_dir+"/Profile_allscans_over_combined_v"+strtrim(string(version),2)+plot_suffixe
   ;;    plot_file = plot_dir+"/Profile_allscans_over_median_v"+plot_suffixe
   ;;    outplot, file=plot_file, /png
   ;; endif
   
   ;; histograms
   params  = ['method 1', 'method 2', 'method 3', 'method 4', 'method 5', 'scatter']
   nparams = 6

   tab_xtitle = ['3Gaussian Beam Efficiency',  '3Gaussian Beam Efficiency', '3Gaussian Beam Efficiency',  '3Gaussian Beam Efficiency', '3Gaussian Beam Efficiency', '3Gaussian Beam Efficiency']
   
   tab_params = dblarr(nparams, nscan, 4)
   ;; fill in the table

   
   r = lindgen(9999)/10. ;; 0-->16.7 arcmin
   un = dblarr(1201)+1d0
   x  = lindgen(1201)-600.
   xm = x#un 
   ym = transpose(xm)
   d  = sqrt(xm^2 + ym^2) 
   
   for iscan=0, nscan-1 do begin
      restore, input_map_files(iscan)
      grid_tags = tag_names( grid1)
      info_tags = tag_names( info1)
      xmap = grid1.xmap
      ymap = grid1.ymap
      restore, profile_fit_files[iscan]

      for itag=0, ntags-1 do begin
        
         ;; method 1: axi-circular main beam
         w = where(r le radius_maximum, nw)
         om_mb0  = total(exp(-1.*r[w]^2/2d0/(tab_3g_par[3, iscan, itag]*!fwhm2sigma)^2)*r[w])*(r[1]-r[0])*2.d0*!dpi
         prof   = profile_3gauss(r, tab_3g_par[*, iscan, itag])
         prof   = prof/max(prof)
         om_tot = total(prof[w]*r[w])*(r(1)-r(0))*2.d0*!dpi
         tab_params[0, iscan, itag] = om_mb0/om_tot
         
         ;; method 1b: axi-circular main beam of nominal FWHM [12.5, 18.5]
         om_mb00  = total(exp(-1.*r[w]^2/2d0/(fwhm_nomi[itag]*!fwhm2sigma)^2)*r[w])*(r(1)-r(0))*2.d0*!dpi
         tab_params[1, iscan, itag] = om_mb00/om_tot

         ;; method 2: 2D Gaussian Main Beam
         wd = where(d le radius_maximum, nwd)
         par = tab_mb_par[*, iscan, itag]
         par[1] = 1.d0 ;; normalised
         par[0] = 0.d0 ;; sans piedestal
         mb = nika_gauss2(xm, ym, par)
         ;;rm = sqrt((xm-tab_mb_par[4, iscan, itag])^2+(ym-tab_mb_par[5, iscan, itag])^2)
         om_mb = total(mb[wd]) ;; arcsec^2
         tab_params[2, iscan, itag] = om_mb/om_tot
         
         ;; measured beam map
         wmap = where(grid_tags eq 'MAP_I'+under[itag]+strtrim(tags[itag], 2), nw)
         map = grid1.(wmap)
         ;;wvar = where(grid_tags eq 'MAP_VAR_I'+under[itag]+strtrim(tags[itag], 2), nw)
         ;;var = grid1.(wvar)
         ;;w=where(finite(var) gt 0 and var lt median(var))
         ;;om_tot_ = total(map[w]/var[w])/total(1d0/var[w])/max(map[w])
         wtag = where( strupcase(info_tags) eq "RESULT_OFF_X_"+tags[itag], nwtag)
         x0   = info1.(wtag)
         wtag = where( strupcase(info_tags) eq "RESULT_OFF_Y_"+tags[itag], nwtag)
         y0   = info1.(wtag)
         dmap = sqrt((xmap-x0)^2+(ymap-y0)^2)
         w=where(dmap le radius_maximum )
         om_tot_ = total(map[w])/max(map[w])
         tab_params[3, iscan, itag] = om_mb/om_tot_

         ;; measured profile
         prof = measured_profile[*, itag]
         r    = MEASURED_PROFILE_RADIUS[*, itag]
         w = where(r le radius_maximum, nwr)
         om_tot__ = total(prof[w]*r[w])*(r(1)-r(0))*2.d0*!dpi/max(prof)
         tab_params[4, iscan, itag] = om_mb00/om_tot__

         
         scat = stddev([om_mb0/om_tot, om_mb/om_tot, om_mb/om_tot_, om_mb/om_tot__])
         tab_params[5, iscan, itag] = scat
         
         
      endfor
   endfor


   ;; print results

   print,''
   print,'--------------------------------'
   print,''
   print,'Beam efficiency'
   print,''
   print,'-------------------------------'
   for iscan = 0, nscan-1 do begin
      print,'===='
      print,scan_list[iscan]
      print,'===='
      for itag = 0, ntags-1 do begin
         print, 'Array ', tags[itag]
         ;print,'--> Using a fitted total beam and a single fwhm main beam'
         ;print,tab_params[0, iscan, itag]
         ;print,'--> Using a fitted total beam and a single nominal fwhm main beam'
         ;print,tab_params[1, iscan, itag]
         ;print,'--> Using a fitted total beam and a 2D Gaussian main beam'
         ;print,tab_params[2, iscan, itag]
         ;print,'--> Using the total beam measured in the map and a 2D Gaussian main beam'
         ;print,tab_params[3, iscan, itag]
         ;print,'--> Using the total beam measured in the profile and a single nominal fwhm main beam'
         print,tab_params[4, iscan, itag]
      endfor
      
   endfor
   print,''
   print,'--------------------------------'
   print,''
   stop
   


   
   for ipar=0, nparams-2 do begin

      print, ' '
      print, "----------------"
      print, params[ipar]
      
      wind, 1, 1, xsize = 1000, ysize = 650, /free
      my_multiplot, 2, 2,  pp, pp1, /rev, ymargin=0., gap_x=0.1, gap_y=0.1, xmargin = 0.
      charsz = 0.9
      ps_thick = 1.
      
      if png eq 1 then begin
         plot_file = plot_dir+"/Profile_fit_allscans"+plot_suffixe+"_histogram_"+params
         ;;outplot, file=plot_file, /png
      endif
      r0 = lindgen(999)/2.+ 1.
      
      tags   = ['1', '3', '1MM', '2']
      under  = ['', '', '_', '']
      titles = ['A1', 'A3', 'A1&A3', 'A2']
      ntags  = n_elements(tags)
      
      text  = strtrim(scan_list,2)
      
      for itag=0, ntags-1 do begin
         
         ;; mb_profiles = dblarr(999, nscan)
         ;; g3_profiles = dblarr(999, nscan)
         ;; if normalise gt 0 then begin
         ;;    for i=0, nscan-1 do mb_profiles[*, i] = exp(-1.*r0^2/2d0/tab_mb_par[2, i, itag]/tab_mb_par[3, i, itag])
         ;;    for i=0, nscan-1 do g3_profiles[*, i] = profile_3gauss(r0,tab_3g_par[*, i, itag])/tab_mb_par[1, i, itag]
         ;; endif else begin
         ;;    for i=0, nscan-1 do mb_profiles[*, i] = tab_mb_par[1, i, itag]*exp(-1.*r0^2/2d0/tab_mb_par[2, i, itag]/tab_mb_par[3, i, itag])
         ;;    for i=0, nscan-1 do g3_profiles[*, i] = profile_3gauss(r0,tab_3g_par[*, i, itag])
         ;; endelse
         
         ;; med_mb_prof = median(mb_profiles,dimension=2)
         ;; med_3g_prof = median(g3_profiles,dimension=2)
      
          
         ;; plot, r0, r0, yr=[1d-4, 30], /ys, xr=[1., 500.], /xs, /nodata, /xlog, /ylog, $
         ;;       ytitle="Profile ratio", xtitle="radius (arcsec)", title=titles[itag], pos=pp1[itag,*], /noerase     
         ;; oplot, r0, med_mb_prof, col=80
         ;; oplot, r0, med_3g_prof, col=250
         
         ;; plot, r0, r0, yr=[0.3, 1.7], /ys, xr=[1., 100.], /xs, /nodata, /xlog, $
         ;;       ytitle="Profile ratio", xtitle="radius (arcsec)", title=titles[itag], pos=pp1[itag,*], /noerase
         
         ;; for iscan =0, nscan-1 do begin
         
         ;;    ;oplot, r0, mb_profiles[*, iscan]/med_mb_prof , col=tab_color(iscan)
         ;;    oplot, r0, g3_profiles[*, iscan]/med_3g_prof , col=tab_color(iscan), thick=2
         ;; endfor
         
         ;; oplot, r0, r0*0.+1d, col=0
         ;; if itag eq 0 then legendastro, text, textcolor=tab_color,
         ;; box=0, charsize=charsz

         print, "---> A"+tags[itag]
     
         f = [reform(tab_params[ipar, *, itag])]
         fcol = 80
                  
         ;;emin = mini[itag]
         ;;emax = maxi[itag]
         ;;bin  = binsi[itag]
         
         np_histo, f, out_xhist, out_yhist, out_gpar, fcol=fcol, fit=0, noerase=1, position=pp1[itag,*], nolegend=1, colorfit=250, thickfit=2*ps_thick, nterms_fit=3, xtitle=tab_xtitle(ipar)

         
         print, 'mean = ', mean(f)
         print, 'median = ', median(f)
         print, 'stddev = ', stddev(f)
         print, ' '
            
            
         
      
      endfor ;; end TAG loop

      if png eq 1 then outplot, /close

   endfor ;; end PARAM loop

   stop
   wd, /a
   
   
endif ;; end do_etendue







end
