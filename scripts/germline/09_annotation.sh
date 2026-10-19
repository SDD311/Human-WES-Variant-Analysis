
#!/usr/bin/env bash
set -euo pipefail

# Germline WES: Functional annotation using Ensembl VEP
# Requires a matching offline GRCh38 VEP cache

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

source config/germline.env

INPUT_DIR="results/germline/variants/filtered"
OUTPUT_DIR="results/germline/annotation"

# Offline VEP cache directory
VEP_CACHE="reference/vep_cache"

mkdir -p "$OUTPUT_DIR"

for tool in vep bcftools; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "ERROR: Missing required tool: $tool" >&2
        exit 1
    }
done

[[ -d "$VEP_CACHE" ]] || {
    echo "ERROR: VEP cache directory missing: $VEP_CACHE" >&2
    exit 1
}

while IFS=, read -r sample sra condition; do

    [[ "$sample" == "sample_id" || -z "$sample" ]] && continue

    echo "Annotating variants for $sample"

    for variant_type in snps indels; do

        INPUT="${INPUT_DIR}/${sample}.${variant_type}.pass.vcf.gz"
        OUTPUT="${OUTPUT_DIR}/${sample}.${variant_type}.vep.vcf"

        [[ -f "$INPUT" ]] || {
            echo "ERROR: Missing filtered VCF: $INPUT" >&2
            exit 1
        }

        vep \
            --input_file "$INPUT" \
            --output_file "$OUTPUT" \
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

        bgzip -f "$OUTPUT"
        bcftools index -t "${OUTPUT}.gz"

        bcftools stats "${OUTPUT}.gz" \
            > "${OUTPUT_DIR}/${sample}.${variant_type}.stats.txt"

    done

    echo "Annotation completed: $sample"

done < "$SAMPLE_SHEET"

echo "All germline variant annotations completed."

