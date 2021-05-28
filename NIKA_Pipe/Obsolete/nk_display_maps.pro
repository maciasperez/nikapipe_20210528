;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_display_maps
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         nk_display_maps, param, info, maps
; 
; PURPOSE: 
;        display maps present in the "maps" structure
;        hacked from nk_average_scans
; 
; INPUT: 
;        - param, info, maps
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
;        - Oct. 24th, 2014: NP
;-

pro nk_display_maps, grid, $
                     png=png, ps=ps, $
                     aperture_photometry=aperture_photometry, $
                     educated=educated, title=title, coltable=coltable, $
                     imrange_i1 = imrange_i1, imrange_q1 = imrange_q1, imrange_u1 = imrange_u1, $
                     imrange_i2 = imrange_i2, imrange_q2 = imrange_q2, imrange_u2 = imrange_u2,  $
                     imrange_ipol1=imrange_ipol1, imrange_ipol2=imrange_ipol2, $
                     imrange_pol_deg1=imrange_pol_deg1, imrange_pol_deg2=imrange_pol_deg2, $
                     image_only = image_only, charsize=charsize



  nk_display_grid, grid, $
                   png=png, ps=ps, $
                   aperture_photometry=aperture_photometry, $
                   educated=educated, title=title, coltable=coltable, $
                   imrange_i1 = imrange_i1, imrange_q1 = imrange_q1, imrange_u1 = imrange_u1, $
                   imrange_i2 = imrange_i2, imrange_q2 = imrange_q2, imrange_u2 = imrange_u2,  $
                   imrange_ipol1=imrange_ipol1, imrange_ipol2=imrange_ipol2, $
                   imrange_pol_deg1=imrange_pol_deg1, imrange_pol_deg2=imrange_pol_deg2, $
                   charsize=charsize
end

