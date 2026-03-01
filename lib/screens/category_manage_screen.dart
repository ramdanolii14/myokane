import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/finance_provider.dart';
import '../providers/settings_provider.dart';
import '../models/transaction.dart';
import '../utils/theme.dart';
import '../animations/animated_widgets.dart';

class CategoryManageScreen extends StatefulWidget {
  const CategoryManageScreen({super.key});

  @override
  State<CategoryManageScreen> createState() => _CategoryManageScreenState();
}

class _CategoryManageScreenState extends State<CategoryManageScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.read<SettingsProvider>();
    final theme = buildAppTheme(sp.settings);
    final fp = context.watch<FinanceProvider>();

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        backgroundColor: theme.bg,
        title: Text('Kelola Kategori',
            style: TextStyle(
                fontWeight: FontWeight.w900, color: theme.textPrimary)),
        leading: TapScale(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: theme.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.border)),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                color: theme.textPrimary, size: 16),
          ),
        ),
        bottom: TabBar(
          controller: _tab,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          labelColor: theme.accent,
          unselectedLabelColor: theme.textMuted,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(color: theme.accent, width: 2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          ),
          tabs: const [Tab(text: 'Pemasukan'), Tab(text: 'Pengeluaran')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _CategoryList(
            theme: theme,
            type: TransactionType.income,
            categories: fp.incomeCategories,
          ),
          _CategoryList(
            theme: theme,
            type: TransactionType.expense,
            categories: fp.expenseCategories,
          ),
        ],
      ),
      floatingActionButton: TapScale(
        onTap: () => _showAddCategory(context, theme,
            _tab.index == 0 ? TransactionType.income : TransactionType.expense),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [theme.accent, theme.accent.withOpacity(0.8)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: theme.accent.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6))
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded,
                  color: theme.isDark ? const Color(0xFF0D0F14) : Colors.white,
                  size: 20),
              const SizedBox(width: 6),
              Text(
                'Tambah Kategori',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color:
                        theme.isDark ? const Color(0xFF0D0F14) : Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCategory(
      BuildContext context, AppTheme theme, TransactionType type) {
    final nameCtrl = TextEditingController();
    String selectedEmoji = type == TransactionType.income ? '💰' : '💸';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 20),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: theme.border,
                        borderRadius: BorderRadius.circular(2))),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('Kategori Baru',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: theme.textPrimary)),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PILIH IKON',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: theme.textMuted,
                            letterSpacing: .5)),
                    const SizedBox(height: 10),
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: theme.surface2,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.border),
                      ),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 10,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                        ),
                        itemCount: emojiList.length,
                        itemBuilder: (_, i) {
                          final e = emojiList[i];
                          return TapScale(
                            onTap: () => setS(() => selectedEmoji = e),
                            child: AnimatedContainer(
                              duration: 150.ms,
                              decoration: BoxDecoration(
                                color: selectedEmoji == e
                                    ? theme.accent.withOpacity(0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: selectedEmoji == e
                                        ? theme.accent
                                        : Colors.transparent),
                              ),
                              child: Center(
                                  child: Text(e,
                                      style: const TextStyle(fontSize: 18))),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: (type == TransactionType.income
                                    ? incomeColor
                                    : expenseColor)
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                              child: Text(selectedEmoji,
                                  style: const TextStyle(fontSize: 26))),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextField(
                            controller: nameCtrl,
                            style: TextStyle(
                                color: theme.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'Nama kategori...',
                              hintStyle: TextStyle(color: theme.textMuted),
                              filled: true,
                              fillColor: theme.surface2,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: theme.border)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: theme.border)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: theme.accent)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: TapScale(
                    onTap: () {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      context
                          .read<FinanceProvider>()
                          .addCategory(CustomCategory(
                            id: const Uuid().v4(),
                            name: name,
                            emoji: selectedEmoji,
                            type: type,
                          ));
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: theme.accent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          'Simpan Kategori',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: theme.isDark
                                  ? const Color(0xFF0D0F14)
                                  : Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final AppTheme theme;
  final TransactionType type;
  final List categories;

  const _CategoryList({
    required this.theme,
    required this.type,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final fp = context.read<FinanceProvider>();

    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 48, color: theme.textMuted),
            const SizedBox(height: 12),
            Text('Belum ada kategori',
                style: TextStyle(
                    color: theme.textMuted, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: categories.length,
      itemBuilder: (_, i) {
        final cat = categories[i];

        return StaggerItem(
          index: i,
          child: Dismissible(
            key: Key(cat.id),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => fp.deleteCategory(cat.id),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: expenseColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.delete_rounded, color: expenseColor),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: theme.surface2,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.border),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: (type == TransactionType.income
                            ? incomeColor
                            : expenseColor)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                      child: Text(cat.emoji,
                          style: const TextStyle(fontSize: 22))),
                ),
                title: Text(cat.name,
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: theme.textPrimary)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TapScale(
                      onTap: () => _showEdit(
                          context, theme, fp, cat.id, cat.name, cat.emoji),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.edit_rounded,
                            size: 16, color: theme.accent),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TapScale(
                      onTap: () =>
                          _confirmDelete(context, theme, fp, cat.id, cat.name),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: expenseColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.delete_rounded,
                            size: 16, color: expenseColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEdit(BuildContext context, AppTheme theme, FinanceProvider fp,
      String id, String name, String emoji) {
    final ctrl = TextEditingController(text: name);
    String sel = emoji;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          decoration: BoxDecoration(
              color: theme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: theme.border,
                      borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Edit Kategori',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: theme.textPrimary)),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  height: 100,
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 10,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4),
                    itemCount: emojiList.length,
                    itemBuilder: (_, i) {
                      final e = emojiList[i];
                      return TapScale(
                        onTap: () => setS(() => sel = e),
                        child: AnimatedContainer(
                          duration: 150.ms,
                          decoration: BoxDecoration(
                            color: sel == e
                                ? theme.accent.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: sel == e
                                    ? theme.accent
                                    : Colors.transparent),
                          ),
                          child: Center(
                              child: Text(e,
                                  style: const TextStyle(fontSize: 18))),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                          color: theme.surface2,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: theme.border)),
                      child: Center(
                          child:
                              Text(sel, style: const TextStyle(fontSize: 26))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: ctrl,
                        style: TextStyle(
                            color: theme.textPrimary,
                            fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: theme.surface2,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: theme.border)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: theme.border)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: theme.accent)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: TapScale(
                    onTap: () {
                      final n = ctrl.text.trim();
                      if (n.isEmpty) return;
                      fp.editCategory(id, n, sel);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                          color: theme.accent,
                          borderRadius: BorderRadius.circular(16)),
                      child: Center(
                          child: Text('Simpan',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: theme.isDark
                                      ? const Color(0xFF0D0F14)
                                      : Colors.white))),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppTheme theme, FinanceProvider fp,
      String id, String name) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: theme.surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hapus "$name"?',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: theme.textPrimary)),
              const SizedBox(height: 12),
              Text('Kategori ini akan dihapus permanen.',
                  style: TextStyle(
                      color: theme.textMuted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Batal',
                        style: TextStyle(
                            color: theme.textMuted,
                            fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 8),
                  TapScale(
                    onTap: () {
                      fp.deleteCategory(id);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                          color: expenseColor,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Text('Hapus',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const emojiList = [
  '💼',
  '💻',
  '📈',
  '🏪',
  '🎁',
  '💰',
  '💵',
  '🏦',
  '💳',
  '🤑',
  '🍜',
  '🚗',
  '🛍️',
  '🎮',
  '🏥',
  '📚',
  '📄',
  '💸',
  '🏠',
  '✈️',
  '🎵',
  '⚽',
  '🍕',
  '☕',
  '🎭',
  '💄',
  '👗',
  '🔧',
  '📱',
  '💡',
  '🎓',
  '🏋️',
  '🌴',
  '🎪',
  '🛒',
  '🚌',
  '🏍️',
  '⛽',
  '💊',
  '🏨',
  '🎯',
  '🌟',
  '🔑',
  '🎈',
  '🍰',
  '🎉',
  '🌈',
  '🦋',
  '🐶',
  '🌸',
];
