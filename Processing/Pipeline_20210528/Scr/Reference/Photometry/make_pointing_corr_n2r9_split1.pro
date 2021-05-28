; See make_pointing_corr
pro make_pointing_corr_n2r9_split1, i

@make_pointing_corr_n2r9_add1.scr

nk_default_param, param
param.version = '2' ; '2' without correction, '3' after correction
param.project_dir = param.dir_save+ '/'+ source
param.do_opacity_correction = 2 
param.iconic = 1
param.map_proj = 'AZEL'
param.interpol_common_mode = 1
param.map_xsize = mapsize
param.map_ysize = mapsize
param.map_reso = mapreso
param.decor_method = 'common_mode_one_block'
param.decor_cm_dmin = 60.  ; 100 recommended by Nicolas 17/3/2017, 60 JMP
; minimum distance to the source for a sample to be declared "off
; source"
param.map_per_subscan = 1  ; do a map and pointing reduction per subscan
param.do_fpc_correction = 1 ; do a pointing correction
param.do_tel_gain_corr =  0 ; no gain elevation correction (TBD)
param.do_plot = 0 ; don't do plots.
param.silent = 1
param.math = 'PF'
nba = 15
nle = nscans/nba
istart = i*nle
iend = (i+1)*nle -1
if i eq (nba-1) then iend = (nscans-1)

for isc = istart, iend do begin
   nk_reset_filing, param,  scan_list[isc]
   wd, /all
   pa = param
   nk, param = pa, scan_list[ isc], /filing
endfor
;------------------------------------------------------
return
end
