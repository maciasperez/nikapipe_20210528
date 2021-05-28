

;+
;
; SOFTWARE: Real time analysis
;
; NAME: 
; nk_focus
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
;        - June 4th, 2014: Nicolas Ponthieu
;-
;================================================================================================


;;==============================================================================================
pro nk_focus, scan, param=param, ref_det_1=ref_det_1, ref_det_2=ref_det_2, ref_det_3=ref_det_3, $
              raw_acq_dir=raw_acq_dir

check=1
scan2daynum, scan, day, scan_num

if not keyword_set(param) then begin
   nk_default_param, param
   param.decor_cm_dmin = 30.d0
   param.map_xsize     = 300.d0
   param.map_ysize     = 300.d0
   param.map_reso      = 4.d0
endif
if not keyword_set(info)  then nk_default_info, info

xml = 0 ; unchecked for now
nk_update_param_info, scan, param, info, xml=xml, raw_acq_dir=raw_acq_dir

;; init
ref_det = !nika.ref_det

if keyword_set(rf)          then param.math        = "RF"
if keyword_set(one_mm_only) then param.one_mm_only = 1
if keyword_set(two_mm_only) then param.two_mm_only = 1
if keyword_set(ref_det_1)   then ref_det[0] = ref_det_1
if keyword_set(ref_det_2)   then ref_det[1] = ref_det_2
if keyword_set(ref_det_3)   then ref_det[2] = ref_det_3

if not keyword_set(radius_far_kids)             then radius_far_kids             = 20.

if keyword_set(online) and keyword_set(imbfits) then begin
   message, /info, "Please do not set /online and /imbfits at the same time"
   return
endif

nk_find_raw_data_file, param.scan_num, param.day, file, imb_fits_file
param.file_imb_fits = imb_fits_file

;; Retrive focus information in the AntennaIMBfits
imbHeader = HEADFITS( param.file_imb_fits, EXTEN='IMBF-scan')
focusx_correction = double( sxpar( imbHeader, 'FOCUSX'))
focusy_correction = double( sxpar( imbHeader, 'FOCUSY'))
focusz_correction = double( sxpar( imbHeader, 'FOCUSZ'))

iext = 1
status = 0
p=0
pp=0
WHILE status EQ 0 AND iext LT 100 DO BEGIN
   aux = mrdfits( param.file_imb_fits, iext, haux, status = status, /silent)
   extname = sxpar( haux, 'EXTNAME')
   if strupcase(extname) eq "IMBF-ANTENNA" then begin
      if p eq 0 then begin
         string_fooffset = sxpar( haux, 'FOOFFSET')
         imbfits_mjd_list = aux[0].mjd
         p++
      endif else begin
         string_fooffset = [string_fooffset, sxpar( haux, 'FOOFFSET')]
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
   
   iext = iext + 1
endwhile

info.FOTRANSL = fotransl

;; 1st value of fooffset is usually not specified
w = where( strlen( strtrim(string_fooffset,2)) ne 0, nw)
string_fooffset  = string_fooffset[ w]
imbfits_mjd_list = imbfits_mjd_list[w]

param.source = info.object

;; Prepare output directory for plots and logbook
plot_output_dir = !nika.plot_dir+"/Logbook/Scans/"+scan
spawn, "mkdir -p "+plot_output_dir
param.plot_dir = plot_output_dir


focus_res = dblarr(3)
focus_err = dblarr(3)

nk_init_grid, param, info, grid

;;-------------------------------------------------------------------------------
;; Get data and process TOIs
nk_scan_preproc, param, info, data, kidpar, grid, xml=xml

;; unflag speed flags that are irrelevant here and that would throw
;; out valid samples
w1 = where(kidpar.type eq 1)
w11 = nk_where_flag( data.flag[w1[0]], 11, nflag=nflag)
if nflag ne 0 then data[w11].flag -= 2L^11

;; Derive limits of secondary mirror fixed postions and focus values
index = data.sample - data[0].sample
w4 = where( data.scan_st eq 4, nw4)
w5 = where( data.scan_st eq 5, nw5)
i_min = w4
i_max = intarr(nw4)
f_offset = dblarr(nw4)

for i=0, nw4-1 do begin
   w = where( w5 gt w4[i], nw)
   if i eq (nw4-1) and nw eq 0 then i_max[i] = max(index) else i_max[i] = min(w5[w])

   dt = imbfits_mjd_list - data[w4[i]].mjd
   w_lkv = where( dt eq max(dt[where(dt le 0)]))
   f_offset[i] = double( string_fooffset[w_lkv])
endfor

case strupcase( strmid( FOTRANSL, 0, 1)) of
   "X": focus = f_offset + focusx_correction
   "Y": focus = f_offset + focusy_correction
   "Z": focus = f_offset + focusz_correction
endcase

;; Derive common mode using kids far from the reference pixel
wind, 1, 1, /free, /large, iconic = param.iconic
outplot, file=plot_output_dir+"/plot_"+param.scan, png=param.plot_png, ps=param.plot_ps
my_multiplot, 3, 1, pp, pp_toi, ymin=0.5, ymax=0.95, gap_x=0.05
my_multiplot, 3, 1, pp, pp_fit, ymax=0.45, ymin=0.05, gap_x=0.05
nsn = n_elements(data)
time = data.mjd - data[0].mjd
info_tags = tag_names(info)
for iarray=1, 3 do begin

   ikid_ref = where(kidpar.numdet eq ref_det[iarray-1],nw)
   d = sqrt( (kidpar.nas_x-kidpar[ikid_ref].nas_x)^2 + (kidpar.nas_y-kidpar[ikid_ref].nas_y)^2)
   w_far = where( d ge param.decor_cm_dmin and kidpar.array eq iarray and kidpar.type eq 1, nw_far)
   if nw_far eq 0 then begin
      message, /info, ""
      message, /info, "radius_far_kids = "+strtrim(radius_far_kids,2)+" arcsec is too large to find pixels for the decorrelation"
      goto, ciao
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

;; Cross calibrate the reference kid on the common mode for 1
;; fixed position of the mirror, the constant (source flux) is
;; irrelevant, we care only about relative variations

   w = where( index ge i_min[0] and index le i_max[0], nw)
   if nw eq 0 then message, "proble here, no valid section to begin with"
   fit = linfit( common_mode[w], data[w].toi[ikid_ref])

;; subtract common mode from the ref. kid
   data.toi[ikid_ref] -= (fit[0] + fit[1]*common_mode)
   plot, time, data.toi[ikid_ref], position=pp_toi[iarray-1,*], /noerase, chars=0.6, $
         ytitle='Flux (AU)', xtitle='Sample index', title=param.scan
   make_ct, nw4, ct
   for i=0, nw4-1 do begin
      w = where( index ge i_min[i] and index le i_max[i], nw)
      if nw ne 0 then oplot, time[w], data[w].toi[ikid_ref], col=ct[i]
   endfor
   for ii=0, n_elements(imbfits_mjd_list)-1 do begin
      oplot, (imbfits_mjd_list[ii]-data[0].mjd)*[1,1], [-1,1]*1e10, line=2, col=70
   endfor
   legendastro, ['Array '+strtrim(iarray,2), $
                 'Kid '+strtrim(kidpar[ikid_ref].numdet,2)], box=0, /right

   flux        = dblarr(nw4)
   s_flux      = dblarr(nw4)
   for ipos=0, nw4-1 do begin
      w = where( index ge i_min[ipos] and index le i_max[ipos] and data.flag[ikid_ref] eq 0, nw)
      if nw eq 0 then begin
         message, /info, "No valid sample to measure the flux for subscan "+strtrim(ipos+1,2)
         flux[ipos]   = !values.d_nan
         s_flux[ipos] = !values.d_nan
      endif else begin
         flux[  ipos] = avg( data[w].toi[ikid_ref])

         ;; Approximate max-min = 3*sigma
         s_flux[ipos] = 0.33*(max( data[w].toi[ikid_ref]) - min( data[w].toi[ikid_ref]))
         
         ;; March, 22nd, 2016 (NP)
         ;; if finite(s_flux[ipos]) eq 0 then s_flux[ipos] = 0.
      endelse
   endfor
   
   ;; March, 22nd, 2016 (NP)                                                                                                 
   w = where( finite(flux) eq 1 and finite(s_flux) eq 1, nw)
   if nw lt 3 then begin
      message, /info, "Not enough valid point to fit a parabola"
   endif else begin

      ;; Focus plots and fits
      focus_plot_fit, focus[w], flux[w], s_flux[w], z_opt, delta_z_opt, fotransl, position=pp_fit[iarray-1,*], $
                      leg_txt=["A"+strtrim(iarray,2), "", 'Numdet '+strtrim(kidpar[ikid_ref].numdet,2)], $
                      /noerase
      focus_res[iarray-1] = z_opt
      focus_err[iarray-1] = delta_z_opt
      
      ww = where( strupcase(info_tags) eq "OPT_FOCUS_"+strtrim(iarray, 2),  nww)
      if nww ne 0 then info.(ww) = z_opt
      ww = where( strupcase(info_tags) eq "ERR_OPT_FOCUS_"+strtrim(iarray, 2),  nww)
      if nww ne 0 then info.(ww) = delta_z_opt
   endelse
   ciao:
endfor
outplot, /close

my_multiplot, /reset

;; Get useful information for the logbook
;; nika_get_log_info, param.scan_num, param.day, data, log_info, kidpar=kidpar
nk_get_log_info, param, info, data, log_info

log_info.source    = param.source
log_info.scan_type = info.obs_type

;; Print summary
case strupcase( strmid( FOTRANSL, 0, 1)) of
   "X": instr = ' /dir X'
   "Y": instr = ' /dir Y'
   "Z": instr = ''
endcase

print, ""
banner, "*****************************", n=1
print, "      FOCUS results"
print, ""
print, "To be used directly in PAKO (take the value of A1 in priority)"
for iarray=1, 3 do begin
   log_info.result_name[iarray-1]  = "Focus_A"+strtrim(iarray,2)+"_"+fotransl
   log_info.result_value[iarray-1] = string(focus_res[iarray-1],format='(F5.2)')
   if finite(focus_res[iarray-1]) then begin
      print, "Array "+strtrim(iarray,2)+": set focus "+string(focus_res[iarray-1],format='(F5.2)')+instr
   endif
endfor

;; Create a html page with plots from this scan
save, file=plot_output_dir+"/log_info.save", log_info
nk_logbook_sub, param.scan_num, param.day

;; Update logbook
nk_logbook, param.day

;; Write output .csv to gather focus results
nk_info2csv, info, plot_output_dir+"/photometry.csv"

end

