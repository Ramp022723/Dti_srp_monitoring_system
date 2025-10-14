import 'package:flutter/material.dart';
import '../services/registration_debug_service.dart';
// import '../services/registration_service.dart'; // File doesn't exist

/// Registration Debug Page
/// 
/// This page helps debug registration issues by running comprehensive tests
/// and displaying detailed information about API responses.
class RegistrationDebugPage extends StatefulWidget {
  const RegistrationDebugPage({Key? key}) : super(key: key);

  @override
  State<RegistrationDebugPage> createState() => _RegistrationDebugPageState();
}

class _RegistrationDebugPageState extends State<RegistrationDebugPage> {
  bool _isLoading = false;
  Map<String, dynamic>? _testResults;
  String _selectedTest = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Debug'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Test Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Test Type',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    DropdownButton<String>(
                      value: _selectedTest,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Tests')),
                        DropdownMenuItem(value: 'connectivity', child: Text('API Connectivity')),
                        DropdownMenuItem(value: 'consumer', child: Text('Consumer Registration')),
                        DropdownMenuItem(value: 'retailer', child: Text('Retailer Registration')),
                        DropdownMenuItem(value: 'invalid_consumer', child: Text('Invalid Consumer Data')),
                        DropdownMenuItem(value: 'invalid_retailer', child: Text('Invalid Retailer Data')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedTest = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Run Tests Button
            ElevatedButton(
              onPressed: _isLoading ? null : _runTests,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text('Running Tests...'),
                      ],
                    )
                  : const Text('Run Tests'),
            ),
            
            const SizedBox(height: 16),
            
            // Test Results
            if (_testResults != null) ...[
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Test Results',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: SingleChildScrollView(
                            child: _buildTestResults(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _runTests() async {
    setState(() {
      _isLoading = true;
      _testResults = null;
    });

    try {
      Map<String, dynamic> results;
      
      switch (_selectedTest) {
        case 'connectivity':
          results = await RegistrationDebugService.testApiConnectivity();
          break;
        case 'consumer':
          results = await RegistrationDebugService.testConsumerRegistration();
          break;
        case 'retailer':
          results = await RegistrationDebugService.testRetailerRegistration();
          break;
        case 'invalid_consumer':
          results = await RegistrationDebugService.testInvalidConsumerRegistration();
          break;
        case 'invalid_retailer':
          results = await RegistrationDebugService.testInvalidRetailerRegistration();
          break;
        case 'all':
        default:
          results = await RegistrationDebugService.runComprehensiveTests();
          break;
      }

      setState(() {
        _testResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResults = {
          'error': 'Test execution failed: $e',
        };
        _isLoading = false;
      });
    }
  }

  Widget _buildTestResults() {
    if (_testResults == null) return const SizedBox();

    if (_testResults!['error'] != null) {
      return Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Error',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 8),
              Text(
                _testResults!['error'],
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      );
    }

    if (_selectedTest == 'all') {
      return _buildComprehensiveResults();
    } else {
      return _buildSingleTestResults();
    }
  }

  Widget _buildComprehensiveResults() {
    final summary = _testResults!['summary'] as Map<String, dynamic>?;
    final connectivity = _testResults!['connectivity'] as Map<String, dynamic>?;
    final consumerTest = _testResults!['consumer_test'] as Map<String, dynamic>?;
    final retailerTest = _testResults!['retailer_test'] as Map<String, dynamic>?;
    final invalidConsumerTest = _testResults!['invalid_consumer_test'] as Map<String, dynamic>?;
    final invalidRetailerTest = _testResults!['invalid_retailer_test'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary
        if (summary != null) ...[
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Test Summary',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Total Tests: ${summary['total_tests']}'),
                  Text('Passed Tests: ${summary['passed_tests']}'),
                  const SizedBox(height: 8),
                  _buildStatusRow('Connectivity', summary['connectivity_status']),
                  _buildStatusRow('Consumer Registration', summary['consumer_status']),
                  _buildStatusRow('Retailer Registration', summary['retailer_status']),
                  _buildStatusRow('Invalid Consumer Test', summary['invalid_consumer_status']),
                  _buildStatusRow('Invalid Retailer Test', summary['invalid_retailer_status']),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Individual Test Results
        if (connectivity != null) _buildTestCard('API Connectivity', connectivity),
        if (consumerTest != null) _buildTestCard('Consumer Registration', consumerTest),
        if (retailerTest != null) _buildTestCard('Retailer Registration', retailerTest),
        if (invalidConsumerTest != null) _buildTestCard('Invalid Consumer Test', invalidConsumerTest),
        if (invalidRetailerTest != null) _buildTestCard('Invalid Retailer Test', invalidRetailerTest),
      ],
    );
  }

  Widget _buildSingleTestResults() {
    return _buildTestCard('Test Results', _testResults!);
  }

  Widget _buildTestCard(String title, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            // Status
            if (data['status'] != null)
              _buildStatusRow('Status', data['status']),
            
            // Message
            if (data['message'] != null)
              _buildInfoRow('Message', data['message']),
            
            // Response Status
            if (data['response_status'] != null)
              _buildInfoRow('Response Status', data['response_status'].toString()),
            
            // Is Success
            if (data['is_success'] != null)
              _buildStatusRow('Success', data['is_success'] ? 'YES' : 'NO'),
            
            // Expected Error
            if (data['expected_error'] != null)
              _buildInfoRow('Expected Error', data['expected_error'] ? 'YES' : 'NO'),
            
            // Got Error
            if (data['got_error'] != null)
              _buildInfoRow('Got Error', data['got_error'] ? 'YES' : 'NO'),
            
            // Request URL
            if (data['request_url'] != null)
              _buildInfoRow('Request URL', data['request_url']),
            
            // Response Body
            if (data['response_body'] != null) ...[
              const SizedBox(height: 8),
              const Text(
                'Response Body:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  data['response_body'],
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
            
            // Parsed Response
            if (data['parsed_response'] != null) ...[
              const SizedBox(height: 8),
              const Text(
                'Parsed Response:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  data['parsed_response'].toString(),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String status) {
    Color color;
    switch (status.toUpperCase()) {
      case 'PASS':
      case 'SUCCESS':
      case 'YES':
        color = Colors.green;
        break;
      case 'FAIL':
      case 'ERROR':
      case 'NO':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: '),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
