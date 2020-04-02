Reading AWS Ground Station Data into Elasticsearch with Kafka

AWS Ground Station is a fully managed service by AWS that lets us control satellite communications, process data and scale our operations without having to worry about building or managing our own ground station infrastructure. With AWS Ground Station you can store and process satellite-originated data using standard AWS services like Amazon S3 Amazon Kinesis Data Streams and Amazon SageMaker.

Recently, we created a pipeline that downloads data from AWS Ground Station into AWS Elasticsearch using Kafka. The pipeline was created using the following components:


AWS Ground Station
Apache Kafka - Confluent Platform on the AWS Cloud
Amazon Cloudwatch
Amazon Elasticsearch & Kibana

The architecture of the pipeline looks like this:


AWS Ground Station

Before you start using AWS Ground Station you will need to complete the registration for your AWS Ground Station account. See the Satellites and Resources section in the AWS Ground Station console page for onboarding details.  

Once you have completed the onboarding steps you may proceed with the following steps:

Onboarding
<STEPS AFTER ONBOARDING>

Configure an AWS CloudFormation Stack
<CLOUDFORMATION STEPS>
Contacts
Once the onboarding is complete, you can schedule, review, and cancel contacts with your satellites. 
<STEPS FOR CONTACTS>
<ANY SUBSEQUENT STEPS FOR DOWNLOADING DATA>
Apache Kafka - Confluent Platform on the AWS Cloud
We used the Confluent Platform for streaming in a  large-scale distributed environment built on Apache Kafka. The Confluent Platform on AWS Quick Start is for users who are looking to evaluate and use the full range of Confluent Platform and Apache Kafka capabilities in the managed infrastructure environment of AWS. 
This Quick Start deploys Confluent Platform using AWS CloudFormation templates. You can use the Quick Start to build a new virtual private cloud (VPC) for your Confluent Platform cluster, or deploy Confluent Platform into an existing VPC.
We created a Kafka Cluster using the following configurations:
 
Broker Node Instance Type:        m4.large (1)
Producer Node Instance Type:    m4.xlarge (1)
Consumer Node Instance Type:    m4.xlarge (1)
Confluent Edition:            Confluent Open Source
Topic:                    groundstation
 


groundstation-broker-0 - Kafka Broker stores messages for Kafka topic groundstation
groundstation-producer-0 - Reads data from radio and sends messages to Kafka topic groundstation
groundstation-consumer-0 - Reads messages from Kafka topic groundstation and spools to a local file groundstation.log
Amazon Cloudwatch
We used Amazon Cloudwatch to collect messages from Kafka because the service has inbuilt functionality to stream data that it receives to Amazon Elasticsearch Service in near real-time through a CloudWatch Logs subscription. 

To accomplish this we configured an Amazon Cloudwatch Agent on the Kafka consumer and set up a subscription on the Amazon Cloudwatch Log Group to send messages to Amazon Elasticsearch service using Lambda.
Amazon Cloudwatch Agent Configuration
An Amazon Cloudwatch Agent is configured on the Kafka Consumer (groundstation-consumer-0) which collects the messages in groundstation.log and transfers them to Amazon Cloudwatch.

log-config.json
{
 "version":"1",
 "log_configs":[{"log_group_name":"/dxc/dev/groundstation/messages"}],
 "Region":"us-east-2"
}

amazon-cloudwatch-agent.toml
[agent]
  collection_jitter = "0s"
  debug = false
  flush_interval = "1s"
  flush_jitter = "0s"
  hostname = ""
  interval = "60s"
  logfile = "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
  metric_batch_size = 1000
  metric_buffer_limit = 10000
  omit_hostname = false
  precision = ""
  quiet = false
  round_interval = false

[inputs]

  [[inputs.tail]]
    data_format = "value"
    data_type = "string"
    file_state_folder = "/opt/aws/amazon-cloudwatch-agent/logs/state"
    name_override = "raw_log_line"

    [[inputs.tail.file_config]]
      file_path = "/var/log/groundstation.log"
      from_beginning = true
      log_group_name = "/dxc/dev/groundstation/messages"
      log_stream_name = "i-02728618e6211bd5a"
      pipe = false
    [inputs.tail.tags]
      metricPath = "logs"

[outputs]

  [[outputs.cloudwatchlogs]]
    file_state_folder = "/opt/aws/amazon-cloudwatch-agent/logs/state"
    force_flush_interval = "5s"
    log_stream_name = "i-02728618e6211bd5a"
    region = "us-east-2"
    tagexclude = ["metricPath"]
    [outputs.cloudwatchlogs.tagpass]
      metricPath = ["logs"]




Amazon Cloudwatch Subscription

Once the messages are received from the Cloudwatch Agent you may setup a subscription of the log group to Amazon Elasticsearch using the option as below:

The subscription uses AWS Lambda to transfer data to AWS Elasticsearch. Once the subscription has been successfully created, you should see a Lambda function in your AWS account.


Amazon Elasticsearch
Amazon Elasticsearch automatically stores the original document and adds a searchable reference to the document in the cluster’s index. You can then search and retrieve the document using the Elasticsearch API. You can also use Kibana, an open-source visualization tool, with Elasticsearch to visualize your data and build interactive dashboards. 


