
;; Larkin K., Oldfield M., Klemm H., 1997, Optics Communication, 139, 99-106

pro nk_larkin, beam, theta_deg, beam_theta, show=show

s = size(beam)

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_larkin, beam, theta_deg, beam_theta"
   return
endif
  
if abs(theta_deg) le 45.d0 then begin
   nk_larkin_sub, beam, s[1], s[2], theta_deg, beam_theta
endif else begin

   sgn = sign(theta_deg)
   ntheta = long( abs(theta_deg)/45.d0)
   rest = theta_deg - ntheta*sgn*45.d0
   
   junk = beam
   for i=0, ntheta-1 do begin
      nk_larkin_sub, junk, s[1], s[2], sgn*45.d0, beam_theta
      junk = beam_theta
   endfor
   
   nk_larkin_sub, junk, s[1], s[2], rest, beam_theta
endelse


;;================================================================================
;; Quick cross-check compared to rot, but remember that rot does
;; polynomial interpolations and it's not that accurate.
if keyword_set(show) then begin
   im = dblarr(256,256)
   im[64:64+128-1,64:64+128-1] = dist(128)

   nk_larkin, im, theta_deg, im_larkin
   
   wind, 1, 1, /free, /large
   my_multiplot, 2, 2, pp, pp1, /rev
   imview, im, title='Image', position=pp1[0,*]
   imview, rot(im,-theta_deg), title='IDL Rot(image)', position=pp1[1,*], /noerase
   imview, im_larkin, title='Larkin', /noerase, position=pp1[2,*]
   imview, im_larkin-rot(im,-theta_deg), title='larkin - IDL', position=pp1[3,*], /noerase, imr=[-1,1]
endif

end
