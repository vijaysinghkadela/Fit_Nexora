/// Model representing a motivational quote for gym members
class QuoteModel {
  final String id;
  final String text;
  final String author;
  final String category;

  const QuoteModel({
    required this.id,
    required this.text,
    required this.author,
    required this.category,
  });

  factory QuoteModel.fromJson(Map<String, dynamic> json) {
    return QuoteModel(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      author: json['author'] ?? 'Unknown',
      category: json['category'] ?? 'motivation',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'author': author,
      'category': category,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuoteModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
