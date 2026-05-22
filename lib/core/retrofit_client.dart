import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'retrofit_client.g.dart';

@RestApi()
abstract class RetrofitClient {
  factory RetrofitClient(
    Dio dio, {
    String? baseUrl,
  }) = _RetrofitClient;

  // =========================================================
  // GET
  // =========================================================

  @GET('{path}')
  Future<HttpResponse<dynamic>> getRequest(
    @Path('path') String path, {
    @Queries() Map<String, dynamic>? queries,
    @CancelRequest() CancelToken? cancelToken,
    @Header('Authorization') String? authorization,
  });

  // =========================================================
  // POST
  // =========================================================

  @POST('{path}')
  Future<HttpResponse<dynamic>> postRequest(
    @Path('path') String path, {
    @Body() dynamic data,
    @CancelRequest() CancelToken? cancelToken,
    @Header('Authorization') String? authorization,
  });

  // =========================================================
  // PUT
  // =========================================================

  @PUT('{path}')
  Future<HttpResponse<dynamic>> putRequest(
    @Path('path') String path, {
    @Body() dynamic data,
    @CancelRequest() CancelToken? cancelToken,
    @Header('Authorization') String? authorization,
  });

  // =========================================================
  // PATCH
  // =========================================================

  @PATCH('{path}')
  Future<HttpResponse<dynamic>> patchRequest(
    @Path('path') String path, {
    @Body() dynamic data,
    @CancelRequest() CancelToken? cancelToken,
    @Header('Authorization') String? authorization,
  });

  // =========================================================
  // DELETE
  // =========================================================

  @DELETE('{path}')
  Future<HttpResponse<dynamic>> deleteRequest(
    @Path('path') String path, {
    @CancelRequest() CancelToken? cancelToken,
    @Header('Authorization') String? authorization,
  });
}
