using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Storage;
using Microsoft.Azure.Storage.Blob;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace AzStorageTransfer.FuncApp
{
    public class ListSourceFiles
    {
        private readonly CloudBlobClient cloudBlobClient;

        public ListSourceFiles()
        {
            this.cloudBlobClient = CloudStorageAccount.Parse(Config.DataStorageConnection).CreateCloudBlobClient();
        }

        [FunctionName(nameof(ListSourceFiles))]
        public IActionResult Run(
            [HttpTrigger(AuthorizationLevel.Function, "get", Route = "sourcefiles")]
            HttpRequest req,
            ILogger log)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");
            try
            {
                var blobs = this.cloudBlobClient.GetContainerReference(Config.ScheduledContainer).ListBlobs();
                var blobList = blobs.OfType<CloudBlockBlob>().ToList();
                var dataTransferObjs = blobList.Select(b => new { 
                    b.Name, 
                    b.Properties, 
                    b.Uri, 
                    b.Metadata, 
                    Container = b.Container.Name 
                });

                return new OkObjectResult(dataTransferObjs);
            }
            catch (Exception ex)
            {
                log.LogError(ex, ex.ToString());                
                return new StatusCodeResult(StatusCodes.Status500InternalServerError);
            }
        }
    }
}