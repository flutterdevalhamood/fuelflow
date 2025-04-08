import 'package:flutter/material.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Reports')));
  }
}

// // import 'package:flutter/material.dart';
// // import 'package:flutter_riverpod/flutter_riverpod.dart';
// //
// // class ReportsScreen extends ConsumerStatefulWidget {
// //   const ReportsScreen({super.key});
// //
// //   @override
// //   ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
// // }
// //
// // class _ReportsScreenState extends ConsumerState<ReportsScreen> {
// //   int _maxPriorityValue = 0;
// //   int? selectedMonth;
// //
// //   final List<String> timeRangeOptions = [
// //     'Today',
// //     'Yesterday',
// //     'Last 7 days',
// //     'Last 30 days',
// //     'This month',
// //     'Last month',
// //     'This year',
// //     'Lifetime',
// //     'Custom date',
// //   ];
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final textStyle = Theme.of(context).textTheme;
// //
// //     return Scaffold(
// //       appBar: AppBar(
// //         automaticallyImplyLeading: false, // Remove the back button
// //         title: Text(
// //           'Ticket',
// //           style: textStyle.titleLarge!.copyWith(
// //             fontSize: 20,
// //             fontWeight: FontWeight.w700,
// //             color: Colors.red,
// //           ),
// //         ),
// //       ),
// //       body: SingleChildScrollView(
// //         child: Column(
// //           children: [_filterOptions(textStyle), const SizedBox(height: 60)],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _filterOptions(TextTheme textStyle) {
// //     // final userFilterResponse = ref.watch<ReportsNotifier>(reportsProvider);
// //     return Row(
// //       mainAxisAlignment: MainAxisAlignment.end,
// //       children: [
// //         _filterWidgets(textStyle, title: 'User ', onTap: () {}),
// //         SizedBox(width: 13),
// //         DropdownButton<String>(
// //           value: null,
// //           hint: Text('Monthly', style: textStyle.bodySmall),
// //           items:
// //               timeRangeOptions.map<DropdownMenuItem<String>>((String value) {
// //                 return DropdownMenuItem<String>(
// //                   value: value,
// //                   child: Text(value, style: textStyle.bodySmall),
// //                 );
// //               }).toList(),
// //           onChanged: (String? newValue) {
// //             // userFilterResponse.setFilter = newValue;
// //           },
// //         ),
// //         // _filterWidgets(textStyle, title: 'Monthly'),
// //         SizedBox(width: 20),
// //       ],
// //     );
// //   }
// //
// //   Widget _filterWidgets(
// //     TextTheme textStyle, {
// //     required String title,
// //     void Function()? onTap,
// //   }) {
// //     return GestureDetector(
// //       onTap: onTap,
// //       child: Container(
// //         padding: EdgeInsets.fromLTRB(10, 6, 3, 6),
// //         decoration: BoxDecoration(
// //           border: Border.all(color: Colors.grey),
// //           borderRadius: BorderRadius.circular(4),
// //         ),
// //         child: Row(
// //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //           children: [
// //             Text(
// //               title,
// //               style: textStyle.bodySmall!.copyWith(color: Colors.black),
// //             ),
// //             const Icon(
// //               Icons.keyboard_arrow_down_rounded,
// //               color: Colors.grey,
// //               size: 20,
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
//
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
//
// class ReportsScreen extends StatefulWidget {
//   @override
//   _ReportsScreenState createState() => _ReportsScreenState();
// }
//
// class _ReportsScreenState extends State<ReportsScreen> {
//   DateTime? _startDate;
//   DateTime? _endDate;
//   String? _selectedCustomer;
//   bool _isLoading = false;
//   List<Map<String, dynamic>> _reportData = [];
//   List<String> _customers = [
//     'All Customers',
//     'Customer A',
//     'Customer B',
//     'Customer C',
//   ]; // Mock data
//
//   Future<void> _selectDate(BuildContext context, bool isStartDate) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate:
//           isStartDate
//               ? (_startDate ?? DateTime.now())
//               : (_endDate ?? DateTime.now()),
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2101),
//     );
//     if (picked != null) {
//       setState(() {
//         if (isStartDate) {
//           _startDate = picked;
//           if (_endDate != null && _endDate!.isBefore(_startDate!)) {
//             _endDate = null;
//           }
//         } else {
//           _endDate = picked;
//         }
//       });
//     }
//   }
//
//   Future<void> _fetchReportData() async {
//     if (_startDate == null || _endDate == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Please select both start and end dates')),
//       );
//       return;
//     }
//
//     setState(() => _isLoading = true);
//
//     // Simulate API call
//     await Future.delayed(Duration(seconds: 2));
//
//     // Mock data - replace with actual API call
//     setState(() {
//       _reportData = List.generate(
//         15,
//         (index) => {
//           'id': index + 1,
//           'date': DateFormat(
//             'yyyy-MM-dd',
//           ).format(_startDate!.add(Duration(days: index))),
//           'customer':
//               _selectedCustomer ?? 'Customer ${['A', 'B', 'C'][index % 3]}',
//           'amount': (1000 + index * 150).toDouble(),
//           'status': ['Completed', 'Pending', 'Cancelled'][index % 3],
//         },
//       );
//       _isLoading = false;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Sales Report'),
//         actions: [
//           IconButton(icon: Icon(Icons.refresh), onPressed: _fetchReportData),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Filter Section
//           _buildFilterSection(),
//           Divider(height: 1),
//
//           // Report Data Section
//           Expanded(
//             child:
//                 _isLoading
//                     ? Center(child: CircularProgressIndicator())
//                     : _reportData.isEmpty
//                     ? Center(
//                       child: Text(
//                         'No data available. Apply filters and load data.',
//                       ),
//                     )
//                     : _buildReportTable(),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildFilterSection() {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Filter Report',
//             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//           ),
//           SizedBox(height: 16),
//           Row(
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Start Date', style: TextStyle(fontSize: 14)),
//                     SizedBox(height: 4),
//                     InkWell(
//                       onTap: () => _selectDate(context, true),
//                       child: Container(
//                         padding: EdgeInsets.symmetric(
//                           vertical: 12,
//                           horizontal: 16,
//                         ),
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey),
//                           borderRadius: BorderRadius.circular(4),
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               _startDate != null
//                                   ? DateFormat(
//                                     'dd MMM yyyy',
//                                   ).format(_startDate!)
//                                   : 'Select start date',
//                             ),
//                             Icon(Icons.calendar_today, size: 20),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('End Date', style: TextStyle(fontSize: 14)),
//                     SizedBox(height: 4),
//                     InkWell(
//                       onTap: () => _selectDate(context, false),
//                       child: Container(
//                         padding: EdgeInsets.symmetric(
//                           vertical: 12,
//                           horizontal: 16,
//                         ),
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey),
//                           borderRadius: BorderRadius.circular(4),
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               _endDate != null
//                                   ? DateFormat('dd MMM yyyy').format(_endDate!)
//                                   : 'Select end date',
//                             ),
//                             Icon(Icons.calendar_today, size: 20),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 16),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text('Customer', style: TextStyle(fontSize: 14)),
//               SizedBox(height: 4),
//               DropdownButtonFormField<String>(
//                 value: _selectedCustomer,
//                 decoration: InputDecoration(
//                   border: OutlineInputBorder(),
//                   contentPadding: EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 8,
//                   ),
//                 ),
//                 items:
//                     _customers.map((customer) {
//                       return DropdownMenuItem<String>(
//                         value: customer == 'All Customers' ? null : customer,
//                         child: Text(customer),
//                       );
//                     }).toList(),
//                 onChanged: (value) {
//                   setState(() {
//                     _selectedCustomer = value;
//                   });
//                 },
//                 hint: Text('All Customers'),
//               ),
//             ],
//           ),
//           SizedBox(height: 16),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: _fetchReportData,
//               child: Text('Generate Report'),
//               style: ElevatedButton.styleFrom(
//                 padding: EdgeInsets.symmetric(vertical: 16),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildReportTable() {
//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       child: SingleChildScrollView(
//         child: DataTable(
//           columns: [
//             DataColumn(label: Text('ID')),
//             DataColumn(label: Text('Date')),
//             DataColumn(label: Text('Customer')),
//             DataColumn(label: Text('Amount'), numeric: true),
//             DataColumn(label: Text('Status')),
//           ],
//           rows:
//               _reportData.map((data) {
//                 return DataRow(
//                   cells: [
//                     DataCell(Text(data['id'].toString())),
//                     DataCell(Text(data['date'])),
//                     DataCell(Text(data['customer'])),
//                     DataCell(Text('\$${data['amount'].toStringAsFixed(2)}')),
//                     DataCell(
//                       Chip(
//                         label: Text(data['status']),
//                         backgroundColor: _getStatusColor(data['status']),
//                         labelStyle: TextStyle(color: Colors.white),
//                       ),
//                     ),
//                   ],
//                 );
//               }).toList(),
//         ),
//       ),
//     );
//   }
//
//   Color _getStatusColor(String status) {
//     switch (status) {
//       case 'Completed':
//         return Colors.green;
//       case 'Pending':
//         return Colors.orange;
//       case 'Cancelled':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }
// }
