

;+
;
; SOFTWARE: Real time analysis
;
; NAME: 
; focus_plot_fit
;
; CATEGORY: general, RTA
;
; CALLING SEQUENCE:
;          - focus_plot_fit, z_pos, flux, s_flux, z_opt, delta_z_opt,
;            fotransl, color=color, title=title, leg_txt=leg_txt,
;            position=position, noerase=noerase
; 
; PURPOSE: 
;        Auxillary function of nk_focus
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
;        - Aug. 10th, 2016: extracted from nk_focus for convenience, NP
;-
;================================================================================================

pro focus_plot_fit, z_pos, flux, s_flux, z_opt, delta_z_opt, fotransl, $
                    color=color, title=title, leg_txt=leg_txt, position=position, $
                    noerase=noerase, charsize=charsize

;;----------
;; Purpose:
;; Plots the flux as a function of the focus offset, fit for max and display result
;;----------

if not keyword_set(leg_txt) then leg_txt=''

fmt = "(F5.2)"
xra = minmax(z_pos) + [-0.2, 0.2]*(max(z_pos)-min(z_pos))
w = where( z_pos gt !undef, nw)
ploterror, z_pos[w], flux[w], s_flux[w], psym=8, $
           xra=xra, /xs, noerase=noerase, position=position, color=color, $
           xtitle='Focus '+strtrim(fotransl,2)+' (mm)', charsize=charsize

if nw ge 3 then begin
   zz = dindgen(100)/100.*(max(xra)-min(xra))+min(xra)
       
   templates = dblarr( 3, nw)
   for ii=0, 2 do templates[ii,*] = z_pos[w]^ii
   multifit, flux[w], s_flux[w], templates, ampl_out, fit, out_covar
   z_opt = -ampl_out[1]/(2.d0*ampl_out[2])
   delta_z_opt = abs(z_opt) * ( abs( sqrt(out_covar[1,1])/ampl_out[1]) + abs(sqrt(out_covar[2,2])/ampl_out[2]))
       
   oploterror, z_pos[w], flux[w], s_flux[w], psym=8, color=color, errcol=color
   oplot, zz, ampl_out[0] + ampl_out[1]*zz + ampl_out[2]*zz^2, color=250
   legendastro, leg_txt, box=0, textcol=color

   ;; Put out a warning if the fit is not a maximum
   if ampl_out[2] gt 0 then begin
      x = min(z_pos)
      y = min(flux-s_flux) 
      xyouts, x, y, "THE FIT RETURNS A MINIMUM", col=250, orientation=45
      xyouts, x+0.2*( max(z_pos)-min(z_pos)), y, "DO NOT APPLY THIS CORRECTION", col=250, orientation=45
      z_opt = !values.d_nan
   endif else begin
      legendastro, [strtrim(fotransl,2)+': '+num2string(z_opt)+" +- "+num2string(delta_z_opt)], $
                   /bottom, /right, box=0
   endelse
   
endif else begin
   message, "Less than three focus positions available to fit focus ?!"
endelse

end

