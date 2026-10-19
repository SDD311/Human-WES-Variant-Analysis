
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

source config/somatic.env

mkdir -p "$VARIANT_DIR"

gatk --java-options "-Xmx${JAVA_MEMORY}" \
    LearnReadOrientationModel \
    -I "${VARIANT_DIR}/f1r2.tar.gz" \
    -O "${VARIANT_DIR}/read-orientation-model.tar.gz"

gatk --java-options "-Xmx${JAVA_MEMORY}" \
    GetPileupSummaries \
    -I "results/somatic/bqsr/$(awk -F, 'NR>1 && $3=="Tumour" {print $1}' "$SAMPLE_SHEET").recal.bam" \
    -V "$GERMLINE_RESOURCE" \
    -L "$TARGET_BED" \
    -O "${VARIANT_DIR}/tumour.pileups.table"

gatk --java-options "-Xmx${JAVA_MEMORY}" \
    GetPileupSummaries \
    -I "results/somatic/bqsr/$(awk -F, 'NR>1 && $3=="Normal" {print $1}' "$SAMPLE_SHEET").recal.bam" \
    -V "$GERMLINE_RESOURCE" \
    -L "$TARGET_BED" \
    -O "${VARIANT_DIR}/normal.pileups.table"

gatk --java-options "-Xmx${JAVA_MEMORY}" \
    CalculateContamination \
    -I "${VARIANT_DIR}/tumour.pileups.table" \
    -matched "${VARIANT_DIR}/normal.pileups.table" \
    -O "${VARIANT_DIR}/contamination.table" \
    --tumor-segmentation "${VARIANT_DIR}/segments.table"

gatk --java-options "-Xmx${JAVA_MEMORY}" \
    FilterMutectCalls \
    -R "$REFERENCE" \
    -V "${VARIANT_DIR}/somatic.unfiltered.vcf.gz" \
    --contamination-table "${VARIANT_DIR}/contamination.table" \
    --tumor-segmentation "${VARIANT_DIR}/segments.table" \
    --ob-priors "${VARIANT_DIR}/read-orientation-model.tar.gz" \
    -O "${VARIANT_DIR}/somatic.filtered.vcf.gz"

bcftools view \
    -f PASS \
    -Oz \
    -o "${VARIANT_DIR}/somatic.pass.vcf.gz" \
    "${VARIANT_DIR}/somatic.filtered.vcf.gz"

bcftools index -t "${VARIANT_DIR}/somatic.pass.vcf.gz"

