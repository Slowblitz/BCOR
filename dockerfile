FROM bioconductor/devel_core AS biocstage 


# Updating is required before any apt-gets
RUN sudo apt-get update && apt-get install -y --force-yes\
  # Required for R Package XML
  libxml2-dev \
  # Curl; required for RCurl; but present in upstream images
  # libcurl4-gnutls-dev \
   # GNU Scientific Library; required by MotIV
  libgsl0-dev \
  # Open SSL is used, for example, devtools dependency git2r
  libssl-dev \
   # CMD Check requires to check pdf size
  qpdf

# Boost libraries are helpful for some r packages
RUN sudo apt-get update && apt-get install -y --force-yes \
libboost-all-dev

COPY Rprofile .Rprofile

COPY Rsetup/install_fonts.R Rsetup/install_fonts.R
COPY Rsetup/fonts Rsetup/fonts
RUN Rscript Rsetup/install_fonts.R

# Install packages
COPY Rsetup/Rsetup.R Rsetup/Rsetup.R
RUN Rscript Rsetup/Rsetup.R
COPY Rsetup/rpack_basic.txt Rsetup/rpack_basic.txt
COPY Rsetup/rpack_bio.txt Rsetup/rpack_bio.txt
RUN Rscript Rsetup/Rsetup.R --packages=Rsetup/rpack_basic.txt
RUN Rscript Rsetup/Rsetup.R --packages=Rsetup/rpack_bio.txt

# If you want to develop R packages on this machine (need biocCheck):
COPY Rsetup/rpack_biodev.txt Rsetup/rpack_biodev.txt
RUN Rscript Rsetup/Rsetup.R --packages=Rsetup/rpack_biodev.txt


# CMD Check requires to check pdf size
RUN sudo apt-get install -y --force-yes qpdf

# Copy over the stuff in Rpack and add it to path
COPY Rpack/ Rpack/
ENV PATH Rpack:$PATH

FROM apache/airflow:2.10.0
ENV DEBIAN_FRONTEND=noninteractive
# Install ICU libraries in the Airflow image
USER root
COPY --from=biocstage /usr/local/lib/R/site-library /usr/local/lib/R/site-library

# Ensure the library path includes ICU libraries
# Ensure the library path includes ICU libraries
ENV LD_LIBRARY_PATH=/usr/local/lib:/usr/lib:/usr/lib/x86_64-linux-gnu

# Switch back to airflow user
USER airflow