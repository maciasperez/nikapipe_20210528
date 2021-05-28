;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_kid2kid_dist
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         nk_kid2kid_dist, kidpar
; 
; PURPOSE: 
;        Computes the matrix of relative distance between two kids
; 
; INPUT: 
; 
; OUTPUT: 
;     kid_dist_matrix
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - July, 4th, 2019
;-

pro nk_kid2kid_dist, kidpar, kid_dist_matrix, test=test

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_kid2kid_dist, kidpar, kid_dist_matrix"
   return
endif


nkids = n_elements(kidpar)
x0 = rebin( kidpar.nas_x#(dblarr(nkids)+1), nkids, nkids)
x1 = rebin( (dblarr(nkids)+1)#kidpar.nas_x, nkids, nkids)

y0 = rebin( kidpar.nas_y#(dblarr(nkids)+1), nkids, nkids)
y1 = rebin( (dblarr(nkids)+1)#kidpar.nas_y, nkids, nkids)

kid_dist_matrix = sqrt( (x0-x1)^2 + (y0-y1)^2)

;;===========================================================================================
if keyword_set(test) then begin
   kidpar = mrdfits(!nika.off_proc_dir+"/kidpar_N2R29_ref_baseline_BL.fits", 1)
   w1 = where( kidpar.type eq 1)
   kidpar = kidpar[w1]
   ntries = 10

   ;; Dummy way
   kid_dist_matrix = dblarr(nkids,nkids)
   t0 = systime(0,/sec)
   for itry=0, ntries-1 do begin
      for i=0, nkids-2 do begin
         for j=i+1, nkids-1 do begin
            kid_dist_matrix[i,j] = sqrt( (kidpar[i].nas_x - kidpar[j].nas_x)^2 + $
                                         (kidpar[i].nas_y - kidpar[j].nas_y)^2)
            kid_dist_matrix[j,i] = kid_dist_matrix[i,j]
         endfor
      endfor
   endfor
   t1 = systime(0,/sec)
   print, "dummy: t1-t0: ", (t1-t0)/ntries

   ;; Using "rebin"
   t2 = systime(0,/sec)
   for itry=0, ntries-1 do begin
      x0 = rebin( kidpar.nas_x#(dblarr(nkids)+1), nkids, nkids)
      x1 = rebin( (dblarr(nkids)+1)#kidpar.nas_x, nkids, nkids)
      
      y0 = rebin( kidpar.nas_y#(dblarr(nkids)+1), nkids, nkids)
      y1 = rebin( (dblarr(nkids)+1)#kidpar.nas_y, nkids, nkids)
      m = sqrt( (x0-x1)^2 + (y0-y1)^2)
   endfor

   t3 = systime(0,/sec)
   print, "rebin: t3-t2: ", (t3-t2)/ntries

   wind, 1, 1, /free, /large
   my_multiplot, 2, 1, pp, pp1, /rev
   imview, kid_dist_matrix, position=pp1[0,*]
   imview, m, position=pp1[1,*], /noerase
   print, minmax(m-kid_dist_matrix)
;; dummy: t1-t0:        3.6527468
;; rebin: t3-t2:      0.067689085
endif

end
