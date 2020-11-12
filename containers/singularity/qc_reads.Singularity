Bootstrap: docker
From: nfcore/base

%labels
    MAINTAINER Robert A. Petit III <robert.petit@emory.edu>
    DESCRIPTION Singularity image containing requirements for the Bactopia qc_reads process
    VERSION 1.5.x

%environment
    PATH=/opt/conda/envs/bactopia-qc_reads/bin:$PATH
    export PATH

%files
    conda/linux/qc_reads.yml /

%post
    /opt/conda/bin/conda env create -f /qc_reads.yml
    /opt/conda/bin/conda clean -a
