import 'package:CloudApiSignUtil.dart';
import 'dart:core';
import 'package:dio/dio.dart';

String baseUrl = 'http://www.baidu.com';


String kNetworkGatewayAPPKey = '123';
String kNetworkGatewayAPPSECRET = 'abc';

class lzReqeust {

  Map requestHeader(String requestMethod, String path, Map requestArgument) {

    Map summaryHeaderParams = {};

    /// 设置请求头中的时间
    String current = new DateTime.now().toString();

    summaryHeaderParams[CLOUDAPI_HTTP_HEADER_DATE] = current;

    /// 设置请求头中的时间戳，以timeIntervalSince1970的形式
    String timeStamp = new DateTime.now().millisecondsSinceEpoch.toString();
    summaryHeaderParams[CLOUDAPI_X_CA_TIMESTAMP] = timeStamp;

    /// 请求放重放Nonce
    summaryHeaderParams[CLOUDAPI_X_CA_NONCE] = '';

    /// 设置请求头中的UserAgent
    summaryHeaderParams[CLOUDAPI_HTTP_HEADER_USER_AGENT] = CLOUDAPI_USER_AGENT;

    /// 设置请求头中的主机地址
    var uri = Uri.parse(baseUrl);
    summaryHeaderParams[CLOUDAPI_HTTP_HEADER_HOST] = uri.host;

    var app_key = kNetworkGatewayAPPKey;
    var app_secret = kNetworkGatewayAPPSECRET;

    summaryHeaderParams[CLOUDAPI_X_CA_KEY] = app_key;

    summaryHeaderParams[CLOUDAPI_X_CA_VERSION] = CLOUDAPI_CA_VERSION;

    summaryHeaderParams[CLOUDAPI_HTTP_HEADER_CONTENT_TYPE] = CLOUDAPI_CONTENT_TYPE_FORM;

    summaryHeaderParams[CLOUDAPI_HTTP_HEADER_ACCEPT] = CLOUDAPI_CONTENT_TYPE_JSON;

    var stage = "RELEASE";

    summaryHeaderParams['X-Ca-Stage'] = stage;

    var method = '';
    if(requestMethod == 'GET') {
      method = CLOUDAPI_GET;
    } else if (requestMethod == 'POST') {
      method = CLOUDAPI_POST;
    } else {
      method = '';
    }

    summaryHeaderParams[CLOUDAPI_X_CA_SIGNATURE] = sign(method, summaryHeaderParams, path, requestArgument, {}, app_secret);

    return  summaryHeaderParams;
  }

  Future<Response> baseRequest(String requestMethod, String path, Map data) async{
    Dio dio = new Dio();
    dio.options.baseUrl = baseUrl;
    dio.options.connectTimeout = 5000;
    dio.options.receiveTimeout = 3000;
    Map map = requestHeader(requestMethod, path, data);
    Map<String, dynamic> header = new Map<String, dynamic>.from(map);
    print('\n\nheader=======$header \n\n');
    dio.options.headers = header;
    Response response = new Response();
    Map<String, dynamic> dataMap = new Map<String, dynamic>.from(data);
    response = await dio.request(
        path,
        queryParameters: dataMap,
        options: Options(method: requestMethod)
    );

    return response;
  }
}

