#' Clean helminth parasite occurrence data
#'
#' Given a host-parasite edgelist, this function can validate species names,
#' provide further taxonomic information (thanks to \code{taxize}), 
#' and remove records only to genus level.
#'
#' Use \code{data(locations)} for a list of possible locations.
#'
#' @param edge Host-parasite edgelist obtained from \code{\link{findLocation}},
#'        \code{\link{findHost}}, or \code{\link{findParasite}}
#' @param speciesOnly boolean flag to remove host and parasite species
#'        where data are only available at genus level (default = FALSE)
#' @param validateHosts boolean flag to check host species names
#'        against Catalogue of Life information and output taxonomic
#'        information (default = FALSE)
#'
#' @return cleanEdge Host-parasite edgelist, but cleaned
#' @export
#' @author Tad Dallas
#'

cleanData <- function (edge, speciesOnly = FALSE, validateHosts = FALSE){
  if (speciesOnly) {
    if (length(grep("sp\\.", edge$Host)) > 0) {
      edge <- edge[-grep(" sp\\.", edge$Host), ]
    }
    if (length(grep("sp\\.", edge$Parasite)) > 0) {
      edge <- edge[-grep(" sp\\.", edge$Parasite), ]
    }
    if (length(grep("spp\\.", edge$Host)) > 0) {
      edge <- edge[-grep(" spp\\.", edge$Host), ]
    }
    if (length(grep("spp\\.", edge$Parasite)) > 0) {
      edge <- edge[-grep(" spp\\.", edge$Parasite), ]
    }

    if (length(grep(".*\\((.*)\\).*", edge$Host)) > 0) {
      edge <- edge[-grep(".*\\((.*)\\).*", edge$Host), ]
    }
    if (length(grep(".*\\((.*)\\).*", edge$Parasite)) > 0) {
      edge <- edge[-grep(".*\\((.*)\\).*", edge$Parasite), ]
    }
  }

  if (validateHosts) {
    validate <- function(hostName) {
      hostName <- as.character(hostName)
      if (length(grep("sp\\.", hostName)) == 1) {
	      hostName2 <- unlist(strsplit(hostName, " "))[1]
      }else{
	      hostName2 <- unlist(strsplit(hostName, " "))[1:2]
      }
      rootClife <- read_xml(paste("http://www.catalogueoflife.org/col/webservice?name=",
      hostName2[1], "&response=full", sep = ""))
      if (xml_attr(rootClife, "number_of_results_returned") == 0) {
        ret <- rep(NA,8)
        names(ret) <- c("Kingdom", "Phylum", "Class", "Order",
        "Superfamily", "Family", "Genus", "Subgenus")
      }else{
        for(i in seq_len(length(xml_children(rootClife)))){
          taxInfo <- xml_text(xml_find_all(xml_children(rootClife)[i],
            "classification/taxon/name"))
          names(taxInfo) <- xml_text(xml_find_all(xml_children(rootClife)[i],
	          "classification/taxon/rank"))
        	if(any(names(taxInfo) == "Genus")&&taxInfo["Genus"]==hostName2[1]){
        	  ret <- taxInfo
            break
          }
        }
      }
      if(length(taxInfo) == 0 | taxInfo['Genus'] != hostName2[1]){
        ret <- rep(NA,8)
        names(ret) <- c("Kingdom", "Phylum", "Class", "Order",
          "Superfamily", "Family", "Genus", "Subgenus")
      }
      return(ret)
    }

    taxMat <- matrix(NA, ncol = 8, nrow = nrow(edge))
    colnames(taxMat) <- c("Kingdom", "Phylum", "Class", "Order",
      "Superfamily", "Family", "Genus", "Subgenus")
    for(q in seq_len(nrow(edge))){
      temp <- validate(edge$Host[q])
      taxMat[q, which(names(temp) %in% colnames(taxMat))] <- unlist(temp)
    }
    if(any(apply(taxMat, 1, function(x){all(is.na(x))}))){
      rmv <- which(apply(taxMat, 1, 
        function(x){
          all(is.na(x))
        })
      )
      taxMat <- taxMat[-rmv, ]
      edge <- edge[-rmv, ]
    }
    return(list(HPedge = edge, HostTaxon = taxMat))
  }
  return(edge)
}
