#' 
#' @title Take in \acronym{SSURGO} csv files and create a soil profile
#' @name ssurgo2sp
#' @description Utility function to convert \acronym{SSURGO} data to soil profile
#' @param mapunit mapunit \acronym{SSURGO} file
#' @param component component \acronym{SSURGO} file
#' @param chorizon chorizon \acronym{SSURGO} file
#' @param mapunit.shp mapunit shapefile for creating metadata
#' @param nmapunit number of mapunits to select
#' @param nsoil number of soil components (within a mapunit) to consider
#' @param xout vector for interpolation and extrapolation
#' @param soil.bottom bottom of the soil profile
#' @param method method used for interpolation (see \code{\link{approx}})
#' @param nlayers number of soil layers to generate
#' @return a list with soil profile matrices with length equal to nsoil
#' @details Download the data from \acronym{SSURGO} using the \sQuote{FedData} package \cr
#' This will generate csv files \sQuote{chorizon}, \sQuote{component} and \sQuote{mapunit}, \cr
#' but also many other files which are not needed for creating a soil profile.
#' @export
#' @examples 
#' \dontrun{
#' require(ggplot2)
#' extd.dir <- system.file("extdata", package = "apsimx")
#' 
#' chorizon <- read.csv(paste0(extd.dir,"/ISUAG/SSURGO/ISUAG_SSURGO_chorizon.csv"))
#' component <- read.csv(paste0(extd.dir,"/ISUAG/SSURGO/ISUAG_SSURGO_component.csv"))
#' mapunit <- read.csv(paste0(extd.dir,"/ISUAG/SSURGO/ISUAG_SSURGO_mapunit.csv"))
#' 
#' ## Using default 'constant' method
#' sp.c <- ssurgo2sp(mapunit = mapunit, 
#'                  component = component, 
#'                  chorizon = chorizon)
#' 
#' ggplot(data = sp.c, aes(y = -Depth, x = Carbon)) + 
#' geom_point() + 
#'   geom_path() + 
#'   ylab("Soil Depth (cm)") + xlab("Organic Matter (percent)") +
#'   ggtitle("method = constant")
#'   
#' ## Using 'linear' method
#' sp.l <- ssurgo2sp(mapunit = mapunit, 
#'                  component = component, 
#'                  chorizon = chorizon, method = "linear")
#'                  
#' ggplot(data = sp.l, aes(y = -Depth, x = Carbon)) + 
#' geom_point() + 
#'   geom_path() + 
#'   ylab("Soil Depth (cm)") + xlab("Organic Matter (percent)") +
#'   ggtitle("Method linear")
#'   
#' }

ssurgo2sp <- function(mapunit = NULL, component = NULL, 
                      chorizon = NULL, mapunit.shp = NULL,
                      nmapunit = 1, nsoil = 1,
                      xout = NULL, soil.bottom = 200,
                      method = c("constant","linear"),
                      nlayers = 10){
  
  if(!requireNamespace("sf",quietly = TRUE)){
    warning("sf is required for this function")
    return(NULL)
  }
  
  ## Select important variables from mapunit
  mapunit2 <- subset(mapunit, 
                     select = c("musym", "muname", "muacres", "farmlndcl", 
                                "iacornsr", "lkey", "mukey"))
  ## Calculate acres percent and number of mapunits to consider
  ## In decreasing order of number of acres
  mapunit2$muacres.percent <- mapunit2$muacres/sum(mapunit2$muacres) * 100
  mapunit2 <- mapunit2[order(mapunit2$muacres, decreasing = TRUE),]
  mapunit3 <- mapunit2[1:nmapunit,]
  
  ## Process component
  component2 <- subset(component, 
                       select = c("compname", "comppct.r",
                                  "slope.r", "drainagecl",
                                  "elev.r", "taxsubgrp", 
                                  "taxpartsize", "taxclname",
                                  "drainagecl","elev.r",
                                  "slope.r","geomdesc",
                                  "mukey", "cokey"))
  component5 <- NULL
  for(i in mapunit3$mukey){
    component3 <- component2[component2$mukey == i,]
    component4 <- component3[order(component3$comppct.r, decreasing = TRUE),]
    ## This calculates the percent of the total acres in the area of interest
    component4$acres.proportion <- mapunit3[mapunit3$mukey == i,]$muacres.percent/100 * component4$comppct.r/100
    component4$compname.mukey <- as.factor(component4$compname):as.factor(component4$mukey)
    lonlat <- colMeans(sf::st_coordinates(mapunit.shp["MUKEY" == i]))
    mapunit.shp.d <- as.data.frame(mapunit.shp)
    component4$state <- rep(unique(strtrim(as.character(mapunit.shp.d[mapunit.shp.d$MUKEY == i,"AREASYMBOL"]),2)),nrow(component4))
    component4$longitude <- lonlat[1]
    component4$latitude <- lonlat[2]
    component5 <- rbind(component5, component4[1:nsoil,])
  }
  
  ## Process chorizon
  chorizon2 <- chorizon[chorizon$cokey %in% component5$cokey,]
  chorizon3 <- subset(chorizon2, 
                      select = c("hzname", "hzdept.r", "hzdepb.r", 
                                 "hzthk.r", "sandtotal.r", "silttotal.r",
                                 "claytotal.r", "om.r", "partdensity", 
                                 "ksat.r", "awc.r", "wtenthbar.r", 
                                 "wthirdbar.r", "wfifteenbar.r",
                                 "wsatiated.r", "ph1to1h2o.r",
                                 "cokey", "chkey"))
  
  chorizon3$hzdepa.r <- (chorizon3$hzdept.r + chorizon3$hzdepb.r)/2
  
  ## Rename to match APSIM
  chorizon3$Depth <- chorizon3$hzdepa.r
  chorizon3$Thickness <- chorizon3$hzthk.r
  chorizon3$LL15 <- chorizon3$wfifteenbar.r * 1e-2 ## convert to fraction
  chorizon3$DUL <- chorizon3$wthirdbar.r * 1e-2 ## convert to fraction
  chorizon3$SAT <- chorizon3$wsatiated.r * 1e-2 ## convert to fraction
  ## Convert micro meters per second to mm/day
  chorizon3$KS <- chorizon3$ksat.r * 1e-6 * (60 * 60 * 24) * 1e3 
  chorizon3$PH <- chorizon3$ph1to1h2o.r
  
  ## From Saxton and Rawls
  chorizon3$BD <- (1 - chorizon3$wsatiated.r/100) * ifelse(is.na(chorizon3$partdensity),2.65,chorizon3$partdensity)
  
  ## Convert to fraction
  chorizon3$AirDry <- chorizon3$wfifteenbar.r * ifelse(chorizon3$hzdept.r == 0, 0.5, 1) * 1e-2
  
  ## Soil Carbon
  ## SOM contains approximately 58% C; therefore, a factor of
  ## 1.72 can be used to convert OC to SOM.
  chorizon3$Carbon <- chorizon3$om.r * 0.58
  
  ## Soil names
  soil.names <- component5$compname.mukey
  soil.list <- vector(mode = "list", length = length(soil.names))
  names(soil.list) <- soil.names
  
  vars <- c("Depth","Thickness","BD","AirDry","LL15","DUL","SAT","KS","Carbon","PH")
  
  for(sz in 1:length(soil.names)){
    
    one.soil <- chorizon3[chorizon3$cokey == component5$cokey[sz],]
  
    soil.mat <- matrix(nrow = nlayers, ncol = length(vars))
  
    nlayers0 <- nlayers
    nlayers1 <- nlayers + 1
  
    for(i in 2:length(vars)){
      tmp <- one.soil[,c("Depth",vars[i])]
    
      nlayers <- ifelse(vars[i] == "Thickness", nlayers1, nlayers0)
    
      sva <- approx_soil_variable(tmp, 
                                  xout = xout, 
                                  soil.bottom = soil.bottom,
                                  method = method, 
                                  nlayers = nlayers)
    
      if(vars[i] == "Thickness"){
        thck <- numeric(nlayers0)
        for(j in 2:nlayers1) thck[j-1] <- sva$x[j] - sva$x[j-1] 
          soil.mat[,i] <- thck
      }else{
        soil.mat[,i] <- sva$y
      }
    }
    soil.mat[,1] <- sva$x
    soil.d <- as.data.frame(soil.mat)
    ## Attributes will be modeled after APSIM metadata
    attr(soil.d, which = "SoilType") <- as.character(soil.names[sz])
    attr(soil.d, which = "State") <- component5$state[sz]
    attr(soil.d, which = "Country") <- "USA"
    attr(soil.d, which = "Longitude") <- component5$longitude[1]
    attr(soil.d, which = "Latitude") <- component5$latitude[1]
    attr(soil.d, which = "DataSource") <- paste("R package FedData, function get_ssurgo and R package apsimx function ssurgo2sp. Timestamp",Sys.time())
    attr(soil.d, which = "Comments") <- paste("cokey =",component5$cokey[sz],
                                              "- acres percent =",component5$acres.proportion[sz] * 100,
                                              "- component percent =",component5$comppct.r[sz],
                                              "- taxonomic classification name =",as.character(component5$taxclname)[sz],
                                              "- drainage class =", as.character(component5$drainagecl)[sz],
                                              "- elevation =", component5$elev.r[sz],
                                              "- slope =", component5$slope.r[sz],
                                              "- geomdesc =", as.character(component5$geomdesc)[sz])
    names(soil.d) <- vars
    ## Store in list
    soil.list[[sz]] <- soil.d
  }

  return(soil.list)
}

#' Interpolate a soil variable using 'approx' and return a data.frame
#' @name approx_soil_variable
#' @description interpolate a soil variable over a range of values
#' @param x input vector
#' @param xout output vector (see stats::approx)
#' @param soil.bottom bottom of the soil layer in cm
#' @param method either 'constant' or 'linear' as used in 'stats::approx'
#' @param nlayers number of soil layers
#' @noRd
#' 
approx_soil_variable <- function(x, xout = NULL, soil.bottom = 200, 
                                 method = c("constant","linear"),
                                 nlayers = 10){
  
  xd <- as.data.frame(x)
  method <- match.arg(method)
  if(is.null(xout)) xout <- seq(0,soil.bottom, length.out = nlayers)
  
  ans <- stats::approx(x = xd[[1]], y = xd[[2]], method = method, xout = xout, rule = 2)
  
  ansd <- data.frame(x = ans$x, y = ans$y)
  return(ansd)
}