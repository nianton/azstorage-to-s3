# Azure Storage to AWS S3

[![Deploy To Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fnianton%2Fazstorage-to-s3%2Fmain%2Fdeploy%2Fazure.deploy.json)

This is a solution based on Azure Functions to transfer Azure Blob Storage files to AWS S3.

The architecture of the solution is as depicted on the following diagram:

![Artitectural Diagram](./assets/AzStorage-to-AwsS3.png?raw=true)

## The role of each component
* **Azure Function** -responsible to manage the file tranfer with two approaches:
    * **BlobTrigger**: whenever a file is added on the referenced container (named 'live' by default), it causes the execution of the function to tranfer it to an AWS S3 bucket
    * **TimeTrigger**: runs in predefined time intervals tranfers all files from Azure Storage container (named 'scheduled' by default) towards AWS S3 bucket, which are then moved to an archive container (named 'archive'😊)
* **Azure Key Vault** responsible to securely store the secrets/credentials for AWS S3 and Az Data Storage Account
* **Application Insights** to provide monitoring and visibility for the health and performance of the application
* **Data Storage Account** the Storage Account that will contain the application data / blob files

**Note:** The external services / application (greyed out on the diagram using Data Factory as an example) generating the data in the Storage Account are not included.

As an example, below are the resources created when running the deployment with project: *'blobtos3'* and environment: *'dev'*

![Artitectural Diagram](./assets/AzStorage-to-AwsS3-resources.png?raw=true)
