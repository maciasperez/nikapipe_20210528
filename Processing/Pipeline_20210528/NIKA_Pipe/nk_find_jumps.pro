;
;+
;=-----------------------------------------------------------------------------
; NAME:   nk_find_jumps
; PURPOSE:
;     Find jumps in NIKA2 data. Can find common glitches as well. Only the flags
;     are changed. So far flag the data as 2^21 for a glitch, 2^20 for a jump
;     the three arrays are processed independently
;     glitches are flagged only if appearing in common on several detectors
;     Jumps as well
; CATEGORY:
;     Reduction1D, flagging
; CALLING SEQUENCE:
;     nk_find_jumps, param, info,  data, kidpar
; INPUTS:
;     param, info, data, kidpar
; OPTIONAL INPUTS: None
; KEYWORD INPUTS : None
; OUTPUTS:
;     data.flag is modified, info is updated
; OPTIONAL OUTPUTS: None
; COMMON BLOCKS: None
; SIDE EFFECTS: None
; RESTRICTIONS: The detection is done independently on each array
; PROCEDURE CALLS:
;      glitch_find, interp_hole
; METHOD:
;      Use of glitch_find to find glitches and jumps (using the
;      derivative). Then look for common=synchronous glitches/jumps
;      over several detectors
; HISTORY:
;      24-08-2016 FXD 1.0 Start from find_jumps.pro in Labtools/FXD/N2R4
;=-----------------------------------------------------------------------------
;-
pro nk_find_jumps, param, info,  data, kidpar,  $
                   glitch_stat = glitch_stat,  jump_stat = jump_stat

IF N_PARAMS() LT 4 THEN BEGIN
   message, /info, 'Calling sequence:'
   print, '   nk_find_jumps, param, info, data, kidpar,   '
   print, '     glitch_stat = glitch_stat,  jump_stat = jump_stat'
   return
ENDIF
  nmax = 20000L                 ; max number of individual glitches
  ndaf = n_elements( data)
  scan_index = lindgen( ndaf)

  nlim = ndaf/3                      ; reasonable amount of valid data
;;   ndetglicommon = 30           ; at least 30 detectors must see the same impact
;;   k_glitch =  [10, 50, 10]     ; standard deglitch
;; ;k_glitch  =  0  ; 0 is no deglitching
;;   k_jump  =  [10, 200, 10]      ; parameters to remove jumps
;; ;k_jump  =  0                    ; default= don't remove jumps
;;   nsmoothju = 5                 ; smoothing used in jump detection

  k_glitch = param.k_glitch
  k_jump = param.k_jump
  ndetglicommon = param.ndetglicommon
  ndetjumpcommon = param.ndetjumpcommon
  nsmoothju = param.nsmoothju

  undef = -1.                   ; any value (not 0)
  flbdptg = 2L^11               ; bad pointing flag
  flgl = 2L^21  ; common glitch flag value
  flju = 2L^20  ; common jump flag value

  ntg = lonarr( 3)              ; counter of glitches
  ntcg = lonarr( 3)             ; counter of common glitches
  ntcj = lonarr( 3)             ; counter of common jumps
  
  nkid = n_elements( kidpar)
  if k_glitch[0] ne 0 then begin
     if (1-keyword_set( param.silent)) then  $
        print, 'Deglitch data with : ', string( k_glitch, format='(3I6)')

     for iarr= 0, 2 do begin
; iarr = 0
        jarr = iarr+1           ; first array name
        idet = where( kidpar.array eq jarr and kidpar.type eq 1, ndet)

        ncomjump = 0            ; default value
        comjump = -1            ; 
        gls = { jk:-1, index:-1L, height:0.0}
        glitch_stat = replicate( gls, 3, nmax) ; listing output

        fglicum = lonarr( ndaf)             ; cumulative number of flagged toi
        FOR jkid = 0, ndet-1 DO BEGIN
           signal = data.toi[ idet[ jkid]]
; Correct here missing data (NaN) and flagged into undef (except for
; bad pointing data which are kept in (between subscans)
           nanindex= where( finite( signal) NE 1 or $
                            (1B-(data.flag[ idet[ jkid]] eq flbdptg or $
                            data.flag[ idet[ jkid]] eq 0L)), n_nanindex)
           IF n_nanindex NE 0 THEN signal[ nanindex]= undef
           ndef = total( long( signal NE undef))
           IF ndef GE nlim THEN BEGIN ; it is worth looking for glitches
              sigint = interp_hole( signal, /simple, holedef = undef, /noextrapol)
              indinit = glitch_find( sigint, k_glitch[0], k_glitch[1], k_glitch[2]) 
              ind = -1
              IF indinit[0] NE (-1) THEN BEGIN
                 dind = shift( indinit, 1) - indinit
                 flag = (dind EQ -1)
;;; not working          flag = flag + shift( flag, 1)  ; mark as not glitches those following each other (jump)
                 good = where( flag NE 1, ngood)
                 IF ngood NE 0 THEN ind = indinit[ good]
              ENDIF 
              IF ind[0] NE (-1) THEN BEGIN 
                                ; NEW Enlarge glitch area
; For 2011 run, 3 points only seem needed
; FXD add 2 for safety
                 enlarge = ([ind-2, ind-1, ind, ind + 1, ind+2] > 0) < (ndaf-1)
                 enlarge = enlarge[ sort( enlarge)]
                 enlarge = enlarge[ uniq( enlarge)]
                 nind = n_elements( ind)
                 ;; daf[ enlarge].( itag + itoff)[ jkid] = undef ; La_undef()
                                ; Do not store info if it goes beyond nmax
                 fglicum[ enlarge] = fglicum[ enlarge] + 1
                 IF ntg[iarr] + nind LT  nmax THEN BEGIN 
                    glitch_stat[ iarr, ntg[iarr]: ntg[iarr] + nind-1].jk = $
                       idet[ jkid]
                    glitch_stat[ iarr, ntg[iarr]: ntg[iarr] + nind-1].index = $
                       reform( ind, 1, nind)
                    sigmed = median( sigint, (k_glitch[1] * 2)/2L + 1)
                    glitch_stat[ iarr, ntg[iarr]: ntg[iarr] + nind-1].height = $
                       reform( sigint[ ind] - sigmed[ ind], 1, nind)
                 ENDIF 
                 ntg[ iarr] = ntg[ iarr] + nind
              ENDIF             ; end of loop on good glitches
           ENDIF                ; end loop on enough data to look for glitches
        ENDFOR                  ; end loop on detector

; Flag all detectors if a fraction of good detectors are flagged
        glicommon = where( fglicum ge ndetglicommon,  nglicommon)
        ntcg[ iarr] = nglicommon
        if nglicommon ne 0 then begin
        if (1-keyword_set( param.silent)) then  $
                   print, nglicommon, $
                  ' samples are in the common glitch flagged area for Array : ' $
                  +strtrim( jarr, 2)
; Flag 21 (CAN BE CHANGED): 21 to be in accordance with documentation 
           for igl = 0, nglicommon-1 do $
              data[ glicommon[igl]].flag[ idet] = $
              data[ glicommon[igl]].flag[ idet] OR flgl
        endif else $
           if (1-keyword_set( param.silent)) then  $
              print, 'No common glitches for Array : ' $
                     +strtrim( jarr, 2)
     ENDFOR                     ; end loop on jarr
     nmaxgl = max( ntg) < nmax
     IF nmaxgl NE 0 THEN glitch_stat = glitch_stat[*, 0:nmaxgl-1] ELSE $
        glitch_stat = glitch_stat[*, 0]
     if (1-keyword_set( param.silent)) then  $
        print, ntg/5, $
            ' glitches were found on all the detectors (Ar1,2,3)'

                                ; A common glitch is flagged over 5
                                ; samples: divide by 5 the number of samples
     info.result_comm_gli_1 = ntcg[0]/5.
     info.result_comm_gli_2 = ntcg[1]/5.
     info.result_comm_gli_3 = ntcg[2]/5.
     info.result_comm_gli_1mm = (ntcg[0]+ntcg[2])/5.
     info.result_comm_gli_2mm = ntcg[1]/5.
     
  endif else begin
     if (1-keyword_set( param.silent)) then  $
             print, 'No deglitching'
     info.result_comm_gli_1 = -1
     info.result_comm_gli_2 = -1
     info.result_comm_gli_3 = -1
     info.result_comm_gli_1mm = -1
     info.result_comm_gli_2mm = -1
  endelse
  

;---------------------------------------------


  if k_jump[0] ne 0 then begin
; Find jumps in the signal
     if (1-keyword_set( param.silent)) then  $
        print, 'Jumps are looked for with: ', string( k_jump, format='(3I6)')
     jus = { jk:-1, index:-1}
     jump_stat = replicate( jus, 3, nmax) ; listing output
     ntj = lonarr(3)                   ; counter
     for iarr= 0, 2 do begin
        jarr = iarr+1           ; first array name
        idet = where( kidpar.array eq jarr and kidpar.type eq 1, ndet)
        FOR jkid = 0, ndet-1 DO BEGIN
           signal = data.toi[ idet[ jkid]] ; do it on deglitched data
; Correct here flagged data (NaN and bad, except for pointing) into undef
           nanindex= where( finite( signal) NE 1 or $
                            data.flag[ idet[ jkid]] eq flgl or $
                            (1B-(data.flag[ idet[ jkid]] eq flbdptg or $
                            data.flag[ idet[ jkid]] eq 0L)), n_nanindex)
           IF n_nanindex NE 0 THEN signal[ nanindex]= undef
           ndef = total( long( signal NE undef))
           IF ndef GE nlim THEN BEGIN ; it is worth looking for jumps
              sigint = interp_hole( signal, /simple, holedef = undef, /noextrapol)
; Detect a jump by finding a glitch in the derivative
              dsignal = deriv( sigint)
              ind = glitch_find( dsignal, k_jump[ 0], k_jump[ 1], k_jump[ 2])
;if idet[jkid] eq 2001 then stop
              IF ind[0] NE (-1) THEN BEGIN
                 nind = n_elements( ind)
; Strong masking (by nsmoothgl) in case of a jump
; Better check that it does not arise from a glitch
                 FOR ijump = 0, nind-1 DO BEGIN
                    doit = 0
                    ij = ind[ ijump]
                    ija = ij -1 > 0
                    ijb = ij + 1 < (ndaf-1)
                    IF (signal[ ij]  NE undef AND  $
                        signal[ ija] NE undef AND  $
                        signal[ ijb] NE undef AND  $
                        ija NE 0 AND ijb NE (ndaf-1)) THEN BEGIN 
                       IF ijump EQ 0 THEN doit = 1
; avoid consecutive (but erroneous) jump flagging
                       IF ijump GT 0 THEN $
                          IF ind[ ijump] NE ind[ ijump-1] + 1 THEN doit = 1

                       IF doit THEN BEGIN 
                                ; Do not store info if it goes beyond nmax
                          IF ntj[ iarr] LT  nmax THEN BEGIN 
                             jump_stat[ iarr, ntj[ iarr]].jk = idet[ jkid]
                             jump_stat[ iarr, ntj[ iarr]].index = ij
                          ENDIF 
                          ntj[ iarr] = ntj[ iarr] + 1
                       ENDIF    ; end of doit
                    ENDIF       ; end of test on signal
                 ENDFOR         ; end loop on jumps
              ENDIF             ; end case of existing jumps
           ENDIF                ; end case where there are enough data
        ENDFOR                  ; end loop on detectors


; Make TOI out of jumps common to several kids
        jcumul = fltarr( ndaf)
        IF ntj[ iarr] GT nmax THEN message,/info,'!!!! NOT ALL Jumps taken into account, change threshold'
        FOR ijump = 0, ntj[ iarr] < nmax -1 DO $
           jcumul[ jump_stat[ iarr, ijump].index ] = $
           jcumul[ jump_stat[ iarr, ijump].index] + 1
; Smooth does not work well, use Gaussian convol instead
        jcumul = gauss_smooth( jcumul, 5/2.35, kernel = kernel) * total( kernel)
        coju = where( jcumul GT ndetjumpcommon, ncoju)
; Need to eliminate adjoint index by finding local maxima
        IF ncoju GT 0 THEN BEGIN 
           djcumul = shift( jcumul, -1) - jcumul
           sc2beg = scan_index[0] + nsmoothju ; Force jumps to be well within scan
           sc2end = scan_index[ ndaf-1] - nsmoothju
           comjump = where( shift(djcumul, + 1) * djcumul LT 0 AND $
                            jcumul GT ndetjumpcommon AND $
                            scan_index GT sc2beg AND $
                            scan_index LT sc2end, ncomjump)
        ENDIF ELSE BEGIN
           comjump = -1
           ncomjump = 0
        ENDELSE
        ntcj[ iarr] = ncomjump
        IF ncomjump NE 0 THEN BEGIN
     if (1-keyword_set( param.silent)) then  $
        print, ncomjump, ' common jumps for Array : ' $
               + strtrim( jarr, 2)
           area_maxnojump = bytarr( ndaf)+1B
           IF ncomjump GT (15>long(6e-4*ndaf)) THEN $
              message,' Too many jumps !' ; stop here if too many jumps
           ;; jumptoi = fltarr( ncomjump, ndaf) ; not used anymore
           ;; FOR icoju = 0, ncomjump-1 DO BEGIN
           ;;    test = fltarr( ndaf)
           ;;    test[ comjump[ icoju]] = 1.
           ;;    jumptoi[ icoju, * ] = total(/cumul, test)
           ;; ENDFOR
           augm_list = [0, comjump, ndaf-1]
           maxnojump = max( shift( augm_list, -1)- augm_list, imax)

           ind_maxnojump = where( scan_index GT (augm_list[ imax]+2) $
                              AND scan_index LT (augm_list[ imax + 1]-3), $
                                      naux)
           IF naux NE 0 THEN area_maxnojump[ ind_maxnojump] = 0
                                ; Flag outside of area_maxnojump for the array
           bad = where( area_maxnojump eq 1, nbad)
           if nbad ne 0 then data[ bad].flag[ idet] = $
              data[ bad].flag[ idet] OR flju ; 20 is in accordance with documentation
           
           
        ENDIF ELSE begin
;           jumptoi = -1
           if (1-keyword_set( param.silent)) then  $
              print, 'No common jump for Array : ' $
                     + strtrim( jarr, 2)
        endelse


     ENDFOR                     ; end loop on jarr
     nmaxju = max( ntj) < nmax
     IF nmaxju NE 0 THEN jump_stat = jump_stat[ *, 0: nmaxju - 1] ELSE $
        jump_stat = jump_stat[*, 0]
     if (1-keyword_set( param.silent)) then  $
        print, ntj, $
               ' jumps were found on all the detectors (Ar1,2,3)'
; At this stage, jumps are just masked
     info.result_comm_jum_1 = ntcj[0]
     info.result_comm_jum_2 = ntcj[1]
     info.result_comm_jum_3 = ntcj[2]
     info.result_comm_jum_1mm = (ntcj[0]+ntcj[2])
     info.result_comm_jum_2mm = ntcj[1]
  ENDIF ELSE BEGIN
     if (1-keyword_set( param.silent)) then  $
        print, 'no jumps were looked for'
     info.result_comm_jum_1 = -1
     info.result_comm_jum_2 = -1
     info.result_comm_jum_3 = -1
     info.result_comm_jum_1mm = -1
     info.result_comm_jum_2mm = -1
  ENDELSE


  return
end
