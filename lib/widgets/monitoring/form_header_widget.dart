import 'package:flutter/material.dart';
import '../../models/monitoring_model.dart';

class FormHeaderWidget extends StatelessWidget {
  final TextEditingController storeNameController;
  final TextEditingController storeAddressController;
  final TextEditingController storeRepController;
  final TextEditingController dtiMonitorController;
  final DateTime monitoringDate;
  final MonitoringMode monitoringMode;
  final Function(DateTime) onDateChanged;
  final Function(MonitoringMode) onModeChanged;

  const FormHeaderWidget({
    super.key,
    required this.storeNameController,
    required this.storeAddressController,
    required this.storeRepController,
    required this.dtiMonitorController,
    required this.monitoringDate,
    required this.monitoringMode,
    required this.onDateChanged,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.store, color: Color(0xFF3498db)),
                const SizedBox(width: 8),
                Text(
                  'Store Information',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Store Name
            TextFormField(
              controller: storeNameController,
              decoration: const InputDecoration(
                labelText: 'Name of Store',
                hintText: 'Enter store name',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Store name is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Store Address
            TextFormField(
              controller: storeAddressController,
              decoration: const InputDecoration(
                labelText: 'Store Address',
                hintText: 'Enter complete store address',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Store address is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Date of Monitoring
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date of Monitoring',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(monitoringDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Mode of Monitoring
            DropdownButtonFormField<MonitoringMode>(
              value: monitoringMode,
              decoration: const InputDecoration(
                labelText: 'Mode of Monitoring',
                prefixIcon: Icon(Icons.monitor),
                border: OutlineInputBorder(),
              ),
              items: MonitoringMode.values.map((mode) {
                return DropdownMenuItem(
                  value: mode,
                  child: Text(mode.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  onModeChanged(value);
                }
              },
              validator: (value) {
                if (value == null) {
                  return 'Monitoring mode is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Store Representative
            TextFormField(
              controller: storeRepController,
              decoration: const InputDecoration(
                labelText: 'Name & Designation of Store Representative',
                hintText: 'Enter representative name and designation',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Store representative is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // DTI Monitor
            TextFormField(
              controller: dtiMonitorController,
              decoration: const InputDecoration(
                labelText: 'DTI Monitor Name & Signature',
                hintText: 'Enter DTI monitor name',
                prefixIcon: Icon(Icons.verified_user),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'DTI monitor is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Form Summary Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Form Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryItem('Store', storeNameController.text.isNotEmpty ? storeNameController.text : 'Not specified'),
                  _buildSummaryItem('Address', storeAddressController.text.isNotEmpty ? storeAddressController.text : 'Not specified'),
                  _buildSummaryItem('Date', _formatDate(monitoringDate)),
                  _buildSummaryItem('Mode', monitoringMode.displayName),
                  _buildSummaryItem('Representative', storeRepController.text.isNotEmpty ? storeRepController.text : 'Not specified'),
                  _buildSummaryItem('DTI Monitor', dtiMonitorController.text.isNotEmpty ? dtiMonitorController.text : 'Not specified'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: monitoringDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3498db),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != monitoringDate) {
      onDateChanged(picked);
    }
  }
}
