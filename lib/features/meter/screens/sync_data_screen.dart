import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smart_application/features/direct_current/services/direct_current_service.dart';
import 'package:smart_application/features/meter/models/sync_data_item.dart';
import 'package:smart_application/core/theme/app_theme.dart';
import 'package:smart_application/core/api_client.dart';

class SyncDataScreen extends StatefulWidget {
  const SyncDataScreen({super.key});

  @override
  State<SyncDataScreen> createState() => _SyncDataScreenState();
}

class _SyncDataScreenState extends State<SyncDataScreen> {
  List<SyncDataItem> _syncList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOfflineData();
  }

  Future<void> _loadOfflineData() async {
    setState(() => _isLoading = true);
    List<SyncDataItem> tempItems = [];

    try {
      // حركات الوصل
      final file1 = await _getFile('SyncData.txt');
      if (await file1.exists()) {
        String content = await file1.readAsString();
        if (content.isNotEmpty) {
          tempItems.add(_parseContent(content, "حركة وصل"));
        }
      }

      // حركات الفصل
      final file2 = await _getFile('SyncData2.txt');
      if (await file2.exists()) {
        String content = await file2.readAsString();
        if (content.isNotEmpty) {
          tempItems.add(_parseContent(content, "حركة فصل"));
        }
      }
    } catch (e) {
      debugPrint("Read File Error: $e");
    }

    setState(() {
      _syncList = tempItems;
      _isLoading = false;
    });
  }

  SyncDataItem _parseContent(String content, String type) {
    SyncDataItem item = SyncDataItem();
    item.type = type;
    item.state = "غير مرحلة";
    item.rawData = content;
    
    // استخراج البيانات من النص strMTR_NUM:...,intWorkshopID:...
    final parts = content.split(',');
    for (var part in parts) {
      if (part.contains("strMTR_NUM:")) item.meterNum = part.split(":")[1];
      if (part.contains("intWorkshopID:")) item.workshopId = part.split(":")[1];
      if (part.contains("strWorkshopName:")) item.workshopName = part.split(":")[1];
      if (part.contains("CityId:")) item.cityNum = part.split(":")[1];
      if (part.contains("CustId:")) item.subNum = part.split(":")[1];
    }
    return item;
  }

  Future<File> _getFile(String fileName) async {
    final directory = await getExternalStorageDirectory();
    // محاكاة مسار Downloads كما في الجافا
    String path = "/storage/emulated/0/Download/$fileName";
    return File(path);
  }

  Future<void> _syncItem(SyncDataItem item) async {
    setState(() => _isLoading = true);
    
    String encryptedData = ApiClient.encryptRSA(item.rawData);
    String result = "";
    
    if (item.type == "حركة وصل") {
      result = await DirectCurrentService.probeConnTrans(encryptedData);
    } else {
      result = await DirectCurrentService.probeDisConnTrans(encryptedData);
    }

    if (result == "تمت العملية بنجاح") {
      // حذف الملف
      final file = await _getFile(item.type == "حركة وصل" ? 'SyncData.txt' : 'SyncData2.txt');
      if (await file.exists()) await file.delete();
      
      _showMsg("تمت المزامنة بنجاح", AppTheme.accentGreen);
      _loadOfflineData();
    } else {
      _showMsg(result, AppTheme.accentRed);
      setState(() => _isLoading = false);
    }
  }

  void _showMsg(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, textAlign: TextAlign.right), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundGrey,
        appBar: AppBar(
          title: const Text('مزامنة الحركات'),
          backgroundColor: AppTheme.secondaryBlue,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppTheme.secondaryBlue))
          : _syncList.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: _syncList.length,
                itemBuilder: (ctx, index) => _buildSyncCard(_syncList[index]),
              ),
      ),
    );
  }

  Widget _buildSyncCard(SyncDataItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          _buildInfoRow('رقم البلدة', item.cityNum),
          _buildInfoRow('رقم الإشتراك', item.subNum),
          _buildInfoRow('رقم الورشة', item.workshopId),
          _buildInfoRow('إسم الورشة', item.workshopName),
          _buildInfoRow('نوع الحركة', item.type),
          _buildInfoRow('الحالة', item.state),
          
          Container(
            padding: const EdgeInsets.all(15),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _syncItem(item),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('مزامنة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          Container(
            width: 120,
            padding: const EdgeInsets.all(10),
            color: Colors.grey.shade100,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(value, style: const TextStyle(fontSize: 13, color: AppTheme.textDark)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('لا توجد حركات بحاجة لمزامنة', style: TextStyle(color: Colors.grey, fontSize: 16)),
    );
  }
}
