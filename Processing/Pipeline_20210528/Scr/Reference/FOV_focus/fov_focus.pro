
;; demonstration script to map the focus accross the entire FOV with a
;; sequence of OTF maps taken at different focus
;;----------------------------------------------------------------------

;; Sequence of scans produced by fov_focus.pako
;scan_list = '20160925s'+strtrim(473+indgen(9),2)
scan_list = '20161006s'+strtrim(59+indgen(9),2)

;; Define positions of the FOV to be mapped
step = 50                                       ; arcsec
xmax = 150                                      ; 250. ; 200.
x_center_list = dindgen( round(xmax/step))*step ; ensure we start by 0.
x_center_list = [-reverse(x_center_list[1:*]), x_center_list]
y_center_list = x_center_list
;; All kids around (x_center,y_center) with a radius of rmax will be
;; taken to produce the map. All the others are not projected
rmax = 40.

;; LP added
process      = 1
project_maps = 0
fit_focus    = 0
project_dir  = getenv('HOME')+'/NIKA/Plots/Run18/FOV_focus'

if process eq 1 then begin
   ;; process the data is it has not been done already
   for iscan=0, n_elements(scan_list)-1 do begin
      scan = scan_list[iscan]
      data_file_save = project_dir+'/fov_focus_data_'+strtrim(scan,2)+'.save'

      nk_default_param, param
      param.do_opacity_correction = 0
      nk_default_info, info
      nk_init_grid, param, info, grid

      ;; LP added:
      param.project_dir = project_dir
      param.plot_dir    = param.project_dir+"/Plots"
      
      param.do_plot = 0

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

      save, param, info, data, kidpar, grid, file=data_file_save
   endfor
endif

if project_maps eq 1 then begin
   ;; Projects the data around each position (x_center_list[ix], y_center_list[iy])
   for iscan=0, n_elements(scan_list)-1 do begin
      scan = scan_list[iscan]
      data_file_save = project_dir+'/fov_focus_data_'+strtrim(scan,2)+'.save'
      restore, data_file_save
      
      kidpar_ref = kidpar

      my_multiplot, n_elements(x_center_list), n_elements(x_center_list), pp, pp1, $
                    /rev, gap_x=0.05, xmargin=0.05
      p = 0
      for ix=0, n_elements(x_center_list)-1 do begin
         for iy=0, n_elements(y_center_list)-1 do begin
            ;; print, "ix, iy: ", ix, iy
            output_dir = project_dir+"/fov_focus_"+strtrim(ix,2)+"_"+strtrim(iy,2)+"/v_1/"+scan
            file_save = output_dir+"/results.save"

            kidpar = kidpar_ref ; restore original kidpar
            
            kid_dist = sqrt( (kidpar.nas_x-x_center_list[ix])^2 + (kidpar.nas_y-y_center_list[iy])^2)
            w = where( kid_dist gt rmax, nw)
            if nw ne 0 then kidpar[w].type = 3

            nk_projection_4, param, info, data, kidpar, grid
            param1  = param
            info1   = info
            kidpar1 = kidpar
            grid1   = grid
            
            spawn, "mkdir -p "+output_dir
            save, param1, info1, kidpar1, grid1, file=file_save
            p++
         endfor
      endfor
   endfor
endif

nx = n_elements(x_center_list)
ny = n_elements(y_center_list)

if fit_focus eq 1 then begin
;; when all scans are processed
;; retrieve param1.map_reso
   restore, project_dir+"/fov_focus_0_0/v_1/"+scan_list[0]+"/results.save"

   flux_focus   = dblarr(3, 3, nx, ny) + !values.d_nan ; 3 sequences, 3 arrays
   fwhm_focus   = dblarr(3, 3, nx, ny) + !values.d_nan
   ellipt_focus = dblarr(3, 3, nx, ny) + !values.d_nan

   fwhm = 12.d0
   sigma = fwhm*!fwhm2sigma
   r_thres = 3.d0*sigma
   ;; hard to define a stringent criterion on npix_thres
   ;; to decide if the current position was mapped during a particular
   ;; scan of the sequence
   npix_thres = 0.8*long( 2*!dpi*(2*sigma)^2/param1.map_reso^2)

   ;; There are 3 sequences of "focus-otf", each sequence maps only
   ;; about 1/3 of the FOV
   for iseq=0, 2 do begin
      scan_list_1 = scan_list[iseq*3:(iseq+1)*3-1]

      for ix=0, nx-1 do begin
         for iy=0, ny-1 do begin
            
            ;; Not all scans map the position (x_center_list[ix],
            ;; y_center_list[iy]), need to select them.
            keep = [-1]
            for iscan=0, n_elements(scan_list_1)-1 do begin
               restore, project_dir+"/fov_focus_"+strtrim(ix,2)+"_"+strtrim(iy,2)+"/v_1/"+scan_list_1[iscan]+"/results.save"
               ;; the source is projected at the center of the map, not
               ;; around (xc,yc) :)
               d = sqrt( grid1.xmap^2 + grid1.ymap^2)
               w = where( grid1.nhits_1 ne 0 and d le r_thres, nw)
               print, ix, iy, " ", scan_list[iscan], " ", nw
               if nw gt npix_thres then keep = [keep, iscan]
               ;; test
               w1=where(kidpar1.type eq 1 and kidpar1.array eq 1, n1)
               for ii=0, n1-1 do print,kidpar1[w1[ii]].nas_x,',',kidpar1[w1[ii]].nas_y
               dispim_bar,grid1.map_i1, cr=[0, 30], /aspect, /nocont
               stop
            endfor
            w = where(keep ne -1, nw)
            keep = keep[w]
            if nw eq 0 then begin
               message, /info, "position "+strtrim(x_center_list[ix],2)+", "+strtrim(y_center_list[iy],2)+" not covered"
            endif else begin
               scan_list_foc = scan_list_1[keep]

               wd, /a
               nk_focus_otf, scan_list_foc, output_root_dir="fov_focus_"+strtrim(ix,2)+"_"+strtrim(iy,2), $
                             focus_res=focus_res, cp1_all=cp1_all, cp2_all=cp2_all, cp3_all=cp3_all, noplot=noplot
               for iarray=1,3 do begin
                  if cp1_all[iarray-1,1] lt 0. then $
                     flux_focus[   iseq, *, ix, iy] = focus_res[*,0]
                  if cp2_all[iarray-1,1] lt 0 then $
                     fwhm_focus[   iseq, *, ix, iy] = focus_res[*,1]
                  ellipt_focus[ iseq, *, ix, iy] = focus_res[*,2]
               endfor
            endelse
;      stop
         endfor
      endfor
   endfor
   save, flux_focus, fwhm_focus, ellipt_focus, file='fov_focus.save'
endif

restore, "fov_focus.save"
;; Summary plot (or even better map of the reults)
xx = dblarr(nx,ny)
yy = dblarr(nx,ny)
npts = nx*ny
for ix=0,nx-1 do xx[ix,*] = x_center_list[ix]
for iy=0,ny-1 do yy[*,iy] = y_center_list[iy]
xx = reform(xx,npts)
yy = reform(yy,npts)

;; Compute relative values to the focus at the center of the FOV
wx = where( x_center_list eq 0)
wy = where( y_center_list eq 0)
w = where( flux_focus[*,0,wx,wy] ne 0,nw) & print,nw
flux_focus_0   = reform(flux_focus[  w,*,wx,wy], 3)
fwhm_focus_0   = reform(fwhm_focus[  w,*,wx,wy], 3)
ellipt_focus_0 = reform(ellipt_focus[w,*,wx,wy], 3)

zra = [-1,1]*0.2
for i=0, 2 do begin
   wind, 1, 1, /free, /large, title='Sequence #'+strtrim(i,2)
   my_multiplot, 3, 3, pp, pp1
   charsize = 0.6
   xra = minmax(x_center_list)
   xra = xra + [-1,1]*0.2*(xra[1]-xra[0])
   yra = minmax(y_center_list)
   yra = yra + [-1,1]*0.2*(yra[1]-yra[0])
   for iarray=1, 3 do begin
      z = reform(flux_focus[i,iarray-1,*,*],npts) - flux_focus_0[iarray-1]
      w = where( z ne 0, nw)
      matrix_plot, xx[w], yy[w], z[w], $
                   position=pp[iarray-1,0,*], title='Flux focus A'+strtrim(iarray,2), /noerase, $
                   charsize=charsize, xra=xra, yra=yra, zra=zra

      z = reform(fwhm_focus[i,iarray-1,*,*],npts) - fwhm_focus_0[iarray-1]
      matrix_plot, xx[w], yy[w], z[w], $
                   position=pp[iarray-1,1,*], title='FWHM focus A'+strtrim(iarray,2), /noerase, $
                   charsize=charsize, xra=xra, yra=yra, zra=zra

      z = reform(ellipt_focus[i,iarray-1,*,*],npts) - ellipt_focus_0[iarray-1]
      matrix_plot, xx[w], yy[w], z[w], $
                   position=pp[iarray-1,2,*], title='ELLIPT focus A'+strtrim(iarray,2), /noerase, $
                   charsize=charsize, xra=xra, yra=yra, zra=zra
   endfor
endfor

zra = [-1,1]*0.2
for iarray=1, 3 do begin
   wind, 1, 1, /free, /large, title='Sequence #'+strtrim(i,2)
   my_multiplot, 3, 3, pp, pp1
   charsize = 0.6
   xra = minmax(x_center_list)
   xra = xra + [-1,1]*0.2*(xra[1]-xra[0])
   yra = minmax(y_center_list)
   yra = yra + [-1,1]*0.2*(yra[1]-yra[0])
   for i=0, 2 do begin
      z = reform(flux_focus[i,iarray-1,*,*],nx,ny) - flux_focus_0[iarray-1]
      imview, z, position=pp[i,0,*], title='Flux focus A'+strtrim(iarray,2), /noerase, $
              charsize=charsize, xra=xra, yra=yra, imrange=zra

      z = reform(fwhm_focus[i,iarray-1,*,*],nx,ny) - fwhm_focus_0[iarray-1]
      imview, z, position=pp[i,1,*], title='FWHM focus A'+strtrim(iarray,2), /noerase, $
              charsize=charsize, xra=xra, yra=yra, imrange=zra

      z = reform(ellipt_focus[i,iarray-1,*,*],nx,ny) - ellipt_focus_0[iarray-1]
      imview, z, position=pp[i,2,*], title='ELLIPT focus A'+strtrim(iarray,2), /noerase, $
              charsize=charsize, xra=xra, yra=yra, imrange=zra
   endfor
endfor






end

