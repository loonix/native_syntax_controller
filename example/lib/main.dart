import 'package:flutter/material.dart';
import 'package:native_syntax_controller/native_syntax_controller.dart';
import 'dart:convert';

// ---------------------------------------------------------------------------
// MAIN UI - EXAMPLE OF USING THE NATIVE_SYNTAX_CONTROLLER PACKAGE
// ---------------------------------------------------------------------------
void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  // Using the SyntaxHighlightingController from the package
  SyntaxHighlightingController? _formulaController;
  final TextEditingController _jsonController = TextEditingController();

  String _result = '';
  String _error = '';
  bool _useCustomColors = false;

  final List<Map<String, dynamic>> _examples = [
    {'formula': "3+AVERAGE(C7,D7) > 10", 'json': '{"C7": 4, "D7": 10}'},
    {'formula': "vehicle_type == 'car' && mileage > 10000", 'json': '{"vehicle_type": "car", "mileage": 15000}'},
    {'formula': "IF(score > 50, 'Pass', 'Fail')", 'json': '{"score": 75}'},
    {'formula': "vehicle_type == 'car' || vehicle_type == 'truck'", 'json': '{"vehicle_type": "car"}'},
    {'formula': "base_price * 1.15 + delivery_fee", 'json': '{"base_price": 100, "delivery_fee": 10}'},
    {'formula': "IF(vehicle_age > 5, base_price * 0.8, base_price)", 'json': '{"vehicle_age": 7, "base_price": 100}'},
    {'formula': "IF(vehicle_age > 5, base_price * 0.d8, base_price)", 'json': '{"vehicle_age": 7, "base_price": 100}'},
    {'formula': "IF(vehicle_age > 5s, base_price * 0.ss8, base_price)", 'json': '{"vehicle_age": 7, "base_price": 100}'},
    {'formula': "SUM(item_1_price, item_2_price, item_3_price)", 'json': '{"item_1_price": 50, "item_2_price": 30, "item_3_price": 20}'},
    {'formula': "field_a + field_b * 0.15 > 100", 'json': '{"field_a": 80, "field_b": 200}'},
    {'formula': "defects[0].status == 'Pass'", 'json': '{"defects": [{"status": "Pass", "severity": "High"}, {"status": "Fail", "severity": "Low"}]}'},
    {'formula': "defects[1].status == 'Fail'", 'json': '{"defects": [{"status": "Pass", "severity": "High"}, {"status": "Fail", "severity": "Low"}]}'},
    {'formula': "inspection.passed && defects[0].severity == 'High'", 'json': '{"inspection": {"passed": true}, "defects": [{"status": "Pass", "severity": "High"}]}'},
    {'formula': "ARRAY_ANY(defects, 'status', 'Fail')", 'json': '{"defects": [{"status": "Pass", "severity": "High"}, {"status": "Fail", "severity": "Low"}]}'},
    {'formula': "ARRAY_ALL(defects, 'status', 'Pass')", 'json': '{"defects": [{"status": "Pass", "severity": "High"}, {"status": "Pass", "severity": "Low"}]}'},
    {
      'formula': "IF(ARRAY_ANY(defects, 'status', 'Fail'), IF(ARRAY_ANY(defects, 'severity', 'High'), 'Critical Failure', 'Minor Failure'), 'All Passed')",
      'json': '{"defects": [{"status": "Pass", "severity": "High"}, {"status": "Fail", "severity": "High"}]}',
    },
    {
      'formula':
          "IF(vehicle_age > 10 && !ARRAY_ANY(defects, 'status', 'Fail'), IF(mileage < 50000, 'Excellent Condition', 'Good Condition'), IF(ARRAY_ALL(defects, 'severity', 'Low'), 'Needs Minor Repair', 'Needs Major Repair'))",
      'json': '{"vehicle_age": 12, "mileage": 30000, "defects": [{"status": "Pass", "severity": "Low"}]}',
    },
    {
      'formula':
          "IF(user_role == 'inspector' && inspection_date != null, IF(ARRAY_ANY(defects, 'status', 'Fail'), IF(ARRAY_ANY(defects, 'severity', 'Critical'), 'Reject Vehicle', IF(vehicle_age > 15, 'Conditional Approval', 'Approve with Repairs')), IF(mileage > 100000, 'Schedule Maintenance', 'Full Approval')), 'Access Denied')",
      'json': '{"user_role": "inspector", "inspection_date": "2025-12-11", "vehicle_age": 8, "mileage": 60000, "defects": [{"status": "Pass", "severity": "Low"}]}',
    },
  ];

  @override
  void initState() {
    super.initState();
    _updateController();
  }

  void _updateController() {
    final text = _formulaController?.text ?? '';
    if (_useCustomColors) {
      _formulaController = SyntaxHighlightingController(
        text: text,
        customStyles: {
          'function': const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          'operator': const TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold),
          'number': const TextStyle(color: Colors.yellow),
          'string': const TextStyle(color: Colors.pink),
        },
      );
    } else {
      _formulaController = SyntaxHighlightingController(text: text);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _formulaController?.dispose();
    _jsonController.dispose();
    super.dispose();
  }

  void _evaluate() {
    if (_formulaController == null) return;

    setState(() {
      _error = '';
      _result = '';
    });

    try {
      final formula = _formulaController!.text.trim();
      if (formula.isEmpty) return;

      final jsonString = _jsonController.text.trim();
      Map<String, dynamic> json = {};
      if (jsonString.isNotEmpty) {
        json = Map<String, dynamic>.from(jsonDecode(jsonString));
      }

      // Using the evaluateFormula function from the package
      final result = evaluateFormula(json, formula);
      setState(() => _result = result.toString());
    } catch (e) {
      setState(() => _error = 'Error: $e');
    }
  }

  void _testDirectFunctions() {
    setState(() {
      _error = '';
      _result = '';
    });

    try {
      // Test direct function calls
      final results = [
        'if_(true, "Pass", "Fail"): ${if_(true, "Pass", "Fail")}',
        'sum(1, 2, 3, 4, 5): ${sum(1, 2, 3, 4, 5)}',
        'average(10, 20, 30): ${average(10, 20, 30)}',
        'sin_(pi_/2): ${sin_(pi_ / 2)}',
        'cos_(0): ${cos_(0)}',
        'arrayAny([{"status": "pass"}, {"status": "fail"}], "status", "fail"): ${arrayAny([{"status": "pass"}, {"status": "fail"}], "status", "fail")}',
        'arrayAll([{"status": "pass"}, {"status": "pass"}], "status", "pass"): ${arrayAll([{"status": "pass"}, {"status": "pass"}], "status", "pass")}',
      ];

      setState(() => _result = results.join('\n'));
    } catch (e) {
      setState(() => _error = 'Error: $e');
    }
  }

  void _loadExample(int index) {
    if (_formulaController == null) return;

    final example = _examples[index];
    _formulaController!.text = example['formula'];
    _jsonController.text = example['json'];
    _evaluate();
  }

  void _toggleCustomColors(bool value) {
    setState(() => _useCustomColors = value);
    _updateController();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(title: const Text('Native Syntax Controller Formula Editor')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Formula:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                child: TextField(
                  controller: _formulaController, // Using the controller from the package with highlighting
                  maxLines: null,
                  style: const TextStyle(fontFamily: 'Courier', fontSize: 16),
                  decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(16), hintText: 'Ex: 3+AVERAGE(C7,D7)'),
                ),
              ),

              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Custom Colors:'),
                  Switch(value: _useCustomColors, onChanged: _toggleCustomColors),
                ],
              ),

              const SizedBox(height: 16),
              const Text('JSON:', style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: _jsonController,
                maxLines: 2,
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Ex: {"C7": 4}'),
              ),

              const SizedBox(height: 16),
              ElevatedButton(onPressed: _evaluate, child: const Text('Evaluate')),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _testDirectFunctions, child: const Text('Test Direct Functions'), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue)),

              const SizedBox(height: 16),
              if (_error.isNotEmpty) Text(_error, style: const TextStyle(color: Colors.redAccent)),
              if (_result.isNotEmpty) Text('Result: $_result', style: const TextStyle(fontSize: 18, color: Colors.greenAccent)),

              const Divider(height: 32),

              Expanded(
                child: ListView.builder(
                  itemCount: _examples.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_examples[index]['formula']),
                      subtitle: Text(_examples[index]['json'], maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () => _loadExample(index),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
