using Amazon.S3;
using AzStorageTransfer.FuncApp;
using Microsoft.Azure.Functions.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Collections.Generic;
using System.Linq;
[assembly: FunctionsStartup(typeof(Startup))]

namespace AzStorageTransfer.FuncApp
{

    public class Startup : FunctionsStartup
    {
        public override void Configure(IFunctionsHostBuilder builder)
        {
            builder.Services.AddSingleton<IAmazonS3>(AmazonS3ClientCreate);
        }

        private static IAmazonS3 AmazonS3ClientCreate(IServiceProvider serviceProvider)
        {
            var validationErrors = ValidateAwsConfig().ToList();
            if (validationErrors.Any())
                throw new InvalidOperationException(string.Join(Environment.NewLine, validationErrors));

            return new AmazonS3Client(Config.Aws.AccessKey, Config.Aws.SecretKey, Config.Aws.Region);
        }

        private static IEnumerable<string> ValidateAwsConfig()
        {
            if (string.IsNullOrEmpty(Config.Aws.AccessKey))
                yield return "Configuration setting 'AwsAccessKey' does not have a value set";

            if (string.IsNullOrEmpty(Config.Aws.SecretKey))
                yield return "Configuration setting 'AwsSecretKey' does not have a value set";

            if (string.IsNullOrEmpty(Config.Aws.BucketName))
                yield return "Configuration setting 'AwsBucketName' does not have a value set";
        }
    }
}
