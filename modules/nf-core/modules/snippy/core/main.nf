// Import generic module functions
include { get_resources; initOptions; saveFiles } from '../../../../../lib/nf/functions'
RESOURCES   = get_resources(workflow.profile, params.max_memory, params.max_cpus)
options     = initOptions(params.options ? params.options : [:], 'snippy-core')
publish_dir = params.is_subworkflow ? "${params.outdir}/bactopia-tools/${params.wf}/${params.run_name}" : params.outdir
conda_tools = "bioconda::snippy=4.6.0 bioconda::vcf-annotator=0.7 bioconda::rename=1.601 bioconda::snpeff=5.0"
conda_name  = conda_tools.replace("=", "-").replace(":", "-").replace(" ", "-")
conda_env   = file("${params.condadir}/${conda_name}").exists() ? "${params.condadir}/${conda_name}" : conda_tools

process SNIPPY_CORE {
    tag "${meta.id}"
    label "process_medium"

    publishDir "${publish_dir}", mode: params.publish_dir_mode, overwrite: params.force,
        saveAs: { filename -> saveFiles(filename:filename, opts:options) }

    conda (params.enable_conda ? conda_env : null)
    container 'quay.io/bactopia/call_variants:2.1.0'

    input:
    tuple val(meta), path(vcf), path(aligned_fa)
    path reference

    output:
    tuple val(meta), path("results/*")                          , emit: results
    tuple val(meta), path("results/${prefix}.aln.gz")           , emit: aln
    tuple val(meta), path("results/${prefix}.full.aln.gz")      , emit: full_aln
    tuple val(meta), path("results/${prefix}-clean.full.aln.gz"), emit: clean_full_aln
    tuple val(meta), path("results/${prefix}.tab.gz")           , emit: tab
    tuple val(meta), path("results/${prefix}.vcf.gz")           , emit: vcf
    tuple val(meta), path("results/${prefix}.txt")              , emit: txt
    path "*.{log,err}"                          , optional: true, emit: logs
    path ".command.*"                                           , emit: nf_logs
    path "versions.yml"                                         , emit: versions

    script:
    prefix = options.suffix ? "${options.suffix}" : "${meta.id}"
    def is_compressed = reference.getName().endsWith(".gz") ? true : false
    def final_reference = reference.getName().replace(".gz", "")
    """
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $reference > $final_reference
    fi

    # Collect samples into necessary folders
    mkdir samples
    find . -name "*.vcf.gz" | sed 's/.vcf.gz//' | xargs -I {} bash -c 'mkdir samples/{}'
    find . -name "*.vcf.gz" | sed 's/.vcf.gz//' | xargs -I {} bash -c 'gzip -cdf {}.vcf.gz > samples/{}/{}.vcf'
    find . -name "*.aligned.fa.gz" | sed 's/.aligned.fa.gz//' | xargs -I {} bash -c 'gzip -cdf {}.aligned.fa.gz > samples/{}/{}.aligned.fa'

    # Run snippy-core
    snippy-core \\
        $options.args \\
        --ref $final_reference \\
        --prefix $prefix \\
        samples/*

    # Cleanup the alignment
    snippy-clean_full_aln ${prefix}.full.aln > ${prefix}-clean.full.aln
    rm *ref.fa

    # Compress outputs
    if [[ ${params.skip_compression} == "false" ]]; then
        pigz -n --best -p ${task.cpus} ${prefix}.aln
        pigz -n --best -p ${task.cpus} ${prefix}.full.aln
        pigz -n --best -p ${task.cpus} ${prefix}-clean.full.aln
        pigz -n --best -p ${task.cpus} ${prefix}.tab
        pigz -n --best -p ${task.cpus} ${prefix}.vcf
    fi

    # Move outputs
    mkdir results
    mv ${prefix}* results/


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pigz: \$(echo \$(pigz --version 2>&1) | sed 's/pigz //')
        snippy: \$(echo \$(snippy --version 2>&1) | sed 's/snippy //')
    END_VERSIONS
    """
}
