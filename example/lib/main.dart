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
  int _selectedCategoryIndex = 0;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Basic Math', 'icon': Icons.calculate, 'color': Colors.blue},
    {'name': 'String Ops', 'icon': Icons.text_fields, 'color': Colors.green},
    {'name': 'Math Functions', 'icon': Icons.functions, 'color': Colors.orange},
    {'name': 'Arrays', 'icon': Icons.list, 'color': Colors.purple},
    {'name': 'Complex', 'icon': Icons.psychology, 'color': Colors.red},
  ];

  final Map<String, List<Map<String, dynamic>>> _examplesByCategory = {
    'Basic Math': [
      {'formula': "3+AVERAGE(C7,D7) > 10", 'json': '{"C7": 4, "D7": 10}', 'description': 'Basic arithmetic with average'},
      {'formula': "vehicle_type == 'car' && mileage > 10000", 'json': '{"vehicle_type": "car", "mileage": 15000}', 'description': 'Boolean logic with variables'},
      {'formula': "base_price * 1.15 + delivery_fee", 'json': '{"base_price": 100, "delivery_fee": 10}', 'description': 'Price calculation with tax'},
      {'formula': "field_a + field_b * 0.15 > 100", 'json': '{"field_a": 80, "field_b": 200}', 'description': 'Percentage calculation'},
    ],
    'String Ops': [
      {'formula': "CONTAINS(product_name, 'premium')", 'json': '{"product_name": "premium package"}', 'description': 'Check if string contains substring'},
      {'formula': "LENGTH(customer_name) > 3", 'json': '{"customer_name": "John"}', 'description': 'String length validation'},
      {'formula': "IF(CONTAINS(status, 'error'), 'Alert', 'OK')", 'json': '{"status": "system error detected"}', 'description': 'Conditional string checking'},
    ],
    'Math Functions': [
      {'formula': "ABS(temperature_difference) < 5", 'json': '{"temperature_difference": -3.2}', 'description': 'Absolute value comparison'},
      {'formula': "SQRT(area) > 10", 'json': '{"area": 144}', 'description': 'Square root calculation'},
      {'formula': "MIN(price_a, price_b, price_c) < 50", 'json': '{"price_a": 45, "price_b": 55, "price_c": 60}', 'description': 'Find minimum value'},
      {'formula': "MAX(scores) >= 90", 'json': '{"scores": [85, 92, 78]}', 'description': 'Find maximum in array'},
    ],
    'Arrays': [
      {'formula': "SUM(item_1_price, item_2_price, item_3_price)", 'json': '{"item_1_price": 50, "item_2_price": 30, "item_3_price": 20}', 'description': 'Sum multiple values'},
      {'formula': "defects[0].status == 'Pass'", 'json': '{"defects": [{"status": "Pass", "severity": "High"}, {"status": "Fail", "severity": "Low"}]}', 'description': 'Array indexing'},
      {
        'formula': "ARRAY_ANY(defects, 'status', 'Fail')",
        'json': '{"defects": [{"status": "Pass", "severity": "High"}, {"status": "Fail", "severity": "Low"}]}',
        'description': 'Check if any item matches',
      },
      {
        'formula': "ARRAY_ALL(defects, 'status', 'Pass')",
        'json': '{"defects": [{"status": "Pass", "severity": "High"}, {"status": "Pass", "severity": "Low"}]}',
        'description': 'Check if all items match',
      },
      {'formula': "LENGTH(items) == 0 || SUM(items) > 100", 'json': '{"items": [25, 30, 50]}', 'description': 'Array length and sum'},
    ],
    'Complex': [
      {'formula': "IF(score > 50, 'Pass', 'Fail')", 'json': '{"score": 75}', 'description': 'Simple conditional'},
      {
        'formula': "inspection.passed && defects[0].severity == 'High'",
        'json': '{"inspection": {"passed": true}, "defects": [{"status": "Pass", "severity": "High"}]}',
        'description': 'Nested object access',
      },
      {
        'formula': "IF(ARRAY_ANY(defects, 'status', 'Fail'), IF(ARRAY_ANY(defects, 'severity', 'High'), 'Critical Failure', 'Minor Failure'), 'All Passed')",
        'json': '{"defects": [{"status": "Pass", "severity": "High"}, {"status": "Fail", "severity": "High"}]}',
        'description': 'Nested conditionals with arrays',
      },
      {
        'formula':
            "IF(vehicle_age > 10 && !ARRAY_ANY(defects, 'status', 'Fail'), IF(mileage < 50000, 'Excellent Condition', 'Good Condition'), IF(ARRAY_ALL(defects, 'severity', 'Low'), 'Needs Minor Repair', 'Needs Major Repair'))",
        'json': '{"vehicle_age": 12, "mileage": 30000, "defects": [{"status": "Pass", "severity": "Low"}]}',
        'description': 'Complex business logic',
      },
    ],
  };

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
        '✅ if_(true, "Pass", "Fail"): ${if_(true, "Pass", "Fail")}',
        '✅ sum(1, 2, 3, 4, 5): ${sum(1, 2, 3, 4, 5)}',
        '✅ average(10, 20, 30): ${average(10, 20, 30)}',
        '✅ sin_(π/2): ${sin_(pi_ / 2)}',
        '✅ cos_(0): ${cos_(0)}',
        '✅ abs_(-5): ${abs_(-5)}',
        '✅ sqrt_(9): ${sqrt_(9)}',
        '✅ min_(5, 3, 8): ${min_(5, 3, 8)}',
        '✅ max_(5, 3, 8): ${max_(5, 3, 8)}',
        '✅ contains_("hello world", "world"): ${contains_("hello world", "world")}',
        '✅ length("hello"): ${length("hello")}',
        '✅ length([1, 2, 3]): ${length([1, 2, 3])}',
        '✅ arrayAny([...], "status", "fail"): ${arrayAny([
          {"status": "pass"},
          {"status": "fail"},
        ], "status", "fail")}',
        '✅ arrayAll([...], "status", "pass"): ${arrayAll([
          {"status": "pass"},
          {"status": "pass"},
        ], "status", "pass")}',
      ];

      setState(() => _result = results.join('\n'));
    } catch (e) {
      setState(() => _error = 'Error: $e');
    }
  }

  void _loadExample(Map<String, dynamic> example) {
    if (_formulaController == null) return;

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
    final currentCategory = _categories[_selectedCategoryIndex]['name'] as String;
    final examples = _examplesByCategory[currentCategory] ?? [];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        cardTheme: CardThemeData(elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Native Syntax Controller'), backgroundColor: Colors.black87, foregroundColor: Colors.white, elevation: 0),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isLargeScreen = constraints.maxWidth > 800;

            // Category selector widget
            final categorySelector = ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isLargeScreen ? 300 : double.infinity, maxHeight: isLargeScreen ? double.infinity : 120),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: isLargeScreen
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.category, color: Colors.purple),
                                const SizedBox(width: 8),
                                const Text('Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Wrapping layout for large screens
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: List.generate(_categories.length, (index) {
                                final category = _categories[index];
                                final isSelected = index == _selectedCategoryIndex;
                                return FilterChip(
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => _selectedCategoryIndex = index);
                                    }
                                  },
                                  label: Row(children: [Icon(category['icon'] as IconData, size: 16), const SizedBox(width: 6), Text(category['name'] as String)]),
                                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  selectedColor: (category['color'] as Color).withValues(alpha: 0.2),
                                  checkmarkColor: category['color'] as Color,
                                );
                              }),
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [const Text('Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))],
                              ),
                              const SizedBox(height: 12),
                              // Wrapping layout for small screens
                              Wrap(
                                spacing: 8.0,
                                runSpacing: 8.0,
                                children: List.generate(_categories.length, (index) {
                                  final category = _categories[index];
                                  final isSelected = index == _selectedCategoryIndex;
                                  return FilterChip(
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() => _selectedCategoryIndex = index);
                                      }
                                    },
                                    label: Row(children: [Icon(category['icon'] as IconData, size: 18), const SizedBox(width: 4), Text(category['name'] as String)]),
                                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    selectedColor: (category['color'] as Color).withValues(alpha: 0.2),
                                    checkmarkColor: category['color'] as Color,
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            );

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: isLargeScreen
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Main content area
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Formula Input Section
                                  Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.edit, color: Colors.blue),
                                              const SizedBox(width: 8),
                                              const Text('Formula Editor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                              const Spacer(),
                                              const Text('Custom Colors'),
                                              Switch(value: _useCustomColors, onChanged: _toggleCustomColors, activeThumbColor: Colors.orange),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                                            ),
                                            child: TextField(
                                              controller: _formulaController,
                                              maxLines: 3,
                                              style: const TextStyle(fontFamily: 'Courier', fontSize: 16),
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding: const EdgeInsets.all(16),
                                                hintText: 'Enter your formula...',
                                                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // JSON Input Section
                                  Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.data_object, color: Colors.green),
                                              const SizedBox(width: 8),
                                              const Text('Context Data (JSON)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          TextField(
                                            controller: _jsonController,
                                            maxLines: 2,
                                            style: const TextStyle(fontFamily: 'Courier'),
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                              hintText: '{"variable": "value"}',
                                              contentPadding: const EdgeInsets.all(12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Action Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: _evaluate,
                                          icon: const Icon(Icons.play_arrow),
                                          label: const Text('Evaluate'),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: _testDirectFunctions,
                                          icon: const Icon(Icons.science),
                                          label: const Text('Test Functions'),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Result Display
                            if (_error.isNotEmpty || _result.isNotEmpty)
                              Expanded(
                                flex: 1,
                                child: Card(
                                  color: _error.isNotEmpty ? Theme.of(context).colorScheme.errorContainer : Theme.of(context).colorScheme.primaryContainer,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              _error.isNotEmpty ? Icons.error : Icons.check_circle,
                                              color: _error.isNotEmpty ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _error.isNotEmpty ? 'Error' : 'Result',
                                              style: TextStyle(fontWeight: FontWeight.bold, color: _error.isNotEmpty ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        SingleChildScrollView(
                                          child: Text(
                                            _error.isNotEmpty ? _error : _result,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontFamily: 'Courier',
                                              color: _error.isNotEmpty ? Theme.of(context).colorScheme.onErrorContainer : Theme.of(context).colorScheme.onPrimaryContainer,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Categories and Examples side by side
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              categorySelector,
                              const SizedBox(width: 16),
                              Expanded(
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.list, color: Colors.teal),
                                            const SizedBox(width: 8),
                                            const Text('Examples', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Expanded(
                                          child: ListView.builder(
                                            itemCount: examples.length,
                                            itemBuilder: (context, index) {
                                              final example = examples[index];
                                              return Card(
                                                margin: const EdgeInsets.only(bottom: 8),
                                                child: InkWell(
                                                  onTap: () => _loadExample(example),
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(12.0),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(example['description'] as String, style: const TextStyle(fontWeight: FontWeight.w500)),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          example['formula'] as String,
                                                          style: TextStyle(fontFamily: 'Courier', color: Theme.of(context).colorScheme.primary, fontSize: 14),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          example['json'] as String,
                                                          style: TextStyle(fontFamily: 'Courier', color: Theme.of(context).colorScheme.secondary, fontSize: 12),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Formula Input Section
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.edit, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    const Text('Formula Editor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const Spacer(),
                                    const Text('Custom Colors'),
                                    Switch(value: _useCustomColors, onChanged: _toggleCustomColors, activeThumbColor: Colors.orange),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                                  ),
                                  child: TextField(
                                    controller: _formulaController,
                                    maxLines: 3,
                                    style: const TextStyle(fontFamily: 'Courier', fontSize: 16),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.all(16),
                                      hintText: 'Enter your formula...',
                                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // JSON Input Section
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.data_object, color: Colors.green),
                                    const SizedBox(width: 8),
                                    const Text('Context Data (JSON)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _jsonController,
                                  maxLines: 2,
                                  style: const TextStyle(fontFamily: 'Courier'),
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    hintText: '{"variable": "value"}',
                                    contentPadding: const EdgeInsets.all(12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _evaluate,
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Evaluate'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _testDirectFunctions,
                                icon: const Icon(Icons.science),
                                label: const Text('Test Functions'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Result Display
                        if (_error.isNotEmpty || _result.isNotEmpty)
                          Card(
                            color: _error.isNotEmpty ? Theme.of(context).colorScheme.errorContainer : Theme.of(context).colorScheme.primaryContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _error.isNotEmpty ? Icons.error : Icons.check_circle,
                                        color: _error.isNotEmpty ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _error.isNotEmpty ? 'Error' : 'Result',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: _error.isNotEmpty ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _error.isNotEmpty ? _error : _result,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'Courier',
                                      color: _error.isNotEmpty ? Theme.of(context).colorScheme.onErrorContainer : Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Category Tabs
                        categorySelector,

                        const SizedBox(height: 8),

                        // Examples List
                        Expanded(
                          child: ListView.builder(
                            itemCount: examples.length,
                            itemBuilder: (context, index) {
                              final example = examples[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  onTap: () => _loadExample(example),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(example['description'] as String, style: const TextStyle(fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 4),
                                        Text(
                                          example['formula'] as String,
                                          style: TextStyle(fontFamily: 'Courier', color: Theme.of(context).colorScheme.primary, fontSize: 14),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          example['json'] as String,
                                          style: TextStyle(fontFamily: 'Courier', color: Theme.of(context).colorScheme.secondary, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}
