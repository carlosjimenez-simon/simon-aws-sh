TG_ARN="arn:aws:elasticloadbalancing:us-east-1:707925622299:targetgroup/sm-dev-refactor-alfresco-tg/0764890d9815d1c1"
AWS_PROFILE="AdministratorAccess-707925622299"
AWS_REGION="us-east-1"

    echo "🎯 Borrando el Target Group..."
    aws elbv2 delete-target-group --target-group-arn $TG_ARN --profile $AWS_PROFILE --region $AWS_REGION
    echo "✅ Target Group eliminado."