import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cryptoutils/cryptoutils.dart';


const String CLOUDAPI_USER_AGENT = "ALIYUN-DART-DEMO";

/// 换行符
const String CLOUDAPI_LF = '\n';

/// 参与签名的系统Header前缀,只有指定前缀的Header才会参与到签名中
const String CLOUDAPI_CA_HEADER_PREFIX = "X-Ca-";

const String CLOUDAPI_CA_VERSION = "1";


/// 签名Header
const String CLOUDAPI_X_CA_SIGNATURE = "X-Ca-Signature";

/// 所有参与签名的Header
const String CLOUDAPI_X_CA_SIGNATURE_HEADERS =  "X-Ca-Signature-Headers";

/// 请求时间戳
const String CLOUDAPI_X_CA_TIMESTAMP = "X-Ca-Timestamp";

/// 请求放重放Nonce,15分钟内保持唯一,建议使用UUID
const String CLOUDAPI_X_CA_NONCE = "X-Ca-Nonce";

/// APP KEY
const String CLOUDAPI_X_CA_KEY = "X-Ca-Key";

//签名算法版本号
const String CLOUDAPI_X_CA_VERSION = "X-Ca-Version";





/// HTTP
const String CLOUDAPI_HTTP = "http://";

/// HTTPS
const String CLOUDAPI_HTTPS = "https://";

//
/// HTTP方法常量
//

/// GET
const String CLOUDAPI_GET = "GET";

/// POST
const String CLOUDAPI_POST = "POST";

/// PUT
const String CLOUDAPI_PUT = "PUT";

/// PATCH
const String CLOUDAPI_PATCH = "PATCH";

/// DELETE
const String CLOUDAPI_DELETE = "DELETE";

//
/// HTTP头常量
//

/// 请求Header Accept
const String CLOUDAPI_HTTP_HEADER_ACCEPT = "Accept";

/// 请求Body内容MD5 Header
const String CLOUDAPI_HTTP_HEADER_CONTENT_MD5 = "Content-MD5";

/// 请求Header Content-Type
const String CLOUDAPI_HTTP_HEADER_CONTENT_TYPE = "Content-Type";

/// 请求Header UserAgent
const String CLOUDAPI_HTTP_HEADER_USER_AGENT = "User-Agent";

/// 请求Header Date
const String CLOUDAPI_HTTP_HEADER_DATE = "Date";

/// 请求Header Host
const String CLOUDAPI_HTTP_HEADER_HOST = "Host";

//
/// 常用HTTP Content-Type常量
//

/// 表单类型Content-Type
const String CLOUDAPI_CONTENT_TYPE_FORM = "application/x-www-form-urlencoded; charset=UTF-8";

/// 流类型Content-Type
const String CLOUDAPI_CONTENT_TYPE_STREAM = "application/octet-stream; charset=UTF-8";

/// JSON类型Content-Type
const String CLOUDAPI_CONTENT_TYPE_JSON = "application/json; charset=UTF-8";

/// XML类型Content-Type
const String CLOUDAPI_CONTENT_TYPE_XML = "application/xml; charset=UTF-8";

/// 文本类型Content-Type
const String CLOUDAPI_CONTENT_TYPE_TEXT = "application/text; charset=UTF-8";




//
///  对字符串进行hmacSha256加密，然后再进行BASE64编码
//
String hmacSha256(String key, String data) {
  var keyBytes = utf8.encode(key);
  var dataBytes = utf8.encode(data);
  var hmacSha256 = new Hmac(sha256, keyBytes);
  var digest = hmacSha256.convert(dataBytes);
  var hash = CryptoUtils.bytesToBase64(digest.bytes);
  print('hash=====$hash');
  return hash;
}

//
/// 将path、queryParam、formParam合成一个字符串
//
String buildResource(String path,Map queryParam,Map formParam) {
  Map parameters = new Map();
  if(queryParam != null) {
    parameters.addAll(queryParam);
  }
  if(formParam != null) {
    parameters.addAll(formParam);
  }
  List keys = parameters.keys.toList();

  keys.sort();

  var result = path;

  if (parameters.length > 0) {
    result = result + "?";
    var isFirst = true;
    for(int i = 0; i < keys.length; i++) {
      if(!isFirst) {
        result = result + "&";
      } else {
        isFirst = false;
      }
      var key = keys[i];
      result = result + key;

      String value = parameters[key];
      if(null != value && value.length > 0)
        result = result + "=" + value;
    }
  }
  return result;
}

///
///  将headers合成一个字符串
///  需要注意的是，HTTP头需要按照字母排序加入签名字符串
///  同时所有加入签名的头的列表，需要用逗号分隔形成一个字符串，加入一个新HTTP头@"X-Ca-Signature-Headers"
///
String buildHeaders(Map headers) {
  var signHeaders = '';
  var result = '';
  List signHeaderNames = new List();
  if(null != headers) {
    var isFirst = true;
    List keys = headers.keys.toList();
    for(int i = 0; i < keys.length; i++) {
      if (keys[i].toString().length >= 5) {
        var temp = keys[i].toString().substring(0,5);
        if(temp == "X-Ca-"){
          if(!isFirst) {
            signHeaders = signHeaders + ',';
          } else {
            isFirst = false;
          }

          signHeaders = signHeaders + keys[i];
          signHeaderNames.add(keys[i]);
        }
      }
    }
    signHeaders += ',X-Ca-Signature-Headers';
    headers['X-Ca-Signature-Headers'] = signHeaders;
    signHeaderNames.add('X-Ca-Signature-Headers');
  }

  signHeaderNames.sort();
  for(int i = 0; i < signHeaderNames.length; i++) {
    result = result + signHeaderNames[i] + ':' + headers[signHeaderNames[i]].toString() + '\n';
  }

  return result;
}

//
/// 将Request中的httpMethod、headers、path、queryParam、formParam合成一个字符串
//
String buildStringToSign(Map headers,String path,Map queryParam,Map formParam,String method){

  String result = method + CLOUDAPI_LF;

  //如果有@"Accept"头，这个头需要参与签名
  if(null != headers[CLOUDAPI_HTTP_HEADER_ACCEPT]) {
    result += headers[CLOUDAPI_HTTP_HEADER_ACCEPT];
  }
  result += CLOUDAPI_LF;

  //如果有@"Content-MD5"头，这个头需要参与签名
  if(null != headers[CLOUDAPI_HTTP_HEADER_CONTENT_MD5]) {
    result += headers[CLOUDAPI_HTTP_HEADER_CONTENT_MD5];
  }
  result += CLOUDAPI_LF;

  //如果有@"Content-Type"头，这个头需要参与签名
  if(null != headers[CLOUDAPI_HTTP_HEADER_CONTENT_TYPE]) {
    result += headers[CLOUDAPI_HTTP_HEADER_CONTENT_TYPE];
  }
  result += CLOUDAPI_LF;

  //如果有@"Date"头，这个头需要参与签名
  if(null != headers[CLOUDAPI_HTTP_HEADER_DATE]) {
    result += headers[CLOUDAPI_HTTP_HEADER_DATE];
  }
  result += CLOUDAPI_LF;

  //将headers合成一个字符串
  result += buildHeaders(headers);

  //将path、queryParam、formParam合成一个字符串
  result += buildResource(path, queryParam, formParam);

  return result;
}

///
/// 签名方法
/// 本方法将Request中的httpMethod、headers、path、queryParam、formParam合成一个字符串用hmacSha256算法双向加密进行签名
///
String sign(String httpMethod, Map headers, String path, Map queryParam, Map formParam, String appSerect) {
    String data = buildStringToSign(headers, path, queryParam, formParam, httpMethod);
    print(data);
    return hmacSha256(appSerect, data);
}





