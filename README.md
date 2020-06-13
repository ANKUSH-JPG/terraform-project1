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
   NOTE: In the code above i didnt mention my secret access key and password for the security purpose, you can use your own credentials to          create the infrastructure in aws.
