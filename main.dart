import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future main() async {
  await dotenv.load();
  runApp(UniversalBacklinkApp());
}

class UniversalBacklinkApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universal Backlink Generator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: BacklinkDashboard(),
    );
  }
}

class BacklinkDashboard extends StatefulWidget {
  @override
  _BacklinkDashboardState createState() => _BacklinkDashboardState();
}

class _BacklinkDashboardState extends State<BacklinkDashboard> {
  TextEditingController _urlController = TextEditingController();
  List<Backlink> _backlinks = [];
  bool _isLoading = false;
  bool _isSubmitting = false;

  Future<void> _fetchBacklinks() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('\${dotenv.env['API_URL']}/backlinks?url=\${_urlController.text}'),
      );
      setState(() {
        _backlinks = Backlink.parseJson(json.decode(response.body));
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: \$e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateBacklinks() async {
    setState(() => _isSubmitting = true);
    try {
      await http.post(
        Uri.parse('\${dotenv.env['API_URL']}/generate'),
        body: {'url': _urlController.text},
      );
      await _fetchBacklinks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed: \$e')),
      );
    }
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Universal Backlink Generator')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Enter Website URL',
                hintText: 'https://example.com',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _generateBacklinks,
                  child: _isSubmitting 
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Generate Backlinks'),
                ),
                ElevatedButton(
                  onPressed: _fetchBacklinks,
                  child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Refresh Data'),
                ),
              ],
            ),
            Expanded(
              child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _backlinks.length,
                    itemBuilder: (ctx, index) => BacklinkCard(_backlinks[index]),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class BacklinkCard extends StatelessWidget {
  final Backlink backlink;

  BacklinkCard(this.backlink);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          backlink.status == 'SUCCESS' ? Icons.check_circle : Icons.error,
          color: backlink.status == 'SUCCESS' ? Colors.green : Colors.red,
        ),
        title: Text(backlink.domain),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("DA: \${backlink.da}"),
            Text("Type: \${backlink.type}"),
            Text("Date: \${backlink.date}"),
          ],
        ),
      ),
    );
  }
}

class Backlink {
  final String domain;
  final String status;
  final String da;
  final String type;
  final String date;

  Backlink({this.domain, this.status, this.da, this.type, this.date});

  static List<Backlink> parseJson(List<dynamic> json) {
    return json.map((item) => Backlink(
      domain: item['domain'],
      status: item['status'],
      da: item['da'],
      type: item['type'],
      date: item['date'],
    )).toList();
  }
}
