tsppath <- function(nodes, startpoint=NULL, type="tsp", method="farthest")
{
    setuplocalization("STATS_TSP")
    
    procname=gtxt("Traveling Salesperson Analysis")
    warningsprocname = gtxt("Traveling Salesperson Analysis: Warnings")
    omsid="STATSTSP"
    warns = Warn(procname=warningsprocname,omsid=omsid)
    
    values <- NULL
    
    if (!is.null(startpoint) && !is.element(startpoint, nodes))
    {
        warns$warn(gtxt("Variable specified on START keyword must also be specified on NODES keyword."),
                dostop=TRUE)
    }
    
    allvars <- nodes
    
    varNum <- spssdictionary.GetVariableCount()
    varNames <- c()
    for (i in 0:(varNum-1))
    {
        varNames <- c(varNames, spssdictionary.GetVariableName(i))
    }
    
    allvarsIndex <- c()
    for (var in allvars)
    {
        allvarsIndex <- c(allvarsIndex, match(var, varNames))
    }
    allvarsIndex <- sort(allvarsIndex)
    
    allvars <- c()
    for (i in allvarsIndex)
    {
        allvars <- c(allvars, varNames[i])
    }
    
    len <- length(allvars)
    
    if (len > 0 && len < varNum)
    {
        cmd <- "COMPUTE filter = "
        cmd <- paste(cmd, allvars[[1]], "=0", sep="")
        for ( i in 2 : length(allvars)) 
        {
            variable <- paste(allvars[[i]], "=0", sep="")
            cmd <- paste(cmd, variable, sep=" | ")
        }
        spsspkg.Submit(cmd)
        spsspkg.Submit("FILTER BY filter.")
        spsspkg.Submit("EXECUTE.")
        values <- spssdata.GetDataFromSPSS(allvars)
        spsspkg.Submit("FILTER OFF.")
        spsspkg.Submit("DELETE VARIABLES filter.")
    }
    else
    {
        values <- spssdata.GetDataFromSPSS(allvars)
    }
    count = nrow(values)
    varname <- unlist(labels(values)[2])
    data <- matrix(unlist(values), count, count, dimnames=list(varname, varname))
    
    tryCatch(library("TSP"), error=function(e){
        warns$warn(gtxtf("The R %s package is required but could not be loaded.", "TSP"),dostop=TRUE)
        }
    )
    
    type <- tolower(type)
    if (type == "tsp")
        tsp_data <- TSP(data)
    else if (type == "atsp")
        tsp_data <- ATSP(data)
    
    method_name <- switch(tolower(method), nn="nn", repetitive="repetitive_nn", nearest="nearest_insertion", farthest="farthest_insertion", cheapest="cheapest_insertion", arbitrary="arbitrary_insertion", two_opt="2-opt")
    tour <- solve_TSP(tsp_data, method=method_name)
    
    labs <- labels(tour)
    index <- as.integer(tour)
    len <- length(tour)
    if (!is.null(startpoint))
    {
        startIndex <- match(startpoint, labs)
        tailCount <- len-startIndex+1
        headCount <- startIndex-1
        labs <- c(tail(labs, tailCount), head(labs, headCount))
        index <- c(tail(index, tailCount), head(index, headCount))
    }
    
    #Create pivot table
    labs <- c(labs, labs[1])
    index <- c(index, index[1])
    no_dummy_len <- len + 1
    cost <- c(data[(index[1]-1) * len + index[1]])
    
    for (i in 2:no_dummy_len)
    {
        cost <- c(cost, data[(index[i]-1) * len + index[i-1]])
    }
    
    charIndex <- c(1:no_dummy_len, "Total")
    labs <- c(labs, "")
    cost <- c(cost, tour_length(tour))
    
    StartProcedure(procname, omsid)
    method_name_disp <- switch(tolower(method), nn="Nearest neighbor", repetitive="Repetitive nearest neighbor", nearest="Nearest insertion", farthest="Farthest insertion", cheapest="Cheapest insertion", arbitrary="Arbitrary insertion", two_opt="2-Opt improvement heuristic")

    spsspivottable.Display(data.frame(labs, cost), title="Solution", caption=paste("Method: ",method_name_disp), 
                rowdim="Order", hiderowdimtitle=FALSE, rowlabels=charIndex, collabels=c("Node", "Cost"))
    spsspkg.EndProcedure()
}

Run <- function(args) {

    cmdname = args[[1]]
    args = args[[2]]
    oobj = spsspkg.Syntax(list(
        spsspkg.Template("NODES", subc="", ktype="existingvarlist", var="nodes", islist=TRUE),
        spsspkg.Template("START", subc="OPTIONS", ktype="existingvarlist", var="startpoint", islist=FALSE),
        spsspkg.Template("TYPE", subc="OPTIONS", ktype="literal", var="type", vallist=list("tsp", "atsp")),
        spsspkg.Template("METHOD", subc="OPTIONS", ktype="literal", var="method", vallist=list("nn", "repetitive", "nearest", "farthest", "cheapest", "arbitrary", "two_opt")),
        spsspkg.Template("HELP", subc="", ktype="bool")
    ))
    
    if ("HELP" %in% attr(args,"names")) {
        helper("Traveling_Salesperson_Problem")
    }
    else {
        res <- spsspkg.processcmd(oobj, args, "tsppath")
    }
}

gtxt <- function(...) {
    return(gettext(...,domain="STATS_TSP"))
}

gtxtf <- function(...) {
    return(gettextf(...,domain="STATS_TSP"))
}

StartProcedure<-function(procname, omsid){
if (as.integer(substr(spsspkg.GetSPSSVersion(),1, 2)) >= 19)
    spsspkg.StartProcedure(procname,omsid)
else
    spsspkg.StartProcedure(omsid)
}

Warn = function(procname, omsid) {
  # constructor (sort of) for message management
  lcl = list(
    procname=procname,
    omsid=omsid,
    msglist = list(),  # accumulate messages
    msgnum = 0
  )
  # This line is the key to this approach
  lcl = mylist2env(lcl) # makes this list into an environment
  
  lcl$warn = function(msg=NULL, dostop=FALSE, inproc=FALSE) {
    # Accumulate messages and, if dostop or no message, display all
    # messages and end procedure state
    # If dostop, issue a stop.
    
    if (!is.null(msg)) { # accumulate message
      assign("msgnum", lcl$msgnum + 1, envir=lcl)
      # There seems to be no way to update an object, only replace it
      m = lcl$msglist
      m[[lcl$msgnum]] = msg
      assign("msglist", m, envir=lcl)
    } 
    
    if (is.null(msg) || dostop) {
      lcl$display(inproc)  # display messages and end procedure state
      if (dostop) {
        stop(gtxt("End of procedure"), call.=FALSE)  # may result in dangling error text
      }
    }
  }
  
  lcl$display = function(inproc=FALSE) {
    # display any accumulated messages as a warnings table or as prints
    # and end procedure state, if any
    
    if (lcl$msgnum == 0) {   # nothing to display
      if (inproc) {
        spsspkg.EndProcedure()
      }
    } else {
      if (!inproc) {
        procok =tryCatch({
          StartProcedure(lcl$procname, lcl$omsid)
          TRUE
        },
        error = function(e) {
          FALSE
        }
        )
      }
      if (procok) {  # build and display a Warnings table if we can
        table = spss.BasePivotTable("Warnings ","Warnings", isSplit=FALSE) # do not translate this
        rowdim = BasePivotTable.Append(table,Dimension.Place.row, 
                                       gtxt("Message Number"), hideName = FALSE,hideLabels = FALSE)
        
        for (i in 1:lcl$msgnum) {
          rowcategory = spss.CellText.String(as.character(i))
          BasePivotTable.SetCategories(table,rowdim,rowcategory)
          BasePivotTable.SetCellValue(table,rowcategory, 
                                      spss.CellText.String(lcl$msglist[[i]]))
        }
        spsspkg.EndProcedure()   # implies display
      } else { # can't produce a table
        for (i in 1:lcl$msgnum) {
          print(lcl$msglist[[i]])
        }
      }
    }
  }
  return(lcl)
}

mylist2env = function(alist) {
    env = new.env()
    lnames = names(alist)
    for (i in 1:length(alist)) {
        assign(lnames[[i]],value = alist[[i]], envir=env)
    }
    return(env)
}

setuplocalization = function(domain) {
    # find and bind translation file names
    # domain is the root name of the extension command .R file, e.g., "SPSSINC_BREUSCH_PAGAN"
    # This would be bound to root location/SPSSINC_BREUSCH_PAGAN/lang

    fpath = Find(file.exists, file.path(.libPaths(), paste(domain, ".R", sep="")))
    bindtextdomain(domain, file.path(dirname(fpath), domain, "lang"))
} 

if (exists("spsspkg.helper")) {
    assign("helper", spsspkg.helper)
}