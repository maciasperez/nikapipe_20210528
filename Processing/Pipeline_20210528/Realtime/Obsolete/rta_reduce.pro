

pro rta_reduce, day_in, scan_num, sn_min=sn_min, sn_max=sn_max, rf=rf, nopng=nopng, $
                noskydip=noskydip, diffuse=diffuse, slow=slow, $
                freefit=freefit, one_mm_only=one_mm_only, two_mm_only=two_mm_only, $
                focal_plane=focal_plane, numdet1=numdet1, numdet2=numdet2, check=check, no_acq_flag=no_acq_flag, $
                force=force, k_noise=k_noise, jump = jump, xsize = xsize, ysize = ysize;, antimb = antimb,  imbfits=imbfits

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, " rta_reduce, day_in, scan_num, sn_min=sn_min, sn_max=sn_max, rf=rf, nopng=nopng, $"
   print, "                noskydip=noskydip, diffuse=diffuse, slow=slow, $"
   print, "                freefit=freefit, one_mm_only=one_mm_only, two_mm_only=two_mm_only, $"
   print, "                focal_plane=focal_plane, numdet1=numdet1, numdet2=numdet2, check=check, no_acq_flag=no_acq_flag, $"
   print, "                force=force, imbfits=imbfits, k_noise=k_noise, antimb=antimb, jump=jump"
   return
endif

wd, /a
antimb  = 1
imbfits = 1

time0 = systime(0, /sec)

;; Ensure correct format for "day"
t = size( day_in, /type)
if t eq 7 then day = strtrim(day_in,2) else day = string( day_in, format="(I8.8)")

common_mode_radius = 30.

png      = 1 - keyword_set(nopng)
educated = 1 - keyword_set(freefit)

;; Determine which type of scan   
if keyword_set(imbfits) then begin
   nika_find_raw_data_file, scan_num, day, file, imb_fits_file
   a = mrdfits( imb_fits_file,0,hdr,/sil)
   obs_type = sxpar( hdr,'OBSTYPE',/silent)
endif else begin
   parse_pako, scan_num, day, pako_str
   obs_type = pako_str.obs_type
endelse

;; Launch the proper routine
case strupcase( strtrim(obs_type,2)) of
   "POINTING": pointing, day, scan_num, offsets1, offsets2, numdet1_in=numdet1, numdet2_in=numdet2, $
                         noskydip=noskydip, png=png, RF=RF, $
                         one_mm_only=one_mm_only, two_mm_only=two_mm_only, check=check, $
                         educated=educated, no_acq_flag=no_acq_flag, imbfits=imbfits, antimb = antimb,  $
                         jump = jump
   
   "FOCUS":focus, day, scan_num, numdet1=numdet1, numdet2=numdet2, f1, f2, common_mode_radius=common_mode_radius, $
                  noskydip=noskydip, png=png, param=param, RF=RF, $
                  sn_min=sn_min, sn_max=sn_max, no_acq_flag=no_acq_flag, force=force, imbfits=imbfits,  $
                  jump = jump,  antimb = antimb
   
   "LISSAJOUS": pointing_liss, day, scan_num, maps, bg_rms, png=png, ps=ps, param=param, $
                               one_mm_only=one_mm_only, two_mm_only=two_mm_only, $
                               noskydip=noskydip, RF=RF, $
                               sn_min=sn_min, sn_max=sn_max, $
                               educated=educated, focal_plane=focal_plane, $
                               check=check, $
                               no_acq_flag=no_acq_flag, slow=slow, diffuse=diffuse, $
                               imbfits=imbfits, force=force, k_noise=k_noise , antimb = antimb,  $
                               jump = jump
   
   "ONTHEFLYMAP": begin
      rta_map, day, scan_num, maps, bg_rms, png=png, ps=ps, param=param, $
               one_mm_only=one_mm_only, two_mm_only=two_mm_only, $
               noskydip=noskydip, RF=RF, $
               sn_min=sn_min, sn_max=sn_max, $
               educated=educated, focal_plane=focal_plane, $
               check=check, $
               no_acq_flag=no_acq_flag, slow=slow, diffuse=diffuse, $
               imbfits=imbfits, force=force, k_noise=k_noise, antimb = antimb,  jump = jump, $
               xsize = xsize, ysize = ysize
      save, maps, file='maps.save'
   end
   
   "DIY": skydip_new, day, scan_num, kidpar, png=png, RF=RF, no_acq_flag=no_acq_flag, force=force
   "TRACK" : message, /info, 'Do not reduce track'
   ELSE: message, /info, 'Unrecognized observation type ' + obs_type
end

nika_logbook, day

time1 = systime(0, /sec)
print, "total CPU time: ", time1-time0

end
