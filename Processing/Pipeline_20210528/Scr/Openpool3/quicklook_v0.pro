
;; Check opacities
png=1

proj_list = ['161_14', '180_14', '181_14']
wind, 1, 1, /free, /large
outplot, file='opacitives_161_180_181', png=png, ps=ps
!p.multi=[0,1,3]
for iproj=0, n_elements(proj_list)-1 do begin
   spawn, "ls "+!nika.plot_dir+"/"+proj_list[iproj]+"/*/MAPS_1mm_2015*fits", list_1mm

   nfiles = n_elements(list_1mm)-1
   tau1mm_res = dblarr(nfiles)
   tau2mm_res = dblarr(nfiles)
   for ifile=0, nfiles-1 do begin
      m = mrdfits( list_1mm[ifile], 4, h)
      print, ""
      tau1mm_res[ifile] = m.TAU_240GHZ_AVG
      tau2mm_res[ifile] = m.tau_140GHZ_avg
   endfor

   plot, tau1mm_res, title='Tau', /xs
   oplot, tau1mm_res, col=70
   oplot, tau2mm_res, col=250
   legendastro, ['1mm', '2mm'], col=[70,250], box=0
endfor
!p.multi=0
outplot, /close

end

