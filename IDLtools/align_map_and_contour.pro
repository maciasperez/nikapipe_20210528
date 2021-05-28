pro align_map_and_contour, map1, head1, map2, head2, map1_f, map2_f, head

;;------- Get astrometry from header
EXTAST, head1, astr1
EXTAST, head2, astr2

reso1_x = -astr1.cdelt[0]*3600L   ;resolution (arcsec)
reso1_y = astr1.cdelt[1]*3600L    ;resolution (arcsec)
reso2_x = -astr2.cdelt[0]*3600L   ;
reso2_y = astr2.cdelt[1]*3600L    ;
npt1_x = astr1.naxis[0]           ;pixel nb
npt1_y = astr1.naxis[1]           ;pixel nb
npt2_x = astr2.naxis[0]           ;
npt2_y = astr2.naxis[1]           ;
ref1 = astr1.crpix                ;reference pixel
ref2 = astr2.crpix                ;
coord1 = astr1.crval              ;coord of ref pixel (deg)
coord2 = astr2.crval              ;

;; Align on the data map center  
;;shift1 = [-1.0*cos(coord[1]*!pi/180.0),1.0]*(coord - coord1)*3600L   ;Shift with resp to the new map
;;shift2 = [-1.0*cos(coord[1]*!pi/180.0),1.0]*(coord - coord2)*3600L   ;
shift1 = [0.d0, 0.d0]
shift2 = [-1.0*cos(coord1[1]*!pi/180.0),1.0]*(coord1 - coord2)*3600L
  
offsc1_x = reso1_x*(ref1[0] - ((npt1_x-1)/2.0+1)) ;Shift between central pixel and reference pixel
offsc1_y = reso1_y*(ref1[1] - ((npt1_y-1)/2.0+1))
offsc2_x = reso2_x*(ref2[0] - ((npt2_x-1)/2.0+1))
offsc2_y = reso2_y*(ref2[1] - ((npt2_y-1)/2.0+1))
  
;;------- Define the grid
reso = abs(reso1_x)
npt = 2*long(max([npt1_x,npt1_y])/reso)+1 ; forced to be odd
fov = npt*reso
x1_f = replicate(1,npt)##((dindgen(npt)*reso - (fov/2.0-(npt1_x*reso1_x)/2.0 - shift1[0] - offsc1_x))/reso1_x)
y1_f = replicate(1,npt)# ((dindgen(npt)*reso - (fov/2.0-(npt1_y*reso1_y)/2.0 - shift1[1] - offsc1_y))/reso1_y)
x2_f = replicate(1,npt)##((dindgen(npt)*reso - (fov/2.0-(npt2_x*reso2_x)/2.0 - shift2[0] - offsc2_x))/reso2_x)
y2_f = replicate(1,npt)# ((dindgen(npt)*reso - (fov/2.0-(npt2_y*reso2_y)/2.0 - shift2[1] - offsc2_y))/reso2_y)

map1_f = interpolate(map1, x1_f, y1_f, missing=bg1)
map2_f = interpolate(map2, x2_f, y2_f, missing=bg2)
  
;;Make a header for the new map
mkhdr,head,map1_f                                                            ;get header typique
naxis = (size(map1_f))[1:2]                                                  ;Nb pixel along x and y
cd = [[1.0,-0.0],[0.0,1.0]]                                                  ;Rotation matrix but no rotation here
cdelt = [-1.0, 1.0] * reso/3600.0                                            ;Pixel size (ra along -1)
crpix = ((size(map1_f))[1:2] - 1)/2.0 + 1                                    ;Ref pixel (central, always odd nb)
crval = coord1                                                                ;ra dec of the ref pix
ctype = ['RA---TAN','DEC--TAN']                                              ;Projection type
ast = {naxis:naxis,cd:cd,cdelt:cdelt,crpix:crpix,crval:crval,ctype:ctype,$   ;astrometry
       longpole:180.,latpole:90.0,pv2:[0.0,0.0]}                             ;astrometry
putast, head, ast, equinox=2000, cd_type=0                                   ;astrometry in header


end


