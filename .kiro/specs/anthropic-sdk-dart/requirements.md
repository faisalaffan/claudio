# Requirements Document

## Introduction

Dokumen ini mendefinisikan requirements untuk **Anthropic SDK Dart** — sebuah package Dart/Flutter yang menyediakan akses type-safe ke Anthropic Messages API (Claude). SDK ini dibangun dari nol (fresh start) dengan fokus utama pada dukungan penuh **multi-tools** (penggunaan beberapa tools dalam satu request/conversation) dan **object type** pada tool parameter schemas, yang merupakan kekurangan dari package existing (`anthropic_sdk_dart` di pub.dev).

SDK ini harus mendukung seluruh platform Dart/Flutter (iOS, Android, macOS, Windows, Linux, Web, dan server-side Dart) dengan arsitektur yang bersih, testable, dan mengikuti best practices ekosistem Dart.

## Glossary

- **SDK**: Software Development Kit — package library yang menyediakan interface untuk berinteraksi dengan Anthropic API
- **Client**: Objek utama SDK yang mengelola koneksi HTTP, autentikasi, dan request ke Anthropic API
- **Messages_API**: Endpoint utama Anthropic (`/v1/messages`) untuk membuat pesan dan berinteraksi dengan model Claude
- **Tool**: Definisi fungsi/alat yang dapat dipanggil oleh model Claude selama percakapan, termasuk nama, deskripsi, dan input schema
- **Multi_Tools**: Kemampuan untuk mendefinisikan dan menggunakan lebih dari satu Tool dalam satu request, termasuk parallel tool use
- **Input_Schema**: JSON Schema yang mendefinisikan parameter input sebuah Tool, termasuk tipe data primitif dan kompleks
- **Object_Type**: Tipe data JSON Schema `object` dengan `properties`, `required`, dan nested object support dalam Input_Schema
- **Tool_Use_Block**: Content block dalam response yang menandakan model ingin memanggil sebuah Tool
- **Tool_Result_Block**: Content block dalam request yang berisi hasil eksekusi Tool yang dikembalikan ke model
- **Tool_Choice**: Konfigurasi yang mengontrol bagaimana model memilih Tool (`auto`, `any`, `tool`, `none`)
- **Streaming**: Mekanisme Server-Sent Events (SSE) untuk menerima response secara incremental
- **Extended_Thinking**: Fitur yang memungkinkan model menampilkan proses berpikir sebelum memberikan jawaban
- **Content_Block**: Unit konten dalam message — bisa berupa teks, gambar, dokumen, tool use, atau tool result
- **System_Prompt**: Instruksi sistem yang diberikan di awal percakapan untuk mengatur perilaku model
- **Stop_Reason**: Alasan model berhenti menghasilkan response (`end_turn`, `max_tokens`, `stop_sequence`, `tool_use`)
- **Serializer**: Komponen yang mengkonversi objek Dart ke format JSON untuk dikirim ke API
- **Deserializer**: Komponen yang mengkonversi response JSON dari API ke objek Dart yang type-safe
- **Parser**: Komponen yang mem-parsing response JSON dari API menjadi model objects
- **Pretty_Printer**: Komponen yang memformat model objects kembali ke representasi JSON yang valid

## Requirements

### Requirement 1: Inisialisasi dan Konfigurasi Client

**User Story:** Sebagai developer, saya ingin menginisialisasi SDK client dengan konfigurasi yang fleksibel, sehingga saya dapat terhubung ke Anthropic API dengan mudah di berbagai environment.

#### Acceptance Criteria

1. THE Client SHALL menyediakan constructor yang menerima API key sebagai parameter wajib
2. THE Client SHALL menyediakan factory method `fromEnvironment` yang membaca API key dari environment variable `ANTHROPIC_API_KEY`
3. WHEN environment variable `ANTHROPIC_API_KEY` tidak ditemukan, THE Client SHALL melempar `AuthenticationException` dengan pesan yang menjelaskan variable yang dibutuhkan
4. THE Client SHALL menerima konfigurasi opsional berupa base URL, timeout duration, dan retry policy
5. THE Client SHALL menggunakan base URL default `https://api.anthropic.com` WHEN base URL tidak dikonfigurasi secara eksplisit
6. THE Client SHALL mengirimkan header `x-api-key`, `anthropic-version`, dan `content-type` pada setiap request ke API
7. WHEN Client di-close, THE Client SHALL melepaskan semua resource HTTP connection yang digunakan
8. IF Client digunakan setelah di-close, THEN THE Client SHALL melempar `ClientClosedException`

---

### Requirement 2: Pembuatan Message (Messages API)

**User Story:** Sebagai developer, saya ingin mengirim pesan ke Claude melalui Messages API, sehingga saya dapat membangun aplikasi percakapan AI.

#### Acceptance Criteria

1. THE Messages_API SHALL menerima request dengan parameter wajib: `model`, `max_tokens`, dan `messages`
2. THE Messages_API SHALL mendukung multi-turn conversation dengan array of messages yang berisi role `user` dan `assistant`
3. THE Messages_API SHALL mendukung System_Prompt sebagai parameter opsional pada request
4. THE Messages_API SHALL mendukung Content_Block bertipe teks, gambar (base64 dan URL), dan dokumen dalam messages
5. WHEN request berhasil, THE Messages_API SHALL mengembalikan objek `Message` yang berisi `id`, `role`, `content`, `model`, `stop_reason`, dan `usage`
6. THE Messages_API SHALL menyediakan convenience getter `text` pada objek `Message` untuk mengambil konten teks dari response
7. IF API mengembalikan HTTP error 4xx atau 5xx, THEN THE Messages_API SHALL melempar exception yang sesuai dengan tipe error (`AuthenticationException`, `RateLimitException`, `InvalidRequestException`, `ApiException`)
8. THE Messages_API SHALL menyertakan informasi `usage` (input_tokens, output_tokens) pada setiap response

---

### Requirement 3: Definisi Tool dengan Object Type Support

**User Story:** Sebagai developer, saya ingin mendefinisikan tools dengan schema yang mendukung object type dan nested properties, sehingga saya dapat membuat tool parameter yang kompleks dan terstruktur.

#### Acceptance Criteria

1. THE Tool SHALL didefinisikan dengan `name`, `description`, dan `input_schema` yang mengikuti format JSON Schema
2. THE Input_Schema SHALL mendukung tipe primitif: `string`, `number`, `integer`, `boolean`
3. THE Input_Schema SHALL mendukung Object_Type dengan `properties`, `required` fields, dan `description` per property
4. THE Input_Schema SHALL mendukung nested Object_Type (object di dalam object) tanpa batas kedalaman yang ditentukan SDK
5. THE Input_Schema SHALL mendukung tipe `array` dengan `items` yang bisa berupa tipe primitif atau Object_Type
6. THE Input_Schema SHALL mendukung `enum` values pada property bertipe `string`
7. THE Tool SHALL menyediakan type-safe builder API di Dart untuk membangun Input_Schema tanpa menulis raw JSON
8. THE Serializer SHALL mengkonversi definisi Tool dari objek Dart ke format JSON yang valid sesuai spesifikasi Anthropic API
9. FOR ALL definisi Tool yang valid, parsing lalu serialisasi lalu parsing kembali SHALL menghasilkan objek yang equivalent (round-trip property)

---

### Requirement 4: Multi-Tools Support

**User Story:** Sebagai developer, saya ingin mengirim beberapa definisi tool sekaligus dalam satu request, sehingga model Claude dapat memilih dan menggunakan tool yang paling sesuai.

#### Acceptance Criteria

1. THE Messages_API SHALL menerima parameter `tools` berupa list yang berisi satu atau lebih definisi Tool
2. THE Messages_API SHALL mendukung pengiriman minimal 1 dan maksimal 128 tools dalam satu request sesuai batas Anthropic API
3. WHEN model memutuskan untuk menggunakan tool, THE Messages_API SHALL mengembalikan response dengan Stop_Reason `tool_use` dan satu atau lebih Tool_Use_Block dalam content
4. THE Tool_Use_Block SHALL berisi `id`, `name`, dan `input` yang sesuai dengan Input_Schema tool yang dipanggil
5. WHEN model menggunakan parallel tool use, THE Messages_API SHALL mengembalikan beberapa Tool_Use_Block dalam satu response
6. THE Messages_API SHALL menerima parameter `tool_choice` dengan opsi `auto`, `any`, `tool` (dengan nama spesifik), dan `none`
7. WHEN Tool_Choice `auto` dikonfigurasi, THE Messages_API SHALL membiarkan model memutuskan apakah menggunakan tool atau menjawab langsung
8. THE Tool_Choice SHALL mendukung opsi `disable_parallel_tool_use` untuk membatasi model hanya menggunakan satu tool per response

---

### Requirement 5: Tool Use Conversation Flow

**User Story:** Sebagai developer, saya ingin mengelola alur percakapan tool use secara lengkap (request → tool_use → tool_result → final response), sehingga saya dapat mengimplementasikan agentic workflow.

#### Acceptance Criteria

1. WHEN response berisi Tool_Use_Block, THE SDK SHALL menyediakan method untuk mengekstrak semua Tool_Use_Block dari response
2. THE Tool_Result_Block SHALL dapat dibuat dengan `tool_use_id` yang sesuai dengan `id` dari Tool_Use_Block
3. THE Tool_Result_Block SHALL mendukung konten berupa teks, gambar, atau kombinasi Content_Block
4. THE Tool_Result_Block SHALL mendukung flag `is_error` untuk menandakan bahwa eksekusi tool gagal
5. WHEN developer mengirim Tool_Result_Block, THE Messages_API SHALL menerima message dengan role `user` yang berisi satu atau lebih Tool_Result_Block
6. WHEN response berisi campuran TextBlock dan Tool_Use_Block, THE SDK SHALL mempertahankan urutan Content_Block sesuai response API
7. THE SDK SHALL menyediakan helper method untuk membangun multi-turn tool use conversation tanpa harus merakit message secara manual

---

### Requirement 6: Streaming Response

**User Story:** Sebagai developer, saya ingin menerima response secara streaming (token-by-token), sehingga saya dapat menampilkan output secara real-time di UI.

#### Acceptance Criteria

1. THE Messages_API SHALL menyediakan method `createStream` yang mengembalikan `Stream<MessageStreamEvent>` menggunakan SSE
2. THE MessageStreamEvent SHALL mencakup event types: `message_start`, `content_block_start`, `content_block_delta`, `content_block_stop`, `message_delta`, dan `message_stop`
3. WHEN streaming tool use response, THE MessageStreamEvent SHALL menyertakan `input_json` delta untuk Tool_Use_Block secara incremental
4. THE Stream SHALL dapat di-cancel oleh developer kapan saja tanpa menyebabkan resource leak
5. WHEN koneksi streaming terputus, THE SDK SHALL melempar `StreamException` dengan informasi error yang deskriptif
6. THE SDK SHALL menyediakan convenience method untuk mengumpulkan seluruh stream menjadi objek `Message` yang lengkap

---

### Requirement 7: Extended Thinking

**User Story:** Sebagai developer, saya ingin mengaktifkan extended thinking pada request, sehingga model dapat menampilkan proses berpikirnya sebelum memberikan jawaban.

#### Acceptance Criteria

1. THE Messages_API SHALL menerima parameter `thinking` dengan konfigurasi `enabled` (dengan `budget_tokens`), `disabled`, atau `adaptive`
2. WHEN extended thinking diaktifkan, THE response SHALL berisi `ThinkingBlock` dengan konten proses berpikir model
3. WHEN extended thinking diaktifkan, THE response MUNGKIN berisi `RedactedThinkingBlock` untuk konten yang di-redact oleh API
4. THE ThinkingBlock SHALL berisi field `thinking` (teks) dan `signature` untuk verifikasi
5. WHILE streaming dengan extended thinking aktif, THE MessageStreamEvent SHALL menyertakan `thinking` delta secara incremental

---

### Requirement 8: Serialisasi dan Deserialisasi JSON

**User Story:** Sebagai developer, saya ingin SDK menangani konversi antara objek Dart dan JSON secara otomatis dan type-safe, sehingga saya tidak perlu menulis parsing manual.

#### Acceptance Criteria

1. THE Serializer SHALL mengkonversi semua request model objects ke format JSON yang sesuai dengan spesifikasi Anthropic API
2. THE Deserializer SHALL mengkonversi semua response JSON dari API ke model objects Dart yang type-safe
3. THE Parser SHALL menangani polymorphic Content_Block (TextBlock, ToolUseBlock, ThinkingBlock, dll.) berdasarkan field `type`
4. THE Pretty_Printer SHALL memformat model objects kembali ke representasi JSON yang valid dan readable
5. FOR ALL valid Message objects, serialisasi lalu deserialisasi SHALL menghasilkan objek yang equivalent (round-trip property)
6. FOR ALL valid Tool definition objects, serialisasi lalu deserialisasi SHALL menghasilkan objek yang equivalent (round-trip property)
7. IF response JSON berisi field yang tidak dikenali, THEN THE Deserializer SHALL mengabaikan field tersebut tanpa melempar error (forward compatibility)
8. IF response JSON kehilangan field opsional, THEN THE Deserializer SHALL menggunakan nilai default yang sesuai

---

### Requirement 9: Error Handling

**User Story:** Sebagai developer, saya ingin SDK memberikan error handling yang jelas dan terstruktur, sehingga saya dapat menangani berbagai skenario kegagalan dengan tepat.

#### Acceptance Criteria

1. THE SDK SHALL mendefinisikan hierarki exception class: `AnthropicException` sebagai base, dengan subclass `AuthenticationException`, `RateLimitException`, `InvalidRequestException`, `ApiException`, `NetworkException`, dan `StreamException`
2. WHEN API mengembalikan HTTP 401, THE SDK SHALL melempar `AuthenticationException`
3. WHEN API mengembalikan HTTP 429, THE SDK SHALL melempar `RateLimitException` yang berisi informasi retry-after jika tersedia
4. WHEN API mengembalikan HTTP 400, THE SDK SHALL melempar `InvalidRequestException` dengan pesan error dari API
5. WHEN API mengembalikan HTTP 500 atau 5xx lainnya, THE SDK SHALL melempar `ApiException` dengan status code dan pesan error
6. WHEN koneksi jaringan gagal atau timeout, THE SDK SHALL melempar `NetworkException`
7. THE AnthropicException SHALL berisi field `message`, `statusCode` (jika applicable), dan `requestId` (jika tersedia dari response header)

---

### Requirement 10: Retry Policy

**User Story:** Sebagai developer, saya ingin SDK secara otomatis melakukan retry pada request yang gagal karena error sementara, sehingga aplikasi saya lebih resilient.

#### Acceptance Criteria

1. THE Client SHALL mendukung konfigurasi retry policy dengan `maxRetries` dan `initialDelay`
2. THE Client SHALL melakukan retry secara otomatis untuk HTTP status 429 (rate limit) dan 5xx (server error)
3. THE Client SHALL menggunakan exponential backoff dengan jitter untuk menghitung delay antar retry
4. THE Client SHALL menghormati header `retry-after` dari response 429 jika tersedia
5. THE Client SHALL TIDAK melakukan retry untuk HTTP status 400 dan 401
6. WHEN semua retry gagal, THE Client SHALL melempar exception dari attempt terakhir

---

### Requirement 11: Inisialisasi Project dan Dokumentasi

**User Story:** Sebagai developer, saya ingin project SDK diinisialisasi dengan struktur yang lengkap dan dokumentasi yang jelas, sehingga saya dapat langsung mulai menggunakan atau berkontribusi.

#### Acceptance Criteria

1. THE Project SHALL memiliki file `pubspec.yaml` yang valid dengan nama package, versi, deskripsi, dan dependencies yang diperlukan
2. THE Project SHALL memiliki file `README.md` yang berisi deskripsi, fitur utama, panduan instalasi, contoh penggunaan dasar, dan contoh multi-tools
3. THE Project SHALL memiliki file `CHANGELOG.md` yang mengikuti format Keep a Changelog
4. THE Project SHALL memiliki file `LICENSE` dengan lisensi MIT
5. THE Project SHALL memiliki file `analysis_options.yaml` yang mengikuti recommended Dart lints
6. THE Project SHALL memiliki struktur direktori: `lib/src/` untuk source code, `test/` untuk unit tests, dan `example/` untuk contoh penggunaan
7. THE Project SHALL memiliki file `lib/anthropic_sdk_dart.dart` sebagai barrel export yang mengekspos public API
8. THE README.md SHALL menyertakan contoh kode untuk: inisialisasi client, pembuatan message sederhana, penggunaan single tool, penggunaan multi-tools dengan object type, dan streaming
