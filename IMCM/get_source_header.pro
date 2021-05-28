
;+
pro get_source_header, source, header, param=param, info=info
;-

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   dl_unix, 'get_source_header'
   return
endif

if not keyword_set(param) then nk_default_param, param
if not keyword_set(info) then nk_default_info, info

case strupcase(source) of

   'PSZ2G144':begin
      info.longobj = 101.96042
      info.latobj  = 70.248056
      param.map_xsize = 10.*60.
      param.map_ysize = 10.*60.
      param.map_reso = 3.d0
   end

   ;; From a Header sent by Laurence
   'PSZ2G141':begin
      info.longobj = 70.275902
      info.latobj  = 68.220200
      param.map_xsize = 333*3.d0
      param.map_ysize = 333*3.d0
      param.map_reso = 3.d0
   end

   '3C286':begin
      info.longobj = 202.78458
      info.latobj  = 30.509167
      param.map_xsize = 12*60.
      param.map_ysize = 12*60.
   end
   
   "IRAS4A":begin
      info.longobj = 52.293875
      info.latobj  = 31.225250
      param.map_xsize = 12*60.
      param.map_ysize = 12*60.
   end

   "DR21OH":begin
      info.longobj = 309.75458
      info.latobj  = 42.380611
      param.map_xsize = 20*60.
      param.map_ysize = 20*60.
   end

   "B335":begin
      info.longobj=294.25371
      info.latobj=7.5691917
      param.map_xsize = 10*60.
      param.map_ysize = 10*60.
   end


   "PSZ2G160":begin
      info.longobj=186.74204
      info.latobj=33.546268
      param.map_xsize=12.*60.
      param.map_ysize=12.*60.
    end

   
   "JINGLE_D1":begin
      info.longobj = 215.65387
      info.latobj  = 0.046830556
      param.map_xsize = 15.*60.
      param.map_ysize = 15.*60.
   end

   "SATURN":begin
      info.longobj = 278.86886
      info.latobj  = -22.299933
      param.map_xsize = 1200.d0
      param.map_ysize = 1200.d0 
   end
   
    "COSMOS":begin
       info.longobj = 150.12005
;;        info.latobj  = 2.2917883
       info.latobj  = 2.2417884
       param.map_xsize = 37.*60.
       param.map_ysize = 45.*60.
    end

   "GOODSNORTH":begin
       info.longobj = 189.22372
       info.latobj  = 62.238220
       param.map_xsize = 24.*60.
       param.map_ysize = 24.*60.
   end

   "DeepField1":begin
       info.longobj = 1.89229279166676E+02
       info.latobj  = 6.22437758333365E+01
       param.map_xsize = 411 * 8.33333333333333E-04*3600
       param.map_ysize = 405 * 8.33333333333333E-04*3600
       param.map_reso = 8.33333333333333E-04*3600
   end

   "GN1200AVG":begin
       info.longobj = 1.89229279166676E+02
       info.latobj  = 6.22437758333365E+01
       param.map_xsize = 411 * 8.33333333333333E-04*3600
       param.map_ysize = 405 * 8.33333333333333E-04*3600
       param.map_reso = 8.33333333333333E-04*3600
   end

   ;; "GOODSNORTH":begin
   ;;     info.longobj = 189.22372
   ;;     info.latobj  = 62.238220
   ;;     param.map_xsize = 24.*60.
   ;;     param.map_ysize = 24.*60.
   ;; end

   "URANUS_BEAMMAP": goto, exit

   "G82":begin
      info.longobj = 313.19083
      info.latobj  = 41.518889
      param.map_xsize = 20.*60
      param.map_ysize = 20.*60
   end

   "L1498_1":begin
      info.longobj = 62.714583
      info.latobj  = 25.166111
      param.map_xsize = 15.*60
      param.map_ysize = 15.*60
   end

   "L1498_2":begin
      info.longobj = 62.714583
      info.latobj  = 25.166111
      param.map_xsize = 15.*60
      param.map_ysize = 15.*60
   end

   "L1498_3":begin
      info.longobj = 62.714583
      info.latobj  = 25.166111
      param.map_xsize = 15.*60
      param.map_ysize = 15.*60
   end

   "L1498":begin
      info.longobj = 62.714583
      info.latobj  = 25.166111
      param.map_xsize = 15.*60
      param.map_ysize = 15.*60
   end

   "PSZ2G091":begin
      info.longobj = 277.78353
      info.latobj  = 62.248093
      param.map_xsize = 20*60.
      param.map_ysize = 20*60.
   end

   'PSZ2G099':begin
      info.longobj = 213.69522
      info.latobj  = 54.783958
      param.map_xsize = 10*60.
      param.map_ysize = 10*60.
   end
   
   "ACTJ0215":begin
      info.longobj = 33.868157
      info.latobj  = 0.50889580
      param.map_xsize = 12.*60.
      param.map_ysize = 12.*60.
      param.map_reso = 3.
   end

   "PSZ2G183":begin
      info.longobj = 137.7032
      info.latobj  = 38.8357
      param.map_xsize = 12.*60.
      param.map_ysize = 12.*60.
      param.map_reso = 3.
   end
   
   "PSZ2-G046.1":begin
        info.longobj = 259.2742d0 
        info.latobj  = 24.0737d0
        param.map_xsize = 12.*60.
        param.map_ysize = 12.*60.
        param.map_reso = 3.
     end

   "L134":begin
      info.longobj    = 238.38792
      info.latobj     = -4.6405556
      param.map_xsize = 15.*60.
      param.map_ysize = 20.*60.
   end
   
   "L183":begin
      info.longobj = 238.54312083331399
      info.latobj  = -2.8414527777777199
      param.map_xsize = 30.*60.
      param.map_ysize = 30.*60.
   end
   
   "GRB1":begin
      info.longobj    = 54.505000
      info.latobj     = -26.946556
      param.map_xsize = 15.*60.
      param.map_ysize = 15.*60.
   end

   "GRB2":begin
      info.longobj    = 54.505000
      info.latobj     = -26.946556
      param.map_xsize = 15.*60.
      param.map_ysize = 15.*60.
   end

   "GRB3":begin
      info.longobj    = 54.505000
      info.latobj     = -26.946556
      param.map_xsize = 15.*60.
      param.map_ysize = 15.*60.
   end

   "G2":begin
      info.longobj = 189.33333
      info.latobj  = 62.341667
      param.map_xsize = 15.*60.
      param.map_ysize = 15.*60.
   end

   "HLS091828":begin
      info.longobj = 139.61917
      info.latobj  = 51.706472
      param.map_xsize = 20.*60.
      param.map_ysize = 20.*60.
   end

   "OMC-1":begin
      info.longobj = 83.810417
      info.latobj  = -5.3758333
      param.map_xsize = 20.*60.
      param.map_ysize = 20.*60.
   end

   "CX-TAU":begin
      info.longobj    = 63.699454
      info.latobj     = 26.802981
      param.map_xsize = 15.*60.
      param.map_ysize = 15.*60.
   end

   "GJ526":begin
      info.longobj    = 206.43550
      info.latobj     = 14.889056
      param.map_xsize = 20.*60
      param.map_ysize = 20.*60
   end

   "NEP-L":begin
      info.longobj    = 273.0125
      info.latobj     = 66.05
      param.map_xsize = 25.*60
      param.map_ysize = 25.*60
   end

   "HR8799":begin
      info.longobj    = 346.87021
      info.latobj     = 21.134002
      param.map_xsize = 18.*60
      param.map_ysize = 18.*60
   end
   
   "MWC349":begin
      info.longobj    = 308.18933
      info.latobj     = 40.660222
      param.map_xsize = 900
      param.map_ysize = 900
   end

   "NGC891":begin
      info.longobj    = 35.639167
      info.latobj     = 42.349167
      param.map_xsize = 2400
      param.map_ysize = 2400
   end
   "NGC6946":begin
      info.longobj    = 308.71792
      info.latobj     = 60.153889
      param.map_xsize = 1800
      param.map_ysize = 1800
   end
   "RXJ1347":begin
      info.longobj    = 206.87725
      info.latobj     = -11.755389
      param.map_xsize = 1800
      param.map_ysize = 1800
   end

   "CRAB":begin
      info.longobj = 83.633125
      info.latobj  = 22.014472
      param.map_xsize = 1200.
      param.map_ysize = 1200.
   end

   '0355+508':begin   ; FXD Thanks to NP
;   "0355+508":begin  ; is not accepted in the syntax
      info.longobj    = 59.873943
      info.latobj     = 50.963953
      param.map_xsize = 5600
      param.map_ysize = 5600
   end



   
   else: begin
      if param.new_method eq 'NEW_DECOR_ATMB_PER_ARRAY' then begin
         if  param.map_xsize lt 10 then begin
            message, /info, 'Provide map size as an input' ; the user has provided the info in param and info
            stop
         endif
      endif else begin
         message, /info, "Please update get_source_header for "+source
         stop
      endelse
      
   end
endcase

nk_param_info2astr, param, info, astr

;mkhdr, primaryHeader, '', /EXTEND
;fits_add_checksum, primaryHeader, /NO_TIMESTAMP
;mwrfits, 0, !nika.plot_dir+"/junk.fits", primaryHeader, /CREATE
mkhdr, header, dblarr( astr.naxis[0], astr.naxis[1]), /IMAGE
nk_putast, header, astr, equinox=2000, cd_type=0
;spawn, "rm -f "+!nika.plot_dir+"/junk.fits"

exit:
end


