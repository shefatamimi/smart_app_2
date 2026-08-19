import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_application/features/meter/services/meter_service.dart';
import 'package:smart_application/features/meter/models/meter_event_item.dart';
import 'package:smart_application/core/theme/app_theme.dart';

class ViewMeterEventsScreen extends StatefulWidget {
  final Map<String, String> meterInfo;
  const ViewMeterEventsScreen({super.key, required this.meterInfo});

  @override
  State<ViewMeterEventsScreen> createState() => _ViewMeterEventsScreenState();
}

class _ViewMeterEventsScreenState extends State<ViewMeterEventsScreen> {
  DateTime startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime endDate = DateTime.now();
  
  List<MeterEventItem> _events = [];
  bool _isLoading = false;

  Future<void> _handleSearch() async {
    setState(() => _isLoading = true);
    
    final meterMNum = widget.meterInfo['display_meter'] ?? "";
    final fromStr = DateFormat('dd/MM/yyyy').format(startDate);
    final toStr = DateFormat('dd/MM/yyyy').format(endDate);
    
    final results = await MeterService.getMeterEvents(meterMNum, fromStr, toStr);
    
    if (mounted) {
      setState(() {
        _events = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundGrey,
        body: Column(
          children: [
            // --- Header matching the provided image ---
            _buildHeader(),

            // --- Date Picker Card ---
            _buildDateSelector(),

            // --- Results List ---
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.secondaryBlue))
                  : _events.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _events.length,
                          itemBuilder: (ctx, index) => _buildEventCard(_events[index]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 25),
      decoration: const BoxDecoration(
        color: AppTheme.secondaryBlue,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(35), bottomRight: Radius.circular(35)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
              Container(
                height: 70,
                width: 70,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset('lib/assets/images.jpg', fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            'عرض إيفينت العداد',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.secondaryBlue.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          _dateField('تاريخ البداية', startDate, (d) => setState(() => startDate = d)),
          const SizedBox(height: 15),
          _dateField('تاريخ النهاية', endDate, (d) => setState(() => endDate = d)),
          const SizedBox(height: 25),
          ElevatedButton(
            onPressed: _handleSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3498DB),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            child: const Text('إستعلام', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _dateField(String label, DateTime value, Function(DateTime) onPick) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: value,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) onPick(picked);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.secondaryBlue.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              DateFormat('dd/MM/yyyy').format(value),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(MeterEventItem event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.backgroundGrey, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.event_note_rounded, color: AppTheme.secondaryBlue, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.eventDesc,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 5),
                Text(
                  event.dateTime,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 15),
          const Text('لا يوجد أحداث مسجلة في هذه الفترة', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
