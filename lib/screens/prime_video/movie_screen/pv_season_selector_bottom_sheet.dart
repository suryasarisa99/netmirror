import 'package:flutter/material.dart';
import 'package:shared_code/models/movie_model.dart';

class SeasonSelectorBottomSheet extends StatelessWidget {
  final Map<int, Season> seasons;
  final int selectedSeason;
  final Function(int seasonNumber) onTap;

  SeasonSelectorBottomSheet({
    required this.seasons,
    required this.selectedSeason,
    required this.onTap,
    super.key,
  });

  final controller = ScrollController();
  @override
  Widget build(BuildContext context) {
    // Get sorted season numbers for consistent display
    final seasonNumbers = seasons.keys.toList();

    //  dragableScrollableSheet
    return DraggableScrollableSheet(
      expand: false,
      builder: (context, x) {
        return Container(
          color: const Color.fromRGBO(25, 30, 37, 1),
          padding: const EdgeInsets.only(left: 20, right: 20, top: 35),
          child: NotificationListener(
            child: ListView.builder(
              itemCount: seasonNumbers.length,
              controller: x,
              itemBuilder: (context, index) {
                final seasonNumber = seasonNumbers[index];
                final season = seasons[seasonNumber]!;
                final isSelected = seasonNumber == selectedSeason;
                return InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    onTap(seasonNumber);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      // borderRadius: BorderRadius.circular(8),
                      color: isSelected
                          ? const Color.fromRGBO(71, 75, 81, 1)
                          : null,
                    ),
                    child: Text("Season ${season.s}"),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
