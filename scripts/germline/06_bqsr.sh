#!/usr/bin/env bash
set -euo pipefail

# Germline WES: GATK Base Quality Score Recalibration

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

source config/germline.env

BAM_DIR="results/germline/bam"
RECAL_DIR="results/germline/bqsr"

mkdir -p "$RECAL_DIR"

command -v gatk >/dev/null || {
    echo "ERROR: GATK is not installed" >&2
    exit 1
}

# Verify required reference resources
for file in "$REFERENCE" "$DBSNP" "$MILLS"; do
    [[ -f "$file" ]] || {
        echo "ERROR: Missing reference resource: $file" >&2
        exit 1
    }
done

while IFS=, read -r sample sra condition; do

    [[ "$sample" == "sample_id" || -z "$sample" ]] && continue

    INPUT="${BAM_DIR}/${sample}.marked.bam"
    TABLE="${RECAL_DIR}/${sample}.recal.table"
    OUTPUT="${RECAL_DIR}/${sample}.recal.bam"

    [[ -f "$INPUT" ]] || {
        echo "ERROR: Missing BAM: $INPUT" >&2
        exit 1
    }

    echo "Generating BQSR table for $sample"

    gatk --java-options "-Xmx${JAVA_MEMORY}" \
        BaseRecalibrator \
        -R "$REFERENCE" \
        -I "$INPUT" \
        --known-sites "$DBSNP" \
        --known-sites "$MILLS" \
        -O "$TABLE"

    echo "Applying BQSR to $sample"

    gatk --java-options "-Xmx${JAVA_MEMORY}" \
        ApplyBQSR \
        -R "$REFERENCE" \
        -I "$INPUT" \
        --bqsr-recal-file "$TABLE" \
        -O "$OUTPUT"

    gatk --java-options "-Xmx${JAVA_MEMORY}" \
        BuildBamIndex \
        -I "$OUTPUT"

    echo "Completed BQSR: $sample"

done < "$SAMPLE_SHEET"

echo "BQSR completed for all samples."

