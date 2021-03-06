from constructs import Construct
from aws_cdk import (
    CfnOutput,
    Stack,
    aws_lambda as _lambda,
    aws_apigateway as apigw,
    aws_s3 as s3,
)

from cdk_dynamo_table_view import TableViewer
from .hitcounter import HitCounter


class CdkWorkshopStack(Stack):

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # Defines and AWS Lambda resource
        my_lambda = _lambda.Function(
            self, 'HelloHandler',
            runtime=_lambda.Runtime.PYTHON_3_7,
            code=_lambda.Code.from_asset('lambda'),
            handler='hello.handler',
        )

        hello_with_counter = HitCounter(
            self, 'HelloHitCounter',
            downstream=my_lambda,
        )

        bucket = s3.Bucket(
            self, 's3cdkdatasyncevent', 
            bucket_name='s3cdkdatasyncevent2022',
        )

        CfnOutput(self, 'bucketname', value=bucket.bucket_name)
        CfnOutput(self, 'bucketarn', value=bucket.bucket_arn)

        apigw.LambdaRestApi(
            self, 'Endpoint',
            handler=hello_with_counter._handler,
        )

        TableViewer(
            self, 'ViewHitCounter',
            title='Hello Hits',
            table=hello_with_counter.table,
        )
