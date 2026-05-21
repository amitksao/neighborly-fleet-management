import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/fleet_ride/fleet_ride_repository.dart';

/// A text field with debounced address autocomplete.
/// Calls [onPlaceSelected] with the resolved [PlaceDetail] when the user picks a suggestion.
class AddressSearchField extends StatefulWidget {
  final FleetRideRepository repository;
  final String label;
  final PlaceDetail? initialValue;
  final void Function(PlaceDetail place) onPlaceSelected;

  const AddressSearchField({
    super.key,
    required this.repository,
    required this.label,
    required this.onPlaceSelected,
    this.initialValue,
  });

  @override
  State<AddressSearchField> createState() => _AddressSearchFieldState();
}

class _AddressSearchFieldState extends State<AddressSearchField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = [];
  bool _loading = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!.address;
    }
    _focus.addListener(() {
      if (!_focus.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.length < 3) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      setState(() => _loading = true);
      try {
        final results = await widget.repository.searchAddress(value);
        if (mounted) {
          setState(() {
            _suggestions = results;
            _showSuggestions = results.isNotEmpty;
            _loading = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  Future<void> _onSuggestionTap(PlaceSuggestion suggestion) async {
    setState(() {
      _showSuggestions = false;
      _loading = true;
      _controller.text = suggestion.description;
    });
    try {
      final detail = await widget.repository.getPlaceDetails(suggestion.placeId);
      if (mounted) {
        setState(() {
          _controller.text = detail.address;
          _loading = false;
        });
        widget.onPlaceSelected(detail);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focus,
          onChanged: _onChanged,
          decoration: InputDecoration(
            labelText: widget.label,
            border: const OutlineInputBorder(),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : null,
          ),
        ),
        if (_showSuggestions)
          Material(
            elevation: 4,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final s = _suggestions[i];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on_outlined, size: 18),
                  title: Text(s.description, style: const TextStyle(fontSize: 14)),
                  onTap: () => _onSuggestionTap(s),
                );
              },
            ),
          ),
      ],
    );
  }
}
