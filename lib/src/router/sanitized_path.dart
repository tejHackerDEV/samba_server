class SanitizedPath {
  final Iterable<String> pathSections;
  final String? queryString;

  SanitizedPath._(this.pathSections, this.queryString);

  factory SanitizedPath(String path) {
    final pathSections = <String>[];
    int startIndex = 0;
    int queryStringIndex = -1;
    for (int i = 0; i < path.length; ++i) {
      if (path[i] == '/') {
        // '/' detected, meaning next pathSection is going to begin,
        // so add previous one as a pathSection, if its not empty.
        // & continue iterations
        final pathSection = path.substring(startIndex, i).trim();
        if (pathSection.isNotEmpty) {
          pathSections.add(pathSection);
        }
        startIndex = i + 1;
        continue;
      }
      if (path[i] == '?') {
        // '?' detected, meaning pathSections got completed
        // so add previous as a pathSection, if its not empty.
        //
        // Also reset the startIndex & insert the remaining as queryString
        final pathSection = path.substring(startIndex, i).trim();
        if (pathSection.isNotEmpty) {
          pathSections.add(pathSection);
        }
        startIndex = -1;
        queryStringIndex = i + 1;
        break;
      }
    }
    if (startIndex != -1) {
      // startIndex is not reset, so there is one last pathSection left
      // add it to the pathSections, only if its not empty string
      // & reset the startIndex.
      final pathSection = path.substring(startIndex).trim();
      if (pathSection.isNotEmpty) {
        pathSections.add(pathSection);
      }
      startIndex = -1;
    }
    return SanitizedPath._(
      pathSections,
      queryStringIndex == -1 ? null : path.substring(queryStringIndex),
    );
  }
}
