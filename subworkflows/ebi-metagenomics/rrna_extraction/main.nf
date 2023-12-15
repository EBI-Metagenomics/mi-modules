
include { INFERNAL_CMSEARCH           } from '../../../modules/ebi-metagenomics/infernal/cmsearch/main'
include { CMSEARCHTBLOUTDEOVERLAP     } from '../../../modules/ebi-metagenomics/cmsearchtbloutdeoverlap/main'
include { EASEL_ESLSFETCH             } from '../../../modules/ebi-metagenomics/easel/eslsfetch/main'

workflow RRNA_EXTRACTION {

    take:
    ch_fasta // channel: [ val(meta), [ fasta ] ]

    main:

    ch_versions = Channel.empty()

    INFERNAL_CMSEARCH(
        ch_fasta,
        file(params.rfam)
    )
    ch_versions = ch_versions.mix(INFERNAL_CMSEARCH.out.versions.first())

    CMSEARCHTBLOUTDEOVERLAP(
        INFERNAL_CMSEARCH.out.cmsearch_tbl,
        file(params.rfam_clan)
    )
    ch_versions = ch_versions.mix(CMSEARCHTBLOUTDEOVERLAP.out.versions.first())

    ch_easel = ch_fasta
                .join(CMSEARCHTBLOUTDEOVERLAP.out.cmsearch_tblout_deoverlapped)


    EASEL_ESLSFETCH(
        ch_easel
    )
    ch_versions = ch_versions.mix(EASEL_ESLSFETCH.out.versions.first())

    emit:
    cmsearch_deoverlap = CMSEARCHTBLOUTDEOVERLAP.out.cmsearch_tblout_deoverlapped   // channel: [ val(meta), [ deoverlapped ] ]
    easel_sfetch = EASEL_ESLSFETCH.out.easel_coords                                 // channel: [ val(meta), [ fasta ] ]
    matched_seqs_with_coords = EASEL_ESLSFETCH.out.matched_seqs_with_coords         // channel: [ val(meta), [ matched_seqs_with_coords ] ]
    versions = ch_versions                                                          // channel: [ versions.yml ]
}
