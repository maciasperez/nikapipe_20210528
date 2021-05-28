;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_simu
;
; CATEGORY: general, simulation
;
; CALLING SEQUENCE:
;         nk_simu, param, info, data, kidpar
; 
; PURPOSE: 
;        This is the main procedure of the NIKA simulation pipeline
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the structure produced by nk_getdata that will be modified
;          during this routine
;        - kidpar: the usual kid database structure
; 
; OUTPUT: 
;        - data: tois, flags etc... will be modified depending on what happens
;          during the simulation
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - April 9th, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;-

pro nk_simu, param, info, data, kidpar

if info.status eq 1 then return
  
  
end
