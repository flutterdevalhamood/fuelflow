import 'dart:io' show Platform;
import 'dart:io';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/customer_controller.dart';
import 'package:sample/src/providers/refilling_unit_controller.dart';
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
  RefillingUnitController? _refillingUnitController;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCustomerId;
  int? _selectedRefillingUnitId;
  bool _isLoading = false;
  bool _showWebView = false;
  late WebViewController _webViewController;
  String? _reportUrl;
  String _reportType = 'refill'; // 'refill', 'activity', or 'inventory'
  String? _selectedAction;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      WebViewPlatform.instance = AndroidWebViewPlatform();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeControllers();
    });

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
    _refillingUnitController = Provider.of<RefillingUnitController>(
      context,
      listen: false,
    );
    await _loadData();
  }

  Future<void> _loadData() async {
    await _customerController?.getCustomerData();
    await _refillingUnitController?.refillUnitsData;
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
        const SnackBar(content: Text('Please select both start and end dates')),
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

      switch (_reportType) {
        case 'activity':
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
          break;

        case 'inventory':
          // Fetch inventory report
          if (_selectedRefillingUnitId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select a refilling unit')),
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }

          success =
              await _reportsController?.postInventoryReportsData(
                fromDate,
                toDate,
                _selectedRefillingUnitId,
              ) ??
              false;

          if (success && _reportsController?.inventoryReportUrl != null) {
            _reportUrl = _reportsController!.inventoryReportUrl!;
          }
          break;

        case 'refill':
        default:
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
          break;
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
        ).showSnackBar(const SnackBar(content: Text('No Report Available')));
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
    final refillingUnitData = _refillingUnitController?.refillUnitsData;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getReportTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchReportData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          if (!_showWebView)
            _buildFilterSection(customerData, refillingUnitData),
          if (_showWebView)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _hideWebView,
                  ),
                  Text('Report', style: const TextStyle(fontSize: 18)),
                ],
              ),
            ),
          const Divider(height: 1),

          // Report Data Section
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _showWebView
                    ? _buildWebView()
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  String _getReportTitle() {
    switch (_reportType) {
      case 'activity':
        return 'Activity Report';
      case 'inventory':
        return 'Inventory Report';
      case 'refill':
      default:
        return 'Refill Report';
    }
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
    // Alternative WebView implementation if needed
    // return Stack(
    //   children: [
    //     WebViewWidget(controller: _webViewController),
    //     if (_isLoading) Center(child: CircularProgressIndicator()),
    //   ],
    // );
  }

  Widget _buildFilterSection(
    List<Map<String, dynamic>>? customerData,
    List<Map<String, dynamic>>? refillingUnitData,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Report',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Start Date', style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => _selectDate(context, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
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
                            const Icon(Icons.calendar_today, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('End Date', style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => _selectDate(context, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
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
                            const Icon(Icons.calendar_today, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildReportTypeSelector(),
          const SizedBox(height: 16),
          // Dynamic form based on report type
          if (_reportType == 'refill')
            _buildRefillReportForm(customerData)
          else if (_reportType == 'activity')
            _buildActivityReportForm()
          else if (_reportType == 'inventory')
            _buildInventoryReportForm(refillingUnitData),
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

  Widget _buildReportTypeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Refill Report'),
            selected: _reportType == 'refill',
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _reportType = 'refill';
                });
              }
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Activity Report'),
            selected: _reportType == 'activity',
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _reportType = 'activity';
                });
              }
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Inventory Report'),
            selected: _reportType == 'inventory',
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _reportType = 'inventory';
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRefillReportForm(List<Map<String, dynamic>>? customerData) {
    final List<Map<String, dynamic>> completeCustomerData = [
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
            searchFieldProps: const TextFieldProps(
              decoration: InputDecoration(hintText: 'Pick Customer'),
            ),
          ),
          items: (filter, infiniteScrollProps) => completeCustomerData,
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
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

  Widget _buildInventoryReportForm(
    List<Map<String, dynamic>>? refillingUnitData,
  ) {
    final List<Map<String, dynamic>> completeRefillingUnitData = [
      ...?refillingUnitData,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Refilling Unit', style: TextStyle(fontSize: 14)),
        const SizedBox(height: 4),
        DropdownSearch<Map<String, dynamic>>(
          popupProps: PopupProps.menu(
            showSearchBox: true,
            fit: FlexFit.tight,
            searchFieldProps: const TextFieldProps(
              decoration: InputDecoration(hintText: 'Pick Refilling Unit'),
            ),
          ),
          items: (filter, infiniteScrollProps) => completeRefillingUnitData,
          itemAsString: (item) => item['serial_no'] ?? '',
          compareFn:
              (item1, item2) =>
                  item1['id'].toString() == item2['id'].toString(),
          onChanged: (Map<String, dynamic>? newValue) async {
            if (newValue != null) {
              setState(() {
                _selectedRefillingUnitId = newValue['id'] as int;
              });
            }
          },
          selectedItem:
              _selectedRefillingUnitId != null
                  ? completeRefillingUnitData.firstWhere(
                    (unit) => unit['id'] == _selectedRefillingUnitId,
                    orElse: () => {'id': null, 'Name': 'Select Refilling Unit'},
                  )
                  : {'id': null, 'Name': 'Select Refilling Unit'},
          validator: (value) {
            if (value == null) {
              return 'Please select a Refilling Unit';
            }
            return null;
          },
        ),
      ],
    );
  }
}
