# terraform-jenkins-github-project

# USING TERRAFORM TO CREATE INFRASTRUCTURE FOR LAUNCHING THE WEB SERVER IN EC2 INSTANCE.

# 1. TASK IN SHORT:
    1.Create the key and security group which allow the port 80.
    2.Launch EC2 instance.
    3.In this Ec2 instance use the key and security group which we have created in step 1.
    4.Launch one Volume (EBS) and mount that volume into /var/www/html
    5.Developer have uploded the code into github repo also the repo has some images.
    6.Copy the github repo code into /var/www/html
    7.Create S3 bucket, and copy/deploy the images from github repo into the s3 bucket and change the permission to public readable.
    8.Create a Cloudfront using s3 bucket(which contains images) and use the Cloudfront URL to update in code in /var/www/html


# 2. CODE:
   The code i created is present above in this repo . you can have a look at it.
   
    NOTE: In the code above i didnt mention my secret access key and password for the security purpose, you can use your own credentials to create the infrastructure in aws.
    
# 3. JENKINS PART OF CREATING THE CODE:
   1. Firstly, i created the html page to be deployed in the webserver(running in aws instance)  and the photos(to be stored in s3).
     
   ![Screenshot (441)](https://user-images.githubusercontent.com/51692515/84569124-b79bc380-ada1-11ea-94e3-6a595c74c55e.png)
   
   2. I created two jobs in jenkins the first one would download the code from git hub an the second one would run the terraform file .The jobs were created using the build pipeline.
   
   ![Screenshot (419)](https://user-images.githubusercontent.com/51692515/84569273-d9e21100-ada2-11ea-8132-0c7589e339fb.png)

# 4. CREATING THE TERRAFORM CODE:
   1. The first part knowing your provider and connecting to it. here i used aws as a service provider and provided my access key and the id to log in .
            
           provider "aws" {
                           region     = "us-east-2"
                           access_key = "AKIARLICQOVGX3J65GM7"
                           secret_key = "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"
                          }
