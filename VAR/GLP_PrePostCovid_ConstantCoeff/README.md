# Reused dependency — BVAR estimation

This folder is the Bayesian VAR estimation package we reuse to draw from the VAR
posterior. It is not developed for this paper. Please cite:

> Domenico Giannone, Michele Lenza and Giorgio E. Primiceri (2015), "Prior
> Selection for Vector Autoregressions", The Review of Economics and Statistics,
> 97(2), 436-451.

`bvarGLP.m` is the entry point. Our code calls it and then applies the paper's
own identification, decomposition and plotting. See `../../../../DEPENDENCIES.md`.
