#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

source config/somatic.env

mkdir -p "$BAM_DIR"

while IFS=, read -r sample sra condition; do
    [[ "$sample" == "sample_id" || -z "$sample" ]] && continue

    gatk --java-options "-Xmx${JAVA_MEMORY}" \
        MarkDuplicates \
        -I "${ALIGNMENT_DIR}/${sample}.sorted.bam" \
        -O "${BAM_DIR}/${sample}.marked.bam" \
        -M "${BAM_DIR}/${sample}.metrics.txt" \
        --CREATE_INDEX true

done < "$SAMPLE_SHEET"

