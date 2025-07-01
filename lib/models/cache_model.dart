import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class MovieCacheManager {
  static final CacheManager instance = CacheManager(Config(
    'movieCache',
    stalePeriod: const Duration(days: 7),
    maxNrOfCacheObjects: 400,
  ));
}

class ShowCacheManager {
  static final CacheManager instance = CacheManager(Config(
    'showCache',
    stalePeriod: const Duration(days: 7),
    maxNrOfCacheObjects: 400,
  ));
}

class BillBoardCacheManager {
  static final CacheManager instance = CacheManager(Config(
    'billboardCache',
    stalePeriod: const Duration(days: 7),
    maxNrOfCacheObjects: 40,
  ));
}

class LogAssetCacheManager {
  static final CacheManager instance = CacheManager(Config(
    'logoAsseetCache',
    stalePeriod: const Duration(days: 7),
    maxNrOfCacheObjects: 40,
  ));
}

class GameCacheManager {
  static final CacheManager instance = CacheManager(Config(
    'gameCache',
    stalePeriod: const Duration(days: 7),
    maxNrOfCacheObjects: 30,
  ));
}

class SearchRecomCacheManager {
  static final CacheManager instance = CacheManager(Config(
    'searchRecCache',
    stalePeriod: const Duration(days: 7),
    maxNrOfCacheObjects: 30,
  ));
}

class MovieThumbCacheManager {
  static final CacheManager instance = CacheManager(Config(
    'movieScreenCache',
    stalePeriod: const Duration(days: 7),
    maxNrOfCacheObjects: 400,
  ));
}

class EpisodeCacheManager {
  static final CacheManager instance = CacheManager(Config(
    'episdoeCache',
    stalePeriod: const Duration(days: 99),
    maxNrOfCacheObjects: 400,
  ));
}

class NfSmallCacheManager {
  static final CacheManager instance = CacheManager(Config(
    'nfSmallCache',
    stalePeriod: const Duration(days: 7),
    maxNrOfCacheObjects: 400,
  ));
}

class NfLargeCacheManager {
  static final CacheManager instance = CacheManager(Config(
    'nfLargeCache',
    stalePeriod: const Duration(days: 7),
    maxNrOfCacheObjects: 400,
  ));
}

class NfSpotLightCacheManager {
  static final CacheManager instance = CacheManager(Config(
    'nfSpotlightCache',
    stalePeriod: const Duration(days: 7),
    maxNrOfCacheObjects: 400,
  ));
}

class PvSpotLightCacheManager {
  static final CacheManager instance = CacheManager(Config(
    'pvSpotlightCache',
    stalePeriod: const Duration(days: 7),
    maxNrOfCacheObjects: 400,
  ));
}

class PvSmallCacheManager {
  static final CacheManager instance = CacheManager(Config(
    'pvSmallCache',
    stalePeriod: const Duration(days: 7),
    maxNrOfCacheObjects: 400,
  ));
}

class PvLargeCacheManager {
  static final CacheManager instance = CacheManager(Config(
    'pvLargeCache',
    stalePeriod: const Duration(days: 7),
    maxNrOfCacheObjects: 400,
  ));
}
