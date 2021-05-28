
;+
pro overplot_corr_contours, kidpar, choice, col=col
;-

box      = 0
subbands = 0
case choice of
   0: box=1
   1: subbands=1
   else:begin
      message, /info, "Choice must be 0 (box) or 1 (subbands)"
      message, /info, "Calling sequence:"
      dl_unix, 'overplot_corr_contours'
   end
endcase

;; Kidpar is assumed to be restricted to valid KIDS, the same as the
;; correlation matrix that has just been drawn.
nkids = n_elements(kidpar)

if box eq 1 then begin
   ;; outline acq boxes
   box0 = kidpar[0].acqbox
   for i=0, nkids-1 do begin
      if kidpar[i].acqbox ne box0 then begin
         oplot, [1,1]*i, [0,1d10], col=col
         oplot, [0,1d10], [1,1]*i, col=col
         box0 = kidpar[i].acqbox
      endif
   endfor
endif

if subbands eq 1 then begin
   subband = kidpar.numdet/80   ; int division on purpose
   b = subband[ uniq( subband, sort(subband))]
   b0 = subband[0]
   for i=0, nkids-1 do begin
      if subband[i] ne b0 then begin
         oplot, [1,1]*i, [0,1d10], col=col
         oplot, [0,1d10], [1,1]*i, col=col
         b0 = subband[i]
      endif
   endfor
endif

end
