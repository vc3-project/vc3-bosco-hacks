# Hacks needed to make bosco work on NERSC

The following changes are based on bosco 1.2.10 (1.2.9 works the same, but requires a patch to `slurm_status.py` included in 1.2.10)

## Running bosco\_cluster manually

NERSC uses Cray Linux (SUSE), which is not supported by bosco.

To install bosco, we need to:
- Run `bosco_cluster` manually, forcing RH6 as the platform
- Include some dependencies not included in the Cray environment

### Installing bosco on the user home area
```
bosco_cluster --platform RH6 --add username@cori.nersc.gov slurm
```

### Adding extra library dependencies
Once bosco has been installed in the NERSC user's home area, copy the `extras directory` in `$HOME/bosco`

```
scp -r extras username@cori.nersc.gov:~/bosco
```
and edit your default shell user's profile or runcom file (e.g .bashrc, .bash\_profile, .zhrc, etc) to make sure these libraries are loaded in the shell by bosco

```
# Add extra libraries for bosco
export LD_LIBRARY_PATH="LD_LIBRARY_PATH:~/bosco/extras"
```

## Hacking bosco to work with SHIFTER and specify node types

### Hacking bosco files w.r.t bosco 1.2.10
Copy files in `glite_hacks/bin` and `glite_hacks/etc` into the bosco area `glite` directory, or modify files according to .diff files.

### Attributes for slurm jobs
Copy `slurm_local_submit_attributes.sh` inside glite/bin
This has slurm config lines for shifter and also to define a walltime, node type and partition type

Check the [NERSC documentation](http://www.nersc.gov/users/computational-systems/cori/running-jobs/batch-jobs) for more details. The defaults here are:

```
echo "#SBATCH --image=docker:benediktriedel/spt_test_shifter:latest"
echo "#SBATCH -t 06:00:00"
echo "#SBATCH -C knl"
echo "#SBATCH --partition=regular"
```

