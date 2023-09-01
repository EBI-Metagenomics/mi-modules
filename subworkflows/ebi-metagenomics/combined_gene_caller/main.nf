
include { PRODIGAL                 } from '../../../modules/ebi-metagenomics/prodigal/main'
include { FRAGGENESCAN             } from '../../../modules/ebi-metagenomics/fraggenescan/main'
include { COMBINEDGENECALLER_MERGE } from '../../../modules/ebi-metagenomics/combinedgenecaller/merge/main'

workflow COMBINED_GENE_CALLER {

    take:
    // Should the mask_file be merged into the assembly channel ?
    ch_assembly  // channel: [ val(meta), [ fasta ] ]
    ch_mask_file // channel: [ val(meta), [.out | .txt] ]

    main:

    ch_versions = Channel.empty()

    PRODIGAL ( ch_assembly, channel.value("sco") )
    ch_versions = ch_versions.mix(PRODIGAL.out.versions.first())

    FRAGGENESCAN ( ch_assembly )
    ch_versions = ch_versions.mix(FRAGGENESCAN.out.versions.first())

    ch_mask_file = ch_mask_file ?: Channel.empty()

    ch_annotations = PRODIGAL.out.gene_annotations.join(
        PRODIGAL.out.nucleotide_fasta, by: [0]
    ).join(
        PRODIGAL.out.amino_acid_fasta, by: [0]
    ).join(
        FRAGGENESCAN.out.gene_annotations, by: [0]
    ).join(
        FRAGGENESCAN.out.nucleotide_fasta, by: [0]
    ).join(
        FRAGGENESCAN.out.amino_acid_fasta, by: [0]
    ).join(
        ch_mask_file, by: [0], remainder: true
    )

    COMBINEDGENECALLER_MERGE ( ch_annotations )

    ch_versions = ch_versions.mix(COMBINEDGENECALLER_MERGE.out.versions.first())

    emit:
    faa      = COMBINEDGENECALLER_MERGE.out.faa  // channel: [ val(meta), [ faa ] ]
    ffn      = COMBINEDGENECALLER_MERGE.out.ffn  // channel: [ val(meta), [ ffn ] ]
    versions = ch_versions                       // channel: [ versions.yml ]
}

