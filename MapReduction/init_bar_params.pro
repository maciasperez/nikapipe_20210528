; Extracted from Marc-Antoine Miville-Deschenes's library

pro init_bar_params

MAMDLIB = {X_THICK:1.0, $      ; thickness of plot axis in device=X
           PS_THICK:4.0, $     ; thickness of plot axis in device=PS
           SCALE:0., $
           PS_SIZEX:0., $
           PS_SIZEY:0., $
           cXSIZE:0., $
           cYSIZE:0., $
           PS_FONT:'Helvetica', $
           DEVICE:'X', $
           COLTABLE:39, $
           TOP:254, $
           BACKGROUND:255, $           
           COLOR:0}
defsysv, '!MAMDLIB', MAMDLIB

IMAFFI = {cadrenu:0, $
          rebin:1., $
          charsize:1.}
defsysv, '!IMAFFI', IMAFFI

BAR = {thickbar:0.01, $
       ticklen:0.01, $
       dxbar:0.01, $
       dybar:0.0, $
       pleg:0.005, $;-0.01, $ ; 0.02, $
       charsize:1.0, $
       orientation:0., $
       alignement:0.5, $
       fraction: 1.0, $
       format:'(E9.2)'}
defsysv, '!BAR', BAR

end
