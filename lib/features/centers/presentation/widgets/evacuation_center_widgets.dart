import 'package:flutter/material.dart';
import 'package:kalig_onan_evac_system/features/centers/domain/evacuation_center.dart';

String statusText(CenterStatus status) {
  switch (status) {
    case CenterStatus.operational:
      return 'Operational';
    case CenterStatus.nearCapacity:
      return 'Near Capacity';
    case CenterStatus.atCapacity:
      return 'At Capacity';
    case CenterStatus.closed:
      return 'Closed';
  }
}

Color statusColor(CenterStatus status) {
  switch (status) {
    case CenterStatus.operational:
      return Colors.green;
    case CenterStatus.nearCapacity:
      return Colors.orange;
    case CenterStatus.atCapacity:
      return Colors.red;
    case CenterStatus.closed:
      return Colors.grey;
  }
}
