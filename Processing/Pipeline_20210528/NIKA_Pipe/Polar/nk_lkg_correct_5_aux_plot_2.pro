

my_multiplot, 3, 3, pp, pp1, /rev, gap_x=0.1
!p.charsize = 0.6

;; Display correction kernels
imview, shift( abs( fft( i_kernel*mask, /double)), grid.nx/2, grid.ny/2), position=pp[0,0,*], /noerase, imr=imr_i_kernel
legendastro, 'fft(i_kernel*mask)', textcol=255
imview, shift( abs( fft( q_kernel*mask, /double)), grid.nx/2, grid.ny/2), position=pp[1,0,*], /noerase, imr=imr_q_kernel
legendastro, 'fft(q_kernel*mask)', textcol=255
imview, shift( abs( fft( u_kernel*mask, /double)), grid.nx/2, grid.ny/2), position=pp[2,0,*], /noerase, imr=imr_u_kernel
legendastro, 'fft(u_kernel*mask)', textcol=255

;; Angular power spectra
ipoker, i_kernel, grid.map_reso/60., k, pk_i_kernel, /rem, /bypass
ipoker, q_kernel, grid.map_reso/60., k, pk_q_kernel, /rem, /bypass
ipoker, u_kernel, grid.map_reso/60., k, pk_u_kernel, /rem, /bypass

ipoker, mask*i_kernel, grid.map_reso/60., k, pk_i_kernel_apod, /rem, /bypass
ipoker, mask*q_kernel, grid.map_reso/60., k, pk_q_kernel_apod, /rem, /bypass
ipoker, mask*u_kernel, grid.map_reso/60., k, pk_u_kernel_apod, /rem, /bypass

k *= !arcsec2rad/(2*!dpi)       ; into arcsec^-1
;; sigma_k = 1.d0/sqrt(4*!dpi*(!nika.fwhm_nom[0]*!fwhm2sigma)^2)

plot, k, pk_i_kernel, position=pp[0,1,*], xtitle='k', ytitle='P(k)', /noerase
oplot, k, pk_i_kernel_apod, col=70
w = where( pk_i_kernel gt max(pk_i_kernel)/20.)
oplot, k[w], pk_i_kernel[w], psym=8, syms=0.5
fit = linfit( k[w]^2, alog(pk_i_kernel[w]))
oplot, k, exp(fit[0])*exp(fit[1]*k^2), col=250
legendastro, ['I kernel', 'I kernel apod'], col=[!p.color,70]

plot, k, pk_q_kernel, position=pp[1,1,*], /noerase, xtitle='k', ytitle='P(k)'
oplot, k, pk_q_kernel_apod, col=150
legendastro, ['Q kernel', 'Q kernel apod'], col=[!p.color,150]

plot, k, pk_u_kernel, position=pp[2,1,*], /noerase, xtitle='k', ytitle='P(k)'
oplot, k, pk_u_kernel_apod, col=200
legendastro, ['U kernel', 'U kernel apod'], col=[!p.color,200]

plot,  k, pk_q_kernel/pk_i_kernel, position=pp[0,2,*], /noerase, xtitle='k', ytitle='P(k)'
oplot, k, pk_q_kernel/pk_i_kernel, col=150
oplot, k, pk_u_kernel/pk_i_kernel, col=200
if defined(taper) then begin &$
   oplot, k, taper*max(pk_q_kernel/pk_i_kernel), col=70 &$
   legendastro, ['Q/I (kernel) apod', 'U/I (kernel) apod', 'Taper (scaled)'], textcol=[150, 200, 70] &$
endif else begin &$
   legendastro, ['Q/I (kernel) apod', 'U/I (kernel) apod'], textcol=[150,200] &$
endelse

