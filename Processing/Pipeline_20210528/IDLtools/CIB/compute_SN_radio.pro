PRO compute_SN_radio, A, Scut, S0, alpha, beta, Cell

; COMPUTE RADIO SHOT NOISE DEPENDING ON FLUX CUT FROM MARCO'S
; NOTE (PLANCK CONSISTENCY)

; Cell in Jy^2/sr (nuInu=cst)

deno = (Scut/S0)^alpha + (Scut/S0)^beta
DSN = 2 * A / deno

Cell = DSN * Scut

END
