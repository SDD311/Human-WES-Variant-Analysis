
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

source config/somatic.env

mkdir -p "$VARIANT_DIR"

TUMOUR=$(awk -F, 'NR>1 && $3=="Tumour" {print $1}' "$SAMPLE_SHEET")
NORMAL=$(awk -F, 'NR>1 && $3=="Normal" {print $1}' "$SAMPLE_SHEET")

if [[ -z "$TUMOUR" || -z "$NORMAL" ]]; then
    echo "ERROR: Tumour and normal sample IDs are required" >&2
    exit 1
fi

gatk --java-options "-Xmx${JAVA_MEMORY}" \
    Mutect2 \
    -R "$REFERENCE" \
    -I "results/somatic/bqsr/${TUMOUR}.recal.bam" \
    -I "results/somatic/bqsr/${NORMAL}.recal.bam" \
    -tumor "$TUMOUR" \
    -normal "$NORMAL" \
    --germline-resource "$GERMLINE_RESOURCE" \
    --panel-of-normals "$PON" \
    -L "$TARGET_BED" \
    -O "${VARIANT_DIR}/somatic.unfiltered.vcf.gz" \
    --f1r2-tar-gz "${VARIANT_DIR}/f1r2.tar.gz"

