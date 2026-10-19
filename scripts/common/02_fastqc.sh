#!/usr/bin/env bash
set -euo pipefail

# Germline WES: Raw sequencing QC using FastQC and MultiQC

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

source config/germline.env

FASTQC_OUTPUT="${QC_DIR}/fastqc_raw"
MULTIQC_OUTPUT="${QC_DIR}/multiqc_raw"

mkdir -p "$FASTQC_OUTPUT" "$MULTIQC_OUTPUT"

for tool in fastqc multiqc; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "ERROR: $tool is not installed" >&2
        exit 1
    fi
done

shopt -s nullglob
FASTQ_FILES=("$FASTQ_DIR"/*.fastq.gz)

if (( ${#FASTQ_FILES[@]} == 0 )); then
    echo "ERROR: No FASTQ files found in $FASTQ_DIR" >&2
    exit 1
fi

echo "Running FastQC on ${#FASTQ_FILES[@]} FASTQ files"

fastqc \
    --threads "$THREADS" \
    --outdir "$FASTQC_OUTPUT" \
    "${FASTQ_FILES[@]}"

echo "Generating MultiQC summary"

multiqc \
    "$FASTQC_OUTPUT" \
    --outdir "$MULTIQC_OUTPUT" \
    --filename multiqc_report.html \
    --force

echo "Raw WES quality control completed."

