;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_get_median_common_mode
;
; CATEGORY: toi processing, subroutine of nk_get_cm
;
; CALLING SEQUENCE:
;
; 
; PURPOSE: 
;        Derives a median common mode from all the input kids dealing
;with the mask and the flags
; 
; INPUT:
;        - param, info, toi, flag, off_source, kidpar
; 
; OUTPUT: 
;        - common_mode: median common mode on samples outside the mask
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Apr. 17th, 2018: NP

pro nk_get_median_common_mode, param, info, toi, flag, off_source, kidpar, common_mode, $
                               nkids_in_cm
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_get_median_common_mode'
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

;; backup original
toi_copy = toi
nsn      = n_elements( toi[0,*])
nkids    = n_elements( toi[*,0])

kids_off_source = dblarr(nkids,nsn) + 1.d0

;; Mark masks and flags with NaN for "median"
w = where( off_source eq 0, nw)
kids_off_source[w] = 0.d0

;; w = where( off_source eq 0 OR flag ne 0, nw)
;; if nw ne 0 then begin
;;    toi_copy[w]        = !values.d_nan
;;    kids_off_source[w] = 0.d0
;; endif

;; Accept intersubscan samples in principle, otherwise there
;; are NaN's in the common mode.
;; These samples can be excluded from the decorrelation later on with
;; other pipeline options

wkeep = where( (off_source eq 1) and (flag eq 0 or flag eq 2L^11), nwkeep, compl=wout, ncompl=nwout)

case param.mydebug of
   4231: wkeep = where(                        flag eq 0 or flag eq 2L^11,  nwkeep, compl=wout, ncompl=nwout)
   4232: wkeep = where(                        flag eq 0,                   nwkeep, compl=wout, ncompl=nwout)
   4233: wkeep = where( (off_source eq 1) and (flag eq 0 or flag eq 2L^11), nwkeep, compl=wout, ncompl=nwout)
   4234: wkeep = where( (off_source eq 1) and (flag eq 0),                  nwkeep, compl=wout, ncompl=nwout)
;;; FXD 1May2021   else:print, ""
   else:
endcase

if nwout ne 0 then toi_copy[wout] = !values.d_nan

;; if param.interactive then begin
;;    if (!mydebug.subscan ge 5 and !mydebug.subscan le 7) and !mydebug.array eq 1 then begin
;;       nkids = n_elements(toi[*,0])
;;       nsn = n_elements(toi[0,*])
;;       r = dblarr(nkids)
;;       for i=0, nkids-1 do r[i] = total( float(finite(toi_copy[i,*])))/nsn
;;    endif
;; endif

;; Subtract the average of each toi outside the mask to have a first
;; correction of the offsets
;; toi_copy -= ( (dblarr(nsn)+1)##avg( toi_copy, 1, /nan))
;;
;; If i compute the median mode on toi_copy (accounting for off_source
;; and flags on the edges, the median mode will have NaN's on
;; the edges systematically and all will crash.
;; => Account for off_source and flags to derive a clean average, then
;; leave it to "median" to clean up the source and flags will prevent
;; the use of bad samples in the decorrelation later on.
;stop
;; toi_avg = (dblarr(nsn)+1)##avg( toi_copy, 1, /nan)
toi_avg = (dblarr(nsn)+1)##median( toi_copy, dim=2)
toi_copy = toi - toi_avg

;; Compute the median mode on finite samples
common_mode = median( toi_copy, dim=1)
nkids_in_cm = total( kids_off_source,1)

;; wind, 1, 1, /free, /large
;; !p.multi=[0,1,2]
;; plot, common_mode, /xs
;; plot, nkids_in_cm, /xs
;; !p.multi=0
;; stop



;; if param.interactive and (!mydebug.subscan ge 5 and !mydebug.subscan le 7) and !mydebug.array eq 1 then begin
;;    !p.multi=0
;;    wind, 1, 1, /free, /large
;;    my_multiplot, 1, 3, pp, pp1, /rev
;;    plot, common_mode, position=pp1[0,*], ytitle='common mode'
;;    plot, r, title="A"+strtrim(!mydebug.array,2)+", subscan "+strtrim(!mydebug.subscan), $
;;          position=pp1[1,*], /noerase, ytitle='r'
;;    stop
;; endif

end
