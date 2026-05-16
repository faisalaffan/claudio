/// claudio — Multi-provider AI SDK for Dart/Flutter.
library;

// Client
export 'src/client/claudio_client.dart';
export 'src/client/provider.dart';
export 'src/client/retry_policy.dart';

// Messages
export 'src/messages/create_request.dart';
export 'src/messages/message_param.dart';
export 'src/messages/message_response.dart';
export 'src/messages/content_block.dart';
export 'src/messages/helpers.dart';

// Tools
export 'src/tools/tool.dart';
export 'src/tools/tool_choice.dart';
export 'src/tools/schema_builder.dart';
export 'src/tools/schema_property.dart';

// Streaming
export 'src/streaming/stream_events.dart';
export 'src/streaming/sse_decoder.dart';

// Errors
export 'src/errors/claudio_exception.dart';
export 'src/errors/authentication_exception.dart';
export 'src/errors/rate_limit_exception.dart';
export 'src/errors/invalid_request_exception.dart';
export 'src/errors/api_exception.dart';
export 'src/errors/network_exception.dart';
export 'src/errors/stream_exception.dart';
export 'src/errors/unsupported_feature_exception.dart';
export 'src/errors/client_closed_exception.dart';
