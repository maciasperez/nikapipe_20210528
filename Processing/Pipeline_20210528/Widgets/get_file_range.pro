
pro get_file_range, file, x1, x2

x1 = 0
x2 = 1e6 ; place holder

done =0 
if strupcase(file) eq strupcase("A_2013_01_15_17h28m24_0005_I.fits") then begin
   x1 = 200
   x2 = 8500
   done = 1
endif

if (strupcase(file) eq strupcase("A_2013_01_15_17h28m24_0005_I.fits")) or $
   (strupcase(file) eq strupcase("A_2013_01_16_10h01m05_0007_I.fits")) or $
   (strupcase(file) eq strupcase("A_2013_01_16_10h49m17_0012_I.fits")) or $
   (strupcase(file) eq strupcase("A_2013_01_16_12h01m47_0014_I.fits")) or $
   (strupcase(file) eq strupcase("A_2013_01_16_13h50m53_0015_I.fits")) or $
   (strupcase(file) eq strupcase("A_2013_01_16_14h35m28_0016_I.fits")) then begin
   ;; keep it all
   done = 1
endif


if done ne 1 then begin
   message, /info, ""
   message, /info, "Please update get_file_range"
   stop
endif

end
