import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/asymmetric/api.dart';
import 'app_constants.dart';

class ApiClient {
  static Future<String> makeSoapRequest(String url, String methodName, String encryptedData) async {
    String soapEnvelope = '''
<v:Envelope xmlns:v="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">
   <v:Header/><v:Body><tem:$methodName><tem:data>$encryptedData</tem:data></tem:$methodName></v:Body>
</v:Envelope>''';
    
    debugPrint(">>> SOAP REQUEST: $url | Method: $methodName");

    final response = await http.post(
      Uri.parse(url), 
      headers: {
        "Content-Type": "text/xml; charset=utf-8", 
        "SOAPAction": "http://tempuri.org/IBillingWcfsrv/$methodName"
      }, 
      body: utf8.encode(soapEnvelope)
    ).timeout(const Duration(seconds: 45));
    
    debugPrint(">>> SOAP RESPONSE RECEIVED: ${response.statusCode}");
    return response.body;
  }

  static String encryptRSA(String plainText) {
    try {
      final pemKey = "-----BEGIN PUBLIC KEY-----\n${AppConstants.publicKeyRaw}\n-----END PUBLIC KEY-----";
      final parser = encrypt.RSAKeyParser();
      final publicKey = parser.parse(pemKey) as RSAPublicKey;
      final encrypter = encrypt.Encrypter(encrypt.RSA(publicKey: publicKey, encoding: encrypt.RSAEncoding.PKCS1));
      
      final result = encrypter.encrypt(plainText).base64.replaceAll("\n", "").replaceAll("\r", "").trim();
      
      if (result.isNotEmpty) {
        debugPrint(">>> RSA Encryption Success");
      }
      return result;
    } catch (e) { 
      debugPrint(">>> RSA Encryption Failed: $e");
      return ""; 
    }
  }

  static String smartSearch(xml.XmlNode node, String tagName) {
    try {
      final elements = node.descendants.whereType<xml.XmlElement>()
          .where((e) => e.name.local.toLowerCase() == tagName.toLowerCase());
      if (elements.isNotEmpty) return elements.first.innerText.trim();
    } catch (_) {}
    return "---";
  }
}
