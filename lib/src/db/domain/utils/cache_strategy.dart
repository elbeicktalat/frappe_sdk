// Copyright (©) 2025. Talat El Beick. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

/// Represents the caching strategy to use for database operations.
enum CacheStrategy {
  /// Always fetch from the remote data source.
  networkOnly,

  /// Always fetch from the local data source.
  cacheOnly,

  /// Fetch from the local data source first.
  /// If the data is not found locally, fetch it from the remote data source
  /// and save it locally.
  cacheFirst,

  /// Fetch from the remote data source first.
  /// If the request succeeds, save the data locally.
  /// If the request fails, fetch the data from the local data source.
  networkFirst,
}
