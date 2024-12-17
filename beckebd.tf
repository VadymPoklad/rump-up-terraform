terraform {
  backend "s3" {
    bucket         = "tfstate-ramp-up"           
    key            = "terraform.tfstate"       
    region         = "us-east-1"                 
    encrypt        = true                        
    dynamodb_table = "tfstate-ramp-up"          
    acl            = "private"                   
  }
}