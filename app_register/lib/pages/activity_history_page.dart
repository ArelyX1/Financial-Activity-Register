import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../components/history_item_widget.dart';
import '../components/text_field_widget.dart';

class ActivityHistoryPage extends StatefulWidget {
  const ActivityHistoryPage({super.key});

  @override
  State<ActivityHistoryPage> createState() => _ActivityHistoryPageState();
}

class _ActivityHistoryPageState extends State<ActivityHistoryPage> {
  final _searchController = TextEditingController();
  int _selectedFilter = 0;
  final _filters = ['Todos', 'Hoy', 'Semana', 'Mes'];

  final _activities = List.generate(10, (i) => {
    'title': 'Gestión ${i + 1}',
    'subtitle': 'Cliente ${i + 1} - Trámite de ${['crédito', 'desembolso', 'vehículo', 'consulta'][i % 4]}',
    'date': '${i + 1} Jun, 2026',
    'status': ['Completado', 'Pendiente', 'En Proceso'][i % 3],
  });

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        title: Text('Historial', style: theme.titleLarge.copyWith(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextFieldWidget(
              controller: _searchController,
              hint: 'Buscar actividades...',
              prefixIcon: Icons.search,
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 12),
          _buildFilterChips(context),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _activities.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '${_activities.length} actividades encontradas',
                      style: theme.bodySmall.copyWith(color: theme.secondaryText),
                    ),
                  );
                }
                final act = _activities[index - 1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: HistoryItemWidget(
                    title: act['title']!,
                    subtitle: act['subtitle'],
                    date: act['date'],
                    status: act['status'],
                    onTap: () {},
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/activity/register'),
        backgroundColor: theme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final theme = AppTheme.of(context);
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = _selectedFilter == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected ? theme.primary : theme.secondaryBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? theme.primary : const Color(0xFFE1E1E1),
                ),
              ),
              child: Center(
                child: Text(
                  _filters[index],
                  style: theme.labelMedium.copyWith(
                    color: selected ? Colors.white : theme.primaryText,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
