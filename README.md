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
                           access_key = "******************"
                           secret_key = "**********************************"
                          }
                          
   2. In order to create the key pair using the code i used the aws_key_pair resource . you can check the offical docs of terraform for more details on aws_key_pair.
              
              resource "aws_key_pair" "key_pair_created" {
                             key_name   = "project1_key_pair"
                             public_key = "ssh-rsa    AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 email@example.com"
}

   3. For creating the security group i used aws_security_group resource . I gave an inbound tcp protocol and outbound was open for all protocols.
              
              resource "aws_security_group" "security_group_created" {
                     name = "project1_security_group"

                     ingress {
                        from_port = 0
                        to_port = 65535
                        protocol = "tcp"
                        cidr_blocks = ["0.0.0.0/0"]
                             }

                    egress {
                         from_port = 0
                         to_port = 0
                         protocol = "-1"
                         cidr_blocks = ["0.0.0.0/0"]
                            }
                          }
              
          
   4. Next , was to create the aws instance which would deploy the web page for us. we used ami version "ami-026dea5602e368e96" for creating the instance , the instance type was "t2.micro" , the key pair and the security group created above was used and attached to the aws instance. Next inorder to establish the connection with the ec2 instance we used connection keyword , and used SSH to connect to the instance . On remote execution we downloaded the required softwares to run deploy the page.
                       
                  resource "aws_instance" "my_web" {
                             ami           = "${var.ami_id}"
                             instance_type = "t2.micro"
                             key_name      = "amazonAMI"
                             security_groups = [aws_security_group.security_group_created.name]
                             tags = {
                                   Name = "FirstUsingTerraform"
                                    }

                            connection {
                                   type     = "ssh"
                                   user     = "ec2-user"
                                   private_key = file("C:/Users/hp/Downloads/amazonAMI.pem")
                                   host        = aws_instance.my_web.public_ip
                                        } 


                            provisioner "remote-exec" {
                                        inline = [
                                        "sudo yum update -y",
                                        "sudo yum install httpd -y",
                                        "sudo systemctl start httpd",
                                        "sudo yum install git -y"
                                                    ]
                                              }
                                           }
