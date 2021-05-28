; See make_pointing_corr
pro make_pointing_corr_n2r10_split2, i

sav = 'v2'
filout = '$NIKA_SAVE_DIR/Log_Iram_tel_Pointing_corr_' + sav + '.save'
restore, file = filout,  /verb
  
@make_pointing_corr_n2r10_add1.scr

nk_default_param, param
param.version = '3' ; '2' without correction, '3' after correction
param.project_dir = param.dir_save+ '/'+ source
param.do_opacity_correction = 2 
param.iconic = 1
param.map_proj = 'AZEL'
param.interpol_common_mode = 1
param.map_xsize = mapsize
param.map_ysize = mapsize
param.map_reso = mapreso
param.decor_method = 'common_mode_one_block'
param.interpol_common_mode = 1
param.decor_cm_dmin = 60.  ; 100 recommended by Nicolas 17/3/2017, 60 JMP
; minimum distance to the source for a sample to be declared "off
; source"
param.map_per_subscan = 1  ; do a map and pointing reduction per subscan
param.do_fpc_correction = 1 ; do a pointing correction
param.do_tel_gain_corr =  0 ; no gain elevation correction (TBD)
param.do_plot = 0 ; don't do plots.
param.math = 'PF'
nba = 15
nle = nscans/nba
istart = i*nle
iend = (i+1)*nle -1
if i eq (nba-1) then iend = (nscans-1)

for isc = istart, iend do begin
   nk_reset_filing, param,  scan_list[isc]
   delvarx, kidout, data, info
   ist=where(strmatch( corr.day+'s'+strtrim( corr.scannum,2), $
                       scan_list[isc]),nist)
   if nist eq 1 then begin
      param.fpc_az = corr[ ist[0]].fpaz
      param.fpc_el = corr[ ist[0]].fpel
   endif else stop, scan_list[isc]+' cannot be corrected'
   wd, /all
   nk, param = param, scan_list[ isc], /filing, $
       kidpar = kidout, info = info, data = data
endfor
;------------------------------------------------------
return
end
