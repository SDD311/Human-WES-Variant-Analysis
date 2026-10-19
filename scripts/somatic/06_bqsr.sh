
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

source config/somatic.env

# Set these to compatible GRCh38 known-sites resources
DBSNP=reference/known_sites/dbsnp.vcf.gz
MILLS=reference/known_sites/Mills_and_1000G_gold_standard.indels.vcf.gz

mkdir -p results/somatic/bqsr

while IFS=, read -r sample sra condition; do
    [[ "$sample" == "sample_id" || -z "$sample" ]] && continue

    gatk --java-options "-Xmx${JAVA_MEMORY}" \
        BaseRecalibrator \
        -R "$REFERENCE" \
        -I "${BAM_DIR}/${sample}.marked.bam" \
        --known-sites "$DBSNP" \
        --known-sites "$MILLS" \
        -O "results/somatic/bqsr/${sample}.table"

    gatk --java-options "-Xmx${JAVA_MEMORY}" \
        ApplyBQSR \
        -R "$REFERENCE" \
        -I "${BAM_DIR}/${sample}.marked.bam" \
        --bqsr-recal-file "results/somatic/bqsr/${sample}.table" \
        -O "results/somatic/bqsr/${sample}.recal.bam"

    gatk BuildBamIndex \
        -I "results/somatic/bqsr/${sample}.recal.bam"

done < "$SAMPLE_SHEET"

