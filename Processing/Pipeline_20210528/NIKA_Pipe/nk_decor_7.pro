

pro nk_decor_7, param, info, data, kidpar, grid, out_temp_data

nsn   = n_elements(data)
nkids = n_elements(kidpar)

;; Keep compatibility with old acquistions
nk_patch_kidpar, param, info, data, kidpar

;; Init the common mode output structure
out_temp_data = create_struct( "toi", data[0].toi*0.d0 + !values.d_nan)
out_temp_data = replicate( out_temp_data, n_elements(data))

;; @ Discard kids that are too uncorrelated to the other ones
if param.flag_uncorr_kid ne 0 then begin
   for i = 1, param.iterate_uncorr_kid do nk_flag_uncorr_kids, param, info, data, kidpar
endif

;; Define continuous sections of the scan per KID
for iarray=1, 3 do begin
   w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)

   toi_out  = data.toi[w1] + !values.d_nan
   flag_out = data.flag[w1]*0 + 2L^7
   
   if nw1 ne 0 then begin
      ;; to get nkids_in_cm for a start
      nk_get_median_common_mode, param, info, data.toi[w1], data.flag[w1], $
                                 data.off_source[w1], kidpar[w1], median_common_mode, nkids_in_cm
      
      ;; Detect continuous sections for the common mode on/off source
      enough_kids = long( nkids_in_cm ge param.nmin_kids_in_cm)
      num = 0
      section = intarr(nsn)
      for ii=1, nsn-1 do begin
         if enough_kids[ii] ne enough_kids[ii-1] then num++
         section[ii] = num
      endfor
      nsection = max(section)-min(section)+1

      ;; Loop on section
      for isec=0, nsection-1 do begin
         wsection = where( section eq isec and enough_kids eq 1, nwsection)
         if nwsection lt param.nsample_min_per_subscan then begin
            flag_out[*,wsection] = 2L^7
            message, /info, "isec, nwsection, param.nsample_min_per_subscan: "+$
                     strtrim(isec,2)+", "+strtrim(nwsection,2)+", "+strtrim(param.nsample_min_per_subscan,2)
         endif else begin
            nk_get_median_common_mode, param, info, $
                                       data[wsection].toi[w1], $
                                       data[wsection].flag[w1], $
                                       data[wsection].off_source[w1], $
                                       kidpar[w1], median_common_mode, nkids_in_cm_section
            
            template = reform( median_common_mode, [1, nwsection])
            
            ;; Decorrelate kid by kid
            for i=0, nw1-1 do begin
               ikid = w1[i]
               myd = sqrt( kidpar[ikid].nas_x^2 + kidpar[ikid].nas_y^2)
               if defined(ikid_plot) eq 0 then begin
                  if myd lt 30 then ikid_plot = ikid
               endif
               do_plot=0
               if defined(ikid_plot) then if ikid eq ikid_plot then do_plot=1
               
               wfit = where( enough_kids eq 1 and section eq isec and $
                             data.off_source[ikid] eq 1, nwfit)
               
               toi        = reform( data[wsection].toi[ikid], [1, nwsection])
               flag       = reform( data[wsection].flag[ikid], [1, nwsection])
               off_source = reform( data[wsection].off_source[ikid], [1, nwsection])

;               if kidpar[ikid].numdet eq 5 and min(data[wsection].subscan) ge 3 then stop

               nk_subtract_templates_4, param, info, toi, flag, off_source, kidpar[ikid], $
                                        template, out_temp1, status=status

               flag_out[wsection,i] = reform( flag, nwsection)
;;                if isec ge 2 then begin
;;                   help, toi, flag, off_source, template, out_temp1
;;                   stop
;;                endif
               if status eq 0 then begin
                  out_temp_data[wsection].toi[ikid] = reform( out_temp1, nwsection)
                  ;; Subtract template in data.toi: needed in nk_scan_reduce_1 for the derivation of nk_w8
                  toi_out[i,wsection] = data[wsection].toi[ikid] - reform( out_temp1, nwsection)
               endif
               
               if param.mydebug eq 0418 and do_plot then begin

                  wind, 1, 1, /free, /large
                  if defined(index) eq 0 then index = lindgen(nsn)

                  plot, kidpar[w1].nas_x, kidpar[w1].nas_y, /iso, $
                        psym=1, syms=0.5, position=[0.1, 0.7, 0.4, 0.95], /noerase
;                  oplot, kidpar[w1[block]].nas_x, kidpar[w1[block]].nas_y, psym=1, syms=0.5, col=250, thick=2
;                  stop
                  
                  my_multiplot, 1, 3, mpp, mpp1
                  yra =[0,max(nkids_in_cm_section)]*1.2
                  plot, nkids_in_cm_section, /xs, yra=yra, position=mpp1[0,*]
                  oplot, enough_kids*max(nkids_in_cm_section)*0.9, col=250
                  oplot, float(section)/max(section)*(yra[1]-yra[0]) + yra[0], col=70
                  legendastro, ['N valid kids off source', 'Enough kids', 'section'], $
                               col=[!p.color, 250, 70], line=0
                  yra = minmax( data.toi[ikid])
                  
                  plot, data.toi[ikid], /xs, /ys, yra=yra, position=mpp1[1,*], /noerase
                  loadct, /sil, 7
                  oplot, data.off_source[ikid]*(yra[1]-yra[0])*0.9 + yra[0], col=200
                  loadct, /sil, 39
                  oplot, float(section)/max(section)*(yra[1]-yra[0])*0.8 + yra[0], col=70
                  oplot, (data.flag[ikid] eq 0 or data.flag[ikid] eq 2L^11)*(yra[1]-yra[0])*0.7 + yra[0], col=150
                  legendastro, ['section'], col=70, line=0
                  loadct, /sil, 7 & legendastro, 'off_source', /bottom, col=200, line=0 & loadct, /sil, 39
                  oplot, [wfit], [data[wfit].toi[ikid]], psym=1, col=100, syms=0.5
                  
                  if status eq 0 then begin
                     oplot, wsection, out_temp1, col=200, thick=2
                     stop
                  endif
;;                  plot, [0, n_elements(data)-1], [0,nw1]/2., /nodata, position=mpp1[2,*], /noerase, /xs
;;                  oplot, [-1,1]*1d10, [1,1]*param.nmin_kids_in_cm, col=70
;;                  oplot, wsection, nn
;;                  legendastro, 'Nkids in block and cm'
;;                  stop
               endif
            endfor
         endelse
      endfor

;;       wind, 1, 1, /free
;;       plot, toi_out[0,*], yra=array2range(toi_out[where(finite(toi_out))])
;;       make_ct, nw1, ct
;;       for i=0, nw1-1 do oplot, toi_out[i,*], col=ct[i]
;;       oplot, section
;;       stop

      data.toi[w1]  = toi_out
      data.flag[w1] = flag_out
   endif
endfor

;; w = where( finite(out_temp_data.toi) eq 0, nw)
;; if nw ne 0 then data.flag[w] = 2L^7
;; message, /info, "exiting:"
;; stop

end

