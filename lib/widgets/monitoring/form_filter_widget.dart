import 'package:flutter/material.dart';

class FormFilterWidget extends StatelessWidget {
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? selectedStore;
  final Function(DateTime?) onDateFromChanged;
  final Function(DateTime?) onDateToChanged;
  final Function(String?) onStoreChanged;
  final VoidCallback onApplyFilters;
  final VoidCallback onClearFilters;

  const FormFilterWidget({
    super.key,
    required this.dateFrom,
    required this.dateTo,
    required this.selectedStore,
    required this.onDateFromChanged,
    required this.onDateToChanged,
    required this.onStoreChanged,
    required this.onApplyFilters,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list, color: Color(0xFF3498db)),
              const SizedBox(width: 8),
              Text(
                'Filter Options',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date Range Filters
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, true),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date From',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    child: Text(
                      dateFrom != null 
                          ? _formatDate(dateFrom!)
                          : 'Select start date',
                      style: TextStyle(
                        color: dateFrom != null ? Colors.black : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, false),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date To',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    child: Text(
                      dateTo != null 
                          ? _formatDate(dateTo!)
                          : 'Select end date',
                      style: TextStyle(
                        color: dateTo != null ? Colors.black : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Store Filter
          TextFormField(
            initialValue: selectedStore,
            decoration: InputDecoration(
              labelText: 'Store Name',
              hintText: 'Filter by store name',
              prefixIcon: const Icon(Icons.store),
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: selectedStore != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => onStoreChanged(null),
                    )
                  : null,
            ),
            onChanged: (value) {
              onStoreChanged(value.trim().isEmpty ? null : value.trim());
            },
          ),

          const SizedBox(height: 16),

          // Filter Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear All'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    side: BorderSide(color: Colors.grey[400]!),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onApplyFilters,
                  icon: const Icon(Icons.search),
                  label: const Text('Apply Filters'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3498db),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          // Active Filters Summary
          if (dateFrom != null || dateTo != null || selectedStore != null) ...[
            const SizedBox(height: 16),
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
                      Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Active Filters:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (dateFrom != null)
                        _buildFilterChip('From: ${_formatDate(dateFrom!)}', () => onDateFromChanged(null)),
                      if (dateTo != null)
                        _buildFilterChip('To: ${_formatDate(dateTo!)}', () => onDateToChanged(null)),
                      if (selectedStore != null)
                        _buildFilterChip('Store: $selectedStore', () => onStoreChanged(null)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[800],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 16,
              color: Colors.blue[600],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate 
          ? (dateFrom ?? DateTime.now().subtract(const Duration(days: 30)))
          : (dateTo ?? DateTime.now()),
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

    if (picked != null) {
      if (isFromDate) {
        onDateFromChanged(picked);
      } else {
        onDateToChanged(picked);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
