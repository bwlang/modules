process PICARD_POSITIONBASEDDOWNSAMPLESAM {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::picard=3.0.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/picard:3.0.0--hdfd78af_1' :
        'quay.io/biocontainers/picard:3.0.0--hdfd78af_1' }"

    input:
    tuple val(meta), path(bam), val(target_num_reads), val(fraction)

    output:
    tuple val(meta), path("*.ds*.bam")        , emit: bam
    tuple val(meta), path("*.ds*.bai")        , optional:true, emit: bai
    path  "versions.yml"                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def avail_mem = 3
    if (!task.memory) {
        log.info '[Picard PositionBasedDownsampleSam] Available memory not known - defaulting to 3GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = task.memory.giga
    }
    """
    picard \\
        -Xmx${avail_mem}g \\
        PositionBasedDownsampleSam \\
        $args \\
        --CREATE_INDEX \\
        --INPUT $bam \\
        --OUTPUT ${prefix}.ds${target_num_reads}.bam \\
        --FRACTION  ${fraction}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        picard: \$(echo \$(picard PositionBasedDownsampleSam --version 2>&1) | grep -o 'Version:.*' | cut -f2- -d:)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.bam
    touch ${prefix}.bam.bai

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        picard: \$(echo \$(picard PositionBasedDownsampleSam --version 2>&1) | grep -o 'Version:.*' | cut -f2- -d:)
    END_VERSIONS
    """
}
