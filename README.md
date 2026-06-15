# RPAToolkit.jl

A toolkit designed to calculate the bare susceptibility of a tight-binding lattice model using the TRIQS library, and perform the random phase approximation (RPA) to detect symmetry-broken instabilities (like superconductivity, magnetism, etc.).

## Installation

1. Install TRIQS and the [triqs_tprf](https://triqs.github.io/tprf/latest/install.html) package in a Python virtual environment or conda environment.
   On Ubuntu, precompiled packages are available. Otherwise, compilation instructions are [here](https://triqs.github.io/triqs/3.3.x/install.html). 
2. Add this Julia repository locally via the Package manager.
3. This package depends on the [TightBindingToolkit.jl](https://github.com/Toronto-Condensed-Matter-Theory/TightBindingToolkit.jl) for defining free Hamiltonians and lattices.

## Usage Overview

A typical RPA workflow involves three steps:
1. **Define the Free Model**: Use `TightBindingToolkit.jl` to define your unit cell, hopping parameters, and Hamiltonian.
2. **Define Interactions**: Define the interaction tensors (Hubbard U, Hund's J, inter-site V, etc.) that will drive the RPA instability.
3. **Run the Pipeline**: Create a YAML configuration file to link everything together, run the bare susceptibility calculation in TRIQS, and solve the RPA gap equation.

## Input Configuration (YAML)

Calculations are driven by a central YAML configuration file. Here is a breakdown of the required and optional inputs:

### General & Files
- `unitcell.julia`: Path to the Julia script/data containing the TightBindingToolkit model.
- `interactions`: Path to the Julia script/data defining the interaction tensors.
- `output`: Prefix for generated data files (e.g. `../Data/MyLattice`).
- `plots`: Prefix for generated plots.
- `triqs_environment`: The command/script used to activate your Python TRIQS environment.

### Physics Parameters
- `beta`: Inverse temperature ($1/k_B T$).
- `n_matsubara`: Number of Matsubara frequencies to use in the TRIQS bubble calculation.
- `directions`: A list of physical susceptibility channels to compute. (e.g., `[0, 1, 2, 3]` maps to `chi_NN`, `chi_XX`, `chi_YY`, `chi_ZZ`).
- `w_max` (Optional): Max frequency for the DLR mesh (defaults to 20.0).
- `dlr_err` (Optional): DLR mesh accuracy error threshold (defaults to 1e-12).

### Momentum Mesh & Path
- `k_size`: Defines the $N \times N \times 1$ Brillouin zone grid for the gap equation.
- `k_points`: Vertices for the 1D high-symmetry path. Can be exact coordinates or `TightBindingToolkit` high-symmetry labels.
  ```yaml
  k_points:
    - G
    - [0.666666666667, 0.333333333333, 0.0]
    - M2
  ```
- `k_points_labels` / `k_labels` (Optional): Custom LaTeX labels for the plotted path points. If omitted, labels are inferred automatically from `k_points`.

### Scan Variables (Chemical Potential / Fillings)
You can scan over a range of chemical potentials (`mus`) or charge densities (`fillings`). **`fillings` is strongly preferred.**
```yaml
fillings:
  min: 0.0
  max: 1.0
  n: 51
```
Or use explicit values:
```yaml
fillings:
  values: [0.2, 0.4, 0.6]
```
*Note: Legacy `mus` inputs are automatically resolved to `fillings` during the bare susceptibility stage.*

## Outputs & Data Structures

When running the `run_bare.jl` (or a higher-level script that triggers the TRIQS `run_bare.py` step), the following files are produced:

### `_runtime_input.yml`
A finalized version of your input YAML with explicitly resolved k-points, chemical potentials, and absolute paths to ensure calculations are completely reproducible.

### `.npz` Bare Susceptibility Files
For each `mu`/`filling` in the scan, a NumPy `.npz` archive is generated containing:
- **Metadata**: `beta`, `mu`, `filling`, `primitives`, `reciprocal`, `bandwidth`.
- **Momentum Spaces**: 
  - `ks`: The exact $N \times N$ coordinates of the full Brillouin zone grid.
  - `path`: The exact continuous coordinates along the 1D high-symmetry path.
  - `bands`: Free particle dispersions along the path.
- **Grid Susceptibilities** (`chi_NN`, `chi_XX`, etc.): The bare susceptibility tensors evaluated exactly on the full BZ grid (used for solving the gap equation).
- **Path Susceptibilities** (`chi_NN_path`, `chi_XX_path`, etc.): The bare susceptibility tensors evaluated *exactly* along the 1D path. These are essential for producing smooth, high-resolution plots without any interpolation blockiness.

### Downstream RPA (`.jld2`)
If using an external script to run the RPA equation (e.g. `run_RPA.jl`), the toolkit provides `combine_chis` to merge the `.npz` outputs into a structured `CombinedOutput` `.jld2` dictionary, which contains the bare susceptibility, RPA gap functions, critical interaction strengths ($\mathcal{I}_c$), and leading instability channels.
