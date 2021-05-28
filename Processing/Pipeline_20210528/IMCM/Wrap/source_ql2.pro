pro source_ql2, project_dir, version, in_scan_list, mail=mail, png=png, ps=k_ps, $
               elevation_out=elevation_out, tau_out=tau_out, $
               flux_out=flux_out, hdr=hdr, $
               recal_coeff=recal_coeff, thick=thick,  $
               nefd_out = nefd_out, info_all = info_all, $
               param = param, chrono = chrono
; Program mostly written by NP, adapted by FXD
  mamdlib_init, 39
plot_color_convention, col_a1, col_a2, col_a3, $
                       col_mwc349, col_crl2688, col_ngc7027, $
                       col_n2r9, col_n2r12, col_n2r14, col_1mm

plot_dir = project_dir+'/Plots'
Oldp = !p
delvarx, info_all
if keyword_set( k_ps) then post = k_ps else post = 0
if post ne 0 then !p.symsize = 0.2
titlehead2 = file_basename( file_dirname(project_dir))+ ' '+ $
            file_basename( project_dir)
;; Check which scans were actually processed
nscans = n_elements(in_scan_list)
keep = intarr(nscans)
if not defined( version) then version = '1'
for iscan=0, nscans-1 do begin
   info_csv_file = project_dir+'/v_'+ strtrim(version, 2)+'/' + $
                   in_scan_list[iscan]+'/info.csv'
   if file_test(info_csv_file) then keep[iscan] = 1
endfor

w = where( keep eq 1, nw)
print, nw, ' scans could be retrieved out of ', nscans
if nw eq 0 then begin
   message, /info, "No scan was reduced"
   return
endif

;; Restrict to reduced files
scan_list = in_scan_list[w]
nscans    = nw
ind_scan = indgen( nscans)      ; make it easier when there is only one scan
if nscans eq 1 then ind_scan = [ind_scan, ind_scan]
for iscan=0, nscans-1 do begin
   info_csv_file = project_dir+'/v_'+ strtrim(version, 2)+'/' + $
                   scan_list[iscan]+'/info.csv'
   nk_read_csv_2, info_csv_file, info
   if defined(info_all) eq 0 and size(/type, info) eq 8 then begin
      info0 = info
      info0.result_tau_1mm = -1.
      info_all = replicate(info0, nscans)
   endif
   if size(/type, info) eq 8 then begin
      tagn = tag_names( info_all)
      tagn2 = tag_names( info)
      for i = 0, n_tags( info_all[0])-1 do begin
         u = where( strmatch( tagn2, tagn[i]), nu)
         if nu eq 1 then info_all[iscan].(i) = info.(u[0])
      endfor
   endif
   
endfor
ninfo = n_elements( info_all)
good = where( info_all.result_tau_1mm gt 0., ngood)
if ngood eq 0 then begin
   message, /info, 'No valid scan with correct opacity, use 225GHz instead !'
   info_all.result_tau_1mm = info_all.tau225
   info_all.result_tau_1 = info_all.tau225
   info_all.result_tau_3 = info_all.tau225
   info_all.result_tau_2mm = info_all.tau225*0.6 ; approx.
   info_all.result_tau_2 = info_all.tau225*0.6
endif
good = where( info_all.result_tau_1mm gt 0., ngood)
if ngood eq 0 then stop, 'Not enough info_all data'
nscans = ngood
info_all = info_all[ good]
print, ngood, ' scans could be read out of ', ninfo
if keyword_set( chrono) then begin
;;;;   info_all = info_all[ sort( info_all.scan)]
   info_all = info_all[ multisort( strmid( info_all.scan, 0, 8), $
                                   long( strmid( info_all.scan, 9)))]
   print, 'Chrono: reorder scans according to time'
endif

;print, info_all.scan

; Output this information
; Save as a csv file
filecsv_out = project_dir+'/info_all_'+info_all[0].object+'_v'+version+'.csv'
list = strarr( nscans)
tagn = tag_names( info_all[0])
ntag = n_tags( info_all[0])

FOR ifl = 0, nscans-1 DO BEGIN
   bigstr = string( info_all[ ifl].(0))
   FOR itag = 1, ntag-1 DO bigstr = bigstr + ' , ' + string( info_all[ ifl].(itag))
   list[ ifl] = bigstr
ENDFOR
bigstr = tagn[ 0]
FOR itag = 1, ntag-1 DO bigstr = bigstr + ' , ' + string( tagn[itag])

list = [ bigstr, list]
write_file, filecsv_out, list, /delete

;; Observing conditions
array_col = [col_a1, col_A2, col_a3] ; , col_1mm]
array_suffix = ['1', '2', '3'];, '_1mm']


;;=========================================================
;; Individual plots for the talk
field_list1 = ['tau', 'elevation_deg']
nfields1 = n_elements(field_list1)
if post lt 2 then wind, 1, 1, /free, /large
for ifield=0, nfields1-1 do begin
   if post ge 1 then begin
      fxd_ps, /landscape, /color
   endif else begin 
      outplot, file=plot_dir+"/"+field_list1[ifield]+ $
               '_v'+ strtrim(version, 2), png=png, $
               thick=thick, charthick=thick
   endelse
   if post ne 0 then !p.symsize = 0.2
   for iarray=1, 3 do begin
      nk_get_info_tag, info_all, field_list1[ifield], iarray, wtag, wtag_err
      if iarray eq 1 then begin
         if wtag_err[0] ne -1 then begin
            ploterror, info_all[ ind_scan].(wtag), info_all[ ind_scan].(wtag_err), psym=-8, $
                       syms=syms, /nodata, xtitle='scan index', $
                       title=info_all[0].object+" "+field_list1[ifield], $
                       xs=2, ys = 2
         endif else begin
            plot, info_all[ ind_scan].(wtag), psym=-8, syms=syms, $
                  /nodata, xtitle='scan index', $
                  title=info_all[0].object+" "+field_list1[ifield], $
                  xs=2, ys = 2
         endelse
      endif
      if wtag_err[0] ne -1 then begin
         oploterror, info_all[ ind_scan].(wtag), info_all[ ind_scan].(wtag_err), psym=8, sym=syms, $
                     col=array_col[iarray-1], errcol=array_col[iarray-1]
      endif else begin
         oplot, info_all[ ind_scan].(wtag), psym=-8, col=array_col[iarray-1], syms=syms
      endelse
   endfor
   if ifield eq 0 then legendastro, 'A'+strtrim(indgen(3)+1,2), col=array_col[0:2], line=0
   if post eq 2 then fxd_psout, /rotate, save_file= $
                                plot_dir+"/"+field_list1[ifield]+ $
                                '_v'+ strtrim(version, 2)+'.pdf', /over
   if post eq 1 then fxd_psout, /rotate, save_file= $
                                plot_dir+"/"+field_list1[ifield]+ $
                                '_v'+ strtrim(version, 2)+'.ps', /over
   if post eq 0 then outplot, /close, /verb
   if post ne 0 then !p.symsize = 0.2
endfor

tau_over_sinelev = dindgen(1000)/999.*2
delvarx, leg_txt
xmin = 0
ymin = 0
xmax = 1
ymax = 10
for iarray=1, 3 do begin
   nk_get_info_tag, info_all, 'nefd_center_i', iarray, wtag, wtag_err
   nk_get_info_tag, info_all, 'result_tau_'+strtrim(iarray,2), iarray, wtau
   x = info_all.(wtau)/sin(info_all.result_elevation_deg*!dtor)
   if max(x)                     gt xmax then xmax = max(x)
   if max(1000.*info_all.(wtag)) gt ymax then ymax = max(1000.*info_all.(wtag)) < 120
endfor
xra = [xmin, xmax]
yra = [ymin, ymax]

if post ge 1 then begin
   fxd_ps, /landscape, /color
endif else begin 
   outplot, file=plot_dir+"/nefd_vs_tausinelev_plot"+ $
            '_v'+ strtrim(version, 2), png=png, thick=thick, charthick=thick
endelse
if post ne 0 then !p.symsize = 0.2
;; Nsa = info_all[0].subscan_arcsec/[!nika.fwhm_nom[0], !nika.fwhm_nom[1], !nika.fwhm_nom[0]] ; how many beams per subscan
;; np = (4.+5.)/info_all[0].nsubscans+ ([param.polynom_subscan1mm, param.polynom_subscan2mm, param.polynom_subscan1mm]+1)
;; noiseup = sqrt(Nsa/(Nsa-Np))    ; this part is done at the map making level : should not be included here anymore
;
noiseup = [1., 1., 1.]
for iarray=1, 3 do begin
   nk_get_info_tag, info_all, 'nefd_center_i', iarray, wtag, wtag_err
   info_all[ ind_scan].(wtag) = info_all[ ind_scan].(wtag) * noiseup[iarray-1] ; debias the noise
   nk_get_info_tag, info_all, 'result_tau_'+strtrim(iarray,2), iarray, wtau
   wkeep = where( info_all.(wtag) lt 1, nwkeep)
   if nwkeep eq 0 then wkeep = where( info_all.(wtag) lt 100, nwkeep) ; real bad but just so the plot works
   if nwkeep eq 1 then wkeep = [wkeep, wkeep]
   x = info_all[wkeep].(wtau)/sin(info_all[wkeep].result_elevation_deg*!dtor)
   ampl = avg( 1000.*info_all[wkeep].(wtag)/exp(info_all[wkeep].(wtau)/sin(info_all[wkeep].result_elevation_deg*!dtor)))
   if iarray eq 1 then begin
      plot, x, 1000.*info_all[wkeep].(wtag), xs=2, ys = 2, $
            psym=8, syms=syms, $
            xtitle='tau/sin(el)', ytitle='NEFD (mJy.s!u1/2!n)', $
            yra=yra, xra=xra, title=info_all[0].object+" "+'NEFD center'
   endif
   oplot, x, 1000.*info_all[wkeep].(wtag), psym=8, syms=syms, col=array_col[iarray-1]
   oplot, tau_over_sinelev, ampl*exp(tau_over_sinelev)
   if defined(leg_txt) eq 0 then $
      leg_txt = "A"+strtrim(iarray,2)+": "+string(ampl,form='(F4.1)') else $
         leg_txt = [leg_txt, "A"+strtrim(iarray,2)+": "+string(ampl,form='(F4.1)')]
endfor
nk_get_info_tag, info_all, 'nefd_center_i_1mm', 1, wtag, wtag_err
wkeep = where( info_all.(wtag) lt 1, nwkeep)
if nwkeep eq 0 then wkeep = where( info_all.(wtag) lt 100, nwkeep) ; real bad but just so the plot works
if nwkeep eq 1 then wkeep = [wkeep, wkeep]
x = info_all[wkeep].(wtau)/sin(info_all[wkeep].result_elevation_deg*!dtor)
ampl = avg( 1000.*info_all[wkeep].(wtag)/exp(info_all[wkeep].(wtau)/sin(info_all[wkeep].result_elevation_deg*!dtor)))
oplot, x, 1000.*info_all[wkeep].(wtag), psym=8, syms=syms, col=col_1mm
oplot, tau_over_sinelev, ampl*exp(tau_over_sinelev)
leg_txt = [leg_txt, "A1&A3: "+string(ampl,form='(F4.1)')]
legendastro, leg_txt, textcol=[array_col[0:2], col_1mm]
legendastro, 'Stokes I', /right
if post eq 2 then fxd_psout, /rotate, save_file=plot_dir+ $
                             "/nefd_vs_tausinelev_plot"+'_v'+ $
                             strtrim(version, 2)+'.pdf', /over 
if post eq 1 then fxd_psout, /rotate, save_file=plot_dir+ $
                             "/nefd_vs_tausinelev_plot"+'_v'+ $
                             strtrim(version, 2)+'.ps', /over 
if post eq 0 then outplot, /close, /verb

if post ne 0 then !p.symsize = 0.2
nefd_out = info_all[wkeep].(wtag)
elevation_out = info_all[wkeep].result_elevation_deg
tau_out = info_all[wkeep].(wtau)

;;--------------------------------------------------------------
;; the same for Q and U if we are observing in polarization mode
nk_get_info_tag, info_all, 'nefd_center_q', 1, wtag, wtag_err
if max( abs( info_all.(wtag))) gt 0.d0 then begin
   if post ge 1 then begin
      fxd_ps, /landscape, /color
   endif else begin 
      outplot, file=plot_dir+"/nefd_vs_tausinelev_plot_Q"+ $
               '_v'+ strtrim(version, 2), png=png, thick=thick, charthick=thick
   endelse
   if post ne 0 then !p.symsize = 0.2
   delvarx, leg_txt
   for iarray=1, 3 do begin
      nk_get_info_tag, info_all, 'nefd_center_q', iarray, wtag, wtag_err
      nk_get_info_tag, info_all, 'result_tau_'+strtrim(iarray,2), iarray, wtau
      wkeep = where( info_all.(wtag) lt 1, nwkeep)
      if nwkeep eq 1 then wkeep = [wkeep, wkeep]
      
      x = info_all[wkeep].(wtau)/sin(info_all[wkeep].result_elevation_deg*!dtor)
      ampl = avg( 1000.*info_all[wkeep].(wtag)/exp(info_all[wkeep].(wtau)/sin(info_all[wkeep].result_elevation_deg*!dtor)))
      if iarray eq 1 then begin
         plot, x, 1000.*info_all[wkeep].(wtag), xs=2, ys = 2, $
               psym=8, syms=syms, $
               xtitle='tau/sin(el)', ytitle='NEFD (mJy.s!u1/2!n)', $
               yra=yra, xra=xra, title=info_all[0].object+" "+'NEFD center'
      endif
      oplot, x, 1000.*info_all[wkeep].(wtag), psym=8, syms=syms, col=array_col[iarray-1]
      oplot, tau_over_sinelev, ampl*exp(tau_over_sinelev)
      if defined(leg_txt) eq 0 then $
         leg_txt = "A"+strtrim(iarray,2)+": "+string(ampl,form='(F4.1)') else $
            leg_txt = [leg_txt, "A"+strtrim(iarray,2)+": "+string(ampl,form='(F4.1)')]
   endfor
   nk_get_info_tag, info_all, 'nefd_center_q_1mm', 1, wtag, wtag_err
   wkeep = where( info_all.(wtag) lt 1, nwkeep)
   if nwkeep eq 1 then wkeep = [wkeep, wkeep]
   x = info_all[wkeep].(wtau)/sin(info_all[wkeep].result_elevation_deg*!dtor)
   ampl = avg( 1000.*info_all[wkeep].(wtag)/exp(info_all[wkeep].(wtau)/sin(info_all[wkeep].result_elevation_deg*!dtor)))
   oplot, x, 1000.*info_all[wkeep].(wtag), psym=8, syms=syms, col=col_1mm
   oplot, tau_over_sinelev, ampl*exp(tau_over_sinelev)
   leg_txt = [leg_txt, "A1&A3: "+string(ampl,form='(F4.1)')]
   legendastro, leg_txt, textcol=[array_col[0:2], col_1mm]
   legendastro, 'Stokes Q', /right
   if post eq 2 then fxd_psout, /rotate, save_file=plot_dir+ $
                                "/nefd_vs_tausinelev_plot_Q"+ $
                                '_v'+ strtrim(version, 2)+'.pdf', /over
   if post eq 1 then fxd_psout, /rotate, save_file=plot_dir+ $
                                "/nefd_vs_tausinelev_plot_Q"+ $
                                '_v'+ strtrim(version, 2)+'.ps', /over
   if post eq 0 then outplot, /close, /verb


   if post ge 1 then begin
      fxd_ps, /landscape, /color
   endif else begin 
      outplot, file=plot_dir+ '/nefd_vs_tausinelev_plot_U_v'+ $
               strtrim(version, 2), png=png, thick=thick, charthick=thick
   endelse
   if post ne 0 then !p.symsize = 0.2
   delvarx, leg_txt
   for iarray=1, 3 do begin
      nk_get_info_tag, info_all, 'nefd_center_u', iarray, wtag, wtag_err
      nk_get_info_tag, info_all, 'result_tau_'+strtrim(iarray,2), iarray, wtau
      wkeep = where( info_all.(wtag) lt 1, nwkeep)
      if nwkeep eq 1 then wkeep = [wkeep, wkeep]
      x = info_all[wkeep].(wtau)/sin(info_all[wkeep].result_elevation_deg*!dtor)
      ampl = avg( 1000.*info_all[wkeep].(wtag)/exp(info_all[wkeep].(wtau)/sin(info_all[wkeep].result_elevation_deg*!dtor)))
      if iarray eq 1 then begin
         plot, x, 1000.*info_all[wkeep].(wtag), xs = 2, ys = 2, $
               psym=8, syms=syms, $
               xtitle='tau/sin(el)', ytitle='NEFD (mJy.s!u1/2!n)', $
               yra=yra, xra=xra, title=info_all[0].object+" "+'NEFD center'
      endif
      oplot, x, 1000.*info_all[wkeep].(wtag), psym=8, syms=syms, col=array_col[iarray-1]
      oplot, tau_over_sinelev, ampl*exp(tau_over_sinelev)
      if defined(leg_txt) eq 0 then $
         leg_txt = "A"+strtrim(iarray,2)+": "+string(ampl,form='(F4.1)') else $
            leg_txt = [leg_txt, "A"+strtrim(iarray,2)+": "+string(ampl,form='(F4.1)')]
   endfor
   nk_get_info_tag, info_all, 'nefd_center_u_1mm', 1, wtag, wtag_err
   wkeep = where( info_all.(wtag) lt 1, nwkeep)
   if nwkeep eq 1 then wkeep = [wkeep, wkeep]
   x = info_all[wkeep].(wtau)/sin(info_all[wkeep].result_elevation_deg*!dtor)
   ampl = avg( 1000.*info_all[wkeep].(wtag)/exp(info_all[wkeep].(wtau)/sin(info_all[wkeep].result_elevation_deg*!dtor)))
   oplot, x, 1000.*info_all[wkeep].(wtag), psym=8, syms=syms, col=col_1mm
   oplot, tau_over_sinelev, ampl*exp(tau_over_sinelev)
   leg_txt = [leg_txt, "A1&A3: "+string(ampl,form='(F4.1)')]
   legendastro, leg_txt, textcol=[array_col[0:2], col_1mm]
   legendastro, 'Stokes U', /right
   if post eq 2 then fxd_psout, /rotate, save_file=plot_dir+ $
                                "/nefd_vs_tausinelev_plot_U"+'.pdf', /over else $
                                   if post eq 1 then fxd_psout, /rotate, $
      save_file=plot_dir+"/nefd_vs_tausinelev_plot_U"+'.ps', /over else $
         if post eq 0 then outplot, /close, /verb

   if post ne 0 then !p.symsize = 0.2
endif
;;=========================================================


field_list1 = ['sigma_boost_i', 'flux_center_i', 'eta', $
               'tau', 'elevation_deg', 'fwhm', 'bg_rms_i']
if keyword_set( recal_coeff) then $ ; goto mJy
   field_mult1 = [ 1, 1000, 1, 1, 1, 1, 1000]
field_unit1 = ['', 'Jy', '', '', 'deg', 'arcsec', 'Jy']
if keyword_set( recal_coeff) then $ ; goto mJy
   field_unit1 = ['', 'mJy', '', '', 'deg', 'arcsec', 'mJy']
field_list2 = ['nefd_center_i']

nfields1 = n_elements(field_list1)
nfields2 = n_elements(field_list2)

nplots = nfields1+nfields2+2
if post lt 2 then wind, 1, 1, /free, /large
my_multiplot, 1, 1, ntot=nplots, pp, pp1, /rev, gap_x=0.05
!p.charsize = 0.6
syms = 0.6
if post ne 0 then syms = 0.2
p=0


if post ge 1 then begin
   fxd_ps, /landscape, /color
endif else begin 
   outplot, file=plot_dir+'/source_ql1_v'+ strtrim(version, 2), $
            png=png, thick=thick, charthick=thick
endelse
if post ne 0 then !p.symsize = 0.2
   
for ifield=0, nfields1-1 do begin
   for iarray=1, 3 do begin
      nk_get_info_tag, info_all, field_list1[ifield], iarray, wtag, wtag_err
      if iarray eq 1 then yrange = minmax( info_all.(wtag)) else $
         yrange = minmax( [minmax( info_all.(wtag)), yrange])
   endfor
   yrange = yrange* field_mult1[ ifield]
   for iarray=1, 3 do begin
      nk_get_info_tag, info_all, field_list1[ifield], iarray, wtag, wtag_err
      if iarray eq 1 then begin
         if wtag_err[0] ne -1 then begin
            ploterror, info_all[ ind_scan].(wtag)* field_mult1[ ifield], $
                       info_all[ ind_scan].(wtag_err)* field_mult1[ ifield], psym=-8, $
                       syms=syms, position=pp1[ifield,*], /noerase, /nodata, $
                       title=info_all[0].object+" "+field_list1[ifield]+ $
                       ' ['+ field_unit1[ifield]+']', xs=2, $
                       yrange = yrange, ysty = 2
         endif else begin
            plot, info_all[ ind_scan].(wtag)* field_mult1[ ifield], psym=-8, syms=syms, $
                  position=pp1[ifield,*], /noerase, /nodata, $
                  title=info_all[0].object+" "+field_list1[ifield]+ $
                       ' ['+ field_unit1[ifield]+']', xs=2, $
                  yrange = yrange, ysty = 2
         endelse
      endif
      if wtag_err[0] ne -1 then begin
         oploterror, info_all[ ind_scan].(wtag)* field_mult1[ ifield], $
                     info_all[ ind_scan].(wtag_err)* field_mult1[ ifield], $
                     psym=8, sym=syms, $
                     col=array_col[iarray-1], errcol=array_col[iarray-1]
      endif else begin
         oplot, info_all[ ind_scan].(wtag)* field_mult1[ ifield], $
                psym=-8, col=array_col[iarray-1], syms=syms
      endelse
   endfor
   p++
   legendastro, 'A'+strtrim(indgen(3)+1,2), col=array_col[0:2]
endfor

;----------------------------------------------------------------
;; effective opacity correction
tau_corr_max = 1.8 ; 1.8
for iarray=1, 3 do begin
   nk_get_info_tag, info_all, 'tau', iarray, wtag, wtag_err
   y = exp( info_all.(wtag)/sin(info_all.result_elevation_deg*!dtor))
   if n_elements( y) eq 1 then y = [y, y]
   if iarray eq 1 then begin
      plot, y, psym=-8, $
            syms=syms, position=pp1[p,*], /noerase, /nodata, $
            title=titlehead2+ ' exp(tau/sin(el))', xs=2, ys = 2
      oplot, [-1,1]*1d10, [1,1]*tau_corr_max
   endif
   oplot, y, psym=-8, sym=syms, col=array_col[iarray-1]
endfor
p++
legendastro, 'A'+strtrim(indgen(3)+1,2), col=array_col[0:2]


;----------------------------------------------------------------
;; NEFD vs tau/sin(elev)
tau_over_sinelev = dindgen(1000)/999.*2
delvarx, leg_txt
xmin = 0
ymin = 0
xmax = 1
ymax = 100
for iarray=1, 3 do begin
   nk_get_info_tag, info_all, 'nefd_center_i', iarray, wtag, wtag_err
   nk_get_info_tag, info_all, 'result_tau_'+strtrim(iarray,2), iarray, wtau
   x = info_all.(wtau)/sin(info_all.result_elevation_deg*!dtor)
   if max(x)                     gt xmax then xmax = max(x)
;   if max(1000.*info_all.(wtag)) gt ymax then ymax = max(1000.*info_all.(wtag))
endfor
xra = [xmin, xmax]
yra = [ymin, ymax]

for iarray=1, 3 do begin
   nk_get_info_tag, info_all, 'nefd_center_i', iarray, wtag, wtag_err
   nk_get_info_tag, info_all, 'result_tau_'+strtrim(iarray,2), iarray, wtau
   x = info_all.(wtau)/sin(info_all.result_elevation_deg*!dtor)
   ampl = avg( 1000.*info_all.(wtag)/exp(info_all.(wtau)/sin(info_all.result_elevation_deg*!dtor)))
   if iarray eq 1 then begin
      plot, x[ind_scan], 1000.*info_all[ ind_scan].(wtag), xs=2, ys = 2, $
            psym=8, syms=syms, /noerase, position=pp1[p,*], $
            xtitle='tau/sin(el)', yra=yra, xra=xra, title=info_all[0].object+" "+'NEFD center'
   endif
   oplot, x[ind_scan], 1000.*info_all[ind_scan].(wtag), psym=8, syms=syms, col=array_col[iarray-1]
   oplot, tau_over_sinelev, ampl*exp(tau_over_sinelev)
   if defined(leg_txt) eq 0 then $
      leg_txt = "A"+strtrim(iarray,2)+": "+string(ampl,form='(F4.1)') else $
         leg_txt = [leg_txt, "A"+strtrim(iarray,2)+": "+string(ampl,form='(F4.1)')]
endfor
p++
nk_get_info_tag, info_all, 'nefd_center_i_1mm', iarray, wtag, wtag_err
nk_get_info_tag, info_all, 'result_tau_'+strtrim(1,2), iarray, wtau
x = info_all.(wtau)/sin(info_all.result_elevation_deg*!dtor)
ampl = avg( 1000.*info_all.(wtag)/exp(info_all.(wtau)/sin(info_all.result_elevation_deg*!dtor)))
oplot, x[ind_scan], 1000.*info_all[ind_scan].(wtag), psym=8, syms=syms, col=col_1mm
oplot, tau_over_sinelev, ampl*exp(tau_over_sinelev)
leg_txt = [leg_txt, 'A1 & A3: '+string(ampl,form='(F4.1)')]
legendastro, leg_txt, col=[array_col, col_1mm], psym=8

;; NEFD0 vs index
delvarx, leg_txt
ymin = 0
ymax = 100.
for iarray=1, 3 do begin
   nk_get_info_tag, info_all, 'nefd_center_i', iarray, wtag, wtag_err
   nk_get_info_tag, info_all, 'result_tau_'+strtrim(iarray,2), iarray, wtau
   x = info_all.(wtau)/sin(info_all.result_elevation_deg*!dtor)
;   if max(1000.*info_all.(wtag)) gt ymax then ymax = max(1000.*info_all.(wtag))
endfor
yra = [ymin, ymax]
for iarray=1, 3 do begin
   nk_get_info_tag, info_all, 'nefd_center_i', iarray, wtag, wtag_err
   nk_get_info_tag, info_all, 'result_tau_'+strtrim(iarray,2), iarray, wtau
   x = info_all.(wtau)/sin(info_all.result_elevation_deg*!dtor)
   ampl = 1000.*info_all.(wtag)/ $
          exp(info_all.(wtau)/sin(info_all.result_elevation_deg*!dtor))
   if iarray eq 1 then begin
      plot, ampl[ind_scan], xs=2, ys = 2, $
            psym=-8, syms=syms, /noerase, position=pp1[p,*], $
            yra=yra,title=info_all[0].object+" "+'NEFD0 [mJy.s^1/2]'
   endif
   oplot, ampl[ind_scan], psym=-8, syms=syms, col=array_col[iarray-1]
   good = where( ampl lt ymax, ngood)
   if ngood eq 0 then message,/info, 'Not enough scans with NEFD0 within the range, change ymax by 10'
   if ngood eq 0 then good = where( ampl lt ymax*10, ngood)
   oplot, replicate( avg(ampl[good]), n_elements( info_all))
   if iarray eq 2 then badnefd = where( ampl gt 1.1*avg(ampl[good]), nbadnefd) ; for later use
   if defined(leg_txt) eq 0 then $
      leg_txt = "A"+strtrim(iarray,2)+": "+string(avg(ampl[good]),form='(F4.1)') else $
         leg_txt = [leg_txt, "A"+strtrim(iarray,2)+": "+string(avg(ampl[good]),form='(F4.1)')]
endfor
nk_get_info_tag, info_all, 'nefd_center_i_1mm', iarray, wtag, wtag_err
nk_get_info_tag, info_all, 'result_tau_'+strtrim(1,2), iarray, wtau
x = info_all.(wtau)/sin(info_all.result_elevation_deg*!dtor)
ampl =1000.*info_all.(wtag)/exp(info_all.(wtau)/sin(info_all.result_elevation_deg*!dtor))
oplot, ampl[ind_scan], psym=-8, syms=syms, col=col_1mm
good = where( ampl lt ymax, ngood)
if ngood eq 0 then message,/info, 'Not enough scans with NEFD0 within the range, change ymax by 10'
if ngood eq 0 then good = where( ampl lt ymax*10, ngood)
oplot, replicate( avg(ampl[good]), n_elements( info_all))
leg_txt = [leg_txt, 'A1 & A3: '+string(avg(ampl[good]),form='(F4.1)')]
legendastro, leg_txt, col=[array_col, col_1mm], psym=8

p++

nk_get_info_tag, info_all, 'tau', 1, wtau1
nk_get_info_tag, info_all, 'tau', 2, wtau2
plot, info_all[ ind_scan].(wtau2)/info_all[ ind_scan].(wtau1), xs=2, ys = 16, psym=-8, syms=syms, $
      xtitle='Scan index',  $
      title=info_all[0].object+ ' Tau2/Tau1', position=pp1[p,*], /noerase
p++
; Plot scan angle wrt Horizontal vs scan number
pv = ((info_all.paral + 360.) mod 360) - 180.  ; True paralactic angle i.e. 0 (instead of 180) degree when HA=0.
anglehz = atan( tan( (info_all.scan_angle + pv)/!radeg))*!radeg  ; +pv is the correct sign Do not change (Tested with G2), get an angle between -90 and 90
plot, anglehz[ind_scan], xs=2, ys = 16, psym=-8, syms=syms, yrange = [-100, 100], $
      xtitle='Scan index (Red > 1.1 avg(NEFD0_2mm))',$; ytitle='Scan angle wrt Horizontal [deg]', $
      title='AngleHor [deg] (Diamonds wrt Ra) ', position=pp1[p,*], /noerase
if nbadnefd gt 0 then oplot, badnefd, anglehz[ badnefd], $
                             psym = 8, syms = syms, col = array_col[2-1] ; mark red the 2mm bad scans
proj = strmatch( strtrim(info_all.systemof), 'projection', /fold) ; Radec as opposed to 'HorizontalTrue'=Azel
; scan_angle is determined in RaDec coordinates
u = where( proj, nu)
if nu eq 1 then u = [u, u]
if nu ne 0 then begin
   oplot, u, info_all[u].scan_angle, col = 100, psym = 4, syms = syms
   v = where( proj[badnefd], nv)
   if nv eq 1 then v = [v, v] ; to avoid an IDL bug next line
   if nv gt 0 then $
      oplot, badnefd[v], info_all[ badnefd[v]].scan_angle, $
             psym = 4, syms = syms, col = array_col[2-1] ; mark red the 2mm bad scans
endif
;; Old version Tau2/Tau1 vs Tau1/sinel
;; plot, x, info_all.(wtau2)/info_all.(wtau1), xs=2, ys = 16, psym=-8, syms=syms, $
;;       xtitle='Tau1/sin(el)', ytitle='Tau2/Tau1', $
;;       title=info_all[0].object, position=pp1[p,*], /noerase
if post eq 2 then fxd_psout, /rotate, save_file=plot_dir+ $
                             '/source_ql1_v'+ strtrim(version, 2)+'.pdf', /over 
if post eq 1 then fxd_psout, /rotate, save_file=plot_dir+ $
                             '/source_ql1_v'+ strtrim(version, 2)+'.ps', /over 
if post eq 0 then outplot, /close, /verb



;;=========================================================

; Scan Integration time RESULT_TIME_MATRIX_CENTER_1MM
; RESULT_TIME_MATRIX_CENTER_2MM
; RESULT_VALID_OBS_TIME RESULT_TOTAL_OBS_TIME
; one plot: subscan_length (subscan_arcsec), scan_width (subscan_step*nsubscans)
; one plot: projection, paral, az_source, which run

nplots = 4
if post lt 2 then wind, 1, 1, /free, /large
my_multiplot, 1, 1, ntot=nplots, pp, pp1, /rev, gap_x=0.05
!p.charsize = 0.6
syms = 0.6
if post ne 0 then syms = 0.2
p=0

if post ge 1 then begin
   fxd_ps, /landscape, /color
endif else begin 
   outplot, file=plot_dir+'/source_ql2_v'+ strtrim(version, 2), $
            png=png, thick=thick, charthick=thick
endelse
if post ne 0 then !p.symsize = 0.2


plot, info_all[ ind_scan].RESULT_TOTAL_OBS_TIME, psym=-8, syms=syms, $
      position=pp1[p,*], /noerase, $
      title=info_all[0].object+'  [TOTAL,VALID,CENTER1,2MM]_TIME [s]', xs=2, $
       ysty = 2
oplot, info_all[ ind_scan].RESULT_VALID_OBS_TIME, psym=-8, syms=syms, col = 50
oplot, info_all[ ind_scan].RESULT_TIME_MATRIX_CENTER_1MM, psym=-8, syms=syms, col = 100
oplot, info_all[ ind_scan].RESULT_TIME_MATRIX_CENTER_2MM, psym=-8, syms=syms, col = 200

p++
yra = minmax( [info_all[ ind_scan].SUBSCAN_ARCSEC, $
               info_all[ ind_scan].subscan_step* $
               (info_all[ ind_scan].nsubscans-1)])
plot, info_all[ ind_scan].SUBSCAN_ARCSEC, psym=-8, syms=syms, $
      position=pp1[p,*], /noerase, $
      title= titlehead2 +'  subscan length(arcsec), scan width (blue)', xs=2, $
       ysty = 2
oplot, info_all[ ind_scan].subscan_step* $
       (info_all[ ind_scan].nsubscans-1), psym=-8, syms=syms, col = 50

; Write the scan name and run every 10 scans
index = indgen((ngood/10)>1)*10
nindex = n_elements( index)
get_nika2_run_info, n2rstruct
scanall = nk_get_all_scan( n2rstruct)
scna = scanall.day+'s'+strtrim( scanall.scannum, 2)
n2r = strarr(nindex)
;;; Should use nk_scan2run instead
for in2r = 0, nindex-1 do begin
   wn2r = where( strmatch( scna, info_all[index[in2r]].scan, /fold), nwn2r)
   if nwn2r gt 0 then n2r[ in2r] = scanall[ wn2r[0]].nika2run
endfor
print, index
print, info_all[ index].scan+' '+n2r
xyouts, index, index*0+10., info_all[ index].scan+' '+n2r, $
        orientation = 90.       ; ie vertical

p++
proj = strmatch( strtrim(info_all.systemof), 'projection', /fold) ; Radec as opposed to 'HorizontalTrue'=Azel
; scan_angle is determined in RaDec coordinates
plot, info_all[ ind_scan].paral, psym=-3, syms=syms, $
      position=pp1[p,*], /noerase, $
      title='  paralactic angle black (proj. RaDec Diamonds), Az Purple [deg]', xs=2, $
      ysty = 2, yrange = [-180, 180.]
u = where( proj, nu)
if nu eq 1 then u = [u, u]
if nu ne 0 then $
   oplot, u,  info_all[u].paral, psym = 4, syms = syms, col = 100
oplot, info_all[ ind_scan].az_source*!radeg, psym=8, syms=syms, col = 200

p++

if post eq 2 then fxd_psout, /rotate, save_file=plot_dir+ $
                             '/source_ql2_v'+ strtrim(version, 2)+'.pdf', /over 
if post eq 1 then fxd_psout, /rotate, save_file=plot_dir+ $
                             '/source_ql2_v'+ strtrim(version, 2)+'.ps', /over 
if post eq 0 then outplot, /close, /verb

; Merge pdf
if post eq 2 then begin
   file1 = plot_dir+ '/source_ql1_v'+ strtrim(version, 2)+'.pdf'
   file2 = plot_dir+ '/source_ql2_v'+ strtrim(version, 2)+'.pdf'
   fileall = plot_dir+ '/source_ql_v'+ strtrim(version, 2)+'.pdf'
   allpdf = strjoin( [file1, file2]+' ')
   command = 'pdfunite '+ allpdf+ ' '+ fileall
   spawn, 'which pdfunite', res
   if strlen( strtrim(res, 2)) gt 0 then begin
      spawn, command, res
      command2 = 'rm -f '+ allpdf
      spawn, command2, res2
   endif else begin
      print, 'Try installing pdfunite '
   endelse
endif

!p = Oldp 

return

end
