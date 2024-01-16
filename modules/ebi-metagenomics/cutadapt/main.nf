
process CUTADAPT {
    tag "$meta.id"
    label 'process_single'

    conda "bioconda::cutadapt=4.6"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/cutadapt:4.6--py39hf95cd2a_1':
        'biocontainers/cutadapt:4.6--py39hf95cd2a_1' }"

    input:
    tuple val(meta), path(reads), path(primers)

    output:
    tuple val(meta), path('*.trim.fastq.gz'), emit: reads
    tuple val(meta), path('*.log')          , emit: log
    path "versions.yml"                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def trimmed  = meta.single_end ? "-o ${prefix}.trim.fastq.gz" : "-o ${prefix}_1.trim.fastq.gz -p ${prefix}_2.trim.fastq.gz"
    def fwd_primer = primers[0].size() > 0 ? "-g file:${primers[0]}"  : ''
    def rev_primer = primers[1].size() > 0  && meta.single_end ? "-a file:${primers[1]}" : primers[1].size() > 0  && !meta.single_end ? "-G file:${primers[1]}" : ''
    def primer_arg = "$fwd_primer $rev_primer"

    """
    cutadapt \\
        --cores $task.cpus \\
        $args \\
        $trimmed \\
        $primer_arg \\
        $reads \\
        > ${prefix}.cutadapt.log
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cutadapt: \$(cutadapt --version)
    END_VERSIONS
    """

    stub:
    def prefix  = task.ext.prefix ?: "${meta.id}"
    def trimmed = meta.single_end ? "${prefix}.trim.fastq.gz" : "${prefix}_1.trim.fastq.gz ${prefix}_2.trim.fastq.gz"
    """
    touch ${prefix}.cutadapt.log
    touch ${trimmed}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cutadapt: \$(cutadapt --version)
    END_VERSIONS
    """
}
