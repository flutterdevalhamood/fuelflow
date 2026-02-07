import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/customer_site_controller.dart';

class CustomerSiteListScreen extends StatefulWidget {
  const CustomerSiteListScreen({Key? key}) : super(key: key);

  @override
  State<CustomerSiteListScreen> createState() => _CustomerSitesScreenState();
}

class _CustomerSitesScreenState extends State<CustomerSiteListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredSites = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerSiteController>().getCustomerSiteData();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      context.read<CustomerSiteController>().loadMore();
    }
  }

  void _filterSites(List<Map<String, dynamic>>? sites) {
    if (sites == null) {
      _filteredSites = [];
      return;
    }

    if (_searchQuery.isEmpty) {
      _filteredSites = sites;
    } else {
      _filteredSites =
          sites.where((site) {
            final siteName = (site['name'] ?? '').toString().toLowerCase();
            final customerName =
                (site['customer']?['Name'] ?? '').toString().toLowerCase();
            final query = _searchQuery.toLowerCase();
            return siteName.contains(query) || customerName.contains(query);
          }).toList();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Sites')),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: Consumer<CustomerSiteController>(
              builder: (context, controller, child) {
                _filterSites(controller.customerSiteData);

                if (controller.isLoading && controller.currentPage == 1) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_filteredSites.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh:
                      () => controller.getCustomerSiteData(loadMore: false),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        _filteredSites.length + (controller.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _filteredSites.length) {
                        return _buildLoadingIndicator();
                      }

                      final site = _filteredSites[index];
                      return _buildSiteCard(site, controller);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Site'),
        backgroundColor: Colors.blue.shade700,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by site or customer name...',
          hintStyle: TextStyle(color: Colors.grey.shade600),
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                  )
                  : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No customer sites found'
                : 'No results for "$_searchQuery"',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Add your first customer site'
                : 'Try a different search term',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildSiteCard(
    Map<String, dynamic> site,
    CustomerSiteController controller,
  ) {
    final customer = site['customer'] as Map<String, dynamic>?;
    final siteName = site['name'] ?? 'Unnamed Site';
    final customerName = customer?['Name'] ?? 'N/A';
    final customerMobile = customer?['Mobile'] ?? 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          siteName.toString(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showAddEditDialog(context, site: site);
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(context, site);
                      }
                    },
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildInfoRow(Icons.business, 'Customer', customerName),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.phone, 'Mobile', customerMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  void _showAddEditDialog(BuildContext context, {Map<String, dynamic>? site}) {
    final isEdit = site != null;
    final nameController = TextEditingController(text: site?['name']);
    final descriptionController = TextEditingController(
      text: site?['description'],
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(isEdit ? 'Edit Customer Site' : 'Add Customer Site'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Site Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter site name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),
                    if (isEdit) ...[
                      const SizedBox(height: 16),
                      // Display current customer info (read-only in edit mode)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.business, color: Colors.grey.shade600),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Customer',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    site['customer']?['Name'] ?? 'N/A',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(dialogContext);

                    final controller = context.read<CustomerSiteController>();
                    bool success;

                    if (isEdit) {
                      // Extract customer_id properly
                      int? customerId;
                      if (site['customer_id'] != null) {
                        customerId = int.tryParse(
                          site['customer_id'].toString(),
                        );
                      }

                      // Extract site id
                      int? siteId;
                      if (site['id'] != null) {
                        siteId = int.tryParse(site['id'].toString());
                      }

                      success = await controller.updateCustomerSites(
                        customerId,
                        nameController.text.trim(),
                        descriptionController.text.trim(),
                        siteId,
                      );
                    } else {
                      // For add, extract customerId from site data or use current user's customer
                      int? customerId;
                      if (controller.customerSiteData != null &&
                          controller.customerSiteData!.isNotEmpty) {
                        final firstSite = controller.customerSiteData!.first;
                        if (firstSite['customer_id'] != null) {
                          customerId = int.tryParse(
                            firstSite['customer_id'].toString(),
                          );
                        }
                      }

                      success = await controller.registerCustomerSites(
                        customerId,
                        nameController.text.trim(),
                        descriptionController.text.trim(),
                      );
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? isEdit
                                    ? 'Site updated successfully'
                                    : 'Site added successfully'
                                : 'Operation failed. Please try again.',
                          ),
                          backgroundColor: success ? Colors.green : Colors.red,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                },
                child: Text(isEdit ? 'Update' : 'Add'),
              ),
            ],
          ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Map<String, dynamic> site,
  ) {
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Delete Customer Site'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Are you sure you want to delete "${site['name']}"?'),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Reason for deletion',
                    border: OutlineInputBorder(),
                    hintText: 'Enter reason...',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  Navigator.pop(dialogContext);

                  // Extract site id properly
                  int? siteId;
                  if (site['id'] != null) {
                    siteId = int.tryParse(site['id'].toString());
                  }

                  await context
                      .read<CustomerSiteController>()
                      .deleteCustomerSites(
                        siteId,
                        descriptionController.text.trim(),
                      );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Site deleted successfully'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}
