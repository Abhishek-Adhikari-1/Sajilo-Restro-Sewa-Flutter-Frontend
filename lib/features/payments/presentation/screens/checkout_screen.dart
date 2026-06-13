import 'package:sajilo_restro_sewa/core/errors/app_error_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../../core/network/api_client.dart';
import '../cubit/payment_cubit.dart';
import '../cubit/payment_state.dart';
import '../../data/models/payment_model.dart';
import 'receipt_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final OrderModel order;

  const CheckoutScreen({super.key, required this.order});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _discountController = TextEditingController(text: '0');
  final _taxController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  bool _isCustomerSet = false;
  String _paymentMethod = 'cash'; // cash, card, mobile_wallet
  String _discountType = 'fixed';
  String _taxType = 'percentage';
  Map<String, dynamic>? _foundCustomerDetails;
  bool _isSearchingCustomer = false;

  final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    _discountController.dispose();
    _taxController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _lookupCustomer() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isCustomerSet = true);
    }
  }

  Future<void> _searchCustomerByPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() {
      _isSearchingCustomer = true;
      _foundCustomerDetails = null;
    });

    try {
      final response = await ApiClient().get('/customers/search?phone=$phone');
      if (response != null && response['data'] != null) {
        setState(() {
          _foundCustomerDetails = response['data'];
          _nameController.text = _foundCustomerDetails!['name'] ?? '';
        });
      } else {
        if (!mounted) return;
        AppErrorHandler.show(context, 'No customer found');
      }
    } catch (e) {
      if (!mounted) return;
      AppErrorHandler.show(context, 'No customer found');
    } finally {
      if (mounted) setState(() => _isSearchingCustomer = false);
    }
  }

  void _processPayment() {
    final discountValue = double.tryParse(_discountController.text) ?? 0.0;
    final taxValue = double.tryParse(_taxController.text) ?? 0.0;
    final subtotal = widget.order.totalAmount;

    if (discountValue < 0 || taxValue < 0) {
      AppErrorHandler.show(context, 'Values cannot be negative');
      return;
    }

    if (_discountType == 'percentage' && discountValue > 100) {
      AppErrorHandler.show(context, 'Discount percentage cannot exceed 100%');
      return;
    }

    if (_discountType == 'fixed' && discountValue > subtotal) {
      AppErrorHandler.show(context, 'Fixed discount cannot exceed the subtotal');
      return;
    }

    if (_taxType == 'percentage' && taxValue > 100) {
      AppErrorHandler.show(context, 'Tax percentage cannot exceed 100%');
      return;
    }

    if (_calculateTotal() < 0) {
      AppErrorHandler.show(context, 'Total amount cannot be negative');
      return;
    }

    final request = PaymentRequestModel(
      orderId: widget.order.id,
      method: _paymentMethod,
      customerName: _nameController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      discountType: _discountType,
      discountValue: discountValue,
      taxType: _taxType,
      taxValue: taxValue,
      notes: _notesController.text.trim(),
    );

    context.read<PaymentCubit>().checkout(request);
  }

  double _calculateDiscount() {
    final val = double.tryParse(_discountController.text) ?? 0.0;
    if (_discountType == 'fixed') return val;
    return widget.order.totalAmount * (val / 100);
  }

  double _calculateTax() {
    final subtotalAfterDiscount = widget.order.totalAmount - _calculateDiscount();
    final val = double.tryParse(_taxController.text) ?? 0.0;
    if (_taxType == 'fixed') return val;
    return subtotalAfterDiscount * (val / 100);
  }

  double _calculateTotal() {
    return widget.order.totalAmount - _calculateDiscount() + _calculateTax();
  }

  String? _getDiscountError() {
    if (_discountController.text.isEmpty) return null;
    final val = double.tryParse(_discountController.text);
    if (val == null) return 'Invalid';
    if (val < 0) return 'Cannot be negative';
    if (_discountType == 'percentage' && val > 100) return 'Max 100%';
    if (_discountType == 'fixed' && val > widget.order.totalAmount) return 'Exceeds subtotal';
    return null;
  }

  String? _getTaxError() {
    if (_taxController.text.isEmpty) return null;
    final val = double.tryParse(_taxController.text);
    if (val == null) return 'Invalid';
    if (val < 0) return 'Cannot be negative';
    if (_taxType == 'percentage' && val > 100) return 'Max 100%';
    return null;
  }

  bool _hasErrors() {
    return _getDiscountError() != null || _getTaxError() != null || _calculateTotal() < 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 800;
    final tableNumberStr = (widget.order.tableNumber ?? widget.order.tableId).toString();
    final shortTableNumber = tableNumberStr.length > 4 ? tableNumberStr.substring(0, 4) : tableNumberStr;

    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout - Table $shortTableNumber'),
      ),
      body: BlocListener<PaymentCubit, PaymentState>(
        listener: (context, state) {
          if (state is PaymentError) {
            AppErrorHandler.showError(context, state.message);
          } else if (state is PaymentSuccess) {
            AppErrorHandler.showSuccess(context, 'Payment processed successfully!');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ReceiptScreen(
                  customerName: _nameController.text.isNotEmpty ? _nameController.text : "Anonymous",
                  customerPhone: _phoneController.text.isNotEmpty ? _phoneController.text : "N/A",
                  order: widget.order,
                  subtotal: widget.order.totalAmount,
                  discountValue: double.tryParse(_discountController.text) ?? 0.0,
                  discountType: _discountType,
                  taxValue: double.tryParse(_taxController.text) ?? 0.0,
                  taxType: _taxType,
                  total: _calculateTotal(),
                  method: _paymentMethod,
                ),
              ),
            );
          }
        },
        child: isMobile
            ? LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildCustomerSection(theme, isMobile),
                              const SizedBox(height: 16),
                              Expanded(child: _buildOrderSummarySection(theme)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _buildCustomerSection(theme, isMobile),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    flex: 1,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                            child: IntrinsicHeight(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: _buildOrderSummarySection(theme),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildRadio(String title, String value) {
    return InkWell(
      onTap: () => setState(() => _paymentMethod = value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ignore: deprecated_member_use
            Radio<String>(
              visualDensity: VisualDensity.compact,
              value: value,
              // ignore: deprecated_member_use
              groupValue: _paymentMethod,
              // ignore: deprecated_member_use
              onChanged: (val) => setState(() => _paymentMethod = val!),
            ),
            Text(value == 'mobile_wallet' ? 'Wallet' : title),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSection(ThemeData theme, bool isMobile) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer Details (Optional)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (!_isCustomerSet)
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _phoneController,
                      focusNode: _phoneFocusNode,
                      autofocus: !isMobile,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: const Icon(Icons.phone),
                        suffixIcon: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _phoneController,
                          builder: (context, value, child) {
                            if (value.text.isEmpty) return const SizedBox.shrink();
                            return _isSearchingCustomer
                                ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                                : Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: IconButton(icon: const Icon(Icons.search), onPressed: _searchCustomerByPhone),
                                  );
                          },
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.search,
                      onFieldSubmitted: (_) {
                        _searchCustomerByPhone();
                        _phoneFocusNode.requestFocus();
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                        onPressed: _lookupCustomer,
                        child: const Text('Set Customer Details'),
                      ),
                    ),
                    if (_foundCustomerDetails != null) ...[
                      const SizedBox(height: 16),
                      Card(
                        color: theme.colorScheme.surfaceContainerHighest,
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                child: Icon(Icons.person, color: theme.colorScheme.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_foundCustomerDetails!['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(_foundCustomerDetails!['phone'] ?? '-', style: theme.textTheme.bodySmall),
                                    if (_foundCustomerDetails!['created_at'] != null)
                                      Text('Since: ${DateFormat.yMMMd().format(DateTime.parse(_foundCustomerDetails!['created_at']).toLocal())}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.check, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_nameController.text.isNotEmpty ? _nameController.text : "Anonymous", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Text(_phoneController.text.isNotEmpty ? _phoneController.text : "N/A", style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _isCustomerSet = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummarySection(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bill Summary', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // Items table
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
              },
              children: [
                const TableRow(
                  children: [
                    Text('Item', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Subtotal', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const TableRow(children: [SizedBox(height: 8), SizedBox(height: 8), SizedBox(height: 8)]),
                ...widget.order.items.map((item) {
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(item.name),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text('${item.quantity}', textAlign: TextAlign.center),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(currencyFormat.format(item.price * item.quantity), textAlign: TextAlign.right),
                      ),
                    ],
                  );
                }),
              ],
            ),
            const Divider(height: 32),
            // Subtotal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:'),
                Text(currencyFormat.format(widget.order.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            // Discount
            Row(
              children: [
                const Expanded(flex: 1, child: Text('Discount:')),
                Expanded(
                  flex: 1,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'fixed', label: Text('Rs')),
                        ButtonSegment(value: 'percentage', label: Text('%')),
                      ],
                      selected: {_discountType},
                      onSelectionChanged: (val) {
                        setState(() => _discountType = val.first);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _discountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      isDense: true, 
                      border: const OutlineInputBorder(),
                      errorText: _getDiscountError(),
                      errorStyle: const TextStyle(fontSize: 10),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Tax
            Row(
              children: [
                const Expanded(flex: 1, child: Text('Tax:')),
                Expanded(
                  flex: 1,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'fixed', label: Text('Rs')),
                        ButtonSegment(value: 'percentage', label: Text('%')),
                      ],
                      selected: {_taxType},
                      onSelectionChanged: (val) {
                        setState(() => _taxType = val.first);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _taxController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      isDense: true, 
                      border: const OutlineInputBorder(),
                      errorText: _getTaxError(),
                      errorStyle: const TextStyle(fontSize: 10),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TOTAL:', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                Text(
                  currencyFormat.format(_calculateTotal()),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Payment Method', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildRadio('Cash', 'cash'),
                _buildRadio('Card', 'card'),
                _buildRadio('Mobile Wallet', 'mobile_wallet'),
                _buildRadio('Others', 'others'),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              flex: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 120),
                child: TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: BlocBuilder<PaymentCubit, PaymentState>(
                builder: (context, state) {
                  final isLoading = state is PaymentLoading;
                  return FilledButton.icon(
                    onPressed: (isLoading || _hasErrors()) ? null : _processPayment,
                    icon: isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle),
                    label: const Text('Process Payment', style: TextStyle(fontSize: 16)),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
