

;+
;
; SOFTWARE: Real time analysis
;
; NAME: 
; nk_focus_track
;
; CATEGORY: general, RTA
;
; CALLING SEQUENCE:
;          - nk_focus
; 
; PURPOSE: 
;        Derives telescope optimal focus offset
;
; INPUT:
; 
; OUTPUT: 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Oct. 15th, 2015: NP
;-
;================================================================================================


pro nk_focus_track_plot_fit, z_pos, flux, s_flux, z_opt, delta_z_opt, $
                             color=color, title=title, leg_txt=leg_txt, position=position, $
                             noerase=noerase, ref=ref, no_acq_flag=no_acq_flag, prism=prism, axis=axis

;;----------
;; Purpose:
;; Plots the flux as a function of the focus offset, fit for max and display result
;;----------

fmt = "(F5.2)"
xra = minmax(z_pos) + [-0.2, 0.2]*(max(z_pos)-min(z_pos))
w = where( z_pos gt !undef, nw)
ploterror, z_pos[w], flux[w], s_flux[w], psym=8, $
           xra=xra, /xs, noerase=noerase, xtitle='z [mm]', title=title, position=position, color=color

if nw ge 3 then begin
   zz = dindgen(100)/100.*(max(xra)-min(xra))+min(xra)
       
   templates = dblarr( 3, nw)
   for ii=0, 2 do templates[ii,*] = z_pos[w]^ii
   multifit, flux[w], s_flux[w], templates, ampl_out, fit, out_covar
   z_opt = -ampl_out[1]/(2.d0*ampl_out[2])
   delta_z_opt = abs(z_opt) * ( abs( sqrt(out_covar[1,1])/ampl_out[1]) + abs(sqrt(out_covar[2,2])/ampl_out[2]))
       
   oploterror, z_pos[w], flux[w], s_flux[w], psym=8, color=color, errcol=color
   oplot, zz, ampl_out[0] + ampl_out[1]*zz + ampl_out[2]*zz^2, color=color
   legendastro, leg_txt, box=0, /right, textcol=color
   legendastro, [axis+': '+num2string(z_opt)+" +- "+num2string(delta_z_opt)], $
                /bottom, /right, box=0
endif else begin
   message, "Less than three focus positions available to fit focus ?!"
endelse


end



pro nk_focus_track, scan, axis=axis, param=param

;scan = '20151015s133'
;scan = '20151015s143'
;scan = '20151015s159'

if not keyword_set(axis) then axis = 'z'
  
check=1
scan2daynum, scan, day, scan_num
if file_test(!nika.xml_dir+"/iram30m-scan-"+scan+".xml") eq 0 then begin
   message, /info, "copying xml file from mrt-lx1"
   spawn, "scp t22@150.214.224.59:/ncsServer/mrt/ncs/data/"+day+"/scans/"+strtrim(scan_num,2)+"/iram*xml $XML_DIR/."
endif
if file_test(!nika.imb_fits_dir+"/iram30m-antenna-"+scan+"-imb.fits") eq 0 then begin
   message, /info, "copying imbfits file from mrt-lx1"
   spawn, "scp t22@150.214.224.59:/data/ncs/data/"+day+"/scans/"+strtrim(scan_num,2)+"/*antenna*fits $IMB_FITS_DIR/."
endif

if not keyword_set(param) then begin
   nk_default_param, param
   param.decor_cm_dmin = 30.d0
   param.map_xsize     = 300.d0
   param.map_ysize     = 300.d0
   param.map_reso      = 4.d0
endif

if not keyword_set(info)  then nk_default_info, info

nk_update_param_info, scan, param, info, xml=xml

if keyword_set(rf)              then param.math        = "RF"
if keyword_set(one_mm_only)     then param.one_mm_only = 1
if keyword_set(two_mm_only)     then param.two_mm_only = 1
if not keyword_set(ref_det_1mm) then ref_det_1mm       = !nika.numdet_ref_1mm
if not keyword_set(ref_det_2mm) then ref_det_2mm       = !nika.numdet_ref_2mm

if not keyword_set(radius_far_kids)             then radius_far_kids             = 20.
;;if not keyword_set(common_mode_radius) then common_mode_radius = 40.

if keyword_set(online) and keyword_set(imbfits) then begin
   message, /info, "Please do not set /online and /imbfits at the same time"
   return
endif

;;-----------------------------------------------------------------------------
;; Retrieve focus positions information
xml = 1 ; default
if keyword_set(online) then begin
   if (not keyword_set(fooffset)) or (not keyword_set(focusz)) then begin
      message, /info, "Please set fooffset and focusz in input keyword if you're working /online"
      return
   endif
   xml = 0
   pako_str.obs_type = "focus"
   pako_str.focusz   = focusz
   pako_str.source   = ""
endif

if keyword_set(imbfits) then begin
   xml = 0

   nk_find_raw_data_file, param.scan_num, param.day, file, imb_fits_file
   param.file_imb_fits = imb_fits_file
   iext = 1
   status = 0
   fooffset = [0]

   imbHeader = HEADFITS( param.file_imb_fits,EXTEN='IMBF-scan')
   pako_str.source = sxpar(imbheader, 'OBJECT')
   WHILE status EQ 0 AND  iext LT 100 DO BEGIN
      aux = mrdfits(  strtrim( param.file_imb_fits), iext, haux, status = status, /silent)
      extname = sxpar( haux, 'EXTNAME')
      if strupcase(extname) eq "IMBF-ANTENNA" then begin
         fooffset = [fooffset, sxpar( haux, 'FOOFFSET')]
         print, sxpar( haux, 'FOOFFSET')
      endif
      if strupcase(extname) eq 'IMBF-SCAN' then begin
         focusz = sxpar( haux, 'FOCUSZ')
         print, "iext, focusz: ", iext, focusz
      endif
      iext = iext + 1
   endwhile
   fooffset = fooffset[1:*]
endif

if xml eq 1 then begin
   parse_pako, param.scan_num, param.day, pako_str

stop
   
   if strupcase(axis) eq "X" then focus   = pako_str.focusx
   if strupcase(axis) eq "Y" then focus   = pako_str.focusy
   if strupcase(axis) eq "Z" then focus   = pako_str.focusz

   fooffset = dblarr(6)
   pako_tags = tag_names(pako_str)
   for i=0, 5 do begin
      w = where( strupcase(pako_tags) eq "FOFFSET"+strtrim(i,2), nw)
      if nw eq 0 then begin
         message, /info, "Wrong focus offset information in pako_str"
         stop
      endif else begin
         fooffset[i] = pako_str.(w)
      endelse
   endfor
endif

param.source = strtrim( pako_str.source, 2)

;; Prepare output directory for plots and logbook
output_dir = !nika.plot_dir+"/Logbook/Scans/"+param.scan
spawn, "mkdir -p "+output_dir
param.output_dir = output_dir

;;-------------------------------------------------------------------------------
;; Get data and process TOIs
;; nk_getdata, param, info, data, kidpar, /rf, xml=xml
;; nk_scan_preproc to have cross-calibration as well
message, /info, ""
message, /info, "fix me: RF"
param.math = "RF"
param.do_opacity_correction = 0

nk_scan_preproc, param, info, data, kidpar, grid, xml=xml

;; unflag speed flags that are irrelevant here and that would throw
;; out valid samples
w1 = where(kidpar.type eq 1)
w11 = nk_where_flag( data.flag[w1[0]], 11, nflag=nflag)
if nflag ne 0 then data[w11].flag -= 2L^11

;; Check "data.subscan" correspondance to scan_Started and scan_done
message, /info, "fix me"
ikid_ref = where( kidpar.numdet eq !nika.ref_det[0])
wind, 1, 1, /free, /xlarge, iconic = param.iconic
my_multiplot, 2, 1, pp, pp1
make_ct, 6, ct
for i=4,5 do begin
   plot, data.toi[ikid_ref], /xs, position=pp1[i-4,*], /noerase
   for j=1, 6 do begin
      w = where( data.subscan eq j, nw)
      if nw ne 0 then begin
         oplot, w, data[w].toi[ikid_ref], psym=3, col=ct[j-1], thick=2
         oplot, [1,1]*min(w), [-1,1]*1e10
         oplot, [1,1]*max(w), [-1,1]*1e10
      endif
   endfor
   w = where( data.scan_st eq i, nw)
   if nw ne 0 then oplot, w, data[w].toi[ikid_ref], psym=1, col=0, syms=2, thick=3
   legendastro, 'scan_st = '+strtrim(i,2), box=0, col=250, psym=2, textcol=250
endfor

;; Derive limites of secondary mirror fixed postions
index = data.sample - data[0].sample
w4 = where( data.scan_st eq 4, nw4)
w5 = where( data.scan_st eq 5, nw5)
i_min = w4
i_max = intarr(nw4)
for i=0, nw4-1 do begin
   w = where( w5 gt w4[i], nw)
   if i eq (nw4-1) and nw eq 0 then i_max[i] = max(index) else i_max[i] = min(w5[w])
endfor

;; Derive common mode using kids far from the reference pixel
wind, 1, 1, /free, /xlarge, iconic = param.iconic
my_multiplot, 2, 1, pp, pp_toi, ymin=0.6
my_multiplot, 2, 1, pp, pp_fit, ymax=0.5
nsn = n_elements(data)
for iarray=1, 2 do begin

   ikid_ref = where(kidpar.numdet eq !nika.ref_det[iarray-1],nw)
   d = sqrt( (kidpar.nas_x-kidpar[ikid_ref].nas_x)^2 + (kidpar.nas_y-kidpar[ikid_ref].nas_y)^2)
   w_far = where( d ge param.decor_cm_dmin and kidpar.array eq iarray and kidpar.type eq 1, nw_far)
   if nw_far eq 0 then begin
      message, /info, ""
      message, /info, "radius_far_kids = "+strtrim(radius_far_kids,2)+" arcsec is too large to find pixels for the decorrelation"
      stop
   endif

   common_mode = dblarr(nsn)
   for i=0, nw_far-1 do begin
      w = where( data.flag[w_far[i]] eq 0 and data.flag[w_far[0]] eq 0, nw)
      if nw eq 0 then begin
         message, /info, "No sample for which both "+strtrim(w_far[0],2)+" and "+strtrim(w_far[1],2)+" have flag=0"
      endif else begin
         fit = linfit( data.toi[w_far[i]], data.toi[w_far[0]])
         common_mode += 1.d0/nw_far * (fit[0] + fit[1]*data.toi[w_far[i]])
      endelse
   endfor

;;      wind, 1, 1, /free, /large
;;      my_multiplot, /reset
;;      !p.multi=[0,2,2]
;;      plot, data.toi[w_far[0]]
;;      oplot, common_mode, col=250
;;
;;      plot, data.toi[w_far[0]]-common_mode
;;      make_ct, nw_far, ct
;;      for i=0, nw_far-1 do begin
;;         fit = linfit( common_mode, data.toi[w_far[i]])
;;         oplot, data.toi[w_far[i]] - (fit[0] + fit[1]*common_mode), col=ct[i]
;;      endfor

;; Cross calibrate the reference kid on the common mode for 1
;; fixed position of the mirror, the constant (source flux) is
;; irrelevant, we care only about relative variations

w = where( index ge i_min[0] and index le i_max[0], nw)
if nw eq 0 then message, "proble here, no valid section to begin with"
fit = linfit( common_mode[w], data[w].toi[ikid_ref])

;; subtract common mode from the ref. kid
data.toi[ikid_ref] -= (fit[0] + fit[1]*common_mode)
plot, data.toi[ikid_ref], position=pp_toi[iarray-1,*], /noerase
make_ct, 6, ct
for i=0, nw4-1 do begin
   w = where( index ge i_min[i] and index le i_max[i], nw)
   oplot, w, data[w].toi[ikid_ref], col=ct[i]
endfor

z_pos       = fooffset+focus
flux        = dblarr(6)
s_flux      = dblarr(6)
for ipos=0, 5 do begin
   w = where( index ge i_min[ipos] and index le i_max[ipos] and data.flag[ikid_ref] eq 0, nw)
   if nw eq 0 then begin
      message, /info, "No valid sample to measure the flux for subscan "+strtrim(ipos+1,2)
   endif else begin
      flux[  ipos] = avg( data[w].toi[ikid_ref])
      s_flux[ipos] = stddev( data[w].toi[ikid_ref]) ; conservative
      ;;s_flux[ipos] = stddev( data[w].toi[ikid_ref])/sqrt(nw) ; correct only if white noise (sic!)
      if finite(s_flux[ipos]) eq 0 then s_flux[ipos] = 0.
   endelse
endfor

;; take the difference between two identical measures (in principle) as a
;; measure of the error on the flux
s_flux[0] = abs(flux[5]-flux[0])
s_flux[1] = abs(flux[2]-flux[1])
s_flux[2] = abs(flux[2]-flux[1])
s_flux[3] = abs(flux[4]-flux[3])
s_flux[4] = abs(flux[4]-flux[3])
s_flux[5] = abs(flux[5]-flux[0])

;; ;; Take the stddev of the (two...) different measures at the same position
;; s_flux[0] = stddev( [flux[0], flux[5]])
;; s_flux[1] = stddev( [flux[1], flux[2]])
;; s_flux[2] = stddev( [flux[1], flux[2]])
;; s_flux[3] = stddev( [flux[3], flux[4]])
;; s_flux[4] = stddev( [flux[3], flux[4]])
;; s_flux[5] = stddev( [flux[0], flux[5]])


;; Focus plots and fits
nk_focus_track_plot_fit, z_pos, flux, s_flux, z_opt, delta_z_opt, position=pp_fit[iarray-1,*], $
                   color=200, leg_txt=[strtrim(iarray,2)+"mm", "", 'Numdet '+strtrim(kidpar[ikid_ref].numdet,2)], $
                   /noerase, axis=axis
if iarray eq 1 then begin
   focus_1mm     = z_opt
   err_focus_1mm = delta_z_opt
endif else begin
   focus_2mm     = z_opt
   err_focus_2mm = delta_z_opt
endelse
endfor
stop

my_multiplot, /reset

;; Print summary
print, ""
banner, "*****************************", n=1
print, "      FOCUS results"
print, ""
print, "To be used directly in PAKO (take the value at 1mm in priority)"
print, ""
print, '(1mm) SET FOCUS '+strtrim( string( focus_1mm, format='(F5.2)'),2)
print, '(2mm) SET FOCUS '+strtrim( string( focus_2mm, format='(F5.2)'),2)
print, ""
banner, "*****************************", n=1

;; Get useful information for the logbook
;; nika_get_log_info, param.scan_num, param.day, data, log_info, kidpar=kidpar
nk_get_log_info, param, info, data, log_info
log_info.source    = param.source
log_info.scan_type = pako_str.obs_type
;;if polar eq 1 then log_info.scan_type = pako_str.obs_type+"_polar"
log_info.result_name[ 0] = 'Focus_1mm'
log_info.result_value[0] = string(focus1,format='(F5.2)')
log_info.result_name[ 1] = 'Focus_2mm'
log_info.result_value[1] = string(focus2,format='(F5.2)')

save, file=output_dir+"/log_info.save", log_info

;; Create a html page with plots from this scan
nk_logbook_sub, param.scan_num, param.day

;; Update logbook
nk_logbook, param.day


end
