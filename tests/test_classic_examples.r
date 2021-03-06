## Write a test for running APSIM only under Windows
require(apsimx)
apsim_options(warn.versions = FALSE)

run.classic.examples <- grepl("windows",Sys.info()[["sysname"]], ignore.case = TRUE)

if(run.classic.examples){
  
  ade <- auto_detect_apsim_examples()
  
  ex <- list.files(path = ade, pattern = ".apsim$")
  ## Will only run a few
  ex.to.run <- c("Canopy","Centro","Millet","Potato","Sugar")
  
  for(i in ex.to.run){
    tmp <- apsim_example(i)
    cat("Ran (apsim_example):",i,"\n")
  }
  
  ## Test examples individually
  for(i in ex.to.run){
    file.copy(paste0(ade,"/",i,".apsim"),".")
    tmp <- apsim(paste0(i,".apsim"), cleanup = TRUE)
    file.remove(paste0("./",i,".apsim"))
    cat("Ran (apsim):",i,"\n")
  }
}




