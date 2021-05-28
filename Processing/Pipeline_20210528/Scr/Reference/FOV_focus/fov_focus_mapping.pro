
;; copy of Processing/Pipeline/Scr/Reference/FOV_focus/fov_focus.pro

;; demonstration script to map the focus accross the entire FOV with a
;; sequence of OTF maps taken at different focus
;;----------------------------------------------------------------------

;; Sequence of out-of-focus beammap scans
scan_list = '20161030s'+strtrim([243, 244, 245, 246, 247],2)
;;scan_list = '20161028s'+strtrim([262, 265, 267, 268, 269],2)
;;scan_list = '20170125s'+strtrim([223, 240, 241],2)
;;scan_list = '20170226s'+strtrim([415, 416, 417, 418, 419], 2)
;;scan_list = '20170226s'+strtrim([425], 2)
;;scan_list = '20170226s'+strtrim([425, 415, 416, 417, 418, 419], 2)
;;scan_list = '20170125s'+strtrim([223, 240, 241, 243],2)
;;scan_list = '20170227s'+strtrim([291, 292, 293, 294, 295],2)


;; Taking into account the optimal focus drift in time
focus_time_drift = 0
scan_list_before = '20170226s'+strtrim([410, 411, 412, 413, 414], 2)
scan_list_after  = '20170226s'+strtrim([420, 421, 422, 423, 424], 2)
scan_list_before = '2017s0125'+strtrim([217, 218, 219, 220, 221], 2)
scan_list_after  = '2017s0125'+strtrim([225, 226, 227, 228, 229], 2)
delta_focus_byhand = [[0.1, 0., 0., 0.],[0.1, 0., 0., 0.],[0.1, 0., 0., 0.]]
delta_focus_byhand = 0

;; set to 1 to save the plot in png files
savepng  = 1
parallel = 1

nk_scan2run, scan_list[0]
project_dir  =  !nika.plot_dir+"/fov_focus"
;;project_dir  = "/home/perotto/NIKA/Plots/Run20/fov_focus_run21/v2"
project_dir  = "/home/perotto/NIKA/Plots/Run19/fov_focus"

;; 1./ preproc and reduce
;;     -- set to 0 once the beammaps have been processed
process      = 1
;;     -- set to 1 to relaunched the processing of already reduced scans
reprocess    = 0
;;     -- set force_kidpar to 1 and define the kidpar file here, and it will be used instead of the
;;       reference kidpar
force_kidpar = 0
;;kidpar_file  = !nika.off_proc_dir+"/kidpar_ref_from_compil_3d_70pc_valid_kids_withskydip.fits"
;;kidpar_file  = !nika.off_proc_dir+"/kidpar_20170125s223_v0_withskydip_20170124s189.fits"
;;kidpar_file  = !nika.off_proc_dir+"/kidpar_20170226s415_v2_skd1_LP.fits"
;;kidpar_file  = "kidpar_20170125s243_v2_sk_20170124189_c1fixed.fits"
;;kidpar_file  = !nika.off_proc_dir+"/kidpar_20170227s291_v2_skd1_LP.fits"
;;     -- opacity correction
do_opacity_correction = 1

;; 2./ map making
;;     -- set to 0 once the small maps around each centers have been produced
project_maps = 1
;;     -- set section "Define positions of the FOV to be mapped" below
;;        to change the FoV coverage

;; 3./ focus fit
;;     -- set to 0 once the focus are fitted
fit_focus             = 1
;;     -- rescale focus error by sqrt(Chi2/N_dof) ?
focus_error_rescaling = 1 
show_focus_plot       = 1


;; 4./ FoV maps
;;     -- discrete FoV map range
disc_zra = [-0.5, 0.5]
;;     -- continuous FoV map range
cont_zra = [-0.3, 0.3]



;;=========================================================================
;; can be launched without further edition
;;
;;=========================================================================


if force_kidpar lt 1 then nk_get_kidpar_ref, scan_num, day, info, kidpar_file, scan=scan_list[0]

;; 1./ Define positions of the FOV to be mapped
;;______________________________________________________________________
;; mapping the FoV in concentric circles spaced of STEP until a
;; maximum radius of RCMAX
step = 70                       ; arcsec
rcmax = 250
;; All kids around (x_center,y_center) with a radius of RMAX will be
;; taken to produce the map. All the others are not projected
rmax = 40.

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


;; plot showing the centers
;;-----------------------------------------------------------------------------------------------
kp = mrdfits(kidpar_file, 1)
phi    = dindgen(100)/99.*2*!dpi
cosphi = cos(phi)
sinphi = sin(phi)
iarray=1
;; setting the plot
;; png=0
;; ps=0
;; ps_xsize    = 16         ;; in cm
;; ps_ysize    = 12         ;; in cm
;; ps_charsize = 1.
;; ps_yoffset  = 0.
;; ps_thick    = 2.
wind, 1, 1, /free, xsize=700, ysize=550
outplot, file='plot_fov_mapping_centers', png=png, ps=ps, xsize=ps_xsize, ysize=ps_ysize, charsize=ps_charsize, yoffset=ps_yoffset, thick=ps_thick
w1 = where( kp.type eq 1 and kp.array eq iarray, nw1)
xra = minmax( [kp[w1].nas_x, kp[w1].nas_y])
xra = xra + [-1,1]*0.2*(xra[1]-xra[0])
yra = xra
plot, kp[w1].nas_x, kp[w1].nas_y, $
      /iso, $
      xtitle='Nasmyth offset x', ytitle='Nasmyth offset y', xra=xra, yra=yra, /xs, /ys, /nodata, charsize=1
oplot, kp[w1].nas_x, kp[w1].nas_y, psym=1, col=50, symsize=0.8, thick=1.5

ncenter = n_elements(x_center_list)
a = rmax
b = rmax
theta = 0. 
for i=0, ncenter-1 do oplot, x_center_list[i] + a*cosphi, $
                             y_center_list[i]+ sinphi*b, col=250, thick=1.5
oplot, x_center_list, y_center_list, col=250, psym=8, symsize=0.8, thick=1.5
legendastro,['kid position','centers for focus fits'],col=[50,250], psym=[1, 8], textcolor=[50, 250], /left,/top,/trad

png = 'plot_fov_mapping_centers_'+strtrim(scan_list[0],2)+'.png'
if savepng gt 0 then WRITE_PNG, png, TVRD(/TRUE)
;;outplot, /close
;;-----------------------------------------

print, "%%%%%%%%%"
print, ''
print, 'the focus will be fitted around ',strtrim(string(ncenter),2) , " centers across the FoV (shown as red dots)"
print, ''
if project_maps gt 0 then begin
   print, ".c to continue if the FoV coverage for focus fits is convenient"
   print, "otherwise edit the script file and change settings ligne 52"
   print, ''
   stop
endif


;;  
;;
;;       process the data
;;
;;___________________________________________________________________________
if process eq 1 then begin
   print, "%%%%%%%%%"
   print, ''
   print, 'TOI processing...'
   ;; process the data if it has not been done already

   if parallel lt 1 then begin
      for iscan=0, n_elements(scan_list)-1 do begin
         scan = scan_list[iscan]
         print, ' reduction of the scan ',strtrim(scan,2)
         print, ''
         data_file_save = project_dir+'/defocus_beammap_'+strtrim(scan,2)+'.save'

         if file_test(data_file_save) lt 1 or reprocess eq 1 then begin 
            
            nk_default_param, param
            param.do_opacity_correction = do_opacity_correction
            param.force_kidpar          = force_kidpar
            param.file_kidpar           = kidpar_file
            nk_default_info, info
            nk_init_grid, param, info, grid
            
            
            param.project_dir = project_dir
            param.plot_dir    = param.project_dir+"/Plots"
            
            param.do_plot = 0
            
            param.decor_cm_dmin = 90. ; to avoid picking secondary lobes up
            param.interpol_common_mode = 1
            param.map_proj = "NASMYTH"
            spawn, "mkdir -p "+param.project_dir
            spawn, "mkdir -p "+param.project_dir+"/UP_files"
            spawn, "mkdir -p "+param.project_dir+"/Plots"
            ;;spawn, "mkdir -p "+param.plot_dir
            spawn, "mkdir -p "+param.preproc_dir
            
            random_string = strtrim( long( abs( randomu( seed, 1)*1e8)),2)
            error_report_file = param.project_dir+"/error_report_"+random_string+".dat"
            
            nk_update_param_info, scan, param, info, xml=xml, katana=katana, raw_acq_dir=raw_acq_dir
            param.cpu_date0             = systime(0, /sec)
            param.cpu_time_summary_file = param.output_dir+"/cpu_time_summary_file.dat"
            param.cpu_date_file         = param.output_dir+"/cpu_date.dat"
            spawn, "rm -f "+param.cpu_time_summary_file
            spawn, "rm -f "+param.cpu_date_file
            info.error_report_file = error_report_file
            
            nk_scan_preproc, param, info, data, kidpar, grid
            
            data_copy = data
            nk_scan_reduce, param, info, data, kidpar, grid
            
            info.result_total_obs_time = n_elements(data)/!nika.f_sampling
            w1 = where( kidpar.type eq 1, nw1)
            ikid = w1[0]
            junk = nk_where_flag( data.flag[ikid], [8,11], ncompl=ncompl)
            info.result_valid_obs_time = ncompl/!nika.f_sampling
            
            print, ' saving the results in ',strtrim(data_file_save,2)
            print, ''
            save, param, info, data, kidpar, grid, file=data_file_save
         endif else print, "already processed scan: ", scan
      endfor
   endif else begin    
      nk_default_param, param
      param.project_dir = project_dir
      spawn, "mkdir -p "+project_dir
      spawn, "mkdir -p "+project_dir+"/UP_files"
      spawn, "mkdir -p "+project_dir+"/Plots"
      spawn, "mkdir -p "+param.preproc_dir
      plot_dir = param.project_dir+"/Plots"
      force_process = reprocess
      
      nscans = n_elements(scan_list)
      nsplit = nscans
      
      split_for, 0, nscans-1, nsplit=nsplit, $
                 commands=['fov_focus_process_sub, i, scan_list, do_opacity_correction=do_opacity_correction, '+$
                           'force_kidpar=force_kidpar, kidpar_file=kidpar_file, '+$
                           'project_dir=project_dir, plot_dir=plot_dir, force_process=force_process'], $
                 varnames = ['scan_list', 'do_opacity_correction', 'force_kidpar', 'kidpar_file', $
                             'project_dir', 'plot_dir', 'force_process']
      
   endelse
endif

;;
;; 
;; 
;;         Map making around each centers
;;
;;___________________________________________________________________________
if project_maps eq 1 then begin
   print, "%%%%%%%%%"
   print, ''
   print, 'Map making...'
   ;; Projects the data around each position (x_center_list[ix],
   ;; y_center_list[iy])
   ncenter = n_elements(x_center_list)
   ny = ceil(ncenter/2.)
   nx = floor(ncenter/2.)
   
   for iscan=0, n_elements(scan_list)-1 do begin
      scan = scan_list[iscan]
      print, ' projecting data onto small maps for scan ',strtrim(scan,2)
      print, ''
      data_file_save = project_dir+'/defocus_beammap_'+strtrim(scan,2)+'.save'
      print, ' reading cleaned TOI file ',strtrim(data_file_save,2)
      print, ''
      restore, data_file_save
      
      kidpar_ref = kidpar
      
      my_multiplot, nx, ny, pp, pp1, $
                    /rev, gap_x=0.05, xmargin=0.05
      
      for ic=0, ncenter-1 do begin
         print, "icenter/ncenter = ", strtrim(string(ic),2),'/',strtrim(string(ncenter),2)
         output_dir = project_dir+"/fov_focus_"+strtrim(ic,2)+"/v_1/"+scan
         file_save = output_dir+"/results.save"
         
         kidpar = kidpar_ref    ; restore original kidpar
         
         kid_dist = sqrt( (kidpar.nas_x-x_center_list[ic])^2 + (kidpar.nas_y-y_center_list[ic])^2)
         w = where( kid_dist gt rmax, nw)
         if nw ne 0 then kidpar[w].type = 3
         
         nk_projection_4, param, info, data, kidpar, grid
         param1  = param
         info1   = info
         kidpar1 = kidpar
         grid1   = grid
            
         spawn, "mkdir -p "+output_dir
         save, param1, info1, kidpar1, grid1, file=file_save
      endfor
   endfor
endif

;;stop


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
   restore, project_dir+"/fov_focus_0/v_1/"+scan_list[0]+"/results.save", /v

   flux_focus   = dblarr(3, ncenter) + !values.d_nan ; 3 arrays, ncenter points
   fwhm_focus   = dblarr(3, ncenter) + !values.d_nan
   ellipt_focus = dblarr(3, ncenter) + !values.d_nan

   noplot = 1
   if show_focus_plot gt 0 then noplot = 0


   ;; param
   nk_default_param, param
   param.do_opacity_correction = do_opacity_correction
   param.force_kidpar          = force_kidpar
   param.file_kidpar           = kidpar_file
   param.project_dir = project_dir
   param.plot_dir    = param.project_dir+"/Plots"
   param.do_plot = 0
   param.decor_cm_dmin = 90.    ; to avoid picking secondary lobes up
   param.interpol_common_mode = 1
   param.map_proj = "NASMYTH"
   
   for ic=0, ncenter-1 do begin
   
      print, "icenter/ncenter = ", strtrim(string(ic),2),'/',strtrim(string(ncenter),2)
      if focus_time_drift gt 0 then begin
         nk_focus_otf_2, scan_list, scan_list_before, scan_list_after, $
                         output_root_dir=project_dir+"/fov_focus_"+strtrim(ic,2), param=param, $
                         focus_res=focus_res, cp1_all=cp1_all, cp2_all=cp2_all, cp3_all=cp3_all, $
                         noplot=noplot, debuging=0, delta_focus_byhand=delta_focus_byhand 
      endif else begin
         nk_focus_otf, scan_list, $
                       output_root_dir=project_dir+"/fov_focus_"+strtrim(ic,2), param=param, $
                       focus_res=focus_res, cp1_all=cp1_all, cp2_all=cp2_all, cp3_all=cp3_all, $
                       noplot=noplot, get_focus_error=focus_error_rescaling
      endelse
         
      if show_focus_plot gt 0 then begin
         ans = ''
         print, "on continue ?"
         read, ans
      endif
      
      for iarray=1,3 do begin
         if cp1_all[iarray-1,2] lt 0. then $
            flux_focus[*, ic] = focus_res[*,0]
         if cp2_all[iarray-1,2] gt 0. then $
            fwhm_focus[*, ic] = focus_res[*,1]
         if cp3_all[iarray-1,2] gt 0. then $
         ellipt_focus[*, ic] = focus_res[*,2]
      endfor
     endfor
     
   ofile_rootname = 'fov_focus_'+strtrim(scan_list[0],2)
   if focus_time_drift gt 0 then ofile_rootname = ofile_rootname+'_zdrift'
   if focus_error_rescaling gt 0 then ofile_rootname = ofile_rootname+'_sigma_rescaled'

   focus_output_file = ofile_rootname+'.save'
   print, ' saving the results in ',strtrim(focus_output_file,2)
   print, ''
   save, flux_focus, fwhm_focus, ellipt_focus, file=focus_output_file
endif


print, "%%%%%%%%%"
print, ''
print, 'Plotting results...'
print, ''
print, ".c to do the plots"
stop


;;  
;;        Plotting
;; 
;;_______________________________________________________________
;; Summary plot (or even better map of the results)

suffixe = ''
if focus_time_drift gt 0 then suffixe = "_zdrift"
if focus_error_rescaling gt 0 then suffixe = suffixe+'_sigma_rescaled'

focus_output_file = 'fov_focus_'+strtrim(scan_list[0],2)+suffixe+'.save'


restore, focus_output_file
;;restore, "fov_focus_witherror_"+strtrim(scan_list[0],2)+".save"

xx = x_center_list
yy = y_center_list
npts = n_elements(xx)

;; Compute relative values to the focus at the center of the FOV
w0 = where( xx eq 0 and yy eq 0)
w = where( flux_focus[*,w0] ne 0, nw) & print,nw
flux_focus_0   = flux_focus[*,w0]
fwhm_focus_0   = fwhm_focus[*,w0]
ellipt_focus_0 = ellipt_focus[*,w0]

phi    = dindgen(1000)/999.*2*!dpi
cosphi = cos(phi)
sinphi = sin(phi)
r = [70., 140., 200.]


print, "%%%%%%%%%"
print, ''
print, 'First series of plot: discrete FoV mapping'
print, ''

zra = [-0.5,0.5]
;; png=0
;; ps=1
;; ps_xsize    = 22.        ;; in cm
;; ps_ysize    = 11.         ;; in cm
;; ps_charsize = 1.
;; ps_yoffset  = 0.
;; ps_thick    = 2.
wind, 1, 1, /free, xsize=1200, ysize=600
;;outplot, file='plot_fov_mapping_discret', png=png, ps=ps, xsize=ps_xsize, ysize=ps_ysize, charsize=ps_charsize, yoffset=ps_yoffset, thick=ps_thick
my_multiplot, 3, 2, pp, pp1, ymargin=0.08, gap_x=0.08, xmargin = 0.06
charsize = 1.2
xra = minmax(x_center_list)
xra = xra + [-1,1]*0.2*(xra[1]-xra[0])
yra = minmax(y_center_list)
yra = yra + [-1,1]*0.2*(yra[1]-yra[0])
order = [1, 3, 2]
for ilam=0, 2 do begin
   iarray = order[ilam]
   
   z = reform(flux_focus[iarray-1,*],npts) - flux_focus_0[iarray-1]
   w = where( z ne 0, nw)
   matrix_plot, xx[w], yy[w], z[w], $
                position=pp[ilam,0,*], title='Flux focus A'+strtrim(iarray,2), /noerase, $
                charsize=charsize, xra=xra, yra=yra, zra=disc_zra, format='(f6.2)',/iso, symsize=2.
   oplot, kp[w1].nas_x, kp[w1].nas_y, psym=3, col=0, symsize=0.5, thick=1
   for ir = 0, 2 do oplot, r[ir]*cosphi, r[ir]*sinphi, col=0, thick=1.
   print, "Array ", iarray
   ;;print, z
   wmax = where(abs(z) eq max(abs(z)), nmax)
   print, "max = ", z(wmax), " pour ", xx(wmax),', ',yy(wmax)
   ;;xyouts, xx[wmax]-30, yy[wmax] + 8., $
   ;;        strtrim(string(z(wmax), format='(f6.2)'),2), chars=charsize, col=0
   xyouts, xx[wmax]-30, yy[wmax] + 10., $
           strtrim(string(z(wmax), format='(f6.2)'),2), chars=charsize, col=0
   z = reform(fwhm_focus[iarray-1,*],npts) - fwhm_focus_0[iarray-1]
   matrix_plot, xx[w], yy[w], z[w], $
                position=pp[ilam,1,*], title='FWHM focus A'+strtrim(iarray,2), /noerase, $
                charsize=charsize, xra=xra, yra=yra, zra=disc_zra, format='(f6.2)', /iso, symsize=2.
   oplot, kp[w1].nas_x, kp[w1].nas_y, psym=3, col=0, symsize=0.5, thick=2
   for ir = 0, 2 do oplot, r[ir]*cosphi, r[ir]*sinphi, col=0, thick=1.
   ;;z = reform(ellipt_focus[iarray-1,*],npts) - ellipt_focus_0[iarray-1]
   ;;matrix_plot, xx[w], yy[w], z[w], $
   ;;             position=pp[iarray-1,2,*], title='ELLIPT focus A'+strtrim(iarray,2), /noerase, $
   ;;             charsize=charsize, xra=xra, yra=yra, zra=zra,
   ;;             format='(f6.2)'
   ;;print, z
   wmax = where(abs(z) eq max(abs(z)), nmax)
   print, "max = ", z(wmax), " pour ", xx(wmax),', ',yy(wmax)
   ;;xyouts, xx[wmax]-30, yy[wmax] + 8., $
   ;;             strtrim(string(z(wmax), format='(f6.2)'),2),
   ;;             chars=charsize, col=0
   xyouts, xx[wmax]-30, yy[wmax] + 10., $
                strtrim(string(z(wmax), format='(f6.2)'),2), chars=charsize, col=0
endfor

;;outplot, /close
png = 'plot_fov_mapping_discrete_'+strtrim(scan_list[0],2)+suffixe+'.png'
 if savepng gt 0 then WRITE_PNG, png, TVRD(/TRUE)

;; ratio
zra = [-0.5, 0.5]
wind, 1, 1, /free, xsize=800, ysize=400
;wind, 1, 1, /free, xsize=1200, ysize=400
;my_multiplot, 3, 1, pp, pp1
charsize = 1.2
xra = minmax(x_center_list)
xra = xra + [-1,1]*0.2*(xra[1]-xra[0])
yra = minmax(y_center_list)
yra = yra + [-1,1]*0.2*(yra[1]-yra[0])
order = [1, 3, 2]
tab_col = [50, 80, 250]
plot, x_center_list*0.+1., yr=[-0.5, 2.5], /ys, title='Flux to FWHM focus ratio', ytitle='Z_Flux / Z_FWHM', xtitle='FoV points (running index)', charsize=charsize
for ilam=0, 2 do begin
   iarray = order[ilam]
   z_flux = reform(flux_focus[iarray-1,*],npts) - flux_focus_0[iarray-1]
   z_fwhm = reform(fwhm_focus[iarray-1,*],npts) - fwhm_focus_0[iarray-1]
   oplot, z_flux/z_fwhm, col=tab_col[ilam]
   ;; w_fwhm = where(z_fwhm ne 0)
   ;; z = z_flux*0.
   ;; z[w_fwhm] = 2.*(z_flux[w_fwhm]-z_fwhm[w_fwhm])/(z_flux[w_fwhm]+z_fwhm[w_fwhm])
   ;; matrix_plot, xx, yy, z, $
   ;;              position=pp[ilam,0,*], title='Rel. Diff. Flux-FWHM focus A'+strtrim(iarray,2), /noerase, $
   ;;              charsize=charsize, xra=xra, yra=yra, zra=zra, format='(f6.2)', symsize=1.3, /iso

endfor
legendastro, ['A1', 'A3', 'A2'], col=tab_col, box=0, /trad, textcol=tab_col, /top, /center, charsize=charsize
;;png = 'plot_fov_mapping_relative_difference_flux_fwhm.png'
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

