provider "aws" {
  region     = "us-east-2"

}

variable "ami_id" {

  default="ami-026dea5602e368e96" 
}


resource "aws_key_pair" "key_pair_created" {
  key_name   = "project1_key_pair"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 email@example.com"
}


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

resource "aws_ebs_volume" "ebs_volume_created" {
  depends_on= [aws_instance.my_web]
  availability_zone = aws_instance.my_web.availability_zone
  size              = 5

  tags = {
    Name = "project1_volume"
  }
}

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

output "public_ip" {

value=aws_instance.my_web.public_ip

}

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

resource "aws_cloudfront_origin_access_identity" "origin_access_identity_created" {

   depends_on = [aws_s3_bucket_object.image2_uploaded]
   comment = "first_origin_access_identity"
  
} 

output "first"{

  value = aws_cloudfront_origin_access_identity.origin_access_identity_created
 
}

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
