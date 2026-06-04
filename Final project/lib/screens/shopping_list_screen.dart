import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/app_provider.dart';
import '../utils/theme.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  List<ShoppingListItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final local = context.read<AppProvider>().local;
    final items = await local.getShoppingList();
    setState(() { _items = items; _loading = false; });
  }

  Future<void> _toggle(String id) async {
    final local = context.read<AppProvider>().local;
    await local.toggleShoppingItem(id);
    await _load();
  }

  Future<void> _remove(String id) async {
    final local = context.read<AppProvider>().local;
    await local.removeShoppingItem(id);
    await _load();
  }

  void _showAdd() {
    final nameCtrl  = TextEditingController();
    final priceCtrl = TextEditingController();
    String emoji = '🛒';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20,
              MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4,
                decoration: BoxDecoration(color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Add Item', style: TextStyle(fontSize: 16,
                fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            // Emoji picker
            SingleChildScrollView(scrollDirection: Axis.horizontal,
              child: Row(children: ['🛒','🌾','🍚','🫙','🧂','🍞','🥛','🍅','🧅','🥚',
                '🍗','🥩','🧈','🥕','🍋','🧃','☕','🍵','🧻','🪥']
                    .map((e) => GestureDetector(
                      onTap: () => setS(() => emoji = e),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: emoji == e ? AppColors.primaryLight : AppColors.gray50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: emoji == e ? AppColors.primary : Colors.transparent)),
                        child: Text(e, style: const TextStyle(fontSize: 18))),
                    )).toList()),
            ),
            const SizedBox(height: 12),
            TextField(controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Item name *')),
            const SizedBox(height: 10),
            TextField(controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Est. price (ETB, optional)')),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final local = context.read<AppProvider>().local;
                await local.addShoppingItem(ShoppingListItem(
                  id: const Uuid().v4(),
                  name: nameCtrl.text.trim(),
                  emoji: emoji,
                  estimatedPrice: double.tryParse(priceCtrl.text),
                ));
                if (ctx.mounted) Navigator.pop(ctx);
                await _load();
              },
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
              child: const Text('Add to List'),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final checked   = _items.where((i) => i.checked).toList();
    final unchecked = _items.where((i) => !i.checked).toList();
    final total = _items
        .where((i) => i.estimatedPrice != null)
        .fold(0.0, (s, i) => s + i.estimatedPrice!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        actions: [
          if (checked.isNotEmpty)
            TextButton(
              onPressed: () async {
                final local = context.read<AppProvider>().local;
                for (final item in checked) {
                  await local.removeShoppingItem(item.id);
                }
                await _load();
              },
              child: const Text('Clear done',
                  style: TextStyle(color: AppColors.accent)),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAdd,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Item'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.primary))
          : _items.isEmpty
              ? _buildEmpty()
              : Column(children: [
                  if (total > 0)
                    Container(
                      color: Theme.of(context).colorScheme.surface,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(children: [
                        const Icon(Icons.shopping_cart_outlined,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Text('Estimated total: ETB ${total.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary)),
                        const Spacer(),
                        Text('${unchecked.length} remaining',
                            style: const TextStyle(fontSize: 12,
                                color: AppColors.gray400)),
                      ]),
                    ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (unchecked.isNotEmpty) ...[
                          _buildSection('To Buy (${unchecked.length})', unchecked),
                        ],
                        if (checked.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildSection('Done ✓ (${checked.length})', checked,
                              done: true),
                        ],
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ]),
    );
  }

  Widget _buildSection(String title, List<ShoppingListItem> items,
      {bool done = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title.toUpperCase(), style: const TextStyle(fontSize: 11,
          fontWeight: FontWeight.w600, color: AppColors.gray400,
          letterSpacing: 0.5)),
      const SizedBox(height: 8),
      Card(
        child: Column(
          children: items.asMap().entries.map((e) {
            final item = e.value;
            return Column(children: [
              Dismissible(
                key: Key(item.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.delete_rounded,
                      color: Colors.white),
                ),
                onDismissed: (_) => _remove(item.id),
                child: ListTile(
                  leading: Text(item.emoji,
                      style: TextStyle(fontSize: 22,
                          color: done ? Colors.grey : null)),
                  title: Text(item.name, style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500,
                      decoration: done ? TextDecoration.lineThrough : null,
                      color: done ? AppColors.gray400 : null)),
                  subtitle: item.estimatedPrice != null
                      ? Text('~ETB ${item.estimatedPrice!.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.gray400))
                      : null,
                  trailing: Checkbox(
                    value: item.checked,
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    onChanged: (_) => _toggle(item.id),
                  ),
                  onTap: () => _toggle(item.id),
                ),
              ),
              if (e.key < items.length - 1)
                const Divider(indent: 60),
            ]);
          }).toList(),
        ),
      ),
    ]);
  }

  Widget _buildEmpty() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('🛒', style: TextStyle(fontSize: 52)),
      const SizedBox(height: 16),
      const Text('Your shopping list is empty',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
              color: AppColors.gray800)),
      const SizedBox(height: 6),
      const Text('Add groceries to track and check off',
          style: TextStyle(fontSize: 13, color: AppColors.gray400)),
      const SizedBox(height: 24),
      ElevatedButton.icon(
        onPressed: _showAdd,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add First Item'),
      ),
    ]),
  );
}
