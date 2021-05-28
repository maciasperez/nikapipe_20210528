;
;
;
;      Get the NEP/kids as estimated while producing kidpars
;
;      LP, Feb. 17, 2017
;
;_______________________________________________________________________________________________________

kidpar_file   = !nika.off_proc_dir+'/kidpar_20170125s223_v2_sk_20170124s189.fits'
kidpar_file   = !nika.off_proc_dir+"/kidpar_skydip_n2r9_skd1.fits"
kidpar_file   = !nika.off_proc_dir+"/kidpar_20170125s243_v2_skd1.fits"
kidpar_file   = !nika.off_proc_dir+"/kidpar_20170226s425_v2_skp1_LP.fits" 
;;kidpar_file   = "kidpar_20170125s223_v2_sk_20170221s48.fits"


;; set to 1 for saving the FF plot in png files
saveplot  = 0

;; opacity correction
use_tau_skydip = 0
use_tau225     = 0
tau225         = 0.1
el_deg         = 48.290672
no_correction  = 0

;; consider only the half side of A1 which is not impacted by the
;; calibration gradient effect
mooncut_a1     = 0

normalized     = 0

;; set to 1 to use the default color range
free_range     = 1

;; default: plot the averaged noise > 4Hz
;; (for the 2 minutes of signal with best RMS)
;; other quantity can be plotted instead: 
;; --> the average noise around 1Hz
plot_noise_1hz = 0
;; --> the average noise around 2Hz
plot_noise_2hz = 0
;; --> the average noise around 10Hz
plot_noise_10hz = 1



;;=========================================================================
;; can be launched without further edition
;;
;;=========================================================================

charsize = 0.7

title = 'NEP in mJy/sqrt(Hz)'
histo_title = "NEP [mJy/sqrt(Hz)]"
histo_min   = 0.
histo_max   = 100.
histo_bin   = 1.
format='(f8.1)'

zrg  = 0

goal = [30., 30., 15.]*sqrt(2.) ;; en mJy/sqrt(Hz)
zrg  = fltarr(2, 3)
for i = 0, 2 do begin
   zrg[0, i] = goal[i]/5.
   zrg[1, i] = goal[i]*1.3
endfor


nickname = file_basename(kidpar_file, ".fits")

kp = mrdfits(kidpar_file, 1)

;; scan = '20170125s223'
;; ;;scan = '20161212s268'
;; project_dir = "/home/perotto/NIKA/Plots/Run22/Flats"
;; file_save = project_dir+'/v_1/'+scan+'/results.save'
;; restore, file_save, /v
;; kp = kidpar1


suf = ''
if plot_noise_1hz  gt 0 then suf = '_noise_1hz'
if plot_noise_2hz  gt 0 then suf = '_noise_2hz'
if plot_noise_10hz gt 0 then suf = '_noise_10hz' 


field = 'noise'
if plot_noise_1hz  gt 0 then field = 'noise_1hz'
if plot_noise_2hz  gt 0 then field = 'noise_2hz'
if plot_noise_10hz gt 0 then field = 'noise_10hz'
kp_tags  = tag_names( kp)
wfield = where( strupcase(kp_tags) eq strupcase(field), nwfield)

if nwfield gt 0 then begin
   print, "Plotting ", strupcase(field)
   
   
   array_tab = [1, 3, 2]
   
   if use_tau225 gt 0 then begin
      
      ;; simple nu2
      tau1mm = tau225 * (250./225.)*(250./225.)
      tau2mm = tau225 * (160./225.)*(160./225.)
      ;; fit from :
      ;; atm_model_mdp, atm_tau1_p1, atm_tau2_p1, atm_tau3_p1, atm_tau_225, nostop=1, bpshift=1.5, /tau225
      tau1mm = tau225 * 1.28210
      tau2mm = tau225 * 0.836040
      
      mytau = [tau1mm, tau1mm, tau2mm]
      
   endif
   if no_correction gt 0 then mytau = dblarr(3)
   
   
   
   kp_tags  = tag_names( kp)
   
   
   wind, 1, 1,  xsize = 1200, ysize =  400, /free
   for ilam=0, 2 do begin
      iarray = array_tab[ilam]
      
      w1 = where(kp.type eq 1 and kp.array eq iarray, n1)
      nas_x = kp(w1).nas_x
      nas_y = kp(w1).nas_y
      calib    = kp(w1).calib   ; Jy/Hz
      ;; noise on the 2 best-rms minutes averaged on Freq > 4Hz 
      noise    = (kp.(wfield))[w1] ; Hz/sqrt(Hz)
      
      if (use_tau225 gt 0 or no_correction gt 0) then begin
         print,"tau_skydip = ", mean(kp[w1].tau_skydip)
         el_avg_rad = el_deg*!dtor
         tau = mytau[ilam]
         opacor = exp((kp[w1].tau_skydip-tau)/sin(el_avg_rad))
         calib  = calib*opacor
      endif
      
      fov      = noise*calib*1.d3 ; mJy/sqrt(Hz)
      
      if (iarray eq 1 and mooncut_a1 gt 0) then begin
         
         angle = 13.*!dtor
         rot_x = nas_x*cos(angle) + nas_y*sin(angle)
         rot_y = -1*nas_x*sin(angle) + cos(angle)*nas_y
         
         wok = where(((rot_x-100.)^2 + rot_y^2) lt 3d4, nmoon, compl=wmoon)
         nas_x = rot_x(wok)*cos(angle) - rot_y(wok)*sin(angle)
         nas_y = rot_x(wok)*sin(angle) + cos(angle)*rot_y(wok)
         fov   = fov(wok)
      endif
      
      if (normalized gt 0.) then begin
         med = median(fov)
         fov = fov/med 
         zrg = [0.7, 1.3]
         format='(f6.2)'
      endif

      if free_range lt 1 then zr = zrg[*, ilam] else zr=0
      
      ;; plot
      xra = [-220, 220]
      yra = [-220, 220]
      
      matrix_plot, nas_x, nas_y, fov, xtitle='Nasmyth offset x', ytitle='Nasmyth offset y',title = 'Array '+strtrim(iarray, 2)+': '+title, xr = xra, yr=yra, /iso, format=format, charsize=charsize, position=[0.1/3. +0.33*(ilam), 0.1, 0.33*(ilam+1) -0.1/3., 0.9 ], zr=zr, /noerase
      
      
   endfor
   
   if saveplot gt 0 then begin
      project_dir = !nika.plot_dir+"/Flats"
      png = project_dir+'/FOVmap_nep_from_'+strtrim(nickname,2)+suf+'.png'
      WRITE_PNG, png, TVRD(/TRUE)
   endif
   
   
   
;; plot histograms
;;==================================================================
   wind, 1, 1, xsize = 1200, ysize =  400, /free
   for ilam=0, 2 do begin
      iarray = array_tab[ilam]
      w1 = where(kp.type eq 1 and kp.array eq iarray, n1)
      nas_x = kp(w1).nas_x
      nas_y = kp(w1).nas_y
      
      calib    = kp(w1).calib   ; Jy/Hz
      noise    = (kp.(wfield))[w1] ; Hz/sqrt(Hz)
      
      if (use_tau225 gt 0 or no_correction gt 0) then begin
         print,"tau_skydip = ", mean(kp[w1].tau_skydip)
         el_avg_rad = el_deg*!dtor
         tau = mytau[ilam]
         opacor = exp((kp[w1].tau_skydip-tau)/sin(el_avg_rad))
         calib  = calib*opacor
      endif
      
      fov      = noise*calib*1.d3 ; mJy/sqrt(Hz)
   
      
      if (iarray eq 1 and mooncut_a1 gt 0) then begin
         
         angle = 13.*!dtor
         rot_x = nas_x*cos(angle) + nas_y*sin(angle)
         rot_y = -1*nas_x*sin(angle) + cos(angle)*nas_y
         
         wok = where(((rot_x-100.)^2 + rot_y^2) lt 3d4, nmoon, compl=wmoon)
         
         HIST_PLOT, fov(wmoon), MIN=histo_min, MAX=histo_max, noplot=1, $
                    BINSIZE=histo_bin, NORMALIZE=NORMALIZE, dostat=0, FILL=FILL, X=X1,Y=Y1, hist=hist
         HIST_PLOT, fov(wok), MIN=histo_min, MAX=histo_max, noplot=0, $
                    BINSIZE=histo_bin, NORMALIZE=NORMALIZE, dostat=1, fitgauss=1, FILL=FILL, X=X2,Y=Y2, $
                    xtitle="A"+strtrim(iarray, 2)+": "+histo_title, $
                    position=[0.1/3. +0.33*(ilam), 0.1, 0.33*(ilam+1) -0.1/3., 0.9 ], $
                    noerase=1, xstyle=1, charsize=charsize 
         
         oplot, x1, y1, col=250
         
         gpar=fltarr(3)
         
         sum=total(hist)
         GPAR[0]=float(SUM[0])
         
         mom=moment(fov(wmoon),sdev=sdev)
   
         GPAR[1]=float(mom[0])
         GPAR[2]=float(sdev)

         ;; fit a Gaussian
         bins = lindgen(n_elements(hist)) * histo_bin + histo_min
         binCenters = bins + (histo_bin / 2.0)
         yfit = GaussFit(bincenters, hist, GPAR, NTERMS=3)
         
         gauss = exp(-1.*(x1 - GPAR[1])^2/2./GPAR[2]^2)*max(hist) ;/GPAR[2]/sqrt(2.*!dpi)
         
         oplot,x1,gauss,color=250
         
         legendastro,['N='+string(gpar[0]), $
                   'm='+string(gpar[1]), $
                      'RMS='+string(gpar[2])],/left,/top,/trad, charsize=charsize
         
      endif else begin
         HIST_PLOT, fov, MIN=histo_min, MAX=histo_max, noplot=noplot, $
                    BINSIZE=histo_bin, NORMALIZE=NORMALIZE, dostat=1, fitgauss=1, FILL=FILL, X=X,Y=Y,$
                    xtitle="A"+strtrim(iarray, 2)+": "+histo_title , $
                    position=[0.1/3. +0.33*(ilam), 0.1, 0.33*(ilam+1) -0.1/3., 0.9 ], $
                    noerase=1, xstyle=1 ;, charsize=charsize
      endelse
      
      
   endfor
   
   
   if keyword_set(saveplot) then begin
      project_dir = !nika.plot_dir+"/Flats"
      png = project_dir+'/Histo_nep_from_'+strtrim(nickname,2)+suf+'.png'
      WRITE_PNG, png, TVRD(/TRUE)
   endif
   
endif else print, "Field not defined in kidpar: ", field

end
