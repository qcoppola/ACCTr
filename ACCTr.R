######

library(tidyverse)
library(stringr)
library(fs)
library(purrr)
library(gsubfn)
library(readr)
library(data.table)

#NOTE AVG RT WILL ONLY WORK FOR FULL ACCT DATA SETS BASED ON 24 TRAINING DAYS WITHOUT ANY DIRECTED TRAINING

#BEFORE YOU RUN,, LIST THE SUBJECTS PID IN THE ORDER THEY OCCUR IN THE FOLDER YOU'RE HOLDING IT IN
#SHOULD BE IN ASCENDING ORDER
#ADD WITH QUOTATION MARKS, INSIDE THE c() AREA IN LINE 16
subjects <- c("NSAT001", "NSAT003")
subjects <- data.frame(subjects)

#YOU CAN CHANGE THE PATH/NAME OF THE FINAL OUTPUT CSV (LINE 463)
#NOTE: FINAL CSV COLUMN K WILL NOT HAVE A NAME BUT IT IS AVERAGE_RT_COLOR_SWITCH


# List of files 
#ENTER IN THE FILE PATH TO ALL ACCT DATA
filenames <- list.files("/Users/quentincoppola/Desktop/ACCTdata/TESTINGACCTDATA", pattern = "*.csv", full.names = TRUE)


############THIS ACTUALLY WORKS#####################
#######DONT CHANGE THIS##########
#Adds full path to first column of each csv in filenames 
#Only for WM and TS, Boxed needs more cleaning before
addedFilenamesList <- 
  lapply(filenames,function(x) { 
    data <- read.csv(x,header=FALSE)
    fullPath <-rep(substr(x,1,nchar(x)),nrow(data))
    # bind date to data frame and return
    cbind(fullPath, data) 
  })

#Creates 3 lists for each module
ls_TS <- addedFilenamesList[sapply(addedFilenamesList,ncol) == 27]
ls_WM <- addedFilenamesList[sapply(addedFilenamesList,ncol) == 15]
ls_BX <- addedFilenamesList[sapply(addedFilenamesList,ncol) == 22]

#Combines each list into a big CSV for each module for further subsetting for each module in next 3 code blocks
#Fixes headers for WM
WM_all <- ls_WM %>%lapply(rename, Trial = V1,
                          Time = V2,
                          Timestamp = V3, 
                          MinHR = V4, 
                          MaxHR = V5, 
                          HR = V6, 
                          NumberOfItems = V7, 
                          Exercise = V8, 
                          NumExercise = V9 , 
                          ThresholdedRT = V10, 
                          ISI = V11, 
                          RT = V12, 
                          Timeout = V13, 
                          Success = V14) %>%
  lapply(`[`, -1,) %>%
  bind_rows 

#Fixes headers for TS
TS_all <- ls_TS %>% lapply(rename, Trial = V1,
                           Time = V2,
                           Timestamp = V3, 
                           MinHR = V4, 
                           MaxHR = V5, 
                           ThresholdedAVGStayColor = V6, 
                           TresholdedAVGStayShape = V7, 
                           ThresholdedAVGColor = V8, 
                           ThresholdedAVGShape = V9 , 
                           HR = V10, 
                           HRInZone = V11, 
                           Shape = V12, 
                           Direction = V13, 
                           StayOrSwitch = V14, 
                           Distance = V15, 
                           ColorStayDisc = V16, 
                           ColorSwitchDisc = V17, 
                           ShapeStayDisc = V18, 
                           ShapeSwitchDisc = V19, 
                           ReturnTime = V20, 
                           HitTimeWindow = V21,
                           LeftOK = V22,
                           RT = V23,
                           FasterThanWindow = V24,
                           HitTime = V25,
                           Success = V26) %>%
  lapply(`[`, -1,) %>%
  bind_rows 

#Fixes headers for BX
BX_all <- ls_BX %>% 
  lapply(rename, Trial = V1,
         Time = V2,
         Timestamp = V3, 
         MinHR = V4, 
         MaxHR = V5, 
         HR = V6, 
         NumRedDistractors = V7, 
         NumGreenDistractors = V8, 
         TargetDirecition = V9 , 
         ThresholdedRT = V10, 
         ReturnTime = V11, 
         RTWindow = V12, 
         HitTimeWindow = V13, 
         PedalingCost = V14, 
         PedalingPoints = V15, 
         ISI = V16, 
         CueInfo = V17, 
         CueStage = V18, 
         LeftOK = V19, 
         RT = V20, 
         Success = V21) %>%
  lapply(`[`, -1,) %>%
  bind_rows 


#######################################################
#Creates a list of each PT by module, maintains all 3 levels of each module 

#WM Seperate based on ID and Level
WM_all <-   WM_all %>%
  separate(fullPath, c("a", "b", "c"), sep = "\\[") %>%
  subset(select = -a) %>%
  subset(select = -c)%>%
  separate(b, c("PID", "b"),  sep = "\\]") %>%
  separate(b, c("a", "Level"), sep ="-") %>%
  subset(select = -a) %>%
  separate(PID, c("a", "PID"), sep = "[tT]") %>%
  subset(select = -a) %>%
  group_split(PID) %>%
  lapply(mutate, RT = as.numeric(levels(RT))[RT],
         NumberOfItems = as.numeric(levels(NumberOfItems))[NumberOfItems],
         Success = as.logical(Success))
  

#TS Seperate based on ID and Level
TS_all <- TS_all %>%
  separate(fullPath, c("a", "b", "c"), sep = "\\[") %>%
  subset(select = -a) %>%
  subset(select = -c)%>%
  separate(b, c("PID", "b"),  sep = "\\]") %>%
  separate(b, c("a", "Level"), sep ="-") %>%
  subset(select = -a) %>%
  separate(PID, c("a", "PID"), sep = "[tT]") %>%
  subset(select = -a) 
  #group_split(PID) will be later in the code because we have to subset this first 
#Subsets based on color/shape and stay/switch
data_ts_color <-  TS_all %>%
  select(PID, Shape, StayOrSwitch, RT, Success)%>%
  filter(Shape == "color") %>%
  group_split(PID)%>%
  lapply(mutate, RT = as.numeric(levels(RT))[RT],
         Success = as.logical(Success))

data_ts_shape <- TS_all %>%
  select(PID, Shape, StayOrSwitch, RT, Success) %>%
  filter(Shape == "shape") %>%
  group_split(PID)%>%
  lapply(mutate, RT = as.numeric(levels(RT))[RT],
         Success = as.logical(Success))

#Subset stay vs switch trials
data_ts_color_stay <-data_ts_color %>%
  lapply(filter, StayOrSwitch == "stay")

data_ts_color_switch <-data_ts_color %>%
  lapply(filter, StayOrSwitch == "switch")

data_ts_shape_stay <-data_ts_shape %>%
  lapply(filter, StayOrSwitch == "stay")

data_ts_shape_switch <-data_ts_shape %>%
  lapply(filter, StayOrSwitch == "switch")



#BX Seperate based on ID and Level
BX_all <- BX_all %>%
  separate(fullPath, c("a", "b", "c"), sep = "\\[") %>%
  subset(select = -a) %>%
  subset(select = -c)%>%
  separate(b, c("PID", "b"),  sep = "\\]") %>%
  separate(b, c("a", "Level"), sep ="-") %>%
  subset(select = -a) %>%
  separate(PID, c("a", "PID"), sep = "[tT]") %>%
  subset(select = -a)%>%
  group_split(PID)

#######################################################
#Filter based on level (OPTIONAL)
#WM
#WM1_all <- WM_all%>%
#  filter(str_detect(Level, "WM1" ))
#WM2_all <- WM_all%>%
#  filter(str_detect(Level, "WM2" ))
#WM3_all <- WM_all%>%
#  filter(str_detect(Level, "WM3" ))
#TS
#TS1_all <- TS_all%>%
#  filter(str_detect(Level, "TS1" ))
#TS2_all <- TS_all%>%
#  filter(str_detect(Level, "TS2" ))
#TS3_all <- TS_all%>%
#  filter(str_detect(Level, "TS3" ))
#BX
#BX1_all <- 
#  BX_all%>%
#  filter(str_detect(Level, "BX1" ))
#BX2_all <- BX_all%>%
#  filter(str_detect(Level, "BX2" ))
#BX3_all <- BX_all%>%
#  filter(str_detect(Level, "BX3" ))

####################################################################################################
####################################################################################################
####################################################################################################
#BOXED ANALYSIS
#dat1 <- BX_all #Change this for individual levels if you choose to do so
#Changes class of important columns
BX_all <- BX_all%>% 
  lapply(mutate,
  ReturnTime = as.numeric(ReturnTime), 
  HitTimeWindow = as.numeric(HitTimeWindow), 
  RTWindow = as.numeric(RTWindow), 
  Success = as.logical(Success))

#######################################################
#Finding the average trial number.
# Each PT played 72 times of each module (ignoring level).  Use nrow to find total number of trials per PT and divide by 72
#THIS IS ONLY FOR DT
BX_trial_Avg <-  BX_all%>%
  lapply(nrow)%>%
  bind_cols()%>%
  t()
  
#Creates a row of each trial average, PIDs will be in numerical order
BX_Trial_Avg <- data.frame(BX_trial_Avg / 72)

#############################################
#Next block creates df of all PIDs mean success, remember, they are in ascending order of PID
#Success means
BX_Success_Avg <-
  BX_all %>%
  lapply(select, Success) %>%
  lapply(mutate, Success = as.numeric(Success))%>%
  lapply(function (x) lapply(x, mean, na.rm=TRUE))%>%
  bind_cols()%>%
  t()
  
BX_Success_Avg <- 
  data.frame(BX_Success_Avg)

#############################################
#Next block creates df of all PIDs mean RT, remember, they are in ascending order of PID
#RT means

BX_RT_Avg <-
  BX_all %>%
  lapply(mutate, RT = as.numeric(levels(RT))[RT])%>%
  lapply(select, RT)%>%
  #lapply(mutate, RT = as.numeric(RT))%>%
  lapply(function (x) lapply(x, mean, na.rm=TRUE))%>%
  bind_cols()%>%
  t()

BX_RT_Avg <- 
  data.frame(BX_RT_Avg)

############################################
#Combines analysis for BX in a df
dfBX <- list(BX_RT_Avg, 
             BX_Success_Avg, 
             BX_Trial_Avg)%>%
  bind_cols
##########################################################################################
##########################################################################################
##########################################################################################
#TASK SWITCH ANALYSIS

#Trial average
# Each PT played 72 times of each module (ignoring level).  Use nrow to find total number of trials per PT and divide by 63
#THIS IS ONLY FOR DT
ts_trial_Avg <-  TS_all%>%
  group_split(PID)%>%
  lapply(nrow)%>%
  bind_cols()%>%
  t()


#Creates a row of each trial average, PIDs will be in numerical order
ts_trial_Avg <- data.frame(ts_trial_Avg / 72)


#Average RT Color_Stay
average_RT_color_stay <- 
  data_ts_color_stay %>%
  lapply(select, RT) %>%
  lapply(function (x) lapply(x, mean, na.rm=TRUE))%>%
  bind_cols()%>%
  t()
average_RT_color_stay <-
  data.frame(average_RT_color_stay)
 
#Average RT Shape_Stay
average_RT_shape_stay <- 
  data_ts_shape_stay %>%
  lapply(select, RT) %>%
  lapply(function (x) lapply(x, mean, na.rm=TRUE))%>%
  bind_cols()%>%
  t()
average_RT_shape_stay <-
  data.frame(average_RT_shape_stay)

#Average RT Color_Switch
average_RT_color_switch <- 
  data_ts_color_switch %>%
  lapply(select, RT) %>%
  lapply(function (x) lapply(x, mean, na.rm=TRUE))%>%
  bind_cols()%>%
  t()
average_RT_color_stay <-
  data.frame(average_RT_color_stay)

#Average RT Shape_Switch
average_RT_shape_switch <- 
  data_ts_shape_switch %>%
  lapply(select, RT) %>%
  lapply(function (x) lapply(x, mean, na.rm=TRUE))%>%
  bind_cols()%>%
  t()
average_RT_shape_switch <-
  data.frame(average_RT_shape_switch)

#Average Accuracy Color_Stay
average_accuracy_color_stay <- 
  data_ts_color_stay%>%
  lapply(select, Success) %>%
  lapply(mutate, Success = as.numeric(Success))%>%
  lapply(function (x) lapply(x, mean, na.rm=TRUE))%>%
  bind_cols()%>%
  t()
average_accuracy_color_stay <-
  data.frame(average_accuracy_color_stay)

#Average Accuracy Shape_Stay
average_accuracy_shape_stay <- 
  data_ts_shape_stay %>%
  lapply(select, Success) %>%
  lapply(mutate, Success = as.numeric(Success))%>%
  lapply(function (x) lapply(x, mean, na.rm=TRUE))%>%
  bind_cols()%>%
  t()
average_accuracy_shape_stay <-
  data.frame(average_accuracy_shape_stay)

#Average Accuracy Color_Switch
average_accuracy_color_switch <- 
  data_ts_color_switch %>%
  lapply(select, Success) %>%
  lapply(mutate, Success = as.numeric(Success))%>%
  lapply(function (x) lapply(x, mean, na.rm=TRUE))%>%
  bind_cols()%>%
  t()
average_accuracy_color_switch <-
  data.frame(average_accuracy_color_switch)

#Average Accuracy Shape_Switch
average_accuracy_shape_switch <-  
  data_ts_shape_switch %>%
  lapply(select, Success) %>%
  lapply(mutate, Success = as.numeric(Success))%>%
  lapply(function (x) lapply(x, mean, na.rm=TRUE))%>%
  bind_cols()%>%
  t()
average_accuracy_shape_switch <-
  data.frame(average_accuracy_shape_switch)

#Creates one big df for all the Task Switch proocessed data
dfTS <- 
  list(
    ts_trial_Avg,
    average_RT_color_stay,
    average_RT_shape_stay,
    average_RT_color_switch,
    average_RT_shape_switch,
    average_accuracy_color_stay,
    average_accuracy_shape_stay,
    average_accuracy_color_switch,
    average_accuracy_shape_switch)%>%
  bind_cols

##########################################################################################
##########################################################################################
##########################################################################################
#WORKING MEMORY ANALYSIS

#Finding the average trial number.
# Each PT played 72 times of each module (ignoring level).  Use nrow to find total number of trials per PT and divide by 72
#THIS IS ONLY FOR DT
WM_Trial_Avg <-  
  WM_all%>%
  lapply(nrow)%>%
  bind_cols()%>%
  t()

#Creates a row of each trial average, PIDs will be in numerical order
WM_Trial_Avg <- data.frame(WM_Trial_Avg / 72)

#############################################
#Next block creates df of all PIDs mean success, remember, they are in ascending order of PID
#Success means
WM_Success_Avg <-
  WM_all %>%
  lapply(select, Success) %>%
  lapply(mutate, Success = as.numeric(Success))%>%
  lapply(function (x) lapply(x, mean, na.rm=TRUE))%>%
  bind_cols()%>%
  t()

WM_Success_Avg <- 
  data.frame(WM_Success_Avg)

#############################################
#Next block creates df of all PIDs mean RT, remember, they are in ascending order of PID
#RT means
WM_RT_Avg <-
  WM_all %>%
  lapply(select, RT)%>%
  lapply(function (x) lapply(x, mean, na.rm=TRUE))%>%
  bind_cols()%>%
  t()

WM_RT_Avg <- 
  data.frame(WM_RT_Avg)

############################################
#Combines analysis for BX in a df
dfWM <- 
  list(WM_RT_Avg, 
       WM_Success_Avg, 
       WM_Trial_Avg)%>%
  bind_cols


##########################################################################################
##########################################################################################
##########################################################################################
##########################################################################################
##########################################################################################
##########################################################################################
#Creates FINAL data frame of all three modules, writes CSV 

dfALL <- list(subjects,
       dfBX,
       dfWM,
       dfTS)%>%
  bind_cols

write.csv(dfALL,"/Users/quentincoppola/Desktop/ACCTdata/SimpleTestAnalysis05.csv", row.names = FALSE)
