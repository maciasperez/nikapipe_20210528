
pro nk_shear_rotate_sub, beam, gridnx, gridny, theta_deg, beam_theta

if abs(theta_deg) gt 45.d0 then begin
   message, /info, "abs(theta_deg) = "+strtrim(theta_deg,2)+" is larger than the allowed maximum of 45d0"
   beam_theta = !values.d_nan
   stop
endif

theta = theta_deg*!dtor

a =  tan(theta/2.)
b = -sin(theta)

ii = dcomplex(0,1.)

;; 1st Xshear
gx = dblarr(gridnx,gridny)

u = dblarr( gridnx)
if (gridnx mod 2) eq 0 then begin
   n1 = gridnx
endif else begin
   n1 = gridnx + 1
endelse
for k=0, n1/2-1 do u[k] = k/double(gridnx)
for k=n1/2, gridnx-1 do u[k] = (k-gridnx)/double(gridnx)

for iy=0, gridny-1 do begin
   gx[*,iy] = fft( exp(-2.d0*!dpi*ii*a*u*(iy-gridny/2)) * fft( beam[*,iy],/double,/inv), /double)
endfor

;; 2nd Yshear
gyx = dblarr(gridnx,gridny)
u = dblarr( gridny)
if (gridny mod 2) eq 0 then begin
   n1 = gridny
endif else begin
   n1 = gridny + 1
endelse
for k=0, n1/2-1 do u[k] = k/double(gridny)
for k=n1/2, gridny-1 do u[k] = (k-gridny)/double(gridny)

for ix=0, gridnx-1 do begin
   gyx[ix,*] = fft( exp(-2.d0*!dpi*ii*b*u*(ix-gridnx/2)) * fft( gx[ix,*],/double,/inv), /double)
endfor

;; 3rd shear
beam_theta = dblarr(gridnx,gridny)
u = dblarr( gridnx)
if (gridnx mod 2) eq 0 then begin
   n1 = gridnx
endif else begin
   n1 = gridnx + 1
endelse
for k=0, n1/2-1 do u[k] = k/double(gridnx)
for k=n1/2, gridnx-1 do u[k] = (k-gridnx)/double(gridnx)

for iy=0, gridny-1 do begin
   beam_theta[*,iy] = fft( exp(-2.d0*!dpi*ii*a*u*(iy-gridny/2)) * fft( gyx[*,iy],/double,/inv), /double)
endfor

end
