using Amazon.S3;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using System;
using System.Threading.Tasks;

namespace AzStorageTransfer.FuncApp
{
    public class ListDestinationFiles
    {
        private readonly IAmazonS3 amazonS3;

        public ListDestinationFiles(IAmazonS3 amazonS3)
        {
            this.amazonS3 = amazonS3;
        }

        [FunctionName(nameof(ListDestinationFiles))]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "get", Route = "destinationfiles")]
            HttpRequest req,
            ILogger log)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");
            try
            {
                var response = await amazonS3.ListObjectsAsync(Config.Aws.BucketName);
                var objects = response.S3Objects;

                return new OkObjectResult(objects);
            }
            catch (Exception ex)
            {
                return new OkObjectResult(new { error = ex.ToString() });
            }
        }
    }
}