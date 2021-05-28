
;; Compare measured fluxes on a list of calibrators to their expected
;; value
;; hacked from Labtools/NP/Dev/redo_secondary_calibrators_n2r4.pro
;;------------------------------------------------------------------------

pro check_calibrators, compute=compute, reset=reset

run = 'N2R4'

;; Update with the relevant data base file
db_file = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_Run16_v0.save"

;; Define output directory name as a function of the kidpar version
nickname = '20160312s284_v2_ApPhot_CMdmin100.00000'
input_kidpar_file = "kidpar_"+nickname+".fits"
aperture_phot = 1

;; set reset to 1 to recompute everything from scratch
if not keyword_set(reset) then reset = 0

;; set compute to 0 if all maps have already been reduced and you just
;; want to produce the output plot
if not keyword_set(compute) then compute = 0
if reset eq 1 then compute = 1

;; set to ps or png to 1 if you want to save a copy of the output plot
ps  = 0
png = 0

;; Demonstration only: replace by the relevant list of sources and
;; their associated fluxes
ref = create_struct( "source", 'a', "flux1", 0.d0, "flux2", 0.d0)
ref = replicate( ref, 3) ; 4)
ref.source = ['MWC349', 'CRL2688', 'NGC7027'];, 'Neptune']
ref.flux1  = [1.87, 3.03, 3.05];, 15.235]
ref.flux2  = [1.46, 0.83, 3.5];, 6.385]
source_list = ref.source

;; Decorrelation mask radius
cm_dmin = 40                    ; hard to go up to 100 for small maps...

;; If you want to use only one scan per source to save time, set to 1
only_one_scan = 0

;;==========================================================================================
parallel     = 1

project_dir = !nika.plot_dir+"/"+nickname
nk_default_param, param
param.map_xsize = 600.d0
param.map_ysize = 600.d0
param.map_reso = 2.d0
param.plot_ps = 1
param.plot_png = 0
param.flag_uncorr_kid = 0 ; 1
param.force_kidpar = 1
param.file_kidpar = input_kidpar_file
param.project_dir = project_dir
param.decor_cm_dmin = cm_dmin
method = "common_mode_kids_out"

outplot_dir = project_dir

nsources = n_elements(source_list)
restore, db_file
db_scan = scan

NoTauCorrect = 0
if only_one_scan eq 1 then parallel = 0
process      = 1
average      = 1
if compute eq 1 then begin
   for isource=0, nsources-1 do begin
      source = source_list[isource]
      
      ;; Scan_list
      w = where( strupcase( db_scan.object) eq strupcase( source) and $
                 db_scan.obstype eq "onTheFlyMap", nw)
      scan_list = strtrim(db_scan[w].day,2)+"s"+strtrim(db_scan[w].scannum,2)

      if only_one_scan eq 1 then begin
         message, /info, "fix me:"
         scan_list = scan_list[0]
      endif
      
      project_dir = outplot_dir+"/"+source+"_"+method
      param.project_dir = project_dir
      param.decor_method = method
      
      in_param_file = 'secondary_calibrator_'+source+"_param.save"
      save, param, file=in_param_file
      point_source_batch, scan_list, project_dir, source, $
                          reset=reset, process=process, average=average, $
                          parallel=parallel, method=method, $
                          input_kidpar_file=input_kidpar_file, $
                          in_param_file=in_param_file, NoTauCorrect=NoTauCorrect
   endfor
endif

;; Get results
flux     = dblarr(4,nsources)
err_flux = dblarr(4,nsources)
for isource=0, nsources-1 do begin
   source = source_list[isource]
   project_dir = outplot_dir+"/"+source+"_"+method
   nk_read_csv, project_dir+"/photometry_out_v1.csv", str
   nscans = n_elements(str.scan)-1 ; last line is the combination
   if aperture_phot eq 1 then begin
      flux[    0,isource] = str[nscans-1].aperture_photometry_i1
      flux[    1,isource] = str[nscans-1].aperture_photometry_i2
      flux[    2,isource] = str[nscans-1].aperture_photometry_i3
      flux[    3,isource] = str[nscans-1].aperture_photometry_i_1mm
      err_flux[0,isource] = str[nscans-1].err_aperture_photometry_i1
      err_flux[1,isource] = str[nscans-1].err_aperture_photometry_i2
      err_flux[2,isource] = str[nscans-1].err_aperture_photometry_i3
      err_flux[3,isource] = str[nscans-1].err_aperture_photometry_i_1mm
   endif else begin
      flux[0,isource] = str[nscans-1].flux_i1
      flux[1,isource] = str[nscans-1].flux_i2
      flux[2,isource] = str[nscans-1].flux_i3
      flux[3,isource] = str[nscans-1].flux_i_1mm
      err_flux[0,isource] = str[nscans-1].err_flux_i1
      err_flux[1,isource] = str[nscans-1].err_flux_i2
      err_flux[2,isource] = str[nscans-1].err_flux_i3
      err_flux[3,isource] = str[nscans-1].err_flux_i_1mm
   endelse
endfor

;; flux summary plot
if ps eq 0 then wind, 1, 1, /free, /large
outplot, file='Calibrators_'+strupcase(run)+'_'+nickname, png=png, ps=ps
my_multiplot, 2, 3, pp, pp1, /rev, ymargin=0.1, gap_y=0.07, xmargin=0.07, gap_x=0.05
xtickv = dindgen(nsources)/(nsources-1)
xra = [-0.1, 1.1]
xcharsize=0.7
nika_color  = 250
ref_color   = 70
nika_sym    = 8
ref_sym     = 4
ref_thick   = 2

;; A1 and A3 on the same plot
iarray = 1
yra1 = [0, max( [reform(flux, n_elements(flux))])]*1.2
ploterror, xtickv, flux[iarray-1,*], err_flux[iarray-1,*], $
           /xs, psym=nika_sym, ytitle='Flux (Jy)', xtickv=xtickv, xra=xra, yra=yra1, $
           xticks=nsources-1, xtickname=source_list, position=pp[0,iarray-1,*], /noerase, $
           xcharsize=xcharsize, title=strmid(param.file_kidpar,7,strlen(param.file_kidpar)-7-5)
oploterror, xtickv, flux[iarray-1,*], err_flux[iarray-1,*], $
            psym=nika_sym, col=nika_color, errcol=nika_color, thick=2
if aperture_phot eq 1 then legendastro, "Aperture Photometry", box=0, /right, /bottom
iarray=3
oploterror, xtickv, flux[iarray-1,*], err_flux[iarray-1,*], $
            psym=nika_sym, col=nika_color, errcol=nika_color
oplot, xtickv, ref.flux1, psym=ref_sym, col=ref_color, thick=ref_thick
legendastro, ['NIKA2 A1', 'NIKA2 A3', 'REF'], box=0, $
             psym=[nika_sym, nika_sym, ref_sym], col=[nika_color,nika_color,ref_color], $
             textcol=[nika_color,nika_color,ref_color]
legendastro, method, box=0, /right

;; Plot ratios
plot, xtickv, [0.5,2], $
      /xs, psym=nika_sym, xtickv=xtickv, xra=xra, $
      xticks=nsources-1, xtickname=source_list, position=pp[1,0,*], /noerase, $
      xcharsize=xcharsize, /nodata, /ys
legendastro, ['NIKA2/REF'], psym=[nika_sym], col=[ref_color], $
             box=0, textcol=[ref_color]
legendastro, 'A1 & A3', box=0, /right
oplot, [-2,2], [1,1], line=1
if only_one_scan eq 1 then xyouts, 0.5, 1, "only one scan", orient=45
oploterror, xtickv, flux[0,*]/ref.flux1, $
            err_flux[0,*]/ref.flux1, psym=nika_sym, col=ref_color, errcol=ref_color
oploterror, xtickv, flux[2,*]/ref.flux1, $
            err_flux[2,*]/ref.flux1, psym=nika_sym, col=ref_color, errcol=ref_color
avg_ratio = avg( [reform(flux[0,*]/ref.flux1), reform(flux[2,*]/ref.flux1)])
oplot, [-1,1], [1,1]*avg_ratio, col=ref_color
xyouts, 0.25, avg_ratio+0.01, strtrim( string(avg_ratio,form='(F4.2)'),2), col=ref_color

;; Fluxes
iarray = 2
ploterror, xtickv, flux[iarray-1,*], err_flux[iarray-1,*], $
           /xs, psym=nika_sym, ytitle='Flux (Jy)', xtickv=xtickv, xra=xra, $
           xticks=nsources-1, xtickname=source_list, position=pp[0,iarray-1,*], /noerase, $
           xcharsize=xcharsize
oploterror, xtickv, flux[iarray-1,*], err_flux[iarray-1,*], $
            psym=nika_sym, col=nika_color, errcol=nika_color, thick=2
oplot, xtickv, ref.flux2, col=ref_color, psym=ref_sym, thick=ref_thick
legendastro, ['NIKA2 A'+strtrim(iarray,2), 'REF'], box=0, $
             psym=[nika_sym,ref_sym], col=[nika_color,ref_color], textcol=[nika_color,ref_color]

;; Plot ratios
plot, xtickv, [0.5,3], $
      /xs, psym=nika_sym, xtickv=xtickv, xra=xra, $
      xticks=nsources-1, xtickname=source_list, position=pp[1,1,*], /noerase, $
      xcharsize=xcharsize, /nodata, /ys
legendastro, ['NIKA2/REF'], psym=[nika_sym], col=[ref_color], $
             box=0, textcol=ref_color
legendastro, 'A2', box=0, /right
oplot, [-2,2], [1,1], line=1
if only_one_scan eq 1 then xyouts, 0.5, 1, "only one scan", orient=45
oploterror, xtickv, flux[1,*]/ref.flux2, $
            err_flux[1,*]/ref.flux2, psym=nika_sym, col=ref_color, errcol=ref_color
avg_ratio = avg( [reform(flux[1,*]/ref.flux2)])
oplot, [-1,1], [1,1]*avg_ratio, col=ref_color
xyouts, 0.25, avg_ratio+0.01, strtrim( string(avg_ratio,form='(F4.2)'),2), col=ref_color

;; Combined 1mm
ploterror, xtickv, flux[3,*], err_flux[3,*], $
           /xs, psym=nika_sym, ytitle='Flux (Jy)', xtickv=xtickv, xra=xra, $
           xticks=nsources-1, xtickname=source_list, position=pp[0,2,*], /noerase, $
           xcharsize=xcharsize, yra=yra1, /ys
oploterror, xtickv, flux[3,*], err_flux[3,*], $
            psym=nika_sym, col=nika_color, errcol=nika_color
oplot, xtickv, ref.flux1, psym=ref_sym, col=ref_color, thick=ref_thick
legendastro, ['NIKA2 Combined 1mm A1&A3', 'REF'], box=0, $
             psym=[nika_sym, ref_sym], col=[nika_color,ref_color], textcol=[nika_color,ref_color]
outplot, /close


end
