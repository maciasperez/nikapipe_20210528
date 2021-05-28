;+
;
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
;        nk_make_header_end
;
; CATEGORY: 
;        initialization
;
; CALLING SEQUENCE:
;        nk_make_header, param, grid
; 
; PURPOSE: 
;        Define the header on which to project the data
; 
; INPUT: 
;        - param: the parameter structure used in the reduction
;        - grid: the structure containing maps
; 
; OUTPUT: 
;        - param: the parameter structure used in the reduction with
;          filled header
; 
; KEYWORDS:
;
; SIDE EFFECT: Modify the param structure
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - 11/11/2014: creation Remi Adam
;-

pro nk_make_header_end, param, grid, header1mm, header2mm, astrometry

  astrometry = {naxis:[grid.nx, grid.ny], $
                cd:[[1.0,-0.0],[0.0,1.0]], $
                cdelt:[-1.0, 1.0] * grid.map_reso/3600.d0, $
                crpix:([grid.nx, grid.ny] - 1)/2.0 + 1, $ ;First pixel is [1,1]
                crval:[param.map_center_ra, param.map_center_dec], $
                ctype:['RA---TAN','DEC--TAN'],$ ;FAUX, c'est GLS normalement mais il me faut TAN
                latpole:90.d0, $
                longpole:180.d0, $
                pv2:[0.0,0.0]}

  ;;========== Create the header and put it in the param file
  mkhdr, header1mm, grid.map_I_1mm            ;get minimal header
  putast, header1mm, astrometry, equinox=2000 ;astrometry in header
  
  mkhdr, header2mm, grid.map_I_2mm            ;get minimal header
  putast, header2mm, astrometry, equinox=2000 ;astrometry in header
  
  ;;========== Add some usefull information
  if strlen(param.source) gt 0 then $
     SXADDPAR, header1mm, 'OBJECT', param.source, 'Name of the source', before='CTYPE1'
  if strlen(param.source) gt 0 then $
     SXADDPAR, header2mm, 'OBJECT', param.source, 'Name of the source', before='CTYPE1'
  SXADDPAR, header1mm, 'CAMERA', 'NIKA', 'Name of the instrument', before='CTYPE1'
  SXADDPAR, header2mm, 'CAMERA', 'NIKA', 'Name of the instrument', before='CTYPE1'
  SXADDPAR, header1mm, 'TELES', 'IRAM30m', 'Name of the telscope', before='CTYPE1'
  SXADDPAR, header2mm, 'TELES', 'IRAM30m', 'Name of the telscope', before='CTYPE1'
  SXADDPAR, header1mm, 'OBS_FREQ', '260 GHz', 'Frequency band', before='CTYPE1'
  SXADDPAR, header2mm, 'OBS_FREQ', '150 GHz', 'Frequency band', before='CTYPE1'

  ;;========== Put the header as one of the param structure
  ;;param.map_head_1mm = header1mm
  ;;param.map_head_2mm = header2mm
  
end
