#! /bin/bash

echo "#SBATCH --image=docker:benediktriedel/spt_test_shifter:latest"
#echo "#SBATCH --image=custom:cms_cvmfs:latest"
echo "#SBATCH -t 06:00:00"
#echo "#SBATCH -C haswell"
#echo "#SBATCH --partition=shared"
#echo "#SBATCH --partition=regularx"
echo "#SBATCH -C knl"
echo "#SBATCH --partition=regular"
##echo "#SBATCH -e spt_%j.err"
##echo "#SBATCH -o spt_%j.out"
