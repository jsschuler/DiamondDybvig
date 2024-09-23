##################################################################################################################################
#                Hyperparameter Tuning Code                                                                                      #
#                Python Version                                                                                                  #
#                June 2023                                                                                                       #
#                John S. Schuler                                                                                                 #
#                                                                                                                                #
##################################################################################################################################

# Step 0: Import librarys

import pandas as pd
import math
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score
from sklearn.preprocessing import LabelEncoder
import optuna
import random
import subprocess
import csv
import datetime



def objective(trial):
    params={
    'min_data_in_leaf' : trial.suggest_int('min_data_in_leaf', 10, 100),
    'learning_rate'    : trial.suggest_float('learning_rate', 0.01, 0.1),
    }
    

    return PPE10

rounds=5000
sweep=100
study = optuna.create_study(direction='maximize')
study.optimize(objective, n_trials=sweep)
best_params = study.best_params
best_value = study.best_value
# now fit with best parameters 
model = lgb.train(best_params, train_data, num_boost_round=rounds, valid_sets=[test_data_IN])
# now get the PPE10 for the second holdout set 
trainPreds=HS(model.predict(train_data.data))
trainY=HS(train_data.label)
PPE10_train=100*np.mean((np.abs(trainPreds-trainY)/trainY) < .1)
PPE5_train=100*np.mean((np.abs(trainPreds-trainY)/trainY) < .05)
inPreds=HS(model.predict(test_data_IN.data))
inY=HS(test_data_IN.label)
PPE10_in=100*np.mean((np.abs(inPreds-inY)/inY) < .1)
PPE5_in=100*np.mean((np.abs(inPreds-inY)/inY) < .05)
outPreds=HS(model.predict(test_data_OUT.data))
outY=HS(test_data_OUT.label)
PPE10_out=100*np.mean((np.abs(outPreds-outY)/outY) < .1)
PPE5_out=100*np.mean((np.abs(outPreds-outY)/outY) < .05)
# Assemble Data 
print("lightGBM")
print(PPE10_out)
print("parameters")
print(best_params)

with open("/s3-mount/lightgbm/reporting/lightGBM.csv", 'a', newline='') as file:
    writer = csv.writer(file)
    writer.writerows([[fips,rounds,sweep,seed1,seed2,best_params['num_leaves'],best_params['max_depth'],best_params['min_data_in_leaf'],\
    best_params['learning_rate'],best_params['bagging_fraction'],best_params['feature_fraction'],best_params['bagging_freq'],best_params['min_child_samples'],best_value,PPE10_train,PPE5_train,PPE10_in,PPE5_in,PPE10_out,PPE5_out]])
    

# 92.36179384405959
# 92.7890796339711

# XG Boost
# 92.61514028586554
#'num_leaves': 89, 'max_depth': 10, 'min_data_in_leaf': 10, 'learning_rate': 0.02682270105142394, 'bagging_fraction': 0.9409707427662206, 'feature_fraction': 0.7875635670301094, 'bagging_freq': 1, 'min_child_samples': 19}

# now, train XG Boost

import xgboost as xgb

dtrain = xgb.DMatrix(subDat[trainDex], label[trainDex], enable_categorical=False)
dtest_in = xgb.DMatrix(subDat[testDexIn], label[testDexIn], enable_categorical=False)
dtest_out = xgb.DMatrix(subDat[testDexOut], label[testDexOut], enable_categorical=False)

params = {"objective": "reg:squarederror", "colsample_bytree" : .979,"max_depth":8,"min_child_weight":7,"eta":.1,"alpha":1,"lambda":.61,'stopping_rounds':100}

  #colsample_bytree = .979,
  #max_depth = 8,
  #min_child_weight = 7,
  #eta = .1,
  #alpha = 1,
  #nrounds =500,
  #lambda = .61,
  #objective = log_cosh_quantile_low,
  #verbose = 0)

