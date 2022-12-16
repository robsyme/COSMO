FROM rocker/r-ver:4	

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        r-cran-randomforest \
        r-bioc-biomart \
        r-cran-glmnet \
        r-cran-caret \
        r-cran-doparallel \
        r-cran-dbplyr

RUN R -e 'install.packages(c("missForest"))'

RUN apt-get install -y --no-install-recommends python3-pandas python3-numpy python3-matplotlib python3-seaborn python3-sklearn