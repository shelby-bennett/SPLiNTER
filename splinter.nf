#!/usr/bin/env nextflow

/*
==================================================================
						SPLINTER
==================================================================
//Description: Workflow to generate quality metrics and reports from SARS-CoV-2 WW data.
//Author:Shelby Bennett
//email:shelby.bennett@dgs.virginia.gov
*/


//input files needed to start analysis

params.alignments = ""
params.outdir = "splinter_report"


Channel
	.fromPath("${params.alignments}/*.bam")
	.ifEmpty {error "Cannot find any alignments"}
	.view()
	.set { workFiles }
									


//reference sequence needed for freyja

params.reference = workflow.projectDir + "/configs/ref_seq.fasta"

Channel 
	.fromPath(params.reference, type:'file')
	.ifEmpty{ exit 1, "No reference genome was selected. Set with 'params.reference'"}
	.set { reference_genome } 

fasta_ref = file(params.reference)

process freyja_variants {
	publishDir "${params.outdir}/freyja_reports/variants/", mode: 'copy', pattern:'*'

	input:
	file(alignments) from workFiles
	file fasta_ref

	output:
	file("*_final.tsv") into variants_out

	shell:
	s_name = alignments.baseName

	"""
	freyja variants !{s_name}.bam --variants !{s_name}_freyja_variants.tsv --depths !{s_name}_freyja_depths --ref !{fasta_ref}
	freyja demix !{s_name}_freyja_variants.tsv !{s_name}_freyja_depths --output !{s_name}_final.tsv
	"""

 
}


process freyja_aggregate {
	publishDir "${params.outdir}", mode: 'copy'
	
	input:
	file(variants) from variants_out.collect()

	output:
	file("aggregated_results.tsv")

	shell:
	"""
	mkdir tmp

	mv !{variants} tmp/.

	freyja aggregate tmp/ --output aggregated_results.tsv 
	freyja plot aggregated_results.tsv --output aggregated_plot.pdf
	"""

}
