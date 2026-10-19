#!/usr/bin/env bash
set -euo pipefail

# GSE Germline WES: Mark PCR and optical duplicates

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

source config/germline.env

BAM_DIR="results/germline/bam"
mkdir -p "$BAM_DIR"

command -v gatk >/dev/null || {
    echo "ERROR: GATK is not installed" >&2
    exit 1
}

while IFS=, read -r sample sra condition; do

    [[ "$sample" == "sample_id" || -z "$sample" ]] && continue

    INPUT="${ALIGNMENT_DIR}/${sample}.sorted.bam"
    OUTPUT="${BAM_DIR}/${sample}.marked.bam"
    METRICS="${BAM_DIR}/${sample}.duplicate_metrics.txt"

    [[ -f "$INPUT" ]] || {
        echo "ERROR: Missing input BAM: $INPUT" >&2
        exit 1
    }

    echo "Marking duplicates: $sample"

    gatk --java-options "-Xmx${JAVA_MEMORY}" \
        MarkDuplicates \
        -I "$INPUT" \
        -O "$OUTPUT" \
        -M "$METRICS" \
        --CREATE_INDEX true \
        --TMP_DIR "${TMPDIR:-/tmp}"

    echo "Completed: $sample"

done < "$SAMPLE_SHEET"

echo "Duplicate marking completed."

