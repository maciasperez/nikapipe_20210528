
;; This script combines several scans into a final map and derives the
;; NEFD with two methods:
;; 1. Fitting the noise on the center flux as a function of the
;; cumulated observation time
;; 2. Measuring the NEFD on jackknife maps
;;-------------------------------------------------------------------

pro nefd, reset=reset, png=png, ps=ps, input_kidpar_file=input_kidpar_file, outplot_dir=outplot_dir, $
          method_num=method_num, nmc=nmc, quick=quick


  nefd_compute, reset=reset, png=png, ps=ps, $
                input_kidpar_file=input_kidpar_file, $
                outplot_dir=outplot_dir, method_num=method_num, $
                project_dir=project_dir, nmc=nmc, quick=quick

  nefd_plot_2, project_dir, png=png, ps=ps
  
end
