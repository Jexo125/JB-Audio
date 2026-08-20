import '../../entities/discovery_criteria.dart';
import '../../entities/cast_options.dart';

class IOSGoogleCastOptions extends GoogleCastOptions {
  final GoogleCastDiscoveryCriteriaInitialize _discoveryCriteria;

  IOSGoogleCastOptions(this._discoveryCriteria);

  @override
  Map<String, dynamic> toMap() {
    return super.toMap()
      ..addAll(
        {
          'discoveryCriteria': _discoveryCriteria.toMap(),
        },
      );
  }
}
