# Human Whole Exome Sequencing (WES) Variant Analysis

## Project Overview
This project develops a reproducible workflow for analysing human whole-exome sequencing data, from raw FASTQ reads to quality-controlled DNA variant calls.

## Planned Analysis Workflow
1. FASTQ quality control using FastQC and MultiQC
2. Read preprocessing using fastp where appropriate
3. Alignment to the human GRCh38 reference using BWA-MEM
4. BAM sorting, duplicate marking and quality assessment
5. Base quality score recalibration using GATK
6. Variant discovery and genotyping
7. Variant filtering and quality assessment
8. Variant annotation and reporting

## Software
- Ubuntu Linux (WSL 2)
- FastQC and MultiQC
- fastp
- BWA-MEM
- samtools
- GATK
- bcftools

## Data
Public human WES dataset to be selected. Reference genome, capture intervals and sample metadata must be verified before execution.

## Project Status
Under development. Pipeline scripts and analysis results have not yet been validated.

## Limitations
This repository is intended for educational and research purposes. It is not a validated clinical diagnostic workflow.
