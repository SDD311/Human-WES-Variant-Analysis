
#!/usr/bin/env bash
set -euo pipefail

# Germline WES: GATK SNP and indel hard filtering
# Research demonstration; thresholds require review

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

source config/germline.env

INPUT_DIR="results/germline/variants/raw_vcf"
OUTPUT_DIR="results/germline/variants/filtered"

mkdir -p "$OUTPUT_DIR"

for tool in gatk bcftools; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "ERROR: Missing tool: $tool" >&2
        exit 1
    }
done

while IFS=, read -r sample sra condition; do

    [[ "$sample" == "sample_id" || -z "$sample" ]] && continue

    INPUT="${INPUT_DIR}/${sample}.raw.vcf.gz"

    [[ -f "$INPUT" ]] || {
        echo "ERROR: Missing VCF: $INPUT" >&2
        exit 1
    }

    echo "Filtering variants: $sample"

    # Separate SNPs and indels
    gatk SelectVariants \
        -R "$REFERENCE" \
        -V "$INPUT" \
        --select-type-to-include SNP \
        -O "${OUTPUT_DIR}/${sample}.snps.vcf.gz"

    gatk SelectVariants \
        -R "$REFERENCE" \
        -V "$INPUT" \
        --select-type-to-include INDEL \
        -O "${OUTPUT_DIR}/${sample}.indels.vcf.gz"

    # SNP quality filtering
    gatk VariantFiltration \
        -R "$REFERENCE" \
        -V "${OUTPUT_DIR}/${sample}.snps.vcf.gz" \
        --filter-name "QD2" \
        --filter-expression "QD < 2.0" \
        --filter-name "FS60" \
        --filter-expression "FS > 60.0" \
        --filter-name "MQ40" \
        --filter-expression "MQ < 40.0" \
        --filter-name "SOR3" \
        --filter-expression "SOR > 3.0" \
        -O "${OUTPUT_DIR}/${sample}.snps.filtered.vcf.gz"

    # Indel quality filtering
    gatk VariantFiltration \
        -R "$REFERENCE" \
        -V "${OUTPUT_DIR}/${sample}.indels.vcf.gz" \
        --filter-name "QD2" \
        --filter-expression "QD < 2.0" \
        --filter-name "FS200" \
        --filter-expression "FS > 200.0" \
        --filter-name "SOR10" \
        --filter-expression "SOR > 10.0" \
        -O "${OUTPUT_DIR}/${sample}.indels.filtered.vcf.gz"

    # Extract variants passing site-level filters
    bcftools view \
        -f PASS,. \
        -Oz \
        -o "${OUTPUT_DIR}/${sample}.snps.pass.vcf.gz" \
        "${OUTPUT_DIR}/${sample}.snps.filtered.vcf.gz"

    bcftools view \
        -f PASS,. \
        -Oz \
        -o "${OUTPUT_DIR}/${sample}.indels.pass.vcf.gz" \
        "${OUTPUT_DIR}/${sample}.indels.filtered.vcf.gz"

    bcftools index -t \
        "${OUTPUT_DIR}/${sample}.snps.pass.vcf.gz"

    bcftools index -t \
        "${OUTPUT_DIR}/${sample}.indels.pass.vcf.gz"

    echo "Finished filtering: $sample"

done < "$SAMPLE_SHEET"

echo "Germline variant filtering completed."

