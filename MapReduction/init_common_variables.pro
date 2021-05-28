pro init_common_variables, w=w, matrix=matrix

  common ql_maps_common

if not keyword_set(w) then w = indgen( n_elements(kidpar))

beam_guess_done = 0
textcol  = 255
x_cross  = double( [!undef])
y_cross  = double( [!undef])
nkids    = n_elements(w)
kidpar   = kidpar[w]
coeff    = double( identity( nkids))
if strupcase(matrix) eq 'W2' then lambda = 2 else lambda = 1
;; nickname = nickname+"_"+strtrim(lambda,2)+'mm'
output_fits_file = nickname+"_FP.fits"

wplot_init = -1
ibol     = (min( where( kidpar.type eq 1)))[0]
;k_max    = max( where( kidpar.type ne 0))
k_max = n_elements(kidpar)
;; px       = long( sqrt(k_max)+1)
;; py       = px
;; my_multiplot, px, py, plot_position, plot_position1, gap_x=1e-6, gap_y=1e-6, xmargin=0.01, ymargin=0.01

my_multiplot, 1, 1, ntot=k_max, plot_position, plot_position1, gap_x=1e-6, gap_y=1e-6, xmargin=0.01, ymargin=0.01

kid_plot_position = dblarr( nkids, 4)

map_list_ref = map_list_ref_ab[ w, *,*]

map_list_out   = map_list_ref     ; init
map_list_out_0 = map_list_out
kidpar.x_pix = !undef
kidpar.y_pix = !undef

ibol = 0
jbol = 0
alpha_fp = 0.0d0
delta_fp = 10.0d0


xra_plot = xra
yra_plot = yra

w1  = where( kidpar.type eq 1, nw1)
w3  = where( kidpar.type eq 3, nw3)
w13 = where( kidpar.type eq 1 or kidpar.type eq 3, nw13)

checklist = 0
no_block = 1
wplot = where( kidpar.type eq 1)

end
