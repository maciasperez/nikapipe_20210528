function readclfits, fitsfile

;+
; retourne le cl lu dans un fichier fits qu'il y ait la colonne de ell
; ou pas.
;-

cls = mrdfits(fitsfile,1)
n = n_tags(cls)
if (n eq 0) then print, "fichier vide..."
if (n eq 1) then cl=cls.(0)
if (n eq 2) then cl = cls.(1)
if (n gt 2) then print,"attention ! plusieurs cl !"

return, cl
end
