
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

mkdir -p logs

LOG="logs/somatic_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1

echo "Human WES Somatic Variant Analysis"
echo "Started: $(date)"

export PIPELINE_CONFIG="config/somatic.env"

run_stage() {
    echo "Running: $1"
    bash "$2"
}

run_stage "Download" scripts/common/01_download.sh
run_stage "FastQC" scripts/common/02_fastqc.sh
run_stage "fastp" scripts/common/03_fastp.sh
run_stage "Alignment" scripts/common/04_alignment.sh
run_stage "Mark duplicates" scripts/somatic/05_markduplicates.sh
run_stage "BQSR" scripts/somatic/06_bqsr.sh
run_stage "Mutect2" scripts/somatic/07_mutect2.sh
run_stage "Somatic filtering" scripts/somatic/08_filtermutectcalls.sh
run_stage "Variant annotation" scripts/somatic/09_annotation.sh

echo "Somatic WES pipeline completed: $(date)"

