

;; Script to monitor the flux of source vs time, azimuth, elevation,
;; opacity
;;
;; This script takes result from reduce_all_n2r9 (see the project_dir
;; definition in there).
;;--------------------------------------------------------------------------

pro flux_monitoring, scan_list, project_dir, flux_res, err_flux_res, elevation, tau_res, $
                     png=png, ps=ps, output_plot_dir=output_plot_dir

;; I leave these two guys hardcode here, see reduce_all_n2r9
run = 'N2R9'

if not keyword_set(output_plot_dir) then output_plot_dir = "."
spawn, "mkdir -p output_plot_dir"

nscans = n_elements(scan_list)

;; Retrieve results
elevation    = dblarr(nscans)
tau_res      = dblarr(3,nscans)
flux_res     = dblarr(3,3,nscans)
fwhm_res     = dblarr(3,nscans)
err_flux_res = dblarr(3,3,nscans)
flux_method = ['FixedFWHM', 'ApPhot', 'FreeFWHM']
for iscan=0, nscans-1 do begin
   file = project_dir+"/v_1/"+scan_list[iscan]+"/photometry.csv"
   if file_test(file) then begin
      nk_read_csv, file, str
      ;; fixed fwhm gauss flux
      flux_res[0,0,iscan]     = str.flux_I1
      flux_res[0,1,iscan]     = str.flux_I2
      flux_res[0,2,iscan]     = str.flux_I3
      err_flux_res[0,0,iscan] = str.err_flux_I1
      err_flux_res[0,1,iscan] = str.err_flux_I2
      err_flux_res[0,2,iscan] = str.err_flux_I3

      flux_res[1,0,iscan]     = str.aperture_photometry_I1
      flux_res[1,1,iscan]     = str.aperture_photometry_I2
      flux_res[1,2,iscan]     = str.aperture_photometry_I3
      err_flux_res[1,0,iscan] = str.err_aperture_photometry_I1
      err_flux_res[1,1,iscan] = str.err_aperture_photometry_I2
      err_flux_res[1,2,iscan] = str.err_aperture_photometry_I3

      flux_res[2,0,iscan]     = str.peak_1
      flux_res[2,1,iscan]     = str.peak_2
      flux_res[2,2,iscan]     = str.peak_3
;   err_beam_flux_res[0,iscan] = str.err_peak_1
;   err_beam_flux_res[1,iscan] = str.err_peak_2
;   err_beam_flux_res[2,iscan] = str.err_peak_3

      fwhm_res[0,iscan] = str.fwhm_1
      fwhm_res[1,iscan] = str.fwhm_2
      fwhm_res[2,iscan] = str.fwhm_3
      
      elevation[iscan] = str.elevation_deg
      tau_res[0,iscan] = str.tau_1mm
      tau_res[1,iscan] = str.tau_2mm
      tau_res[2,iscan] = str.tau_1mm
   endif
   ;; to get info1
   if iscan eq 0 then restore, project_dir+"/v_1/"+scan_list[iscan]+"/results.save"
endfor

ct = [70, 250, 40]
psym_array = [4,8,1]
thick_array = [2,1,2]
;; Plot results
for iflux=0, 2 do begin
   wind, 1, 1, /free, /large
   outplot, file=output_plot_dir+'/flux_monitoring_'+strtrim(str_replace(info1.object," ", "_"),2)+"_"+flux_method[iflux], png=png, ps=ps
   my_multiplot, 1, 3, pp, pp1, /rev, ymargin=0.07, gap_y=0.1
   plot, flux_res[iflux,0,*], yra=[0, max(flux_res)]*2, /ys, $
         position=pp1[0,*], /nodata, xtitle='scan index', title=flux_method[iflux], xra=[-1, nscans], /xs
   xyouts, indgen(nscans), avg(flux_res[iflux,0,*]), strmid(scan_list,5), orient=90, chars=0.7
   for iarray=1,3 do begin
      oplot, flux_res[iflux,iarray-1,*], thick=thick_array[iarray-1], psym=psym_array[iarray-1], col=ct[iarray-1]
      oplot, [-1,nscans], [1,1]*avg(flux_res[iflux,iarray-1,*]), col=ct[iarray-1]
   endfor
   legendastro, ['A1: '+string( avg(flux_res[iflux,0,*]),form='(F5.2)')+" +- "+string( stddev( flux_res[iflux,0,*]),form='(F5.2)'), $
                 'A2: '+string( avg(flux_res[iflux,1,*]),form='(F5.2)')+" +- "+string( stddev( flux_res[iflux,1,*]),form='(F5.2)'), $
                 'A3: '+string( avg(flux_res[iflux,2,*]),form='(F5.2)')+" +- "+string( stddev( flux_res[iflux,2,*]),form='(F5.2)')], $
                textcol=ct, psym=[1,8,4], col=ct
   legendastro, [info1.object], box=0, /right
   plot, elevation, flux_res[iflux,0,*], yra=[0, max(flux_res)]*1.2, /ys, $
         position=pp1[1,*], /noerase, xtitle='Elevation', /nodata, title=flux_method[iflux]
   for iarray=1,3 do begin
      oplot, elevation, flux_res[iflux,iarray-1,*], thick=thick_array[iarray-1], psym=psym_array[iarray-1], col=ct[iarray-1]
      oplot, [-1,100], [1,1]*avg(flux_res[iflux,iarray-1,*]), col=ct[iarray-1]
   endfor
   legendastro, ['A1: '+string( avg(flux_res[iflux,0,*]),form='(F5.2)')+" +- "+string( stddev( flux_res[iflux,0,*]),form='(F5.2)'), $
                 'A2: '+string( avg(flux_res[iflux,1,*]),form='(F5.2)')+" +- "+string( stddev( flux_res[iflux,1,*]),form='(F5.2)'), $
                 'A3: '+string( avg(flux_res[iflux,2,*]),form='(F5.2)')+" +- "+string( stddev( flux_res[iflux,2,*]),form='(F5.2)')], $
                textcol=ct, psym=[1,8,4], col=ct
   legendastro, [info1.object], box=0, /right
   
   plot, tau_res[0,*], flux_res[iflux,0,*], yra=[0, max(flux_res)]*1.2, /ys, $
         position=pp1[2,*], /noerase, xtitle='Tau', /nodata, xra=minmax(tau_res), /xs
   oplot, tau_res[0,*], flux_res[iflux,0,*], thick=thick_array[0], psym=psym_array[0], col=ct[0]
   oplot, tau_res[2,*], flux_res[iflux,2,*], thick=thick_array[2], psym=psym_array[2], col=ct[2]
   oplot, tau_res[1,*], flux_res[iflux,1,*], thick=thick_array[1], psym=psym_array[1], col=ct[1]
   for iarray=1,3 do begin
      oplot, [-1,100], [1,1]*avg(flux_res[iflux,iarray-1,*]), col=ct[iarray-1]
   endfor
   legendastro, ['A1: '+string( avg(flux_res[iflux,0,*]),form='(F5.2)')+" +- "+string( stddev( flux_res[iflux,0,*]),form='(F5.2)'), $
                 'A2: '+string( avg(flux_res[iflux,1,*]),form='(F5.2)')+" +- "+string( stddev( flux_res[iflux,1,*]),form='(F5.2)'), $
                 'A3: '+string( avg(flux_res[iflux,2,*]),form='(F5.2)')+" +- "+string( stddev( flux_res[iflux,2,*]),form='(F5.2)')], $
                textcol=ct, psym=[1,8,4], col=ct
   legendastro, [info1.object], box=0, /right
   my_multiplot, /reset
   outplot, /close
endfor

iflux = 0
wind, 1, 1, /free, /large
outplot, file=output_plot_dir+'/RelatFlux_vs_elev_'+strtrim(str_replace(info1.object," ", "_"),2)+"_"+flux_method[iflux], png=png, ps=ps
plot, elevation, flux_res[iflux,0,*]/avg(flux_res[iflux,0,*]), $
      yra=[0.5, 1.5], /ys, $
      xtitle='Elevation', ytitle='Relative flux', title=flux_method[iflux], /nodata
for iarray=1,3 do begin
   oplot, elevation, flux_res[iflux,iarray-1,*]/avg(flux_res[iflux,iarray-1,*]), $
          thick=thick_array[iarray-1], psym=psym_array[iarray-1], col=ct[iarray-1]
   oplot, [-1,100], [1,1], col=ct[iarray-1]
endfor
legendastro, ['A1', $
              'A2', $
              'A3'], $
             textcol=ct, psym=[1,8,4], col=ct
legendastro, [info1.object], box=0, /right
outplot, /close

;; stop
;; 
;; ;; Aperture phot
;; wind, 1, 1, /free, /large
;; outplot, file=output_plot_dir+'/aphot_flux_monitoring_'+strtrim(info1.object,2), png=png, ps=ps
;; my_multiplot, 1, 3, pp, pp1, /rev, ymargin=0.07, gap_y=0.07
;; plot, aphot_flux_res[0,*], yra=[0, max(aphot_flux_res)]*2, /ys, $
;;       position=pp1[0,*], /nodata, xtitle='scan index', title='Aphot flux', xra=[-1, nscans], /xs
;; xyouts, indgen(nscans), avg( aphot_flux_res[0,*]), strmid(scan_list,5), orient=90, chars=0.7
;; for iarray=1,3 do oplot, aphot_flux_res[iarray-1,*], thick=thick_array[iarray-1], psym=psym_array[iarray-1], col=ct[iarray-1]
;; legendastro, ['A1', 'A2', 'A3'], $
;;              textcol=ct, psym=[1,8,4], col=ct
;; legendastro, [info1.object], box=0, /right
;; 
;; plot, elevation, aphot_flux_res[0,*], yra=[0, max(aphot_flux_res)]*2, /ys, $
;;       position=pp1[1,*], /noerase, xtitle='Elevation', /nodata, title='Aphot flux'
;; for iarray=1,3 do oplot, elevation, aphot_flux_res[iarray-1,*], thick=thick_array[iarray-1], psym=psym_array[iarray-1], col=ct[iarray-1]
;; legendastro, ['A1', 'A2', 'A3'], $
;;              textcol=ct, psym=[1,8,4], col=ct
;; legendastro, [info1.object], box=0, /right
;; 
;; plot, tau_res[0,*], aphot_flux_res[0,*], yra=[0, max(aphot_flux_res)]*2, /ys, $
;;       position=pp1[2,*], /noerase, xtitle='Tau', /nodata, xra=minmax(tau_res), /xs
;; oplot, tau_res[0,*], aphot_flux_res[0,*], thick=thick_array[0], psym=psym_array[0], col=ct[0]
;; oplot, tau_res[2,*], aphot_flux_res[2,*], thick=thick_array[2], psym=psym_array[2], col=ct[2]
;; oplot, tau_res[1,*], aphot_flux_res[1,*], thick=thick_array[1], psym=psym_array[1], col=ct[1]
;; legendastro, ['A1', 'A2', 'A3'], $
;;              textcol=ct, psym=[1,8,4], col=ct
;; legendastro, [info1.object], box=0, /right
;; my_multiplot, /reset
;; outplot, /close
;; 
;; ;; Gauss phot with free fwhm
;; wind, 1, 1, /free, /large
;; outplot, file=output_plot_dir+'/beam_flux_monitoring_'+strtrim(info1.object,2), png=png, ps=ps
;; my_multiplot, 1, 3, pp, pp1, /rev, ymargin=0.07, gap_y=0.07
;; plot, beam_flux_res[0,*], yra=[0, max(beam_flux_res)]*2, /ys, $
;;       position=pp1[0,*], /nodata, xtitle='scan index', title='Beam flux', xra=[-1, nscans], /xs
;; xyouts, indgen(nscans), avg(beam_flux_res[0,*]), strmid(scan_list,5), orient=90, chars=0.7
;; for iarray=1,3 do oplot, beam_flux_res[iarray-1,*], thick=thick_array[iarray-1], psym=psym_array[iarray-1], col=ct[iarray-1]
;; legendastro, ['A1', 'A2', 'A3'], $
;;              textcol=ct, psym=[1,8,4], col=ct
;; legendastro, [info1.object], box=0, /right
;; 
;; plot, elevation, beam_flux_res[0,*], yra=[0, max(beam_flux_res)]*2, /ys, $
;;       position=pp1[1,*], /noerase, xtitle='Elevation', /nodata, title='Beam flux'
;; for iarray=1,3 do oplot, elevation, beam_flux_res[iarray-1,*], thick=thick_array[iarray-1], psym=psym_array[iarray-1], col=ct[iarray-1]
;; legendastro, ['A1', 'A2', 'A3'], $
;;              textcol=ct, psym=[1,8,4], col=ct
;; legendastro, [info1.object], box=0, /right
;; 
;; plot, tau_res[0,*], beam_flux_res[0,*], yra=[0, max(beam_flux_res)]*2, /ys, $
;;       position=pp1[2,*], /noerase, xtitle='Tau', /nodata, xra=minmax(tau_res), /xs
;; oplot, tau_res[0,*], beam_flux_res[0,*], thick=thick_array[0], psym=psym_array[0], col=ct[0]
;; oplot, tau_res[2,*], beam_flux_res[2,*], thick=thick_array[2], psym=psym_array[2], col=ct[2]
;; oplot, tau_res[1,*], beam_flux_res[1,*], thick=thick_array[1], psym=psym_array[1], col=ct[1]
;; legendastro, ['A1', 'A2', 'A3'], $
;;              textcol=ct, psym=[1,8,4], col=ct
;; legendastro, [info1.object], box=0, /right
;; my_multiplot, /reset
;; outplot, /close

print, "A3/A1 (gauss phot): "+strtrim( avg( flux_res[0,2,*]/flux_res[0,1,*]))
print, "A3/A1 (Ap. phot): "+strtrim( avg( flux_res[1,2,*]/flux_res[1,1,*]))
print, "A3/A1 (Free fwhm phot): "+strtrim( avg( flux_res[2,2,*]/flux_res[2,1,*]))



end
