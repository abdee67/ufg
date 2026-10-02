class AllImages {
  AllImages._();
  static final AllImages _instance = AllImages._();
  factory AllImages() => _instance;

  static const String images = 'assets/images';
  static const String icons = 'assets/icons';
  static const String logo = 'assets/icon/icon.png';
  static const String kDefaultImage =
      'https://cdn.pixabay.com/photo/2016/08/08/09/17/avatar-1577909_1280.png';
}
