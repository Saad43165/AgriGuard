import 'package:agriguard_fyp/core/services/api_gateway.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('proxy mode sends traffic to the proxy and needs no local keys', () {
    dotenv.testLoad(fileInput: 'API_PROXY_URL=https://proxy.example/api/\n');
    expect(ApiGateway.useProxy, isTrue);
    expect(ApiGateway.groqUrl, 'https://proxy.example/api/groq');
    expect(ApiGateway.plantIdBaseUrl, 'https://proxy.example/api/plantid');
    expect(ApiGateway.weatherBaseUrl, 'https://proxy.example/api/weather');
    expect(ApiGateway.weatherQuery, isEmpty);
    expect(ApiGateway.groqAvailable, isTrue);
    expect(ApiGateway.plantIdAvailable, isTrue);
  });

  test('direct mode uses provider URLs and local keys', () {
    dotenv.testLoad(fileInput: 'GROQ_API_KEY=g\nWEATHER_API_KEY=w\n');
    expect(ApiGateway.useProxy, isFalse);
    expect(ApiGateway.groqUrl, 'https://api.groq.com/openai/v1/chat/completions');
    expect(ApiGateway.plantIdBaseUrl, 'https://api.plant.id/v3');
    expect(ApiGateway.weatherQuery, {'key': 'w'});
    expect(ApiGateway.groqAvailable, isTrue);
    expect(ApiGateway.plantIdAvailable, isFalse);
  });

  test('nothing configured means features are unavailable', () {
    dotenv.testLoad(fileInput: '');
    expect(ApiGateway.groqAvailable, isFalse);
    expect(ApiGateway.plantIdAvailable, isFalse);
  });
}
