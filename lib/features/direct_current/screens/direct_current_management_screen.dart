import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'package:smart_application/features/direct_current/services/direct_current_service.dart';
import 'package:smart_application/features/direct_current/models/direct_current_item.dart';
import 'package:smart_application/core/theme/app_theme.dart';
import 'package:smart_application/features/direct_current/screens/direct_current_process_screen.dart';

class DirectCurrentManagementScreen extends StatefulWidget {
  final Map<String, String> meterInfo;

  const DirectCurrentManagementScreen({
    super.key,
    required this.meterInfo,
  });

  @override
  State<DirectCurrentManagementScreen> createState() =>
      _DirectCurrentManagementScreenState();
}

class _DirectCurrentManagementScreenState
    extends State<DirectCurrentManagementScreen> {
  // ============================================================
  // FILTERS
  // ============================================================

  bool checkAll = true;
  bool checkPending = false;
  bool checkApproved = false;
  bool checkExpired = false;

  // التاريخ موجود في الواجهة، لكن حاليًا لا ندخله في WHERE
  DateTime selectedDate = DateTime.now();

  // ============================================================
  // DATA
  // ============================================================

  List<DirectCurrentItem> _allRequests = [];
  List<DirectCurrentItem> _filteredRequests = [];

  bool _isLoadingData = false;

  // ============================================================
  // INSERT
  // ============================================================

  final TextEditingController _engineerController =
  TextEditingController();

  final TextEditingController _reasonController =
  TextEditingController();

  bool _isSending = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _fetchRequests();
  }

  // ============================================================
  // FETCH REQUESTS
  // ============================================================

  Future<void> _fetchRequests() async {
    if (_isLoadingData) return;

    setState(() {
      _isLoadingData = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // ----------------------------------------------------------
      // قراءة رقم الموظف الحقيقي من SharedPreferences
      // ----------------------------------------------------------

      final String empNo =
      (prefs.getString('EMP_NO') ?? '').trim();

      debugPrint('==============================================');
      debugPrint('>>> SHARED PREFERENCES');
      debugPrint('==============================================');

      debugPrint(
        '>>> username = [${prefs.getString('username') ?? ''}]',
      );

      debugPrint(
        '>>> ID = [${prefs.getString('ID') ?? ''}]',
      );

      debugPrint(
        '>>> EMP_NO = [$empNo]',
      );

      debugPrint(
        '>>> ORACLE_USER = [${prefs.getString('ORACLE_USER') ?? ''}]',
      );

      debugPrint('==============================================');

      // ----------------------------------------------------------
      // التأكد أن رقم الموظف موجود
      // ----------------------------------------------------------

      if (empNo.isEmpty) {
        debugPrint(
          '>>> ERROR: EMPLOYEE NUMBER IS EMPTY',
        );

        if (mounted) {
          setState(() {
            _isLoadingData = false;
          });

          _showSnackBar(
            'رقم الموظف غير موجود، يرجى تسجيل الدخول من جديد',
            AppTheme.accentRed,
          );
        }

        return;
      }

      debugPrint(
        '>>> EMPLOYEE NUMBER = [$empNo]',
      );

      // ----------------------------------------------------------
      // التاريخ للعرض فقط حاليًا
      // ----------------------------------------------------------

      final String formattedDate =
      DateFormat('dd/MM/yyyy').format(selectedDate);

      debugPrint(
        '>>> SELECTED DATE = $formattedDate',
      );

      // ==========================================================
      // مهم جدًا
      //
      // Java:
      //
      // String where = " and a.ENTRY_EMP_NO = " + empNo;
      //
      // وكان التاريخ يضاف فقط إذا كان CheckBox التاريخ مفعلاً.
      //
      // حاليًا نحن نجرب بدون التاريخ.
      // ==========================================================

      final String whereClause =
          ' and a.ENTRY_EMP_NO = $empNo';

      debugPrint('==============================================');
      debugPrint('>>> DIRECT CURRENT REQUEST');
      debugPrint('==============================================');

      debugPrint(
        '>>> EMPLOYEE NUMBER = [$empNo]',
      );

      debugPrint(
        '>>> SELECTED DATE = $formattedDate',
      );

      debugPrint(
        '>>> WHERE CLAUSE = [$whereClause]',
      );

      debugPrint('==============================================');

      // ----------------------------------------------------------
      // إرسال الطلب للسيرفر
      // ----------------------------------------------------------

      final List<DirectCurrentItem> results =
      await DirectCurrentService.getDirectCurrentList(
        whereClause,
      );

      // ----------------------------------------------------------
      // طباعة النتيجة
      // ----------------------------------------------------------

      debugPrint('==============================================');

      debugPrint(
        '>>> API RETURNED ${results.length} RECORDS',
      );

      debugPrint('==============================================');

      for (int i = 0; i < results.length; i++) {
        final item = results[i];

        debugPrint('>>> RECORD ${i + 1}');
        debugPrint('>>> ID = ${item.id}');
        debugPrint('>>> MTR_M_NUM = ${item.mtrMNum}');
        debugPrint('>>> ENG_NAME = ${item.engName}');
        debugPrint('>>> STATE = ${item.state}');
        debugPrint(
          '>>> ENG_APPROVED = ${item.engApproved}',
        );
      }

      // ----------------------------------------------------------
      // تحديث الشاشة
      // ----------------------------------------------------------

      if (!mounted) return;

      setState(() {
        _allRequests = results;
        _filteredRequests = results;
        _isLoadingData = false;
      });

      _applyFilters();
    } catch (e, stack) {
      debugPrint('==============================================');
      debugPrint('>>> FETCH REQUESTS ERROR');
      debugPrint('>>> $e');
      debugPrint('$stack');
      debugPrint('==============================================');

      if (!mounted) return;

      setState(() {
        _isLoadingData = false;
      });

      _showSnackBar(
        'حدث خطأ أثناء جلب البيانات',
        AppTheme.accentRed,
      );
    }
  }

  // ============================================================
  // FILTER DATA
  // ============================================================

  void _applyFilters() {
    final List<String> statesToFilter = [];

    if (!checkAll) {
      if (checkPending) {
        statesToFilter.add('1');
      }

      if (checkApproved) {
        statesToFilter.add('2');
      }

      if (checkExpired) {
        statesToFilter.add('3');
      }
    }

    final List<DirectCurrentItem> filtered =
    _allRequests.where((item) {
      // ----------------------------------------------------------
      // نفس منطق Java
      //
      // إذا ENG_APPROVED = 0
      // تصبح STATE = 3
      // ----------------------------------------------------------

      if (item.engApproved == '0') {
        item.state = '3';
        item.stateDesc = 'منتهية';
      } else {
        switch (item.state) {
          case '1':
            item.stateDesc = 'بانتظار إجراء المهندس';
            break;

          case '2':
            item.stateDesc = 'بانتظار إجراء المقدم';
            break;

          case '3':
            item.stateDesc = 'منتهية';
            break;

          default:
            item.stateDesc = 'غير معروف';
        }
      }

      if (checkAll) {
        return true;
      }

      return statesToFilter.contains(item.state);
    }).toList();

    setState(() {
      _filteredRequests = filtered;
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundGrey,

        body: Column(
          children: [
            _buildProfessionalHeader(),

            _buildSearchAndFilters(),

            Expanded(
              child: _isLoadingData
                  ? const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryBlue,
                ),
              )
                  : _filteredRequests.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  100,
                ),
                physics: const BouncingScrollPhysics(),
                itemCount: _filteredRequests.length,
                itemBuilder: (context, index) {
                  return _buildUltraModernCard(
                    _filteredRequests[index],
                  );
                },
              ),
            ),
          ],
        ),

        floatingActionButton: _buildFloatingActionBtn(),

        floatingActionButtonLocation:
        FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildProfessionalHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        60,
        20,
        25,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),

          Column(
            children: [
              Container(
                height: 65,
                width: 65,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                      Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      'lib/assets/images.jpg',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'إدارة حركات التأمين',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH + FILTERS
  // ============================================================

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius:
              BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color:
                  Colors.black.withValues(alpha: 0.03),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    child: Padding(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color:
                            AppTheme.secondaryBlue,
                            size: 20,
                          ),

                          const SizedBox(width: 12),

                          Text(
                            DateFormat('dd/MM/yyyy')
                                .format(selectedDate),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight:
                              FontWeight.w600,
                              color:
                              AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                IconButton(
                  onPressed: _fetchRequests,
                  icon: const Icon(
                    Icons.search_rounded,
                    color: AppTheme.primaryBlue,
                    size: 28,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor:
                    AppTheme.backgroundGrey,
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(15),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  'الكل',
                  checkAll,
                      (value) {
                    setState(() {
                      checkAll = true;
                      checkPending = false;
                      checkApproved = false;
                      checkExpired = false;
                    });

                    _applyFilters();
                  },
                ),

                const SizedBox(width: 8),

                _buildFilterChip(
                  'بانتظار الموافقة',
                  checkPending,
                      (value) {
                    setState(() {
                      checkAll = false;
                      checkPending = true;
                      checkApproved = false;
                      checkExpired = false;
                    });

                    _applyFilters();
                  },
                ),

                const SizedBox(width: 8),

                _buildFilterChip(
                  'تم الإجراء',
                  checkApproved,
                      (value) {
                    setState(() {
                      checkAll = false;
                      checkPending = false;
                      checkApproved = true;
                      checkExpired = false;
                    });

                    _applyFilters();
                  },
                ),

                const SizedBox(width: 8),

                _buildFilterChip(
                  'منتهية',
                  checkExpired,
                      (value) {
                    setState(() {
                      checkAll = false;
                      checkPending = false;
                      checkApproved = false;
                      checkExpired = true;
                    });

                    _applyFilters();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER CHIP
  // ============================================================

  Widget _buildFilterChip(
      String label,
      bool isSelected,
      Function(bool) onSelected,
      ) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: AppTheme.primaryBlue,
      backgroundColor: AppTheme.surfaceWhite,
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : AppTheme.textGrey,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
      padding:
      const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(15),
        side: BorderSide(
          color: isSelected
              ? AppTheme.primaryBlue
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      elevation: isSelected ? 4 : 0,
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _buildUltraModernCard(
      DirectCurrentItem item,
      ) {
    Color statusColor;
    String statusLabel;

    if (item.state == '1') {
      statusColor = AppTheme.accentOrange;
      statusLabel = 'بانتظار المهندس';
    } else if (item.state == '2') {
      statusColor = AppTheme.primaryBlue;
      statusLabel = 'بانتظار المقدم';
    } else if (item.state == '3') {
      statusColor = Colors.grey;
      statusLabel = 'منتهية';
    } else {
      statusColor = Colors.grey;
      statusLabel = 'غير معروف';
    }

    return Container(
      margin:
      const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius:
        BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    DirectCurrentProcessScreen(
                      data: item,
                    ),
              ),
            );
          },
          borderRadius:
          BorderRadius.circular(24),
          child: Padding(
            padding:
            const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.all(12),
                  decoration:
                  const BoxDecoration(
                    color:
                    AppTheme.backgroundGrey,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.electric_meter_rounded,
                    color:
                    AppTheme.primaryBlue,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        'عداد: ${item.mtrMNum}',
                        style:
                        const TextStyle(
                          fontWeight:
                          FontWeight.w900,
                          fontSize: 17,
                          color:
                          AppTheme.textDark,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'المهندس: ${item.engName}',
                        style:
                        const TextStyle(
                          color:
                          AppTheme.textGrey,
                          fontSize: 13,
                          fontWeight:
                          FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration:
                  BoxDecoration(
                    color: statusColor
                        .withValues(alpha: 0.1),
                    borderRadius:
                    BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight:
                      FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FLOATING BUTTON
  // ============================================================

  Widget _buildFloatingActionBtn() {
    return Container(
      width:
      MediaQuery.of(context).size.width * 0.9,
      height: 60,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color:
            AppTheme.primaryBlue
                .withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _showInsertDialog,
        icon: const Icon(
          Icons.add_rounded,
          size: 28,
        ),
        label: const Text(
          'إدخال حركة جديدة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        style:
        ElevatedButton.styleFrom(
          backgroundColor:
          AppTheme.primaryBlue,
          foregroundColor:
          Colors.white,
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // ============================================================
  // INSERT DIALOG
  // ============================================================

  void _showInsertDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
      Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            bottom:
            MediaQuery.of(ctx)
                .viewInsets
                .bottom,
          ),
          decoration:
          const BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.only(
              topLeft:
              Radius.circular(35),
              topRight:
              Radius.circular(35),
            ),
          ),
          child:
          SingleChildScrollView(
            padding:
            const EdgeInsets.all(30),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration:
                  BoxDecoration(
                    color:
                    AppTheme.backgroundGrey,
                    borderRadius:
                    BorderRadius.circular(
                        10),
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'إضافة طلب تأمين تيار',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight:
                    FontWeight.w900,
                    color:
                    AppTheme.primaryBlue,
                  ),
                ),

                const SizedBox(height: 30),

                _buildModernTextField(
                  'اسم المهندس المسؤول',
                  Icons.person_outline_rounded,
                  _engineerController,
                ),

                const SizedBox(height: 20),

                _buildModernTextField(
                  'سبب التأمين أو ملاحظات',
                  Icons.edit_note_rounded,
                  _reasonController,
                  maxLines: 3,
                ),

                const SizedBox(height: 35),

                ElevatedButton(
                  onPressed: _isSending
                      ? null
                      : () async {
                    setState(() {
                      _isSending = true;
                    });

                    await _handleFinalSubmit();

                    if (mounted) {
                      setState(() {
                        _isSending =
                        false;
                      });
                    }
                  },
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    AppTheme.secondaryBlue,
                    foregroundColor:
                    Colors.white,
                    minimumSize:
                    const Size(
                      double.infinity,
                      60,
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                          20),
                    ),
                    elevation: 5,
                  ),
                  child: _isSending
                      ? const CircularProgressIndicator(
                    color:
                    Colors.white,
                  )
                      : const Text(
                    'إرسال المعاملة الآن',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildModernTextField(
      String label,
      IconData icon,
      TextEditingController controller, {
        int maxLines = 1,
      }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration:
      InputDecoration(
        labelText: label,
        labelStyle:
        const TextStyle(
          color:
          AppTheme.textGrey,
          fontWeight:
          FontWeight.w500,
        ),
        prefixIcon:
        Icon(
          icon,
          color:
          AppTheme.secondaryBlue,
        ),
        filled: true,
        fillColor:
        AppTheme.backgroundGrey,
        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(18),
          borderSide:
          BorderSide.none,
        ),
        contentPadding:
        const EdgeInsets.all(20),
      ),
    );
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _selectDate() async {
    final DateTime? picked =
    await showDatePicker(
      context: context,
      initialDate:
      selectedDate,
      firstDate:
      DateTime(2020),
      lastDate:
      DateTime(2030),
      builder:
          (context, child) {
        return Theme(
          data: Theme.of(context)
              .copyWith(
            colorScheme:
            const ColorScheme.light(
              primary:
              AppTheme.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });

      /*
       * حاليًا الضغط على التاريخ يعيد تحميل البيانات
       * لكن _fetchRequests لا يستخدم التاريخ في WHERE.
       *
       * هذا متعمد للاختبار.
       */

      _fetchRequests();
    }
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),

          Icon(
            Icons.search_off_rounded,
            size: 80,
            color: AppTheme.textGrey
                .withValues(alpha: 0.2),
          ),

          const SizedBox(height: 16),

          const Text(
            'لا توجد نتائج',
            style: TextStyle(
              color:
              AppTheme.textGrey,
              fontSize: 16,
              fontWeight:
              FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'الموظف: ${_getEmployeeNumberForDisplay()}',
            style: const TextStyle(
              color:
              AppTheme.textGrey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _getEmployeeNumberForDisplay() {
    return '3040';
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnackBar(
      String msg,
      Color color,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          msg,
          textAlign:
          ui.TextAlign.right,
        ),
        backgroundColor: color,
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // FINAL SUBMIT
  // ============================================================

  Future<void> _handleFinalSubmit() async {
    try {
      final prefs =
      await SharedPreferences.getInstance();

      // ----------------------------------------------------------
      // رقم الموظف الحقيقي
      // ----------------------------------------------------------

      final String empNo =
      (prefs.getString('EMP_NO') ?? '').trim();

      if (empNo.isEmpty) {
        _showSnackBar(
          'رقم الموظف غير موجود',
          AppTheme.accentRed,
        );

        return;
      }

      debugPrint(
        '>>> INSERT EMP_NO = [$empNo]',
      );

      // ----------------------------------------------------------
      // تجهيز البيانات
      // ----------------------------------------------------------

      final Map<String, dynamic> params = {
        'ENTRY_EMP_NO': empNo,

        'CUSM_CITY':
        widget.meterInfo['MTR_CITY'] ?? '',

        'CUSM_NUM':
        widget.meterInfo['MTR_NUM'] ?? '',

        'CUSM_NAME':
        (widget.meterInfo['display_name'] ?? '')
            .replaceAll(
          'إسم المشترك: ',
          '',
        )
            .trim(),

        'MTR_M_NUM':
        widget.meterInfo['display_meter'] ?? '',

        'MTR_PHASE':
        (widget.meterInfo['display_faz'] ?? '')
            .replaceAll(
          'فاز',
          '',
        )
            .trim(),

        'MTR_IS_SMART':
        widget.meterInfo['display_smart'] ==
            'ذكي'
            ? 1
            : 0,

        'MTR_LOCATION':
        '0.0,0.0',

        'UNPAID_BILL_AMT':
        double.tryParse(
          (widget.meterInfo[
          'display_inv_amt'] ??
              '0')
              .replaceAll(
            RegExp(r'[^0-9.]'),
            '',
          ),
        )?.toInt() ??
            0,

        'REGION_DESC':
        (widget.meterInfo[
        'display_area'] ??
            '')
            .replaceAll(
          'رقم المنطقة:',
          '',
        )
            .trim(),

        'READER_MOBILE':
        (widget.meterInfo[
        'display_mobile'] ??
            '')
            .replaceAll(
          'هاتف القارئ:',
          '',
        )
            .trim(),

        'ENG_WRKSHP_NO':
        '1',

        'ENG_NAME':
        _engineerController.text.trim(),

        'EMP_NOTES':
        _reasonController.text.trim(),
      };

      debugPrint(
        '>>> INSERT PARAMS = $params',
      );

      // ----------------------------------------------------------
      // إرسال
      // ----------------------------------------------------------

      final int resultCode =
      await DirectCurrentService
          .insertDirectCurrent(
        params,
      );

      debugPrint(
        '>>> INSERT RESULT = $resultCode',
      );

      if (!mounted) return;

      if (resultCode == -2) {
        _showSnackBar(
          'معاملة مكررة لهذا اليوم',
          AppTheme.accentOrange,
        );
      } else if (resultCode > 0) {
        _showSnackBar(
          'تم الإرسال بنجاح',
          AppTheme.accentGreen,
        );

        Navigator.pop(context);

        _fetchRequests();
      } else {
        _showSnackBar(
          'فشل الإرسال',
          AppTheme.accentRed,
        );
      }
    } catch (e) {
      debugPrint(
        '>>> FINAL SUBMIT ERROR: $e',
      );

      _showSnackBar(
        'حدث خطأ: $e',
        AppTheme.accentRed,
      );
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _engineerController.dispose();
    _reasonController.dispose();

    super.dispose();
  }
}