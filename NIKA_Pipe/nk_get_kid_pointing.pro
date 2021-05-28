
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_get_kid_pointing
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         nk_get_kid_pointing, param, info, data, kidpar
; 
; PURPOSE: 
;        Computes kids individual pointing in Ra and Dec
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the nika data structure
;        - kidpar: the kids strucutre
; 
; OUTPUT: 
;        - data.dra, data.ddec
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Apr 23rd, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;===============================================================================================

pro nk_get_kid_pointing, param, info, data, kidpar
;-

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   dl_unix, 'nk_get_kid_pointing'
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

nkids = n_elements(kidpar)

;;; HR: put back where it was previously, to prevent bug caused by undefined values
ofs_az = data.ofs_az ; leave data.ofs_oz untouched for safety
ofs_el = data.ofs_el ; leave data.ofs_el untouched for safety

;; Depending on PAKO's projection keyword, data.ofs_az and data.ofs_el
;; may be already Ra and Dec, so we need to rotate them back to (az,el) to
;; compute kid pointing in (az,el) and then, convert back to (ra,dec) if requested.
if strupcase(info.systemof) eq "PROJECTION" then begin

   if strtrim(strupcase(info.ctype1),2) eq "GLON" and $
      strtrim(strupcase(info.ctype2),2) eq "GLAT" then begin
      ;; the scan was in galactic coordinates, need to rotate them into
      ;; RADEC for the next coordinates rotations
;;      wind, 1, 1, /free, /large
;;      my_multiplot, 2, 2, pp, pp1, /rev
;;      plot, ofs_az, ofs_el, /iso, position=pp[0,0,*]
;;      oplot, [0], [0], psym=1, thick=2, col=250
;;      legendastro, 'Input raw ofs_az, ofs_el'

      euler, info.longobj + ofs_az/3600.d0, info.latobj + ofs_el/3600.d0, ra, dec, 2
      euler, info.longobj, info.latobj, ra_center, dec_center, 2
      ofs_az = (ra - ra_center)*3600.d0*cos(dec*!dtor)
      ofs_el = (dec-dec_center)*3600.d0

;;      plot, ofs_az, ofs_el, /iso, position=pp[1,0,*], /noerase
;;      oplot, [0], [0], psym=1, thick=2, col=250
;;      legendastro, 'Reconstructed Ra, Dec'
   endif

   ;; Convert the current data in ofs_az and ofs_el from radec
   ;; which they actually here if systemof == "projection"
   ;; into true azimuth and elevations.
   alpha = data.paral
   ;; ofs_az1  = -cos(alpha)*ofs_az - sin(alpha)*ofs_el
   ;; ofs_el   = -sin(alpha)*ofs_az + cos(alpha)*ofs_el

   ;; change sign of paral, dec 2018
   ofs_az1  = -cos(alpha)*ofs_az + sin(alpha)*ofs_el
   ofs_el   =  sin(alpha)*ofs_az + cos(alpha)*ofs_el
   
   ofs_az =  ofs_az1
endif

nsn = n_elements(data.toi[0,*])

;; Determine pointing toi
if param.lab eq 1 then begin
   
   ;; Need to center ofs_az and ofs_el for maps, at least
   ;; approximately
   w1 = where( kidpar.type eq 1, nw1)
   w = where( data.flag[w1[0]] eq 0, nw)
   
   if nw eq 0 then message, "no valid sample ?!"
   ofs_az -= avg( data[w].ofs_az)
   ofs_el -= avg( data[w].ofs_el)

   for ikid=0, nkids-1 do begin
      if (kidpar[ikid].type ne 0) and (kidpar[ikid].type ne 2) then begin
         data.dra[ikid]  = ofs_az - kidpar[ikid].nas_x
         data.ddec[ikid] = ofs_el - kidpar[ikid].nas_y
         if info.polar eq 2 then begin
            data.dra1[ikid]  = ofs_az - kidpar[ikid].nas_x1
            data.ddec1[ikid] = ofs_el - kidpar[ikid].nas_y1
         endif
      endif
   endfor

endif else begin

   case strtrim(strupcase(param.map_proj),2) of
      "AZEL": nk_nasmyth2azel, param, info, data, kidpar, ofs_az, ofs_el

      "NASMYTH": begin
         for ikid=0, nkids-1 do begin
            if (kidpar[ikid].type ne 0) and (kidpar[ikid].type ne 2) then begin
               azel2nasm, data.el, ofs_az, ofs_el, ofs_x, ofs_y
               ;; to match the new convention in parallactic angle,
               ;; daz, del
               dra  = -(kidpar[ikid].nas_x - ofs_x)
               ddec = -(kidpar[ikid].nas_y - ofs_y)
               
               data.dra[ikid]  = dra
               data.ddec[ikid] = ddec
               if info.polar eq 2 then begin
                  dra1  = ofs_x - kidpar[ikid].nas_x1
                  ddec1 = ofs_y - kidpar[ikid].nas_y1
                  data.dra1[ikid] = dra1
                  data.ddec1[ikid] = ddec1
               endif
            endif
         endfor
      end
      
      "RADEC":begin
         nk_nasmyth2azel,   param, info, data, kidpar, ofs_az, ofs_el
         nk_dazdel2draddec, param, info, data, kidpar

         ;; extra rotation if requested
         if abs( param.alpha_radec_deg) gt 0.d0 then begin
            dra       = cos(param.alpha_radec_deg*!dtor)*data.dra - sin(param.alpha_radec_deg*!dtor)*data.ddec
            data.ddec = sin(param.alpha_radec_deg*!dtor)*data.dra + cos(param.alpha_radec_deg*!dtor)*data.ddec
            data.dra = dra
         endif

         data.dra  += param.fpc_ra
         data.ddec += param.fpc_dec
      end

      "GALACTIC": nk_draddec2dglondglat, param, info, data, kidpar, ofs_az, ofs_el
   endcase
endelse

if param.cpu_time then nk_show_cpu_time, param

end
