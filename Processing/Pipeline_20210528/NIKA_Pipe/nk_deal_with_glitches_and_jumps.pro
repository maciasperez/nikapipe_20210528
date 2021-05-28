;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_deal_with_glitches_and_jumps
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         nk_deal_with_glitches_and_jumps, param, info, data, kidpar
; 
; PURPOSE: 
;        detects glitches and jumps based on an average mode per box,
;        flag out and interpolates for all kids
; 
; INPUT: 
; 
; OUTPUT: 
;        - data.toi and data.flag are modified
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Aug. 2nd, 2019: NP
;
pro nk_deal_with_glitches_and_jumps, param, info, data, kidpar
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_deal_with_glitches_and_jumps'
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

w1 = where( kidpar.type eq 1, nw1)
if nw1 eq 0 then begin
   nk_error, info, "no valid kid"
   return
endif

nsn = n_elements(data)
index = lindgen(nsn)
kernel = dblarr(param.glitch_width) + 1.d0/param.glitch_width
;save,  param, info, data, kidpar, file=!nika.preproc_dir+"/data_"+param.scan+"_11.save"
nk_get_one_mode_per_box, param, info, data.toi, data.flag, data.off_source, kidpar, common_mode_per_box
;save,  param, info, data, kidpar, file=!nika.preproc_dir+"/data_"+param.scan+"_12.save"

if param.interactive eq 1 then begin
   wind, 1, 1, /free, /large
   my_multiplot, 2, 10, pp, pp1, gap_x=0.05, gap_y=0.02, /rev
endif

info_tags = tag_names(info)
for ibox=0, n_elements(common_mode_per_box[*,0])-1 do begin
   wkbox = where( kidpar.acqbox eq ibox and kidpar.type eq 1, nwkbox)
   if nwkbox ne 0 then begin
      y = reform( common_mode_per_box[ibox,*])
      ;; Compare TOI's to their smoothed version to find outlyers
      y_smooth = convol(y, kernel, /edge_mirror)
      sigma = stddev( y-y_smooth)
      w = where( abs(y-y_smooth) gt param.glitch_nsigma*sigma, nw, compl=wgood)

      ;; to log for slurm*out
      if nw ne 0 then message, /info, "Found "+strtrim(nw,2)+" outlyers in box "+strtrim(ibox,2)

      if param.interactive eq 1 then begin
         xra = [3200,4200]
         if ibox eq 0 then title='glitch_width '+strtrim( long(param.glitch_width),2)+", "+$
                                 'glitch_nsigma '+strtrim( long(param.glitch_nsigma),2) else title=''
         
         plot, y, position=pp1[ibox,*], /noerase, chars=0.7, title=title, xra=xra, /xs
         legendastro, "box "+strtrim(ibox,2)+", A"+strtrim(kidpar[wkbox[0]].array,2)
         oplot, y_smooth, col=150
         if nw ne 0 then oplot, w, y[w], psym=8, syms=0.5, col=250
      endif
      if nw ne 0 then begin
         ;; take some margin for interpolations
         nmargin = 5            ; samples
         kk = dblarr(nmargin+1)+1.d0 & kk /= total(kk)
         toi_w = dblarr(nsn)
         toi_w[w] = 1.d0
         toi_w = convol( toi_w, kk, /edge_mirr)
         
         ;; update w
         w = where( toi_w gt 0., nw, compl=wgood)
         if param.interactive eq 1 then begin
            oplot, interpol( y[wgood], index[wgood], index), col=250
            stop
         endif
      endif

      if nw ne 0 then begin
         ;; flag out all KIDs of this box on these bad samples if any
         nk_add_flag, data, 0, wsample=w, wkid=wkbox
         wtag = where( strupcase(info_tags) eq strupcase("n_jump_or_glitch_flagged_samples_box"+strtrim(ibox,2)))
         info.(wtag) += nw
         xr = randomn( seed, nwkbox, nw)
         for ik=0, nwkbox-1 do begin
            ;; Interpolate the glitch or jump
            ;; DO NOT USE SPLINES IN INTERPOL, IT CREATES BOUNCES =>
            ;; enlarge a bit the margin around glitches and do a
            ;; simple linear interpolation.

            ;; plot, data.toi[wkbox[ik]], xra=xra
            ;; oplot, wgood, data[wgood].toi[wkbox[ik]], psym=1, col=150
            ;; oplot, w, data[w].toi[wkbox[ik]], psym=8, syms=0.5, col=250
            ;; oplot, interpol( data[wgood].toi[wkbox[ik]], index[wgood], index), col=70
            ;; stop

            data.toi[wkbox[ik]] = interpol( data[wgood].toi[wkbox[ik]], index[wgood], index)
            ;; Add constrained noise
            sigma = stddev( data.toi[wkbox[ik]] - convol( data.toi[wkbox[ik]], kernel, /edge_mirror))
            data[w].toi[wkbox[ik]] += xr[ik,*]*sigma
         endfor
      endif
   endif
endfor

if param.cpu_time then nk_show_cpu_time, param

end
