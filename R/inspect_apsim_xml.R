#' 
#' @title Inspect an .apsim (XML) file
#' @name inspect_apsim
#' @description inspect an XML apsim file. It does not replace the GUI, but it can save time by quickly checking parameters and values.
#' @param file file ending in .apsim (Classic) to be inspected (XML)
#' @param src.dir directory containing the .apsim file to be inspected; defaults to the current working directory
#' @param node either 'Weather', 'Soil', 'SurfaceOrganicMatter', 'MicroClimate', 'Crop', 'Manager' or 'Other'
#' @param soil.child specific soil component to be inspected
#' @param parm parameter to inspect when node = 'Crop', 'Manager' or 'Other'
#' @param digits number of decimals to print (default 3)
#' @param print.path whether to print the parameter path (default = FALSE)
#' @details This is simply a script that prints the relevant parameters which are likely to need editing. It does not print all information from an .apsim file.
#'          For 'Crop', 'Manager' and 'Other' 'parm' should be indicated with a first element to look for and a second with the relative position in case there are
#'          multiple results.
#' @return table with inspected parameters and values
#' @export
#' @examples 
#' \dontrun{
#' extd.dir <- system.file("extdata", package = "apsimx")
#' ## Testing using 'Millet'
#' inspect_apsim("Millet", src.dir = extd.dir, node = "Clock")
#' inspect_apsim("Millet", src.dir = extd.dir, node = "Weather") 
#' inspect_apsim("Millet", src.dir = extd.dir, node = "Soil", soil.child = "Metadata")
#' inspect_apsim("Millet", src.dir = extd.dir, node = "Soil", soil.child = "Water")
#' inspect_apsim("Millet", src.dir = extd.dir, node = "Soil", soil.child = "OrganicMatter")
#' inspect_apsim("Millet", src.dir = extd.dir, node = "Soil", soil.child = "Analysis")
#' inspect_apsim("Millet", src.dir = extd.dir, node = "Soil", soil.child = "InitialWater")
#' inspect_apsim("Millet", src.dir = extd.dir, node = "Soil", soil.child = "Sample")
#' inspect_apsim("Millet", src.dir = extd.dir, node = "SurfaceOrganicMatter")
#' inspect_apsim("Millet", src.dir = extd.dir, node = "Crop", parm = list("sow",NA)) 
#' inspect_apsim("Millet", src.dir = extd.dir, node = "Crop", parm = list("sow",7))
#' 
#' 
#' ## Testing with maize-soybean-rotation.apsim
#' inspect_apsim("maize-soybean-rotation", src.dir = extd.dir, node = "Clock")
#' inspect_apsim("maize-soybean-rotation", src.dir = extd.dir, node = "Weather")
#' inspect_apsim("maize-soybean-rotation", src.dir = extd.dir, node = "Soil",
#'               soil.child = "Metadata")
#' inspect_apsim("maize-soybean-rotation", src.dir = extd.dir, node = "Soil", 
#'                soil.child = "OrganicMatter")
#' inspect_apsim("maize-soybean-rotation", src.dir = extd.dir, node = "Soil", 
#'                soil.child = "Analysis")
#' inspect_apsim("maize-soybean-rotation", src.dir = extd.dir, node = "Soil", 
#'                soil.child = "InitialWater")
#' inspect_apsim("maize-soybean-rotation", src.dir = extd.dir, node = "Soil", 
#'                soil.child = "Sample")
#' inspect_apsim("maize-soybean-rotation", src.dir = extd.dir, 
#'                node = "SurfaceOrganicMatter")
#' inspect_apsim("maize-soybean-rotation", src.dir = extd.dir, node = "Crop")
#' ## This has many options and a complex structure
#' ## It is possible to select unique managements, but not non-unique ones
#' ## The first element in parm can be a regular expression
#' inspect_apsim("maize-soybean-rotation", src.dir = extd.dir, 
#'                node = "Manager", parm = list("rotat",NA))
#' inspect_apsim("maize-soybean-rotation", src.dir = extd.dir, 
#'                node = "Manager", 
#'                parm = list("sow on a fixed date - maize",NA))
#' ## Select an individual row by position
#' inspect_apsim("maize-soybean-rotation", src.dir = extd.dir, 
#'               node = "Manager", 
#'               parm = list("sow on a fixed date - maize",7))
#'               
#' ## Illustrating the 'print.path' feature.
#' inspect_apsim("Millet", src.dir = extd.dir, 
#'                node = "Soil", soil.child = "Water", 
#'                parm = "DUL", print.path = TRUE)
#' ## But the path can also be returned as a string
#' ## Which is useful for later editing
#' pp <-  inspect_apsim("Millet", src.dir = extd.dir, 
#'                node = "Soil", soil.child = "Water", 
#'                parm = "DUL", print.path = TRUE)
#' }
#' 

inspect_apsim <- function(file = "", src.dir = ".", 
                          node = c("Clock","Weather","Soil","SurfaceOrganicMatter",
                                        "Crop","Manager","Other"),
                          soil.child = c("Metadata","Water","OrganicMatter", "Nitrogen",
                                         "Analysis","InitialWater","Sample",
                                         "SWIM"),
                          parm = NULL,
                          digits = 3,
                          print.path = FALSE){
  
  file.names <- dir(path = src.dir, pattern=".apsim$",ignore.case=TRUE)
  
  if(length(file.names)==0){
    stop("There are no .apsim files in the specified directory to inspect.")
  }
  
  node <- match.arg(node)
  soil.child <- match.arg(soil.child)
  
  if(print.path & missing(parm) & node != "Weather") 
    stop("parm should be specified when print.path is TRUE")
  
  ## This matches the specified file from a list of files
  ## Notice that the .apsimx extension will be added here
  file <- match.arg(file, file.names)
  
  ## Read the file
  apsim_xml <- xml2::read_xml(paste0(src.dir,"/",file))
  
  ## parm.path.0 is the 'root' path
  parm.path <- NULL
  parm.path.0 <- NULL
  parm.path.1 <- NULL

  if(node == "Clock"){
    parm.path.0 <- ".//clock"
    parms <- c("start_date", "end_date")
    for(i in parms){
      clock.node <- xml2::xml_find_first(apsim_xml, paste0(parm.path.0,"/",i))
      cat(i,":",xml2::xml_text(clock.node),"\n")
    }
    if(!missing(parm)){
      parm.path.1 <- paste0(parm.path.0,"/",parm)
    }
  }
  
  if(node == "Weather"){
    parm.path.0 <- ".//metfile/filename"
    weather.filename.node <- xml2::xml_find_first(apsim_xml, parm.path.0)
    cat("Met file:",(xml2::xml_text(weather.filename.node)),"\n")
  }
  
  ## Extracting soil Depths
  ## May be I should move this function to 'apsim_internals.R'
  ## t2d is "thickness" to "depth"
  t2d <- function(x){
    x2 <- c(0,x)/10 ## Divide by 10 to go from mm to cm
    ans <- character(length(x))
    csx2 <- cumsum(x2)
    for(i in 2:length(x2)){
        ans[i-1] <- paste0(csx2[i-1],"-",csx2[i]) 
    }
    ans
  }
  
  if(node == "Soil"){
    ## Soil depths for naming columns
    ## It seems that Depth is not explicitly exposed
    ## But Thickness is
    thickness.path <- ".//Thickness"
    soil.thickness <- as.numeric(xml2::xml_text(xml2::xml_children(xml2::xml_find_first(apsim_xml, thickness.path))))
    soil.depths <- t2d(soil.thickness)
    ## Determine the number of soil layers
    number.soil.layers <- length(soil.thickness)
    
    ## Print soil type, latitude and longitude
    cat("Soil Type: ",xml2::xml_text(xml2::xml_find_first(apsim_xml, ".//Soil/SoilType")),"\n")
    cat("Latitude: ",xml2::xml_text(xml2::xml_find_first(apsim_xml, ".//Soil/Latitude")),"\n")
    cat("Longitude: ",xml2::xml_text(xml2::xml_find_first(apsim_xml, ".//Soil/Longitude")),"\n")
    
    if(soil.child == "Metadata"){
      metadata.parms <- c("SoilType","LocalName","Site","NearestTown","Region","State",
                          "Country","ApsoilNumber","Latitude","Longitude","YearOfSampling",
                          "DataSource","Comments","NaturalVegetation")
      met.dat <- data.frame(parm = metadata.parms, value = NA)
      j <- 1
      for(i in metadata.parms){
        parm.path.0 <- ".//Soil"
        parm.path.1 <- paste0(parm.path.0,"/",i)
        soil.metadata.node <- xml2::xml_find_first(apsim_xml, parm.path.1)
        if(length(soil.metadata.node) > 0){
          met.dat[j,1] <- i
          met.dat[j,2] <- strtrim(xml2::xml_text(soil.metadata.node), options()$width - 35)
          j <- j + 1
        }
      }
      print(knitr::kable(stats::na.omit(met.dat)))
    }
    
    if(soil.child == "Water"){
      ## Crop specific
      crop.parms <- c("LL","KL","XF")
      
      val.mat <- matrix(NA, ncol = (length(crop.parms)+1),
                        nrow = number.soil.layers)
      crop.d <- data.frame(val.mat)
      crop.d[,1] <- soil.depths
      names(crop.d) <- c("Depth",crop.parms)
      j <- 2
      for(i in crop.parms){
        parm.path.0 <- ".//Soil/Water/SoilCrop"
        parm.path.1 <- paste0(parm.path.0,"/",i)
        soil.water.crop.node <- xml2::xml_find_first(apsim_xml, parm.path.1)
        crop.d[,j] <- xml2::xml_double(xml2::xml_children(soil.water.crop.node))
        j <- j + 1
      }
      
      if(!missing(parm) && parm %in% crop.parms)
          parm.path.0 <- ".//Soil/Water/SoilCrop"

      soil.parms <- c("Thickness","BD","AirDry","LL15","DUL","SAT","KS")
      val.mat <- matrix(NA, ncol = length(soil.parms),
                        nrow = number.soil.layers)
      soil.d <- data.frame(val.mat)
      names(soil.d) <- soil.parms
      j <- 1
      for(i in soil.parms){
        parm.path.0 <- ".//Soil/Water"
        parm.path.1 <- paste0(parm.path.0,"/",i)
        soil.water.node <- xml2::xml_find_first(apsim_xml, parm.path.1)
        soil.d[,j] <- xml2::xml_double(xml2::xml_children(soil.water.node))
        j <- j + 1
      }
      print(knitr::kable(cbind(crop.d,soil.d), digits = digits))
      
      if(!missing(parm) && parm %in% soil.parms) 
        parm.path.0 <- ".//Soil/Water"
      
      ## Soil Water
      soil.water.parms <- c("SummerCona", "SummerU", "SummerDate",
                            "WinterCona", "WinterU", "WinterDate",
                            "DiffusConst","DiffusSlope", "Salb",
                            "CN2Bare","CNRed","CNCov")
 
      soil.water.d <- data.frame(soil.water = soil.water.parms,
                                 value = NA)
      j <- 1
      for(i in soil.water.parms){
        parm.path.0 <- ".//Soil/SoilWater"
        parm.path.1 <- paste0(parm.path.0,"/",i)
        soil.water.node <- xml2::xml_find_first(apsim_xml, parm.path.1)
        soil.water.d[j,"value"] <- xml2::xml_text(soil.water.node)
        j <- j + 1
      }
      print(knitr::kable(soil.water.d, digits = digits))
      
      if(!missing(parm) && parm %in% soil.water.parms) 
          parm.path.0 <- ".//Soil/SoilWater"
    }
    
    if(soil.child == "SWIM"){
    
      parm.path.0 <- ".//Soil/Swim"
      ## This first set are single values
      swim.parms1 <- c("Salb","CN2Bare","CNRed","CNCov","KDul",
                      "PSIDul","VC","DTmin","DTmax","MaxWaterIncrement",
                      "SpaceWeightingFactor","SoluteSpaceWeightingFactor",
                      "Diagnostics")
      
      swim.parms1.d <- data.frame(parm = swim.parms1, value = NA)
      
      j <- 1
      for(i in swim.parms1){
        parm.path.1 <- paste0(parm.path.0,"/",i)
        swim.parm.node <- xml2::xml_find_first(apsim_xml, parm.path.1)
        swim.parms1.d[j,"value"] <- xml2::xml_text(swim.parm.node)
        j <- j + 1
      }
      print(knitr::kable(swim.parms1.d))
      
      ## Water table and Subsurface drain
      swim.parms2 <- c("SwimWaterTable/WaterTableDepth",
                       "SwimSubsurfaceDrain/DrainDepth",
                       "SwimSubsurfaceDrain/DrainSpacing",
                       "SwimSubsurfaceDrain/DrainRadius",
                       "SwimSubsurfaceDrain/Klat",
                       "SwimSubsurfaceDrain/ImpermDepth")
      
      swim.parms2.d <- data.frame(parm = gsub("/"," : ",swim.parms2), value = NA)
      
      j <- 1
      for(i in swim.parms2){
        parm.path.1.1 <- paste0(parm.path.0,"/",i)
        swim.parm.node <- xml2::xml_find_first(apsim_xml, parm.path.1.1)
        swim.parms2.d[j,"value"] <- xml2::xml_text(swim.parm.node)
        j <- j + 1
      }
      print(knitr::kable(swim.parms2.d))
      
      if(!missing(parm) && parm %in% swim.parms2){
        if(grepl("WaterTableDepth",parm,fixed=TRUE)){
          parm.path.0 <- paste0(parm.path.0,"/","SwimWaterTable")
        }else{
          parm.path.0 <- paste0(parm.path.0,"/","SwimSubsurfaceDrain")
        }
      }
    }
    
    if(soil.child == "Nitrogen"){
      stop("not implemented yet")
      nitrogen.parms <- c("fom_type","fract_carb","fract_cell","fract_lign")
      
      val.mat <- matrix(NA, ncol = length(nitrogen.parms),
                        nrow = 6, 
                        dimnames = list(NULL,nitrogen.parms))
      
      nitro.d <- data.frame(val.mat)
      k <- 1
      for(i in nitrogen.parms){
        parm.path <- paste0(".//Soil/SoilNitrogen","/",i)
        soil.nitrogen.node <- xml2::xml_find_first(apsim_xml, parm.path)
        nitro.d[,k] <- xml2::xml_text(xml2::xml_children(soil.nitrogen.node))
        k <- k + 1
      }
      print(knitr::kable(nitro.d, digits = digits))
    }
    
    if(soil.child == "OrganicMatter"){
      ## State what are organic matter possible parameters
      ## Will keep these ones hard coded
      som.parms1 <- c("RootCN","RootWt","SoilCN","EnrACoeff",
                      "EnrBCoeff")
      
      som.d1 <- data.frame(parm = som.parms1, value = NA)
      
      for(i in som.parms1){
        parm.path.0 <- ".//Soil/SoilOrganicMatter"
        parm.path.1 <- paste0(parm.path.0,"/",i)
        soil.som1.node <- xml2::xml_find_first(apsim_xml, parm.path.1)
        som.d1[som.d1$parm == i,2] <- xml2::xml_text(soil.som1.node)
      }
      print(knitr::kable(som.d1, digits = digits))
      
      som.parms2 <- c("Thickness","OC","FBiom","FInert")
      
      val.mat <- matrix(NA, ncol = (length(som.parms2)+1),
                        nrow = number.soil.layers)
      val.mat[,1] <- soil.depths
      som.d2 <- as.data.frame(val.mat)
      names(som.d2) <- c("Depth", som.parms2)
      
      j <- 2
      for(i in som.parms2){
        parm.path.0 <- ".//Soil/SoilOrganicMatter"
        parm.path.1 <- paste0(parm.path.0,"/",i)
        soil.som2.node <- xml2::xml_find_first(apsim_xml, parm.path.1)
        som.d2[,j] <- xml2::xml_text(xml2::xml_children(soil.som2.node))
        j <- j + 1
      }
      print(knitr::kable(som.d2, digits = digits))
      
      if(!missing(parm) && parm %in% c(som.parms1,som.parms2)){
        parm.path.0 <- ".//Soil/SoilOrganicMatter"
      }
    }
    
    if(soil.child == "Analysis"){
      ## I will keep this one hard coded because it is simple
      analysis.parms <- c("Thickness","PH","EC")
      
      val.mat <- matrix(NA, ncol = (length(analysis.parms)+1),
                        nrow = number.soil.layers)
      analysis.d <- as.data.frame(val.mat)
      analysis.d[,1] <- soil.depths
      names(analysis.d) <- c("Depth", analysis.parms)
      
      j <- 2
      for(i in analysis.parms){
        parm.path.0 <- ".//Soil/Analysis"
        parm.path.1 <- paste0(parm.path.1,"/",i)
        soil.analysis.node <- xml2::xml_find_first(apsim_xml, parm.path.1)
        analysis.d[,j] <- xml2::xml_text(xml2::xml_children(soil.analysis.node))
        j <- j + 1
      }
      print(knitr::kable(analysis.d, digits = digits))
      
      if(!missing(parm) && parm %in% analysis.parms){
        parm.path.0 <- ".//Soil/Analysis"
      }
    }
    
    if(soil.child == "InitialWater"){
      initialwater.parms <- c("PercentMethod","FractionFull","DepthWetSoil")
      
      initial.water.d <- data.frame(parm = initialwater.parms, value = NA)
      
      for(i in initialwater.parms){
        parm.path.0 <- ".//Soil/InitialWater"
        parm.path.1 <- paste0(parm.path.0,"/",i)
        soil.InitialWater.node <- xml2::xml_find_first(apsim_xml, parm.path.1)
        initial.water.d[initial.water.d$parm == i,2] <- xml2::xml_text(soil.InitialWater.node)
      }
      print(knitr::kable(initial.water.d, digits = digits))
      
      if(!missing(parm) && parm %in% analysis.parms){
        parm.path.0 <- ".//Soil/Analysis"
      }
    }
    
    if(soil.child == "Sample"){
      sample.parms <- c("Thickness","NO3","NH4","SW","OC","EC","CL","ESP","PH")
      
      val.mat <- matrix(NA, ncol = (length(sample.parms)+1),
                        nrow = number.soil.layers)
      sample.d <- data.frame(val.mat)
      sample.d[,1] <- soil.depths
      names(sample.d) <- c("Depth", sample.parms)
      
      j <- 2
      for(i in sample.parms){
        parm.path.0 <- ".//Soil/Sample"
        parm.path.1 <- paste0(parm.path.0,"/",i)
        soil.sample.node <- xml2::xml_find_first(apsim_xml, parm.path.1)
        sample.d[,j] <- xml2::xml_text(xml2::xml_children(soil.sample.node))
        j <- j + 1
      }
      print(knitr::kable(sample.d, digits = digits))
      
      if(!missing(parm) && parm %in% sample.parms){
        parm.path.0 <- ".//Soil/Sample"
      }
    }
  }
  
  if(node == "SurfaceOrganicMatter"){
    ## The lines below are hardcoded, which could be used if we want to
    ## restrict the variables to inspect
    ## pools.parms <- c("PoolName","ResidueType","Mass","CNRatio",
    ##             "CPRatio","StandingFraction")
    pools.path <- ".//surfaceom"
    pools.parms <- xml2::xml_name(xml2::xml_children(xml2::xml_find_first(apsim_xml, pools.path)))
      
    pools.d <- data.frame(parm = pools.parms, value = NA)
      
    for(i in pools.parms){
      parm.path.1 <- paste0(pools.path,"/",i)
      soil.pools.node <- xml2::xml_find_first(apsim_xml, parm.path.1)
      pools.d[pools.d$parm == i,2] <- xml2::xml_text(soil.pools.node)
    }
    print(knitr::kable(pools.d, digits = digits))
    
    if(!missing(parm) && parm %in% pools.parms){
      parm.path.0 <- ".//surfaceom"
    }
  }

  if(node == "Crop" | node == "Manager"){
    ## It seems that for nodes Crop and Manager, the names can be arbitrary which
    ## makes this hard parsing complicated
    cat("Crop Type: ",xml2::xml_text(xml2::xml_find_first(apsim_xml, ".//manager/ui/crop")),"\n")
    ## Make sure sowing rule is present
    xfa.manager <- as.vector(unlist(xml2::xml_attrs(xml2::xml_find_all(apsim_xml, ".//manager"))))
    cat("Management Scripts:", xfa.manager,"\n", sep = "\n")
    
    if(missing(parm)) parm.path.0 <- ".//manager"
    
    if(!missing(parm)){
      parm1 <- parm[[1]]
      position <- parm[[2]]
    
      all.manager.names <- xml2::xml_attrs(xml2::xml_find_all(apsim_xml, ".//manager"))
    
      find.parm <- grep(parm1, all.manager.names, ignore.case = TRUE)
      
      if(length(find.parm) == 0)
        stop(paste(parm1, " not found"))
      if(length(find.parm) > 1) stop("parm selection should be unique")
      
      cat("Selected manager: ", all.manager.names[[find.parm]],"\n")

      crop <- xml2::xml_find_all(apsim_xml, paste0(".//manager"))[find.parm]
      crop2 <- xml2::xml_find_first(crop, "ui")
      
      if(!is.na(position)){
        parm.path.0 <- xml2::xml_path(xml2::xml_children(crop2)[[position]])
      }else{
        parm.path.0 <- ".//manager"
      }
      
      descr <- sapply(xml2::xml_attrs(xml2::xml_children(crop2)),function(x) x[["description"]])
      vals <- xml2::xml_text(xml2::xml_children(crop2))
    
      if(is.na(position)){
        position <- 1:length(vals)
      }
      crop.d <- data.frame(parm = descr, value = vals)[position,]
      print(knitr::kable(crop.d, digits = digits))
    }
  }
  
  if(node == 'Other'){
    if(missing(parm)){
      stop("parm should be specified when node = 'Other'")
    }
    
    other.d <- NULL
    other <- xml2::xml_find_all(apsim_xml, parm)
    for(i in other){
      ms.attr <- xml2::xml_children(other)
      ms.nm <- xml2::xml_name(ms.attr)
      ms.vl <- xml2::xml_text(ms.attr)
      tmp <- data.frame(parm = ms.nm, value = ms.vl)
      other.d <- rbind(other.d, tmp)
    }
    print(knitr::kable(other.d))
    
    parm.path.0 <- xml_path(other)
    if(length(parm.path.0) > 1) stop("figure out why parm.path is greater than 1 for 'Other'")
  }
  
  if(!node %in% c("Crop","Manager") && !is.null(parm)){
    parm.path <- xml2::xml_path(xml2::xml_find_first(apsim_xml,paste0(parm.path.0,"/",parm)))
  }
    
  if(print.path){
    if(is.null(parm.path.0)) stop("root parm path not found")
    parm.path <- parm.path.0
    if(!is.null(parm.path.1)){
      parm.path <- parm.path.1
    }
    cat("Parm path:", parm.path,"\n")
  }
  invisible(parm.path)
}
