#!/bin/bash -l

#SBATCH --job-name=FluxTest    # Job name
#SBATCH --output=/users/pa23/goumas/kkats/jobs/FluxTest.%j.out # Stdout (%j expands to jobId)
#SBATCH --error=/users/pa23/goumas/kkats/jobs/FluxTest.%j.err # Stderr (%j expands to jobId)
#SBATCH --ntasks=3     # Number of tasks(processes)
#SBATCH --nodes=3     # Number of nodes requested
#SBATCH --ntasks-per-node=1     # Tasks per node
#SBATCH --cpus-per-task=1     # Threads per task
#SBATCH --time=00:05:00   # walltime
#SBATCH --mem-per-cpu=2400
#SBATCH --exclusive

if [ x$SLURM_CPUS_PER_TASK == x ]; then
  export OMP_NUM_THREADS=1
else
  export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
fi


## LOAD MODULES ##
module purge        # clean up loaded modules 

# load necessary modules

module load gnu/8
module load gnu/13.2.0
module load python/3.9.18
module load git
module load intel/19
module load intelmpi/2018

# define enviromental variables

BASE_DIR=$HOME/kkats/flurm/aris

NNODES=$((SLURM_JOB_NUM_NODES-1)) # the total nodes - the control node
NTASKS=8 # the actual amount of task(processes) needed for the job

export SPACK_PYTHON="$(dirname "$(dirname "$(which python)")")"

. $BASE_DIR/opt/spack/share/spack/setup-env.sh

spack load flux-sched 

## RUN YOUR PROGRAM ##
readarray -t HOSTS < <(scontrol show hostnames $SLURM_NODELIST)
CONTROL_NODE=${HOSTS[0]}
COMPUTE_NODES=("${HOSTS[@]:1}")

echo "Control node: $Control_NODE"
echo "Compute nodes: ${COMPUTE_NODES[@]}"

COMPUTE_NODELIST=$(IFS=, ; echo "${COMPUTE_NODES[*]}")

RANKLIST="0-$NNODES"
if [ "$NNODES" -eq 0 ]; then
  RANKLIST="0"
fi

echo "Compute Rlist: $COMPUTE_RLIST"

python3 $BASE_DIR/scripts/jgf_gen.py --nodes "$BROKER_NODE,$COMPUTE_NODELIST" --sockets 2 --cores 10 -o "$BASE_DIR/conf.d/aris.json"

sed -e "s|TEMPLATE_HOSTLIST|\"$BROKER_NODE\",$COMPUTE_RLIST|g" \
    -e "s|TEMPLATE_RANKLIST|${RANKLIST}|g" $BASE_DIR/conf.d/R.template > $BASE_DIR/conf.d/R

FLUX_DISABLE_JOB_CLEANUP=1 LD_PRELOAD=$BASE_DIR/opt/flux_helpers/redirect_random.so \
    srun -N $SLURM_JOB_NUM_NODES -n $SLURM_JOB_NUM_NODES --mpi=pmi2 --export=ALL flux start -o --config-path=$BASE_DIR/conf.d/flux-config.toml \ 
    flux run --requires="hosts:${COMPUTE_NODELIST}" -N $NNODES -n $NTASKS \ 
    hostname # replace with your script										  

