// ignore_for_file: unused_local_variable
// ignore_for_file: unused_import

/// Contoh penggunaan lengkap Anthropic SDK Dart.
///
/// File ini mendemonstrasikan berbagai fitur SDK:
/// 1. Inisialisasi client (explicit API key & fromEnvironment)
/// 2. Pembuatan message sederhana
/// 3. Penggunaan single tool dengan SchemaBuilder
/// 4. Penggunaan multi-tools dengan nested object type
/// 5. Streaming response
///
/// Catatan: Contoh ini tidak akan berjalan tanpa API key yang valid.
/// Setiap contoh dibungkus dalam fungsi terpisah dengan try-catch.
library;

import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart';

// ---------------------------------------------------------------------------
// 1. Inisialisasi Client
// ---------------------------------------------------------------------------

/// Mendemonstrasikan cara menginisialisasi [AnthropicClient].
///
/// SDK menyediakan dua cara untuk membuat client:
/// - Constructor dengan API key eksplisit
/// - Factory `fromEnvironment()` yang membaca dari environment variable
void clientInitialization() {
  print('=== 1. Client Initialization ===\n');

  // --- Cara 1: API key eksplisit ---
  final client = AnthropicClient(apiKey: 'sk-ant-your-api-key-here');
  print('Client dibuat dengan API key eksplisit.');

  // --- Cara 2: Dari environment variable ANTHROPIC_API_KEY ---
  // Pastikan environment variable sudah di-set sebelum memanggil ini.
  // export ANTHROPIC_API_KEY=sk-ant-your-api-key-here
  try {
    final envClient = AnthropicClient.fromEnvironment();
    print('Client dibuat dari environment variable.');
    envClient.close();
  } on AuthenticationException catch (e) {
    print('Environment variable tidak ditemukan: ${e.message}');
  }

  // --- Konfigurasi opsional ---
  final customClient = AnthropicClient(
    apiKey: 'sk-ant-your-api-key-here',
    baseUrl: 'https://api.anthropic.com', // default
    timeout: const Duration(seconds: 60),
    retryPolicy: const RetryPolicy(
      maxRetries: 3,
      initialDelay: Duration(seconds: 2),
    ),
  );
  print('Client dibuat dengan konfigurasi kustom.');

  // Selalu close client setelah selesai digunakan.
  client.close();
  customClient.close();

  // Menggunakan client setelah close akan melempar ClientClosedException.
  try {
    client.messages;
  } on ClientClosedException catch (e) {
    print('Client sudah di-close: ${e.message}');
  }

  print('');
}

// ---------------------------------------------------------------------------
// 2. Simple Message
// ---------------------------------------------------------------------------

/// Mendemonstrasikan pembuatan message sederhana ke Claude.
///
/// Ini adalah penggunaan paling dasar: kirim satu pesan user,
/// terima respons dari assistant.
Future<void> simpleMessage() async {
  print('=== 2. Simple Message ===\n');

  final client = AnthropicClient(apiKey: 'sk-ant-your-api-key-here');

  try {
    // Buat request dengan parameter wajib: model, maxTokens, messages.
    final message = await client.messages.create(
      CreateMessageRequest(
        model: 'claude-sonnet-4-20250514',
        maxTokens: 1024,
        messages: [
          MessageParam(role: 'user', content: 'Apa itu Dart programming language?'),
        ],
      ),
    );

    // Akses respons menggunakan convenience getter `text`.
    print('Response: ${message.text}');
    print('Model: ${message.model}');
    print('Stop reason: ${message.stopReason}');
    print('Input tokens: ${message.usage.inputTokens}');
    print('Output tokens: ${message.usage.outputTokens}');

    // --- Multi-turn conversation ---
    final followUp = await client.messages.create(
      CreateMessageRequest(
        model: 'claude-sonnet-4-20250514',
        maxTokens: 1024,
        systemPrompt: 'Kamu adalah asisten yang membantu dalam Bahasa Indonesia.',
        messages: [
          MessageParam(role: 'user', content: 'Apa itu Dart?'),
          MessageParam(role: 'assistant', content: 'Dart adalah bahasa pemrograman oleh Google.'),
          MessageParam(role: 'user', content: 'Apa kelebihannya?'),
        ],
      ),
    );

    print('Follow-up: ${followUp.text}');
  } on AnthropicException catch (e) {
    print('Error: ${e.message} (status: ${e.statusCode})');
  } finally {
    client.close();
  }

  print('');
}

// ---------------------------------------------------------------------------
// 3. Single Tool
// ---------------------------------------------------------------------------

/// Mendemonstrasikan penggunaan single tool dengan SchemaBuilder.
///
/// Alur tool use:
/// 1. Definisikan tool dengan nama, deskripsi, dan input schema
/// 2. Kirim request dengan tool definition
/// 3. Terima response dengan ToolUseBlock (stop_reason: tool_use)
/// 4. Eksekusi tool secara lokal
/// 5. Kirim tool result kembali ke model
/// 6. Terima respons final dari model
Future<void> singleToolUsage() async {
  print('=== 3. Single Tool Usage ===\n');

  final client = AnthropicClient(apiKey: 'sk-ant-your-api-key-here');

  try {
    // --- Langkah 1: Definisikan tool menggunakan SchemaBuilder ---
    final getWeatherTool = Tool(
      name: 'get_weather',
      description: 'Mendapatkan cuaca terkini untuk suatu lokasi.',
      inputSchema: SchemaBuilder().object(
        properties: {
          'location': SchemaProperty.string(
            description: 'Nama kota, contoh: "Jakarta"',
          ),
          'unit': SchemaProperty.string(
            description: 'Satuan suhu',
            enumValues: ['celsius', 'fahrenheit'],
          ),
        },
        required: ['location'],
      ).build(),
    );

    // --- Langkah 2: Kirim request dengan tool ---
    final response = await client.messages.create(
      CreateMessageRequest(
        model: 'claude-sonnet-4-20250514',
        maxTokens: 1024,
        messages: [
          MessageParam(
            role: 'user',
            content: 'Bagaimana cuaca di Jakarta hari ini?',
          ),
        ],
        tools: [getWeatherTool],
      ),
    );

    // --- Langkah 3: Cek apakah model ingin menggunakan tool ---
    if (response.hasToolUse) {
      print('Model ingin menggunakan tool!');
      print('Stop reason: ${response.stopReason}'); // tool_use

      // Ekstrak semua ToolUseBlock dari response.
      final toolUseBlocks = response.toolUseBlocks;
      for (final toolUse in toolUseBlocks) {
        print('Tool: ${toolUse.name}');
        print('Input: ${toolUse.input}');

        // --- Langkah 4: Eksekusi tool secara lokal ---
        // Di aplikasi nyata, ini akan memanggil API cuaca.
        const weatherResult = '{"temperature": 32, "condition": "Cerah"}';

        // --- Langkah 5: Kirim tool result kembali ---
        final toolResult = createToolResult(
          toolUseId: toolUse.id,
          text: weatherResult,
        );

        final finalResponse = await client.messages.create(
          CreateMessageRequest(
            model: 'claude-sonnet-4-20250514',
            maxTokens: 1024,
            messages: [
              MessageParam(
                role: 'user',
                content: 'Bagaimana cuaca di Jakarta hari ini?',
              ),
              // Sertakan response assistant sebelumnya.
              response.toAssistantParam(),
              // Kirim tool result sebagai user message.
              createToolResultMessage([toolResult]),
            ],
            tools: [getWeatherTool],
          ),
        );

        // --- Langkah 6: Respons final dari model ---
        print('Final response: ${finalResponse.text}');
      }
    } else {
      // Model menjawab langsung tanpa menggunakan tool.
      print('Response: ${response.text}');
    }
  } on AnthropicException catch (e) {
    print('Error: ${e.message} (status: ${e.statusCode})');
  } finally {
    client.close();
  }

  print('');
}

// ---------------------------------------------------------------------------
// 4. Multi-Tools dengan Nested Object Type
// ---------------------------------------------------------------------------

/// Mendemonstrasikan penggunaan multi-tools dengan nested object schema.
///
/// Contoh ini mendefinisikan dua tools:
/// - `create_order`: Tool dengan nested object schema (customer → address)
/// - `check_inventory`: Tool sederhana untuk cek stok
///
/// Ini menunjukkan kemampuan SDK untuk mendukung schema kompleks
/// termasuk nested objects dan array of objects.
Future<void> multiToolsWithNestedObjects() async {
  print('=== 4. Multi-Tools with Nested Objects ===\n');

  final client = AnthropicClient(apiKey: 'sk-ant-your-api-key-here');

  try {
    // --- Tool 1: create_order (nested object schema) ---
    final createOrderTool = Tool(
      name: 'create_order',
      description: 'Membuat pesanan baru dengan data customer dan item.',
      inputSchema: SchemaBuilder().object(
        properties: {
          // Nested object: customer → address
          'customer': SchemaProperty.object(
            description: 'Data pelanggan',
            properties: {
              'name': SchemaProperty.string(description: 'Nama pelanggan'),
              'email': SchemaProperty.string(description: 'Email pelanggan'),
              'address': SchemaProperty.object(
                description: 'Alamat pengiriman',
                properties: {
                  'street': SchemaProperty.string(description: 'Nama jalan'),
                  'city': SchemaProperty.string(description: 'Kota'),
                  'zip': SchemaProperty.string(description: 'Kode pos'),
                },
                required: ['street', 'city'],
              ),
            },
            required: ['name', 'email'],
          ),
          // Array of objects: items
          'items': SchemaProperty.array(
            description: 'Daftar item yang dipesan',
            items: SchemaProperty.object(
              properties: {
                'product_id': SchemaProperty.string(
                  description: 'ID produk',
                ),
                'quantity': SchemaProperty.integer(
                  description: 'Jumlah item',
                ),
                'options': SchemaProperty.array(
                  description: 'Opsi tambahan',
                  items: SchemaProperty.string(),
                ),
              },
              required: ['product_id', 'quantity'],
            ),
          ),
          // Enum string
          'payment_method': SchemaProperty.string(
            description: 'Metode pembayaran',
            enumValues: ['credit_card', 'bank_transfer', 'e_wallet'],
          ),
          'is_gift': SchemaProperty.boolean(
            description: 'Apakah pesanan ini hadiah',
          ),
        },
        required: ['customer', 'items'],
      ).build(),
    );

    // --- Tool 2: check_inventory (schema sederhana) ---
    final checkInventoryTool = Tool(
      name: 'check_inventory',
      description: 'Mengecek ketersediaan stok produk.',
      inputSchema: SchemaBuilder().object(
        properties: {
          'product_id': SchemaProperty.string(description: 'ID produk'),
          'warehouse': SchemaProperty.string(
            description: 'Lokasi gudang',
            enumValues: ['jakarta', 'surabaya', 'bandung'],
          ),
        },
        required: ['product_id'],
      ).build(),
    );

    // --- Kirim request dengan multiple tools ---
    final response = await client.messages.create(
      CreateMessageRequest(
        model: 'claude-sonnet-4-20250514',
        maxTokens: 1024,
        messages: [
          MessageParam(
            role: 'user',
            content: 'Tolong buatkan pesanan untuk Budi (budi@email.com) '
                'di Jl. Sudirman 123, Jakarta. '
                'Dia mau beli 2 unit produk SKU-001 dan 1 unit SKU-002. '
                'Bayar pakai e-wallet.',
          ),
        ],
        tools: [createOrderTool, checkInventoryTool],
        // Opsional: kontrol bagaimana model memilih tool.
        toolChoice: const ToolChoice.auto(),
      ),
    );

    // --- Handle response ---
    if (response.hasToolUse) {
      final toolBlocks = response.toolUseBlocks;
      print('Model menggunakan ${toolBlocks.length} tool(s):');

      final toolResults = <ToolResultBlock>[];

      for (final toolUse in toolBlocks) {
        print('  - ${toolUse.name}: ${toolUse.input}');

        // Simulasi eksekusi tool.
        final result = switch (toolUse.name) {
          'create_order' => '{"order_id": "ORD-12345", "status": "created"}',
          'check_inventory' => '{"available": true, "stock": 50}',
          _ => '{"error": "Unknown tool"}',
        };

        toolResults.add(createToolResult(
          toolUseId: toolUse.id,
          text: result,
        ));
      }

      // Kirim semua tool results sekaligus (parallel tool use).
      final finalResponse = await client.messages.create(
        CreateMessageRequest(
          model: 'claude-sonnet-4-20250514',
          maxTokens: 1024,
          messages: [
            MessageParam(
              role: 'user',
              content: 'Tolong buatkan pesanan untuk Budi.',
            ),
            response.toAssistantParam(),
            createToolResultMessage(toolResults),
          ],
          tools: [createOrderTool, checkInventoryTool],
        ),
      );

      print('Final: ${finalResponse.text}');
    } else {
      print('Response: ${response.text}');
    }

    // --- Contoh tool_choice variants ---
    // Force model untuk menggunakan tool tertentu:
    final forcedRequest = CreateMessageRequest(
      model: 'claude-sonnet-4-20250514',
      maxTokens: 1024,
      messages: [
        MessageParam(role: 'user', content: 'Cek stok SKU-001.'),
      ],
      tools: [checkInventoryTool],
      toolChoice: const ToolChoice.tool(name: 'check_inventory'),
    );

    // Disable parallel tool use:
    final singleToolRequest = CreateMessageRequest(
      model: 'claude-sonnet-4-20250514',
      maxTokens: 1024,
      messages: [
        MessageParam(role: 'user', content: 'Proses pesanan ini.'),
      ],
      tools: [createOrderTool, checkInventoryTool],
      toolChoice: const ToolChoice.auto(disableParallelToolUse: true),
    );
  } on AnthropicException catch (e) {
    print('Error: ${e.message} (status: ${e.statusCode})');
  } finally {
    client.close();
  }

  print('');
}

// ---------------------------------------------------------------------------
// 5. Streaming Response
// ---------------------------------------------------------------------------

/// Mendemonstrasikan penggunaan streaming response.
///
/// Streaming memungkinkan menerima respons secara incremental
/// (token-by-token) menggunakan Server-Sent Events (SSE).
/// Berguna untuk menampilkan output secara real-time di UI.
Future<void> streamingResponse() async {
  print('=== 5. Streaming Response ===\n');

  final client = AnthropicClient(apiKey: 'sk-ant-your-api-key-here');

  try {
    // --- Streaming dasar ---
    final stream = client.messages.createStream(
      CreateMessageRequest(
        model: 'claude-sonnet-4-20250514',
        maxTokens: 1024,
        messages: [
          MessageParam(
            role: 'user',
            content: 'Ceritakan sejarah singkat Indonesia.',
          ),
        ],
      ),
    );

    // Listen ke stream events.
    await for (final event in stream) {
      switch (event) {
        case MessageStartEvent(:final message):
          // Event pertama: berisi metadata message (id, model).
          print('Stream dimulai - ID: ${message.id}');

        case ContentBlockStartEvent(:final index, :final contentBlock):
          // Content block baru dimulai.
          print('Content block #$index dimulai (${contentBlock.type})');

        case ContentBlockDeltaEvent(:final index, :final delta):
          // Incremental content update.
          switch (delta) {
            case TextDelta(:final text):
              // Tampilkan teks secara incremental (tanpa newline).
              print(text);
            case InputJsonDelta(:final partialJson):
              // Partial JSON untuk tool input (saat streaming tool use).
              print('Tool input chunk: $partialJson');
            case ThinkingDelta(:final thinking):
              // Thinking content (saat extended thinking aktif).
              print('Thinking: $thinking');
          }

        case ContentBlockStopEvent(:final index):
          // Content block selesai.
          print('\nContent block #$index selesai.');

        case MessageDeltaEvent(:final delta, :final usage):
          // Metadata akhir: stop reason dan usage.
          print('Stop reason: ${delta.stopReason}');
          print('Output tokens: ${usage.outputTokens}');

        case MessageStopEvent():
          // Stream selesai.
          print('Stream selesai.');
      }
    }
  } on StreamException catch (e) {
    print('Stream error: ${e.message}');
  } on AnthropicException catch (e) {
    print('Error: ${e.message} (status: ${e.statusCode})');
  } finally {
    client.close();
  }

  print('');
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

/// Entry point yang menjalankan semua contoh.
///
/// Setiap contoh dibungkus dalam try-catch sehingga kegagalan
/// pada satu contoh tidak menghentikan contoh lainnya.
Future<void> main() async {
  print('Anthropic SDK Dart — Contoh Penggunaan\n');
  print('${'=' * 50}\n');

  // 1. Client initialization (synchronous, bisa dijalankan langsung).
  try {
    clientInitialization();
  } catch (e) {
    print('Error pada client initialization: $e\n');
  }

  // 2. Simple message.
  try {
    await simpleMessage();
  } catch (e) {
    print('Error pada simple message: $e\n');
  }

  // 3. Single tool usage.
  try {
    await singleToolUsage();
  } catch (e) {
    print('Error pada single tool usage: $e\n');
  }

  // 4. Multi-tools with nested objects.
  try {
    await multiToolsWithNestedObjects();
  } catch (e) {
    print('Error pada multi-tools: $e\n');
  }

  // 5. Streaming response.
  try {
    await streamingResponse();
  } catch (e) {
    print('Error pada streaming: $e\n');
  }

  print('=' * 50);
  print('Semua contoh selesai.');
}
