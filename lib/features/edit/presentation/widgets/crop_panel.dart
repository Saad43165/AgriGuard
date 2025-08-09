import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_measurements.dart';

class CropPanel extends StatelessWidget {
  final bool isCropping;
  final VoidCallback onStartCrop;
  final VoidCallback? onApplyCrop;
  final VoidCallback onResetCrop;

  const CropPanel({
    super.key,
    required this.isCropping,
    required this.onStartCrop,
    required this.onApplyCrop,
    required this.onResetCrop,
  });

  @override
  Widget build(BuildContext context) {
    final padding = AppMeasurements.getResponsivePadding(context);
    final borderRadius = AppMeasurements.getResponsiveBorderRadius(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding / 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
          ),
          onPressed: onStartCrop,
          child: Text(AppStrings.startCrop),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding / 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
          ),
          onPressed: onApplyCrop,
          child: Text(AppStrings.applyCrop),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding / 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
          ),
          onPressed: onResetCrop,
          child: Text(AppStrings.resetCrop),
        ),
      ],
    );
  }
}