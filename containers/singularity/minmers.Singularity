Bootstrap: docker
From: nfcore/base

%labels
    MAINTAINER Robert A. Petit III <robert.petit@emory.edu>
    DESCRIPTION Singularity image containing requirements for the Bactopia minmers process
    VERSION 1.5.x

%environment
    PATH=/opt/conda/envs/bactopia-minmers/bin:$PATH
    export PATH

%files
    conda/linux/minmers.yml /

%post
    /opt/conda/bin/conda env create -f /minmers.yml
    /opt/conda/bin/conda clean -a
