;;===============================================================
;;           Name: Epsilon Eri
;;           Run: 10
;;           Extended: yes
;;           Flux peak: a few mJy
;;           Target description: 
;;                Planetary disk
;;===============================================================
 
;;------- Properties of the source to be given here ------------------
source = 'Epsi_Eri'                              ;Name of the source
projid = '060-14'    ; official project id
version = 'v0.1'                                     ;Version of the analysis
name4file = STRJOIN(STRSPLIT(source,/EXTRACT),'_') ;Name without space but '_'
obstype = 'ONTHEFLYMAP'   ; give the observing type


;; ------- Scans --------------
;; scan_num1 = [079,080,081,082,083,084,085,086,087,088,089,090,091,092,093,094,095,096,097,098,099,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,116,117,118,119,120,121,122,123,124,125,126,127]
;; scan_num2 = [04,05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,55,56,60,61]
;; scan_num3 = [285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301,302,303,304,305,306,307,308,309,310,311,312,313,314,315,316,317,318,319,320,321,322,323,324,325,326,327,328,329,330,331,332,333,334,335,336]
;; scan_num4 = lindgen(121)+3
 

;; day1 = '20141112'+strarr(n_elements(scan_num1))
;; day2 = '20141113'+strarr(n_elements(scan_num2))
;; day3 = '20141115'+strarr(n_elements(scan_num3))
;; day4 = '20141116'+strarr(n_elements(scan_num4))


;; scan_num = [scan_num1, scan_num2,scan_num3,scan_num4]
;; day = [day1, day2,day3,day4]
;; New method
restore,'$NIKA_SOFT_DIR/Pipeline/Datamanage/Logbook/' + $
        'Log_Iram_tel_Run10_v0.save'
avoid_list = ['20141113s54', '20141113s55', '20141113s56', $
              '20141113s57', '20141113s58', '20141113s59', '20141116s2']
indscan = nk_select_scan( scan, source, obstype, nscans, avoid = avoid_list)
scan_num = scan[indscan].scannum
day = scan[indscan].day
print, nscans, ' scans found'
print, day +'s'+strtrim(scan_num,2)
if nscans gt 0 then print, 'Projects found: ', scan[ indscan].projid
;; Not working  because t21, test are mixed in with
;; projid = strtrim( scan[indscan[0]].projid, 2)
print, 'Project directory: ', projid

;;------- Prepare output directory for plots and logbook --------------
output_dir = !nika.plot_dir+'/'+projid+'/'+source
spawn, "mkdir -p "+output_dir

;;------- Init default param and change the ones you want to change ---
nika_pipe_default_param, scan_num, day, param
param.source = source
param.name4file = name4file
param.version = version
param.output_dir = output_dir

param.map.reso = 2
param.map.size_ra = 400
param.map.size_dec = 400

param.filter.apply = 'yes'
param.filter.freq_start = 1.0
param.filter.nsigma = 4

param.decor.method = 'COMMON_MODE_BLOCK'
param.decor.common_mode.d_min = 30.0
param.decor.common_mode.per_subscan = 'yes'
param.decor.common_mode.median = 'yes'
param.decor.common_mode.nsig_bloc = 1.0
param.decor.common_mode.nbloc_min = 40
param.fit_elevation = 'yes'
param.decor.baseline = [0,8]

param.w8.per_subscan = 'yes'
param.w8.dist_off_source = 30.0
param.zero_level.per_subscan = 'yes'
param.zero_level.dist_off_source = 30.0

param.flag.uncorr = 'yes'
param.flag.sat = 'yes'

add_source = {type:'DISK', $
              disk:{radius:25.0, $
                    pos:[0.0,0.0], $      ;Position source 2 [arcsec]
                    flux:[0.5, 0.5]}, $ ;Flux source [Jy]
              ps:{pos:[0.0,0.0],$
                  flux:[-0.5,-0.5]},$
              beam:[12.5, 18.5]}          ;Beam FWHM [arcsec]

;;------- Launch the pipeline
; clean =0 means the savesets are not erased (good for debugging)
nika_pipe_launch, param, map_combi, map_list, $
                  use_noise_from_map=1, $
                  check_flag_cor=1, check_flag_speed=1, meas_atm=1, plot_decor_toi=1, ps=1,  $ ; clean=1, $
                  noskydip=1, multi=2,$
                  add_source=0;add_source

;;------- Analysis after the pipeline
restore, output_dir+'/param_'+name4file+'_'+version+'.save', /verb
nika_anapipe_default_param, anapar

anapar.flux_map.relob.a = 10
anapar.flux_map.relob.b = 10
anapar.snr_map.relob.a = 10
anapar.snr_map.relob.b = 10

anapar.noise_meas.apply = 'yes'
anapar.noise_meas.jk.relob.a = 10
anapar.noise_meas.jk.relob.b = 10

;;------- Diffuse photometry
anapar.dif_photo.apply = 'yes'
anapar.dif_photo.nb_source = 1
anapar.dif_photo.method = 'coord'
anapar.dif_photo.per_scan = 'no'
anapar.dif_photo.coord[0].ra = [3.0,32.0,54.9]
anapar.dif_photo.coord[0].dec = [-9.0,27.0,29.0]
anapar.dif_photo.r0[0] = [40.0]
anapar.dif_photo.r1[0] = [60.0]

;;------- Radial profile
anapar.profile.apply = 'yes'
anapar.profile.method = 'coord'
anapar.profile.nb_pt = 50
anapar.profile.xr[0,*] = [0,60]
anapar.profile.coord[0].ra = [3.0,32.0,54.9]
anapar.profile.coord[0].dec = [-9.0,27.0,29.0]

anapar.ps_photo.apply = 'yes'
anapar.ps_photo.per_scan = 'yes'

nika_anapipe_launch, param, anapar

stop
end
