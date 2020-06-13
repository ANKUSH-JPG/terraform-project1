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
                                           
  5. Next , was to create an ebs volume and to mount it to the instance for the data persistency . so , we created a volume and attached it to the instance and enabled the force detached (to unmout when the "terraform destroy" is executed) . We also used a null resource to connect to the instance again ( to create the partitioning and to download the code using "git clone" and deploy the code in /var/www/html folder ).
   
             
              resource "aws_volume_attachment" "volume_attachment_created" {
                                    device_name = "/dev/xvdh"
                                    volume_id   = aws_ebs_volume.ebs_volume_created.id
                                    instance_id = aws_instance.my_web.id
                                    depends_on = [aws_ebs_volume.ebs_volume_created]
                                    force_detach =true
                                                                            }

                                    resource "null_resource" "second_null_resource" {

                                             depends_on = [aws_volume_attachment.volume_attachment_created]
                                             connection {
                                                    type     = "ssh"
                                                     user     = "ec2-user"
                                                    private_key = file("C:/Users/hp/Downloads/amazonAMI.pem")
                                                     host        = aws_instance.my_web.public_ip
    
                                                        } 


                                    provisioner "remote-exec" {
                                                     inline = [
                                                            "sudo fdisk -l",
                                                            "sudo mkfs.ext4 /dev/xvdh",
                                                            "sudo mount /dev/xvdh /var/www/html",
                                                            "sudo lsblk",
                                                            "sudo git clone https://github.com/ANKUSH-JPG/terraform-project1.git",
                                                            "sudo mv terraform-project1 /var/www/html"
                                                                ]
                                                              }
                                                            }
              
 6. Next , is to create a s3 bucket in order to store the images , so as to use them in our code . Along with the bucket creation we resticted the bucket access so , that only the authorised user can have a access to the content . The bucker policy would be created further when we will create cloudfront distribution .
 
                       resource "aws_s3_bucket" "bucket_created" {
                                        bucket = "terraform-bucket06"
                                            }
                      resource "aws_s3_bucket_public_access_block" "bucket_public_access_created" {
                      depends_on = [aws_s3_bucket.bucket_created]
                      bucket = "${aws_s3_bucket.bucket_created.id}"
                      block_public_acls   = true
                      block_public_policy = true
                      restrict_public_buckets = true
                      ignore_public_acls = true
                                        }
                       resource "aws_s3_bucket_object" "image1_uploaded" {
                                    depends_on = [aws_s3_bucket.bucket_created]
                                    bucket = "${aws_s3_bucket.bucket_created.id}"
                                    key    = "corona_image.jpg"
                                    source = "C:/Users/hp/Downloads/photo1.jpg"
                                    etag = "${filemd5("C:/Users/hp/Downloads/photo1.jpg")}"
                                            }
                        resource "aws_s3_bucket_object" "image2_uploaded" {
                                    depends_on = [aws_s3_bucket.bucket_created]
                                    bucket = "${aws_s3_bucket.bucket_created.id}"
                                    key    = "corona_image2.jpg"
                                    source = "C:/Users/hp/Downloads/photo2.jpg"
                                    etag = "${filemd5("C:/Users/hp/Downloads/photo2.jpg")}"
                                                }
               
 7. Next , is to create the cloudfront distribution , so that it will go on our behalf to access the images from the bucket and only allow the authorised people to access using the bucket policy that we will define soon. The distribution was attached to the same bucket we created above . A cloudfront origin access identity was also created in order to use with the cloudfront distribution . All the types of the protocols were allowed and no geo-restriction was applied.
 
                    resource "aws_cloudfront_distribution" "cloudfront_distribution_created" {
                        depends_on = [aws_cloudfront_origin_access_identity.origin_access_identity_created]
                        origin {
                            domain_name = "${aws_s3_bucket.bucket_created.bucket_regional_domain_name}"
                            origin_id   = "S3-terraform-bucket06"

                        s3_origin_config {
                            origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity_created.cloudfront_access_identity_path
                                            }
                                        }
 
                            enabled   = true

                             default_cache_behavior {
                                    allowed_methods  = [ "GET", "HEAD"]
                                    cached_methods   = ["GET", "HEAD"]
                                    target_origin_id = "S3-terraform-bucket06"

                          forwarded_values {
                                    query_string = false

                                    cookies {
                                        forward = "none"
                                             }
                                        }

                           viewer_protocol_policy = "allow-all"
                            min_ttl                = 0
                            default_ttl            = 3600
                            max_ttl                = 86400
                                }

                            restrictions {
                                geo_restriction {
                                        restriction_type = "none"
                                                }
                                            }

                             viewer_certificate {
                                    cloudfront_default_certificate = true
                                                }

                                             }
                                             
 8. Next , we created the bucket policy and attached it to the bucket that was created using s3.
 
                data "aws_iam_policy_document" "s3_policy" {
  
                                     statement {
                                             actions   = ["s3:GetObject"]
                                             resources = ["${aws_s3_bucket.bucket_created.arn}/*"]

                                             principals {
                                                   type        = "AWS"
                                                   identifiers = ["${aws_cloudfront_origin_access_identity.origin_access_identity_created.iam_arn}"]
                                                        }
                                                    }

                                             statement {
                                                    actions   = ["s3:ListBucket"]
                                                    resources = ["${aws_s3_bucket.bucket_created.arn}"]

                                            principals {
                                                     type        = "AWS"
                                                    identifiers = ["${aws_cloudfront_origin_access_identity.origin_access_identity_created.iam_arn}"]
                                                        }
                                                    }
                                                   }

                  resource "aws_s3_bucket_policy" "bucket_policy_created" {
                            depends_on = [aws_cloudfront_origin_access_identity.origin_access_identity_created]
                            bucket = "${aws_s3_bucket.bucket_created.id}"
                            policy = "${data.aws_iam_policy_document.s3_policy.json}"
                                    } 
# 6. FINAL OUTPUT:
   THE OUTPUT WHEN THE PUBLIC IP OF THE INSTANCE WAS USED ALON WITH PORT 80.
    
   ![Screenshot (440)](https://user-images.githubusercontent.com/51692515/84570869-a789e100-adad-11ea-9276-36b08eaa85bc.png)
# 5. TERRAFORM CODE IN ACTION :
   ![Screenshot (420)](https://user-images.githubusercontent.com/51692515/84570785-43ffb380-adad-11ea-9d08-09f0b947360d.png)
   
   ![Screenshot (421)](https://user-images.githubusercontent.com/51692515/84570791-46620d80-adad-11ea-9d50-f37e49178aa6.png)
   
   ![Screenshot (422)](https://user-images.githubusercontent.com/51692515/84570805-54179300-adad-11ea-9a89-85963daf7b1c.png)
   
   ![Screenshot (423)](https://user-images.githubusercontent.com/51692515/84570801-50840c00-adad-11ea-9e44-85f378371a9e.png)
   
   ![Screenshot (424)](https://user-images.githubusercontent.com/51692515/84570803-524dcf80-adad-11ea-9f6a-c9a6a33cdf1c.png)
   
   ![Screenshot (425)](https://user-images.githubusercontent.com/51692515/84570809-5974dd80-adad-11ea-8709-83dfaa5ca1fe.png)

   ![Screenshot (426)](https://user-images.githubusercontent.com/51692515/84570806-57128380-adad-11ea-9155-dc950f4fcbaa.png)
   
   ![Screenshot (427)](https://user-images.githubusercontent.com/51692515/84570808-5843b080-adad-11ea-876d-1c121c3a5400.png)
