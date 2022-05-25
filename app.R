library(shiny)
library(ggplot2)
library(randomForest)
library(stats)



indind <- ""
historyfile <-  paste("./data/SwipeHistory",indind, ".sqlite", sep="")                                          
#zapis zgodovine rezultatov
link <-  paste( "./data/MzMine_Output_PlasmaBPA_Project1_New_gapFill_out",indind,".csv", sep="")
sqlitePath <- "swiperespons.sqlite"
xtraVar <- 9 
nswipeReward = 25
maxmz <- 600
baselinemin <- 0.1


source("arrangeGrobLocal.R")   #TA DVA FILA STA SAMO ZA RAZPOREDITEV PLOTOV VZPOREDNO!, nista bistvena za razumevanje delovanja kode
source("grid.arrangeLocal.R")



appDataUpdater <- function(historyfile,sqlitePath ){
    # get the database

    mydb <- DBI::dbConnect(RSQLite::SQLite(), sqlitePath)
    if("swipes" %in% DBI::dbListTables(mydb) ){
        swipedata <- DBI::dbReadTable(mydb, "swipes")
        data.exists = TRUE
        DBI::dbRemoveTable(mydb, "swipes")
    } else{
        data.exists = FALSE
    }
    DBI::dbDisconnect(mydb)
    #historyfile = paste("./data/SwipeHistory.sqlite",sep = "")
    Db <- DBI::dbConnect(RSQLite::SQLite(), historyfile)
    print(length(DBI::dbListTables(Db)))
    print(DBI::dbListTables(Db))
    if(length(DBI::dbListTables(Db))==0){
        df <- data.frame(user=character(),
                         NatuRA=character(),
                         polarity=character(),
                         ind=integer(),
                         mz=double(),
                         rt=double(),
                         swipe=character(),
                         date=character(),
                         stringsAsFactors=FALSE)
        DBI::dbWriteTable(Db, name = "history", df)
    }
    print(length(DBI::dbListTables(Db)))
    print(DBI::dbListTables(Db))
    DBI::dbDisconnect(Db)
    if(data.exists){
        
        swipedata <- subset(swipedata, select = - iter )
        swipedata$date = as.character(Sys.time())
        Db <- DBI::dbConnect(RSQLite::SQLite(), historyfile)
        
        DBI::dbWriteTable(Db, name="history", value=swipedata, row.names=FALSE, append=TRUE)
        DBI::dbDisconnect(Db)
    }
}

saveData <- function(input, output, iter) {
    # Connect to the database
    NatuRA_members = c("Martin", "Ana")            #!!Popravil imena                    #Samo odzivi teh ljudi se štejejo za umerjanje modela
    
    NatuRA <- tolower(input$useRname) %in% tolower(NatuRA_members)                      #Preveri, če je oseba na seznamu
    
    data2 = cbind(iter, input$useRname, NatuRA, input$Polarity, output[1,,drop = FALSE])#združi vrstice, da iz inputa in outputa
    colnames(data2) = c("iter", "user", "NatuRA","polarity","ind", "mz","rt","swipe")   #prepiše ime vrstice
    
    db <- DBI::dbConnect(RSQLite::SQLite(), sqlitePath)                                 #odpre bazo podatkov; swiperespons.sqlite
    
    DBI::dbWriteTable(db, name="swipes", value=data2, row.names=FALSE, append=TRUE)     #pripne trenutne podatke
    
    DBI::dbDisconnect(db)                                                               #zapre bazo
}
#getHistory na poglagi nastavitev iz Swipehistory izbere posamezne podatke in jih vrne
getHistory <- function(input) {
    if(file.exists(historyfile)){                                                       #preveri, če ta baza že obstaja
        if(input$onlyNew == "yes"){                                                     #OČITNO JE POMEMBNO, če je new to me/natura; onlyNew pomeni da je new to NatuRa 
            # new to NatuRA
            
            Db <- DBI::dbConnect(RSQLite::SQLite(), historyfile)
            
            history_indexes <- as.integer(DBI::dbGetQuery(Db, paste("SELECT ind FROM history WHERE polarity='",input$Polarity,"' AND NatuRA=1", sep = "") )[[1]] )
                                                                                        #Filtrira glede na naboj in glede na to če je v natura ali ne
            DBI::dbDisconnect(Db)
        } else if(input$onlyNew == "no"){
            # new to me
            Db <- DBI::dbConnect(RSQLite::SQLite(), historyfile)
            
            history_indexes <- as.integer(DBI::dbGetQuery(Db, paste("SELECT ind FROM history WHERE polarity='",input$Polarity,"' AND user='", as.character(input$useRname),"'", sep = "") )[[1]] )
        }
    } else {
        history_indexes = NULL
    }
    return(history_indexes)
}
#iz baze squliteRespons izbriše vnos
OopsieDaisyRemoveDbEntry <- function(input, output, iter){
    Db <- DBI::dbConnect(RSQLite::SQLite(), sqlitePath)                                 #iz squliteRespons gleda, isto odpre bazo, izvrši ukaz, da se zbriše produkt z iter in tistim username-om
    
    if("swipes" %in% DBI::dbListTables(Db) ){
        DBI::dbExecute(Db, paste("DELETE FROM swipes WHERE user='", as.character(input$useRname),"' AND iter=", as.character(iter), sep = "") )
    }
    DBI::dbDisconnect(Db)
}

#na poglagi prejšnjih meritev izračuna model, udata tabelo shinyPos/NegData.txt
UpdateModelPredictions <- function(input, xtraVar){
    appDataUpdater(historyfile,sqlitePath)
    #step 1: get reviewed indexes and their swipe response
    Db <- DBI::dbConnect(RSQLite::SQLite(), historyfile)
    history_swipe_pos <- DBI::dbGetQuery(Db, "SELECT ind, swipe FROM history WHERE polarity='Pos' AND ind !='NA' AND NatuRA=1" ) #Posebaj importa pozitivne in negativne ione, vzame ind in swipe
    rightswipe <- history_swipe_pos[toupper(history_swipe_pos$swipe)=="RIGHT",]
    #print(rightswipe)
    history_swipe_current <- DBI::dbGetQuery(Db, paste("SELECT ind FROM history WHERE polarity='",input$Polarity,"' AND NatuRA=1", sep = "") ) # vzame samo ind od trenuutne polarnosti??
    DBI::dbDisconnect(Db)
    
    history_swipe_pos <- history_swipe_pos[!duplicated(history_swipe_pos$ind) & history_swipe_pos$swipe != "Up", ] #filtrira tiste ki so Up in izvzame duplikate

    if (nrow(history_swipe_pos) > 0) rownames(history_swipe_pos) <- paste("Pos_", history_swipe_pos$ind, sep = "")  #poimenuje vrstico Neg_/Pos_+index

    #step 2: get the time profiles matching the indices of history_swipe to train the model
    dat_pos <- read.table(file = link, sep = ",", header = TRUE)                              #prebere raw file
    dat_current <- read.table(file = link, sep = ",", header = TRUE) #prebere še raw file na tistem naboji ki je označen

    trainingData_pos <- dat_pos[dat_pos$index %in% history_swipe_pos$ind ,]                                        #za training data vzame samo tiste, ki smo jih ocenili
    if (nrow(trainingData_pos) > 0) rownames(trainingData_pos) <- paste("Pos_", trainingData_pos$index, sep = "")  #poimenuje vrstico Neg_/Pos_+index
    # reorder to match with history_swipe
    trainingData_pos <- trainingData_pos[match(history_swipe_pos$ind, trainingData_pos$index), (xtraVar+1):ncol(dat_pos)] #preuredi df, da se ujema po indexih
    trainingData <- trainingData_pos                                                        #združi vrstice

    trainingLabels_pos <- history_swipe_pos$swipe == "Right"                                                       #T/F odvisno od tega, če je levo/desno
    trainingLabels = as.factor(c(trainingLabels_pos))
    RF.model <- randomForest::randomForest(x = trainingData,                                                       #naredi model random tree z tesnimi podatki in izzidi
                                           y = trainingLabels, 
                                           ntree = 500, 
                                           importance = TRUE)
    # step 3: use model to predict unseen data
    print(RF.model$confusion)
    PredictData <- dat_current[dat_current$qSvsMB <= input$qValue &                                                #vzame samo podatke, ki imajo dovolj nizke qSvsMB, qSvsNC in index ni v testnem setu
                                   dat_current$qSvsNC <= input$qValue & 
                                   !dat_current$index %in% history_swipe_current$ind, (xtraVar+1):ncol(dat_current)]
    
    if(any(!colnames(PredictData) == colnames(trainingData))){                                                     #test, če se ujemata dataframa v imenih stolpcev
        stop("Something is wrong with the training data and testing data columns. They do not match properly.")
    }
    
    predicted.probs <- stats::predict(object = RF.model,                                                           #vzame izračunan model in ga uporabi na PredictData
                                      newdata = PredictData, 
                                      type = "prob")[,2]
    
    # set the 'modelPredicted' variable of the Predicted Data to TRUE
    dat_current$modelPredicted <- 0
    dat_current$modelPredicted[dat_current$qSvsMB <= input$qValue &                                                #očitno predvideva vrednost glede na qvrednost
                                   dat_current$qSvsNC <= input$qValue & 
                               !dat_current$index %in% history_swipe_current$ind] <- TRUE
    
    dat_current$matched <- 0
    dat_current$matched[dat_current$index %in% history_swipe_current$ind] <- -1
    dat_current$matched[dat_current$index %in% rightswipe$ind] <- 1
    
    
    # change the 'predictVal' variable of the Predicted Data to the corresponding probability
    dat_current$predictVal[dat_current$qSvsMB <= input$qValue &                                                    #napiše verjetnost (predictVal)
                               dat_current$qSvsNC <= input$qValue & 
                           !dat_current$index %in% history_swipe_current$ind] <- as.numeric(predicted.probs)
    # write the new data
    write.table(dat_current, file = link, sep = ",", row.names = F)           #updata txt file z novimi vrednostimi in shrani v originalen file
}

#Podobno kot UpdateModelPredictions(), le da ta vrne seznam verjetnosti in jih ne shrani v file
GetModelPredictions <- function(DataToPredict, xtraVar){
    
    #step 1: get reviewed indexes and their swipe response 
    Db <- DBI::dbConnect(RSQLite::SQLite(), historyfile)
    history_swipe_pos <- DBI::dbGetQuery(Db, "SELECT ind, swipe FROM history WHERE polarity='Pos' AND ind !='NA' AND NatuRA=1" ) 
    DBI::dbDisconnect(Db)
    
    history_swipe_pos <- history_swipe_pos[!duplicated(history_swipe_pos$ind) & history_swipe_pos$swipe != "Up", ]

    
    if (nrow(history_swipe_pos) > 0) rownames(history_swipe_pos) <- paste("Pos_", history_swipe_pos$ind, sep = "")  

    
    #step 2: get the time profiles matching the indices of history_swipe to train the model
    dat_pos <- read.table(file = link, sep = ",", header = TRUE)

    
    trainingData_pos <- dat_pos[dat_pos$index %in% history_swipe_pos$ind ,]
    if (nrow(trainingData_pos) > 0) rownames(trainingData_pos) <- paste("Pos_", trainingData_pos$index, sep = "") 
    # reorder to match with history_swipe
    trainingData_pos <- trainingData_pos[match(history_swipe_pos$ind, trainingData_pos$index), (xtraVar+1):ncol(dat_pos)]
    trainingData <- trainingData_pos
    
    trainingLabels_pos <- history_swipe_pos$swipe == "Right"
    trainingLabels = as.factor(c(trainingLabels_pos))                                           #podobno kot prejšnja funkcija, le da ne gleda trenutnega načina (+/-)
    
    RF.model <- randomForest::randomForest(x = trainingData,
                                           y = trainingLabels, 
                                           ntree = 500, 
                                           importance = TRUE)
    
    # step 3: use model to predict unseen data
    PredictData <- DataToPredict[, (xtraVar+1):ncol(DataToPredict)]          #!!!  spremenil iz PredictData <- DataToPredict[, (xtraVar+1):ncol(dat_current)]--> itak more biti isti ker v naslednji vrstici primerjamo colnames()
    if(any(!colnames(PredictData) == colnames(trainingData))){
        stop("Something is wrong with the training data and testing data columns. They do not match properly.")
    }
    
    # probability of interesting
    predicted.probs <- stats::predict(object = RF.model, 
                                      newdata = PredictData, 
                                      type = "prob")[,2]
    return(predicted.probs)
}

reset_history <- function(){
    # get the database
    Db <- DBI::dbConnect(RSQLite::SQLite(), historyfile)
    print(length(DBI::dbListTables(Db)))
    print(DBI::dbListTables(Db))
    df <- data.frame(user=character(),
                     NatuRA=character(),
                     polarity=character(),
                     ind=integer(),
                     mz=double(),
                     rt=double(),
                     swipe=character(),
                     date=character(),
                     stringsAsFactors=FALSE)
    DBI::dbWriteTable(Db, name = "history", df)
    print(length(DBI::dbListTables(Db)))
    print(DBI::dbListTables(Db))
    DBI::dbDisconnect(Db)
}

#user inferface
{ui <- fluidPage(
    headerPanel('This is the GOA tindeResting! app.'),
    sidebarLayout(
        sidebarPanel(
            fluidRow(
                column(6,
                       textInput("useRname", "Your name", "Martin")
                ),
                column(6, 
                       radioButtons("Preference", "Preference", choiceNames = list(
                           icon("github-alt"),
                           icon("venus"),
                           icon("mars")
                       ),
                       choiceValues = list(
                           "kitten" , "female",  "male"
                       ), 
                       inline = TRUE
                       )
                )
            ),
            fluidRow(
                column(6,
                       selectInput("Polarity", "Ion mode", c("Negative" = "Pos")) #, "Negative" = "Neg"
                ),
                column(6, 
                       radioButtons("modelFilter", "Model based filter", choiceNames = list(
                           "yes",
                           "no"
                           
                       ),
                       choiceValues = list(
                            "TRUE","FALSE"
                       ), 
                       inline = TRUE
                       )
                )
            ),
            fluidRow(
                column(6,
                       numericInput("qValue", "max q value", 1, min = 0.0, max = 1.0, step = 0.1)
                ),
                column(6, 
                       numericInput("minRT", "minimal RT (min)", 0.5, min = 0, step = 0.05)
                )
            ),
            fluidRow(
                column(6,
                       selectInput("onlyNew", "Time profiles", c("New to NatuRA" = "yes", "New to me" = "no"))
                ),
                column(6, selectInput("swipeOrder", "Swipe Order", c("Significance" = "sig", "Random" = "rnd", "Active Learning" = "AL")))
            ),
            plotOutput("selectedRegion", height = 300),
            br(),
            fluidRow(
                column(6, actionButton("undo", 
                                       "Oopsie daisy",  
                                       style="color:#fff; background-color:Crimson"),
                       align = "center", 
                       offset = 0 ),
                column(6, actionButton("ModelPredict", 
                                        "Update Predictions",  
                                        style="color:#fff; background-color:DodgerBlue"),
                       align = "center", 
                       offset = 0 ))
            
        ),
        mainPanel(
            p("Swipe the plot to the right if the time profile is interesting. Left if not."),
            p(paste("Source: ", link)),
            p(paste("Saving responses into: ", historyfile)),
            hr(),
            fluidRow(
                column(2, actionButton(inputId = "buttonLeft", label = "boring", icon = icon("arrow-left") ), align = "left", offset = 3),
                column(2, actionButton(inputId = "buttonUp", label = "other", icon = icon("arrow-up") ), align = "center", offset = 0),
                column(2, actionButton(inputId = "buttonRight", label = "interesting", icon = icon("arrow-right")), align = "right" , offset = 0)
            ),
            br(),
            fluidRow(plotOutput("profilePlot"))                 #!!popravil: shinyswiprUI
            ,
            hr(),
            h4("Swipe History"),
            tableOutput("resultsTable")
            
        )
        
    ),
    hr(),
    p("Made by Charlie Beirnaert, modified by Martin Rafael Gulin" )
    
)
}

server <- function(input, output, session) {
    # update data in the beginning, also do this when session ends to speed it up
                                             #Prestavi v history
    appDataUpdater(historyfile,sqlitePath)
    
    #card_swipe <- callModule(shinyswipr, "quote_swiper")
    
    
    dataSet <- reactive({
        dat <- read.table(file = link, sep = ",", header = TRUE)
        dat
    })
    
    dataSubset <- reactive({
        # the getHistory function knows which selection is to be made (because we give it input): user or natura based
        subset.selection <- rep(FALSE, nrow(dataSet()))                                                            #Začne z samimi FALSE
        if(input$modelFilter){                                                                                     #Tistim produktom, ki ustrezajo pogojem pripiše TRUE
            subset.selection[dataSet()$qSvsMB <= input$qValue &
                                 dataSet()$qSvsNC<= input$qValue &
                                 dataSet()$rtmed >= (input$minRT) &
                                 ! dataSet()$index %in% getHistory(input) &
                                 dataSet()$predictVal > baselinemin] <- TRUE
        }else{
            subset.selection[dataSet()$qSvsMB <= input$qValue &
                                 dataSet()$qSvsNC<= input$qValue &
                                 dataSet()$rtmed >= (input$minRT) &
                                 ! dataSet()$index %in% getHistory(input)&
                                 dataSet()$mzmed<=maxmz] <- TRUE   
        }
        subset.selection
    })
    
    selection.vector <- reactive({
        datasubset <- dataSet()[dataSubset(),]                                                                     #Izbere tiste vrstice, ki ustrezajo pogojem in jih uredi gelde na izbran swipeorder
                                                                                                                   #c("Significance" = "sig", "Random" = "rnd", "Active Learning" = "AL")
        if(input$swipeOrder == "sig"){
            modelProbs <- GetModelPredictions(datasubset, xtraVar)
            showorder <- order(modelProbs, decreasing = T)
        } else if(input$swipeOrder == "rnd"){
            showorder <- order(runif(nrow(datasubset)))
        } else if(input$swipeOrder == "AL"){
            modelProbs <- GetModelPredictions(datasubset, xtraVar)
            showorder <- order(abs(modelProbs - 0.5), decreasing = FALSE)
        }else{
            showorder <- seq(1,nrow(datasubset))
        }
        showorder
    })
    
    
    distributionPlot <- reactive({
        datasubset <- dataSet()[dataSubset(),]                                                                     #Izbere tiste vrstice, ki ustrezajo pogojem 
        
        
    })
    
    output$selectedRegion <- renderPlot({                                                                          #Izriše majhen plot vseh točk in shrani v output$selectedRegion
        
        input$useRname# to get the shit started                         #??ZAKAJ
        ggplot(dataSet(), aes(x = qSvsMB, y = qSvsNC, colour = as.factor(dataSubset()))) +
            geom_point() +
            labs(colour="Selected",
                 x = "q value. S vs MB",
                 y= "q value. S vs NC") +
            ggtitle(paste(as.character(sum(dataSubset()))," Features Selected", sep ="")) +
            theme(plot.title = element_text(hjust = 0.5))+
            coord_cartesian(xlim=c(0,1), ylim=c(0,1))
        
    })
    
    
    
    ### old shit
    output$profilePlot        <- renderPlot({
        input$useRname # to get the shit started
        datasubset <- dataSet()[dataSubset(),] #data.subset()                                                      #izbere samo tiste ki ustrezajo pogojem
        start <- (xtraVar) 
        end <-  ncol(dataSet())
        time <- as.numeric(unlist(lapply(strsplit(colnames(dataSet()[,start:end]), "_"), `[[`, 3)))                #Iz colnames vzame ime produkta in čas --> tabela more bit poimenovana XYZ_time
        type <- as.factor(unlist(lapply(strsplit(colnames(dataSet()[,start:end]), "_"), `[[`, 1)))
        aliquot <- as.factor(unlist(lapply(strsplit(colnames(dataSet()[,start:end]), "_"), `[[`, 2)))
        print(time)
        print(type)
        kk <- selection.vector()[as.numeric(appVals$k)]                                                            #appVals$k se mi zdi da je spremenljivka, ki pove katera vrstica je trenutna (id produkta?), iter v saveData()
        compoundData <- data.frame(t = time, int = as.numeric(datasubset[kk,start:end]), types = type, aliquot = aliquot)  
        compoundData$full_name <- paste(compoundData$types, compoundData$aliquot, sep='_')
        # browser()
        RTplot = as.character((round(100*(datasubset$rtmed[kk]))/100))
        MZplot = as.character(round(1000*datasubset$mzmed[kk])/1000)
        predVal <- as.character(round(1000*datasubset$predictVal[kk])/1000)
        plotname <-  paste("mz:", MZplot, "  RT:",  RTplot, "min, predicted value: ", predVal , sep = " ")
        gg1 <- ggplot(compoundData[!is.na(compoundData$t),], aes(x=t,y=int,group = full_name, colour = types)) +
            geom_line(alpha=0.7, size=1) +
            geom_segment(data= compoundData[is.na(compoundData$t),], 
                         aes(x = 0, y = int, xend = 480, yend = int, col = factor(types)), alpha=0.7, size=1)+
            geom_hline(yintercept=1000)+
            ggtitle(plotname) +
            theme_bw(base_size = 15)+
            scale_color_manual(values = c("black","darkgreen","darkred","gray50"))+
            theme(panel.grid.major = element_line(colour="gray70", size=0.5)) +
            # scale_x_continuous(breaks = c(0, 3,5,6,7,8,9,10,11,12,13,14,15,16,17,18), minor_breaks =c())+
            theme(plot.title = element_text(hjust = 0.5),
                  legend.position="bottom")
        
        gg2 <- ggplot(compoundData[!is.na(compoundData$t),], aes(x=t,y=log10(int+1),group = full_name, colour = types)) +                     #graf log10(x+1), da ni -neskončno ampak 0. Mogoče bi se bolj splačalo popraviti na nekaj manjšega?
            geom_line(alpha=0.7, size=1)+
            
            ggtitle(" ") +
            theme_bw(base_size = 15) +
            scale_color_manual(values = c("black","darkgreen","darkred","gray50"))+
            theme(panel.grid.minor = element_line(colour="gray80", size=0.5)) +
            geom_segment(data= compoundData[is.na(compoundData$t),], 
                         aes(x = 0, y = log10(int+1), xend = 480, yend = log10(int+1), col = factor(types)), alpha=0.7, size=1)+
            # scale_x_continuous(minor_breaks = c(0, 3,5,6,7,8,9,10,11,12,13,14,15,16,17,18))+
            theme(plot.title = element_text(hjust = 0.5),
                  legend.position="bottom")
        grid.arrangeLocal(gg1,gg2, layout_matrix = rbind(c(1,1,2),c(1,1,2),c(1,1,2)))
        
   
    })
    ####
    output$index <- renderText({dataSet()[dataSubset(),]$index[selection.vector()[as.numeric(appVals$k)]]})
    output$mz <- renderText({ dataSet()[dataSubset(),]$mzmed[selection.vector()[as.numeric(appVals$k)]]})
    output$rt <- renderText({dataSet()[dataSubset(),]$rtmed[selection.vector()[as.numeric(appVals$k)]]})
    
    output$resultsTable <- renderDataTable({appVals$swipes})                                                      #Naredi tabelo preteklih swipov, ki je pod grafom
    
    
    appVals <- reactiveValues( #???ZAKAJ JE DEFINIRANA ZA TEM KO JE UPORABLJENA????
        k  =  1,    #=???
        swipes = data.frame(index = character(), mz = character(), rt = character(), swipe = character())
    )

    #TU SE ZAČNE DOGODEK.
    #skoraj identično razen, da je gumb namesto swipa!
    observeEvent( input$buttonLeft,{
        #Record our last swipe results.
        appVals$swipes <- rbind(
            data.frame(index  = as.character(dataSet()[dataSubset(),]$index[selection.vector()[as.numeric(appVals$k)]]),
                       mz = as.character(dataSet()[dataSubset(),]$mzmed[selection.vector()[as.numeric(appVals$k)]]),
                       rt = as.character(dataSet()[dataSubset(),]$rtmed[selection.vector()[as.numeric(appVals$k)]]),
                       swipe  = "Left"
            ),
            appVals$swipes
        )
        #send results to the output.
        output$resultsTable <- renderTable({appVals$swipes})
        
        #update the quote
        appVals$k <-  appVals$k + 1 
        
        
        if(appVals$k %% nswipeReward == 0){
            nmales = length(list.files("www/male_celebs"))
            nfemales = length(list.files("www/female_celebs"))
            if(input$Preference == "male"){
                showModal(modalDialog(
                    modalButton(label = img(src=paste("male_celebs/male",sample(nmales,1),".jpg", sep = ""), height = 300), icon = NULL),
                    easyClose = TRUE
                ))
            } else if(input$Preference == "kitten"){
                showModal(modalDialog(
                    modalButton(label = img(src="kat.gif", height = 300), icon = NULL),
                    easyClose = TRUE
                ))
            } else if(input$Preference == "female"){
                showModal(modalDialog(
                    modalButton(label = img(src=paste("female_celebs/fem",sample(nfemales,1),".jpg", sep = ""), height = 300), icon = NULL),
                    easyClose = TRUE
                ))
            }
        }
        
        
        saveData(input, appVals$swipes, appVals$k)
        
        #send update to the ui.
        output$index <- renderText({dataSet()[dataSubset(),]$index[selection.vector()[as.numeric(appVals$k)]]})
        output$mz <- renderText({ dataSet()[dataSubset(),]$mzmed[selection.vector()[as.numeric(appVals$k)]]})
        output$rt <- renderText({dataSet()[dataSubset(),]$rtmed[selection.vector()[as.numeric(appVals$k)]]})
        
        
        
    }) #close event observe.
    #skoraj identično razen, da je gumb namesto swipa!
    observeEvent( input$buttonUp,{
        #Record our last swipe results.
        appVals$swipes <- rbind(
            data.frame(index  = as.character(dataSet()[dataSubset(),]$index[selection.vector()[as.numeric(appVals$k)]]),
                       mz = as.character(dataSet()[dataSubset(),]$mzmed[selection.vector()[as.numeric(appVals$k)]]),
                       rt = as.character(dataSet()[dataSubset(),]$rtmed[selection.vector()[as.numeric(appVals$k)]]),
                       swipe  = "Up"
            ),
            appVals$swipes
        )
        #send results to the output.
        output$resultsTable <- renderTable({appVals$swipes})
        
        #update the quote
        appVals$k <-  appVals$k + 1 
        
        if(appVals$k %% nswipeReward == 0){
            nmales = length(list.files("www/male_celebs"))
            nfemales = length(list.files("www/female_celebs"))
            if(input$Preference == "male"){
                showModal(modalDialog(
                    modalButton(label = img(src=paste("male_celebs/male",sample(nmales,1),".jpg", sep = ""), height = 300), icon = NULL),
                    easyClose = TRUE
                ))
            } else if(input$Preference == "kitten"){
                showModal(modalDialog(
                    modalButton(label = img(src="kat.gif", height = 300), icon = NULL),
                    easyClose = TRUE
                ))
            } else if(input$Preference == "female"){
                showModal(modalDialog(
                    modalButton(label = img(src=paste("female_celebs/fem",sample(nfemales,1),".jpg", sep = ""), height = 300), icon = NULL),
                    easyClose = TRUE
                ))
            }
        }
        
        saveData(input, appVals$swipes, appVals$k)
        
        #send update to the ui.
        output$index <- renderText({dataSet()[dataSubset(),]$index[selection.vector()[as.numeric(appVals$k)]]})
        output$mz <- renderText({ dataSet()[dataSubset(),]$mzmed[selection.vector()[as.numeric(appVals$k)]]})
        output$rt <- renderText({dataSet()[dataSubset(),]$rtmed[selection.vector()[as.numeric(appVals$k)]]})
        
        
        
    }) #close event observe.
    
    observeEvent( input$buttonRight,{
        #Record our last swipe results.
        appVals$swipes <- rbind(
            data.frame(index  = as.character(dataSet()[dataSubset(),]$index[selection.vector()[as.numeric(appVals$k)]]),
                       mz = as.character(dataSet()[dataSubset(),]$mzmed[selection.vector()[as.numeric(appVals$k)]]),
                       rt = as.character(dataSet()[dataSubset(),]$rtmed[selection.vector()[as.numeric(appVals$k)]]),
                       swipe  = "Right"
            ),
            appVals$swipes
        )
        #send results to the output.
        output$resultsTable <- renderTable({appVals$swipes})
        
        #update the quote
        appVals$k <-  appVals$k + 1 
        
        
        
        if(appVals$k %% nswipeReward == 0){
            nmales = length(list.files("www/male_celebs"))
            nfemales = length(list.files("www/female_celebs"))
            if(input$Preference == "male"){
                showModal(modalDialog(
                    modalButton(label = img(src=paste("male_celebs/male",sample(nmales,1),".jpg", sep = ""), height = 300), icon = NULL),
                    easyClose = TRUE
                ))
            } else if(input$Preference == "kitten"){
                showModal(modalDialog(
                    modalButton(label = img(src="www/kat.gif", height = 300), icon = NULL),
                    easyClose = TRUE
                ))
            } else if(input$Preference == "female"){
                showModal(modalDialog(
                    modalButton(label = img(src=paste("female_celebs/fem",sample(nfemales,1),".jpg", sep = ""), height = 300), icon = NULL),
                    easyClose = TRUE
                ))
            }
        }
        
        
        
        saveData(input, appVals$swipes, appVals$k)
        
        #send update to the ui.
        output$index <- renderText({dataSet()[dataSubset(),]$index[selection.vector()[as.numeric(appVals$k)]]})
        output$mz <- renderText({ dataSet()[dataSubset(),]$mzmed[selection.vector()[as.numeric(appVals$k)]]})
        output$rt <- renderText({dataSet()[dataSubset(),]$rtmed[selection.vector()[as.numeric(appVals$k)]]})
        
        
        
    }) #close event observe.
    
    observeEvent( input$undo,{
        
        
        OopsieDaisyRemoveDbEntry(input, appVals$swipes, appVals$k)
        
        showModal(modalDialog(
            title = "Reaction deleted",
            "The last reaction you submitted to the database has been deleted. The time profile will be reviewed by someone else.",
            easyClose = TRUE
        ))
        
    }) #close event observe.
    
    observeEvent( input$ModelPredict,{
        
        showModal(modalDialog(
            title = "Updating model predictions",
            "The model predictions have been updated. You will no longer see time profiles that the model flagged as uninteresting.",
            easyClose = TRUE
        ))
        
        UpdateModelPredictions(input, xtraVar)
    }) #close event observe.
    
    session$onSessionEnded(function() {                                                                            #ko se konča seja se verjetno še enkrat updata in prepiše v history
        appDataUpdater(historyfile,sqlitePath)
    })
}


shinyApp(ui, server)
