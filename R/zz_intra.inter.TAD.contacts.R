#' intra.inter.TAD.contacts
#'
#' Combine a bed file with TAD positions and the Hi-C matrix file to calculate
#' the average coverage over a TAD and between two TADs.
#'
#' @author Elzo de Wit, \email{e.d.wit@nki.nl}
#' @param exp The Hi-C experiment object of a sample from construct.experiment()
#' @param TAD A bed-dataframe. TADs should be consecutive
#' (i.e. the 3' border of TAD1 is the 5' border of TAD2).
#' This means that using TAD-calls from Arrowhead is only possible after some
#' these internal sub-TADs.
#' @param max_neighbour How many surrounding TADs should be taken into account?
#' @return A list:
#' @return \item{hic}{dataframe with indexes of two TADs and interaction-score}
#' @return \item{tad}{dataframe with TADs and the index used in the hic-df}
#' @return \item{sampleName}{the sample name of the experiment-object}
#' @import data.table
#' @examples
#' \dontrun{
#' # get scores for WT and WAPL data
#' TAD_N_WT <- intra.inter.TAD.contacts(
#'   TAD = WT_TADs,
#'   max.neighbor = 10,
#'   exp = Hap1_WT_10kb
#' )
#' TAD_N_WAPL <- intra.inter.TAD.contacts(
#'   TAD = WT_TADs,
#'   max.neighbor = 10,
#'   exp = Hap1_WAPL_10kb
#' )
#'
#' # plot a TAD+N dotplot
#' differential.TAD.dotplot(
#'   exp1 = TAD_N_WT, # denominator
#'   exp2 = TAD_N_WAPL
#' ) # numerator
#'
#' # plot a TAD+N scatterplot
#' differential.TAD.scatterplot(
#'   exp1 = TAD_N_WT, # x
#'   exp2 = TAD_N_WAPL, # y
#'   allData = T
#' )
#' }
intra.inter.TAD.contacts <- function(exp, TAD, max_neighbour = 10) {
  # error handling
  if (any(TAD[, 3] < TAD[, 2])) {
    stop("Incorrectly structured TAD data: end column smaller than start")
  }
  # sort the TADs otherwise the findInterval function will not work
  TAD <- TAD[order(TAD[, 1], TAD[, 2]), 1:3]
  TAD[, 4] <- NA
  chrom <- unique(TAD[, 1])
  max.tad <- 1
  if (exists("intra.inter")) {
    rm(intra.inter)
  }
  # loop over chromosomes
  for (chr in chrom) {

    # select the chromosome ids from the HiC data structure
    chr.id <- exp$IDX[V1 == chr, ]
    # determine which ids overlap with which TAD/domain
    chr.id[["V5"]] <- findInterval(chr.id[["V2"]], TAD[TAD[, 1] == chr, 2])
    # determine which ids overlap with which TAD/domain
    chr.id[["V6"]] <- findInterval(chr.id[["V2"]], TAD[TAD[, 1] == chr, 3])
    # select only those sites that are within a TAD that is given by the user
    chr.id <- chr.id[chr.id[["V5"]] != chr.id[["V6"]], ]
    d <- exp$MAT # select the ICE matrix from the HiC data structure
    # select the intrachromosomal contact sites for chr
    chrom.min <- min(chr.id[["V4"]])
    chrom.max <- max(chr.id[["V4"]])
    d.chrom <- d[J(chrom.min:chrom.max), ]
    d.chrom <- d.chrom[d.chrom$V2 >= chrom.min & d.chrom$V2 <= chrom.max, ]

    # associate hic-pro indices with TAD positions
    tad.x <- chr.id[match(d.chrom$V1, chr.id[["V4"]]), V5]
    tad.y <- chr.id[match(d.chrom$V2, chr.id[["V4"]]), V5]
    # select tad(combination)s that are not more than max.neighbor apart
    sel <- tad.y - tad.x <= max_neighbour & tad.x > 0 & tad.y > 0 & !is.na(tad.x) & !is.na(tad.y)
    tad.x <- tad.x[sel]
    tad.y <- tad.y[sel]
    d.chrom <- d.chrom$V3[sel]
    # calculate the sum of the TAD-TAD interactions
    if (exists("intra.inter")) {
      max.tad <- max(intra.inter[, 1:2])
      # sum over d.chrom, on the two tad positions
      intra.inter.chr <- ave(d.chrom, tad.x, tad.y, FUN = sum)
      # create a new data.frame with the results
      intra.inter.chr <- data.frame(x = tad.x, y = tad.y, score = intra.inter.chr)
      intra.inter.chr <- unique(intra.inter.chr)
      intra.inter.chr[, 1] <- intra.inter.chr[, 1] + max.tad
      intra.inter.chr[, 2] <- intra.inter.chr[, 2] + max.tad
      intra.inter <- rbind(intra.inter, intra.inter.chr)
      TAD[TAD[, 1] == chr, 4] <- (max.tad + 1):(max.tad + nrow(TAD[TAD[, 1] == chr, ]))
    } else {
      intra.inter <- ave(d.chrom, tad.x, tad.y, FUN = sum)
      intra.inter <- data.frame(x = tad.x, y = tad.y, score = intra.inter)
      intra.inter <- unique(intra.inter)
      TAD[TAD[, 1] == chr, 4] <- max.tad:(max.tad + nrow(TAD[TAD[, 1] == chr, ]) - 1)
    }
    # give every TAD an ID corresponding to the IDs used in intra.inter
  }
  # combine the TAD positions and
  list(hic = intra.inter, tad = TAD, sampleName = attr(exp, "samplename"))
}
