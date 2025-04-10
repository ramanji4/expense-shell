#!/bin/bash

USERID=$(id -u)

LOGS_FOLDER="/var/log/expense"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIME_STAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE=$LOGS_FOLDER/$SCRIPT_NAME-$TIME_STAMP.log
mkdir -p $LOGS_FOLDER

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
        echo -e "$R $2...is FAILED...Please cehck it once $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$G $2...is SUCCESS $N" | tee -a $LOG_FILE
    fi
}

echo "Script started executing at: $(date)" | tee -a $LOG_FILE

ROOT_ACCESS

dnf list installed nginx &>>$LOG_FILE
if [ $? -ne 0 ]
then
    echo -e "$Y nginx is not installed...going to install $N" | tee -a $LOG_FILE
    dnf install nginx -y &>>$LOG_FILE
    VALIDATION $? "installing nginx"
else
    echo -e "$G nginx is already installed...$N" | tee -a $LOG_FILE
fi

systemctl enable nginx &>>$LOG_FILE
VALIDATION $? "Enabling nginx"

systemctl start nginx &>>$LOG_FILE
VALIDATION $? "Starting nginx"

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATION $? "Removing default content" 

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$LOG_FILE
VALIDATION $? "Downloading frontend code"

cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATION $? "Extracting frontend code"

cp /home/ec2-user/expense-shell/expense.conf /etc/nginx/default.d/expense.conf
VALIDATION $? "Copying expense conf" 

systemctl restart nginx &>>$LOG_FILE
VALIDATION $? "Restarting nginx" 