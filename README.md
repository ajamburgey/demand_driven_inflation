# Demand-Driven Inflation

This repository contains the replication code for Domenico Giannone and Giorgio E. Primiceri (2026), “Demand Driven Inflation,” *Brookings Papers on Economic Activity*.

## 1. Software requirements

- **MATLAB.** The code was most recently run with MATLAB R2025b on macOS Tahoe (v26.5.2).
- **Statistics and Machine Learning Toolbox.** This is the only MATLAB toolbox required; it provides functions such as `mvnrnd`, `gamrnd`, `ksdensity`, and `prctile` used in the Bayesian VAR and DSGE code.
- **Internet access** is required only to fetch data. Estimation and output scripts run offline using the data included in the repository.

No other installation is required. Third-party MATLAB packages are vendored in the repository; see Section 6.

## 2. Repository structure

The repository is organized into four folders:

```
Descriptive/   Descriptive charts of the price components used throughout the paper
VAR/           Bayesian SVAR analysis (sign-restricted demand/supply decomposition)
DSGE/          DSGE estimation and decompositions
Realtime/      Real-time forecast-error analysis
```

Each folder contains:

- Main scripts at its root (`Get*Data.m`, `Prepare*Data.m`, `Get*Draws.m`, `FigureN.m`, and `TableN.m`).
- `aux/`, which contains project-specific helper functions.
- `data/`, which contains raw series and prepared `.mat` files.
- `results/`, where figures and tables are saved.
- `draws/` (VAR and DSGE only), which contains cached posterior and prior draws.

Third-party packages are vendored alongside `aux/`, rather than inside it. Examples include `VAR/GLP_PrePostCovid_ConstantCoeff/`, `DSGE/gensys/`, and `DSGE/csminwel/`.

## 3. Reproducing the figures and tables

The prepared data and cached draws used by the paper are included in the repository. Run scripts from within their own folder, since they use paths relative to that folder.

The draw scripts estimate the relevant models and save posterior draws in `draws/*.mat`. These files contain the computationally expensive estimation results that the figure and table scripts reuse, so the figures and tables do not need to rerun the MCMC each time.

### VAR

The three VAR draw scripts estimate Bayesian VARs using the included data, impose the paper’s sign restrictions, and save accepted posterior draws for subsequent figures:

- `GetVARDraws.m` estimates the two-variable GDP-price VAR for the United States and euro area, identifying demand and supply shocks. It saves `draws/PQus_draws.mat` and `draws/PQea_draws.mat`, used by `Figure2.m`, `Figure3.m`, and `Figure12.m`.
- `GetVARDrawsHT.m` estimates the GDP, prices-ex-energy, transport-energy, and household-energy VAR. It identifies demand, non-energy supply, and two energy-supply shocks using sign and additional energy-price restrictions. It saves `draws/PQHTus_draws.mat` and `draws/PQHTea_draws.mat`, used by `Figure5.m` and `Figure13.m`.
- `GetVARDrawsRF.m` estimates the GDP, CPI, interest-rate, and primary-deficit VAR. It identifies monetary-policy, fiscal-policy, other-demand, and supply shocks. It saves `draws/PQRFus_draws.mat` and `draws/PQRFea_draws.mat`, used by `Figure6.m` and `Figure14.m`.

After the relevant draw script has run, execute `Figure2.m`, `Figure3.m`, `Figure5.m`, `Figure6.m`, `Figure13.m`, and `Figure14.m`. `Figure11.m` and `Figure12.m` run smaller estimations inline; `Figure12.m` also uses the baseline draws from `draws/PQus_draws.mat`.

`Figure3.m` additionally uses the included `data/SWcovid_quarterly.mat` file.

### DSGE

`GetDSGEDraws.m` estimates the DSGE model. It first refines the posterior mode, then runs an MCMC chain to obtain posterior parameter draws and computes the model objects and smoothed states needed by the analysis. It saves these results in `draws/DSGE_draws.mat`.

Run `GetDSGEDraws.m`, then run `Figure8.m`, `Table1.m`, and `Table2.m`. If `data/DSGEData.mat` does not exist, build it as described in Section 4 first.

### Realtime

Run `Figure9.m` and `Figure10.m`.

### Descriptive

Run `Figure1.m` and `Figure4.m` using the included prepared data.

## 4. Building the data from scratch

The repository includes prepared data, so these steps are optional. Each data source generally has two scripts:

- **`Get*Data.m`** fetches raw series and saves them as CSV files under `data/raw/`. It requires internet access.
- **`Prepare*Data.m`** reads those CSVs and performs chain-linking, quarterly aggregation, seasonal adjustment, and alignment before saving the `.mat` files used by the estimation and output scripts. It does not require internet access.

The main data pipelines are:

- **VAR:** `GetVARData.m` → `PrepareVARData.m` → `data/VARData.mat`.
- **VAR COVID factor:** `GetSWfactor.m` → `PrepareSWfactor.m` → `data/SWcovid_quarterly.mat`.
- **DSGE:** `GetDSGEData.m` → `PrepareDSGEData.m` → `data/DSGEData.mat`.
- **Realtime:** `GetRealTimeData.m` → `PrepareRealTimeData.m` → `data/CPIvintages.mat` and the real-time projections `.mat` file.
- **Descriptive:** `GetChartData.m` → `PrepareChartData.m` → `data/DataChart.mat`.

`VAR/GetVARData.m` and `Descriptive/GetChartData.m` support two data sources:

```matlab
SOURCE = 'haver';   % 'public' or 'haver'
```

- **`haver`** uses Haver Analytics and requires a valid `HAVER_KEY`.
- **`public`** uses free public sources: the BLS public API for US series and DBnomics, ECB, Eurostat, and FRED for the remaining series. A `BLS_KEY` can be supplied for the BLS API.

The corresponding `Prepare*Data.m` scripts have their own `SOURCE` switch, so fetching and preparation can be performed separately. DSGE and Realtime use free public sources only.

## 5. Known differences between the Haver and public EA data

The ECB and Haver euro-area HICP series are very similar but have slight differences. The public versions of the household-energy (COICOP 04.5) and transport-energy (COICOP 07.2.2) series are not seasonally adjusted; the code applies its own seasonal adjustment to these two series before using them.

For a detailed comparison, see [`VAR/data/HaverPublicComparison_EAEnergy.xlsx`](VAR/data/HaverPublicComparison_EAEnergy.xlsx). The workbook is generated by [`VAR/ComparePanels.m`](VAR/ComparePanels.m).

## 6. Third-party code

This repository vendors the following packages, unmodified except for removing unrelated functions:

- **`VAR/GLP_PrePostCovid_ConstantCoeff/`** — the Bayesian VAR package used for posterior draws. Please cite:

  > Domenico Giannone, Michele Lenza and Giorgio E. Primiceri (2015), “Prior Selection for Vector Autoregressions,” *The Review of Economics and Statistics*, 97(2), 436–451.

  See the package’s own `README.md` for details.

- **`DSGE/gensys/`** — Christopher Sims’ linear rational-expectations solver, used to solve the DSGE model. Please cite:

  > Christopher A. Sims (2002), “Solving Linear Rational Expectations Models,” *Computational Economics*, 20(1–2), 1–20.

- **`DSGE/csminwel/`** — Christopher Sims’ quasi-Newton optimizer, used to maximize the DSGE posterior.

All other code in this repository is original to this paper.
