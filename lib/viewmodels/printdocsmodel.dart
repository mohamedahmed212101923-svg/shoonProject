import 'package:flutter/material.dart';
import '../services/database/leaders_repository.dart';

class LeadersViewModel2 extends ChangeNotifier {
  final LeadersRepository repo;
  LeadersViewModel2(this.repo);

  Map<String, Map<String, dynamic>> leaders = {};
  bool loading = false;
}
