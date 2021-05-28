pro beam_per_kid_toi, scan, kidparfile, dir_plot


;kidparfile = !nika.off_proc_dir+ '/kidpar_20161213s102_v2.fits'
;scan = '20161213s102'
;scan = '20161212s268'
;scan = '20170124s186'
;scan = '20170125s223'  
nk_default_param, in_param
in_param.map_proj='AZEL'
in_param.force_kidpar = 1
in_param.file_kidpar = kidparfile
in_param.plot_ps = 1

;dir_plot = '/home/macias/NIKA/Plots/CheckTOIBeams/'

; reading data
nk_getdata, param, info, data, kidpar,scan = scan, in_param = in_param
nk_get_kid_pointing, param, info, data, kidpar

; do work per array

for iarray=1,3 do begin
   print, "working in array "+strtrim(iarray,2)
   lkid = where(kidpar.array eq iarray,nkid)
   detname = kidpar[lkid].name
   detnum  = kidpar[lkid].numdet
;plot, dindgen(100),dindgen(100), xr=[-50.0,50.0],yr=[0.0,1.1], /nodata
dra_arr = dindgen(121)-60.0
beam_arr = dblarr(nkid,121)
beam_norm = beam_arr
dramax = dblarr(nkid)
fluxmax = dblarr(nkid)

for idet=0,nkid-1 do begin
   toi = reform(data.toi[lkid[idet],*])
   toi -= median(toi, 30)
   lposra = where(abs(data.dra[lkid[idet],*]) lt 100.0 and abs(data.ddec[lkid[idet],*]) lt 2.0,nlposra)
;lposdec = where(abs(data.dra[lkid[idet],*]) lt 3.0 and abs(data.ddec[lkid[idet],*]) lt 100.0,nlposdec)
   if (nlposra gt  10) then begin
      toira = toi[lposra]
      dra = (data.dra)[lkid[idet],lposra]

      lra = where(abs(dra) gt  40,nlra)
      if nlra gt 10 then toira -= median(toira[lra])
      beam_arr[idet,*] = interpol(toira[sort(dra)],dra[sort(dra)],dra_arr)
      fluxmax[idet]= max(beam_arr[idet,*],nposmax)
      dramax[idet] = dra_arr[nposmax]
      beam_norm[idet,*] = beam_arr[idet,*]/fluxmax[idet]
   endif
endfor

;dispim_bar, beam_norm, /nocont,cr=[0.7,1.0],yr=[50,70]
okkids = where(abs(dramax) lt 20.0,nokkids)

window,0,xsize =1500,ysize=500
dispim_bar, beam_norm[okkids,*], /nocont,cr=[0.7,1.0],ymap =dindgen(120)-60.0, $
            title='Array '+strtrim(iarray,2),$
            xtitle='Detector ID [arbitrary units]',ytitle='Position offset [arcsec]',$
            yr=[-10,10]
WRITE_JPEG, dir_plot+ 'beam_pos_im_'+scan+'_arr_'+strtrim(iarray,2)+'.jpeg', TVRD(/TRUE), /TRUE

window,1
histo_make, dramax[okkids], n_bins = 10, /plot, xtitle='Position offset',ytitle='Number of detectors'
WRITE_JPEG, dir_plot+ 'beam_pos_hist_'+scan+'_arr_'+strtrim(iarray,2)+'.jpeg', TVRD(/TRUE), /TRUE

window,2
plot, dra_arr,dra_arr,xr=[-60,60], yr=[-0.1,1.1],/xs, /ys,/nodata, $
      xtitle='Distance [arcsec]',ytitle='Normalized flux', title='Array '+strtrim(iarray,2)
for idet=0,nokkids-1 do oplot,dra_arr, beam_norm[okkids[idet],*],col=50+long(dramax[okkids[idet]])*40
legendastro, 'Offset '+ strtrim(lindgen(5)-2,2)+ ' arcsec', col = 50+ (lindgen(5)-2)*40,psym= intarr(5)
WRITE_JPEG, dir_plot+ 'beam_centered_'+scan+'_arr_'+strtrim(iarray,2)+'.jpeg', TVRD(/TRUE), /TRUE

window,3
histo_make, fluxmax[okkids], n_bins = 20, /plot, xtitle='Flux [Hz]',ytitle='Number of detectors',title='A'+strtrim(iarray,2)
WRITE_JPEG, dir_plot+ 'beam_flux_hist_'+scan+'_arr_'+strtrim(iarray,2)+'.jpeg', TVRD(/TRUE), /TRUE

r = {da:dra_arr,beam:beam_arr,name:detname,num:detnum,fluxmax:fluxmax,dramax:dramax}
mwrfits, r, dir_plot+'results_'+scan+'_arr_'+strtrim(iarray,2)+'.fits', /create

endfor

end
