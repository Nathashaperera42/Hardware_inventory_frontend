import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/app_theme.dart';
import '../models/supplier.dart';
import '../services/inventory_api.dart';
import '../widgets/section_card.dart';
import '../widgets/feedback.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});
  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final _api = InventoryApi();
  List<Supplier> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getSuppliers();
      if (mounted) setState(() { _list = data; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) { showSnack(context, e.message, error: true); setState(() => _loading = false); }
    }
  }

  Future<void> _openForm([Supplier? existing]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _SupplierDialog(api: _api, existing: existing),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Supplier s) async {
    final ok = await confirmDelete(context, 'Delete "${s.supplierName}"?');
    if (ok != true) return;
    try {
      await _api.deleteSupplier(s.supplierId);
      if (mounted) showSnack(context, 'Supplier deleted.');
      _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SectionCard(
        title: 'Suppliers',
        subtitle: 'Vendors who supply your stock',
        action: ElevatedButton.icon(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Supplier'),
        ),
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator())
            : _list.isEmpty
                ? const EmptyView('No suppliers yet.')
                : LayoutBuilder(builder: (context, c) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: c.maxWidth),
                        child: DataTable(
                          headingRowColor:
                              WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                          columns: const [
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Contact')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Address')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: _list
                              .map((s) => DataRow(cells: [
                                    DataCell(Text(s.supplierName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600))),
                                    DataCell(Text(s.contactNumber ?? '-')),
                                    DataCell(Text(s.email ?? '-')),
                                    DataCell(SizedBox(
                                        width: 200,
                                        child: Text(s.address ?? '-',
                                            overflow: TextOverflow.ellipsis))),
                                    DataCell(Row(children: [
                                      IconButton(
                                          icon: const Icon(Icons.edit_outlined,
                                              size: 20,
                                              color: AppColors.primary),
                                          onPressed: () => _openForm(s)),
                                      IconButton(
                                          icon: const Icon(Icons.delete_outline,
                                              size: 20, color: AppColors.out),
                                          onPressed: () => _delete(s)),
                                    ])),
                                  ]))
                              .toList(),
                        ),
                      ),
                    );
                  }),
      ),
    );
  }
}

class _SupplierDialog extends StatefulWidget {
  final InventoryApi api;
  final Supplier? existing;
  const _SupplierDialog({required this.api, this.existing});
  @override
  State<_SupplierDialog> createState() => _SupplierDialogState();
}

class _SupplierDialogState extends State<_SupplierDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name, _contact, _email, _address;
  bool _active = true, _busy = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.supplierName ?? '');
    _contact =
        TextEditingController(text: widget.existing?.contactNumber ?? '');
    _email = TextEditingController(text: widget.existing?.email ?? '');
    _address = TextEditingController(text: widget.existing?.address ?? '');
    _active = widget.existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _email.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final model = Supplier(
      supplierId: widget.existing?.supplierId ?? 0,
      supplierName: _name.text.trim(),
      contactNumber: _contact.text.trim(),
      email: _email.text.trim(),
      address: _address.text.trim(),
      isActive: _active,
    );
    try {
      if (widget.existing == null) {
        await widget.api.createSupplier(model);
      } else {
        await widget.api.updateSupplier(widget.existing!.supplierId, model);
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() => _busy = false);
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text(widget.existing == null ? 'Add Supplier' : 'Edit Supplier'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration:
                    const InputDecoration(labelText: 'Supplier name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contact,
                decoration:
                    const InputDecoration(labelText: 'Contact number'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) =>
                    (v != null && v.isNotEmpty && !v.contains('@'))
                        ? 'Invalid email'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'Address'),
                maxLines: 2,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Save')),
      ],
    );
  }
}
