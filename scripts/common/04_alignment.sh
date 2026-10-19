#!/usr/bin/env bash
set -euo pipefail

# Germline WES: BWA-MEM alignment to GRCh38

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

source config/germline.env

mkdir -p "$ALIGNMENT_DIR"

for tool in bwa samtools; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "ERROR: $tool is not installed" >&2
        exit 1
    }
done

[[ -f "$REFERENCE" ]] || {
    echo "ERROR: Reference genome missing: $REFERENCE" >&2
    exit 1
}

# BWA index must be prepared before execution
[[ -f "${REFERENCE}.bwt" ]] || {
    echo "ERROR: BWA genome index is missing" >&2
    exit 1
}

while IFS=, read -r sample sra condition; do

    [[ "$sample" == "sample_id" || -z "$sample" ]] && continue

    R1="${TRIMMED_DIR}/${sample}_R1.fastq.gz"
    R2="${TRIMMED_DIR}/${sample}_R2.fastq.gz"

    [[ -f "$R1" && -f "$R2" ]] || {
        echo "ERROR: Missing trimmed FASTQs for $sample" >&2
        exit 1
    }

    echo "Aligning sample: $sample"

    # BAM read-group information is necessary for GATK
    READ_GROUP="@RG\tID:${sample}\tSM:${sample}\tPL:ILLUMINA\tLB:${sample}_lib\tPU:${sample}_unit"

    bwa mem \
        -t "$THREADS" \
        -R "$READ_GROUP" \
        "$REFERENCE" \
        "$R1" "$R2" |
    samtools sort \
        -@ "$THREADS" \
        -m 512M \
        -o "${ALIGNMENT_DIR}/${sample}.sorted.bam" \
        -

    samtools index \
        "${ALIGNMENT_DIR}/${sample}.sorted.bam"

    samtools flagstat \
        "${ALIGNMENT_DIR}/${sample}.sorted.bam" \
        > "${ALIGNMENT_DIR}/${sample}.flagstat.txt"

    echo "Alignment completed: $sample"

done < "$SAMPLE_SHEET"

echo "All germline WES samples aligned successfully."

