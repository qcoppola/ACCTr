# ACCTr
#This is a code for processing full sets of ACCT data
#Spits out a csv with 
#BX_RT_Avg
#BX_Success_Avg
#BX_trial_Avg
#WM_RT_Avg	
#WM_Success_Avg	
#WM_Trial_Avg	
#ts_trial_Avg
#average_RT_color_stay	
#average_RT_shape_stay	
#average_RT_color_switch
#average_RT_shape_switch	
#average_accuracy_color_stay	
#average_accuracy_shape_stay	
#average_accuracy_color_switch	
#average_accuracy_shape_switch

#####################################################

#RT for all modules will only be correct if subjects 
#have completed all 24 days of training (FOR NOW)
#For specific number of training days you'll need to 
#change the integer division in lines:
#241
#295
#411
#The number you will change it to will be NumTrainingDays * 3 (for nDT groups)
