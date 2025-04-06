#!/bin/bash

USERID=$(id -u)

LOGS_FOLDER="/var/log/expense"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIME_STAMP=$(+%Y-%m-%d-%H-%M-%S)
SCRIPT_NAME=$LOGS_FOLDER/$SCRIPT_NAME-$TIME_STAMP.log
mkdir -p $LOGS_FOLDER

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"