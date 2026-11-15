/// Only this app's official store pages may be opened by an update response.
bool isOfficialStoreUrl(Uri? url, String platform) {
  if (url == null || url.scheme != 'https' || url.userInfo.isNotEmpty) {
    return false;
  }
  return platform == 'android'
      ? url.host == 'play.google.com' &&
            url.path == '/store/apps/details' &&
            url.queryParameters['id'] == 'com.j2partners.buildingManageFront'
      : platform == 'ios' &&
            url.host == 'apps.apple.com' &&
            url.path.endsWith('/id6755674738');
}
