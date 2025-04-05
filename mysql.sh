#!/bin/bash

LOGS_FOLDER="/var/log/expense"
SCRIPT_NAME=$(echo $0 |cut -d "." -f1)
TIME_STAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE=$LOGS_FOLDER/$SCRIPT_NAME-$TIME_STAMP.log
mkdir -p $LOGS_FOLDER

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

ROOT_ACCESS(){
    if [ $USERID -ne 0 ]
    then
        echo -e "$R PLEASE RUN THE SCRIPT WITH ROOT PRIVILEGES $N" | tee -a $LOG_FILE
        exit 1
    fi
}

VALIDATION(){
    if [ $1 -ne 0 ]
    then
        echo -e "$R $2 is...FAILED...Please check it once $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$G $2 is...SUCCESS $N" | tee -a $LOG_FILE
    fi
}

ROOT_ACCESS

echo "Script started executing at : $(date)" | tee -a $LOG_FILE


dnf list installed mysql &>>$LOG_FILE

if [ $? -ne 0 ]
then
    echo -e "$Y mysql is not installed...going to install it $N" | tee -a $LOG_FILE
    dnf install mysql-server -y
    VALIDATION $? "MySQL installation"
else
    echo -e "$G MySQL is already installed nothing to do $N" | tee -a $LOG_FILE
fi

systemctl enable mysqld &>>$LOG_FILE
VALIDATION $? "Enabling MySQL"

systemctl start mysqld &>>$LOG_FILE
VALIDATION $? "Starting MySQL"

mysql -h mysql.ram4india.space -u root -pExpenseApp@1 -e 'show databases;' &>>$LOG_FILE
if [ $? -ne 0 ]
then 
    echo -e "$Y MySQL root password is not set up...setting the password now $N" | tee -a $LOG_FILE
    mysql_secure_installation --set-root-pass ExpenseApp@1
    VALIDATION $? "setting up root password"
else
    echo -e "$G MySQL root password is already set up... $Y SKIPPING $N for now $N" | tee -a $LOG_FILE
fi