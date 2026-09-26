using System.Net;
using System.Text.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;

namespace App.Api.Tests;

public sealed class ApiTests
{
    [Fact]
    public async Task WeatherForecast_ReturnsFiveDailyForecasts()
    {
        await using var factory = CreateFactory("Development");
        using var client = CreateClient(factory);
        var todayBeforeRequest = DateOnly.FromDateTime(DateTime.Now);

        using var response = await client.GetAsync("/weatherforecast", TestContext.Current.CancellationToken);
        var todayAfterRequest = DateOnly.FromDateTime(DateTime.Now);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("application/json", response.Content.Headers.ContentType?.MediaType);
        using var body = JsonDocument.Parse(await response.Content.ReadAsStringAsync(TestContext.Current.CancellationToken));
        var forecasts = body.RootElement.EnumerateArray().ToArray();
        Assert.Equal(5, forecasts.Length);

        for (var index = 0; index < forecasts.Length; index++)
        {
            var forecast = forecasts[index];
            var date = DateOnly.ParseExact(forecast.GetProperty("date").GetString()!, "yyyy-MM-dd");
            Assert.InRange(date, todayBeforeRequest.AddDays(index + 1), todayAfterRequest.AddDays(index + 1));
            Assert.InRange(forecast.GetProperty("temperatureC").GetInt32(), -20, 54);
            Assert.Equal(JsonValueKind.Number, forecast.GetProperty("temperatureF").ValueKind);
            Assert.False(string.IsNullOrWhiteSpace(forecast.GetProperty("summary").GetString()));
        }
    }

    [Theory]
    [InlineData("Development", HttpStatusCode.OK)]
    [InlineData("Production", HttpStatusCode.NotFound)]
    public async Task OpenApi_IsOnlyAvailableInDevelopment(string environment, HttpStatusCode expectedStatus)
    {
        await using var factory = CreateFactory(environment);
        using var client = CreateClient(factory);

        using var response = await client.GetAsync("/openapi/v1.json", TestContext.Current.CancellationToken);

        Assert.Equal(expectedStatus, response.StatusCode);
        if (expectedStatus == HttpStatusCode.OK)
        {
            using var body = JsonDocument.Parse(await response.Content.ReadAsStringAsync(TestContext.Current.CancellationToken));
            Assert.True(body.RootElement.GetProperty("paths").TryGetProperty("/weatherforecast", out _));
        }
    }

    private static WebApplicationFactory<Program> CreateFactory(string environment) =>
        new WebApplicationFactory<Program>().WithWebHostBuilder(builder => builder.UseEnvironment(environment));

    private static HttpClient CreateClient(WebApplicationFactory<Program> factory) =>
        factory.CreateClient(new WebApplicationFactoryClientOptions
        {
            BaseAddress = new Uri("https://localhost"),
            AllowAutoRedirect = false
        });
}
