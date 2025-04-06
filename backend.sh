#!/bin/bash

LOGS_FOLDER="/var/log/expense"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIME_STAMP=$(+%Y-%m-%d-%H-%M-%S)
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
        echo -e "$R PLEASE RUN THE SCRIPT WITH ROOT PRIVELEGES $N" | tee -a $LOG_FILE
        exit 1
    fi
}

VALIDATION(){
    if [ $1 -ne 0 ]
    then
        echo -e " $R $2...FAILED...Please check it once $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$G $2...is SUCCESS $N" | tee -a $LOG_FILE
    fi
}

echo "Script started executing at : $(date)" | tee -a $LOG_FILE

ROOT_ACCESS

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATION $? "Disabling nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATION $? "Enabling nodejs"

dnf list installed nodejs &>>$LOG_FILE
if [ $? -ne 0 ]
then
    echo -e "$Y Nodejs is not installed...going to install it $N" | tee -a $LOG_FILE
    dnf install nodejs -y &>>$LOG_FILE
    VALIDATION $? "installing nodejs"
else
    echo -e "$G nodejs is already installed...nothing to do $N" | tee -a $LOG_FILE
fi

id expense &>>$LOG_FILE
if [ $? -ne 0 ]
then
    echo -e "$Y expense user not exists...Creating expense User now...$N" | tee -a $LOG_FILE
    useradd expense
    VALIDATION $? "Creating Expense User"
else
    echo -e "Expense user already exists...$G SKIPPING $N" | tee -a $LOG_FILE
fi

mkdir -p /app
VALIDATION $? "Creating app folder"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE
VALIDATION $? "Downloading code"

cd /app
rm -rf /app*
unzip /tmp/backend.zip &>>$LOG_FILE
VALIDATION $? "Extracting backend application code"

npm install &>>$LOG_FILE
cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service

dnf install mysql -y &>>$LOG_FILE
VALIDATION $? "installing MySQL client"

mysql -h mysql.ram4india.space -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE
VALIDATION $? "Schema loading" 

systemctl daemon-reload &>>$LOG_FILE
VALIDATION $? "Daemon reload"

systemctl enable backend &>>$LOG_FILE
VALIDATION $? "Enabling backend"

systemctl restart backend &>>$LOG_FILE
VALIDATION $? "restarting backend" 