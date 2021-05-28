function taux_model2, x, p, nkid = nkid, nscan = nscan, nam = nam
;
;p contains all fr0 values (nkid) then
; all fr2K coefficients (nkid), and then tau values (nscan)
; x contains all am tried (nam per scan) so x is nam*nscan
; y contains the absolute frequency of all the kids taken at the x values
;   there are nkid*nam*nscan values

if total( 1-finite(p)) ne 0 then return, !values.d_nan
;nkid = fstr.nkid
nkid2 = 2*nkid
;nscan = fstr.nscan
;nam = fstr.nam
ntot = nkid2+nscan-1  ; number of parameters

ptau = reform( replicate(1.D0, nam)#p[nkid2:ntot], nam*nscan) ;tau values
farr  = reform( replicate(1.D0, nam*nscan) # p[0:nkid-1], nkid*nam*nscan)
y = farr + $
    reform( (1.d0 - exp( - x*ptau))#(p[nkid:nkid2-1]*270.d0), $
            nkid*nam*nscan)
;;help, y

;; ;; New function
;; exp_x_ptau = 1.d0 + (-x*ptau) + (-x*ptau)^2/2 + (-x*ptau)^3/6.d0 + $
;;              (-x*ptau)^4/24.d0 + (-x*ptau)^5/120.d0 + (-x*ptau)^6/720.d0 + $
;;              (-x*ptau)^7/5040.d0 + (-x*ptau)^8/40320.d0
;; y = farr + reform( (1.d0-exp_x_ptau)#(p[nkid:nkid2-1]*270.d0), nkid*nam*nscan)
;; help, y
;; stop

return, y
                                                                   
end
