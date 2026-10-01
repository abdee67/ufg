class AllImages {
  AllImages._();
  static final AllImages _instance = AllImages._();
  factory AllImages() => _instance;

  String images = 'assets/images';
  String icons = 'assets/icons';
  String logo = 'assets/icon/icon.png';
  String kDefaultImage =
      'https://cdn.pixabay.com/photo/2016/08/08/09/17/avatar-1577909_1280.png';
}
