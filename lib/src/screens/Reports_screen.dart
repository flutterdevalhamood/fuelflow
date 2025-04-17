import 'dart:io' show Platform;
import 'dart:io';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/customer_controller.dart';
import 'package:sample/src/providers/reports_controller.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportsController? _reportsController;
  CustomerController? _customerController;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCustomerId;
  bool _isLoading = false;
  bool _showWebView = false;
  late WebViewController _webViewController;
  String? _reportUrl;
  bool _isActivityReport = false;
  String? _selectedAction;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      WebViewPlatform.instance = AndroidWebViewPlatform();
    }
    _initializeControllers();
    _initWebViewController();
  }

  void _initWebViewController() {
    _webViewController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.transparent)
          ..enableZoom(true)
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (int progress) {
                setState(() {
                  _isLoading = progress < 100;
                });
              },
              onPageStarted: (String url) {
                setState(() {
                  _isLoading = true;
                });
              },
              onPageFinished: (String url) {
                setState(() {
                  _isLoading = false;
                });
              },
              onWebResourceError: (WebResourceError error) {
                setState(() {
                  _isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to load page: ${error.description}'),
                  ),
                );
              },
            ),
          )
          ..loadRequest(Uri.parse('about:blank'));
  }

  Future<void> _initializeControllers() async {
    _reportsController = Provider.of<ReportsController>(context, listen: false);
    _customerController = Provider.of<CustomerController>(
      context,
      listen: false,
    );
    await _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    await _customerController?.getCustomerData();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          isStartDate
              ? (_startDate ?? DateTime.now())
              : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _fetchReportData() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select both start and end dates')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _showWebView = false;
    });

    try {
      final fromDate = DateFormat('yyyy-MM-dd').format(_startDate!);
      final toDate = DateFormat('yyyy-MM-dd').format(_endDate!);
      bool success = false;

      if (_isActivityReport) {
        // Fetch activity report
        success =
            await _reportsController?.postActivityReportsData(
              fromDate,
              toDate,
              _selectedAction == 'all' ? 'all' : _selectedAction,
            ) ??
            false;

        if (success && _reportsController?.activityReportUrl != null) {
          _reportUrl = _reportsController!.activityReportUrl!;
        }
      } else {
        // Fetch refill report
        final customerId =
            _selectedCustomerId == 'all'
                ? 'all'
                : _selectedCustomerId != null
                ? int.tryParse(_selectedCustomerId!)
                : null;

        success =
            await _reportsController?.postReportsData(
              fromDate,
              toDate,
              customerId.toString(),
            ) ??
            false;

        if (success && _reportsController?.reportUrl != null) {
          _reportUrl = _reportsController!.reportUrl!;
        }
      }

      if (success && _reportUrl != null) {
        setState(() {
          _showWebView = true;
        });
        // Load the URL with error handling
        try {
          await _webViewController.loadRequest(
            Uri.parse(_reportUrl!),
            headers: {'Referer': _reportUrl!},
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading report: ${e.toString()}')),
          );
          setState(() {
            _showWebView = false;
          });
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No Report Available')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating report: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _hideWebView() {
    setState(() {
      _showWebView = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final customerData = _customerController?.customerData;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isActivityReport ? 'Activity Report' : 'Refill Report'),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _fetchReportData),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          if (!_showWebView) _buildFilterSection(customerData),
          if (_showWebView)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: _hideWebView,
                  ),
                  Text('Report', style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
          Divider(height: 1),

          // Report Data Section
          Expanded(
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _showWebView
                    ? _buildWebView()
                    : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildWebView() {
    return SfPdfViewer.network(
      _reportUrl!,
      canShowPaginationDialog: true,
      onDocumentLoadFailed: (details) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load PDF: ${details.description}')),
        );
      },
    );
    // return Stack(
    //   children: [
    //     WebViewWidget(controller: _webViewController),
    //     if (_isLoading) Center(child: CircularProgressIndicator()),
    //   ],
    // );
  }

  Widget _buildFilterSection(List<Map<String, dynamic>>? customerData) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Report',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Start Date', style: TextStyle(fontSize: 14)),
                    SizedBox(height: 4),
                    InkWell(
                      onTap: () => _selectDate(context, true),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _startDate != null
                                  ? DateFormat(
                                    'dd MMM yyyy',
                                  ).format(_startDate!)
                                  : '',
                            ),
                            Icon(Icons.calendar_today, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('End Date', style: TextStyle(fontSize: 14)),
                    SizedBox(height: 4),
                    InkWell(
                      onTap: () => _selectDate(context, false),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _endDate != null
                                  ? DateFormat('dd MMM yyyy').format(_endDate!)
                                  : '',
                            ),
                            Icon(Icons.calendar_today, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Refill Report'),
                  selected: !_isActivityReport,
                  onSelected: (selected) {
                    setState(() {
                      _isActivityReport = !selected;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Activity Report'),
                  selected: _isActivityReport,
                  onSelected: (selected) {
                    setState(() {
                      _isActivityReport = selected;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Dynamic form based on report type
          _isActivityReport
              ? _buildActivityReportForm()
              : _buildRefillReportForm(customerData),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _fetchReportData,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Generate Report'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefillReportForm(List<Map<String, dynamic>>? customerData) {
    final List<Map<String, dynamic>> completeCustomerData = [
      {'id': 'null', 'Name': 'Select Customer'},
      {'id': 'all', 'Name': 'All Customers'},
      ...?customerData,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Customer', style: TextStyle(fontSize: 14)),
        const SizedBox(height: 4),
        DropdownSearch<Map<String, dynamic>>(
          popupProps: PopupProps.menu(
            showSearchBox: true,
            fit: FlexFit.tight,
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(hintText: 'Pick Customer'),
            ),
          ),
          items: (filter, infiniteScrollProps) => completeCustomerData ?? [],
          itemAsString: (item) => item['Name'] ?? '',
          compareFn:
              (item1, item2) =>
                  item1['id'].toString() == item2['id'].toString(),
          onChanged: (Map<String, dynamic>? newValue) async {
            if (newValue != null) {
              setState(() {
                _selectedCustomerId = newValue['id'].toString();
              });
            }
          },
          selectedItem:
              _selectedCustomerId != null
                  ? completeCustomerData.firstWhere(
                    (customer) =>
                        customer['id'].toString() == _selectedCustomerId,
                    orElse: () => {'id': null, 'Name': 'Select Customer'},
                  )
                  : {'id': null, 'Name': 'Select Customer'},
          validator: (value) {
            if (value == null) {
              return 'Please select a Customer Name';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildActivityReportForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Action Type', style: TextStyle(fontSize: 14)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: _selectedAction,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          items: const [
            DropdownMenuItem<String>(value: null, child: Text('Select Action')),
            DropdownMenuItem<String>(value: 'all', child: Text('All')),
            DropdownMenuItem<String>(value: 'update', child: Text('Update')),
            DropdownMenuItem<String>(value: 'delete', child: Text('Delete')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedAction = value;
            });
          },
          hint: const Text('Select Activity'),
        ),
      ],
    );
  }
}
