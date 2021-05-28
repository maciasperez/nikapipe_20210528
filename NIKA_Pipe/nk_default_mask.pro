;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_default_mask
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         nk_default_mask
; 
; PURPOSE: 
;        Generates a mask for decorrelation
; 
; INPUT: 
;        - param, info, grid
; 
; KEYWORDS:
;       - dist: distance to the center
;       - xcenter: x coordinates of the center
;       - ycenter: y coordinates of the center
;
; OUTPUT: 
;        - grid.mask_source
; 
; KEYWORDS:
;        - radius, xcenter, ycenter
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - April 08th, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;        - Sept. 25th, 2015: NP, changed dist keyword into radius to remove
;          ambiguity with "d ~= diameter"


pro nk_default_mask, param, info, grid, radius=radius, xcenter=xcenter, ycenter=ycenter
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_default_mask'
   return
endif
if not keyword_set(radius)  then radius  = param.mask_default_radius
if not keyword_set(xcenter) then xcenter = 0.d0
if not keyword_set(ycenter) then ycenter = 0.d0

grid.mask_source_1mm = 1
grid.mask_source_2mm = 1
w = where( sqrt( (grid.xmap-xcenter)^2 + (grid.ymap-ycenter)^2) lt radius, nw)
if nw ne 0 then begin
   grid.mask_source_1mm[w] = 0.d0
   grid.mask_source_2mm[w] = 0.d0
endif

end
