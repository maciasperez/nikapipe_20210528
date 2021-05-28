
;; To produce a plot illustrating how we compute the map background
;; variance

scan = '20171022s165' ; sigma_boost = 0.9
scan = '20171031s75'
nk_default_param, param
param.commissioning_plot = 1
param.decor_method = 'common_mode_one_block'
nk, scan, param=param, grid=grid, info=info, kidpar=kidpar


end
