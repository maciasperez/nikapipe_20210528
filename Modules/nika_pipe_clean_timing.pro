pro nika_pipe_clean_timing, data,  verbose = verbose, use_B = use_B
; Use to have a regular mjd
; New method involves using int(mjd) and add utc which is finely resampled to
; microsec precision. 
; A sync by default. /use_B otherwise

; mjd and samples are sometimes wrong. Correct them
; Use only mjd and samples in data
facqapprox =  !nika.f_sampling 
; should be up to date (if read_nika_brute just before).

; Sometimes sample number is 0. Reestablish the proper value.
indzero = where( data.sample LT 1, nindzero)
IF nindzero NE 0 THEN BEGIN
  IF keyword_set( verb) THEN print, nindzero, ' zeroes in sample number'
  indnotzero = where( data.sample GE 1)
  data[ indzero].sample = $
     interpol( data[ indnotzero].sample, indnotzero, indzero)
  sa_zero = data[ indzero]
ENDIF


ind_notcontig = where( (data.sample-shift( data.sample, 1)) NE 1, $
                       nind_notcontig)
nind_notcontig = nind_notcontig -1  ; beginning is wrong
IF nind_notcontig NE 0 THEN BEGIN 
   ind_notcontig = ind_notcontig[1: * ]
   IF keyword_set( verb) THEN print, nind_notcontig, ' jumps in samples'
   sa_notcontig = data[ ind_notcontig].sample
 ENDIF ELSE BEGIN
   ind_notcontig = -1
 ENDELSE
; Don't do anything for these jumps, just hope they do not mess up the whole timeline
 if tag_exist( data, 'A_T_UTC') then utc =  data.a_t_utc else $
    utc = data.b_t_utc  ; second case should not happen (31-jan-2014)
if keyword_set( use_B) then utc = data.b_t_utc  ; for imbfits B box

; A is the master, B is the slave (in principle)
mjd= long( data.mjd)+ utc/86400D0
; Time is not well sampled so modify the time and convert it
; Time is locally inaccurate, do a linear regression
; Maybe a hiccup at change of day (TBC)

badmjd = where( (data.mjd- 55000) GT 9000.D0 OR $
                  (data.mjd- 55000) LT 600 OR data.scan lt 0.5, nbadmjd)  
IF nbadmjd NE 0 THEN mjd[ badmjd] = !undef


nmjd = n_elements(mjd)

if (nmjd gt nbadmjd+10) then begin  
; Estimate the zero mjd if an approximate frequency is used
   mjd0estim = mjd- (data.sample-data[0].sample) * $
               (1/facqapprox/3600.D0/24.)
   mjd0estim[ badmjd] = !undef
   bestmjd0 = la_median( mjd0estim)
   residue = 86400D0 * (mjd0estim-bestmjd0) ; seconds
   residue[ badmjd] = !undef
; histo_make, residue, /plot,/gauss,/print, minval = (-.1), maxval = .1
; This approx freq is accurate to 2e-4 Hz, so timing cannot drift by 1s.
   badmjd = where( abs( residue) GT 1., nbadmjd)
   IF nbadmjd NE 0 THEN mjd[ badmjd] = !undef
   goodmjd = where( mjd ne !undef)
; avoid glitches in mjd
   delvarx, slope
   plot_correl, double(data.sample), mjd, slope, a0, nostop = 1 , /noplot
   if defined( slope) then begin 
      mjd = data.sample * slope + a0
      facq = 1./ (median( deriv( data.sample)) * slope * 24. * 3600) ; acquisition frequency
; Need a more complex test
; For small duration tests, do nothing
      ftest = 1
      IF n_elements( data) GT 1000 THEN $
         ftest = abs( facq- facqapprox) LT 1 * sqrt( 1000./ n_elements( data))
      IF NOT ftest THEN  message, /info, '########   Timing pb for ' + strtrim( data[0].mjd, 2)
      data.mjd = mjd
   endif else begin
      facq = facqapprox
      message, /info, 'Case1: Not enough points to correct mjd'
   endelse

endif else begin
   
   message, /info, 'Case2: Not enough points to correct mjd'
   
endelse


return
end
