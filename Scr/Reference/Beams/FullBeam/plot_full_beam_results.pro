;;
;;
;;
;;    Fit de modele de profile sur la carte de lobe de la Sect. Full Beam pattern
;;
;;    voir production de la carte dans comresult_beammap.pro
;;
;;________________________________________________________________________

pro plot_full_beam_results, png=png, ps=ps, pdf=pdf
  
  project_dir  = '/home/perotto/NIKA/Plots/Beams/FullBeams/'
  plot_dir     = project_dir
  version      = 1

  ;; plot aspect
  ;;----------------------------------------------------------------

  
  ;; window size
  wxsize = 800.
  wysize = 550.
  ;; plot size in files
  pxsize = 12.3
  pysize = 9.
  ;; charsize
  charsize  = 1.0
  if keyword_set(png) then png = 1 else png=0 
  if keyword_set(ps) then charthick = 3.0 else charthick = 1.0 
  if keyword_set(ps) then thick     = 3.0 else thick = 2.0
  symsize   = 0.7

  decibel=1

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


;; plots
;;--------------------------------------------------
;; plot superimposed profile of all the scans
do_plot_allscans = 1
normalise        = 1
plot_suffixe='_db';'_mixed'

nbin = 225 ;; 100

;; stat on profile models
do_stats = 0
;normalise        = 0
;plot_suffixe='_uranus'
normalise        = 1
plot_suffixe='_mixed'


;; input_map_files (IN) and profile_fit_files (OUT)
;;---------------------------------------------------------------------------------------------
profile_fit_files = project_dir+'Profiles/'+'Prof_3Gauss_'+strtrim(scan_list,2)+'.save'
input_map_files   = project_dir+'v_'+strtrim(string(version), 2)+'/'+strtrim(scan_list,2)+'/results.save'





;;_______________________________________________________________________________________
;;_______________________________________________________________________________________
;;_______________________________________________________________________________________

nscan = n_elements(scan_list)

;; combined results

m1 = [10.8, 10.8, 10.8, 17.4]
m2 = [11.3, 11.2, 11.2, 17.4]
m3 = [11.3, 11.1, 11.2, 17.8]
m4 = [11.2, 11.1, 11.2, 17.6]

s1 = [0.1, 0.1, 0.1, 0.1]
s2 = [0.4, 0.4, 0.3, 0.2]
s3 = [0.2, 0.2, 0.2, 0.1]
s4 = [0.1, 0.1, 0.1, 0.1]


all = [[m1], [m2], [m3], [m4]]
err = [[s3], [s2], [s3], [s3]]

comb = dblarr(4)
sig  = dblarr(4)
for ia = 0, 3 do begin
   sig(ia) = 1d0/total(1d0/err(ia, *)^2)
   comb(ia) = total(all(ia,*)/err(ia, *)^2)*sig(ia)
endfor


;; median 3G profile
avg_amp1  = [0.89, 0.90, 0.90, 0.96]
avg_amp2  = [0.08, 0.07, 0.07, 0.03]
avg_amp3  = [5.d-3, 4.d-3, 4.d-3, 1.d-3]
avg_fwhm1 = [11., 11., 11., 17.5]
avg_fwhm2 = [29., 30., 29., 63.]
avg_fwhm3 = [65., 72., 70., 65.]

avg_amp1_  = [0.89, 0.90, 0.90, 0.96]
avg_amp2_  = [0.08, 0.07, 0.07, 0.03]
avg_amp3_  = [5.d-3, 4.d-3, 4.d-3, 1.d-3]
avg_fwhm1_ = [11., 11., 11., 17.5]
avg_fwhm2_ = [29., 30., 29., 63.]
avg_fwhm3_ = [65., 72., 70., 65.]

;; 1mm
;; median results using LP
avg_amp1_[2] = 0.93
avg_amp2_[2] = 0.07
avg_amp3_[2] = 0.0025
avg_fwhm1_[2] = 10.8
avg_fwhm2_[2] = 30.0
avg_fwhm3_[2] = 81.0

;; median result using FR
;avg_amp1_[2] = 0.88
;avg_amp2_[2] = 0.10
;avg_amp3_[2] = 0.01
;avg_fwhm1_[2] = 10.8
;avg_fwhm2_[2] = 24.0
;avg_fwhm3_[2] = 58.0

;; 2019
avg_amp1[2] = 0.90   ;; +- 0.2
avg_amp2[2] = 0.09   ;; +- 0.01
avg_amp3[2] = 0.009  ;; +- 0.003
avg_fwhm1[2] = 10.8  ;; +- 0.3
avg_fwhm2[2] = 25.0  ;; +- 1
avg_fwhm3[2] = 57.0  ;; +- 4


;; 2mm
;; first guess
;avg_amp1[3] = 0.95
;avg_amp2[3] = 0.05
;avg_amp3[3] = 0.003
;avg_fwhm1[3] = 17.0
;avg_fwhm2[3] = 42.0
;avg_fwhm3[3] = 85.0

;; median results using FR
avg_amp1_[3]  = 0.95
avg_amp2_[3]  = 0.05
avg_amp3_[3]  = 0.002
avg_fwhm1_[3] = 17.4
avg_fwhm2_[3] = 42.0
avg_fwhm3_[3] = 99.0

;; 2019
avg_amp1[3] = 0.948   ;; +- 0.006
avg_amp2[3] = 0.050   ;; +- 0.016
avg_amp3[3] = 0.002  ;; +- 0.010
avg_fwhm1[3] = 17.0  ;; +- 0.2
avg_fwhm2[3] = 42.0  ;; +- 6
avg_fwhm3[3] = 99.0  ;; +- 20



;; median results using LP
;avg_amp1[3] = 0.97
;avg_amp2[3] = 0.03
;avg_amp3[3] = 0.0001
;avg_fwhm1[3] = 17.4
;avg_fwhm2[3] = 63.0
;avg_fwhm3[3] = 65.0

avg_3gauss_p = [0.95, 0.05, 0.003, 17.4, 42.0, 99.0]


print, '-----------------------------'
print, ''
print, '    3G model parameters'
print, ''
print, '-----------------------------'
print, "main beam : amp = ", 10.d0*alog(avg_amp1[2:3])/alog(10.d0), " , FWHM = ", avg_fwhm1[2:3]
print, "first error beam : amp = ", 10.d0*alog(avg_amp2[2:3])/alog(10.d0), " , FWHM = ", avg_fwhm2[2:3]
print, "second error beam : amp = ", 10.d0*alog(avg_amp3[2:3])/alog(10.d0), " , FWHM = ", avg_fwhm3[2:3]

stop 

;;    plots & stats
;;_______________________________________________________________________________________

;; superimpose all the profiles
if do_plot_allscans gt 0 then begin
   
   plot_color_convention, col_a1, col_a2, col_a3, $
                          col_mwc349, col_crl2688, col_ngc7027, $
                          col_n2r9, col_n2r12, col_n2r14
   
   scan_col = [245, 230, 200, 180, 160, 140, 120, 115, 95, 90, 80, 75, 65, 60, 50, 45, 35, 10]
   
   r0 = lindgen(999)/2.+ 1.
   
   tags   = ['1', '3', '1MM', '2']
   under  = ['', '', '_', '']
   titles = ['A1', 'A3', 'A1&A3', 'A2']
   suf    = ['_a1', '_a3', '_1mm', '_a2'] 
   quoi   = titles
   ntags  = n_elements(tags)
   
   restore, input_map_files[0], /v
   grid_tags = tag_names( grid1)
   info_tags = tag_names( info1)
   grid_suffix = ['1', '3', '_1MM', '_2MM']
   
   text      = strarr(nscan)
   tab_color = scan_col

   tab_rad   = dblarr(nbin, nscan, 4)
   tab_prof  = dblarr(nbin, nscan, 4)
   tab_var   = dblarr(nbin, nscan, 4)
   
   for iscan =0, nscan-1 do begin
         print, "restoring ", profile_fit_files[iscan]
         restore, profile_fit_files[iscan], /v
         restore, input_map_files[iscan], /v
         
         for itag=0, 3 do begin
            rad      = measured_profile_radius[*, itag]
            prof     = measured_profile[*, itag]
            proferr  = measured_profile_error[*, itag]
            nr = n_elements(rad)
         
            if normalise gt 0 then begin
               ;;norm = max(prof[0:10])
               wmap = where( strupcase(grid_tags) eq "MAP_I"+grid_suffix[itag], nwmap)
               norm = max(grid1.(wmap))
               norm = amplitude[itag]
               
               prof = prof/norm
               proferr = proferr/norm
            endif
         
            tab_rad[ 0:nr-1, iscan, itag] = rad[0:nr-1]
            tab_prof[0:nr-1, iscan, itag] = prof[0:nr-1]
            tab_var[ 0:nr-1, iscan, itag] = proferr[0:nr-1]^2
            
         endfor
         
      endfor


   for itag=0, ntags-1 do begin

      ylog = 1
      
      if normalise gt 0 then begin
         min = 1d-5
         max = 10.
         if decibel then begin
            min = -50.0
            max = 5.0
            ylog=0
         endif
      endif else begin
         prof     = tab_prof[*, 0, itag]
         max = 2.*max(prof)
         min = max-max*(1d0-1d-5) 
      endelse
      
      wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
      outfile = plot_dir+'plot_profiles'+suf[itag]+plot_suffixe
      outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
      
      plot, r0, r0,  yr=[min, max], /ys, xr=[1., 200.], /xs, /nodata, $
            ytitle="Beam profile [dB]", xtitle="Radius [arcsec]", /xlog;, ytickformat='(e9.0)'
      
      decal = alog(rad)/2.
      if normalise gt 0 then decal = 0.
 
      for iscan =0, nscan-1 do begin
         rad  = tab_rad[ 0:nr-1, iscan, itag]
         prof = tab_prof[0:nr-1, iscan, itag] 
         proferr = tab_var[ 0:nr-1, iscan, itag]

         if decibel then begin
            prof = 10.d0*alog(prof)/alog(10.d0)
            proferr = 10.d0/alog(10.d0)*proferr/tab_prof[0:nr-1, iscan, itag] 
         endif
         
         if (iscan eq 13 or iscan eq 17) then oploterror, rad+(iscan*decal), prof, rad*0., proferr, psym=8, col=scan_col[iscan], errcol=scan_col[iscan], symsize=symsize
         text[iscan] = strtrim(scan_list[iscan],2)

         ;if iscan ge (nscan-1) then begin
         ;   print, "-------------------------"
         ;   print, "restoring ", profile_fit_files[iscan]
         ;   restore, profile_fit_files[iscan]
         ;   p = threeG_param[*, itag]
         ;   ex_prof = profile_3gauss(r0,p)/total(p[0:2])
         ;   if decibel then ex_prof = 10.d0*alog(ex_prof)/alog(10.d0)
         ;   oplot, r0, ex_prof, col = 0, thick=thick*2.
         ;endif
      endfor

      ;; main beam
      ;;mb_comb_prof = exp(-r0^2/2.0d0/(comb[itag]*!fwhm2sigma)^2)
      mb_comb_prof = avg_amp1[itag]*exp(-(r0)^2/2.0/(avg_fwhm1[itag]*!fwhm2sigma)^2)
      if decibel then mb_comb_prof = 10.d0*alog(mb_comb_prof)/alog(10.d0)
      ;oplot, r0, mb_comb_prof, col = 0, thick=thick*1.5

      ;; average 3G model
      avg_prof = avg_amp1[itag]*exp(-(r0)^2/2.0/(avg_fwhm1[itag]*!fwhm2sigma)^2) + $
                 avg_amp2[itag]*exp(-(r0)^2/2.0/(avg_fwhm2[itag]*!fwhm2sigma)^2) + $
                 avg_amp3[itag]*exp(-(r0)^2/2.0/(avg_fwhm3[itag]*!fwhm2sigma)^2)
      if decibel then avg_prof = 10.d0*alog(avg_prof)/alog(10.d0)
      avg_prof_ = avg_amp1_[itag]*exp(-(r0)^2/2.0/(avg_fwhm1_[itag]*!fwhm2sigma)^2) + $
                 avg_amp2_[itag]*exp(-(r0)^2/2.0/(avg_fwhm2_[itag]*!fwhm2sigma)^2) + $
                 avg_amp3_[itag]*exp(-(r0)^2/2.0/(avg_fwhm3_[itag]*!fwhm2sigma)^2)
      
      if decibel then avg_prof_ = 10.d0*alog(avg_prof_)/alog(10.d0)
      oplot, r0, avg_prof, col = 249, thick=thick ;*1.5
      if itag gt 2 then stop
      oplot, r0, avg_prof_, col = 100, thick=thick;*1.5
      
      
      
      if itag eq 2 then legendastro, text[0:8], textcolor=tab_color[0:8], box=0, charsize=charsize*0.7, pos=[1.3, -20]
      if itag eq 2 then legendastro, text[9:*], textcolor=tab_color[9:*], box=0, charsize=charsize*0.7, pos=[4.9, -20]

      dd = 0
      if itag eq 2 then dd = -20.
      xyouts, 90+dd, 0, quoi[itag], col=0 

      outplot, /close

      if keyword_set(pdf) then spawn, 'epstopdf '+plot_dir+'plot_profiles'+suf[itag]+plot_suffixe+'.eps'

      
   endfor ;; end TAG loop

   stop

   r0 = lindgen(999)/2.+ 1.
   
   tags   = ['1', '3', '1MM', '2']
   under  = ['', '', '_', '']
   titles = ['A1', 'A3', 'A1&A3', 'A2']
   quoi   = titles
   suf    = ['_a1', '_a3', '_1mm', '_a2'] 
   ntags  = n_elements(tags)

   decal = alog(rad)/3.
   text  = strtrim(scan_list,2)

   if normalise gt 0 then decal = 0.
   
   for itag=0, ntags-1 do begin

      med_rad  = dblarr(100)
      med_prof = dblarr(100)
      med_var  = dblarr(100)
      w8   = dblarr(100)

      med_rad  = median(tab_rad(*, *, itag),dimension=2)
      med_prof = median(tab_prof(*, *, itag),dimension=2)
      med_err  = stddev(tab_prof(*, *, itag),dimension=2)

      
      wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
      outfile = plot_dir+'plot_profile_diff_wrt_median'+suf[itag]
      outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
      plot, r0, r0, yr=[-0.1, 0.1], /ys, xr=[1., 180.], /xs, /nodata, /xlog, $
            ytitle="Normalized profile residual", xtitle="radius (arcsec)"
      
      for iscan =0, nscan-1 do begin
         rad  = tab_rad(*, iscan, itag)
         prof = (tab_prof(*, iscan, itag)-med_prof)
         err  = sqrt(tab_var(*, iscan, itag))
         oploterror, rad+iscan*decal, prof, rad*0., err, psym=8, col=tab_color(iscan), errcol=tab_color(iscan), symsize=symsize
      endfor

      xyouts, 2, 0.08, quoi[itag], col=0, charsize=charsize 
      oplot, [1, 180], [0, 0], col=0

      outplot, /close

      if keyword_set(pdf) then spawn, 'epstopdf '+plot_dir+'plot_profile_diff_wrt_median'+suf[itag]+'.eps'

      
      
   endfor ;; end TAG loop

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
      
   if keyword_set(png) then begin
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
   tab_3g_par3  = dblarr(7, nscan, 4)
   
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
         
         ;fit_profile_2 = fit_triple_beam(r0, p2)/norm
         fit_profile_2 = p2[0]*exp(-(r0-p[6])^2/2.0/(p2[3]*!fwhm2sigma)^2) + $
                         p2[1]*exp(-(r0-p[6])^2/2.0/(p2[4]*!fwhm2sigma)^2) + $
                         p2[2]*exp(-(r0-p[6])^2/2.0/(p2[5]*!fwhm2sigma)^2)
         fit_profile_2 = fit_profile_2/norm

         ;oplot, r0, mb_p[1]*exp(-1.*r0^2/2d0/mb_p[2]/mb_p[3])/norm, col=tab_color[iscan], thick=1, linestyle=2
         oplot, r0, fit_profile, col=tab_color[iscan], thick=2
         oplot, r0, fit_profile_2, col=tab_color[iscan], thick=2, linestyle=2

         tab_3g_par[*, iscan, itag]  = p
         tab_3g_err[*, iscan, itag]  = p_err
         tab_3g_par2[*, iscan, itag] = p2
         tab_mb_par[*, iscan, itag]  = mb_p
         tab_mb_err[*, iscan, itag]  = mb_err
         tab_mb_ir[0, iscan, itag]   = mainbeam_internal_radius[itag]

         tab_3g_par3[*, iscan, itag] = p
        
         text[iscan] = strtrim(scan_list[iscan],2)

      endfor ;; end SCAN loop 
      if itag eq 0 then legendastro, text, textcolor=tab_color, box=0, charsize=charsz, /right

      for i=3, 5 do tab_3g_par[ i, *, itag] = abs(tab_3g_par[i, *, itag])
      for i=3, 5 do tab_3g_par2[i, *, itag] = abs(tab_3g_par2[i, *, itag])
      for i=3, 5 do tab_3g_par3[i, *, itag] = abs(tab_3g_par3[i, *, itag])
      
      ;; reorder G1, G2 and G3

      for isc = 0, nscan-1 do begin
         ggg = tab_3g_par[3:5, isc, itag]
         ggg0 = [tab_3g_par[3, isc, itag], max([tab_3g_par[4, isc, itag], 12.]), max([tab_3g_par[5, isc, itag], 15.])]
         ggg = ggg(sort(ggg0))
         tab_3g_par[3:5, isc, itag] = ggg
         tab_3g_par[0:2, isc, itag] = tab_3g_par[sort(ggg0), isc, itag]
         ;;
         ggg = tab_3g_par2[3:5, isc, itag]
         ggg0 = [tab_3g_par2[3, isc, itag], max([tab_3g_par2[4, isc, itag], 12.]), max([tab_3g_par2[5, isc, itag], 15.])]
         ggg = ggg(sort(ggg0))
         tab_3g_par2[3:5, isc, itag] = ggg
         tab_3g_par2[0:2, isc, itag] = tab_3g_par2[sort(ggg0), isc, itag]
         ;;
         ggg = tab_3g_par3[3:5, isc, itag]
         ggg0 = [tab_3g_par3[3, isc, itag], max([tab_3g_par3[4, isc, itag], 12.]), max([tab_3g_par3[5, isc, itag], 15.])]
         ggg = ggg(sort(ggg0))
         tab_3g_par3[3:5, isc, itag] = ggg
         tab_3g_par3[0:2, isc, itag] = tab_3g_par3[sort(ggg0), isc, itag]
      endfor
      
      ;; treat outliers
      w=where(abs(tab_3g_par3[4, *, itag]-median(tab_3g_par3[4, *, itag])) gt 6., n)
      if n gt 0 then tab_3g_par3[4, w, itag] = tab_3g_par2[4, w, itag]
      if n gt 0 then tab_3g_par3[1, w, itag] = tab_3g_par2[1, w, itag]
      w=where(tab_3g_par3[5, *, itag] gt 200., n)
      if n gt 0 then tab_3g_par3[5, w, itag] = tab_3g_par2[5, w, itag]
      if n gt 0 then tab_3g_par3[2, w, itag] = tab_3g_par2[2, w, itag]

      ;; average model
      print, "Average model :"
      print, "-----------------"
      norm = total(tab_3g_par3[0:2, *, itag], 1)
      print, 'avg_amp1 = ', mean(tab_3g_par2[0, *, itag]/norm)
      print, 'med_amp1 = ', median(tab_3g_par2[0, *, itag]/norm)
      print, 'avg_amp2 = ', mean(tab_3g_par2[1, *, itag]/norm)
      print, 'med_amp2 = ', median(tab_3g_par2[1, *, itag]/norm)
      print, 'avg_amp3 = ', mean(tab_3g_par2[2, *, itag]/norm)
      print, 'med_amp3 = ', median(tab_3g_par2[2, *, itag]/norm)

      print, 'avg_fwhm1 = ', mean(tab_3g_par2[3, *, itag])
      print, 'med_fwhm1 = ', median(tab_3g_par2[3, *, itag])
      print, 'avg_fwhm2 = ', mean(tab_3g_par2[4, *, itag])
      print, 'med_fwhm2 = ', median(tab_3g_par2[4, *, itag])
      print, 'avg_fwhm3 = ', mean(tab_3g_par2[5, *, itag])
      print, 'med_fwhm3 = ', median(tab_3g_par2[5, *, itag])
      
   endfor ;; end TAG loop

      
   
   if keyword_set(png) then outplot, /close

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
   params  = ['3Gauss_FWHM_1', '3Gauss_FWHM_2', '3Gauss_FWHM_3','3Gauss_A_1', '3Gauss_A_2', '3Gauss_A_3', '3Gauss2_FWHM_1', '3Gauss2_FWHM_2', '3Gauss2_FWHM_3', "MainBeam_FWHM", "Mainbeam_ellip", "MainBeam_FWHM_XY"]
   nparams = 13

   tab_xtitle = ["G1-FWHM (arcsec)", "G2-FWHM (arcsec)", "G3-FWHM (arcsec)", "G1-A", "G2-A", "G3-A", "FR-G1-FWHM (arcsec)", "FR-G2-FWHM (arcsec)", "FR-G3-FWHM (arcsec)", "Main Beam FWHM (arcsec)", 'Main Beam ellipticity', '2D Main Beam FWHM (arcsec)']
   
   tab_params = dblarr(nparams, nscan, 4)
   ;; fill in the table

   ;; 1st G FWHM
   tab_params[0, *, *] = tab_3g_par3[3, *, *]
   ;; 2nd and 3rd G FWHM
   tab_params[1, *, *] = tab_3g_par3[4, *, *]
   tab_params[2, *, *] = tab_3g_par3[5, *, *]
   ;;for itag=0, ntags-1 do begin
   ;;   min = abs(min([tab_3g_par3[4, *, itag], tab_3g_par3[5, *, itag]], dimension=1, /abs))      
   ;;   tab_params[1, *, itag] = min
   ;;   max = abs(max([tab_3g_par3[4, *, itag], tab_3g_par3[5, *, itag]], dimension=1, /abs))      
   ;;   tab_params[2, *, itag] = max
   ;;endfor

   ;; normalized amplitudes
   tab_params[3, *, *] = tab_3g_par3[0, *, *]/tab_mb_par[1, *, *]
   tab_params[4, *, *] = tab_3g_par3[1, *, *]/tab_mb_par[1, *, *]
   tab_params[5, *, *] = tab_3g_par3[2, *, *]/tab_mb_par[1, *, *]
   
   
   ;; 1st G FWHM
   tab_params[6, *, *] = tab_3g_par2[3, *, *]
   ;; 2nd and 3rd G FWHM
   tab_params[7, *, *] = tab_3g_par2[4, *, *]
   tab_params[8, *, *] = tab_3g_par2[5, *, *]
   ;;for itag=0, ntags-1 do begin
   ;;   min = abs(min([tab_3g_par2[4, *, itag], tab_3g_par2[5, *, itag]], dimension=1, /abs))      
   ;;   tab_params[4, *, itag] = min
   ;;   max = abs(max([tab_3g_par2[4, *, itag], tab_3g_par2[5, *, itag]], dimension=1, /abs))      
   ;;   tab_params[5, *, itag] = max
   ;;endfor
   
   ;; Main Beam geometrical FWHM
   tab_params[9, *, *] = sqrt(tab_mb_par[2, *, *]*tab_mb_par[3, *, *])/!fwhm2sigma
   ;;--- correct for Uranus finite extension
   delta_fwhm = [0.19, 0.19, 0.12, 0.19]
   wu = where(sources eq 'Uranus', nu)
   if nu gt 0 then begin
      for ia =0, 3 do tab_params[9, wu, ia] = tab_params[9, wu, ia]-delta_fwhm[ia]
      for ia =0, 3 do tab_params[0, wu, ia] = tab_params[0, wu, ia]-delta_fwhm[ia]
   endif
  
   
   ;; Main Beam ellipticity
   for itag=0, ntags-1 do begin
      ga = max([tab_mb_par[2, *, itag], tab_mb_par[3, *, itag]], dimension=1)
      pa = min([tab_mb_par[2, *, itag], tab_mb_par[3, *, itag]], dimension=1)
      tab_params[10, *, itag] = ga/pa
   endfor
   tab_params[11, *, *] = tab_mb_par[2, *, *]/!fwhm2sigma
   tab_params[12, *, *] = tab_mb_par[3, *, *]/!fwhm2sigma
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
      
      if keyword_set(png) then begin
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
         if ipar eq 11 then begin
            f = CREATE_STRUCT('h1', dblarr(nscan), 'h2', dblarr(nscan))
            f.h1 = reform(tab_params[8, *, itag])
            f.h2 = reform(tab_params[9, *, itag])
            ;;help, f, /str
            fcol=[200, 80]
         endif
         
         ;;emin = mini[itag]
         ;;emax = maxi[itag]
         ;;bin  = binsi[itag]
         
         np_histo, f, out_xhist, out_yhist, out_gpar, fcol=fcol, fit=0, noerase=1, position=pp1[itag,*], nolegend=1, colorfit=250, thickfit=2*ps_thick, nterms_fit=3, xtitle=tab_xtitle(ipar)

         if ipar lt 11 then begin
            w = where(abs(f-median(f)) le 2.*median(f) and abs(f-median(f)) le 2.*stddev(f), nn, compl=wout, ncompl=nout)
            w = where(abs(f-median(f)) le 2.*stddev(f), nn, compl=wout, ncompl=nout)
            print, 'n reg = ', nn
            if nout gt 0 then print, 'out list = ', text(wout)
            print, 'mean = ', mean(f)
            print, 'median = ', median(f)
            print, 'rms = ', stddev(f)
            print, 'rms reg = ', stddev(f(w))
         endif else begin
            print, 'mean 1 = ', mean(f.(0))
            print, 'rms 1 = ', stddev(f.(0))
            print, 'mean 2 = ', mean(f.(1))
            print, 'rms 2 = ', stddev(f.(1))
         endelse

         if ipar eq 9 or ipar eq 0 then begin
            wout = where(sources eq 'Mars', n_mars, compl=w, ncompl=n_compl)
            print, 'n mars = ', n_mars, ', n others = ', n_compl
            print, 'mean = ', mean(f(wout)), mean(f(w)) 
            print, 'median = ', median(f(wout)), median(f(w))
            print, 'rms = ', stddev(f(wout)), stddev(f(w))
            
         endif
         
         print, ' '
            
            
      endfor ;; end TAG loop
      if ipar eq 9 or ipar eq 0 then stop
      

      
      wd, /a
      if keyword_set(png) then outplot, /close

   endfor ;; end PARAM loop

   wd, /a
   stop
   
endif ;; end do_stats




end
