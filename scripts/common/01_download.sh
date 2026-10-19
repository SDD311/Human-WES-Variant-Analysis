
#!/usr/bin/env bash
set -euo pipefail

# Download human germline WES samples from SRA

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

source config/germline.env

mkdir -p "$FASTQ_DIR" data/germline/sra

for tool in prefetch fasterq-dump pigz; do
    command -v "$tool" >/dev/null || {
        echo "ERROR: Missing software: $tool" >&2
        exit 1
    }
done

while IFS=, read -r sample sra condition; do

    [[ "$sample" == "sample_id" || -z "$sample" ]] && continue

    echo "Downloading $sample ($sra)"

    prefetch "$sra" \
        --output-directory data/germline/sra

    fasterq-dump \
        "data/germline/sra/${sra}/${sra}.sra" \
        --split-files \
        --threads "$THREADS" \
        --outdir "$FASTQ_DIR"

    if [[ -f "$FASTQ_DIR/${sra}_1.fastq" &&
          -f "$FASTQ_DIR/${sra}_2.fastq" ]]; then

        mv "$FASTQ_DIR/${sra}_1.fastq" \
           "$FASTQ_DIR/${sample}_R1.fastq"

        mv "$FASTQ_DIR/${sra}_2.fastq" \
           "$FASTQ_DIR/${sample}_R2.fastq"

        pigz -p "$THREADS" \
            "$FASTQ_DIR/${sample}_R1.fastq" \
            "$FASTQ_DIR/${sample}_R2.fastq"

    else
        echo "ERROR: Expected paired-end FASTQ files missing for $sample" >&2
        exit 1
    fi

done < "$SAMPLE_SHEET"

echo "Germline WES FASTQ download completed."

