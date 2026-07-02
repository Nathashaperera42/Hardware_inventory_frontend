import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/app_theme.dart';
import '../models/category.dart';
import '../services/inventory_api.dart';
import '../widgets/section_card.dart';
import '../widgets/feedback.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _api = InventoryApi();
  List<Category> _list = [];
  bool _loading = true;
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = _keyword.isEmpty
          ? await _api.getCategories()
          : await _api.searchCategories(_keyword);
      if (mounted) setState(() { _list = data; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) { showSnack(context, e.message, error: true); setState(() => _loading = false); }
    }
  }

  Future<void> _openForm([Category? existing]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _CategoryDialog(api: _api, existing: existing),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Category c) async {
    final ok = await confirmDelete(context, 'Delete "${c.categoryName}"?');
    if (ok != true) return;
    try {
      await _api.deleteCategory(c.categoryId);
      if (mounted) showSnack(context, 'Category deleted.');
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
        title: 'Categories',
        subtitle: 'Group your hardware products',
        action: ElevatedButton.icon(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Category'),
        ),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search categories...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) { _keyword = v; _load(); },
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator())
            else if (_list.isEmpty)
              const EmptyView('No categories yet.')
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Description')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: _list.map((c) => DataRow(cells: [
                    DataCell(Text(c.categoryName,
                        style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text(c.description ?? '-')),
                    DataCell(Text(
                      c.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                          color: c.isActive ? AppColors.good : AppColors.textMuted),
                    )),
                    DataCell(Row(children: [
                      IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              size: 20, color: AppColors.primary),
                          onPressed: () => _openForm(c)),
                      IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 20, color: AppColors.out),
                          onPressed: () => _delete(c)),
                    ])),
                  ])).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  final InventoryApi api;
  final Category? existing;
  const _CategoryDialog({required this.api, this.existing});
  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _desc;
  bool _active = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.categoryName ?? '');
    _desc = TextEditingController(text: widget.existing?.description ?? '');
    _active = widget.existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final model = Category(
      categoryId: widget.existing?.categoryId ?? 0,
      categoryName: _name.text.trim(),
      description: _desc.text.trim(),
      isActive: _active,
    );
    try {
      if (widget.existing == null) {
        await widget.api.createCategory(model);
      } else {
        await widget.api.updateCategory(widget.existing!.categoryId, model);
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
      title: Text(widget.existing == null ? 'Add Category' : 'Edit Category'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Category name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _desc,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 4),
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
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Save')),
      ],
    );
  }
}
