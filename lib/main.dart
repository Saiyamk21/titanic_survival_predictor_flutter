import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const TitanicApp());
}

class TitanicApp extends StatelessWidget {
  const TitanicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Titanic Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const TitanicForm(),
    );
  }
}

class TitanicForm extends StatefulWidget {
  const TitanicForm({super.key});

  @override
  State<TitanicForm> createState() => _TitanicFormState();
}

class _TitanicFormState extends State<TitanicForm> {
  final _formKey = GlobalKey<FormState>();

  double pclass = 3;
  double age = 25;
  double sibsp = 0;
  double parch = 0;
  double fare = 30;
  String sex = 'male';
  String embarked = 'S';

  String? prediction;
  String? survivalProb;
  String? deathProb;
  String? error;

  bool isLoading = false;

  Future<void> predict() async {
    final url = Uri.parse("https://saiyamkkkalls-tittanicspace.hf.space/run/predict");

    final body = jsonEncode({
      "data": [pclass, age, sibsp, parch, fare, sex, embarked]
    });

    setState(() {
      isLoading = true;
      prediction = null;
      survivalProb = null;
      deathProb = null;
      error = null;
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final resultString = decoded["data"][0] as String;
        final lines = resultString.split('\n');

        setState(() {
          prediction = lines[0].replaceFirst("Prediction: ", "").trim();
          survivalProb = lines[1].replaceFirst("Probability of Survival: ", "").trim();
          deathProb = lines[2].replaceFirst("Probability of Not Surviving: ", "").trim();
        });
      } else {
        setState(() {
          error = "Prediction failed: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        error = "Error: $e";
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildDropdown<T>(String label, T value, List<T> options, Function(T?) onChanged) {
    return DropdownButtonFormField<T>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label),
      items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt.toString()))).toList(),
    );
  }

  Widget _buildNumberField(String label, double value, Function(String) onChanged) {
    return TextFormField(
      initialValue: value.toString(),
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      onChanged: onChanged,
    );
  }

  Widget _buildPredictionCard() {
    return AnimatedOpacity(
      opacity: prediction != null ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Card(
        color: prediction == "Survived" ? Colors.green[100] : Colors.red[100],
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Prediction:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    prediction == "Survived" ? Icons.check_circle : Icons.cancel,
                    color: prediction == "Survived" ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    prediction ?? "",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const Divider(height: 20),
              Text("Survival Probability: $survivalProb", style: TextStyle(fontSize: 16)),
              Text("Death Probability: $deathProb", style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Titanic Survival Predictor'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildDropdown("Pclass", pclass, [1.0, 2.0, 3.0], (val) => setState(() => pclass = val!)),
              _buildNumberField("Age", age, (val) => age = double.tryParse(val) ?? age),
              _buildNumberField("SibSp", sibsp, (val) => sibsp = double.tryParse(val) ?? sibsp),
              _buildNumberField("Parch", parch, (val) => parch = double.tryParse(val) ?? parch),
              _buildNumberField("Fare", fare, (val) => fare = double.tryParse(val) ?? fare),
              _buildDropdown("Sex", sex, ['male', 'female'], (val) => setState(() => sex = val!)),
              _buildDropdown("Embarked", embarked, ['S', 'C', 'Q'], (val) => setState(() => embarked = val!)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: isLoading ? null : predict,
                icon: isLoading
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.analytics_outlined),
                label: const Text("Predict"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 30),
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              if (prediction != null) _buildPredictionCard(),
            ],
          ),
        ),
      ),
    );
  }
}
