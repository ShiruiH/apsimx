#'
#' This function requires the \sQuote{nasapower} pacakge.
#'
#' @title Get POWER data for an APSIM met file
#' @description Uses 'get_power' from the 'nasapower' package to download data to create an APSIM met file.
#' @name get_power_apsim_met
#' @param lonlat Longitude and latitude vector
#' @param dates date ranges
#' @param wrt.dir write directory
#' @param filename file name for writing out to disk
#' @details If the filename is not provided it will not write the file to disk, 
#' but it will return an object of class 'met'. This is useful in case manipulation
#' is required before writing to disk.
#' @export
#' @examples 
#' \dontrun{
#' require(nasapower)
#' ## This will not write a file to disk
#' pwr <- get_power_apsim_met(lonlat = c(-93,42), dates = c("2012-01-01","2012-12-31"))
#' ## Note that missing data is coded as -99
#' summary(pwr)
#' ## Check for reasonable ranges 
#' check_apsim_met(pwr)
#' ## replace -99 with NA
#' pwr$radn <- ifelse(pwr$radn == -99, NA, pwr$radn)
#' ## Impute using linear interpolation
#' pwr.imptd <- impute_apsim_met(pwr, verbose = TRUE)
#' summary(pwr.imptd)
#' }
#' 

get_power_apsim_met <- function(lonlat, dates, wrt.dir=".", filename=NULL){
  
  if(!requireNamespace("nasapower",quietly = TRUE)){
    warning("The nasapower is required for this function")
    return(NULL)
  }
  
  if(missing(filename)) filename <- "noname.met"
   
  if(!grepl(".met", filename, fixed=TRUE)) stop("filename should end in .met")
  
  pwr <- nasapower::get_power(community = "AG",
                              pars = c("T2M_MAX",
                              "T2M_MIN",
                              "ALLSKY_SFC_SW_DWN",
                              "PRECTOT",
                              "RH2M",
                              "WS2M"),
                              dates = dates,
                              lonlat = lonlat,
                              temporal_average = "DAILY")
  
  pwr <- subset(as.data.frame(pwr), select = c("YEAR","DOY","T2M_MAX","T2M_MIN",
                                                "ALLSKY_SFC_SW_DWN","PRECTOT",
                                                "RH2M","WS2M"))
  
  names(pwr) <- c("year","day","maxt","mint","radn","rain","rh","wind_speed")
  units <- c("()","()","(oC)","(oC)","(MJ/m2/day)","(mm)","(%)","(m/s)")
  
  comments <- paste("!data from nasapower R pacakge. retrieved: ",Sys.time())
    
  attr(pwr, "filename") <- filename
  attr(pwr, "site") <- sub(".met","", filename, fixed = TRUE)
  attr(pwr, "latitude") <- paste("latitude =",lonlat[2])
  attr(pwr, "longitude") <- paste("longitude =",lonlat[1])
  attr(pwr, "tav") <- paste("tav =",mean(colMeans(pwr[,c("maxt","mint")],na.rm=TRUE),na.rm=TRUE))
  attr(pwr, "amp") <- paste("amp =",mean(pwr$maxt, na.rm=TRUE) - mean(pwr$mint, na.rm = TRUE))
  attr(pwr, "colnames") <- names(pwr)
  attr(pwr, "units") <- units
  attr(pwr, "comments") <- comments
  ## No constants
  class(pwr) <- c("met","data.frame")
  
  if(filename != "noname.met"){
    write_apsim_met(pwr, wrt.dir = wrt.dir, filename = filename)
  }
  return(invisible(pwr))
}