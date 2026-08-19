import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:smart_application/core/theme/app_theme.dart';
import 'package:smart_application/features/meter/services/meter_service.dart';
import 'package:intl/intl.dart';

class ViewMeterBillingScreen extends StatefulWidget {
  final Map<String, String> meterInfo;
  const ViewMeterBillingScreen({super.key, required this.meterInfo});

  @override
  State<ViewMeterBillingScreen> createState() => _ViewMeterBillingScreenState();
}

class _ViewMeterBillingScreenState extends State<ViewMeterBillingScreen> {
  String _billingData = "";
  bool _isLoading = false;
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 365));
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Fetch automatically for the last year on start
    _fetchMeterBilling();
  }

  Future<void> _fetchMeterBilling() async {
    setState(() => _isLoading = true);
    
    final meterNo = widget.meterInfo['display_meter'] ?? "";
    final fromStr = DateFormat('yyyyMMdd').format(_fromDate);
    final toStr = DateFormat('yyyyMMdd').format(_toDate);
    
    final result = await MeterService.getMeterBilling(meterNo, fromStr, toStr);
    
    if (mounted) {
      setState(() {
        _billingData = result;
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _fetchMeterBilling();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سجل فواتير العداد'),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.date_range_rounded),
              onPressed: _selectDateRange,
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.primaryBlue.withValues(alpha: 0.05),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('الفترة الزمنية:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${DateFormat('yyyy/MM/dd').format(_fromDate)} - ${DateFormat('yyyy/MM/dd').format(_toDate)}',
                    style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: SelectableText(
                          _billingData,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _fetchMeterBilling,
          backgroundColor: AppTheme.primaryBlue,
          child: const Icon(Icons.refresh, color: Colors.white),
        ),
      ),
    );
  }
}
