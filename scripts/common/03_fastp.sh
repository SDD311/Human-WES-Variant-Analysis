
#!/usr/bin/env bash
set -euo pipefail

# Germline WES: Paired-end read preprocessing with fastp

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

source config/germline.env

REPORT_DIR="${QC_DIR}/fastp"
mkdir -p "$TRIMMED_DIR" "$REPORT_DIR"

command -v fastp >/dev/null 2>&1 || {
    echo "ERROR: fastp is not installed" >&2
    exit 1
}

while IFS=, read -r sample sra condition; do

    [[ "$sample" == "sample_id" || -z "$sample" ]] && continue

    R1="${FASTQ_DIR}/${sample}_R1.fastq.gz"
    R2="${FASTQ_DIR}/${sample}_R2.fastq.gz"

    if [[ ! -f "$R1" || ! -f "$R2" ]]; then
        echo "ERROR: Missing paired FASTQ files for $sample" >&2
        exit 1
    fi

    echo "Preprocessing $sample"

    fastp \
        --in1 "$R1" \
        --in2 "$R2" \
        --out1 "${TRIMMED_DIR}/${sample}_R1.fastq.gz" \
        --out2 "${TRIMMED_DIR}/${sample}_R2.fastq.gz" \
        --thread "$THREADS" \
        --html "${REPORT_DIR}/${sample}_fastp.html" \
        --json "${REPORT_DIR}/${sample}_fastp.json"

done < "$SAMPLE_SHEET"

echo "fastp preprocessing completed."

