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

//workFiles
	//.combine(reference_genome)
	//.set {alignments_with_reference}

fasta_ref = file(params.reference)

process freyja_variants {
	publishDir "${params.outdir}/freyja_reports/variants/", mode: 'copy', pattern:'*'
	//publishDir "$outdir/freyja_reports/depths/"

	input:
	file(alignments) from workFiles
	file fasta_ref
	//file (reference) from reference_genome


	output:
	file("*") into variants_out

	shell:
	s_name = alignments.baseName
	//fasta_ref = file(params.reference)
	"""
	freyja variants !{s_name}.bam --variants !{s_name}_freyja_variants.tsv --depths !{s_name}_freyja_depths --ref !{fasta_ref}
	freyja demix !{s_name}_freyja_variants.tsv !{s_name}_freyja_depths --output !{s_name}_final.tsv
	"""

 
}


//process freyja_demix {
	//tag "$name"
	//publishDir "$outdir/freyja_reports/"

	//input:
	//tuple name, file(vars) from variants_out
	//tuple name, file(depths) from depths_out

	//output:
	//file "${name}_final.tsv"

	//script:
	//"""
	//freyja demix ${vars} ${depths} --output "${name}_final.tsv"
	//"""
//}