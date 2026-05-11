import 'package:flutter/material.dart';

class CatProfile {
  final String id;
  final String name;
  final Color color;
  final String preferredMode;

  CatProfile({
    required this.id,
    required this.name,
    required this.color,
    this.preferredMode = 'Under the Rug',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
      'preferredMode': preferredMode,
    };
  }

  factory CatProfile.fromJson(Map<String, dynamic> json) {
    return CatProfile(
      id: json['id'],
      name: json['name'],
      color: Color(json['color']),
      preferredMode: json['preferredMode'] ?? 'Under the Rug',
    );
  }
}
