# Flurm on ARIS

This folder contains scripts and helpers for running **Flux inside Slurm** on the **ARIS HPC system**.  
Slurm acts as the total resource allocator, while Flux runs as the inner resource manager and job scheduler.

---

## Contents

- **`opt/`**
  - `flux-helpers/` → Essential helpers making Flux work in ARIS.
  - `spack_install_flux.sh` → Script to install Flux and dependencies via [Spack](https://spack.readthedocs.io/).

- **`scripts/`**
  - `flux_template.sh` → A Slurm job submission template that launches Flux inside your allocation.
  - `check_ghosts.sh` → Script to detect and clean up leftover/“ghost” processes or jobs.
  - `jgf_gen.py` → Script to generate a JSON Graph Format (JGF) resource description for Flux.

- **`conf.d/`**
  - `flux-config.toml` -> Example Flux configuration file for ARIS.
  - `R.template` -> The template for a R file for ARIS. `TEMPLATE_RANKLIST` and `TEMPLATE_HOSTLIST` should be replaced with the actual ranklist and hostlist.

---

## Usage on ARIS

1. **Install Flux and Spack**
   - The `spack_install_flux.sh` script will install Spack and use it to install Flux and its dependencies in your home directory.  
   - You only need to do this once.
   - You can customize the spack user config and user cache paths by defining the `SPACK_USER_CONFIG_PATH` and `SPACK_USER_CACHE_PATH` environment variables before running the script. The default is `~/.spack` for both of them.
   - In order for Flux to work properly on ARIS, you need to run `make` inside the `flux-helpers` directory after running the installation script.
2. **Submit Jobs**
   - Use the `flux_template.sh` script as a starting point for your Slurm job scripts.  
   - It will allocate resources, load the Flux module, and launch a Flux broker inside your Slurm allocation. One node is used as the Flux control node, while the rest are used as compute nodes.
   - It uses `jgf_gen.py` to generate a JSON Graph Format (JGF) resource description for Flux based on your Slurm allocation (`aris.json`) and replaces the placeholders in the `R.template` file to create a R file for your system.
   - Adapt the script for your allocation size, walltime, modules and cluster architecture.
   - Adapt the `flux-config.toml` file in `conf.d/` to your needs and pass it to the `flux start` command using the `--config` option.
3. **Monitor and Clean Up**
   - Use the `check_ghosts.sh` script to check for and clean up any leftover Flux or Slurm processes that may not have terminated properly after your jobs complete. Ghost processes should be impossible if everything works correctly, but this script is useful for debugging.

## Notes

- The provided scripts and configurations are tailored for the ARIS HPC system, e.g. they assume every compute node has 2 sockets and 10 cores per socket. You may need to adjust them for other systems.
- For more information on Flux and its capabilities, refer to the [Flux documentation](https://flux-framework.readthedocs.io/en/latest/).