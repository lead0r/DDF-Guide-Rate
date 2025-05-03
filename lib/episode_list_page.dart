class _EpisodeListPageState extends State<EpisodeListPage> {
  List<Episode> get futureEpisodes => _episodes.where((ep) => ep.isFuture).toList();
  
  List<Episode> get filteredRegular => _episodes
      .where((ep) => !ep.isFuture)
      .where((ep) => _searchController.text.isEmpty ||
          ep.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          ep.number.toString().contains(_searchController.text))
      .toList();

  List<Episode> get filteredFuture => futureEpisodes
      .where((ep) => _searchController.text.isEmpty ||
          ep.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          ep.number.toString().contains(_searchController.text))
      .toList();
} 