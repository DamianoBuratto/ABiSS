
<!-- Centered Logo with Descriptive Alt Text -->
<p align="center">
  <img 
    src="ABiSS_logo.png" 
    alt="ABiSS Logo:  antibody-antigen going deep into energy well" 
    width="400" 
    height="auto" 
  />
</p>

<!-- Optional: Add a line break or divider -->
---

# ABiSS - Antibody in Silico Selection

**Design**: Damiano Buratto & Francesco Zonta  
**Author**: Damiano Buratto  
**Email**: damianoburatto@gmail.com  
**Version**: 0.6 (August 2023)  

---

## Description

ABiSS (Antibody in Silico Selection) is a computational tool designed for the selection and design of antibody sequences using molecular dynamics and energy minimization methods. This software is aimed at researchers in the field of computational biology, particularly those working with antibodies and protein-ligand interactions.

### Key Features:
- **Antibody Mutagenesis**: Allows for the creation and analysis of mutant antibody structures.
- **Protein-Protein Interaction (PPI) Calculation**: Handles complex protein-protein interaction simulations and binding free energy evaluations using tools like gmx_MMPBSA.
- **Metropolis Algorithm**: Implements a Metropolis algorithm to explore different conformations of antibody mutants.
- **Multiple Simulation Support**: The program supports parallel processing for computational efficiency, especially useful for high-throughput simulations on clusters.
- **Customizable Workflows**: Provides flexibility in configuring the simulation process using a variety of user-defined parameters.

---

## Requirements

Before running ABiSS, ensure you have the following dependencies installed:

- **Gromacs** (for structure file handling and Molecular Dynamics)
- **VMD** (no GUI - for structure file handling )
- **Modeller** (to perform mutagenesis)
- **Python 3.8 or higher**
<!-- **Antechamber** (optional, for force field parameterization) -->
<!-- **OpenBabel** (optional, but strongly recommended for molecular format conversions) -->

---

## Installation

1. Clone the repository:
    ```bash
    git clone https://github.com/DamianoBuratto/ABiSS.git
    cd ABiSS
    ```

2. Install required dependencies. You may need to install **Gromacs**, **VMD**, **Modeller**, and **Python** dependencies manually or using a package manager (e.g., `conda`).

3. Set up the environment by ensuring all necessary programs are available in your system's PATH.

---

## Usage

### Running ABiSS:

To run the program, you can use the following command:

```bash
ABiSS_custom.sh -I INPUT.in 
```
where the parameter -I is used to specify the input file pattern. An example of the INPUT file (`INPUT_example.in`) is provided with the code.

You can also restart calculations by passing the -R option along with the path to previously computed settings:

```bash
ABiSS_custom.sh -I INPUT.in -R "RUN1/SETUP_PROGRAM_FILES/abiss_settings.sh"
```

### Workflow
ABiSS follows a structured workflow:

1. Setup and Initialization:
   - The system configuration and setup files are loaded, and directories are created for different cycles.
2. Mutation Cycle:
   - The program iterates through several mutant cycles, applying changes to antibody sequences using the Metropolis algorithm.
3. Position Restraints, Equilibration, and Molecular Dynamics (MD):
   - Position restraints can be generated for the system
   - the structure is equilibrated using NVT and NPT simulations.
   - a new configurational minimum is achieved through Simulated Annealing Molecular dynamics (SAMD)
   - equilibrium MD is performed
4. Energy Calculation:
   - frames from MD are used for interaction calculations to assess binding affinity.
6. Analysis and Output:
   - The final results, including energy calculations and mutant configurations, are saved and made available for further analysis.

<!-- ### Example Usage
#### Generating a New Mutation:
```bash
MakeNewMutant_Modeller.py "${complex_FILE}.pdb" -s "${SystemName}" -o "./Mutant${SEQUENCE}" \
    -rl ${TargetResidueList} -rw ${resid_be_decomp_files[*]} -v
```
#### Running MD Simulations:
```bash
run_md_for_every_cycle "system_equil.gro" "${topName}" "${tprFILE}" "${trjNAME}"
```
-->


---

## License
This project is licensed under the MIT License - see the LICENSE file for details.

---

## Acknowledgements
ABiSS was developed by Damiano Buratto and Francesco Zonta with the precious contributions and suggestions from Prof. Zhous's group at IQB, ZJU. 
The software is based on various computational biology tools, including Gromacs, VMD, Modeller, and Chimera.


