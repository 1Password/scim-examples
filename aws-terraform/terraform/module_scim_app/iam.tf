// app instance policy/role/profile

data "aws_iam_policy_document" "app" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:DescribeTags"]
    resources = ["*"]
  }

  // access to software bucket (optional)
  /*
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${APP_BUCKET}/*"]
  }
  */

  // access to secret manager
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["arn:aws:secretsmanager:${var.region}:${var.aws-account}:secret:${var.scim_secret_name}-*"]

    /* condition {
            test     = "ForAnyValue:StringEquals"
            variable = "secretsmanager:VersionStage"
            values = [ "AWSCURRENT" ]
    } */
  }
}

resource "aws_iam_role_policy" "app" {
  name   = "${var.env}-${var.application}-role-policy"
  role   = "${aws_iam_role.app.id}"
  policy = "${data.aws_iam_policy_document.app.json}"
}

data "aws_iam_policy_document" "app-assume-role-policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app" {
  name               = "${var.env}-${var.application}-role"
  assume_role_policy = "${data.aws_iam_policy_document.app-assume-role-policy.json}"
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.env}-${var.application}-instance-profile"
  role = "${aws_iam_role.app.name}"
}
