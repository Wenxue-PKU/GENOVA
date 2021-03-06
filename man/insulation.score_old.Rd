% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/insulation_functions.R
\name{insulation.score_old}
\alias{insulation.score_old}
\title{insulation.score}
\usage{
insulation.score_old(
  exp,
  window.size,
  chrom,
  start,
  end,
  diag.add = 0,
  local = T
)
}
\arguments{
\item{exp}{A Hi-C experiment object: produced by \code{loadContacts()}.}

\item{window.size}{The sliding square size}

\item{chrom}{Chromosome}

\item{start}{Start position of the region of interest}

\item{end}{End position of the region of interest}

\item{diag.add}{Add values to diaginal}

\item{local}{Local or per-chromosome normalisation?}
}
\value{
A plot
}
\description{
Get insulation scores of a region or chromosome.
}
\examples{
# Get the insulation score with window-size 20 of a locus on chromosome 7.
\dontrun{
localInsulationScores <- insulation.score(hic = Hap1_WT_10kb, 
                                          window.size = 20, 
                                          chrom = "chr7", 
                                          start = 25e6, 
                                          end = 30e6, 
                                          local = T)
}
}
