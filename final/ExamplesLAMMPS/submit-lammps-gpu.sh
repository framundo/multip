#! /bin/bash
#
#$ -cwd
#$ -j y
#$ -S /bin/bash
##  pido la cola gpu.q
#$ -q gpu.q
## pido una placa
#$ -l h=compute-0-2
#$ -l gpu=0
#$ -N PageRank
#
module load cuda
#module load intel/intel-12
#ejecuto el binario
hostname
mpirun -np 1 lmp_openmpi -in input_file.in -cuda on -sf cuda 
