
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

source config/somatic.env

mkdir -p "$ANNOTATION_DIR"

vep \
    --input_file "${VARIANT_DIR}/somatic.pass.vcf.gz" \
    --output_file "${ANNOTATION_DIR}/somatic.annotated.vcf" \
    --format vcf \
    --vcf \
    --offline \
    --cache \
    --dir_cache "$VEP_CACHE" \
    --assembly GRCh38 \
    --symbol \
    --canonical \
    --biotype \
    --force_overwrite

bgzip -f "${ANNOTATION_DIR}/somatic.annotated.vcf"

bcftools index -t \
    "${ANNOTATION_DIR}/somatic.annotated.vcf.gz"

bcftools stats \
    "${ANNOTATION_DIR}/somatic.annotated.vcf.gz" \
    > "${ANNOTATION_DIR}/somatic.variant_stats.txt"

