import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class SearchableDropdownWidget extends StatefulWidget {
  final String label;
  final LocationData? value;
  final List<LocationData> items;
  final Color fillColor;
  final void Function(LocationData?) onChanged;
  final String? hint;

  const SearchableDropdownWidget({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.fillColor,
    required this.onChanged,
    this.hint,
  });

  @override
  State<SearchableDropdownWidget> createState() => _SearchableDropdownWidgetState();
}

class _SearchableDropdownWidgetState extends State<SearchableDropdownWidget> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSheet() {
    _searchController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SearchSheet(
        items: widget.items,
        searchController: _searchController,
        onSelect: (loc) {
          Navigator.pop(ctx);
          widget.onChanged(loc);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: theme.bodyMedium.copyWith(
            color: theme.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _openSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: widget.fillColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE1E1E1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.value?.name ?? (widget.hint ?? 'Seleccionar ${widget.label}'),
                    style: theme.bodyMedium.copyWith(
                      color: widget.value != null
                          ? theme.primaryText
                          : theme.secondaryText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.search, color: theme.secondaryText, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchSheet extends StatefulWidget {
  final List<LocationData> items;
  final TextEditingController searchController;
  final void Function(LocationData) onSelect;

  const _SearchSheet({
    required this.items,
    required this.searchController,
    required this.onSelect,
  });

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  List<LocationData> _filtered = [];
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      if (q.isEmpty) {
        _filtered = widget.items;
      } else {
        _filtered = widget.items
            .where((loc) => loc.name.toLowerCase().contains(q))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final topPad = MediaQuery.paddingOf(context).top;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollController) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 12 + topPad * 0.3, 20, 20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.secondaryText.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE4E4E4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: widget.searchController,
                  focusNode: _focusNode,
                  onChanged: _filter,
                  style: theme.bodyMedium.copyWith(color: theme.primaryText),
                  decoration: InputDecoration(
                    hintText: 'Buscar...',
                    hintStyle: theme.bodyMedium.copyWith(color: theme.secondaryText),
                    prefixIcon: Icon(Icons.search, color: theme.secondaryText, size: 20),
                    suffixIcon: widget.searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: theme.secondaryText, size: 18),
                            onPressed: () {
                              widget.searchController.clear();
                              _filter('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Text(
                          'Sin resultados',
                          style: theme.bodyMedium.copyWith(color: theme.secondaryText),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _filtered.length,
                        itemBuilder: (ctx, i) {
                          final loc = _filtered[i];
                          return InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => widget.onSelect(loc),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              margin: const EdgeInsets.only(bottom: 2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                loc.name,
                                style: theme.bodyMedium.copyWith(color: theme.primaryText),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
