;+
;PURPOSE: Read a FITS map used to flag the source
;
;INPUT: The parameter, data and kidpar structures
;
;OUTPUT: The map
;
;LAST EDITION: 15/02/2014: creation(adam@lpsc.in2p3.fr)
;-

pro nika_pipe_extract_map_flag, path, type, relobe, map_guess, reso, max_noise=max_noise

  if not keyword_set(max_noise) then nsig_noise = 2 else nsig_noise = max_noise

  map_flux = mrdfits(path, 0, header, /sil)
  map_noise = mrdfits(path, 1, header, /sil)

  EXTAST, header, astr
  reso = astr.cdelt[1]*3600
  nx = astr.naxis[0]
  ny = astr.naxis[1]
  
  lnan = where(finite(map_noise) ne 1 or map_noise le 0, nlnan)
  if nlnan ne 0 then map_noise[lnan] = max(map_noise, /nan)*100
  map_noise = filter_image(map_noise, fwhm=relobe/reso, /all)
  map_flux = filter_image(map_flux, fwhm=relobe/reso, /all)
  
  case strupcase(type) of
     'SNR': begin
        map_guess = map_flux/map_noise
        fact = stddev(filter_image(randomn(seed,nx, ny), FWHM=relobe/reso, /all))
        map_guess /= fact
     end
     'FLUX': begin
        ln = where(map_noise gt nsig_noise*min(map_noise,/nan), nln)
        if nln ne 0 then map_flux[ln] = 0
        map_guess = map_flux
     end
  endcase
  
  return
end
