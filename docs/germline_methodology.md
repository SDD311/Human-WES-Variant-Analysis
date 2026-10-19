
# Germline Whole-Exome Sequencing Analysis

## 1. Project Overview

This project develops a reproducible computational pipeline for identifying germline single-nucleotide variants (SNVs) and small insertions and deletions (indels) from human whole-exome sequencing (WES) data.

The pipeline follows a GATK-based variant discovery workflow, from raw sequencing quality assessment to variant annotation.

## 2. Analysis Objectives

1. Evaluate the quality of raw WES sequencing reads.
2. Align sequencing reads to the human GRCh38 reference genome.
3. Identify and mark duplicate reads.
4. Perform base quality score recalibration.
5. Identify germline SNPs and indels using GATK HaplotypeCaller.
6. Apply variant quality filters.
7. Annotate variants and generate summary statistics.

## 3. Planned Bioinformatics Workflow

### Raw Read Quality Control
Tools: FastQC and MultiQC

Evaluate sequencing quality, GC content, adapter contamination and sequence duplication.

### Read Preprocessing
Tool: fastp

Perform adapter trimming and quality filtering when justified by raw read QC.

### Sequence Alignment
Tools: BWA-MEM and samtools

Align paired-end reads to GRCh38 and generate coordinate-sorted BAM files.

### Duplicate Marking
Tool: GATK MarkDuplicates

Identify and flag duplicate sequencing reads.

### Base Quality Score Recalibration
Tools: GATK BaseRecalibrator and ApplyBQSR

Recalibrate base-quality scores using compatible known-sites variant resources.

### Germline Variant Calling
Tools: GATK HaplotypeCaller and GenotypeGVCFs

Generate sample-level GVCFs and genotype variants.

### Variant Filtering
Tools: GATK VariantFiltration and bcftools

Apply exploratory hard-filter criteria and assess variant-quality metrics.

### Variant Annotation
Tool: Ensembl Variant Effect Predictor (VEP)

Annotate variant consequences, genomic locations and affected genes.

## 4. Reference Data

- Human reference genome: GRCh38
- Capture intervals: To be selected for the dataset
- Known variant resources: GRCh38-compatible dbSNP and Mills indels
- VEP annotation cache: GRCh38-compatible release

Exact reference versions and source URLs will be recorded before execution.

## 5. Expected Outputs

- FastQC and MultiQC reports
- Sorted and duplicate-marked BAM files
- Recalibrated BAM files
- Germline GVCF and VCF files
- Filtered SNP and indel VCF files
- VEP-annotated variants
- Variant quality statistics

## 6. Reproducibility

The project includes numbered analysis scripts, central configuration, sample metadata and a master execution script.

Software versions, reference checksums, execution logs and QC metrics will be recorded during pipeline validation.

## 7. Limitations

The pipeline is currently under development and has not been validated on the selected dataset.

Variant filtering thresholds are illustrative and require assessment against sequencing quality, coverage and assay characteristics.

This workflow is for educational and research purposes only. It is not a validated clinical diagnostic pipeline.

