

pro nk_focus_liss, scan, param=param, educated=educated, xml=xml, offsets=offsets, nopng=nopng, $
                   jump_remove=jump_remove, data=data, kidpar=kidpar, info=info, $
                   xyguess=xyguess, radius=radius, azelguess=azelguess


;; scan = '20151010s164' ; only3 subscans ?
;; ;; scan = '20151009s146' ; 5 subscans, but impossible to fit the source
;; scan = '20151012s43'

scan2daynum, scan, day, scan_num
if file_test(!nika.xml_dir+"/iram30m-scan-"+scan+".xml") eq 0 then begin
   message, /info, "copying xml file from mrt-lx1"
   spawn, "scp t22@150.214.224.59:/ncsServer/mrt/ncs/data/"+day+"/scans/"+strtrim(scan_num,2)+"/iram*xml $XML_DIR/."
endif
if file_test(!nika.imb_fits_dir+"/iram30m-antenna-"+scan+"-imb.fits") eq 0 then begin
   message, /info, "copying imbfits file from mrt-lx1"
   spawn, "scp t22@150.214.224.59:/data/ncs/data/"+day+"/scans/"+strtrim(scan_num,2)+"/*antenna*fits $IMB_FITS_DIR/."
endif

if not keyword_set(param) then nk_default_param,  param
if keyword_set(one_mm_only) then param.one_mm_only = one_mm_only
if keyword_set(two_mm_only) then param.two_mm_only = two_mm_only

param.math = "RF"

;param.decor_method = 'common_mode'
param.decor_method = 'common_mode_kids_out'
param.decor_per_subscan = 1 ; make sure here
param.interpol_common_mode = 1

param.fast_deglitch = 1
param.do_plot  = 1
param.plot_png = 1
param.do_opacity_correction = 0
param.focus_liss_new = 1
param.fine_pointing = 0
param.imbfits_ptg_restore = 0

k_noise = 0.2

plot_output_dir = !nika.plot_dir+"/Logbook/Scans/"+scan
spawn, "mkdir -p "+plot_output_dir

if keyword_set(nopng) then param.plot_png = 0

;; Process data
nk_default_info, info
nk_update_param_info, scan, param, info
nk_init_grid, param, info, grid

param.focus_liss_new = 1 ; to bypass speed_flags and cut_scans that perform global fits on pointing
nk_getdata, param, info, data, kidpar, sn_min=sn_min, sn_max=sn_max,$
            force_file = force_file, $
            xml = xml, list_detector=list_detector
if info.status eq 1 then begin
   message, /info, "could not read the data"
   return
endif

;; 1st subscan of this sequence looks like a calibration subscan:
;; discard it.
data = data[ where(data.subscan ge 2)]

if keyword_set(jump_remove) then nk_remove_jumps, param, info, data, kidpar

;; Compute individual kid pointing once for all
;; Needed here for simulations
nk_get_kid_pointing, param, info, data, kidpar

;; Compute data.ipix to save time
nk_get_ipix, data, info, grid

;; Calibrate
nk_calibration, param, info, data, kidpar, simpar=simpar

;; Deglitch
if param.fast_deglitch eq 1 then begin
   nk_deglitch_fast, param, info, data, kidpar
endif else begin
   nk_deglitch, param, info, data, kidpar
endelse

smin = min(data.subscan)
smax = max(data.subscan)
nsubscans    = smax - smin + 1
subscan_list = indgen(nsubscans) + smin
make_ct, nsubscans, ct

w5 = where( data.scan_st eq 5, nw5)
w6 = where( data.scan_st eq 6, nw6)

;; Define which parts of the maps must be masked for common mode estimation
;; info.mask_source must be 1 outside the source, 0 on source

if keyword_set(xyguess) then begin
   if not keyword_set(radius) then radius = 50
   nk_default_mask, param, info, grid, radius=radius, $
                    xcenter=info.NASMYTH_OFFSET_X, $
                    ycenter=info.NASMYTH_OFFSET_Y
   param.decor_method = 'common_mode_kids_out'
   xguess = info.NASMYTH_OFFSET_X
   yguess = info.NASMYTH_OFFSET_Y
   educated = 0
endif
if keyword_set(azelguess) then begin
   nk_default_mask, param, info, grid, radius=radius
   param.decor_method = 'common_mode_kids_out'
   xguess = 0.d0
   yguess = 0.d0
   educated = 1
endif

nk_mask_source, param, info, data, kidpar, grid

;; ;; Retrieve MJD at integration start from the AntennaIMBfits
;; iext=1
;; stat=0
;; mjd_imbfits = [0]
;; focus_imbfits = [0]
;; while stat eq 0 do begin
;;    m = mrdfits(param.file_imb_fits,iext,status=stat,/silent, header)
;;    if size(m,/type) eq 8 then begin
;;       if tag_exist(m,"mjd") and tag_exist(m,"focus_z") then begin
;;          print, "Extention: "+strtrim(iext,2)+", focus_z: "+strtrim(m[0].focus_z,2)
;;          print, string(m[0].mjd, format="(F16.10)"), string(m[0].focus_z, format="(F16.10)")
;;          focus_imbfits = [focus_imbfits, m[0].focus_z]
;;          mjd_imbfits   = [mjd_imbfits, m[0].mjd]
;;        endif
;;    endif
;;    iext++
;; endwhile
;; 
;; mjd_imbfits   = mjd_imbfits[1:*]
;; focus_imbfits = focus_imbfits[1:*]
;; w = where( mjd_imbfits ge min(data.mjd), nw)
;; if nw eq 0 then begin
;;    message, /info, "MJD's in the AntennaIMBfits do not match data.mjd"
;;    stop
;; endif
;; mjd_imbfits   = mjd_imbfits[w]
;; focus_imbfits = focus_imbfits[w]
;; 
;; message, /info, "fix me: test pako focus values:"
;; parse_pako, scan_num, day, pako_str
;; help, pako_str, /str
;; ;;pako_offsets =  [-1,-0.5,0,0.5,1] -0.6
;; stop
;; ;focus_imbfits = pako_offsets
;; ;stop

;; Retrieve focus values and MJD at integration start from the AntennaIMBfits

;; RZ's prescription for focus, Oct. 4th, 2012
;; Then you have to fit the observed intensity
;; (more precisely the mean of the observed intensity between backOnTrack and subScanEnd)
;; as function of FOCUSZ+FOOFFSET.

;; Retrive focus information in the AntennaIMBfits
imbHeader = HEADFITS( param.file_imb_fits, EXTEN='IMBF-scan')
focusx_correction = double( sxpar( imbHeader, 'FOCUSX'))
focusy_correction = double( sxpar( imbHeader, 'FOCUSY'))
focusz_correction = double( sxpar( imbHeader, 'FOCUSZ'))

status = 0
p=0
iext = 1
WHILE status EQ 0 AND iext LT 100 DO BEGIN
   aux = mrdfits( param.file_imb_fits, iext, haux, status = status, /silent)
   ;fooffset = sxpar( haux, "fooffset")
   ;print, "iext, fooffset: ", iext, fooffset

   extname = sxpar( haux, 'EXTNAME')
   if strupcase(extname) eq "IMBF-ANTENNA" then begin
      if p eq 0 then begin
         string_fooffset = sxpar( haux, 'FOOFFSET')
         imbfits_mjd_list = aux[0].mjd
         p++
      endif else begin
         string_fooffset = [string_fooffset, strtrim(sxpar( haux, 'FOOFFSET'),2)]
         imbfits_mjd_list = [imbfits_mjd_list, aux[0].mjd]
      endelse
   endif
   
   if strupcase(extname) eq "IMBF-SUBREFLECTOR" then begin
      f = sxpar( haux, "FOTRANSL")
      if strmid( f,0,1) ne '' then fotransl = f
      ;; check that it does not change accross the scan
      if defined(fotransl) then begin
         if strupcase( f) ne strupcase(fotransl) then begin
            message, /info, "FOTRANSL is chaging across the scan"
            message, /info, "This program is not ready to cope with it."
            return
         endif
      endif
   endif

   iext++
endwhile

info.FOTRANSL = fotransl

;; print, "focusz: ", focusz_correction
;; print, "FOTRANSL: ", FOTRANSL
;; print, "string_foffset: ", string_fooffset+", "
;; print, "imbfits_mjd_list: ", string(imbfits_mjd_list, format='(F20.14)')
;; print, "minmax(data.mjd): ", string( minmax(data.mjd), format='(F20.14)')
;; stop

;; The first value seems to be always wrong in offset
imbfits_mjd_list = imbfits_mjd_list[1:*]
string_fooffset  = string_fooffset[ 1:*]

;; Derive limits of secondary mirror fixed postions and focus values
index = data.sample - data[0].sample
w4 = where( data.scan_st eq 4, nw4)
w5 = where( data.scan_st eq 5, nw5)
i_min = w4
i_max = intarr(nw4)
f_offset = dblarr(nw4)
;; <<<<<<< .mine
;; ;; for i=0, nw4-1 do begin
;; ;;    w = where( w5 gt w4[i], nw)
;; ;;    if i eq (nw4-1) and nw eq 0 then i_max[i] = max(index) else i_max[i] = min(w5[w])
;; ;;    dt = imbfits_mjd_list - data[w4[i]].mjd
;; ;;    w_lkv = where( dt eq max(dt[where(dt le 0)]))
;; ;;    f_offset[i] = double( string_fooffset[w_lkv])
;; ;; endfor
;; f_offset= float( string_fooffset)  ; FXD for N2R1
;; =======
;; 
;; >>>>>>> .r9098

;; WARNING :: NICO WE HAVE CHANGED tHIS  
f_offset = float(string_fooffset)

;; for i=0, nw4-1 do begin
;;    w = where( w5 gt w4[i], nw)
;;    if i eq (nw4-1) and nw eq 0 then i_max[i] = max(index) else i_max[i] = min(w5[w])
;;    dt = imbfits_mjd_list - data[w4[i]].mjd - 4D-5 ; fudge factor to be understood 26-oct-2015
;;    ; tested on nk_rta,'20151026s27'
;;    w_lkv = where( dt eq max(dt[where(dt le 0)])) ; this is attempting to find the most recent (past) subscan to use. But what happens when all dt >0? Disaster!
;;    f_offset[i] = double( string_fooffset[w_lkv])
;; endfor

case strupcase( strmid( FOTRANSL, 0, 1)) of
   "X": focus = f_offset + focusx_correction
   "Y": focus = f_offset + focusy_correction
   "Z": focus = f_offset + focusz_correction
endcase

wind, 1, 1, /free, /large, iconic = param.iconic
!p.multi=[0,2,2]
plot, data.ofs_az, data.ofs_el, /iso, xtitle='Ofs_az', ytitle='Ofs_el'

fields = ['ofs_az', 'ofs_el']
tags = tag_names(data)
nsn = n_elements(data)
xmin = min( [imbfits_mjd_list, data[0].mjd])
xmax = max( [imbfits_mjd_list, data[nsn-1].mjd])
xra = [xmin,xmax] + [-0.2, 0.2]*(xmax-xmin)
for ifield=0, n_elements(fields)-1 do begin
   wfield = where( strupcase(tags) eq strupcase(fields[ifield]))
   ymax = max(data.(wfield))
   ymin = min(data.(wfield))
   yra = [ymin, ymax] + [-0.1, 0.5]*(ymax-ymin)
   plot, data.mjd, data.(wfield), /xs, yra=yra, /ys, xra=xra
   for i=0, nsubscans-1 do begin
   w = where( data.subscan eq subscan_list[i], nw)
   if nw ne 0 then oplot, data[w].mjd, data[w].(wfield), thick=2, col=ct[i]
   endfor
   oplot, data[w6].mjd, data[w6].(wfield), psym=1, col=70, thick=2  ; back on track
   oplot, data[w5].mjd, data[w5].(wfield), psym=1, col=250, thick=2 ; subscan done
   for i=0, n_elements(imbfits_mjd_list)-1 do oplot, [1,1]*imbfits_mjd_list[i], [-1,1]*1e10
   legendastro, [fields[ifield], $
                 "Back on track", $
                 "subscan done"], box=0, psym=[1,1,1], col=[0,70,250]
endfor
!p.multi=0

;;-------------------------------------------
;; Main loop

res_label     = ['Flux', 'FWHM']
results       = fltarr(nsubscans, 3, 2) ; 3 arrays, two values (flux and fwhm)
sigma_results = results*0.d0

focus_list = fltarr(nsubscans)
wind, 1, 1, /free, /large, iconic = param.iconic
outplot, file = plot_output_dir+"/maps_"+strtrim(scan, 2), png = param.plot_png, ps = param.plot_ps
w_summary = !d.window
my_multiplot, nsubscans, 3, pp, pp1, /rev, /full
grid_tags = tag_names(grid)
info_tags = tag_names(info)
for i=0, nsubscans-1 do begin
   wsubscan = where( data.subscan eq subscan_list[i], nwsubscan)

   if nwsubscan ne 0 then begin

      ;; Get the relevant focus for this subscan
      ;; based on MJD's last know value. In case one is missing, discard the
      ;; subscan.
      mid_time = data[wsubscan[nwsubscan/2]].mjd
      w = where( mid_time - imbfits_mjd_list ge 0, nw)
      if nw eq 0 then begin
         message, /info, "No focus information from the AntennaIMBfits for this subscan"
         message, /info, "=> Discard it"
      endif else begin
         focus_list[i] = focus[max(w)]

         param.do_plot=0
         data1 = data[wsubscan]

         nk_speed_flag_2, param, info, data1, kidpar
         nk_clean_data_2, param, info, data1, kidpar
         nk_w8, param, info, data1, kidpar
         nk_projection_4, param, info, data1, kidpar, grid

         for iarray =1, 3 do begin
            wt1 = where( grid_tags eq "MAP_I"+strtrim(iarray,2))
            wv1 = where( grid_tags eq "MAP_VAR_I"+strtrim(iarray,2))
            wn1 = where( grid_tags eq "NHITS_"+strtrim(iarray,2))
            if max( grid.(wn1)) gt 0 then begin
               info.status = 0
               if strupcase(param.map_proj) eq "NASMYTH" then coltable=3
               nk_map_photometry, grid.(wt1), grid.(wv1), grid.(wn1), grid.xmap, grid.ymap, !nika.fwhm_array[iarray-1], $
                                  flux, s_flux, sigma_bg, output_fit_par, output_fit_par_error, $
                                  position=pp[i,iarray-1,*], k_noise=k_noise, /nobar, $
                                  info=info, educated=educated, /short, charsize = 0.6, $
                                  extra_leg_txt='Focus '+strtrim(FOTRANSL,2)+": "+$
                                  string( focus_list[i], format="(F5.2)"), extra_leg_col=255, $
                                  xguess=xguess, yguess=yguess, coltable=coltable
               
               if info.status eq 0 then begin
                  results[       i, iarray-1, 0] = flux
                  sigma_results[ i, iarray-1, 0] = s_flux
                  
                  results[       i, iarray-1, 1] = sqrt( output_fit_par[2]*output_fit_par[3])/!fwhm2sigma
                  sigma_results[ i, iarray-1, 1] = sqrt(output_fit_par_error[2]*output_fit_par_error[3])/!fwhm2sigma
                  
                  ;; ww = where( strupcase(info_tags) eq "RESULT_FWHM_X_"+strtrim(iarray, 2), nww)
                  ;; if nww ne 0 then info.(ww) = output_fit_par[2]
                  ;; ww = where( strupcase(info_tags) eq "RESULT_FWHM_Y_"+strtrim(iarray, 2), nww)
                  ;; if nww ne 0 then info.(ww) = output_fit_par[3]
                  ;; ww = where( strupcase(info_tags) eq "RESULT_FWHM_"+strtrim(iarray, 2), nww)
                  ;; if nww ne 0 then info.(ww) = results[ i, iarray-1, 1]
                  
               endif
            endif

         endfor
      endelse
   endif
endfor
outplot, /close
my_multiplot, /reset
loadct, 39
;; ;; From Hans Ungerechts' email, Nov. 12th, 2014
;; ;; however,  for the data selection,  to be conservative,  I recommend: 
;; ;; for the start: antMD:subscanId.1:segmentStarted + 2.000 [s]
;; ;;                -- start of the ramp-up leading into the Lissajous 
;; ;;            or: antMD:subscanId.2:segmentStarted
;; ;;                -- start of the Lissajous curve itself
;; ;; 
;; ;;             for the end:   antMD subscanDone - 2 slow loops ( 2*0.125 [s] )
;; 


;; ;; test on fwhm
;; stop
;; wkeep = where( results[*,1,1] gt 0, nwkeep)
;; if nwkeep lt 3 then begin
;;    message, /info, "Not enough valid fits to estimate the focus"
;;    message, /info, "Please relaunch the Pako script."
;;    return
;; endif

;; Init structure for the logbook
;; nika_get_log_info, param.scan_num, param.day, data, log_info, kidpar=kidpar
nk_get_log_info, param, info, data, log_info

;; Fit optimal focus
;; focus      = focus_list[wkeep]

wind, 1, 1, /free, /large, iconic = param.iconic
outplot, file = plot_output_dir+"/plot_"+strtrim(scan, 2), png = param.plot_png, ps = param.plot_ps
my_multiplot, 3, 2, pp, pp1, /rev, gap_y=0.1, ymargin=0.05
z_results = dblarr(3,2)
for iarray=1, 3 do begin
   w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
   if nw1 ne 0 then begin
      wkeep = where( results[*,iarray-1,0] gt 0, nwkeep)
      if nwkeep lt 3 then begin
         message, /info, "Not enough valid fluxes to fit the focus for array "+strtrim(iarray,2)
      endif else begin
         focus = focus_list[wkeep]
         for ir=0,1 do begin
            meas     = reform( results[       wkeep,iarray-1,ir], nwkeep)
            meas_err = reform( sigma_results[ wkeep,iarray-1,ir], nwkeep)
            cp = poly_fit( focus, meas, 2, measure_errors=meas_err)
            
            xx = dindgen(100)/99*10-5
            fit_p = xx*0.d0
            for i = 0, n_elements(cp)-1 do fit_p += cp[i]*xx^i
            
            opt_z_p = -cp[1]/(2.d0*cp[2])
            z_results[iarray-1,ir] = opt_z_p
            ploterror, focus, meas, meas_err, psym = 8, $
                       xtitle='Focus '+strtrim(FOTRANSL,2)+' [mm]', position=pp[iarray-1,ir,*], /noerase
            oplot, xx, fit_p, col = 250
            res_type = res_label[ir]+" A"+strtrim(iarray,2)
            legendastro, [res_type, $
                          'Opt '+strtrim(FOTRANSL,2)+': '+num2string(opt_z_p)], box = 0, chars=0.8
            
            log_info.result_name[ (iarray-1)*2+ir] = res_type
            log_info.result_value[(iarray-1)*2+ir] = opt_z_p

            if ir eq 1 then begin
               ww = where( strupcase(info_tags) eq "OPT_FOCUS_"+strtrim(iarray, 2),  nww)
               if nww ne 0 then info.(ww) = opt_z_p
            endif
            ;ww = where( strupcase(info_tags) eq "ERR_OPT_FOCUS_"+strtrim(iarray, 2),  nww)
            ;if nww ne 0 then info.(ww) = delta_z_opt

         endfor
      endelse
   endif
endfor
outplot, /close

;; Create a html page with plots from this scan
save, file=plot_output_dir+"/log_info.save", log_info
nk_logbook_sub, param.scan_num, param.day

;; Update logbook
nk_logbook, param.day

;; Write output .csv to gather focus results
nk_info2csv, info, plot_output_dir+"/photometry.csv"

print, ""
banner, "*****************************", n=1
print, "      FOCUS results"
print, ""
print, "To be used directly in PAKO"
print, "Check the best fit value, give preference to the minimum FWHM"
print, ""
for iarray=1, 3 do begin
   print, '(Flux A'+strtrim(iarray,2)+') SET FOCUS '+string( z_results[iarray-1,0], format='(F5.2)')
   print, '(FWHM A'+strtrim(iarray,2)+') SET FOCUS '+string( z_results[iarray-1,1], format='(F5.2)')
endfor
banner, "*****************************", n=1


end
