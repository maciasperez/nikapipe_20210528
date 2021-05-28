pro clusterlensing, Ty, angsize, pixsize, dymap, Tmap, doplot=doplot

tildeTmap = clusterlens_gradtmap(Ty, angsize, pixsize)
Tmap = tildeTmap + dymap*180.*60./!dpi*Ty

;; quick check
nx=angsize/pixsize
vecy=(dindgen(nx+1)*pixsize - 0.5*angsize)
y=(dblarr(nx+1)+1d0)#vecy
x=transpose(y)

diffmap = Tmap-tildeTmap

print,"amplitude a r=",strtrim(string(y(nx/2.,nx/2.+1d/pixsize)),2)," arcmin : ",abs(diffmap(nx/2.,nx/2.+1d/pixsize))," microK_CMB"
print,"amplitude a r=",strtrim(string(y(nx/2.,nx/2.+3.3/pixsize)),2)," arcmin : ",abs(diffmap(nx/2.,nx/2.+3.3/pixsize))," microK_CMB"

;; plotting
if keyword_set(doplot) then begin      
   window,0
   dispim_bar,diffmap, /aspect,/nocont,title="lensed - unlensed",crange=[-10,10],xmap=x,ymap=y
   window,1
   nx=angsize/pixsize
   vecy=(dindgen(nx+1)*pixsize - 0.5*angsize)
   y=(dblarr(nx+1)+1d0)#vecy
   plot,y(nx/2.,*),tildeTmap(nx/2.,*),yrange=[-70.,70.],xrange=[-0.5*angsize,0.5*angsize],/xs,/ys
   oplot,y(nx/2.,*),tildeTmap(nx/2.,*)*0d,col=0,linestyle=2
   oplot,y(nx/2.,*),Tmap(nx/2.,*),col=50
   oplot,y(nx/2.,*),diffmap(nx/2.,*),col=250
endif

return
end 
