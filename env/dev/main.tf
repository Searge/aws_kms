provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "my_web_app" {
  instance_type = "m3.xlarge"

  tags = {
    Environment = "development"
    Service = "web-app"
  }

  root_block_device {
    volume_size = 1000
  }
}

resource "aws_lambda_function" "my_hello_world" {
  function_name = "my-hello-world"
  role = aws_iam_role.my_lambda.arn
  runtime = "nodejs12.x"
  memory_size = 512

  tags = {
    Environment = "Development"
  }
}
