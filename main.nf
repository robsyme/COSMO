#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

/* Prints help when asked for and exits */
def helpMessage() {
    log.info"""
    =========================================
    COSMO => COrrection of Sample Mislabeling by Omics
    =========================================
    Usage:
    nextflow run cosmo.nf
    Arguments:
      --d1_file         Dataset with quantification data at gene level.
      --d2_file         Dataset with quantification data at gene level.
      --cli_file        Sample annotation data.
      --cli_attribute   Sample attribute(s) for prediction. Multiple attributes must be separated by ",".
      --outdir          Output folder.
      --help            Print help message.
    """.stripIndent()
}

// Show help emssage
if (params.help) {
    helpMessage()
    exit 0
}

d1_file     = file(params.d1_file, checkIfExists: true)
d2_file     = file(params.d2_file, checkIfExists: true)
sample_file = file(params.cli_file, checkIfExists: true)

log.info "Sample attribute will be used: $params.cli_attribute \n"

process PREPROCESS {
    label 'process_low'

    input:
    path d1_file
    path d2_file
    path sample_file

    output:
    tuple path("out/${d1_file.name}"), path("out/${d2_file.name}"), path("out/${sample_file.name}")

    script:
    """
    format_input_data \\
        --d1 $d1_file \\
        --d2 $d2_file \\
        --samples $sample_file \\
        --out out
    """
}

process METHOD1 {
    label 'process_medium'

    input:
    tuple path(d1_file), path(d2_file), path(samplefile)
    path gene_tsv

    output:
    path "method1_out"

    script:
    """
    cosmo \\
        one \\
        --d1 $d1_file \\
        --d2 $d2_file \\
        --samples $samplefile \\
        --out method1_out \\
        --genes $gene_tsv \\
        --attributes ${params.cli_attribute} \\
        --cpus ${task.cpus}
    """
}

process METHOD2 {
    label 'process_medium'

    input:
    tuple path(d1_file), path(d2_file), path(samplefile)

    output:
    path "method2_out"

    script:
    """
    method2_function.py \\
        -d1 ${d1_file} \\
        -d2 ${d2_file} \\
        -s ${samplefile} \\
        -l ${params.cli_attribute} \\
        -o method2_out
    """
}

process COMBINE {
    label 'process_medium'

    input:
    path method1_out_folder
    path method2_out_folder
    path sample_file

    output:
    path "cosmo*"

    script:
    """
    cosmo \\
        combine \\
        --method-one-out $method1_out_folder \\
        --method-two-out $method2_out_folder \\
        --samples $sample_file \\
        --attributes ${params.cli_attribute} \\
        --prefix cosmo \\
        --cpus ${task.cpus} \\
        --out .
    """
}

workflow {
    genes = Channel.fromPath(params.genes)

    PREPROCESS(d1_file, d2_file, sample_file)

    METHOD1(PREPROCESS.out, genes.first())
    METHOD2(PREPROCESS.out)

    COMBINE(METHOD1.out, METHOD2.out, sample_file)
}