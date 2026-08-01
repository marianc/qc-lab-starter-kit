using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Client.Validation;
using QCLab.Middleware;
using QCLab.Models;
using QCLab.Services;

namespace QCLab
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            var tenantTag = Environment.GetEnvironmentVariable("TENANT_TAG") ?? "Default";
            var connectionString = Environment.GetEnvironmentVariable("CONNECTION_STRING") ?? builder.Configuration.GetConnectionString("DefaultConnection");

            builder.Services.AddDataProtection()
                .PersistKeysToFileSystem(new DirectoryInfo("/app/keys"))
                .SetApplicationName($"QCLab_{tenantTag}");

            // Add services to the container.
            builder.Services.AddRazorComponents();

            builder.Services.AddDbContext<QualityControlContext>(options =>
                options.UseNpgsql(connectionString),
                ServiceLifetime.Transient,
                ServiceLifetime.Transient);

            builder.Services.AddHttpClient();
            builder.Services.AddTransient<IUniquenessChecker, ServerUniquenessChecker>();

            // Auth Services
            builder.Services.AddTransient<ServerAuthService>();
            builder.Services.AddTransient<IAuthService>(sp => sp.GetRequiredService<ServerAuthService>());
            builder.Services.AddHttpContextAccessor();
            builder.Services.AddAuthentication(options =>
                {
                    options.DefaultScheme = "CustomCookie";
                    options.DefaultChallengeScheme = "CustomCookie";
                })
                .AddCookie("CustomCookie", options =>
                {
                    options.LoginPath = "/login";
                    options.LogoutPath = "/logout";
                    options.ExpireTimeSpan = TimeSpan.FromHours(12);
                    options.Cookie.Name = $"QCLabSession_{tenantTag}";
                });
            builder.Services.AddAuthorization();
            builder.Services.AddCascadingAuthenticationState();

            // Register application services
            builder.Services.AddTransient<ICategoriesService, ServerCategoriesService>();
            builder.Services.AddTransient<ICertificatesService, ServerCertificatesService>();
            builder.Services.AddTransient<ICertificationStatusService, ServerCertificationStatusService>();
            builder.Services.AddTransient<IControlCodesService, ServerControlCodesService>();
            builder.Services.AddTransient<IFormGroupsService, ServerFormGroupsService>();
            builder.Services.AddTransient<IFormsService, ServerFormsService>();
            builder.Services.AddTransient<IMaterialsService, ServerMaterialsService>();
            builder.Services.AddTransient<IMeasurementsService, ServerMeasurementsService>();
            builder.Services.AddTransient<INormsService, ServerNormsService>();
            builder.Services.AddTransient<IReceptionsService, ServerReceptionsService>();
            builder.Services.AddTransient<IReceptionTypesService, ServerReceptionTypesService>();
            builder.Services.AddTransient<IReportsService, ServerReportsService>();
            builder.Services.AddTransient<ISpecsService, ServerSpecsService>();
            builder.Services.AddTransient<ITestsService, ServerTestsService>();
            builder.Services.AddTransient<IUnitsService, ServerUnitsService>();
            builder.Services.AddTransient<IUsersService, ServerUsersService>();
            builder.Services.AddTransient<IValueTypesService, ServerValueTypesService>();
            builder.Services.AddTransient<IFormEvalsService, ServerFormEvalsService>();

            builder.Services.AddCors(options =>
            {
                options.AddPolicy("ReactClient", policy =>
                {
                    policy.WithOrigins("http://localhost:5173", "http://localhost:8081", "http://localhost:8082", "http://localhost:8083", "http://localhost:8084", "http://localhost:8085", "http://localhost:8086", "http://localhost:8087")
                          .AllowAnyHeader()
                          .AllowAnyMethod()
                          .AllowCredentials();
                });
            });

            var app = builder.Build();

            app.UseForwardedHeaders(new ForwardedHeadersOptions
            {
                ForwardedHeaders = Microsoft.AspNetCore.HttpOverrides.ForwardedHeaders.All
            });

            // Configure the HTTP request pipeline.
            if (!app.Environment.IsDevelopment())
            {
                app.UseExceptionHandler("/Error");
            }

            app.UseStatusCodePagesWithReExecute("/not-found", createScopeForStatusCodePages: true);
            
            app.UseStaticFiles();

            app.UseCors("ReactClient");

            app.UseAuthentication();
            app.UseMiddleware<SessionAuthMiddleware>();

            // Protect all /api endpoints except login
            app.Use(async (context, next) =>
            {
                if (context.Request.Path.StartsWithSegments("/api") &&
                    !context.Request.Path.StartsWithSegments("/api/auth/login"))
                {
                    if (context.User.Identity?.IsAuthenticated != true)
                    {
                        context.Response.StatusCode = StatusCodes.Status401Unauthorized;
                        return;
                    }

                    var mustChangeClaim = context.User.FindFirst("MustChangePassword");
                    if (mustChangeClaim != null && mustChangeClaim.Value == "true")
                    {
                        if (!context.Request.Path.StartsWithSegments("/api/auth"))
                        {
                            context.Response.StatusCode = StatusCodes.Status403Forbidden;
                            return;
                        }
                    }
                }
                await next();
            });

            app.UseAuthorization();
            app.UseAntiforgery();

            app.MapStaticAssets().AllowAnonymous();

            // API Route Group with Antiforgery Disabled
            var apiGroup = app.MapGroup("/api").DisableAntiforgery();

            // Auth Endpoints
            apiGroup.MapPost("/auth/login", async ([FromBody] LoginRequest request, IAuthService authService) => 
            {
                var user = await authService.Login(request);
                return user != null ? Results.Ok(user) : Results.Unauthorized();
            }).AllowAnonymous();

            apiGroup.MapPost("/auth/logout", async (IAuthService authService) => 
            {
                await authService.Logout();
                return Results.Ok();
            });

            apiGroup.MapGet("/auth/me", async (IAuthService authService) => 
            {
                var user = await authService.GetCurrentUser();
                return user != null ? Results.Ok(user) : Results.Unauthorized();
            });

            apiGroup.MapPost("/auth/change-password", async ([FromBody] ChangePasswordDto dto, IAuthService authService) => 
            {
                var success = await authService.ChangePassword(dto);
                return success ? Results.Ok() : Results.BadRequest();
            });

            // Validation
            apiGroup.MapGet("/validate/unique", (string entity, string property, string value, long? id, string? scope_id, IUniquenessChecker checker) =>
            {
                bool isUnique;
                if (!string.IsNullOrEmpty(scope_id))
                {
                    isUnique = checker.IsUniqueScoped(entity, property, value, id, scope_id);
                }
                else
                {
                    isUnique = checker.IsUnique(entity, property, value, id);
                }
                return Results.Ok(new { is_unique = isUnique });
            });

            apiGroup.MapGet("/validate/formula", async (long formId, long testId, bool isCalculated, string? formula, IFormsService s) =>
            {
                try
                {
                    await s.ValidateFormula(formId, testId, isCalculated, formula);
                    return Results.Ok(new { valid = true });
                }
                catch (Exception ex)
                {
                    return Results.Ok(new { valid = false, msg = ex.Message });
                }
            });

            // Categories
            apiGroup.MapGet("/categories", (ICategoriesService categoriesService) => categoriesService.GetAllCategories());
            apiGroup.MapGet("/categories/{id}", (long id, ICategoriesService categoriesService) => categoriesService.GetCategory(id));
            apiGroup.MapPost("/categories", async ([FromBody] CreateCategoryDto dto, ICategoriesService categoriesService) =>
            {
                try { return Results.Ok(await categoriesService.CreateCategory(dto)); }
                catch (ArgumentException ex) { return Results.BadRequest(new { msg = ex.Message }); }
            });
            apiGroup.MapPut("/categories/{id}", async (long id, [FromBody] UpdateCategoryDto dto, ICategoriesService categoriesService) =>
            {
                try { await categoriesService.UpdateCategory(id, dto); return Results.Ok(); }
                catch (ArgumentException ex) { return Results.BadRequest(new { msg = ex.Message }); }
            });
            apiGroup.MapGet("/categories/{id}/tests", (long id, ICategoriesService categoriesService) => categoriesService.GetCategoryTests(id));
            apiGroup.MapPut("/categories/{id}/tests", (long id, [FromBody] UpdateCategoryTestsDto dto, ICategoriesService categoriesService) => categoriesService.UpdateCategoryTests(id, dto));
            apiGroup.MapPut("/categories/{id}/toggle_obsolete", (long id, [FromBody] ToggleObsoleteDto dto, ICategoriesService categoriesService) => categoriesService.ToggleObsolete(id, dto));

            // Certificates
            apiGroup.MapGet("/certificates", async (
                [FromQuery] int page,
                [FromQuery] int pageSize,
                bool isQCPersonnel,
                [FromQuery] long? materialId,
                [FromQuery] int? submissionYear,
                [FromQuery] int? submissionMonth,
                ICertificatesService s) =>
            {
                try
                {
                    return Results.Ok(await s.GetAllCertificates(page, pageSize, isQCPersonnel, materialId, submissionYear, submissionMonth));
                }
                catch (Exception ex)
                {
                    Console.Error.WriteLine($"Error in GET /certificates: {ex}");
                    return Results.BadRequest(new { msg = ex.Message, detail = ex.StackTrace });
                }
            });

            apiGroup.MapGet("/certificates/export-excel", async (
                ICertificatesService s,
                bool isQCPersonnel,
                [FromQuery] long? materialId,
                [FromQuery] int? submissionYear,
                [FromQuery] int? submissionMonth,
                [FromQuery] int? loadedPages,
                [FromServices] IHttpClientFactory clientFactory) =>
            {
                try
                {
                    var excelBytes = await s.ExportCertificatesExcel(isQCPersonnel, materialId, submissionYear, submissionMonth, loadedPages, 15, clientFactory);
                    if (excelBytes == null) return Results.NotFound();
                    return Results.File(excelBytes, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "quality_certificates.xlsx");
                }
                catch (Exception ex)
                {
                    return Results.BadRequest(new { msg = ex.Message });
                }
            });
            apiGroup.MapGet("/certificates/{id}", (long id, ICertificatesService s) => s.GetCertificate(id));
            apiGroup.MapGet("/certificates/{id}/has_existing", async (long id, ICertificatesService s) => new { hasExisting = await s.HasExistingValidCertificates(id) });
            apiGroup.MapPost("/certificates/generate", ([FromBody] GenerateCertificateDto dto, ICertificatesService s) => s.GenerateCertificate(dto));
            apiGroup.MapPut("/certificates/{id}", (long id, [FromBody] UpdateCertificateDto dto, ICertificatesService s) => s.UpdateCertificate(id, dto));
            apiGroup.MapPut("/certificates/{id}/refresh_tests", (long id, ICertificatesService s) => s.RefreshTests(id));
            apiGroup.MapGet("/certificates/{id}/analyze_results", (long id, ICertificatesService s) => s.AnalyzeResults(id));
            apiGroup.MapPut("/certificates/{id}/submit", (long id, [FromBody] CertificateActionDto dto, ICertificatesService s) => s.SubmitCertificate(id, dto));
            apiGroup.MapPut("/certificates/{id}/cancel", (long id, [FromBody] CertificateActionDto dto, ICertificatesService s) => s.CancelCertificate(id, dto));
            apiGroup.MapDelete("/certificates/{id}", async (long id, ICertificatesService s) =>
            {
                try
                {
                    await s.DeleteCertificate(id);
                    return Results.Ok(new { success = true });
                }
                catch (UnauthorizedAccessException)
                {
                    return Results.StatusCode(StatusCodes.Status403Forbidden);
                }
                catch (InvalidOperationException ex)
                {
                    return Results.BadRequest(new { msg = ex.Message });
                }
                catch (ArgumentException ex)
                {
                    return Results.BadRequest(new { msg = ex.Message });
                }
            });
            apiGroup.MapGet("/certificates/{id}/pdf", async (long id, ICertificatesService s) =>
            {
                var pdfBytes = await s.GetCertificatePdf(id);
                if (pdfBytes == null) return Results.NotFound();
                return Results.File(pdfBytes, "application/pdf", $"quality_certificate_{id}.pdf");
            });

            // Certification Status
            apiGroup.MapGet("/certification_status", (ICertificationStatusService s) => s.GetCertificationStatus());

            // Control Codes
            apiGroup.MapGet("/control_codes", (IControlCodesService s) => s.GetAllControlCodes());
            apiGroup.MapGet("/control_codes/by_material/{material_id}", (long material_id, IControlCodesService s) => s.GetControlCodesByMaterial(material_id));
            apiGroup.MapPost("/control_codes", ([FromBody] CreateControlCodeDto dto, IControlCodesService s) => s.CreateControlCode(dto));

            // Form Groups
            apiGroup.MapGet("/form_groups", (IFormGroupsService s) => s.GetAllFormGroups());
            apiGroup.MapGet("/form_groups/{id}", (long id, IFormGroupsService s) => s.GetFormGroup(id));
            apiGroup.MapPost("/form_groups", ([FromBody] CreateFormGroupDto dto, IFormGroupsService s) => s.CreateFormGroup(dto));
            apiGroup.MapPut("/form_groups/{id}", (long id, [FromBody] UpdateFormGroupDto dto, IFormGroupsService s) => s.UpdateFormGroup(id, dto));
            apiGroup.MapPut("/form_groups", ([FromBody] List<UpdateFormGroupDto> dtos, IFormGroupsService s) => s.BulkUpdateFormGroups(dtos));
            apiGroup.MapDelete("/form_groups/{id}", (long id, IFormGroupsService s) => s.DeleteFormGroup(id));
            apiGroup.MapGet("/form_groups/{id}/forms", (long id, IFormGroupsService s) => s.GetFormsByGroup(id));

            // Forms
            apiGroup.MapGet("/forms", (IFormsService s) => s.GetAllForms());
            apiGroup.MapGet("/forms/{id}", (long id, IFormsService s) => s.GetForm(id));
            apiGroup.MapPost("/forms", ([FromBody] CreateFormDto dto, IFormsService s) => s.CreateForm(dto));
            apiGroup.MapPut("/forms/{id}", (long id, [FromBody] UpdateFormDto dto, IFormsService s) => s.UpdateForm(id, dto));
            apiGroup.MapGet("/forms/{id}/params", (long id, IFormsService s) => s.GetFormParams(id));
            apiGroup.MapPut("/forms/{id}/params/reorder", (long id, [FromBody] List<ReorderFormParamDto> dtos, IFormsService s) => s.ReorderFormParams(id, dtos));
            apiGroup.MapPut("/forms/{id}/params/batch-update", (long id, [FromBody] List<BatchUpdateFormParamDto> dtos, IFormsService s) => s.BatchUpdateFormParams(id, dtos));
            apiGroup.MapPost("/forms/{id}/params", async (long id, [FromBody] CreateFormParamDto dto, IFormsService s) =>
            {
                try { return Results.Ok(await s.AddFormParam(id, dto)); }
                catch (Exception ex) { return Results.BadRequest(new { msg = ex.Message }); }
            });
            apiGroup.MapPut("/forms/{id}/params/{testId}", async (long id, long testId, [FromBody] UpdateFormParamDto dto, IFormsService s) =>
            {
                try { await s.UpdateFormParam(id, testId, dto); return Results.Ok(); }
                catch (Exception ex) { return Results.BadRequest(new { msg = ex.Message }); }
            });
            apiGroup.MapDelete("/forms/{id}/params/{testId}", async (long id, long testId, IFormsService s) =>
            {
                try { await s.DeleteFormParam(id, testId); return Results.Ok(); }
                catch (Exception ex) { return Results.BadRequest(new { msg = ex.Message }); }
            });
            apiGroup.MapPut("/forms/{id}/submit", async (long id, [FromBody] FormActionDto dto, IFormsService s) =>
            {
                try { await s.SubmitForm(id, dto); return Results.Ok(); }
                catch (Exception ex) { return Results.BadRequest(new { msg = ex.Message }); }
            });
            apiGroup.MapPut("/forms/{id}/validate", async (long id, [FromBody] FormActionDto dto, IFormsService s) =>
            {
                try { await s.ValidateForm(id, dto); return Results.Ok(); }
                catch (Exception ex) { return Results.BadRequest(new { msg = ex.Message }); }
            });
            apiGroup.MapPut("/forms/{id}/cancel", async (long id, [FromBody] FormActionDto dto, IFormsService s) =>
            {
                try { await s.CancelForm(id, dto); return Results.Ok(); }
                catch (Exception ex) { return Results.BadRequest(new { msg = ex.Message }); }
            });
            apiGroup.MapPut("/forms/{id}/reactivate", async (long id, IFormsService s) =>
            {
                try { await s.ReactivateForm(id); return Results.Ok(); }
                catch (Exception ex) { return Results.BadRequest(new { msg = ex.Message }); }
            });
            apiGroup.MapPost("/forms/{id}/duplicate", async (long id, [FromBody] FormActionDto dto, IFormsService s) =>
            {
                try { return Results.Ok(await s.DuplicateForm(id, dto)); }
                catch (Exception ex) { return Results.BadRequest(new { msg = ex.Message }); }
            });

            // Form Evals
            apiGroup.MapGet("/forms/{id}/evals", (long id, IFormEvalsService s) => s.GetFormEvals(id));
            apiGroup.MapGet("/form-evals/{id}", (long id, IFormEvalsService s) => s.GetFormEval(id));
            apiGroup.MapPost("/form-evals", ([FromBody] CreateFormEvalDto dto, IFormEvalsService s) => s.CreateFormEval(dto));
            apiGroup.MapPut("/form-evals/{id}", (long id, [FromBody] UpdateFormEvalDto dto, IFormEvalsService s) => s.UpdateFormEval(id, dto));
            apiGroup.MapDelete("/form-evals/{id}", (long id, IFormEvalsService s) => s.DeleteFormEval(id));
            apiGroup.MapPost("/form-evals/{id}/calculate", (long id, IFormEvalsService s) => s.CalculateFormEval(id));

            // Materials
            apiGroup.MapGet("/materials", (IMaterialsService s) => s.GetAllMaterials());
            apiGroup.MapGet("/materials/with_valid_spec", (IMaterialsService s) => s.GetMaterialsWithValidSpec());
            apiGroup.MapGet("/materials/{id}", (long id, IMaterialsService s) => s.GetMaterial(id));
            apiGroup.MapPost("/materials", async ([FromBody] CreateMaterialDto dto, IMaterialsService s) =>
            {
                try { return Results.Ok(await s.CreateMaterial(dto)); }
                catch (ArgumentException ex) { return Results.BadRequest(new { msg = ex.Message }); }
            });
            apiGroup.MapPut("/materials/{id}", async (long id, [FromBody] UpdateMaterialDto dto, IMaterialsService s) =>
            {
                try { await s.UpdateMaterial(id, dto); return Results.Ok(); }
                catch (ArgumentException ex) { return Results.BadRequest(new { msg = ex.Message }); }
            });
            apiGroup.MapGet("/materials/{id}/tests", (long id, IMaterialsService s) => s.GetMaterialTests(id));
            apiGroup.MapPut("/materials/{id}/tests", (long id, [FromBody] UpdateMaterialTestsDto dto, IMaterialsService s) => s.UpdateMaterialTests(id, dto));
            apiGroup.MapPut("/materials/{id}/toggle_obsolete", (long id, [FromBody] ToggleObsoleteDto dto, IMaterialsService s) => s.ToggleObsolete(id, dto));
            apiGroup.MapGet("/materials/{id}/control_codes", (long id, IMaterialsService s) => s.GetControlCodes(id));
            apiGroup.MapGet("/materials/{id}/control_codes_for_certificate", (long id, IMaterialsService s) => s.GetControlCodesForCertificate(id));

            // Measurements
            apiGroup.MapGet("/measurement_tests/{id}", (long id, IMeasurementsService s) => s.GetMeasurementTest(id));
            apiGroup.MapPut("/measurement_tests/{id}", (long id, [FromBody] UpdateMeasurementTestBulkDto dto, IMeasurementsService s) => s.UpdateMeasurementTest(id, dto));
            apiGroup.MapGet("/measurement_params/{id}", (long id, IMeasurementsService s) => s.GetMeasurementParam(id));
            apiGroup.MapPut("/measurement_params/{id}", (long id, [FromBody] UpdateMeasurementParamDto dto, IMeasurementsService s) => s.UpdateMeasurementParam(id, dto));
            apiGroup.MapPost("/measurements", ([FromBody] CreateMeasurementDto dto, IMeasurementsService s) => s.CreateMeasurement(dto));
            apiGroup.MapDelete("/measurements/{id}", (long id, IMeasurementsService s) => s.DeleteMeasurement(id));
            apiGroup.MapPut("/measurements/{id}/toggle_reported", async (long id, [FromQuery] long userId, IMeasurementsService s) => 
            {
                try
                {
                    await s.ToggleReported(id, userId);
                    return Results.Ok();
                }
                catch (Exception ex)
                {
                    return Results.BadRequest(new { msg = ex.Message });
                }
            });
            apiGroup.MapPost("/measurements/{id}/tests", (long id, [FromBody] AddMeasurementTestDto dto, IMeasurementsService s) => s.AddMeasurementTest(id, dto));

            // Norms
            apiGroup.MapGet("/norms", (INormsService s) => s.GetAllNorms());
            apiGroup.MapGet("/norms/{id}", (long id, INormsService s) => s.GetNorm(id));
            apiGroup.MapPost("/norms", async ([FromBody] CreateNormDto dto, INormsService s) =>
            {
                try { return Results.Ok(await s.CreateNorm(dto)); }
                catch (ArgumentException ex) { return Results.BadRequest(new { msg = ex.Message }); }
            });
            apiGroup.MapPut("/norms/{id}", async (long id, [FromBody] UpdateNormDto dto, INormsService s) =>
            {
                try { await s.UpdateNorm(id, dto); return Results.Ok(); }
                catch (ArgumentException ex) { return Results.BadRequest(new { msg = ex.Message }); }
            });
            apiGroup.MapPut("/norms/{id}/toggle_obsolete", (long id, [FromBody] ToggleObsoleteDto dto, INormsService s) => s.ToggleObsolete(id, dto));

            // Receptions
            apiGroup.MapGet("/receptions", (
                IReceptionsService s,
                [FromQuery] int page = 1,
                [FromQuery] int per_page = 15,
                [FromQuery] long? user_id = null,
                [FromQuery] long? submitted_by = null,
                [FromQuery] long? type_id = null,
                [FromQuery] long? material_id = null,
                [FromQuery] string? report_submitted = null,
                [FromQuery] string? status = null,
                [FromQuery] int? submission_year = null,
                [FromQuery] int? submission_month = null) => 
                    s.GetAllReceptions(page, per_page, user_id, submitted_by, type_id, material_id, report_submitted, status, submission_year, submission_month));

            apiGroup.MapGet("/receptions/{id}", (long id, IReceptionsService s) => s.GetReception(id));
            apiGroup.MapGet("/receptions/{id}/applicable_forms", (long id, IReceptionsService s) => s.GetApplicableForms(id));
            apiGroup.MapPost("/receptions", ([FromBody] CreateReceptionDto dto, IReceptionsService s) => s.CreateReception(dto));
            apiGroup.MapPut("/receptions/{id}", (long id, [FromBody] UpdateReceptionDto dto, IReceptionsService s) => s.UpdateReception(id, dto));
            apiGroup.MapGet("/receptions/{id}/tests", (long id, IReceptionsService s) => s.GetReceptionTests(id));
            apiGroup.MapPut("/receptions/{id}/tests", (long id, [FromBody] UpdateReceptionTestsDto dto, IReceptionsService s) => s.UpdateReceptionTests(id, dto));
            apiGroup.MapPut("/receptions/{id}/submit", (long id, [FromBody] SubmitReceptionDto dto, IReceptionsService s) => s.SubmitReception(id, dto));
            apiGroup.MapPut("/receptions/{id}/cancel_submission", (long id, IReceptionsService s) => s.CancelSubmission(id));
            apiGroup.MapPut("/receptions/{id}/receive", (long id, [FromBody] ReceiveReceptionDto dto, IReceptionsService s) => s.ReceiveReception(id, dto));
            apiGroup.MapPut("/receptions/{id}/reject", (long id, [FromBody] RejectReceptionDto dto, IReceptionsService s) => s.RejectReception(id, dto));
            apiGroup.MapGet("/receptions/{id}/reports", (long id, IReceptionsService s) => s.GetReceptionReports(id));
            apiGroup.MapPost("/receptions/{id}/create_report", (long id, [FromBody] CreateReportDto dto, IReceptionsService s) => s.CreateReport(id, dto));
            apiGroup.MapGet("/receptions/{id}/check_report_conflict", (long id, IReceptionsService s) => s.CheckReportConflict(id).ContinueWith(t => new { conflict = t.Result }));
            apiGroup.MapGet("/receptions/{id}/measurement_tests", (long id, IReceptionsService s) => s.GetReceptionMeasurementTests(id));
            apiGroup.MapGet("/receptions/{id}/measurement_params", (long id, IReceptionsService s) => s.GetReceptionMeasurementParams(id));
            apiGroup.MapGet("/receptions/{id}/preview", (long id, IReceptionsService s) => s.GetPreviewReport(id));
            apiGroup.MapPost("/receptions/{id}/submit_express_certificate", (long id, [FromBody] ExpressCertificateDto dto, IReceptionsService s) => s.SubmitExpressCertificate(id, dto));

            // Reception Types
            apiGroup.MapGet("/reception_types", (IReceptionTypesService s) => s.GetAllReceptionTypes());

            // Reports
            apiGroup.MapGet("/reports", (
                IReportsService s,
                [FromQuery] int page,
                [FromQuery] int pageSize,
                [FromQuery] long userId,
                [FromQuery] long? receptionTypeId,
                [FromQuery] long? materialId,
                [FromQuery] int? submissionYear,
                [FromQuery] int? submissionMonth) =>
                    s.GetAllReports(page, pageSize, userId, receptionTypeId, materialId, submissionYear, submissionMonth));

            apiGroup.MapGet("/reports/export-excel", async (
                IReportsService s,
                [FromQuery] long? receptionTypeId,
                [FromQuery] long? materialId,
                [FromQuery] int? submissionYear,
                [FromQuery] int? submissionMonth,
                [FromQuery] int? loadedPages,
                [FromServices] IHttpClientFactory clientFactory) =>
            {
                try
                {
                    var excelBytes = await s.ExportReportsExcel(receptionTypeId, materialId, submissionYear, submissionMonth, loadedPages, 15, clientFactory);
                    if (excelBytes == null) return Results.NotFound();
                    return Results.File(excelBytes, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "testing_reports.xlsx");
                }
                catch (Exception ex)
                {
                    return Results.BadRequest(new { msg = ex.Message });
                }
            });
            apiGroup.MapGet("/reports/{id}", (long id, IReportsService s) => s.GetReport(id));
            apiGroup.MapGet("/reports/{id}/check_conflict", (long id, IReportsService s) => s.CheckReportConflict(id).ContinueWith(t => new { conflict = t.Result }));
            apiGroup.MapGet("/reports/{id}/pdf", async (long id, IReportsService s, [FromServices] IHttpClientFactory clientFactory) =>
            {
                var report = await s.GetReport(id);
                if (report == null) return Results.NotFound();

                var client = clientFactory.CreateClient();
                var baseUrl = Environment.GetEnvironmentVariable("PYTHON_REPORTING_URL") ?? Environment.GetEnvironmentVariable("REPORTING_SERVICE_URL") ?? "http://reporting_pdf:8000";
                baseUrl = baseUrl.Replace("/generate-report", "").TrimEnd('/');
                var pythonServiceUrl = $"{baseUrl}/testing-report-pdf";

                var payload = new { report };
                var response = await client.PostAsJsonAsync(pythonServiceUrl, payload);
                if (!response.IsSuccessStatusCode)
                {
                    var errContent = await response.Content.ReadAsStringAsync();
                    return Results.BadRequest(new { msg = $"Failed to generate PDF from reporting service: {errContent}" });
                }

                var pdfBytes = await response.Content.ReadAsByteArrayAsync();
                return Results.File(pdfBytes, "application/pdf", $"testing_report_{id}.pdf");
            });
            apiGroup.MapPut("/reports/{id}/cancel", async (long id, [FromBody] CancelReportDto dto, IReportsService s) =>
            {
                try
                {
                    await s.CancelReport(id, dto);
                    return Results.Ok();
                }
                catch (Exception ex)
                {
                    return Results.BadRequest(new { msg = ex.Message });
                }
            });

            // Specs
            apiGroup.MapGet("/specs", (ISpecsService s, long? userId, bool isQCPersonnel) => s.GetAllSpecs(userId, isQCPersonnel));
            apiGroup.MapGet("/specs/{id}", (long id, ISpecsService s) => s.GetSpec(id));
            apiGroup.MapPost("/specs", ([FromBody] CreateSpecDto dto, ISpecsService s) => s.CreateSpec(dto));
            apiGroup.MapPut("/specs/{id}", (long id, [FromBody] UpdateSpecDto dto, ISpecsService s) => s.UpdateSpec(id, dto));
            apiGroup.MapPost("/specs/{id}/tests", (long id, [FromBody] CreateSpecTestDto dto, ISpecsService s) => s.AddSpecTest(id, dto));
            apiGroup.MapPut("/specs/{id}/tests/{testId}", (long id, long testId, [FromBody] UpdateSpecTestDto dto, ISpecsService s) => s.UpdateSpecTest(id, testId, dto));
            apiGroup.MapDelete("/specs/{id}/tests/{testId}", (long id, long testId, ISpecsService s) => s.DeleteSpecTest(id, testId));
            apiGroup.MapDelete("/specs/{id}", (long id, ISpecsService s) => s.DeleteSpec(id));
            apiGroup.MapPut("/specs/{id}/submit", async (long id, [FromBody] SpecActionDto dto, ISpecsService s) =>
            {
                try { return Results.Ok(await s.SubmitSpec(id, dto)); }
                catch (Exception ex) { return Results.BadRequest(new { msg = ex.Message }); }
            });
            apiGroup.MapPut("/specs/{id}/cancel", async (long id, [FromBody] SpecActionDto dto, ISpecsService s) =>
            {
                try { await s.CancelSpec(id, dto); return Results.Ok(); }
                catch (Exception ex) { return Results.BadRequest(new { msg = ex.Message }); }
            });
            apiGroup.MapPost("/specs/{id}/duplicate", async (long id, [FromBody] SpecActionDto dto, ISpecsService s) =>
            {
                try { return Results.Ok(await s.DuplicateSpec(id, dto)); }
                catch (Exception ex) { return Results.BadRequest(new { msg = ex.Message }); }
            });
            apiGroup.MapPost("/specs/validate-condition", async ([FromBody] string condition, ISpecsService s) =>
            {
                try
                {
                    await s.ValidateCondition(condition);
                    return Results.Ok();
                }
                catch (Exception ex)
                {
                    return Results.BadRequest(new { msg = ex.Message });
                }
            });
            apiGroup.MapGet("/specs/{id}/pdf", async (long id, ISpecsService s) =>
            {
                var pdfBytes = await s.GetSpecPdf(id);
                if (pdfBytes == null) return Results.NotFound();
                return Results.File(pdfBytes, "application/pdf", $"specification_{id}.pdf");
            });
            apiGroup.MapPost("/forms/validate-condition", async ([FromBody] string condition, IFormsService s) =>
            {
                try
                {
                    await s.ValidateCondition(condition);
                    return Results.Ok();
                }
                catch (Exception ex)
                {
                    return Results.BadRequest(new { msg = ex.Message });
                }
            });

            // Tests
            apiGroup.MapGet("/tests", (ITestsService s) => s.GetAllTests());
            apiGroup.MapGet("/tests/certified_ids", (ITestsService s) => s.GetCertifiedTestIds());
            apiGroup.MapGet("/tests/check_code_uniqueness", (ITestsService s, string code, long? id) => s.CheckCodeUniqueness(code, id).ContinueWith(t => new { is_unique = t.Result }));
            apiGroup.MapGet("/tests/{id}", (long id, ITestsService s) => s.GetTest(id));
            apiGroup.MapGet("/tests/{id}/enums", (long id, ITestsService s) => s.GetTestEnums(id));
            apiGroup.MapPost("/tests/{id}/enums", (long id, [FromBody] CreateTestEnumDto dto, ITestsService s) => s.AddTestEnum(id, dto));
            apiGroup.MapPut("/tests/{id}/enums/reorder", (long id, [FromBody] List<ReorderTestEnumDto> dtos, ITestsService s) => s.ReorderTestEnums(id, dtos));
            apiGroup.MapPut("/tests/{id}/enums/{enumId}", (long id, long enumId, [FromBody] UpdateTestEnumDto dto, ITestsService s) => s.UpdateTestEnum(id, enumId, dto));
            apiGroup.MapDelete("/tests/{id}/enums/{enumId}", (long id, long enumId, ITestsService s) => s.DeleteTestEnum(id, enumId));
            apiGroup.MapPost("/tests", ([FromBody] CreateTestDto dto, ITestsService s) => s.CreateTest(dto));
            apiGroup.MapPut("/tests/reorder", ([FromBody] List<ReorderTestDto> dtos, ITestsService s) => s.ReorderTests(dtos));
            apiGroup.MapPut("/tests/{id}", (long id, [FromBody] UpdateTestDto dto, ITestsService s) => s.UpdateTest(id, dto));
            apiGroup.MapPut("/tests/{id}/toggle_obsolete", (long id, [FromBody] ToggleObsoleteDto dto, ITestsService s) => s.ToggleObsolete(id, dto));

            // Units
            apiGroup.MapGet("/units", (IUnitsService s) => s.GetAllUnits());
            apiGroup.MapGet("/units/{id}", (long id, IUnitsService s) => s.GetUnit(id));
            apiGroup.MapPost("/units", async ([FromBody] CreateUnitDto dto, IUnitsService s) =>
            {
                try { return Results.Ok(await s.CreateUnit(dto)); }
                catch (ArgumentException ex) { return Results.BadRequest(new { msg = ex.Message }); }
            });
            apiGroup.MapPut("/units/{id}", async (long id, [FromBody] UpdateUnitDto dto, IUnitsService s) =>
            {
                try { await s.UpdateUnit(id, dto); return Results.Ok(); }
                catch (ArgumentException ex) { return Results.BadRequest(new { msg = ex.Message }); }
            });

            // Users
            apiGroup.MapGet("/users", (IUsersService s) => s.GetAllUsers());
            apiGroup.MapGet("/users/{id}", (long id, IUsersService s) => s.GetUser(id));
            apiGroup.MapPost("/users", async ([FromBody] CreateUserDto dto, IUsersService s) =>
            {
                try { return Results.Ok(await s.CreateUser(dto)); }
                catch (ArgumentException ex) { return Results.BadRequest(new { msg = ex.Message }); }
            });
            apiGroup.MapPut("/users/{id}", async (long id, [FromBody] UpdateUserDto dto, IUsersService s) =>
            {
                try { await s.UpdateUser(id, dto); return Results.Ok(); }
                catch (ArgumentException ex) { return Results.BadRequest(new { msg = ex.Message }); }
            });
            apiGroup.MapPut("/users/{id}/toggle_obsolete", (long id, [FromBody] ToggleObsoleteDto dto, IUsersService s) => s.ToggleObsolete(id, dto));
            apiGroup.MapPut("/users/{id}/reset_password", (long id, [FromBody] ResetPasswordDto dto, IUsersService s) => s.ResetPassword(id, dto));

            // Value Types
            apiGroup.MapGet("/value_types", (IValueTypesService s) => s.GetAllValueTypes());

            app.Run();
        }
    }
}