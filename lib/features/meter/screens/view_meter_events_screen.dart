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
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppTheme.primaryBlue, AppTheme.secondaryBlue],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
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
              // Circular Logo - Matching HomeScreen
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
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
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 25,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          _dateField('تاريخ البداية', startDate, Icons.calendar_today_rounded, (d) => setState(() => startDate = d)),
          const SizedBox(height: 16),
          _dateField('تاريخ النهاية', endDate, Icons.event_available_rounded, (d) => setState(() => endDate = d)),
          const SizedBox(height: 25),
          ElevatedButton(
            onPressed: _handleSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              shadowColor: AppTheme.primaryBlue.withOpacity(0.3),
            ),
            child: const Text(
              'إستعلام عن الأحداث',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateField(String label, DateTime value, IconData icon, Function(DateTime) onPick) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textGrey, fontSize: 13),
          ),
        ),
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
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundGrey.withOpacity(0.8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.secondaryBlue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(value),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textDark),
                  ),
                ),
                const SizedBox(width: 32), // Spacer to balance icon
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(MeterEventItem event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.secondaryBlue.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_note_rounded, color: AppTheme.secondaryBlue, size: 26),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.eventDesc,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.textGrey),
                    const SizedBox(width: 6),
                    Text(
                      event.dateTime,
                      style: const TextStyle(color: AppTheme.textGrey, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
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
