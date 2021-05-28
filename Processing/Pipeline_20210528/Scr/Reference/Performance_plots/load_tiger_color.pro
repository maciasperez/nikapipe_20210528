;+
;
;  Load the color table for performance plots
;
;  on the model of Helene Roussel load_mapcol.pro
;
;  LP, July 2018
;-

pro load_tiger_color

x = [0, 5, 10, 20, 35, 45, 60, 65, 75, 80, 95, 115, 121, 140, 160, 180, 190, 200, 230, 240, 250, 255]

rgb = bytarr(256, 3)
rgb(x(21), *) = [255, 255, 255]   ;;; 255 white  
rgb(x(20), *) = [255,  20, 147]   ;;; 250 deep pink
;rgb(x(20), *) = [255,  50, 120]   ;;; 250 deep pink
rgb(x(19), *) = [230,  0, 255]    ;;; 240 fushia
rgb(x(18), *) = [200,  0, 255]    ;;; 230 mauve    
rgb(x(17), *) = [148,  5, 211]    ;;; 200 light purple 
;rgb(x(16), *) = [130,  5, 255]    ;;; 190 violet 
rgb(x(16), *) = [148,  0, 211]    ;;; 190 dark violet 
rgb(x(15), *) = [180, 0, 35]      ;;; 180 ecarlate
rgb(x(14), *) = [240, 30, 40]     ;;; 160 red
rgb(x(13), *) = [255, 90, 90]     ;;; 140 corail
rgb(x(12), *) = [255, 80, 0]      ;;; 125 orange
;;--------- vert
rgb(x(11), *) = [255, 220, 0]     ;;; 115 jaune
rgb(x(10), *) = [170, 235, 10]    ;;; 95  chartreuse
rgb(x(9), *) = [30, 190, 50]      ;;; 80  green
rgb(x(8), *) = [100, 255, 150]    ;;; 75  menthe
rgb(x(7), *) = [0, 180, 205]      ;;; 65  turquoise I
;rgb(x(6), *) = [100, 255, 230]    ;;; 60  turquoise II
rgb(x(6), *) = [80, 255, 250]    ;;; 60  turquoise II
;;--------- bleu
;rgb(x(5), *) = [0, 180, 250]      ;;; 45  sky blue
rgb(x(5), *) = [0, 191, 255]      ;;; 45  sky blue
rgb(x(4), *) = [30, 144, 255]     ;;; 35  dodger blue
rgb(x(3), *) = [0, 77, 255]       ;;; 20  blue
;; ------ vert-noir
rgb(x(2), *) = [25, 0, 205]       ;;; 10  deep blue
rgb(x(1), *) = [175, 175, 10]     ;;; 5   olive
rgb(x(0), *) = [35, 35, 35]       ;;; 0   black

for i = 0, 2 do rgb(*, i) = interpol(rgb(x, i), x, indgen(256))

tvlct, rgb
  
end

