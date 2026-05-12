import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
part 'retrofit_client.g.dart';

@RestApi()
abstract class RetrofitClient {
  factory RetrofitClient(Dio dio) = _RetrofitClient;

  // Generic methods that use your existing endpoints
  @GET('{path}')
  Future<HttpResponse<dynamic>> getRequest(
    @Path('path') String path,
    @Queries() Map<String, dynamic>? queries,
  );

  @POST('{path}')
  Future<HttpResponse<dynamic>> postRequest(
    @Path('path') String path,
    @Body() dynamic data,
  );

  @PUT('{path}')
  Future<HttpResponse<dynamic>> putRequest(
    @Path('path') String path,
    @Body() dynamic data,
  );

  @PATCH('{path}')
  Future<HttpResponse<dynamic>> patchRequest(
    @Path('path') String path,
    @Body() dynamic data,
  );

  @DELETE('{path}')
  Future<HttpResponse<dynamic>> deleteRequest(@Path('path') String path);
}
