
using System.Collections.Concurrent;
using System.Net;
using System.Text.Json;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

namespace SampleAPI;

public class API
{
    private readonly ILogger<API> _logger;

    private static readonly ConcurrentDictionary<int, Product> Products = new()
    {
        [1] = new Product(1, "Laptop", "Business Laptop", 65000),
        [2] = new Product(2, "Monitor", "27-inch QHD Monitor", 18000),
        [3] = new Product(3, "Keyboard", "Mechanical Keyboard", 3500)
    };

    private static int _nextProductId = 3;

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public API(ILogger<API> logger)
    {
        _logger = logger;
    }

    // GET /api/health
    [Function("Health")]
    public async Task<HttpResponseData> Health(
        [HttpTrigger(AuthorizationLevel.Function, "get", Route = "health")]
        HttpRequestData req)
    {
        var response = req.CreateResponse(HttpStatusCode.OK);

        await response.WriteAsJsonAsync(new
        {
            status = "Healthy",
            message = "Sample API is running."
        });

        return response;
    }

    // GET /api/products
    [Function("GetProducts")]
    public async Task<HttpResponseData> GetProducts(
        [HttpTrigger(AuthorizationLevel.Function, "get", Route = "products")]
        HttpRequestData req)
    {
        var response = req.CreateResponse(HttpStatusCode.OK);

        await response.WriteAsJsonAsync(Products.Values.OrderBy(p => p.Id));

        return response;
    }

    // GET /api/products/{id}
    [Function("GetProductById")]
    public async Task<HttpResponseData> GetProductById(
        [HttpTrigger(AuthorizationLevel.Function, "get", Route = "products/{id:int}")]
        HttpRequestData req)
    {
        if (!TryGetProductId(req, out var id))
            return req.CreateResponse(HttpStatusCode.BadRequest);

        if (!Products.TryGetValue(id, out var product))
            return req.CreateResponse(HttpStatusCode.NotFound);

        var response = req.CreateResponse(HttpStatusCode.OK);
        await response.WriteAsJsonAsync(product);

        return response;
    }

    // POST /api/products
    [Function("CreateProduct")]
    public async Task<HttpResponseData> CreateProduct(
        [HttpTrigger(AuthorizationLevel.Function, "post", Route = "products")]
        HttpRequestData req)
    {
        ProductRequest? request;

        try
        {
            request = await JsonSerializer.DeserializeAsync<ProductRequest>(
                req.Body, JsonOptions);
        }
        catch (JsonException)
        {
            return req.CreateResponse(HttpStatusCode.BadRequest);
        }

        if (request == null ||
            string.IsNullOrWhiteSpace(request.Name) ||
            string.IsNullOrWhiteSpace(request.Description) ||
            request.Price <= 0)
        {
            return req.CreateResponse(HttpStatusCode.BadRequest);
        }

        var id = Interlocked.Increment(ref _nextProductId);

        var product = new Product(
            id,
            request.Name,
            request.Description,
            request.Price);

        Products[id] = product;

        var response = req.CreateResponse(HttpStatusCode.Created);
        await response.WriteAsJsonAsync(product);

        return response;
    }

    // PUT /api/products/{id}
    [Function("UpdateProduct")]
    public async Task<HttpResponseData> UpdateProduct(
        [HttpTrigger(AuthorizationLevel.Function, "put", Route = "products/{id:int}")]
        HttpRequestData req)
    {
        if (!TryGetProductId(req, out var id))
            return req.CreateResponse(HttpStatusCode.BadRequest);

        if (!Products.ContainsKey(id))
            return req.CreateResponse(HttpStatusCode.NotFound);

        ProductRequest? request;

        try
        {
            request = await JsonSerializer.DeserializeAsync<ProductRequest>(
                req.Body, JsonOptions);
        }
        catch (JsonException)
        {
            return req.CreateResponse(HttpStatusCode.BadRequest);
        }

        if (request == null ||
            string.IsNullOrWhiteSpace(request.Name) ||
            string.IsNullOrWhiteSpace(request.Description) ||
            request.Price <= 0)
        {
            return req.CreateResponse(HttpStatusCode.BadRequest);
        }

        var product = new Product(
            id,
            request.Name,
            request.Description,
            request.Price);

        Products[id] = product;

        var response = req.CreateResponse(HttpStatusCode.OK);
        await response.WriteAsJsonAsync(product);

        return response;
    }

    // DELETE /api/products/{id}
    [Function("DeleteProduct")]
    public Task<HttpResponseData> DeleteProduct(
        [HttpTrigger(AuthorizationLevel.Function, "delete", Route = "products/{id:int}")]
        HttpRequestData req)
    {
        if (!TryGetProductId(req, out var id))
            return Task.FromResult(req.CreateResponse(HttpStatusCode.BadRequest));

        if (!Products.TryRemove(id, out _))
            return Task.FromResult(req.CreateResponse(HttpStatusCode.NotFound));

        return Task.FromResult(req.CreateResponse(HttpStatusCode.NoContent));
    }

    private static bool TryGetProductId(HttpRequestData req, out int id)
    {
        id = 0;

        return req.FunctionContext.BindingContext.BindingData.TryGetValue(
                   "id", out var value)
               && int.TryParse(value?.ToString(), out id);
    }
}

public record Product(
    int Id,
    string Name,
    string Description,
    decimal Price);

public class ProductRequest
{
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public decimal Price { get; set; }
}
