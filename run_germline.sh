
#!/usr/bin/env bash
set -euo pipefail

# End-to-end germline whole-exome sequencing pipeline
# Educational and research use only

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

mkdir -p logs

LOG_FILE="logs/germline_$(date +%Y%m%d_%H%M%S).log"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "======================================"
echo "Human Germline WES Analysis"
echo "======================================"
echo "Start time: $(date)"

source config/germline.env

# Verify metadata is populated
[[ -f "$SAMPLE_SHEET" ]] || {
    echo "ERROR: Germline sample sheet missing" >&2
    exit 1
}

if [[ $(tail -n +2 "$SAMPLE_SHEET" | grep -c '[^[:space:]]' || true) -eq 0 ]]; then
    echo "ERROR: No germline samples configured" >&2
    exit 1
fi

# Ensure reference files are present
for file in "$REFERENCE" "$TARGET_BED" "$DBSNP" "$MILLS"; do
    [[ -f "$file" ]] || {
        echo "ERROR: Missing reference resource: $file" >&2
        exit 1
    }
done

# Check all pipeline scripts before starting
SCRIPTS=(
    scripts/common/01_download.sh
    scripts/common/02_fastqc.sh
    scripts/common/03_fastp.sh
    scripts/common/04_alignment.sh
    scripts/germline/05_markduplicates.sh
    scripts/germline/06_bqsr.sh
    scripts/germline/07_haplotypecaller.sh
    scripts/germline/08_variant_filtering.sh
    scripts/germline/09_annotation.sh
)

for script in "${SCRIPTS[@]}"; do
    [[ -f "$script" ]] || {
        echo "ERROR: Missing script: $script" >&2
        exit 1
    }
done

run_stage() {
    local name="$1"
    local script="$2"

    echo
    echo "======================================"
    echo "$name"
    echo "Started: $(date)"
    echo "======================================"

    bash "$script"

    echo "Completed: $name at $(date)"
}

run_stage "1. Download FASTQ" \
    scripts/common/01_download.sh

run_stage "2. FastQC and MultiQC" \
    scripts/common/02_fastqc.sh

run_stage "3. Read preprocessing" \
    scripts/common/03_fastp.sh

run_stage "4. BWA-MEM alignment" \
    scripts/common/04_alignment.sh

run_stage "5. Duplicate marking" \
    scripts/germline/05_markduplicates.sh

run_stage "6. Base quality recalibration" \
    scripts/germline/06_bqsr.sh

run_stage "7. HaplotypeCaller" \
    scripts/germline/07_haplotypecaller.sh

run_stage "8. Variant filtering" \
    scripts/germline/08_variant_filtering.sh

run_stage "9. Variant annotation" \
    scripts/germline/09_annotation.sh

echo
echo "======================================"
echo "Germline WES pipeline completed"
echo "Finished: $(date)"
echo "Log: $LOG_FILE"
echo "======================================"

