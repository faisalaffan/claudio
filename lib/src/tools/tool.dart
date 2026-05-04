/// A tool that the model can call.
class Tool {
  final String name;
  final String? description;
  final Map<String, dynamic> inputSchema;

  const Tool({
    required this.name,
    this.description,
    required this.inputSchema,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null) 'description': description,
        'input_schema': inputSchema,
      };
}
