// Import generic module functions
include { get_resources; initOptions; saveFiles } from '../../../../../lib/nf/functions'
RESOURCES   = get_resources(workflow.profile, params.max_memory, params.max_cpus)
options     = initOptions(params.options ? params.options : [:], 'rgi_heatmap')
publish_dir = params.is_subworkflow ? "${params.outdir}/bactopia-tools/${params.wf}/${params.run_name}" : params.outdir
conda_tools = "bioconda::rgi=5.2.1"
conda_env   = file("${params.condadir}/rgi_heatmap").exists() ? "${params.condadir}/rgi_heatmap" : conda_tools

process RGI_HEATMAP {
    tag "$meta.id"
    publishDir "${publish_dir}", mode: params.publish_dir_mode, overwrite: params.force,
        saveAs: { filename -> saveFiles(filename:filename, opts:options) }

    conda (params.enable_conda ? conda_env : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/rgi:5.2.1--pyha8f3691_2' :
        'quay.io/biocontainers/rgi:5.2.1--pyha8f3691_2' }"

    input:
    tuple val(meta), path(json, stageAs: 'json/*')

    output:
    tuple val(meta), path("*.{csv,eps,png}"), emit: heatmap, optional: true
    path "*.{log,err}"                      , emit: logs, optional: true
    path ".command.*"                       , emit: nf_logs
    path "versions.yml"                     , emit: versions

    script:
    def prefix = options.suffix ? "${options.suffix}" : "${meta.id}"
    """
    NUM_SAMPLES=\$(ls json/ | wc -l)
    if [[ "\${NUM_SAMPLES}" -gt 1 ]]; then
        rgi \\
            heatmap \\
            $options.args \\
            --output $prefix \\
            --input json/
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rgi: \$(rgi main --version)
    END_VERSIONS
    """
}
