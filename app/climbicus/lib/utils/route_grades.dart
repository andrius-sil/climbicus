
import 'package:climbicus/constants.dart';

const GRADE_SYSTEMS = {
  'V': ['VB', 'V0-', 'V0', 'V0+', 'V1', 'V2', 'V3', 'V4', 'V5', 'V6', 'V7', 'V8', 'V9', 'V10', 'V11', 'V12', 'V13', 'V14', 'V15', 'V16', 'V17'],
  'French': ['1', '2', '3', '4', '4a', '4b', '4c', '5a', '5b', '5c', '6a', '6a+', '6b', '6b+', '6c', '6c+', '7a', '7a+', '7b', '7b+', '8a', '8a+', '8b', '8b+', '8c', '8c+'],
  'Font': ['3', '4-', '4', '4+', '5', '5+', '6A', '6A+', '6B', '6B+', '6C', '6C+', '7A', '7A+', '7B', '7B+', '7C', '7C+', '8A', '8A+', '8B', '8B+', '8C', '8C+', '9A'],
};

const DEFAULT_GRADE_SYSTEM = {
  SPORT_CATEGORY: 'Font',
  BOULDERING_CATEGORY: 'V',
};


class GradeValues {
  final int start;
  final int end;

  const GradeValues(this.start, this.end);
}