#!/bin/bash
#SBATCH -J flye
#SBATCH -o flye.o%j
#SBATCH -c 20
#SBATCH --mem=32G
#SBATCH -t 15:00:00
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=jearce2@uh.edu
set -e
set -u
set -o pipefail

set +eu
source ~/.bashrc

if [ $# -ne 4 ]
then
  echo "Incorrect number of arguments"
  echo "run_flye.sh <nanoreads> <r1> <r2> <outdir>"
  exit
fi

export nanoreads=$1
export r1=$2
export r2=$3
export assembly_dir=$4

t=20
#assemble genome
conda activate flye-env

flye --nano-raw ${nanoreads} --out-dir ${assembly_dir} --threads ${t} -i 3
cd ${assembly_dir}

conda deactivate


#set up polishing environment 
conda activate polish-env
module load SAMtools/1.9-intel-2017b

#three rounds of polishing
assembly="assembly.fasta"
for i in {1..3}
do
  polish_dir="polish_round_${i}"
  mkdir ${polish_dir}
  sorted_aln="${polish_dir}/aln-sorted.bam"
  pilon_out="${polish_dir}/pilon_out"
  minimap2 -ax -t ${t} sr ${assembly} ${r1} ${r2} | samtools view -u | samtools sort -@ ${t} > ${sorted_aln}
  pilon --genome ${assembly} --frags ${aln} --threads ${t} --outdir ${pilon_out}
  assembly="${pilon_out}/pilon.fasta"
done

conda deactivate
