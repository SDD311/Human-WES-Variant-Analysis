#!/usr/bin/env bash
set -euo pipefail

# Germline WES variant calling
# HaplotypeCaller GVCF -> GenotypeGVCFs VCF

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

source config/germline.env

INPUT_DIR="results/germline/bqsr"
GVCF_DIR="results/germline/variants/gvcf"
VCF_DIR="results/germline/variants/raw_vcf"

mkdir -p "$GVCF_DIR" "$VCF_DIR"

command -v gatk >/dev/null || {
    echo "ERROR: GATK not installed" >&2
    exit 1
}

for file in "$REFERENCE" "$TARGET_BED"; do
    [[ -f "$file" ]] || {
        echo "ERROR: Missing file: $file" >&2
        exit 1
    }
done

while IFS=, read -r sample sra condition; do

    [[ "$sample" == "sample_id" || -z "$sample" ]] && continue

    INPUT="${INPUT_DIR}/${sample}.recal.bam"
    GVCF="${GVCF_DIR}/${sample}.g.vcf.gz"
    VCF="${VCF_DIR}/${sample}.raw.vcf.gz"

    [[ -f "$INPUT" ]] || {
        echo "ERROR: Missing recalibrated BAM: $INPUT" >&2
        exit 1
    }

    echo "Calling variants for $sample"

    # Generate intermediate GVCF
    gatk --java-options "-Xmx${JAVA_MEMORY}" \
        HaplotypeCaller \
        -R "$REFERENCE" \
        -I "$INPUT" \
        -L "$TARGET_BED" \
        -ERC GVCF \
        -O "$GVCF"

    # Genotype this individual sample
    gatk --java-options "-Xmx${JAVA_MEMORY}" \
        GenotypeGVCFs \
        -R "$REFERENCE" \
        -V "$GVCF" \
        -O "$VCF"

    echo "Completed variant calling: $sample"

done < "$SAMPLE_SHEET"

echo "Germline variant calling completed."

